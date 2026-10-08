"""Local-only preview. Runs real addon Lua with isolated, synthetic saved data."""
from pathlib import Path
import argparse, contextlib, io, json, os, runpy, sys, threading, time, traceback, webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, unquote

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools' / '.py'))
# A worktree shares the primary checkout's optional Python dependencies.
gitfile = ROOT / '.git'
if gitfile.is_file():
    gitdir = Path(gitfile.read_text().strip().split(': ', 1)[1])
    common = (gitdir / (gitdir / 'commondir').read_text().strip()).resolve()
    sys.path.insert(0, str(common.parent / 'tools' / '.py'))
from lupa import lua51
from PIL import Image

FILES = ['Data.lua', 'Library.lua', 'Npcs.lua', 'Quests.lua', 'Core.lua']

def plain(value):
    if lua51.lua_type(value) == 'table':
        keys = list(value.keys())
        if keys and all(isinstance(k, (int, float)) for k in keys) and set(keys) == set(range(1, len(keys)+1)):
            return [plain(value[i]) for i in range(1, len(keys)+1)]
        return {str(k): plain(value[k]) for k in keys if lua51.lua_type(value[k]) != 'function'}
    if lua51.lua_type(value) == 'function':
        return None
    return value

class Lab:
    def __init__(self, persist=True):
        self.persist = persist
        self.lock = threading.RLock()
        self.loaded = 0
        self.reload()

    def reload(self):
        statefile = HERE / '.state' / 'session.lua'
        saved = self.rt.eval('STUB_SERIALIZE(ForeverGoalTrackerDB)') if hasattr(self, 'rt') else (statefile.read_text(encoding='utf-8') if self.persist and statefile.exists() else None)
        self.rt = lua51.LuaRuntime(unpack_returned_tuples=True)
        self.rt.execute((ROOT / 'tools/wowstub.lua').read_text(encoding='utf-8'))
        self.rt.execute((HERE / 'runtime.lua').read_text(encoding='utf-8'))
        self.ns = self.rt.table()
        self.rt.globals().STUB_NS = self.ns
        run = self.rt.eval('function(src,name,ns) assert(loadstring(src,"@"..name))("ForeverGoalTracker",ns) end')
        for f in FILES:
            run((ROOT / f).read_text(encoding='utf-8'), f, self.ns)
        if saved:
            self.rt.execute('ForeverGoalTrackerDB = ' + saved)
        else:
            self.rt.execute('ForeverGoalTrackerDB = {active={thunderfury=true,raid_aq20=true,att_mc=true}, progress={},notes={},characters={}, welcomeSeen=true}')
        self.rt.execute('STUB_FIRE("ADDON_LOADED","ForeverGoalTracker"); STUB_FIRE("PLAYER_LOGIN"); LAB_BIND(STUB_NS)')
        self.loaded = time.time()
        self.started = time.monotonic()
        self.ns.SelectGoal(self.rt.globals().ForeverGoalTrackerDB.selected or 'thunderfury')

    def save(self):
        if not self.persist: return
        directory = HERE / '.state'
        directory.mkdir(exist_ok=True)
        temporary = directory / 'session.tmp'
        temporary.write_text(self.rt.eval('STUB_SERIALIZE(ForeverGoalTrackerDB)'), encoding='utf-8')
        temporary.replace(directory / 'session.lua')

    def snapshot(self):
        self.rt.globals().LAB_NOW = 100 + time.monotonic() - self.started
        self.rt.execute('LAB_TIMERS()')
        result = plain(self.rt.eval('LAB_SNAPSHOT(STUB_NS)'))
        result['checkout'] = str(ROOT)
        result['loaded'] = self.loaded
        result['draft'] = True
        return result

    def action(self, data):
        self.rt.globals().LAB_NOW = 100 + time.monotonic() - self.started
        self.rt.execute('LAB_TIMERS()')
        kind = data.get('action')
        goal = self.ns.GoalById(data.get('goal', self.rt.globals().ForeverGoalTrackerDB.selected))
        if kind == 'reload':
            previous = (self.rt, self.ns, self.loaded, self.started)
            try:
                self.reload()
            except Exception:
                self.rt, self.ns, self.loaded, self.started = previous
                raise
        elif kind == 'select':
            self.ns.SelectGoal(goal.id)
        elif kind == 'toggle':
            key = data['key']
            if isinstance(key, str) and key.isdigit(): key = int(key)
            rows = plain(self.rt.globals().LAB_ROWS(self.ns, goal))
            if goal.autoLevels or not any(r['key'] == key and r['kind'] != 'heading' for r in rows):
                raise ValueError('This is not a manual checkbox.')
            self.rt.globals().LAB_TOGGLE(goal.id, key)
        elif kind == 'reset':
            self.ns.resetBtn.GetScript(self.ns.resetBtn, 'OnClick')()
        elif kind == 'note':
            text = data.get('text', '')
            if len(text) > 240 or not text.strip(): raise ValueError('Enter 1 to 240 characters.')
            self.ns.SetGoalNote(goal, text)
        elif kind == 'deleteNote':
            self.ns.SetGoalNote(goal, '')
        elif kind == 'track':
            db = self.rt.globals().ForeverGoalTrackerDB
            db.active[goal.id] = True
            if goal.group:
                if not db.activeParts: db.activeParts = self.rt.table()
                parts = self.rt.table()
                for _, part in self.ns.GroupParts(goal).items(): parts[part.key] = True
                db.activeParts[goal.id] = parts
            self.ns.SelectGoal(goal.id)
        elif kind == 'fixture':
            fixture = data.get('fixture', 'fresh')
            if fixture not in {'fresh','level','loot','quests'}: raise ValueError('Unknown test setup')
            self.rt.globals().LAB_FIXTURE(fixture, goal.id)
        elif kind == 'checks':
            output = io.StringIO()
            previous = Path.cwd()
            ok = True
            try:
                os.chdir(ROOT)
                with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                    runpy.run_path(str(ROOT / 'tools/check.py'), run_name='__main__')
            except SystemExit as e:
                ok = e.code in (0, None)
                if not ok: output.write(f'Check runner exited with {e.code}\n')
            except Exception:
                ok = False
                output.write(traceback.format_exc())
            finally:
                os.chdir(previous)
            return {'ok': ok, 'output': output.getvalue()[-20000:]}
        else:
            raise ValueError('Unknown action')
        self.save()
        return self.snapshot()

LAB = None
class LocalServer(ThreadingHTTPServer):
    # Windows must not let two runtimes share a port and serve different saves.
    allow_reuse_address = False

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args): pass
    def reply(self, status, data, mime='application/json'):
        self.send_response(status)
        self.send_header('Content-Type', mime)
        self.send_header('Cache-Control', 'no-store')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.end_headers()
        self.wfile.write(data if isinstance(data, bytes) else json.dumps(data).encode())
    def trusted(self):
        host = self.headers.get('Host','')
        return host in {f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}'}
    def do_GET(self):
        if not self.trusted(): return self.reply(403, {'error':'Local access only'})
        path = unquote(urlparse(self.path).path)
        try:
            if path == '/api/state':
                with LAB.lock: return self.reply(200, LAB.snapshot())
            if path.startswith('/asset/'):
                asset = (ROOT / path[len('/asset/'):]).resolve()
                if not asset.is_relative_to(ROOT / 'Media') and not asset.is_relative_to(ROOT / 'Fonts'):
                    return self.reply(403, {'error':'Asset outside media folders'})
                if asset.suffix == '.tga':
                    out = io.BytesIO(); Image.open(asset).save(out, format='PNG')
                    return self.reply(200, out.getvalue(), 'image/png')
                return self.reply(200, asset.read_bytes(), 'font/ttf' if asset.suffix == '.ttf' else 'image/png')
            name = {'/':'index.html','/app.js':'app.js','/style.css':'style.css'}.get(path)
            if not name: return self.reply(404, {'error':'Not found'})
            return self.reply(200, (HERE/name).read_bytes(), {'index.html':'text/html; charset=utf-8','app.js':'text/javascript; charset=utf-8','style.css':'text/css; charset=utf-8'}[name])
        except Exception as e: self.reply(500, {'error':str(e)})
    def do_POST(self):
        origin = self.headers.get('Origin')
        if not self.trusted() or (origin and origin not in {f'http://{self.headers.get("Host")}'}):
            return self.reply(403, {'error':'Local access only'})
        if self.path != '/api/action': return self.reply(404, {'error':'Not found'})
        try:
            length = int(self.headers.get('Content-Length','0'))
            if length > 16384: raise ValueError('Request too large')
            data = json.loads(self.rfile.read(length))
            with LAB.lock: result = LAB.action(data)
            self.reply(200, result)
        except Exception as e: self.reply(400, {'error':str(e)})

if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--port', type=int, default=8765); parser.add_argument('--no-browser', action='store_true')
    args = parser.parse_args()
    LAB = Lab()
    server = LocalServer(('127.0.0.1', args.port), Handler)
    url = f'http://127.0.0.1:{args.port}'
    print(f'Forever Goal Tracker workbench: {url}\nDraft source: {ROOT}\nCtrl+C to stop.', flush=True)
    if not args.no_browser: webbrowser.open(url)
    try: server.serve_forever()
    except KeyboardInterrupt: server.server_close()

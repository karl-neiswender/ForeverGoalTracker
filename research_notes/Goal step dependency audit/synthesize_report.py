import collections, csv, json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = pathlib.Path(__file__).resolve().parent
OUT = ROOT / 'reports'
OUT.mkdir(exist_ok=True)
def read(name):
    return json.loads((BASE/name).read_text(encoding='utf-8'))
inventory = read('addresses.json')
def address(value):
    if isinstance(value,int) or str(value).isdigit(): return 'steps[%s]' % value
    if str(value).startswith(('steps[','sections[')): return str(value)
    match = re.fullmatch(r'(\d+)_(\d+)_(piece|m(\d+))',str(value))
    assert match, value
    s,p,kind,m=match.groups()
    return f'sections[{s}].pieces[{p}]' + (f'.materials[{m}]' if m else '')
expected={}
for g in inventory['Forever']:
    for a in g['addresses']:
        ident=g['id']+':'+address(a['key'])
        assert ident not in expected
        expected[ident]=(g,a)
records=[]
ownership={}
input_counts={}
for filename in ('quest_step_audit.json','parallel_step_audit.json','raid_set_step_audit.json'):
    document=read(filename)
    rows=document['records'] if isinstance(document,dict) else document
    input_counts[filename]={'goals':len({r['goalId'] for r in rows}),'addresses':len(rows)}
    for raw in rows:
        r=dict(raw)
        ident=r['goalId']+':'+address(r['address'])
        assert ident in expected, ('unowned',ident)
        assert ident not in ownership, ('duplicate',ident)
        ownership[ident]=filename
        g,a=expected[ident]
        assert r['text']==a['text'], ('mismatched text',ident,r['text'],a['text'])
        r['address']=address(r['address'])
        r['id']=ident
        r['rawKey']=a['key']
        r['kind']=a['kind']
        r['countedTask']=a.get('counted',True)
        r['originalStatus']=r['status']
        r['status']={'no_lock':'no_lock','candidate':'candidate','unknown':'withheld'}[r['status']]
        r['originalSources']=r.pop('sources')
        r['sourceURLs']=[('https://github.com/karl-neiswender/ForeverGoalTracker/blob/main/'+s.split('/')[-1]) if s.startswith('../') else s for s in r['originalSources']]
        r['provenance']=filename
        r['requiresAll']=[r['goalId']+':'+address(v) for v in r['requiresAll']]
        r['requiresAny']=[r['goalId']+':'+address(v) for v in r['requiresAny']]
        r['productionReady']=False
        r['productionReadiness']='Research recommendation only; candidate edges need matching character/quest or instance evidence and current client verification.'
        r['externalPredicateNotes']=r.get('structuredPredicateNotes','')
        if 'missingPrerequisite' in r:
            r['externalPredicateNotes']=json.dumps(r['missingPrerequisite'],ensure_ascii=False)
        r['autoRule']=a.get('auto')
        records.append(r)
assert set(ownership)==set(expected), ('missing',set(expected)-set(ownership))
refs=0
for r in records:
    for ref in r['requiresAll']+r['requiresAny']:
        assert ref in expected, ('dangling',r['id'],ref)
        assert ref!=r['id'], ('self dependency',ref)
        refs+=1
    assert all(isinstance(s,str) and s.startswith('https://') for s in r['sourceURLs'])
    assert r['sourceURLs'], ('unsourced',r['id'])
# Direct row candidates form a DAG. External active-quest requirements are deliberately
# not converted to completed-row edges (notably Charger 7643/7645).
graph={r['id']:r['requiresAll']+r['requiresAny'] for r in records}
visiting=set(); visited=set()
def visit(node):
    assert node not in visiting, ('cycle',node)
    if node in visited:return
    visiting.add(node)
    for dep in graph[node]:visit(dep)
    visiting.remove(node);visited.add(node)
for key in graph:visit(key)
era={g['id']+':'+address(a['key']):a for g in inventory['Era'] for a in g['addresses']}
assert set(era)==set(expected)
variants=[]
for r in records:
    old=era[r['id']];new=expected[r['id']][1]
    if old['text']!=new['text']:
        r['clientTexts']={'Era':old['text'],'Forever':new['text']}
        variants.append(r['id'])
counts=collections.Counter(r['status'] for r in records)
task_counts=collections.Counter(r['status'] for r in records if r['countedTask'])
assert len(inventory['Forever'])==79 and len(records)==1177
assert sum(r['countedTask'] for r in records)==1105
assert sum(not r['countedTask'] for r in records)==72
validation={'researchDate':'2026-10-08','passed':True,'goalCount':79,'rawAddressCount':1177,'countedTaskCount':1105,'uncountedTier3Parents':72,'inputCounts':input_counts,'statusCountsRaw':dict(counts),'statusCountsCountedTasks':dict(task_counts),'missingAddresses':0,'duplicateAddresses':0,'unownedAddresses':0,'mismatchedTexts':0,'danglingReferences':0,'selfDependencies':0,'rowDependencyCycles':0,'validatedRowReferences':refs,'EraForeverAddressSetsMatch':True,'clientTextVariants':variants,'productionEdgesImplemented':0,'meaning':'Complete classification coverage including deliberate withheld decisions; coverage does not establish all external gameplay predicates or validate the incoming Forever build.'}
def write_json(name,data): (OUT/name).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8',newline='\n')
write_json('Goal step dependency audit.validation.json',validation)
write_json('Goal step dependency audit.json',{'researchDate':'2026-10-08','purpose':'Research only; do not import as production dependency edges','addressSyntax':'goalId:steps[n] or goalId:sections[s].pieces[p][.materials[m]], original one-based saved source positions','statusDefinitions':{'no_lock':'Available collection/milestone or soft/contextual ordering; no hard row lock recommended. External gameplay eligibility can still exist.','candidate':'Source-supported Classic dependency candidate, conditional on evidence/scope and client verification; not production-ready.','withheld':'Guide correction, missing condition, conflicting source or unverified client/access/vendor behavior prevents an asserted row lock.'},'logicalSemantics':'requiresAll = AND row-completion candidates; requiresAny = OR row-completion candidates, potentially joined by alternativeConditions. External quest acceptance/completion, eligibility and instance conditions stay in externalPredicateNotes/notes/missingPrerequisite. Empty arrays are not proof of unrestricted gameplay.','validation':validation,'records':records})
columns=['id','goalId','address','rawKey','kind','countedTask','text','status','requiresAll','requiresAny','scope','confidence','sourceURLs','notes','externalPredicateNotes','alternativeConditions','classification','productionReady','provenance']
with (OUT/'Goal step dependency audit.csv').open('w',newline='',encoding='utf-8-sig') as f:
    writer=csv.DictWriter(f,fieldnames=columns,lineterminator='\n')
    writer.writeheader()
    for r in records:
        writer.writerow({k:json.dumps(r[k],ensure_ascii=False) if isinstance(r.get(k),(dict,list)) else r.get(k,'') for k in columns})
bygoal=collections.defaultdict(list)
for r in records:bygoal[r['goalId']].append(r)
OVERVIEWS={
'ashbringer':'Entry/loot candidates; personal earlier-wing kill history does not prove present raid access.',
'frostsaber':'Repeatable farming stays available; quest thresholds and purchase eligibility need client verification; Classic level58 conflicts with current40.',
'atiesh':'Frame then parallel head/base then both; purification row must say accept before its entity kill.',
'rhokdelar':'String and demon/stave branches can overlap; final combine needs stave AND string; Stoma turn-in correction.',
'lokdelar':'Leaf/start unlocks all four demons together; all four heads then reward.',
'thunderfury':'Either binding starts quest; both bindings AND bars AND Essence summon; raw ingredients remain parallel.',
'benediction':'Divinity unlocks event; Shadow gathering is independent; final combine needs three components.',
'sulfuras':'Eye/materials parallel; purchasing hammer bypasses personal plans/material/crafting route.',
'mount_dreadsteed':'Correct unrelated Kroshius row and missing ritual branches before locking; Imp Delivery and Arcanite converge.',
'mount_charger':'Horse feed completes before Equine Spirit completion; active7643 predicate; disputed7641 ordering withheld.',
'quelserrar':'Blade heating/treatment/return chain; timed item state and current detector correction needed.',
'att_mc':'Quest/fragment final return; attunement is raid entrance shortcut, not universal MC access requirement.',
'att_ony_ally':'Same Alliance character quest chain; compressed True Masters requires final quest proof.',
'att_ony_horde':'Emberstrife unlocks three skull quests together; all three unlock Axtroz.',
'att_bwl':'Command and boss can be worked independently; final brand requires quest and cleared boss; shortcut only.',
'att_naxx':'Same character level60 AND Honored-or-better; tier-specific quest/cost alternatives.',
'key_ubrs':'Condensed collection/forging chain; party key availability is not personal ownership prerequisite.',
'key_scholo':'Single row hides faction quest chain; no fabricated earlier-row gate.',
'key_brd':'Second Dark Iron Legacy follows first; ghost start and Ironfel remain external detail.',
'key_strat':'Independent single boss-drop collection; other party keys bypass entrance ownership.',
'key_dm':'Independent single Pusillin collection; other party keys bypass entrance ownership.',
'epicmounts':'Level, rep and savings parallel; native race OR Exalted candidate; purchase/use/riding differences withheld.',
'social_guild':'Membership/tabard design purchase conditions need verification; membership historical tick is insufficient.',
'mount_deathcharger':'Kill/loot candidate; level60 preparation is not mandatory kill gate; item proof overrides missed encounter.',
'mount_raptor':'Kill/loot candidate; no full Zul\'Gurub completion requirement.',
'mount_tiger':'Kill/loot candidate; no full Zul\'Gurub completion requirement.',
'mount_qiraji':'Scepter/event/crystal route unverified in Forever; realm event conditions external.',
'raid_mc':'First eight bosses available; Majordomo all-of plus doused runes; raid-instance evidence required.',
'raid_ony':'Personal amulet entry candidate; final row detects head ownership rather than turn-in completion.',
'raid_bwl':'Attunement shortcut only; conventional boss order withheld as hard lock pending access proof.',
'raid_zg':'No hard priest-clear gate for Hakkar; optional summons need external conditions.',
'raid_aq20':'Kurinnaxx/Rajaxx candidate; optional Moam/Buru/Ayamiss never gate Ossirian.',
'raid_aq40':'Optional Bug Trio/Viscidus/Ouro never gate C\'Thun; main-route access edges withheld.',
'raid_naxx':'Four independent wings; entry fans out; four wing ends converge on Sapphiron then Kel\'Thuzad.',
'raid_hyjal':'New Forever boss access unknown; no inferred locks.',
'raid_barrow':'New Forever boss access unknown; no inferred locks.',
'tier3':'285 material tasks parallel;72 parent rows uncounted; Echoes of War missing for future turn-in gating.',
'set_dungeon2':'Four reward stages per class;1/2/3/2 rewards per stage; same-character quest proof over item ticks.',
'set_forever_raid':'54 alternative-role collection pieces parallel; sources/access unconfirmed.',
'set_viper':'Five collection pieces independent; no boss order locks.',
}
def overview(g):
    ident=g['id']
    if ident in OVERVIEWS:return OVERVIEWS[ident]
    if ident.startswith('pvp_set_'):return 'Independent pieces; per-character vendor rank candidates unconfirmed in Forever.'
    if ident.startswith(('pvp_rank14_','pvp_mount_','pvp_avmount_')):return 'Milestones remain available; purchaser rank/reputation gate withheld pending current vendor evidence.'
    if ident in ('set_tier1','set_tier2','set_dungeon1'):return 'All72 pieces collected independently; no earlier piece or personal boss-history lock.'
    return 'All current milestones/parts available in parallel; no ascending-threshold or sibling-order locks.'
table=['| Goal ID | Goal | Raw / tasks | No lock / candidate / withheld | Research treatment |','|---|---|---:|---:|---|']
for g in inventory['Forever']:
    rs=bygoal[g['id']];c=collections.Counter(r['status'] for r in rs)
    table.append(f"| `{g['id']}` | {g['name']} | {len(rs)} / {sum(r['countedTask'] for r in rs)} | {c['no_lock']} / {c['candidate']} / {c['withheld']} | {overview(g)} |")
(BASE/'per_goal_overview.md').write_text('\n'.join(table)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(validation,indent=2))

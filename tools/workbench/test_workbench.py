"""Integration tests of real addon logic through the offline adapter."""
import tempfile, unittest
from pathlib import Path
from unittest.mock import patch
import server
from server import Lab

class WorkbenchTests(unittest.TestCase):
    def setUp(self): self.lab = Lab(persist=False)
    def goal(self, state, goal='thunderfury'):
        return next(g for g in state['goals'] if g['id']==goal)
    def action(self, kind, **kw):
        return self.lab.action({'action':kind,'goal':'thunderfury',**kw})

    def test_real_tick_reset_undo_and_expiry(self):
        self.assertEqual(self.goal(self.lab.snapshot())['done'], 0)
        self.assertEqual(self.goal(self.action('toggle',key=2))['done'], 1)
        reset=self.action('reset'); self.assertEqual(self.goal(reset)['done'],0)
        self.assertEqual(reset['undo']['seconds'],10)
        self.assertEqual(self.goal(self.action('reset'))['done'],1)
        self.action('reset'); self.lab.started-=11
        self.assertIsNone(self.lab.snapshot().get('undo'))

    def test_note_rules_and_reload_keep_progress(self):
        with self.assertRaises(ValueError): self.action('note',text='   ')
        with self.assertRaises(ValueError): self.action('note',text='x'*241)
        self.action('note',text='Bring a friend |cff00ff00 literal text')
        self.action('toggle',key=2)
        reloaded=self.action('reload')
        self.assertEqual(self.goal(reloaded)['done'],1)
        self.assertEqual(self.goal(reloaded)['note'],'Bring a friend |cff00ff00 literal text')
        self.assertEqual(self.goal(self.action('deleteNote'))['note'],'')

    def test_real_auto_rules_and_group_material_counts(self):
        s=self.action('fixture',fixture='loot')
        self.assertEqual(self.goal(s)['done'],self.goal(s)['total'])
        s=self.action('track',goal='tier3')
        g=self.goal(s,'tier3')
        checkboxes=[r for r in g['rows'] if r['kind']=='step']
        self.assertTrue(len(checkboxes)>0)
        self.assertEqual(len(checkboxes),g['total'])
        s=self.action('toggle',goal='tier3',key=checkboxes[0]['key'])
        self.assertEqual(self.goal(s,'tier3')['done'],1)
        with self.assertRaises(ValueError): self.action('toggle',key='bogus')

    def test_disk_save_is_separate_and_restart_restores_it(self):
        runtime=(server.HERE/'runtime.lua').read_text(encoding='utf-8')
        with tempfile.TemporaryDirectory() as directory:
            here=Path(directory)
            (here/'runtime.lua').write_text(runtime,encoding='utf-8')
            with patch.object(server,'HERE',here):
                self.lab.persist=True
                self.action('note',text='Keep this offline note')
                self.action('toggle',key=2)
                restarted=Lab()
                self.assertEqual(self.goal(restarted.snapshot())['note'],'Keep this offline note')
                self.assertEqual(self.goal(restarted.snapshot())['done'],1)
                self.assertTrue((here/'.state/session.lua').is_file())

    def test_failed_reload_retains_working_runtime(self):
        self.action('toggle',key=2)
        old=self.lab.rt
        with patch.object(self.lab,'reload',side_effect=RuntimeError('Draft syntax error')):
            with self.assertRaises(RuntimeError): self.action('reload')
        self.assertIs(self.lab.rt,old)
        self.assertEqual(self.goal(self.lab.snapshot())['done'],1)

if __name__=='__main__': unittest.main()

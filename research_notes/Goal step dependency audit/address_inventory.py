import json,pathlib
P=pathlib.Path(__file__).resolve().parent
C=json.loads((P/'catalogue.json').read_text(encoding='utf-8'))
def array(x):return x if isinstance(x,list) else []
def step(x):return x if isinstance(x,dict) else {'text':x}
def rows(g):
    r=[]
    for i,s in enumerate(array(g.get('steps')),1):
        s=step(s);r.append({'key':i,'kind':'step','text':s.get('text'),'auto':s.get('auto')})
    for si,section in enumerate(array(g.get('sections')),1):
        for pi,piece in enumerate(array(section.get('pieces')),1):
            r.append({'key':f'{si}_{pi}_piece','kind':'piece','section':si,'piece':pi,'sectionName':section['name'],'text':piece.get('text',piece.get('name')),'auto':piece.get('auto'),'counted':not bool(array(piece.get('materials')))})
            for mi,m in enumerate(array(piece.get('materials')),1):r.append({'key':f'{si}_{pi}_m{mi}','kind':'material','section':si,'piece':pi,'material':mi,'sectionName':section['name'],'text':m,'counted':True})
        for ti,s in enumerate(array(section.get('steps')),1):r.append({'key':f'{si}_{ti}','kind':'section-step','section':si,'text':step(s).get('text')})
    return r
out={client:[{'id':g['id'],'name':g['name'],'category':g['category'],'faction':g.get('faction'),'forever':g.get('forever'),'needs':g.get('needs'),'addresses':rows(g)} for g in goals] for client,goals in C.items()}
(P/'addresses.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8',newline='\n')
owned=lambda g:g['category'] in ['Raid','Item Set'] or g['id'].startswith('pvp_set_')
lines=['# Expanded raid and set addresses','', 'Every raw catalogue goal is retained, including parts hidden by the UI. Address keys follow Core.lua MaterialKey/PieceKey; ordinary step keys are numbers. Counted rows exclude the parent Tier 3 piece because PieceProgress counts its materials only. Research date: 2026-10-08.','']
for g in out['Forever']:
    if not owned(g):continue
    lines.extend(['## '+g['id']+' — '+g['name'],'','| Key | Type | Exact current text |','|---|---|---|'])
    for r in g['addresses']:lines.append('| '+str(r['key'])+' | '+r['kind']+' | '+str(r['text']).replace('|','\\|')+' |')
    lines.append('')
(P/'raid_set_addresses.md').write_text('\n'.join(lines),encoding='utf-8',newline='\n')
for client,goals in out.items():
    print(client,'goals',len(goals),'all-addresses',sum(len(g['addresses']) for g in goals))
    os=[g for g in goals if owned(g)]
    print('owned',len(os),'addresses',sum(len(g['addresses']) for g in os),'counted',sum(sum(r.get('counted',True) for r in g['addresses']) for g in os))
    print([(g['id'],len(g['addresses'])) for g in os])

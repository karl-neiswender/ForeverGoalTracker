import json,pathlib
P=pathlib.Path(__file__).resolve().parent
C=json.loads((P/'addresses.json').read_text(encoding='utf-8'))['Forever']
src={
 'raid_mc':'https://www.wowhead.com/classic/guide/majordomo-executus-molten-core-strategy-wow-classic',
 'raid_ony':'https://www.wowhead.com/classic/news/molten-core-onyxias-lair-attunement-wow-classic-353602',
 'raid_bwl':'https://www.wowhead.com/classic/guide/blackwing-lair-raid-overview-classic-wow',
 'raid_zg':'https://www.wowhead.com/classic/npc=14834/hakkar-the-soulflayer',
 'raid_aq20':'https://www.wowhead.com/classic/zone=3429/ruins-of-ahnqiraj',
 'raid_aq40':'https://www.wowhead.com/classic/zone=3428/ahnqiraj',
 'raid_naxx':'https://www.wowhead.com/classic/npc=15989/sapphiron',
 'set_dungeon1':'https://www.wowhead.com/classic/guide/dungeon-sets-1-2-quests-wow-classic',
 'set_dungeon2':'https://www.wowhead.com/classic/guide/dungeon-sets-1-2-quests-wow-classic',
 'tier3':'https://www.wowhead.com/classic/guide/naxxramas-tier-3-armor-set-wow-classic',
 'set_forever_raid':'https://www.wowhead.com/forever/guide/raids-overview-hub-dates-locations',
}
owned=lambda g:g['category'] in ['Raid','Item Set'] or g['id'].startswith('pvp_set_')
out=[]
for g in C:
 if not owned(g):continue
 for a in g['addresses']:
  gid,k=g['id'],a['key']
  r={'goalId':gid,'address':k,'text':a['text'],'kind':a['kind'],'countedTask':a.get('counted',True),'status':'no_lock','requiresAll':[],'requiresAny':[],'scope':'same class section for sets; independent collection','confidence':'high for collection independence, unconfirmed Forever equivalence','sources':[src.get(gid,'../../Library.lua')],'notes':'No item-collection prerequisite on another set piece. Auto-completed ownership overrides locks.'}
  if g['category']=='Raid':
   r.update(scope='shared raid instance; personal historical roster ticks are insufficient',notes='No verified hard lock. Normal boss route does not imply a required encounter gate.')
   if gid in ['raid_hyjal','raid_barrow']:r.update(status='unknown',confidence='unconfirmed',sources=[src['set_forever_raid']],notes='Current single known boss; entrance, attunement and preceding encounter gates unknown.')
   edges={'raid_mc':{10:list(range(2,10)),11:[10]},'raid_ony':{2:[1],3:[2]},'raid_naxx':{2:[1],5:[1],8:[1],11:[1],15:[4,7,10,14],16:[15]},'raid_aq20':{2:[1]}}
   if k in edges.get(gid,{}):
    r.update(status='candidate',requiresAll=edges[gid][k],confidence='Classic-supported; conditional on instance/character evidence',notes='Candidate guide dependency only. A prerequisite may have been completed by the raid before this player joined. Never block recording completed evidence.')
   if gid=='raid_mc' and k==10:r['notes']+=' Dousing runes is additional missing raid-state evidence.'
   if gid=='raid_ony' and k==2:r['notes']+=' Amulet must belong to the entering character, not merely another roster alt.'
   if gid=='raid_ony' and k==3:r['notes']+=' Current step merges head loot and turn-in; auto item rule proves ownership, not quest turn-in.'
   if gid in ['raid_mc','raid_bwl'] and k==1:r['notes']='Attunement shortcut only; does not hard-gate the boss steps.';r['sources']=['https://www.wowhead.com/classic/guide/classic-wow-attunements-and-keys-dungeons-raids']
   if gid=='raid_zg':r['notes']='All current bosses independent for tracker locks. Priest kills weaken Hakkar rather than make him accessible; optional bosses never gate him.'
   if gid=='raid_aq40':r['notes']='Main route1->3->4->6->7->9 is advice; exact physical access gates unverified. Optional2/5/8 never gate9.'
   if gid=='raid_bwl' and k!=1:r.update(status='unknown',notes='Mostly linear route2->3->4->5->6->7->8->9; individual drake/door required-kill gates unverified. No production lock until verified.')
   if gid=='raid_aq20' and k>=3:r['notes']='Optional3/4/5 do not gate6. Exact access after1/2 needs verification; leave unlocked.'
  if gid=='tier3':
   r.update(scope='same piece materials; tradeable collection independent',notes='All existing material rows collect independently. Echoes of War9033 is missing from the current goal; it gates crafting quests, not gathering. Parent piece is auto-owned metadata and has no manual checkbox.',missingPrerequisite={'quest':9033,'name':'Echoes of War','appliesTo':'future crafting/turn-in task only'})
  if gid=='set_dungeon2':
   si,pi=a['section'],a['piece']
   prev={4:[7],6:[7],2:[4,6],5:[4,6],8:[4,6],1:[2,5,8],3:[2,5,8]}.get(pi,[])
   r.update(scope='same class AND same questing character, faction-specific variants',confidence='Classic stage sequence supported; quest IDs/evidence missing',notes='Conditional reward-stage guidance only. Quest completion, not item possession, proves eligibility. Matching D1 slot is consumed. Full D1 set is unnecessary; same-stage rewards unlock together.',missingPrerequisite={'questStage':{7:1,4:2,6:2,2:3,5:3,8:3,1:4,3:4}[pi],'questVariantIds':'not enumerated','matchingDungeon1Piece':f'set_dungeon1:{si}_{pi}_piece'})
   if prev:r.update(status='candidate',requiresAll=[f'{si}_{j}_piece' for j in prev])
   r['sources'] += ['https://www.wowhead.com/classic/quest=8906/an-earnest-proposition','https://www.wowhead.com/classic/quest=8931/just-compensation','https://www.wowhead.com/classic/quest=8952/anthions-parting-words','https://www.wowhead.com/classic/quest=9000/saving-the-best-for-last']
  if gid.startswith('pvp_set_'):
   r.update(status='unknown',confidence='rank inferred from name; Forever purchase eligibility unconfirmed',scope='same faction/class purchasing character; merged role alternatives',notes='No piece-to-piece prerequisites. Candidate rank by slot1/3=13,2/5=12,4=10,6=9; do not implement hard rank locks without verified Forever rules.',missingPrerequisite={'rankCandidate':{1:13,2:12,3:13,4:10,5:12,6:9}[a['piece']]})
  if gid=='set_forever_raid':r.update(status='unknown',notes='No piece-to-piece locks; boss drops and access prerequisites not confirmed.')
  out.append(r)
assert len(out)==878
assert len({(r['goalId'],str(r['address'])) for r in out})==878
(P/'raid_set_step_audit.json').write_text(json.dumps(out,indent=2,ensure_ascii=False),encoding='utf-8',newline='\n')
summary={'catalogueGoals':len(C),'rawAddresses':sum(len(g['addresses']) for g in C),'countedTasks':sum(sum(a.get('counted',True) for a in g['addresses']) for g in C),'raidSetGoals':sum(owned(g) for g in C),'raidSetRawAddresses':len(out),'raidSetCountedTasks':sum(r['countedTask'] for r in out),'ownedIDs':[g['id'] for g in C if owned(g)],'semantics':'raw includes72 uncounted Tier3 parent-piece addresses; other raw piece parents with materials are likewise uncounted. Counted means PieceProgress weighting, not number of UI headers. The complete catalogue retains hidden goals/parts.'}
(P/'inventory_assertions.json').write_text(json.dumps(summary,indent=2),encoding='utf-8',newline='\n')
print(json.dumps(summary,indent=2))

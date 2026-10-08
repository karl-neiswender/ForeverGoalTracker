let state, tab='tracker', selected, busy=false, previousDone=new Set(), previousWidths=new Map();
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const list=x=>Array.isArray(x)?x:Object.values(x||{});
function text(s){return esc(String(s??'').replace(/\|c[0-9a-f]{8}/gi,'').replace(/\|r/g,'').replace(/\|H[^|]*\|h(.*?)\|h/g,'$1').replace(/\|T.*?\|t/g,'').replace(/\{item:\d+:([^}]+)\}/g,'$1').replace(/\{[^:}]+:([^}]+)\}/g,'$1').replace(/\.$/,''));}
function goal(){return state.goals.find(g=>g.id===selected)||state.goals[0];}
async function action(action,extra={}){
  try {const r=await fetch('/api/action',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,goal:selected,...extra})});const result=await r.json();if(!r.ok)throw Error(result.error);if(action==='checks')return result;state=result;selected=state.selected;render();return result;}
  catch(e){status(e.message,true);throw e;}
}
function status(message,error=false){$('#status').textContent=message;$('#status').classList.toggle('error',error);}
function render(){
  const oldWidths=previousWidths;
  const query=$('#search').value.toLowerCase();
  $('#goals').innerHTML=state.goals.filter(g=>(tab==='library'||g.active)&&g.name.toLowerCase().includes(query)).map(g=>`<button class="goal ${g.id===selected?'selected':''}" data-goal="${esc(g.id)}"><span class="goalName">${esc(g.name)}</span><span class="meta">${esc(g.category)} · ${esc(g.difficulty||'')}</span><div class="bar"><div class="fill" style="width:${g.total?100*g.done/g.total:0}%"></div></div></button>`).join('')||'<p style="padding:15px">No goals here. Browse the Goal Library.</p>';
  const g=goal();if(!g)return;
  const undo=state.undo?.goal===g.id&&state.undo.seconds>0;
  let lastSection='';
  const rows=list(g.rows).map(r=>{let section='';if(r.section&&r.section!==lastSection){lastSection=r.section;section=`<h3 class="sectionTitle">${esc(r.section)}</h3>`;}if(r.kind==='heading')return section+`<div class="pieceTitle">${text(r.text)}</div>`;return section+`<button class="step ${r.done?'done':''}" data-key="${esc(r.key)}" ${g.autoLevels?'disabled':''}><span class="box">${r.done?`<img class="${previousDone.has(g.id+':'+r.key)?'steady':''}" src="/asset/Media/icons/check.tga" alt="Complete">`:''}</span><span>${text(r.text)}${r.automatic?'<span class="automatic" title="This step can be completed by the addon’s real automatic rules">AUTO</span>':''}</span></button>`;}).join('');
  $('#detail').innerHTML=`<div class="detailTop"><div><div class="category">${esc(g.category).toUpperCase()}</div><h2>${esc(g.name)}</h2></div><div class="detailActions"><button class="icon" id="editNote" title="${g.note?'Edit':'Add'} personal note"><img src="/asset/Media/icons/note.tga" alt="Personal note"></button>${g.autoLevels?'':`<button class="icon" id="reset" title="${undo?`Undo reset (${state.undo.seconds}s remaining)`:'Reset this goal'}"><img src="/asset/Media/icons/${undo?'refresh':'refresh-white'}.tga" alt="${undo?'Undo reset':'Reset goal'}"></button>`}</div></div><div class="chips"><span class="chip">${esc(g.difficulty||'').toUpperCase()}</span><span class="chip">${esc(g.duration||'')}</span></div><p class="description">${text(g.description)}</p>${g.note?`<p class="personal"><strong>NOTE:</strong> ${esc(g.note)}</p>`:''}${g.forever?`<div class="forever"><img src="/asset/Media/forever.tga" alt="">${text(g.forever)}</div>`:''}${!g.active?'<button class="gold" id="track">Add to My Goals · all parts</button>':''}<div class="progress"><div class="bar"><div class="fill" style="width:${g.total?100*g.done/g.total:0}%"></div></div><p>${g.done} / ${g.total} · ${g.total?Math.round(100*g.done/g.total):0}%</p></div><div class="steps">${rows}</div>${list(g.tips).length?`<div class="tips"><h3>Tips</h3><ul>${list(g.tips).map(t=>`<li>${text(typeof t==='string'?t:t.text||'')}</li>`).join('')}</ul></div>`:''}`;
  $('#source').textContent='Draft source: '+state.checkout;$('#source').title=state.checkout;
  $('#fixture').value=state.fixture;
  previousWidths=new Map(state.goals.map(g=>[g.id,g.total?100*g.done/g.total:0]));
  previousDone=new Set(state.goals.flatMap(g=>list(g.rows).filter(r=>r.done).map(r=>g.id+':'+r.key)));
  document.querySelectorAll('[data-goal] .fill').forEach(el=>{const id=el.closest('[data-goal]').dataset.goal;animateBar(el,oldWidths.get(id),previousWidths.get(id));});
  animateBar($('#detail .progress .fill'),oldWidths.get(g.id),previousWidths.get(g.id));
}
function animateBar(el,from,to){if(!el||from===undefined||from===to)return;el.style.transition='none';el.style.width=from+'%';requestAnimationFrame(()=>requestAnimationFrame(()=>{if(el.isConnected){el.style.transition='';el.style.width=to+'%';}}));}
$('#goals').onclick=async e=>{const b=e.target.closest('[data-goal]');if(b)await action('select',{goal:b.dataset.goal});};
$('#detail').onclick=async e=>{const b=e.target.closest('button');if(!b)return;if(b.dataset.key){const old=goal().done;await action('toggle',{key:b.dataset.key});status(`Step ${goal().done>old?'completed':'cleared'} in real Lua`);}else if(b.id==='reset'){await action('reset');$('#reset')?.classList.add('spin');status(state.undo?'Reset saved. You have 10 seconds to undo.':'Progress restored.');}else if(b.id==='editNote')openNote();else if(b.id==='track'){await action('track');status('Goal added to test tracker');}};
$('.mode').onclick=e=>{const b=e.target.closest('[data-tab]');if(!b)return;tab=b.dataset.tab;document.querySelectorAll('[data-tab]').forEach(x=>x.classList.toggle('active',x===b));render();};
$('#search').oninput=render;
function openNote(){const g=goal();$('#noteGoal').textContent=g.name;$('#noteText').value=g.note;$('#deleteNote').disabled=!g.note;noteCount();$('#notes').showModal();$('#noteText').focus();}
function noteCount(){let chars=Array.from($('#noteText').value);if(chars.length>240){$('#noteText').value=chars.slice(0,240).join('');chars=chars.slice(0,240);}$('#count').textContent=`${chars.length} / 240 characters`;$('#saveNote').disabled=!$('#noteText').value.trim();}
$('#noteText').oninput=noteCount;
$('#closeNote').onclick=()=>$('#notes').close();
$('#notes').onclick=e=>{if(e.target===$('#notes'))$('#notes').close();};
$('#saveNote').onclick=async()=>{await action('note',{text:$('#noteText').value});$('#notes').close();status('Personal note saved in the test session');};
$('#deleteNote').onclick=async()=>{await action('deleteNote');$('#notes').close();status('Personal note deleted');};
$('#reload').onclick=async()=>{await action('reload');status('Draft Lua reloaded. Test progress kept.');};
$('#applyFixture').onclick=async()=>{await action('fixture',{fixture:$('#fixture').value});status('Test roster loaded. Automatic rules applied. Existing ticks stay checked.');};
$('#checks').onclick=async()=>{if(busy)return;busy=true;$('#checks').disabled=true;status('Running the addon’s Lua checks…');try{const result=await action('checks');$('#checkOutput').textContent=result.output;$('#results').showModal();status(result.ok?'Lua checks passed':'Lua checks found a problem',!result.ok);}finally{busy=false;$('#checks').disabled=false;}};
$('#closeResults').onclick=()=>$('#results').close();
async function poll(){try{const r=await fetch('/api/state');if(!r.ok)throw Error('Workbench unavailable');const next=await r.json();if(!state){state=next;selected=state.selected;render();status('Ready · draft changes stay off main');}else{state.undo=next.undo;const b=$('#reset');if(b){const undo=next.undo?.goal===selected&&next.undo.seconds>0;b.title=undo?`Undo reset (${next.undo.seconds}s remaining)`:'Reset this goal';b.querySelector('img').src=`/asset/Media/icons/${undo?'refresh':'refresh-white'}.tga`;}}}catch(e){status(e.message,true);}}
poll();setInterval(poll,500);

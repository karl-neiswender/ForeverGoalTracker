// Reads Wowhead Forever's "Latest Community Findings" list (the items and quests
// players have just found), as JSON. Run it in the browser's console, or through
// the built-in browser, while looking at https://www.wowhead.com/forever.
//
// Use it by hand, at most once a day: it reads the page you already loaded, so it
// makes no extra requests. Save the result as reports/audit/findings-YYYY-MM-DD.json
// and run tools/findings.py to compare it with the addon's data.
(() => {
  const heads = [...document.querySelectorAll('*')].filter(e => e.children.length === 0 && /Latest Community Findings/.test(e.textContent));
  let root = heads[0];
  for (let i = 0; i < 6 && root; i++) {
    if (root.querySelectorAll('a[href*="/forever/item="], a[href*="/forever/quest="]').length > 3) break;
    root = root.parentElement;
  }
  const seen = new Set(), rows = [];
  root.querySelectorAll('a[href*="/forever/item="], a[href*="/forever/quest="], a[href*="/forever/npc="], a[href*="/forever/spell="], a[href*="/forever/zone="]').forEach(a => {
    const m = a.getAttribute('href').match(/\/forever\/(item|quest|npc|spell|zone)=(\d+)\/?([^?#]*)/);
    if (!m) return;
    const key = m[1] + m[2];
    if (seen.has(key)) return;
    seen.add(key);
    const age = (a.textContent.trim().match(/(\d+[hdwm]) ago/) || [])[1] || null;
    rows.push({ kind: m[1], id: +m[2], slug: m[3], age });
  });
  return JSON.stringify({ fetched: new Date().toISOString(), source: location.href, count: rows.length, rows });
})()

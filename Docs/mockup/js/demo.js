"use strict";
/* RaidKit Buffs mockup: display mode, demo mode, simulated debuffs (= BarVisibility.lua, BarDemo.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// = ns.SHOW_MODES (2026-11-09): where the bar is shown. While it is shown it replaces the Blizzard buff bar
// (buffs and debuffs); elsewhere the Blizzard bar stays. With the options window open the bar is always shown.
const SHOW_MODES = [
  { key: "never", label: L("Never") },
  { key: "always", label: L("Always") },
  { key: "party", label: L("Party") },
  { key: "group", label: L("Party + Raid") },
  { key: "raid", label: L("Raid") },
];
// = ns:BarModeActive(): does the display mode apply right now? (party = group without raid)
function modeActive() {
  const m = (barLayout || profile).showMode || "group", g = sim.group;
  return m === "always" ? true : m === "party" ? g === "party" : m === "raid" ? g === "raid" : m === "group" ? g !== "solo" : false;
}
const barWanted = () => sim.optionsOpen || modeActive() || !!demo; // demo shows the bar too (2026-11-10)

/* ----- Demo mode (= ns:StartDemo in Bar.lua, 2026-11-10): fake buffs/debuffs for at most 60 s ----- */
const DEMO_BUFFS = [
  { id: 25315, name: "Renew", icon: "spell_holy_renew", dur: 15 },
  { id: 25299, name: "Rejuvenation", icon: "spell_nature_rejuvenation", dur: 12 },
  { id: 9858, name: "Regrowth", icon: "spell_nature_resistnature", dur: 21 },
  { id: 10901, name: "Power Word: Shield", icon: "spell_holy_powerwordshield", dur: 30 },
  { id: 12970, name: "Flurry", icon: "ability_ghoulfrenzy", dur: 15 },
  { id: 12880, name: "Enrage", icon: "spell_shadow_unholyfrenzy", dur: 12 },
  { id: 20007, name: "Holy Strength", icon: "spell_holy_blessingofstrength", dur: 15 },
  { id: 28866, name: "Kiss of the Spider", icon: "inv_trinket_naxxramas04", dur: 15 },
  { id: 24427, name: "Diamond Flask", icon: "inv_drink_01", dur: 60 },
  { id: 10060, name: "Power Infusion", icon: "spell_holy_powerinfusion", dur: 15 },
];
const DEMO_DEBUFFS = [
  { id: 6788, name: "Weakened Soul", icon: "spell_holy_ashestoashes", dur: 15 },
  { id: 11717, name: "Curse of Recklessness", icon: "spell_shadow_unholystrength", dur: 120, type: "Curse" },
  { id: 10894, name: "Shadow Word: Pain", icon: "spell_shadow_shadowwordpain", dur: 18, type: "Magic" },
  { id: 11201, name: "Crippling Poison", icon: "ability_poisonsting", dur: 12, type: "Poison" },
  { id: 23170, name: "Brood Affliction: Bronze", icon: "inv_misc_head_dragon_bronze", dur: 0 },
  { id: 12294, name: "Mortal Strike", icon: "ability_warrior_savageblow", dur: 10 },
];
const DEMO_SECONDS = 60;
let demo = null, demoTimer = null;
function demoAdd(list, defs, t) {
  const free = defs.filter((d) => !list.some((a) => a.id === d.id));
  if (!free.length) return;
  const d = free[Math.floor(Math.random() * free.length)];
  list.push(Object.assign({}, d, { demo: true, exp: d.dur > 0 ? t + d.dur : Infinity }));
}
// = DemoFree() in Bar.lua: the demo never shows more buffs than the cap allows
const demoFree = () => BUFF_CAP - activeAuras(now()).length - (demo ? demo.buffs.length + demo.nRows : 0);
function demoRefresh() { updateAll(); if (typeof updateDemoButton === "function") updateDemoButton(); }
function demoTick() {
  if (!demo) return;
  const t = now();
  if (t >= demo.end) return stopDemo();
  for (const list of [demo.buffs, demo.debuffs]) for (let i = list.length - 1; i >= 0; i--) if (list[i].exp <= t) list.splice(i, 1);
  // "here and there": a new buff roughly every 2 s, a debuff every 4 s
  if (demo.buffs.length < 8 && demoFree() > 0 && Math.random() < 0.5) demoAdd(demo.buffs, DEMO_BUFFS, t);
  if (demo.debuffs.length < 4 && Math.random() < 0.25) demoAdd(demo.debuffs, DEMO_DEBUFFS, t);
  // an unwanted buff comes back now and then, so the red button can be tried again
  if (demoFree() > 0 && Math.random() < 0.1) demoAdd(demo.buffs, demo.unwantedDefs, t);
  demoRefresh();
}
// = DemoRowExp in Bar.lua (user 2026-11-10): world buffs 30 min to 1:45 h, at most their real duration
// (Songflower, Rend: 1 h); every other row icon 5 to 55 minutes
function demoRowExp(entry, t) {
  const b = typeof entry === "number" ? BUFF_BY_ID[entry] : null;
  const rnd = (a, z) => a + Math.floor(Math.random() * (z - a + 1));
  if (b && b.cat === "world") return t + Math.min(rnd(30, 105), b.dur > 0 ? Math.floor(b.dur / 60) : 105) * 60;
  return t + rnd(5, 55) * 60;
}
function startDemo() {
  if (demo) return;
  const t = now();
  if (sim.combat) return print(L("The demo only starts out of combat."));
  // = DemoUnwantedDefs() in Bar.lua: demo versions of the unwanted buffs that are not really active
  const real = new Set(activeAuras(t).map(String));
  const unwantedDefs = (profile.unwanted || []).map((id) => BUFF_BY_ID[id]).filter((b) => b && !b.spells.some((s) => real.has(String(s))))
    .map((b) => ({ id: b.spells[0], name: b.name, icon: b.icon, dur: b.dur || 1800 }));
  demo = { end: t + DEMO_SECONDS, buffs: [], debuffs: [], rows: {}, nRows: 0, unwantedDefs };
  // 5 to 20 inactive non-weapon icons of the rows look active (world buffs included), 5 to 55 minutes left, world buffs 30 min to 1:45 h (demoRowExp);
  // room stays for 2 unwanted and 4 other demo buffs, nothing beyond the cap
  const cand = barButtons.filter((b) => b.classList.contains("missing") && !isWeaponEntry(b._entry));
  // every group gets at least one active icon (user 2026-11-19), so the budget covers one per group (+1 for the long
  // world buff), still never beyond the cap (= StartDemo in BarDemo.lua)
  const grpOf = (b) => b.parentElement && b.parentElement._g;
  const groups = new Set(cand.map(grpOf).filter(Boolean));
  let nRows = Math.max(Math.min(Math.max(5 + Math.floor(Math.random() * 16), groups.size + 1), cand.length, demoFree() - 6), 0);
  const filled = new Set();
  // always one 2-hour world buff with more than 100 minutes left (user 2026-11-14; = StartDemo in Bar.lua)
  const long = cand.filter((b) => { const w = typeof b._entry === "number" ? BUFF_BY_ID[b._entry] : null; return w && w.cat === "world" && (w.dur || 0) >= 7200; });
  if (long.length && nRows > 0) {
    const b = long[Math.floor(Math.random() * long.length)];
    cand.splice(cand.indexOf(b), 1);
    demo.rows[b.dataset.key] = t + (101 + Math.floor(Math.random() * 19)) * 60;
    demo.nRows++; nRows--; filled.add(grpOf(b));
  }
  for (const g of groups) {
    if (filled.has(g) || nRows <= 0) continue;
    const mine = cand.filter((b) => grpOf(b) === g), b = mine[Math.floor(Math.random() * mine.length)];
    cand.splice(cand.indexOf(b), 1);
    demo.rows[b.dataset.key] = demoRowExp(b._entry, t);
    demo.nRows++; nRows--;
  }
  for (let i = 0; i < nRows; i++) {
    const b = cand.splice(Math.floor(Math.random() * cand.length), 1)[0];
    demo.rows[b.dataset.key] = demoRowExp(b._entry, t);
    demo.nRows++;
  }
  for (let i = 0; i < 2; i++) if (demoFree() > 0) demoAdd(demo.buffs, unwantedDefs, t);
  for (let i = 0; i < 4; i++) if (demoFree() > 0) demoAdd(demo.buffs, DEMO_BUFFS, t);
  for (let i = 0; i < 2; i++) demoAdd(demo.debuffs, DEMO_DEBUFFS, t);
  demoTimer = setInterval(demoTick, 1000);
  print(fmt(L("Demo running (at most 1 minute): %d row icons active, other and unwanted buffs and debuffs come and go. Right-click removes only demo buffs, real ones stay; the X removes the unwanted ones. Clicking again or closing the options window ends it."), demo.nRows));
  buildBar(); demoRefresh();
}
function stopDemo() {
  if (!demo) return;
  demo = null; clearInterval(demoTimer); demoTimer = null;
  print(L("Demo ended."));
  buildBar(); demoRefresh();
}
const toggleDemo = () => (demo ? stopDemo() : startDemo());
// = ns:DemoAddBuffs in Bar.lua (user 2026-11-10): button "Buffs hinzufügen" fills the buff slots step by step, so the
// colour of the bar can be checked. Each click takes a random kind (all kinds, user 2026-11-10): an inactive row icon
// (elixir, potion, food, world buff ...), an unwanted buff (transformation ...) or a buff for "Sonstige".
// Everything lasts until the demo ends.
function demoAddBuffs(n) {
  if (!demo) return;
  const pick = (a) => a[Math.floor(Math.random() * a.length)];
  for (let i = 0; i < n && demoFree() > 0; i++) {
    const rows = barButtons.filter((b) => b.classList.contains("missing") && !isWeaponEntry(b._entry) && !demo.rows[b.dataset.key]);
    const unw = demo.unwantedDefs.filter((d) => !demo.buffs.some((a) => a.id === d.id));
    const kinds = [...(rows.length ? ["row"] : []), ...(unw.length ? ["unw"] : []), "other"];
    const kind = pick(kinds);
    if (kind === "row") {
      const b = pick(rows);
      demo.rows[b.dataset.key] = demoRowExp(b._entry, now());
      demo.nRows++;
      updateAll(); // the icon turns active, so the next pick sees it
      continue;
    }
    let pool = unw;
    if (kind === "other") {
      pool = DEMO_BUFFS.filter((d) => !demo.buffs.some((a) => a.id === d.id));
      if (!pool.length) pool = DEMO_BUFFS;
    }
    demo.buffs.push(Object.assign({}, pick(pool), { demo: true, exp: demo.end + 1, dur: 0 })); // ends with the demo: no yellow timer
  }
  demoRefresh();
}
const demoLeft = () => (demo ? Math.max(Math.ceil(demo.end - now()), 0) : null);
function removeDemoAura(a) {
  if (!demo) return;
  for (const list of [demo.buffs, demo.debuffs]) { const i = list.indexOf(a); if (i >= 0) list.splice(i, 1); }
  hideTip(); demoRefresh();
}
// debuffs only for the simulation (shown by RaidKit Buffs while it replaces the Blizzard bar)
const DEBUFF_SIM = [
  { id: 11717, name: "Curse of Recklessness", icon: "spell_shadow_unholystrength", type: "Curse", dur: 120 },
  { id: 6788, name: "Weakened Soul", icon: "spell_holy_ashestoashes", type: null, dur: 15 },
  { id: 11201, name: "Crippling Poison", icon: "ability_poisonsting", type: "Poison", dur: 12 },
  { id: 23170, name: "Brood Affliction: Bronze", icon: "inv_misc_head_dragon_bronze", type: null, dur: 0 },
  { id: 10894, name: "Shadow Word: Pain", icon: "spell_shadow_shadowwordpain", type: "Magic", dur: 18 },
];
// = DebuffTypeColor in the game
const DEBUFF_COLOR = { Magic: "rgb(51,153,255)", Curse: "rgb(153,0,255)", Disease: "rgb(153,102,0)", Poison: "rgb(0,153,0)", none: "rgb(204,0,0)" };

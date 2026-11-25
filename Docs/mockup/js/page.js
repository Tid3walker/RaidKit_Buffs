"use strict";
/* RaidKit Buffs mockup: hosts, bags, simulation toolbar, start.
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Hosts ===================== */
// The Blizzard options only show a button that opens the own window (the content is too wide).
const hostWindow = document.getElementById("hostWindow"), hostSettings = document.getElementById("hostSettings");
hostWindow.style.width = (CONTENT_W + 8) + "px"; hostWindow.style.height = (CONTENT_H + 34) + "px"; // = Options.lua window:SetSize
function attach(host, x, y) { content.style.left = x + "px"; content.style.top = y + "px"; host.appendChild(content); }
function showWindowView() {
  hostSettings.style.display = "none"; hostWindow.style.display = "";
  document.getElementById("viewWindow").classList.add("on"); document.getElementById("viewSettings").classList.remove("on");
}
document.getElementById("viewWindow").addEventListener("click", showWindowView);
document.getElementById("viewSettings").addEventListener("click", (e) => {
  hostWindow.style.display = "none"; hostSettings.style.display = "";
  e.target.classList.add("on"); document.getElementById("viewWindow").classList.remove("on");
});
document.getElementById("openOptions").addEventListener("click", showWindowView);

/* ===================== Bags ===================== */
function renderBag() {
  const bag = document.getElementById("bag");
  bag.innerHTML = "";
  const ids = [13452, 12460, 20452, 3825, 13445, 21151, 18269, 13455, 13458, 13457, 13510, 9206, 12451, 20079, 13928, 21023, 10310, 8410, 6948];
  for (const id of ids) {
    const s = mk("div", "slot ic");
    setIcon(s, id);
    s.title = itemInfo(id).name + " (" + id + ")";
    // same drag as a catalog line (2026-11-22, user: the old HTML5 drag only reached the hidden item grid, so dropping
    // into the rows of a group did nothing); = an item on the cursor from a bag in the game
    s.addEventListener("mousedown", (e) => startPending(e, id, "catalog"));
    bag.appendChild(s);
  }
}

/* ===================== Toolbar ===================== */
document.getElementById("btnCombat").addEventListener("click", (e) => {
  sim.combat = !sim.combat;
  // PLAYER_REGEN_DISABLED (attributes still changeable): all buttons usable, except Flask/Zanza already active
  sim.locked = new Set(sim.combat ? barButtons.filter((b) => isFlaskEntry(b._entry) && activeVariant(b._entry)).map(btnKey) : []);
  updateAll();
  e.target.textContent = P(sim.combat ? "Combat: on" : "Combat: off");
  e.target.classList.toggle("on", sim.combat);
  screenEl.classList.toggle("combat", sim.combat);
  if (!sim.combat && sim.pending) requestRebuild();
  if (!sim.combat) lossReportCombatEnd(); // losses of a boss fight in the chat (loss-report.js)
  updateMover();
});
document.getElementById("btnAllOn").addEventListener("click", () => {
  const t = now();
  for (const row of activeRows()) for (const en of row.items) applyEntry(en);
  updateAll();
});
document.getElementById("btnAllOff").addEventListener("click", () => { Object.keys(sim.auras).forEach(cancelAura); updateAll(); });
// applies the chosen variant of an entry with a random rest duration
function applyEntry(en) {
  const id = entPick(en), i = itemInfo(id);
  if (i.isBuff) applyAura(i.buff, i.dur ? i.dur * (0.3 + Math.random() * 0.7) : 0);
  else if (i.dur) applyAura(auraOfItem(id), i.dur * (0.3 + Math.random() * 0.7));
}
// typical raid start: world buffs first (hours before), then consumables, raid buffs, a bit of everything
document.getElementById("btnRaid").addEventListener("click", () => {
  const rows = activeRows().filter((r) => !r.hidden && r.name !== L("Protection") && r.name !== L("Situational"));
  const isWorld = (r) => r.name === L("World Buffs");
  const order = [...rows.filter(isWorld), ...rows.filter((r) => !isWorld(r))];
  for (const row of order) for (const en of row.items) applyEntry(en);
  for (const sp of [10157, 27841, 25898, 25895, 19900, 20906]) { const b = SPELL_INFO[sp].buffEntry; applyAura(sp, b.dur ? b.dur * 0.8 : 0); }
  applyAura(25315, 15);
  print(P("Raid situation: world buffs, consumables, raid buffs, Int/Spirit (unwanted), blessings, aura, Renew."));
  updateAll();
});
document.getElementById("btnProcs").addEventListener("click", () => {
  const pool = OTHER_SIM.filter((o) => o.proc).sort(() => Math.random() - 0.5).slice(0, 4);
  for (const o of pool) applyAura(o.buff, o.dur);
  print("Procs: " + pool.map((o) => o.name).join(", "));
  updateAll();
});
// mount (2026-11-17): mount up on a random mount (dur 0 like in the game), again = dismount
document.getElementById("btnMount").addEventListener("click", () => {
  const t = now(), on = MOUNT_SIM.find((m) => sim.auras[m.buff] > t);
  if (on) { delete sim.auras[on.buff]; print(P("Dismounted.")); }
  else { const pool = MOUNT_SIM.filter((m) => !!m.aq === (sim.zone === "aq40")), m = pool[Math.floor(Math.random() * pool.length)]; applyAura(m.buff, 0); print(P("Mounted: ") + m.name); }
  updateAll();
});
// zone (2026-11-19): in AQ40 the mount icon offers a Qiraji crystal (red first), elsewhere the first 100 % mount
document.getElementById("btnZone").addEventListener("click", (e) => {
  sim.zone = sim.zone === "aq40" ? "world" : "aq40";
  e.target.textContent = P(sim.zone === "aq40" ? "Zone: AQ40" : "Zone: world");
  e.target.classList.toggle("on", sim.zone === "aq40");
  updateAll();
});
// debuffs: two random ones (shown by RaidKit Buffs only while it replaces the Blizzard bar)
document.getElementById("btnDebuff").addEventListener("click", () => {
  const t = now();
  for (const d of DEBUFF_SIM.filter((x) => !(sim.debuffs[x.id] > t)).sort(() => Math.random() - 0.5).slice(0, 2)) {
    sim.debuffs[d.id] = d.dur ? t + d.dur : Infinity;
  }
  updateAll();
});
// Windfury Totem on the main hand (working assumption: the stone stays and pauses meanwhile)
document.getElementById("btnWf").addEventListener("click", (e) => {
  sim.wf = !sim.wf;
  e.target.textContent = P(sim.wf ? "Windfury: on" : "Windfury: off");
  e.target.classList.toggle("on", sim.wf);
  updateAll();
});
// off hand with or without a weapon (two-hander / shield)
document.getElementById("btnOffhand").addEventListener("click", (e) => {
  sim.offhand = !sim.offhand;
  if (!sim.offhand) sim.weapon.off = null;
  e.target.textContent = P(sim.offhand ? "Off hand: weapon" : "Off hand: none");
  e.target.classList.toggle("on", sim.offhand);
  updateAll();
});
// = GROUP_ROSTER_UPDATE: solo -> group -> raid; the display mode decides who shows the buffs
const GROUP_LABEL = { solo: "Group: Solo", party: "Group: Party", raid: "Group: Raid" };
document.getElementById("btnGroup").addEventListener("click", (e) => {
  sim.group = sim.group === "solo" ? "party" : sim.group === "party" ? "raid" : "solo";
  e.target.textContent = P(GROUP_LABEL[sim.group]);
  e.target.classList.toggle("on", sim.group !== "solo");
  requestRebuild();
});
// = /rkb opens the window: bar always shown, outline + preview visible, plain dragging moves
document.getElementById("btnOptOpen").addEventListener("click", (e) => {
  sim.optionsOpen = !sim.optionsOpen;
  e.target.textContent = P(sim.optionsOpen ? "Options window: open" : "Options window: closed");
  e.target.classList.toggle("on", sim.optionsOpen);
  // opening always starts on the group "Buffs & Cons" (user, session 20; "Alle Gruppen" from 2026-11-14) = OnShow in Options.lua
  if (sim.optionsOpen) { selectedGroup = "main"; refreshOptions(); }
  if (!sim.optionsOpen && demo) stopDemo(); // closing the window ends the demo too (user 2026-11-10)
  requestRebuild();
});
document.getElementById("btnRefill").addEventListener("click", () => { for (const k in sim.counts) sim.counts[k] = 5; updateAll(); });
document.getElementById("btnEmpty").addEventListener("click", () => { for (const k in sim.counts) sim.counts[k] = 0; updateAll(); });
let timeFactor = 1;
document.getElementById("btnFast").addEventListener("click", (e) => {
  timeFactor = timeFactor === 1 ? 60 : 1; setTimeFactor(timeFactor);
  e.target.textContent = P("Time: " + timeFactor + "×"); e.target.classList.toggle("on", timeFactor !== 1);
});
// items with default alternatives (user 2026-11-10): the catalog line shows the icon of the first one
// (= line.alt in Options.lua); the tooltip lists all of them with icons
// icon (2026-11-20): an icon name instead of alternatives (buff of a trinket / trigger of a proc, buffLink)
function setAltMark(el, alts, icon) {
  const src = alts && alts.length ? ICON_URL(itemInfo(alts[0]).icon) : icon ? ICON_URL(icon) : null;
  el.style.display = src ? "" : "none";
  el.style.backgroundImage = src ? `url(${src})` : "none";
}
document.getElementById("btnReset").addEventListener("click", () => { resetAll(); buildBar(); updateAll(); refreshOptions(); print(P("Mockup reset.")); });
document.getElementById("btnExamples").addEventListener("click", addExampleProfiles);
window.addEventListener("resize", positionBar);

/* ===================== Start ===================== */
resetAll();
createContent();
attach(hostWindow, 4, 28);
renderBag();
buildBar();
updateAll();
refreshOptions();
setInterval(updateAll, 500);
print(P("Mockup loaded. Ctrl+click uses an item, right-click removes the buff."));
// = fresh install in Core.lua (user 2026-11-10): no SavedVariables yet -> the options open at the first login
// (the mockup never keeps anything, so every load counts as one)
setTimeout(() => { if (!sim.optionsOpen) document.getElementById("btnOptOpen").click(); print(L("Welcome! This is where you set up RaidKit Buffs. By default the bar replaces the Blizzard buff bar only in raids (button \"Show\" at the top of this window). /rkb opens this window again.")); }, 500);

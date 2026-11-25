"use strict";
/* RaidKit Buffs mockup: loss report (= Core/LossReport.lua, user 2026-11-24). Collects what the loss alarm reported
   (lossAlarm in core.js, not the test) and repeats it in the chat: after a boss fight (as soon as combat is off) the
   losses of that fight, when leaving the raid instance every loss of the visit. Toolbar: "Boss" (= ENCOUNTER_START /
   ENCOUNTER_END, switches combat on/off with it) and "Instance" (= PLAYER_ENTERING_WORLD inside / outside a raid).
   Part of raidkit_buffs.html, loaded in order by js/boot.js. */

const MOCK_BOSS = "Kel'Thuzad", MOCK_RAID = "Naxxramas"; // names come from the game client, never translated
let encounter = null;                                    // { name, losses, ended }
let raidLog = { instance: MOCK_RAID, list: [] };          // the mockup starts inside the raid ("Group: Raid")

// the game shows a clickable item link; the mockup a white [Name]
function lossItemText(name) { return "|cffffffff[" + name + "]|r"; }
function clockText() { const d = new Date(); return String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0"); }

function recordLoss(name, left) {
  const boss = encounter && !encounter.ended ? encounter.name : null;
  if (boss) encounter.losses.push({ name, left });
  if (raidLog.instance) raidLog.list.push({ name, left: Math.floor(left), at: clockText(), boss });
}
function printEncounter() {
  const e = encounter;
  encounter = null;
  if (!e || !e.losses.length) return;
  const parts = e.losses.map((l) => fmt(L("%s (%s left)"), lossItemText(l.name), fmtTimeLong(l.left)));
  print(fmt(L("Lost during %s: %s"), e.name, parts.join(", ")));
}
function encounterStart(name) { encounter = { name, losses: [] }; }
function encounterEnd() {
  if (!encounter) return;
  encounter.ended = true;
  if (!sim.combat) printEncounter(); // else at the end of combat (lossReportCombatEnd)
}
function lossReportCombatEnd() { if (encounter && encounter.ended) printEncounter(); }

function printRaid(log) {
  if (!log.list.length) { print(fmt(L("No consumable lost in %s."), log.instance)); return; }
  print(fmt(L("Consumables lost in %s: %d"), log.instance, log.list.length));
  for (const l of log.list) {
    let line = fmt(L("%s %s, %s left"), l.at, lossItemText(l.name), fmtTimeLong(l.left));
    if (l.boss) line += " (" + l.boss + ")";
    print(line);
  }
}
// = OnLossReportZone: entering starts the list, leaving prints and clears it
function lossReportZone(inRaid) {
  if (inRaid) { if (!raidLog.instance) raidLog = { instance: MOCK_RAID, list: [] }; return; }
  if (raidLog.instance) { printRaid(raidLog); raidLog = { instance: null, list: [] }; }
}

/* ===================== Toolbar ===================== */
function setCombat(on) { if (sim.combat !== on) document.getElementById("btnCombat").click(); }
document.getElementById("btnBoss").addEventListener("click", (e) => {
  const on = !(encounter && !encounter.ended);
  if (on) { encounterStart(MOCK_BOSS); setCombat(true); } else { encounterEnd(); setCombat(false); }
  e.target.textContent = P(on ? "Boss: Kel'Thuzad" : "Boss: off");
  e.target.classList.toggle("on", on);
});
document.getElementById("btnInstance").addEventListener("click", (e) => {
  const inRaid = !raidLog.instance;
  lossReportZone(inRaid);
  e.target.textContent = P(inRaid ? "Instance: Naxxramas" : "Instance: outside");
  e.target.classList.toggle("on", inRaid);
});

"use strict";
/* RaidKit Buffs mockup: tooltip.
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Tooltip ===================== */
const tip = document.getElementById("tip");
function placeTip(e) {
  tip.style.display = "block";
  tip.style.left = Math.min(e.clientX + 14, window.innerWidth - 300) + "px";
  tip.style.top = (e.clientY + 14) + "px";
}
function showBarTip(e, b) {
  if (!b) return;
  const en = b._entry, id = shownVariant(en), info = itemInfo(id), st = itemBuffState(id), t = now();
  if (isWeaponEntry(en)) {
    const ws = weaponEntryState(en), hand = HAND_NAME[en.hand];
    // texts = WeaponButton_OnEnter in Bar.lua
    const state = ws.wf ? `<div class="g">${L("Windfury (totem) active - takes priority over the stone")}</div>`
      : ws.noWeapon ? `<div class="r">${L("No weapon in the off hand")}</div>`
      : ws.active ? `<div class="g">${fmt(L("Active - %s left"), fmtTimeLong(ws.exp - t))}</div>`
      : ws.other ? `<div class="y">${fmt(L("Other enchant: %s"), itemInfo(ws.other).name)}</div>` : `<div class="r">${L("Missing")}</div>`;
    const alts = en.v.map((v) => `<div class="${v === en.pick ? "y" : "w"}">${v === en.pick ? "▶ " : "&nbsp;&nbsp;&nbsp;"}${itemInfo(v).name} <span class="${sim.counts[v] ? "d" : "r"}">(${sim.counts[v] || 0})</span></div>`).join("");
    const ut = useTarget(en);
    const use = sim.combat ? L("Ctrl+click: not in combat") : ws.wf ? L("Ctrl+click: locked (Windfury)") : ws.noWeapon ? L("Ctrl+click: nothing (no weapon)")
      : ws.active ? L("Ctrl+click: nothing (already active)") : !ut ? L("Ctrl+click: nothing in the bags") : fmt(L("Ctrl+click: %s on the %s"), itemInfo(ut).name, hand);
    tip.innerHTML = `<div class="n">${fmt(L("Weapon: %s"), hand)}</div><br><div class="y">${fmt(L("RaidKit Buffs: %s (slot %d)"), hand, en.hand === "main" ? 16 : 17)}</div>${state}<div class="w">${L("Variants:")}</div>${alts}<br>` +
      `<div class="d">${use}</div>${isSlot(en) && en.v.length > 1 ? `<div class="d">${L("Mouse wheel: switch variant")}</div>` : ""}<div class="d">${L("Shift+right-click: options")}</div>`;
    return placeTip(e);
  }
  const status = st.active ? `<div class="g">${st.exp === Infinity ? L("Active") : fmt(L("Active - %s left"), fmtTimeLong(st.exp - t))}</div>` : `<div class="r">${L("Missing")}</div>`;
  if (info.mount) {
    // mount (2026-11-19, = BuffButton_OnEnter): riding = the mount's buff; not riding = the item Ctrl+click mounts
    // (item tooltip in the game), no "Missing" (a mount is not a missing buff)
    const m = st.active ? null : mountPick(), riding = st.active && st.sp ? spellInfo(st.sp).name : null;
    const use = st.active ? "" : sim.combat ? L("Ctrl+click: not in combat") : m ? L("Ctrl+click: mount up") : noMountText();
    tip.innerHTML = `<div class="n">${riding || (m ? m.itemName || m.name : info.name)}</div><div class="d">(${m ? "Item" : "Buff"}-Tooltip)</div><div class="b">${L(info.note)}</div><br>` +
      `${st.active ? status : `<div class="d">${L("Not mounted")}</div>`}<br>${use ? `<div class="d">${use}</div>` : ""}` +
      `${st.active ? `<div class="d">${L("Right-click: dismount")}</div>` : ""}<div class="d">${L("Shift+right-click: options")}</div>`;
    return placeTip(e);
  }
  if (info.isBuff) {
    // buff slot (mage armors, 2026-11-15; = BuffButton_OnEnter): variants with the chosen one, Ctrl+click casts that one
    const pk = itemInfo(entPick(en)), own = isOwnBuff(pk) ? pk : null;
    const alts = isSlot(en) ? `<br><div class="w">${L("Alternatives:")}</div>` + en.v.map((v) => `<div class="${v === en.pick ? "y" : "w"}">${v === en.pick ? "▶ " : "&nbsp;&nbsp;&nbsp;"}${itemInfo(v).name}${itemBuffState(v).active ? ` <span class="g">${L("active")}</span>` : ""}</div>`).join("") : "";
    tip.innerHTML = `<div class="n">${info.name}</div><div class="d">(Buff-Tooltip)</div><div class="b">${info.note ? L(info.note) : ""}</div><br>${status}${alts}<br>` +
      `<div class="d">${own ? fmt(L("Ctrl+click: cast %s"), own.name) : L("Foreign buff - Ctrl+click does nothing")}</div>` +
      `${isSlot(en) ? `<div class="d">${L("Mouse wheel: switch variant")}</div>` : ""}` +
      `${st.active ? `<div class="d">${L("Right-click: remove buff")}</div>` : ""}<div class="d">${L("Shift+right-click: options")}</div>`;
    return placeTip(e);
  }
  let slot = "";
  if (isSlot(en)) {
    slot = `<br><div class="w">${L("Alternatives:")}</div>` + en.v.map((v) => {
      const a = itemBuffState(v).active, c = sim.counts[v] || 0;
      return `<div class="${v === en.pick ? "y" : "w"}">${v === en.pick ? "▶ " : "&nbsp;&nbsp;&nbsp;"}${itemInfo(v).name} <span class="${c ? "d" : "r"}">(${c})</span>${a ? ` <span class="g">${L("active")}</span>` : ""}</div>`;
    }).join("");
  }
  let use = "";
  if (barLayout.useMode === "ctrl") {
    const ut = useTarget(en);
    if (sim.combat && sim.locked.has(btnKey(b))) use = L("Ctrl+click: locked until combat ends (was active when combat started)");
    else if (!sim.combat && activeVariant(en)) use = L("Ctrl+click: nothing (buff already active)");
    else if (!ut) use = L("Ctrl+click: nothing in the bags");
    else use = fmt(L(ut !== entPick(en) ? "Ctrl+click: %s (substitute)" : "Ctrl+click: %s"), itemInfo(ut).name);
  }
  tip.innerHTML = `<div class="n">${info.name}</div><div class="d">(Item-Tooltip)</div><br>${status}
    <div class="w">${fmt(L("In bags: %d"), sim.counts[id] || 0)}</div>${slot}<br>${use ? `<div class="d">${use}</div>` : ""}${isSlot(en) ? `<div class="d">${sim.combat ? L("Mouse wheel: switch variant (not in combat)") : L("Mouse wheel: switch variant")}</div>` : ""}${st.active ? `<div class="d">${L("Right-click: remove buff")}</div>` : ""}<div class="d">${L("Shift+drag: move bar")}</div><div class="d">${L("Shift+right-click: options")}</div>`;
  placeTip(e);
}
// tooltip right of an icon (grid / fold-out column), so it never covers the column below the icon
function placeTipBeside(el) {
  const r = el.getBoundingClientRect();
  tip.style.display = "block";
  tip.style.left = Math.min(r.right + 8, window.innerWidth - 300) + "px";
  tip.style.top = r.top + "px";
}
function hideTip() { tip.style.display = "none"; }

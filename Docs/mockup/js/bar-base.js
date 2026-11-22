"use strict";
/* RaidKit Buffs mockup: bar helpers: style, timers, weapon enchants, secure macros, row layout (= BarBase.lua, BarButtons.lua, BarStyle.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Bar (Bar.lua) ===================== */
const BORDER = { active: "rgb(51,230,51)", missing: "rgb(89,89,89)", empty: "rgb(204,38,38)" };

/* ----- Style (proposal 2026-11-14, user; mockup only, Lua later) -----
   Three sections: frame (background + border of a group frame), sep (separator line), icon (icon borders).
   profile.style[sec] = values of "Alle Gruppen" (only what was changed; the rest comes from STYLE_DEF);
   g.style[sec] = own values of a group, value by value (only what was changed at the group; second round 2026-11-14).
   Resolved: STYLE_DEF < profile.style < g.style. Shown/hidden: frame = texture or border not "none" (since 2026-11-15), g.separator / g.showBorders.
   STYLE_DEF is the look before 2026-11-14, so nothing changes for existing profiles. */
const STYLE_DEF = {
  frame: { bgTex: "none", bgColor: "#28282e", bgAlpha: 0.85, edge: "none", edgeColor: "#6c6c78", edgeAlpha: 1, edgeSize: 1 },
  // fade (2026-11-15, user): which ends fade out, its own choice for every look ("none" | "left" | "right" | "both",
  // default "left"); before a look "fade" (both ends, solid only), converted by MigrateSepFade in Core.lua
  sep: { look: "solid", fade: "left", color: "#a0a0aa", alpha: 0.5, size: 1, inset: 0 },
  icon: { size: 1, active: "#33e633", missing: "#595959", unwanted: "#ff3030", other: "#555555" },
};
// = WoW backdrop files later (bgFile / edgeFile); in the mockup CSS imitations. Tinted with the chosen colour like
// SetVertexColor / SetBackdropColor.
const BG_TEXTURES = [
  { key: "none", label: () => L("None##texture") }, // no background (2026-11-15, user; default of "All Groups")
  { key: "solid", label: () => L("Solid") },
  { key: "gradient", label: () => L("Gradient") },
  { key: "dialog", label: () => L("Dialog (dark)") },
  { key: "marble", label: () => L("Marble") },
  { key: "parchment", label: () => L("Parchment") },
];
const EDGE_STYLES = [
  { key: "none", label: () => L("None") },
  { key: "flat", label: () => L("Flat line") },
  // "Double line" removed 2026-11-15 (user); an old "double" is shown as "flat" (Lua: SanitizeStyle)
  { key: "tooltip", label: () => L("Tooltip") },
  { key: "dialog", label: () => L("Dialog") },
];
const SEP_LOOKS = [
  { key: "solid", label: () => L("Solid") },
  { key: "dashed", label: () => L("Dashed") },
  { key: "dotted", label: () => L("Dotted") },
];
// which ends of the separator fade out (2026-11-15, user; = SEP_FADES in OptionsBars.lua). Vertical lines (a group
// docked at the side): left = top, right = bottom
const SEP_FADES = [
  { key: "none", label: () => L("No") },
  { key: "left", label: () => L("Left") },
  { key: "right", label: () => L("Right") },
  { key: "both", label: () => L("Both sides") },
];
// CSS mask of a faded line (half the length per end since 2026-11-15, user; a quarter, then a third were too short; = the gradient
// pieces of PlaceSeparator in BarStyle.lua)
const sepFadeMask = (fade, dir) => (fade === "left" ? `linear-gradient(${dir}, transparent, #000 50%)`
  : fade === "right" ? `linear-gradient(${dir}, #000 50%, transparent)`
  : fade === "both" ? `linear-gradient(${dir}, transparent, #000 50%, transparent)` : "none");
const hexA = (hex, a) => { const n = parseInt(hex.slice(1), 16); return `rgba(${n >> 16 & 255},${n >> 8 & 255},${n & 255},${a})`; };
const ownStyle = (g, sec) => !!(g && g.style && g.style[sec]);
// frame of a group (2026-11-15, user; = ns.FrameOn): texture or border other than "none"; either one makes the frame.
// "Unwanted Buffs" never (own button frame).
// = ns.NameAlign (2026-11-15, user): alignment of the group name only. Since session 20 (user: no "Automatic") the
// group's own value, else the default "right"
const nameAlignOf = (g) => (g && g.nameAlign) || "right";
const frameOn = (g) => { if (!g || g.area === "unw") return false; const st = styleOf(g, "frame"); return st.bgTex !== "none" || st.edge !== "none"; };
function styleOf(g, sec) {
  return Object.assign({}, STYLE_DEF[sec], ownStyle(g, sec) ? g.style[sec] : {}); // no "Alle Gruppen" level since session 20
}
// background layer of a frame: colour (with opacity) and the texture pattern on top
function frameCss(st) {
  const c = hexA(st.bgColor, st.bgAlpha), dark = hexA("#000000", st.bgAlpha * 0.45), light = hexA("#ffffff", st.bgAlpha * 0.06);
  const bg = {
    solid: c,
    gradient: `linear-gradient(${c}, ${dark}), ${c}`,
    dialog: `radial-gradient(ellipse at 50% 30%, ${light}, transparent 70%), linear-gradient(${dark}, ${dark}), ${c}`,
    marble: `repeating-linear-gradient(115deg, ${light} 0 2px, transparent 2px 9px), repeating-linear-gradient(35deg, ${dark} 0 1px, transparent 1px 13px), ${c}`,
    parchment: `radial-gradient(ellipse at 50% 50%, ${hexA("#fff4d0", st.bgAlpha * 0.18)}, ${hexA("#5a3a10", st.bgAlpha * 0.35)} 95%), ${c}`,
    none: "transparent", // no background, the border can show alone (2026-11-15)
  }[st.bgTex] || c;
  const e = hexA(st.edgeColor, st.edgeAlpha), n = st.edgeSize;
  const edge = {
    none: "none",
    flat: `0 0 0 ${n}px ${e}`,
    tooltip: `0 0 0 ${n}px rgba(0,0,0,.85), 0 0 0 ${2 * n}px ${e}, 0 0 ${2 * n + 2}px rgba(0,0,0,.6)`,
    dialog: `inset 0 0 0 1px rgba(0,0,0,.7), 0 0 0 ${n + 1}px ${e}, 0 0 0 ${n + 3}px rgba(0,0,0,.85), 0 0 0 ${n + 4}px ${hexA(st.edgeColor, st.edgeAlpha * 0.6)}`,
  }[st.edge === "double" ? "flat" : st.edge] || "none";
  return { background: bg, boxShadow: edge, borderRadius: st.edge === "tooltip" || st.edge === "dialog" ? "4px" : "2px" };
}
// how far the border of a framed group reaches outside its background (2026-11-15, user; = FrameOutset in Bar.lua): it
// counts towards the box, so the gap to snapped groups grows with the border thickness
function frameOutset(g) {
  if (!frameOn(g)) return 0;
  const st = styleOf(g, "frame"), n = st.edgeSize;
  return { none: 0, flat: n, tooltip: 2 * n, dialog: n + 4 }[st.edge === "double" ? "flat" : st.edge] || 0;
}
function applyFrameStyle(fr, g) { Object.assign(fr.style, frameCss(styleOf(g, "frame"))); }
// icon borders: CSS variables on the group element, read by .border (thickness, colours per state)
function applyIconStyle(el, g) {
  const st = styleOf(g, "icon");
  el.style.setProperty("--bw", st.size + "px");
  for (const k of ["active", "missing", "unwanted", "other"]) el.style.setProperty("--bc-" + k, st[k]);
}
const barEl = document.getElementById("bar"), screenEl = document.getElementById("screen");
let barButtons = [], extraEl = null;
// = FormatTime / FormatTimeLong in Bar.lua (2026-11-10): icon rounds up like Blizzard (1:59:59 = "2h"),
// tooltip and chat exact to the minute ("1 Std. 59 Min.")
// check / cross on the icons (user 2026-11-10: off; = SHOW_STATUS_MARKS in Bar.lua)
const SHOW_STATUS_MARKS = false;
// minutes from one minute on, also above an hour (2026-11-14, user; = FormatTime in Bar.lua)
const fmtTime = (s) => { s = Math.max(s, 0); return s > 60 ? Math.ceil(s / 60) + "m" : Math.ceil(s) + "s"; };
// remaining time with color (user 2026-11-12, = SetTimer in Bar.lua): at most 10 % of the full duration left = yellow;
// dur 0/undefined (unknown, debuffs, auras without duration) stays white
const LOW_TIME_SHARE = 0.10;
const isLowTime = (left, dur) => !!(dur > 0 && Math.max(left, 0) <= dur * LOW_TIME_SHARE);
const timerDiv = (exp, dur, t) => exp === Infinity ? `<div class="timer"></div>` : `<div class="timer${isLowTime(exp - t, dur) ? " low" : ""}">${fmtTime(exp - t)}</div>`;
const fmtTimeLong = (s) => {
  s = Math.max(s, 0);
  if (s < 60) return fmt(L("%d sec"), Math.ceil(s));
  const min = Math.floor(s / 60), h = Math.floor(min / 60), m = min % 60;
  return h === 0 ? fmt(L("%d min"), m) : m === 0 ? fmt(L("%d hr"), h) : fmt(L("%d hr %d min"), h, m);
};

const USE_MODE_FLASH = {
  off: L("Use is off (display only)"), // mockup-only texts (UIErrors flash of the simulation)
  ctrl: L("Nothing happens - Ctrl+click uses"),
};
// --- weapon enchants (proposal 2026-11-09) ---
// = what GetWeaponEnchantInfo() reports for a hand right now: Windfury wins on the main hand
function handState(hand) {
  const t = now();
  if (hand === "off" && !sim.offhand) return { noWeapon: true };
  if (hand === "main" && sim.wf) return { wf: true };
  const w = sim.weapon[hand];
  return w && w.exp > t ? { id: w.id, exp: w.exp, dur: w.dur } : {};
}
// state of a weapon entry: active when its hand carries one of its variants, or Windfury on the main hand
function weaponEntryState(en) {
  const hs = handState(en.hand);
  if (hs.wf) return { active: true, exp: Infinity, wf: true };
  if (hs.noWeapon) return { active: false, noWeapon: true };
  if (hs.id && en.v.includes(hs.id)) return { active: true, exp: hs.exp, id: hs.id, dur: hs.dur };
  return { active: false, other: hs.id };
}
// hands that a visible row covers (their enchants are not repeated under "Sonstige")
const coveredHands = () => new Set(barLayout.rows.flatMap((r) => r.items.filter(isWeaponEntry).map((e) => e.hand)));

// --- slot state (proposal) ---
const activeVariant = (en) => isWeaponEntry(en) ? weaponEntryState(en).id : entIds(en).find((id) => itemBuffState(id).active);
// what Ctrl+click would use: the chosen variant, else the next one in the bags (list order)
function useTarget(en) {
  const p = entPick(en);
  if (isBuffId(p)) return undefined; // buffs are not in the bags
  if ((sim.counts[p] || 0) > 0) return p;
  return entIds(en).find((id) => (sim.counts[id] || 0) > 0);
}
// icon in the bar: active variant, else what Ctrl+click would use, else the chosen one (red 0)
const shownVariant = (en) => activeVariant(en) ?? useTarget(en) ?? entPick(en);
const btnKey = (b) => b.dataset.key;

// left click (= Bar.lua: "ctrl-type1"; Shift is reserved for moving, "shift-type1" = macro without text)
// Proposal: out of combat the button is switched off while the buff (any variant) is active. In combat it
// always uses (attributes cannot change), except Flasks/Zanza that were active at the pull.
function onBarClick(e, b) {
  if (e.shiftKey) return;
  const en = b._entry;
  if (barLayout.useMode === "ctrl" && e.ctrlKey) {
    if (isWeaponEntry(en)) return useWeapon(en);
    if (sim.combat && sim.locked.has(btnKey(b))) return flash(L("Flask/Zanza was active at the pull - locked until combat ends"));
    const act = activeVariant(en);
    if (!sim.combat && act) return flash(fmt(L("%s is already active - nothing used (right-click removes the buff)"), itemInfo(act).name));
    // buff entries: foreign buffs cannot be used; own ones (Battle Shout) are cast (secure "spell" instead of "item")
    if (isBuffId(entMain(en))) {
      // a buff slot (mage armors, 2026-11-15) casts its chosen variant (= UpdateSecure in Bar.lua)
      const pk = itemInfo(entPick(en)), own = isOwnBuff(pk) ? pk : null;
      if (pk.mount) { // mount (2026-11-19): mounts mountPick(), only out of combat (= UpdateSecure in BarButtons.lua)
        const m = mountPick();
        if (sim.combat) return flash(L("Ctrl+click: not in combat"));
        if (!m) return flash(noMountText());
        applyAura(m.buff, 0); print(P("Mounted: ") + m.name); return updateAll();
      }
      if (!own) return flash(L("Foreign buff - cannot be used"));
      applyAura(own.buff, own.dur); print(fmt(L("%s cast."), own.name)); return updateAll();
    }
    const t = useTarget(en);
    if (!t) return print(L("No variant in the bags."));
    if (act && act !== t) for (const s of buffSpellsForItem(act)) cancelAura(s); // same buff place: overwritten
    return useItem(t);
  }
  flash(USE_MODE_FLASH[barLayout.useMode]);
}
// = secure macro "/use item:<id>" + "/use 16" (main hand) or "/use 17" (off hand); only out of combat
// (applying takes 3 s). Locked while Windfury is on the main hand: the stone would be wasted or block it.
function useWeapon(en) {
  const hs = handState(en.hand), ws = weaponEntryState(en);
  if (sim.combat) return flash(L("Weapon enchants only work out of combat"));
  if (hs.noWeapon) return flash(L("No weapon in the off hand"));
  if (ws.wf) return flash(L("Windfury active - the stone would be wasted (locked)"));
  if (ws.active) return flash(fmt(L("%s is already active on the %s"), itemInfo(ws.id).name, HAND_NAME[en.hand]));
  const t = useTarget(en);
  if (!t) return print(L("No variant in the bags."));
  sim.counts[t]--;
  sim.weapon[en.hand] = { id: t, exp: now() + itemInfo(t).dur, dur: itemInfo(t).dur };
  print(fmt(L("%s on the %s (/use %d)."), itemInfo(t).name, HAND_NAME[en.hand], en.hand === "main" ? 16 : 17));
  updateAll();
}
// right click (= "type2" macro "/cancelaura <buff>", in every mode; Shift+right-click = PostClick options)
function onBarRightClick(e, b) {
  e.preventDefault();
  if (e.shiftKey) { hideTip(); return document.getElementById("viewWindow").scrollIntoView({ behavior: "smooth" }); }
  // weapon: no removal (CancelItemTempEnchantment is risky for addons, PitBull avoids it too)
  if (isWeaponEntry(b._entry)) return flash(L("Weapon enchants cannot be removed here")); // mockup-only text
  // demo (2026-11-10): no right-click macro at all (= ApplyUseMode in Bar.lua), real potions stay; an icon the demo
  // shows active goes back to grey (2026-11-11, = ns:RemoveDemoRow via PostClick in Bar.lua)
  if (demo) {
    if (demo.rows[b.dataset.key]) { delete demo.rows[b.dataset.key]; demo.nRows--; hideTip(); updateAll(); }
    return;
  }
  const act = activeVariant(b._entry);
  if (!act) return flash(L("Buff not active - nothing to remove")); // mockup-only text
  for (const s of buffSpellsForItem(act)) cancelAura(s);
  updateAll();
}
// mouse wheel on a slot: next/previous variant (only out of combat, changes secure attributes)
function onBarWheel(e, b) {
  const en = b._entry;
  if (!isSlot(en)) return;
  e.preventDefault();
  if (sim.combat) return flash(L("Switching the variant only works out of combat."));
  const [r, i] = btnKey(b).split(",").map(Number);
  const pe = profile.rows[r].items[i];
  const k = pe.v.indexOf(pe.pick), n = pe.v.length;
  pe.pick = pe.v[(k + (e.deltaY > 0 ? 1 : n - 1)) % n];
  flash(fmt(L("Picked: %s"), itemInfo(pe.pick).name)); // mockup-only text
  refreshOptions(); requestRebuild();
  showBarTip(e, barButtons.find((x) => btnKey(x) === btnKey(b)));
}

// = ns:RowLayout() in Bar.lua: icon size and spacing of one row. Since 2026-11-16 (user) a row has no own size any
// more (before row.iconSize / spacing / scale / perLine): every row of a group uses the group's values, rows never wrap.
function rowLayout(p) {
  return { size: p.iconSize, sp: p.spacing };
}

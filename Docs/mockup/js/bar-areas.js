"use strict";
/* RaidKit Buffs mockup: Unwanted / Other / Debuffs areas, buff cap, Blizzard buff frame (= BarAreas.lua, BarAreaIcons.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// = Sonstige: active, not covered by a row, not unwanted (own row since 2026-11-10), stable order (application order)
const otherAuras = (t) => { const cov = coveredSpells(), u = unwantedSpells(); return activeAuras(t).filter((sp) => !cov.has(sp) && !u.has(sp)).sort((a, b) => sim.applied[a] - sim.applied[b]); };
// = CAP_LEVELS / CapLevel() in Bar.lua (user 2026-11-10, replaces the slider "Proc-Reserve"): fixed steps by free
// buff slots. 5 or more free = no tint; 4 yellow, 3 light orange, 2 orange, 1 soft red, 0 (full) red.
// rgba = background of the bar, cls = colour of the counter.
const CAP_LEVELS = {
  4: { rgba: "rgba(255, 209, 0, .14)", cls: "l4" },
  3: { rgba: "rgba(255, 165, 40, .17)", cls: "l3" },
  2: { rgba: "rgba(255, 115, 20, .20)", cls: "l2" },
  1: { rgba: "rgba(255, 60, 45, .22)", cls: "l1" },
  0: { rgba: "rgba(255, 30, 30, .32)", cls: "l0" },
};
const capLevel = (free) => free > 4 ? null : CAP_LEVELS[Math.max(free, 0)];
// free buff slots right now, demo buffs included (= B.CapFree in BarAreas.lua): tint of the bar and the buff counter
const capFreeNow = (t) => BUFF_CAP - activeAuras(t).length - (demo ? demo.buffs.length + demo.nRows : 0);
// Preview of "Sonstige" at maximum size (shown with the Shift outline). With a buff cap (Era) everything fits:
// ceil(32 / per line) lines, even if no row covers anything. Without a cap (other versions) the frame stays
// open at the bottom and fades out.
// = OtherSize() in Bar.lua: docked top/bottom the lines never get wider than the bar (2026-11-09, the area stuck
// out left of a right-aligned bar), so "Pro Zeile" is a maximum there; at least 4 per line (slider minimum)
const DEBUFF_CAP = 16; // = DEBUFF_MAX_DISPLAY
// = AreaLayout() in Bar.lua. Size of an area group ("unw" / "other" / "debuff"): since 2026-11-12 (user: everything
// like the other groups) the same "Eigene Größe" as every group, on = the group's iconSize, spacing, scale, perLine,
// rowSpacing (size * scale), off = "Alle Gruppen". rowSpacing = gap between the area's lines.
// Since 2026-11-14 (user) every value on its own (gEff: group value or "Alle Gruppen"). The area element is already
// scaled by "Alle Gruppen" (transform), so an own scale counts relative to it: effective scale = the shown value.
function areaLayout(p, id) {
  const g = (p.groups || profile.groups).find((x) => x.id === id);
  const sc = gEff(g, "scale"); // the area element is not scaled any more (no "Alle Gruppen" since session 20)
  return { size: gEff(g, "iconSize", p) * sc, sp: gEff(g, "spacing", p) * sc, rs: gEff(g, "rowSpacing", p) * sc, per: gEff(g, "perLine", p) ?? 0 };
}
const AREA_TIMER_H = 0; // = Bar.lua: room below an area icon for its timer, 0 since 2026-11-12 (time inside the icon)
// = OtherSize() in Bar.lua. kind undefined = "other", "unw", "debuff"; areaId = its group (the same). Snapped above/below
// another group the lines are at most as wide as that group; free or beside a group just "Pro Zeile" ("alle" = 10).
// lineH = size + AREA_TIMER_H + rowSpacing (timer inside the icon since 2026-11-12, before 10 px below).
function otherSize(p, kind, areaId) {
  const id = areaId || kind || "other";
  const { size, sp, rs } = areaLayout(p, id);
  let per = areaLayout(p, id).per;
  if (!per) per = 99; // 0 = "alle" (2026-11-10): as many as fit into the width of the group above
  const width = areaLimit(id);
  if (width != null) per = Math.max(Math.min(per, Math.floor((width + sp + 0.5) / (size + sp))), 4);
  else if (per === 99) per = 10;
  return { size, sp, per, lineH: size + AREA_TIMER_H + rs };
}
// Orientation of an area group (2026-11-11, user: like the row groups). null = "automatisch": rows, aligned like the
// group it hangs on (as before); hleft/hright = rows from the left/right (columns removed 2026-11-14).
// = AreaSlot / AreaExtent in Bar.lua. Along a line the step is size + sp, from line to line lineH.
// position of icon i (0-based) of n: x from the area's corner (mirrored by placeX when right-aligned), y from the top
function areaSlot(el, i, n, per, size, sp, lineH) {
  return [(i % per) * (size + sp), Math.floor(i / per) * lineH];
}
// width and height that n icons take (n >= 1); lines = rows of icons (for names below)
function areaExtent(el, n, per, size, sp, lineH) {
  const rs = lineH - size - AREA_TIMER_H;
  return { w: Math.min(n, per) * (size + sp) - sp, h: Math.ceil(n / per) * lineH - rs, lines: Math.ceil(n / per) };
}
// preview box (edges + placeholders) at y, filling from the corner next to the bar; open = far edge open, fading
function previewBox(p, id, cls, y, lines, cells, open, label, kind, areaId) {
  const { size, sp, per, lineH } = otherSize(p, kind, areaId);
  const pv = document.createElement("div");
  pv.id = id;
  // ar: label on the left, away from the counter (right-aligned it covered "Buffs n/32", 2026-11-09)
  pv.className = "cb-preview " + cls + (open ? " open" : "") + (extraEl._up ? " up" : "") + (extraEl._alignR ? " ar" : "");
  pv._alignR = extraEl._alignR; pv._up = extraEl._up;
  // exactly over the icon places (2026-11-11, before 3 px around them: the box ran into the area's name)
  placeX(pv, 0, y);
  // full lines
  const ext = { w: per * (size + sp) - sp, h: lines * lineH - (lineH - size - AREA_TIMER_H) };
  pv.style.width = ext.w + "px";
  pv.style.height = ext.h + "px";
  for (let i = 0; i < cells; i++) {
    const c = document.createElement("div");
    c.className = "ph";
    c.style.width = c.style.height = size + "px";
    const [cx, cy] = areaSlot(extraEl, i, cells, per, size, sp, lineH);
    placeX(c, cx, cy, pv);
    pv.appendChild(c);
  }
  pv.style.display = cells > 0 ? "" : "none";
  pv.title = label;
  return pv;
}
// = PreviewCells() in Bar.lua: "Sonstige Buffs" gets every buff slot that the rows do not use RIGHT NOW (user
// 2026-11-09, fully dynamic): 32 minus the active buffs that a visible row shows. No buff active = 32, two = 30.
// Buffs in "Sonstige" itself do not count (they sit in these places).
function previewCells(p) {
  const cov = coveredSpells();
  // unwanted buffs sit in their own row since 2026-11-10: their slots are taken, too
  return Math.max(BUFF_CAP - activeAuras(now()).filter((sp) => cov.has(sp)).length - (demo ? demo.nRows : 0) - unwantedNow().length, 0);
}
// gap before the debuff lines: room for their name when names sit above (= DEBUFF_GAP in Bar.lua)
const debuffGap = () => (namesAbove() ? 12 : 0); // = NAME_GAP in Bar.lua (= ROW_LABEL_H, 2026-11-10; before 14)
// = NameGapBelow() in Bar.lua (2026-11-11): names below sit after the timers of the last line, so the next section
// starts 12 px later (growing up the name sits right after the icon and fits into the normal gap)
const nameGapBelow = () => (!!extraEl._pos && extraEl._pos.startsWith("bottom") && !extraEl._up ? 12 : 0);
const activeDebuffs = (t) => DEBUFF_SIM.filter((d) => sim.debuffs[d.id] > t);
// = UpdateExtra() in Bar.lua. Since 2026-11-11 (groups, phase 2) three own groups: "Unerwünschte Buffs", "Sonstige
// Buffs" (with the counter) and "Debuffs". Each is laid out from its own top-left corner, then measured (icons,
// names, previews) so that snapped groups sit right after it. A group with nothing to show is hidden, except while
// the previews show (options open, Shift over a group, dragging): then it shows its preview box and can be dragged
// even when empty. Hidden groups pass their snap on, so what hangs below moves up (as before).
function renderExtras(t) {
  if (!areaEls.other) return;
  const p = barLayout, pv0 = !!areaPreview;
  // empty groups (placeholders, 2026-11-15) show together with the area previews (= UpdateExtra in Bar.lua)
  for (const x of groupEls) if (x.el._placeholder) x.el._hidden = !pv0;
  // eye of an area off (2026-11-12, user; = UpdateExtra in Bar.lua): not drawn, not even as preview while editing
  const hid = (a) => !!(areaEls[a] && areaEls[a]._g.hidden), pvU = pv0 && !hid("unw"), pvO = pv0 && !hid("other"), pvD = pv0 && !hid("debuff");
  // demo buffs count like real ones (= UpdateExtra in Bar.lua)
  const lv = capLevel(capFreeNow(t));
  // every group with "Buff-Limit-Färbung" (2026-11-11, g.capTint) gets the same tint
  for (const x of groupEls) {
    const tt = x.el._tint, on = !!lv && x.g.area !== "debuff" && (x.g.id === "main" ? x.g.capTint !== false : x.g.capTint === true); // debuffs never (session 4c)
    if (tt) { tt.style.display = on ? "block" : "none"; tt.style.background = on ? lv.rgba : ""; }
  }
  const { size, sp, per, lineH } = otherSize(p), u = unwantedSpells();

  // ----- "Unerwünschte Buffs": all active unwanted buffs; click on the X removes all, right-click one icon just that one
  extraEl = areaEls.unw;
  { // own size since 2026-11-11 (user): "Eigene Größe" of its group, else like "Sonstige Buffs"
  const { size, sp, per, lineH } = otherSize(p, "unw", "unw");
  const unwRow = document.getElementById("unwRow"), au = unwantedNow();
  const uExt = areaExtent(extraEl, Math.max(au.length, 1), per, size, sp, lineH), uLines = au.length ? uExt.lines : 0;
  unwRow.innerHTML = "";
  unwRow.style.display = au.length ? "" : "none";
  placeX(unwRow, 0, 0);
  // framed like a button (user 2026-11-11, = extra.unwBox in Bar.lua): only as wide as the icons plus a cell with a
  // red X (14 px), since 2026-11-12 at the start, the icons after it; red frame on hover. The click area (secure button) stays the full row.
  const fitW = uExt.w;
  unwRow.className = "cb-unwrow s-button";
  unwRow.style.width = (fitW + sp + 14) + "px"; unwRow.style.height = (au.length ? uExt.h : 0) + "px";
  au.forEach((x, i) => {
    const o = document.createElement("div"), exp = x.a ? x.a.exp : sim.auras[x.s], dur = x.a ? x.a.dur : sim.durs[x.s];
    o.className = "cb-other unw";
    o.style.width = o.style.height = size + "px";
    const [ux, uy] = areaSlot(extraEl, i, au.length, per, size, sp, lineH);
    placeX(o, ux + 14 + sp, uy, unwRow); // after the X cell at the start (user 2026-11-12, = UNW_X_CELL in Bar.lua)
    const icon = x.a ? x.a.icon : spellInfo(x.s).icon;
    o.innerHTML = `<div class="border"></div><div class="icon ic" style="background-image:url(${ICON_URL(icon)})"></div>${timerDiv(exp, dur, t)}`;
    // own mouse handling (user 2026-11-11, = CreateUnwIcon in Bar.lua): the icon lies above the click area of the
    // row, right-click removes just this buff (out of combat, like "Sonstige"); only the X removes all
    const name = x.a ? x.a.name : spellInfo(x.s).name;
    o.addEventListener("click", (e) => e.stopPropagation());
    o.addEventListener("mousemove", (e) => {
      e.stopPropagation();
      tip.innerHTML = `<div class="n">${name}</div><div class="d">(Buff-Tooltip)</div>` + (x.a ? `<div class="b">${L("Demo - not real")}</div>` : "") +
        `<div class="r">${L("Unwanted")}</div><br><div class="d">${sim.combat && !x.a ? L("Right-click: remove only this one (not possible in combat)") : L("Right-click: remove only this one")}</div>` +
        `<div class="d">${L("Click the X: remove all (also in combat)")}</div>`;
      placeTip(e);
    });
    o.addEventListener("contextmenu", (e) => {
      e.preventDefault(); e.stopPropagation();
      if (x.a) return removeDemoAura(x.a); // demo: just drop it
      if (sim.combat) return flash(L("Cannot be removed one by one in combat. The X removes all."));
      if (demo) return flash(L("No real buffs are removed during the demo."));
      cancelAura(x.s); hideTip(); updateAll();
    });
    unwRow.appendChild(o);
  });
  if (au.length) {
    const h = document.createElement("div");
    h.className = "hint"; h.textContent = "✖"; h.style.width = "14px"; h.style.height = size + "px";
    h.style[extraEl._alignR ? "right" : "left"] = "0px"; // X at the start side since 2026-11-12 (user), before at the end
    unwRow.appendChild(h);
  }
  // empty: a one-cell preview while the previews show, so the group can be found and dragged
  document.getElementById("unwPreview").classList.toggle("show", pvU && !au.length);
  const nU = document.getElementById("nameUnw");
  nU.style.display = extraEl._pos && (au.length || pvU) ? "" : "none";
  if (extraEl._pos) placeName(nU, 0, Math.max(uLines, 1), lineH, size, sp, false, au.length ? fitW + sp + 14 : size + 6);
  // whole width of the button with every buff of the list active (= MeasureArea call in Bar.lua)
  const uFull = areaExtent(extraEl, Math.max((profile.unwanted || []).length, 1), per, size, sp, lineH).w;
  finishArea(areaEls.unw, au.length > 0, pvU, 0, uFull + sp + 14);
  }

  // ----- "Sonstige Buffs": weapon enchants without an icon, other buffs, demo buffs
  extraEl = areaEls.other;
  const box = extraEl.querySelector(".cb-others");
  box.innerHTML = "";
  const oTop = 0; // session 4b: no counter line any more (= OTHER_TOP in Bar.lua)
  // the blue preview follows the active buffs (a buff of a row comes or goes): rebuild it when its size changes
  const cells = previewCells(p);
  if (cells !== extraEl._pvCells || !document.getElementById("otherPreview")) {
    extraEl._pvCells = cells; extraEl._pvLines = Math.ceil(cells / per);
    const nb = previewBox(p, "otherPreview", "", oTop, extraEl._pvLines, cells, false, fmt(L("Other: %d free slots"), cells)); // mockup-only texts (preview title)
    const old = document.getElementById("otherPreview");
    if (old) old.replaceWith(nb); else extraEl.appendChild(nb);
  }
  document.getElementById("otherPreview").classList.toggle("show", pvO);
  const cov = coveredHands(), weaponOthers = [];
  for (const hand of ["main", "off"]) {
    if (cov.has(hand) || hid("other")) continue; // hidden area: nothing drawn (2026-11-12)
    const hs = handState(hand);
    if (hs.wf) weaponOthers.push({ hand, icon: WINDFURY.icon, name: WINDFURY.name, exp: Infinity });
    else if (hs.id) weaponOthers.push({ hand, icon: itemInfo(hs.id).icon, name: itemInfo(hs.id).name, exp: hs.exp, dur: hs.dur });
  }
  // total first (areaSlot gets the count)
  const others = hid("other") ? [] : otherAuras(t), demoBuffs = demo && !hid("other") ? demo.buffs.filter((a) => !u.has(String(a.id))) : [];
  const nTot = weaponOthers.length + others.length + demoBuffs.length;
  const oSlot = (i) => { const [x, y] = areaSlot(extraEl, i, nTot, per, size, sp, lineH); return [x, oTop + y]; };
  weaponOthers.forEach((w, i) => {
    const o = document.createElement("div");
    o.className = "cb-other";
    o.style.width = o.style.height = size + "px";
    placeX(o, ...oSlot(i));
    o.innerHTML = `<div class="border"></div><div class="icon ic" style="background-image:url(${ICON_URL(w.icon)})"></div><div class="hand">${HAND_LETTER[w.hand]}</div>${timerDiv(w.exp, w.dur, t)}`;
    o.addEventListener("mousemove", (e) => { tip.innerHTML = `<div class="n">${w.name}</div><div class="d">${fmt(L("Weapon enchant, %s"), HAND_NAME[w.hand])}</div>`; placeTip(e); });
    o.addEventListener("mouseleave", hideTip);
    box.appendChild(o);
  });
  const off0 = weaponOthers.length; // buffs follow the weapon enchants
  const usedLines = nTot ? areaExtent(extraEl, nTot, per, size, sp, lineH).lines : 0; // lines taken by "Sonstige"
  // demo buffs after the real ones (= UpdateExtra in Bar.lua); right-click just drops them
  demoBuffs.forEach((a, k) => {
    const i = off0 + others.length + k;
    const o = document.createElement("div");
    o.className = "cb-other"; // demo unwanted ones sit in their own row since 2026-11-10
    o.style.width = o.style.height = size + "px";
    placeX(o, ...oSlot(i));
    o.innerHTML = `<div class="border"></div><div class="icon ic" style="background-image:url(${ICON_URL(a.icon)})"></div>${timerDiv(a.exp, a.dur, t)}`;
    o.addEventListener("mousemove", (e) => { tip.innerHTML = `<div class="n">${a.name}</div><div class="d">(Spell-Tooltip)</div><div class="b">${L("Demo - not real")}</div>`; placeTip(e); });
    o.addEventListener("mouseleave", hideTip);
    o.addEventListener("contextmenu", (e) => { e.preventDefault(); removeDemoAura(a); });
    box.appendChild(o);
  });
  others.forEach((s, k) => {
    const i = k + off0;
    const o = document.createElement("div"), exp = sim.auras[s];
    o.className = "cb-other";
    o.style.width = o.style.height = size + "px";
    placeX(o, ...oSlot(i));
    o.innerHTML = `<div class="border"></div><div class="icon ic" style="background-image:url(${ICON_URL(spellInfo(s).icon)})"></div>${timerDiv(exp, sim.durs[s], t)}`;
    o.addEventListener("mousemove", (e) => {
      const left = sim.auras[s];
      tip.innerHTML = `<div class="n">${spellInfo(s).name}</div><div class="d">(Buff-Tooltip)</div><br>` +
        // remaining time = part of the game's buff tooltip (mockup-only texts)
        (left > now() ? `<div class="g">${left === Infinity ? L("Active (no duration)") : fmt(L("%s remaining"), fmtTimeLong(left - now()))}</div>` : "") +
        (u.has(s) ? `<div class="r">${L("Unwanted")}</div>` : "") +
        `<div class="d">${sim.combat ? L("Right-click: remove (not possible in combat)") : L("Right-click: remove")}</div>`;
      placeTip(e);
    });
    o.addEventListener("mouseleave", hideTip);
    o.addEventListener("contextmenu", (e) => {
      e.preventDefault();
      // plain frames: CancelUnitBuff only out of combat (in combat later via SecureAuraHeader)
      if (sim.combat) return flash(L("Cannot be removed in combat (comes with the buff bar replacement)."));
      if (demo) return flash(L("No real buffs are removed during the demo.")); // = OnClick in Bar.lua
      cancelAura(s); hideTip(); updateAll();
    });
    box.appendChild(o);
  });
  const otherLines = Math.max(pvO ? extraEl._pvLines : 0, usedLines);
  const nO = document.getElementById("nameOther");
  nO.style.display = extraEl._pos && otherLines > 0 ? "" : "none";
  if (extraEl._pos) placeName(nO, oTop, Math.max(otherLines, 1), lineH, size, sp, true);
  // empty without buffs and preview, like the debuffs (session 4b: the counter is no longer part of it)
  finishArea(areaEls.other, usedLines > 0, pvO && cells > 0, 0, areaEls.other._w);

  // ----- "Debuffs": only while the bar replaces the Blizzard bar (that one shows them otherwise), demo debuffs always.
  // The name at the top, then the icons (DEB_GAP 0 since 2026-11-14: the divider is the group separator in the gap
  // before the area, placeSeparator; before 2026-11-14 a line at the top and the icons 4 px below). Border = DebuffTypeColor.
  extraEl = areaEls.debuff;
  const dbox = extraEl.querySelector(".cb-others");
  dbox.innerHTML = "";
  const debuffs = hid("debuff") ? [] : (modeActive() ? activeDebuffs(t).map((d) => Object.assign({}, d, { exp: sim.debuffs[d.id] })) : [])
    .concat(demo ? demo.debuffs : []);
  const ds = otherSize(p, "debuff"), dlineH = ds.lineH, DEB_GAP = 0, debTop = debuffGap() + DEB_GAP;
  placeX(document.getElementById("debuffPreview"), 0, debTop);
  document.getElementById("debuffPreview").classList.toggle("show", pvD);
  const nD = document.getElementById("nameDebuff");
  nD.style.display = extraEl._pos && (debuffs.length || pvD) ? "" : "none";
  if (extraEl._pos) placeName(nD, debTop, Math.max(pvD ? Math.ceil(DEBUFF_CAP / ds.per) : Math.ceil(debuffs.length / ds.per), 1), dlineH, ds.size, ds.sp, false);
  debuffs.forEach((d, i) => {
    const o = document.createElement("div"), exp = d.exp;
    o.className = "cb-other cb-debuff";
    o.style.width = o.style.height = ds.size + "px";
    const [dx, dy] = areaSlot(extraEl, i, debuffs.length, ds.per, ds.size, ds.sp, dlineH);
    placeX(o, dx, debTop + dy);
    o.innerHTML = `<div class="border" style="background:${DEBUFF_COLOR[d.type || "none"]}"></div><div class="icon ic" style="background-image:url(${ICON_URL(d.icon)})"></div><div class="timer">${exp === Infinity ? "" : fmtTime(exp - t)}</div>`;
    o.addEventListener("mousemove", (e) => {
      tip.innerHTML = `<div class="n">${d.name}</div><div class="d">(Debuff-Tooltip)</div>` + (d.type ? `<div class="w">${d.type}</div>` : "")
        + (d.demo ? `<div class="b">${L("Demo - not real")}</div>` : "");
      placeTip(e);
    });
    o.addEventListener("mouseleave", hideTip);
    if (d.demo) o.addEventListener("contextmenu", (e) => { e.preventDefault(); removeDemoAura(d); });
    dbox.appendChild(o);
  });
  // the divider above the debuffs is the general separator of the groups since 2026-11-14 (placeSeparator)
  finishArea(areaEls.debuff, debuffs.length > 0, pvD, 0, areaEls.debuff._w);
  extraEl = areaEls.other;
  layoutGroups();
  for (const x of groupEls) sizeMover(x);
}
// measures an area group after drawing it: box = everything shown (icons, names, previews, counter) plus the frame
// padding; frame, tint and outline follow the box. Hidden when it has nothing to show and no preview is up.
// fullX, fullW (2026-11-12, = MeasureArea in Bar.lua; user: the bar shook while buffs came and went): the outline always
// covers the whole width the area can take, so a group beside it no longer moves with every buff. fullX from the side
// the icons start at (mirrored when right-aligned).
function finishArea(el, hasContent, pv, fullX, fullW) {
  el._hidden = !barWanted() || (!hasContent && !pv);
  if (el._hidden) { el.style.display = "none"; return; }
  el.style.display = "";
  const s = el._p.scale || 1, er = el.getBoundingClientRect();
  let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity;
  for (const c of el.querySelectorAll(".cb-counter, .cb-unwrow, .cb-other, .cb-label, .cb-preview.show")) {
    if (c.offsetParent === null || getComputedStyle(c).display === "none") continue;
    // rounded to whole units like MeasureArea in Bar.lua (2026-11-12: sub-pixel rest made the bar shake ingame)
    const r = c.getBoundingClientRect();
    x0 = Math.min(x0, Math.round((r.left - er.left) / s)); y0 = Math.min(y0, Math.round((r.top - er.top) / s));
    x1 = Math.max(x1, Math.round((r.right - er.left) / s)); y1 = Math.max(y1, Math.round((r.bottom - er.top) / s));
  }
  if (x0 === Infinity) { x0 = 0; y0 = 0; x1 = el._w; y1 = 16; }
  if (fullW != null) { const a = el._alignR ? el._w - fullX - fullW : fullX; x0 = Math.min(x0, a); x1 = Math.max(x1, a + fullW); }
  const fo = frameOutset(el._g), fp = frameOn(el._g) ? FRAME_PAD + fo : 0; // border inside the box (2026-11-15)
  // hanging above/below a group, the outline is as wide as that group's (session 4b, = MeasureArea in Bar.lua)
  const anchor = areaAnchor(el._g.id);
  if (anchor && anchor !== el && anchor._box) {
    const want = outlineOf(anchor).w / s - 2 * moverPad(el) - 2 * fp;
    if (want > x1 - x0) { if (el._alignR) x0 = x1 - want; else x1 = x0 + want; }
  }
  let ml = Math.floor(x0), mt = Math.floor(y0), mw = Math.ceil(x1 - x0), mh = Math.ceil(y1 - y0);
  // 1 unit of hysteresis, = MeasureArea in Bar.lua
  const m = el._measured;
  if (m && Math.abs(m[0] - ml) <= 1 && Math.abs(m[1] - mt) <= 1 && Math.abs(m[2] - mw) <= 1 && Math.abs(m[3] - mh) <= 1) {
    [ml, mt, mw, mh] = m;
  } else el._measured = [ml, mt, mw, mh];
  el._box = { l: ml - fp, t: mt - fp, w: mw + 2 * fp, h: mh + 2 * fp };
  const b = el._box;
  for (const k of [el._frame, el._tint]) {
    if (!k) continue;
    // tint = outline box (2026-11-11): without a frame MOVER_PAD around the content
    const pad = k === el._tint ? moverPad(el) : -fo; // the frame background sits fo inside the box
    k.style.left = (b.l - pad) + "px"; k.style.top = (b.t - pad) + "px";
    k.style.width = (b.w + 2 * pad) + "px"; k.style.height = (b.h + 2 * pad) + "px";
  }
}
// "Buff counter" in a row (user 2026-11-25, replaces the hidden counter "Buffs n/32" of session 4b and the line on
// "Info"; = B.UpdateCounterButton in BarAreas.lua): the USED buff slots as a big number, colored by CAP_LEVELS like the
// tint (white up to 27 used, then yellow ... red at 32). On the bar without icon and border (user: no background);
// the catalog and the rows of the options show the icon.
// Never gray, no timer, bag count, cooldown or status mark.
function updateCounterButton(b, t) {
  const free = Math.max(capFreeNow(t), 0), lv = capLevel(free);
  if (b.dataset.id !== "counter") { b.dataset.id = "counter"; setIcon(b.querySelector(".icon"), entPick(b._entry)); }
  b.classList.remove("missing", "lost", "wf");
  b.classList.add("capctr");
  b.querySelector(".border").style.background = `var(--bc-active, ${BORDER.active})`;
  b.querySelector(".st").style.display = "none";
  b.querySelector(".count").style.display = "none";
  b.querySelector(".timer").textContent = "";
  drawCooldown(b.querySelector(".cd"), 0, 0, t);
  let num = b.querySelector(".capnum");
  if (!num) { num = document.createElement("div"); b.appendChild(num); }
  num.className = "capnum " + (lv ? lv.cls : "");
  num.style.fontSize = Math.round((parseInt(b.style.height, 10) || 36) * 0.55) + "px"; // = SetFont(size * 0.55) in Lua
  num.textContent = BUFF_CAP - free;
}
// tooltip of the buff counter (before session 4c the counter "Buffs n/32"): slots, free, buffs no row shows
function showCounterTip(e) {
  const t = now(), free = capFreeNow(t), n = BUFF_CAP - free, others = otherAuras(t);
  tip.innerHTML = `<div class="n">${fmt(L("Buff slots: %d of %d"), n, BUFF_CAP)}</div>` +
    `<div class="${free <= 1 ? "r" : free <= 4 ? "y" : "g"}">${free > 0 ? fmt(L("%d free"), free) : L("Full - the next buff pushes out another one")}</div>` +
    `<div class="d">${L("From 4 free slots on the bar is tinted: yellow, orange, red at 1.")}</div><div class="d">${L("RaidKit Buffs does not see invisible buffs (some enchants, set bonuses).")}</div>` +
    (others.length ? `<br><div class="w">${L("Not in a row:")}</div>` + others.map((s) => `<div class="d">${spellInfo(s).name}</div>`).join("") : "") +
    `<br><div class="d">${L("Shift+right-click: options")}</div>`;
  placeTip(e);
}
function showUnwantedTip(e) {
  const au = unwantedNow();
  tip.innerHTML = `<div class="r">${groupName(groupById("unw"))}</div>` + au.map((x) => `<div class="w">${x.a ? x.a.name + " (Demo)" : spellInfo(x.s).name}</div>`).join("") +
    `<br><div class="d">${L("Click the X: remove all (also in combat)")}</div><div class="d">${L("Right-click an icon: remove only this one")}</div><div class="d">${L("List: options, catalog tab \"Buffs\"")}</div>`;
  placeTip(e);
}
// = secure button with a macro of several "/cancelaura <name>" lines, works in combat
function removeUnwanted() {
  const au = activeUnwanted(now());
  au.forEach(cancelAura);
  // demo (2026-11-10): its unwanted buffs go too (= RemoveDemoUnwanted via PostClick in Bar.lua)
  if (demo) { const ids = new Set(demo.unwantedDefs.map((d) => d.id)); demo.buffs = demo.buffs.filter((a) => !ids.has(a.id)); }
  if (au.length) print(fmt(L("Removed: %s"), au.map((s) => spellInfo(s).name).join(", "))); // mockup-only text
  hideTip(); updateAll();
}

// = Blizzard BuffFrame: buffs, then a line of debuffs. Hidden while RaidKit Buffs replaces it (display mode).
function renderBuffFake() {
  const el = document.getElementById("bufffake"), t = now();
  const replaced = modeActive(); // label below it removed 2026-11-22 (user)
  el.style.display = replaced ? "none" : "";
  if (replaced) return;
  const icons = [];
  for (const sp of activeAuras(t).sort((a, b) => sim.applied[a] - sim.applied[b])) icons.push(spellInfo(sp).icon);
  const deb = activeDebuffs(t);
  // = TemporaryEnchantFrame: weapon enchants left of the buffs (replaced together with the BuffFrame)
  const wIcons = ["main", "off"].map((h) => { const hs = handState(h); return hs.wf ? WINDFURY.icon : hs.id ? itemInfo(hs.id).icon : null; }).filter(Boolean);
  el.innerHTML = wIcons.map((i) => `<div class="ic wpn" style="background-image:url(${ICON_URL(i)})"></div>`).join("") + icons.map((i) => `<div class="ic" style="background-image:url(${ICON_URL(i)})"></div>`).join("")
    + (deb.length ? `<div class="brk"></div>` + deb.map((d) => `<div class="ic deb" style="background-image:url(${ICON_URL(d.icon)}); box-shadow: 0 0 0 1px ${DEBUFF_COLOR[d.type || "none"]}"></div>`).join("") : "");
}

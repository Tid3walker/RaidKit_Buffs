"use strict";
/* RaidKit Buffs mockup: building the bar, anchors, group layout, separators, placing (= Bar.lua, BarGroups.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// = BuildBar() in Bar.lua. Orientation (proposal 2026-11-09, p.orientation):
//   "hleft"  rows top to bottom, left-aligned (as before)
//   "hright" rows top to bottom, right-aligned (icon order unchanged, shorter rows start further right)
// No row names since 2026-11-16 (user). Columns (vdown/vup) were removed 2026-11-14 (user).
// Groups (proposal 2026-11-11): every shown group is its own container; "main" is #bar and keeps the buff area below
// it (phase 1). A group without a visible row is not shown (except "main").
let groupEls = []; // [{ g, el, p }] in group order
function buildBar() {
  for (const x of groupEls) if (x.el !== barEl) x.el.remove();
  groupEls = []; barButtons = [];
  const P = barLayout;
  let after = barEl;
  for (const g of P.groups) {
    if (g.area) continue; // buff areas: buildAreas below
    const gp = groupLayout(P, g), main = g.id === "main";
    // a group without a visible row is a placeholder (2026-11-15, user): drawn only while editing, like the area
    // previews, so a new empty group can be seen and moved (= BuildBar in Bar.lua); eye off = not at all
    const ph = !main && !gp.rows.length;
    if (ph && g.hidden) continue;
    let el = barEl;
    if (!main) { el = document.createElement("div"); el.className = "cb-container cb-group"; after.after(el); after = el; }
    el._g = g; el._p = gp; el._placeholder = ph;
    buildGroup(el, gp, g, main);
    if (ph) el._hidden = !areaPreview;
    if (main) el.style.visibility = g.hidden ? "hidden" : ""; // hidden main group: empty anchor (= BuildGroup in Bar.lua)
    groupEls.push({ g, el, p: gp });
  }
  buildAreas(P);
  layoutGroups();
  updateMover();
  renderExtras(now());
}
function buildGroup(el, p, g, main) {
  el.innerHTML = ""; // alignment per row since 2026-11-18 (rowAlign), no "Icons:" for groups with rows
  el.classList.toggle("noborder", !p.showBorders); // = BordersOn(g) in Bar.lua (per group since session 4d; p = groupLayout)
  el.classList.toggle("notime", !gEff(g, "showTime", p)); // = TimeOn(g) in Bar.lua (2026-11-14), inherits since then
  el.style.setProperty("--tfs", gEff(g, "timeSize", p) + "px"); // font size of the time (2026-11-14)
  applyIconStyle(el, g); // icon border style (2026-11-14)
  // first pass: size of every row. Rows never wrap since 2026-11-16 (user): one line each, a normal row as long as its
  // icons; a split row spans the widest row of the group (session 20, user; bar-split.js). No row names since
  // 2026-11-16 (user: only group names stay).
  const infos = p.rows.map((row) => {
    const { size, sp } = rowLayout(p, row), split = isSplitRow(row);
    return { row, size, sp, split, len: rowLength(row, size, sp), align: rowAlign(row) };
  });
  const maxLen = infos.reduce((m, r) => Math.max(m, r.len), 0);
  // alignment per row (2026-11-18, user; bar-split.js rowAlign): only "both" stretches a split row over the group
  for (const r of infos) if (r.split && r.align === "both") r.len = maxLen;
  const makeButton = (row, en, i, x, y, size) => {
    const b = document.createElement("div");
    b.className = "cb-btn" + (isSlot(en) ? " slot" : "");
    b.style.cssText = `left:${x}px; top:${y}px; width:${size}px; height:${size}px;`;
    b.innerHTML = `<div class="border"></div><div class="icon ic"></div>
      <canvas class="cd" width="${size}" height="${size}"></canvas><div class="hl"></div><div class="timer"></div><div class="count"></div>
      <div class="st"></div>${isSlot(en) && !isWeaponEntry(en) ? `<div class="slotmark"></div>` : ""}${isWeaponEntry(en) ? `<div class="hand">${HAND_LETTER[en.hand]}</div>` : ""}`;
    b._entry = en;
    b.dataset.key = row._src + "," + i;
    b.addEventListener("click", (e) => onBarClick(e, b));
    // Shift+drag moves the icon's group; with the options window open plain dragging moves too (Ctrl+click still uses)
    b.addEventListener("mousedown", (e) => { if (e.button === 0 && (e.shiftKey || (sim.optionsOpen && !e.ctrlKey))) startMove(e, el); });
    b.addEventListener("contextmenu", (e) => onBarRightClick(e, b));
    b.addEventListener("wheel", (e) => onBarWheel(e, b), { passive: false });
    b.addEventListener("mousemove", (e) => showBarTip(e, b));
    b.addEventListener("mouseleave", hideTip);
    el.appendChild(b);
    barButtons.push(b);
  };
  // a piece of the separator of a split row (2026-11-17, user; = the textures of B.SplitMark in BarSplit.lua)
  const makeMark = (x, y, w, h) => {
    const m = document.createElement("div");
    m.className = "cb-rsep";
    m.style.cssText = `left:${x}px; top:${y}px; width:${w}px; height:${h}px; background:${SEP_COLOR};`;
    el.appendChild(m);
  };
  let y = 0;
  infos.forEach(({ row, size, sp, split, len: rowW, align }, r) => {
    const x0 = align === "right" ? maxLen - rowW : 0; // right-aligned: the row ends at the right edge
    if (r > 0) y += p.rowSpacing;
    if (split) placeSplitRow(row, x0, y, size, sp, rowW, makeButton, makeMark); // split row (2026-11-16): bar-split.js
    else row.items.forEach((en, i) => makeButton(row, en, i, x0 + i * (size + sp), y, size));
    y += size;
  });
  let barW = maxLen, barH = y;
  if (!main && !p.rows.length) {
    // placeholder (2026-11-15, = BuildGroup in Bar.lua): "Name (empty)" in a blue box, at least 4 icons wide, 1 high
    const ph = document.createElement("div");
    ph.className = "cb-ph"; ph.textContent = fmt(L("%s (empty)"), groupName(g));
    el.appendChild(ph);
    barW = Math.max(4 * (p.iconSize + p.spacing) - p.spacing, ph.scrollWidth + 12); barH = p.iconSize;
    ph.style.width = barW + "px"; ph.style.height = barH + "px";
  }
  el.style.width = Math.max(barW, p.iconSize) + "px";
  el.style.height = Math.max(barH, p.iconSize) + "px";
  // = ns:ApplyVisibility(): shown by the display mode (then it replaces the Blizzard bar) or while the options are open
  el.style.display = barWanted() ? "" : "none";
  const s = p.scale || 1;
  el.style.transform = `scale(${s})`; el.style.transformOrigin = "center center"; el.style.right = "auto";
  const mover = document.createElement("div");
  mover.className = "cb-mover"; if (main) mover.id = "mover";
  el.appendChild(mover); el._mover = mover;
  // = mover OnDragStart in Bar.lua: while editing the empty space inside the outline can be dragged too
  // (Shift: the outline takes the mouse too since 2026-11-14, so Shift+drag on the frame or a gap moves as well)
  mover.addEventListener("mousedown", (e) => { if (e.button === 0 && (e.shiftKey || (sim.optionsOpen && !e.ctrlKey))) startMove(e, el); });
  if (main && !document.getElementById("demoLabel")) {
    // "Demo-Modus" in big letters next to the bar while the demo runs (= container.demoLabel in Bar.lua, 2026-11-10).
    // Once, on the screen (2026-11-15): placed beyond every group in its line by updateMover
    const demoLabel = document.createElement("div");
    demoLabel.className = "cb-demolabel"; demoLabel.id = "demoLabel"; demoLabel.textContent = L("Demo mode");
    screenEl.appendChild(demoLabel);
  }
  // nothing sticks out left/right of the icons since 2026-11-16 (before the row names: labelLeft / labelRight)
  const w = el.offsetWidth, lw = 0, rw = 0;
  // group box (2026-11-11): icons + row names, plus the frame padding and the group name above it. Snapping and the
  // outline use this box (the buff areas are own groups since phase 2, 2026-11-11).
  // the counter "Buffs n/32" in the main group's name line (session 4b, hidden since 4c) is gone since 2026-11-25: the
  // "Buff counter" icon goes into any row instead (bar-areas.js updateCounterButton)
  const fp = frameOn(g) ? FRAME_PAD : 0, nameH = gEff(g, "showName", p) ? GNAME_H : 0, h = el.offsetHeight;
  const fb = fp + frameOutset(g); // box edge: the border lies inside the box (2026-11-15), the background stays at fp
  el._box = { l: -(lw + fb), t: -fb - nameH, w: w + lw + rw + 2 * fb, h: h + 2 * fb + nameH };
  // 2026-11-15 (proposal, user): the name line lies inside the frame and the outline, so the visible outline no longer
  // leaves it out (before session 4b..2026-11-15: name above the frame)
  el._nameH = 0;
  el._alignR = rowsAlignRight(p.rows); // from the rows since 2026-11-18 (user; before "Icons:" of the group)
  el._anchorPt = anchorPoint(el._alignR); // corner a free group grows away from (2026-11-14)
  if (frameOn(g)) {
    const fr = document.createElement("div");
    fr.className = "cb-gframe";
    fr.style.cssText = `left:${-(lw + fp)}px; top:${-fp - nameH}px; width:${w + lw + rw + 2 * fp}px; height:${h + 2 * fp + nameH}px;`;
    applyFrameStyle(fr, g); // style proposal 2026-11-14
    el.insertBefore(fr, el.firstChild);
  }
  if (gEff(g, "showName", p)) { // inherits from "Alle Gruppen" (2026-11-14)
    const n = document.createElement("div");
    n.className = "cb-label cb-gname"; n.textContent = groupName(g);
    // inside the frame, in the line above the rows, flush with the rows' edge on the side of the group's alignment
    n.style.transform = "none"; n.style.top = (-nameH - Math.round(fp / 2)) + "px";
    const na = nameAlignOf(g); // the name's own alignment since 2026-11-15 (user; before = the group's)
    if (na === "right") n.style.right = -rw + "px";
    else if (na === "center") { n.style.left = ((w + rw - lw) / 2) + "px"; n.style.transform = "translateX(-50%)"; }
    else n.style.left = -lw + "px";
    el.appendChild(n);
  }
  // background tint by free buff slots (2026-11-10): first child, so it lies below every icon. Since 2026-11-11 the
  // same box as the outline for every group (main too): the frame, or MOVER_PAD around icons and names without one
  const tint = document.createElement("div");
  tint.className = "cb-tint"; if (main) tint.id = "capTint";
  el.insertBefore(tint, el.firstChild); el._tint = tint;
  const pad = frameOn(g) ? fp : MOVER_PAD;
  tint.style.left = -(lw + pad) + "px"; tint.style.top = (-pad - nameH) + "px"; // with the name line (2026-11-15)
  tint.style.width = (w + lw + rw + pad * 2) + "px"; tint.style.height = (h + pad * 2 + nameH) + "px";
  if (main) { barLabelWidth = lw; barLabelRight = rw; }
}

// ----- group positions (2026-11-11) -----
// outer box of a group in screen coordinates (relative to #screen); scale works around the element's centre
function rectOf(el) {
  const b = el._box, s = el._p.scale || 1, W = el.offsetWidth, H = el.offsetHeight;
  const L = parseFloat(el.style.left) || 0, T = parseFloat(el.style.top) || 0;
  const h = b.h;
  return { x: L + W / 2 + (b.l - W / 2) * s, y: T + H / 2 + (b.t - H / 2) * s, w: b.w * s, h: h * s };
}
// moves a group so that its outer box starts at X/Y
function placeRect(el, X, Y) {
  const b = el._box, s = el._p.scale || 1, W = el.offsetWidth, H = el.offsetHeight;
  el.style.left = (X - W / 2 - (b.l - W / 2) * s) + "px";
  el.style.top = (Y - H / 2 - (b.t - H / 2) * s) + "px";
}
// = AnchorPoint in Bar.lua (2026-11-14, user: a longer row made the bar grow from its middle): the corner of the outline
// a free group grows away from. Rows left/right = top left/top right.
function anchorPoint(alignR) { return alignR ? "TOPRIGHT" : "TOPLEFT"; }
// offset of an anchor point from a box's top-left corner (x right, y down) = PointOffset in Bar.lua
function pointOffset(pt, w, h) {
  return [pt.includes("LEFT") ? 0 : pt.includes("RIGHT") ? w : w / 2, pt.includes("TOP") ? 0 : pt.includes("BOTTOM") ? h : h / 2];
}
// free position: q.pt set (since 2026-11-14) = that corner of the outline, offset from the same corner of the screen
// (y up); without q.pt (older) = centre offset of the element from the screen centre like profile.point
function placeFree(el, q) {
  const sw = screenEl.clientWidth, sh = screenEl.clientHeight;
  if (q.pt && el._box) {
    const [rx, ry] = pointOffset(q.pt, sw, sh), o = outlineOf(el), [ox, oy] = pointOffset(q.pt, o.w, o.h);
    return placeOutline(el, rx + q.x - ox, ry - q.y - oy);
  }
  el.style.left = (sw / 2 + q.x - el.offsetWidth / 2) + "px";
  el.style.top = (sh / 2 - q.y - el.offsetHeight / 2) + "px";
}
const gpos = (id) => (profile.groupPos || {})[id] || null;
const mainPos = () => ({ x: profile.point[3], y: profile.point[4], pt: profile.point[5] === "outline" ? profile.point[0] : undefined });
function freePos(id) {
  if (id === "main") return mainPos();
  const q = gpos(id);
  if (q && q.x != null) return q;
  // no position yet (a new group): newGroupPos; before it is drawn, near the main group
  const ge = groupEls.find((x) => x.g.id === id), el = ge && ge.el;
  if (barEl._box && el && el._box && el !== barEl) return newGroupPos(el);
  const m = mainPos();
  return { x: m.x + 280, y: m.y, pt: m.pt };
}
// = NewGroupPoint in Bar.lua (2026-11-15, user): a new group goes diagonally next to the main group, towards the middle
// of the screen (left and down for a bar at the top right), NEW_GROUP_GAP away; a shown group in the way pushes it
// further towards the middle; then kept on the screen. Returned as free position (TOPLEFT corner of the outline).
const NEW_GROUP_GAP = 20;
function newGroupPos(el) {
  const sw = screenEl.clientWidth, sh = screenEl.clientHeight, GAP = NEW_GROUP_GAP;
  const m = outlineOf(barEl), me = outlineOf(el);
  const toLeft = m.x + m.w / 2 > sw / 2, down = m.y + m.h / 2 < sh / 2;
  const clampX = (v) => Math.min(Math.max(v, 0), Math.max(sw - me.w, 0));
  const clampY = (v) => Math.min(Math.max(v, 0), Math.max(sh - me.h, 0));
  let X = clampX(toLeft ? m.x - GAP - me.w : m.x + m.w + GAP);
  let Y = clampY(down ? m.y + m.h + GAP : m.y - GAP - me.h);
  for (let k = 0; k < 20; k++) {
    let hit = false;
    for (const x of groupEls) {
      if (x.el === el || x.el._hidden || !x.el._box || x.el.style.display === "none") continue;
      const o = outlineOf(x.el);
      if (X < o.x + o.w + GAP && X + me.w + GAP > o.x && Y < o.y + o.h + GAP && Y + me.h + GAP > o.y) {
        // further towards the middle sideways; no room on the screen there: below (above) that group instead
        const nx = toLeft ? o.x - GAP - me.w : o.x + o.w + GAP;
        if (nx === clampX(nx)) X = nx; else Y = clampY(down ? o.y + o.h + GAP : o.y - GAP - me.h);
        hit = true;
      }
    }
    if (!hit) break;
  }
  return { x: Math.round(X), y: Math.round(-Y), pt: "TOPLEFT" };
}
// stores where a group is right now as its free position (snap released): the corner el._anchorPt of its outline as
// offset from the same corner of the screen (= SetFree in Bar.lua, 2026-11-14; before the centre of the element)
function setFree(el) {
  const id = el._g.id, sw = screenEl.clientWidth, sh = screenEl.clientHeight, pt = el._anchorPt || "TOPLEFT";
  const o = outlineOf(el), [ox, oy] = pointOffset(pt, o.w, o.h), [rx, ry] = pointOffset(pt, sw, sh);
  const x = Math.round(o.x + ox - rx), y = Math.round(ry - (o.y + oy));
  if (id === "main") { profile.point = [pt, "UIParent", pt, x, y, "outline"]; delete profile.groupPos.main; }
  else profile.groupPos[id] = { x, y, pt };
}
// = NeedsResave in Bar.lua: the stored free position is older (centre) or for another corner
function needsResave(el) {
  const id = el._g.id, want = el._anchorPt || "TOPLEFT";
  if (id === "main") return profile.point[5] !== "outline" || profile.point[0] !== want;
  const q = gpos(id);
  return !!q && q.x != null && q.pt !== want;
}
// true if group a hangs (directly or through others) on group b
function dependsOn(a, b) {
  const seen = new Set();
  for (let cur = a; cur && !seen.has(cur); ) { seen.add(cur); const q = gpos(cur); cur = q && q.snap; if (cur === b) return true; }
  return false;
}
const SIDE_NAME = { bottom: L("below"), top: L("above"), left: L("left of"), right: L("right of") };
// top-left corner for a box w x h at the given side of rect t (bottom/top aligned like the target's rows)
// dInset = iconInset(group) - iconInset(target): left/right of the target the icons line up (2026-11-15, user)
// gap between two snapped outlines: fixed since session 20 (before row spacing of "Alle Gruppen" + 2) = SnapGap in Lua
const SNAP_GAP = PROFILE_DEFAULTS.rowSpacing + 2;
// Eight snap points (2026-11-18, user; = SnapXY in BarGroups.lua): every side has a start and an end. Above/below:
// "start" = left-aligned, "end" = right-aligned; left/right of the target: "start" = first icon lines at the same height,
// "end" = last icon lines at the same height. align = "start" | "end"; dInset = iconInset(group) - iconInset(target),
// dBottom = iconBottomInset(group) - iconBottomInset(target).
function snapXY(t, side, w, h, align, dInset, dBottom) {
  // gap between two outlines (session 4b: layout by outlines)
  const GAP = SNAP_GAP, end = align === "end";
  if (side === "bottom") return { X: end ? t.x + t.w - w : t.x, Y: t.y + t.h + GAP };
  if (side === "top") return { X: end ? t.x + t.w - w : t.x, Y: t.y - h - GAP };
  const Y = end ? t.y + t.h - h + (dBottom || 0) : t.y - (dInset || 0);
  if (side === "right") return { X: t.x + t.w + GAP, Y };
  return { X: t.x - w - GAP, Y };
}
// = SlotAlign in BarGroups.lua: the end of the side a snap q uses on target element tEl. Stored since 2026-11-18
// (q.align); older snaps: above/below like the target's rows (right-aligned = "end"), beside it the top ("start")
const slotAlign = (q, tEl) => (q && (q.align === "start" || q.align === "end") ? q.align
  : q && (q.side === "bottom" || q.side === "top") && tEl && tEl._alignR ? "end" : "start");
// = ALIGN_NAME in OptionsRefresh.lua: the end of a side in words
const ALIGN_NAME = { start: { v: L("(left)"), h: L("(top)") }, end: { v: L("(right)"), h: L("(bottom)") } };
const slotName = (side, align) => SIDE_NAME[side] + " " + ALIGN_NAME[align][side === "bottom" || side === "top" ? "v" : "h"];
// = IconInset in BarGroups.lua (2026-11-15, user: the icons of "Unwanted Buffs" sat 4 px lower than those of Buffs &
// Cons beside it, its button frame lies around them): how far the first icon line lies below the top of the outline
// (#screen units, y down). Measured on the icons themselves; no icons (empty, placeholder): the top of the box.
function iconInset(el) {
  const icons = [...el.querySelectorAll(".cb-btn, .cb-other")].filter((i) => i.offsetParent && i.getBoundingClientRect().height > 0);
  const o = outlineOf(el), pad = moverPad(el) * (el._p.scale || 1);
  if (!icons.length) return pad;
  const sr = screenEl.getBoundingClientRect();
  const top = Math.min(...icons.map((i) => i.getBoundingClientRect().top)) - sr.top - screenEl.clientTop;
  return top - o.y;
}
// = IconBottomInset in BarGroups.lua (2026-11-18): how far the last icon line ends above the bottom of the outline. Only
// groups with rows (= f.iconBottom in Bar.lua); areas and groups without icons: the padding of the outline
function iconBottomInset(el) {
  const pad = moverPad(el) * (el._p.scale || 1);
  if (el._area) return pad;
  const icons = [...el.querySelectorAll(".cb-btn")].filter((i) => i.offsetParent && i.getBoundingClientRect().height > 0);
  if (!icons.length) return pad;
  const o = outlineOf(el), sr = screenEl.getBoundingClientRect();
  const bottom = Math.max(...icons.map((i) => i.getBoundingClientRect().bottom)) - sr.top - screenEl.clientTop;
  return o.y + o.h - bottom;
}
// = LayoutGroups(): free groups at their position, snapped groups at the edge of their target (they follow it when it
// grows). A snap target that is not shown (no visible row) passes its own snap on; loops fall back to free.
function layoutGroups() {
  // hidden = an area group with nothing to show (2026-11-11): not placed, what hangs on it takes its snap
  const vis = groupEls.filter((x) => !x.el._hidden), shown = new Map(vis.map((x) => [x.g.id, x.el]));
  for (const x of groupEls) x.el.style.display = barWanted() && !x.el._hidden ? "" : "none";
  // = Resolve in BarGroups.lua: id = target of a group snapped on side. A hidden target passes on its place: the group
  // goes where the last hidden group of the chain would be, on that group's side of the shown one (2026-11-18, user: a
  // group snapped below the empty "Unerwünschte Buffs", which hang left of Buffs & Cons, went below Buffs & Cons)
  // q0 = the snap of the group; returns the shown target and the snap whose side and end count (q0 or the last hidden)
  const resolve = (q0) => {
    const seen = new Set();
    let cur = q0.snap, q = q0;
    while (cur && !shown.has(cur) && !seen.has(cur)) {
      seen.add(cur);
      const n = gpos(cur);
      if (!n || !n.snap) return { free: freePos(cur) };
      cur = n.snap; q = n;
    }
    return shown.has(cur) ? { id: cur, q } : null;
  };
  const placed = new Set(), docked = new Map(); // docked: id -> side it is snapped on (separator)
  for (let progress = true; progress; ) {
    progress = false;
    for (const x of vis) {
      const id = x.g.id;
      if (placed.has(id)) continue;
      const q = gpos(id);
      if (!q && id !== "main") continue; // no position yet (new group): placed last, next to the others (newGroupPos)
      if (!q || !q.snap) {
        placeFree(x.el, freePos(id));
        // older centre position or other orientation: store the corner where the group is now (2026-11-14)
        if (!moverDrag && !sim.combat && needsResave(x.el)) setFree(x.el);
        placed.add(id); progress = true; continue;
      }
      const r = resolve(q);
      if (!r || r.free) { placeFree(x.el, r ? r.free : freePos(id)); placed.add(id); progress = true; continue; }
      if (!placed.has(r.id)) continue; // target first
      // laid out by outlines since session 4b (= OutlineOf/PlaceOutline in Bar.lua): framed and unframed line up
      const tEl = shown.get(r.id), t = outlineOf(tEl), me = outlineOf(x.el);
      const p = snapXY(t, r.q.side, me.w, me.h, slotAlign(r.q, tEl), iconInset(x.el) - iconInset(tEl), iconBottomInset(x.el) - iconBottomInset(tEl));
      placeOutline(x.el, p.X, p.Y);
      docked.set(id, r.q.side);
      placed.add(id); progress = true;
    }
  }
  for (const x of vis) {
    if (placed.has(x.g.id)) continue;
    placeFree(x.el, freePos(x.g.id)); // loop, or a new group without position: free
    // a new group keeps the place it gets with its first row (2026-11-15), so it never jumps when the others change;
    // as an empty placeholder it is placed anew each time, so its real size counts once rows come in
    if (!gpos(x.g.id) && x.g.id !== "main" && !x.el._placeholder && !moverDrag && !sim.combat) setFree(x.el);
  }
  // separators by group id (group elements are rebuilt, the lines stay); groups that are gone lose theirs
  for (const id of Object.keys(sepEls)) if (!groupEls.some((x) => x.g.id === id)) sepEls[id].style.display = "none";
  for (const x of groupEls) placeSeparator(x, vis.includes(x) ? docked.get(x.g.id) : null);
}
const sepEls = {};
// = sepOn / SeparatorOn in Bar.lua (2026-11-14): option "Trenner anzeigen"; nil = default, on for Sonstige and Debuffs
const sepOn = (g) => !!g && (g.separator != null ? !!g.separator : g.area === "other" || g.area === "debuff");
// = PlaceSeparator in Bar.lua (2026-11-14, user): a thin line in the middle of the gap on the side where the group is
// docked (side = where it sits: "bottom" = below its target, so the line is above it). Free or hidden: no line.
// Replaces the fixed divider at the top of the debuff area (extra.debLine, 2026-11-11). Debuffs keep its red tint.
function placeSeparator(x, side) {
  let s = sepEls[x.g.id];
  if (!side || !sepOn(x.g) || !barWanted()) { if (s) s.style.display = "none"; return; }
  if (!s) { s = document.createElement("div"); s.className = "cb-sep"; screenEl.appendChild(s); sepEls[x.g.id] = s; }
  // style (2026-11-14): look, colour, thickness, inset at both ends; debuffs: own red style instead of .deb
  const st = styleOf(x.g, "sep"), n = st.size, ins = st.inset;
  const o = outlineOf(x.el), half = SNAP_GAP / 2, horiz = side === "bottom" || side === "top";
  const pos = side === "bottom" ? o.y - half : side === "top" ? o.y + o.h + half : side === "right" ? o.x - half : o.x + o.w + half;
  const len = Math.max((horiz ? o.w : o.h) - 2 * ins, 4), dir = horiz ? "90deg" : "180deg", c = hexA(st.color, st.alpha);
  const bg = st.look === "dashed" ? `repeating-linear-gradient(${dir}, ${c} 0 ${4 * n + 2}px, transparent ${4 * n + 2}px ${6 * n + 4}px)`
    : st.look === "dotted" ? `repeating-linear-gradient(${dir}, ${c} 0 ${n}px, transparent ${n}px ${3 * n}px)` : c;
  const mask = sepFadeMask(st.fade, dir); // fading ends for every look (2026-11-15)
  Object.assign(s.style, { background: bg, maskImage: mask, webkitMaskImage: mask }, horiz
    ? { display: "block", left: (o.x + (o.w - len) / 2) + "px", top: Math.round(pos - (n - 1) / 2) + "px", width: len + "px", height: n + "px" }
    : { display: "block", left: Math.round(pos - (n - 1) / 2) + "px", top: (o.y + (o.h - len) / 2) + "px", width: n + "px", height: len + "px" });
}
const positionBar = () => { if (groupEls.length) layoutGroups(); };

// Buff areas as own groups (groups phase 2, 2026-11-11): "Unerwünschte Buffs", "Sonstige Buffs" (counter, other buffs,
// weapon enchants without an icon) and "Debuffs". Plain frames, no secure buttons except the unwanted macro button.
// Each one is a group (g.area) with its own position: free, or snapped to another group's edge (default: unw below the
// main group, other below unw, debuff below other = the old look). Their size comes from page "Darstellung" (tabs
// "Sonstige Buffs" / "Debuffs"); "Unerwünscht" uses the size of "Sonstige". Snapped above/below a group their lines
// are at most as wide as that group, so they end flush with it (like before with the bar).
let areaEls = {}, areaPreview = false; // area -> element; previews shown (options open, Shift over a group, dragging)
// group this area hangs on (directly or through hidden ones), if it hangs above or below
function areaAnchor(id) {
  const seen = new Set();
  for (let q = gpos(id); q && q.snap && !seen.has(q.snap); q = gpos(q.snap)) {
    seen.add(q.snap);
    if (q.side !== "bottom" && q.side !== "top") return null;
    const t = groupEls.find((x) => x.g.id === q.snap);
    if (t) return t.el;
  }
  return null;
}
function areaLimit(id) { const t = areaAnchor(id); return t ? (t._area ? t._w : t.offsetWidth) : null; }
function buildAreas(P) {
  areaEls = {};
  let after = groupEls.length ? groupEls[groupEls.length - 1].el : barEl;
  for (const g of P.groups) {
    if (!g.area) continue;
    const el = document.createElement("div");
    el.className = "cb-container cb-group cb-area";
    after.after(el); after = el;
    el._g = g; el._p = P; el._area = g.area;
    el.classList.toggle("noborder", g.showBorders !== true); // per group (session 4d), no "Alle Gruppen" since session 20
    el.classList.toggle("notime", !gEff(g, "showTime", P)); // "Zeit anzeigen" (2026-11-14)
    groupEls.push({ g, el, p: P });
    areaEls[g.area] = el;
    const anchor = areaAnchor(g.id);
    // own orientation only since session 20 (user: no "Automatic"; before like the group it hangs on, else like "All
    // Groups"); no value = the default "Rows right" (= LayoutAreas in Bar.lua)
    el._alignR = g.orientation !== "hleft";
    el._anchorPt = anchorPoint(el._alignR); // corner a free area grows away from (2026-11-14)
    el._up = false;
    const kind = g.area === "other" ? undefined : g.area;
    const { size, sp, per, lineH } = otherSize(P, kind, g.id);
    el._w = per * (size + sp) - sp;
    el.style.width = el._w + "px"; el.style.height = "1px";
    el.style.transform = "scale(1)"; el.style.transformOrigin = "center center"; el.style.right = "auto"; // own scale: areaLayout
    // names like the rows' names; "Namen zeigen" of the group switches them off (2026-11-11)
    // the name is the group name (2026-11-15 proposal, user: every group alike): on top, on the side of the alignment,
    // looks like the name of a row group; before like a row name at the position of the row names
    el._pos = gEff(g, "showName") ? "top" + nameAlignOf(g) : null; // own flag and alignment (no "Alle Gruppen" since session 20)
    extraEl = el;
    if (g.area === "unw") {
      el.innerHTML = `<div class="cb-unwrow" id="unwRow"></div><div class="cb-label cb-xname" id="nameUnw"></div>`;
      el.appendChild(previewBox(P, "unwPreview", "unw", 0, 1, 1, false, L("Unwanted buffs appear here"), "unw", g.id));
      const unw = el.querySelector(".cb-unwrow");
      unw._alignR = el._alignR; unw._up = false;
      unw.addEventListener("click", () => { if (!justMoved) removeUnwanted(); });
      unw.addEventListener("mousemove", showUnwantedTip); unw.addEventListener("mouseleave", hideTip);
    } else if (g.area === "other") {
      // the counter moved to the main group in session 4b
      el.innerHTML = `<div class="cb-others"></div><div class="cb-label cb-xname" id="nameOther"></div>`;
      el._pvCells = null;
    } else {
      el.innerHTML = `<div class="cb-others"></div><div class="cb-label cb-xname" id="nameDebuff"></div>`;
      const dper = otherSize(P, "debuff", g.id).per;
      el.appendChild(previewBox(P, "debuffPreview", "deb", 0, Math.ceil(DEBUFF_CAP / dper), DEBUFF_CAP, false, fmt(L("Debuffs: max. %d"), DEBUFF_CAP), "debuff", g.id));
    }
    el.querySelector(".cb-xname").textContent = groupName(g);
    el.querySelector(".cb-xname").classList.add("cb-gname");
    // frame (optional), tint and outline like the row groups; sizes follow the measured box (finishArea)
    if (frameOn(g)) { const fr = document.createElement("div"); fr.className = "cb-gframe"; applyFrameStyle(fr, g); el.insertBefore(fr, el.firstChild); el._frame = fr; }
    applyIconStyle(el, g); // icon border style (2026-11-14)
    el.style.setProperty("--tfs", gEff(g, "timeSize", P) + "px"); // font size of the time (2026-11-14)
    const tint = document.createElement("div"); tint.className = "cb-tint"; el.insertBefore(tint, el.firstChild); el._tint = tint;
    const mover = document.createElement("div"); mover.className = "cb-mover"; el.appendChild(mover); el._mover = mover;
    el._box = { l: 0, t: 0, w: el._w, h: 16 };
    // Shift+drag (options open: plain drag) anywhere on the area moves it, also on an empty preview box
    el.addEventListener("mousedown", (e) => { if (e.button === 0 && (e.shiftKey || (sim.optionsOpen && !e.ctrlKey))) startMove(e, el); });
  }
  extraEl = areaEls.other || null;
}
// outline box of a group (2026-11-11, user: outlines looked shifted): the same for every group, exactly on the frame
// (moverPad 0) or MOVER_PAD around icons and names without one
function sizeMover(x) {
  const b = x.el._box, mv = x.el._mover, pad = moverPad(x.el);
  if (!b || !mv) return;
  const nh = x.el._nameH || 0; // = Decorate in Bar.lua: outline on the frame, the name line above stays outside
  mv.style.left = (b.l - pad) + "px"; mv.style.top = (b.t + nh - pad) + "px";
  mv.style.width = (b.w + pad * 2) + "px"; mv.style.height = (b.h - nh + pad * 2) + "px";
}
// = PlaceAbs() in Bar.lua: position from the left or right edge of the area (side "left" / "right"), y from the
// edge next to the bar (mirrored when growing up)
function placeAbs(el, side, x, y) {
  el.style.left = el.style.right = el.style.top = el.style.bottom = "auto";
  el.style[side] = x + "px";
  el.style[extraEl._up ? "bottom" : "top"] = y + "px";
}
const namesAbove = () => !!extraEl._pos && extraEl._pos.startsWith("top");
const nameSide = () => extraEl._pos && extraEl._pos.endsWith("right") ? "right" : "left";
// = PlaceName() in Bar.lua: name of a wrapping row whose lines start at y0 and take n lines. A line takes the icon
// plus the timer below it (growing up: the timer lies towards the bar). first = "Sonstige Buffs" (counter line).
// boxW (2026-11-11, row "Unerwünschte Buffs"): the row is a framed button only as wide as boxW; its name keeps
// clear of the frame (4 px further out) and lines up with the button's edge, not the area's.
function placeName(el, y0, n, lineH, size, sp, first, boxW) {
  const pos = extraEl._pos, up = extraEl._up, pad = boxW ? 4 : 0;
  if (pos === "topcenter") { // centred over the area, or over the button of "Unerwünschte Buffs" (2026-11-15, = PlaceName)
    const cx = boxW ? (extraEl._alignR ? extraEl._w - boxW / 2 : boxW / 2) : extraEl._w / 2;
    el.style.right = el.style.bottom = "auto"; el.style.left = cx + "px"; el.style.top = (y0 - 1 - pad) + "px";
    el.style.transform = "translate(-50%, -100%)";
    return;
  }
  // name on the side away from the area's alignment: ends at the button's edge instead of the area's, but never
  // sticks out of the area when the name is wider than the button
  const x = boxW && (nameSide() === "right") !== !!extraEl._alignR ? Math.max(extraEl._w - Math.max(boxW, el.offsetWidth), 0) : 0;
  el.style.transform = "none";
  if (pos.startsWith("top")) {
    // like the rows' names (user 2026-11-10: same gap): bottom edge 1 px above the first line. The first row
    // reaches into the counter line (the counter sits on the other side), later rows get NAME_GAP before them.
    if (up) placeAbs(el, nameSide(), x, y0 - 26);
    else { placeAbs(el, nameSide(), x, y0 - 1 - pad); el.style.transform = "translateY(-100%)"; }
  } else if (pos.startsWith("bottom")) {
    // after the far edge of the last line
    const last = y0 + (n - 1) * lineH;
    placeAbs(el, nameSide(), x, up ? last + size + 2 : last + size + AREA_TIMER_H + 1 + pad);
  } else {
    // beside the first line, outside the area like the rows' names (left: right edge 6 px left of the area)
    placeAbs(el, pos === "left" ? "right" : "left", extraEl._w + 6, y0 + size / 2);
    el.style.transform = up ? "translateY(50%)" : "translateY(-50%)";
  }
}
// position inside the buff area, measured from its anchor corner (mirrored when right-aligned / growing up)
function placeX(el, x, y, box) {
  box = box || extraEl;
  el.style.left = el.style.right = el.style.top = el.style.bottom = "auto";
  el.style[box._alignR ? "right" : "left"] = x + "px";
  el.style[box._up ? "bottom" : "top"] = y + "px";
}

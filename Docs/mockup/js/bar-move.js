"use strict";
/* RaidKit Buffs mockup: Shift+drag, snapping, mover (= BarMove.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// = Bar.lua: Shift+drag on an icon moves its group (2026-11-11; before: the bar); no lock, no handle. Shift over a
// group shows its outline. While dragging, every group shows its outline; near another group's edge the dragged one
// snaps (green outline) and stays attached after letting go.
// 2026-11-11 (user: unclear which group the others hang on): the drag start decides what moves.
// - middle of a group: the whole docked cluster (every group that hangs on the same free group, its "root") moves; the
//   root is dragged and may snap to another group, the rest follows as before.
// - edge of a group (EDGE_W inside its outline): only this group; it comes loose, and whatever hung on it takes over
//   its snap (closes the gap, like a hidden area) or, if it was free, stays where it is.
// Hovering shows it before pressing: the outlines that would move turn yellow.
const SHOW_COUNTER = false; // = SHOW_COUNTER in Bar.lua (session 4c)
const MOVER_PAD = 2, HOVER_PAD = 8, EDGE_W = 12; // EDGE_W 8 -> 12 in session 4b (user: edge should work earlier)
const moverPad = (el) => (el._g && frameOn(el._g) ? 0 : MOVER_PAD);
// hint in the options (group panel and "Alle Gruppen"), = MOVE_HINT in Options.lua
const MOVE_HINT = L("Move: drag (window closed: Shift+drag). Middle of a group = with everything docked to it; edge = only this group, it detaches. Yellow = moves, green = snaps.");
let justMoved = false;
let moverDrag = null, barLabelWidth = 0, barLabelRight = 0, cursorX = null, cursorY = null, shiftDown = false;

// free group at the end of the snap chain of id (= RootOf in Bar.lua)
function rootOf(id) {
  const seen = new Set([id]);
  for (let cur = id; ; ) {
    const q = gpos(cur);
    if (!q || !q.snap || seen.has(q.snap)) return cur;
    cur = q.snap; seen.add(cur);
  }
}
// ids of every shown group with the same root (= the groups a drag from the middle moves)
function clusterOf(id) {
  const r = rootOf(id);
  return new Set(groupEls.filter((x) => rootOf(x.g.id) === r).map((x) => x.g.id));
}
// outline rect of a group in #screen coordinates
function outlineOf(el) {
  const r = rectOf(el), pad = moverPad(el) * (el._p.scale || 1);
  return { x: r.x - pad, y: r.y - pad, w: r.w + 2 * pad, h: r.h + 2 * pad };
}
// moves a group so that its outline starts at X/Y (= PlaceOutline in Bar.lua)
function placeOutline(el, X, Y) {
  const pad = moverPad(el) * (el._p.scale || 1);
  placeRect(el, X + pad, Y + pad);
}
// = Reroot in Bar.lua: id becomes the root of its cluster by turning the snaps between it and the old root around
const OPPOSITE = { bottom: "top", top: "bottom", left: "right", right: "left" };
function reroot(id) {
  const gp = profile.groupPos, chain = [id], seen = new Set([id]);
  for (;;) {
    const q = gp[chain[chain.length - 1]];
    if (!q || !q.snap || seen.has(q.snap)) break;
    chain.push(q.snap); seen.add(q.snap);
  }
  const sides = chain.slice(0, -1).map((c) => gp[c].side), aligns = chain.slice(0, -1).map((c) => gp[c].align);
  // the end stays (2026-11-18): B below A on the left = A above B on the left
  for (let i = chain.length - 2; i >= 0; i--) gp[chain[i + 1]] = { snap: chain[i], side: OPPOSITE[sides[i]] || "bottom", align: aligns[i] };
}
// visible outline (= VisibleOutline in Bar.lua, session 4c): without the name line above the frame
function visibleOutline(el) {
  const o = outlineOf(el), nh = (el._nameH || 0) * (el._p.scale || 1);
  return { x: o.x, y: o.y + nh, w: o.w, h: o.h - nh };
}
// = GroupAt in Bar.lua: the group whose visible outline contains the point, else the nearest within HOVER_PAD
function groupAt(mx, my) {
  let best = null, bestD = Infinity;
  for (const x of groupEls) {
    if (x.el.style.display === "none" || x.el._hidden) continue;
    const o = visibleOutline(x.el);
    const dx = Math.max(o.x - mx, 0, mx - (o.x + o.w)), dy = Math.max(o.y - my, 0, my - (o.y + o.h)), d = Math.hypot(dx, dy);
    if (d === 0) return x.el;
    if (d <= HOVER_PAD && d < bestD) { best = x.el; bestD = d; }
  }
  return best;
}
// true if the point (#screen coordinates) lies in the edge band of the group's visible outline or outside it
function onEdge(el, mx, my) {
  const o = visibleOutline(el);
  return mx < o.x + EDGE_W || mx > o.x + o.w - EDGE_W || my < o.y + EDGE_W || my > o.y + o.h - EDGE_W;
}
const screenXY = (cx, cy) => { const sr = screenEl.getBoundingClientRect(); return { mx: cx - sr.left, my: cy - sr.top }; };
// = DetachGroup in Bar.lua: el comes loose; what hung on it takes over its snap, or stays where it is
function detachGroup(el) {
  const id = el._g.id, mine = gpos(id), mineSnap = mine && mine.snap ? { snap: mine.snap, side: mine.side } : null;
  let changed = !!mineSnap;
  const hangers = Object.keys(profile.groupPos).filter((k) => k !== id && (profile.groupPos[k] || {}).snap === id);
  for (const k of hangers) {
    changed = true;
    // session 4c (user): what hung on el stays where it is (free), it no longer jumps into el's place
    const x = groupEls.find((y) => y.g.id === k && y.el.style.display !== "none");
    if (x) setFree(x.el);
    else delete profile.groupPos[k];
  }
  setFree(el);
  return changed;
}

function startMove(e, el) {
  e.preventDefault(); e.stopPropagation();
  if (sim.combat) return flash(L("Cannot be moved in combat")); // mockup-only text
  const { mx, my } = screenXY(e.clientX, e.clientY);
  // the group comes from the press point, not from the element that got the event (= StartMove in Bar.lua, session
  // 4c: widened outlines of neighbours overlap)
  el = groupAt(mx, my) || el || barEl;
  // nothing changes before the mouse really moves (a plain click on an edge must not detach anything)
  moverDrag = { el, x: e.clientX, y: e.clientY, edge: onEdge(el, mx, my), started: false, snap: null };
  hideTip();
  updateMover();
}
// first real movement: pick what moves (edge: this group alone, middle: the root of its cluster)
function beginMove(d) {
  let el = d.el;
  if (d.edge) {
    if (detachGroup(el)) flash(fmt(L("%s detached, only this group is moved."), groupName(el._g)));
  } else {
    const r = groupEls.find((x) => x.g.id === rootOf(el._g.id) && x.el.style.display !== "none");
    if (r) el = r.el; else { d.edge = true; detachGroup(el); } // root not shown: like the edge
    setFree(el); // the root is free already; keeps its place
  }
  layoutGroups();
  // every shown group of the dragged cluster may snap (session 4b): their outlines at the start
  const members = {};
  for (const id of clusterOf(el._g.id)) {
    const x = groupEls.find((y) => y.g.id === id && !y.el._hidden && y.el.style.display !== "none");
    if (x) members[id] = outlineOf(x.el);
  }
  members[el._g.id] = outlineOf(el);
  Object.assign(d, { el, members, started: true });
}
// = DragUpdate in Bar.lua (session 4b, user: snapping must not depend on where the drag started): every member of the
// dragged cluster against the four sides of every other shown group. A side counts when the gap is below SNAP_DIST
// and both outlines overlap along it (no need to hit the corner); the nearest wins and the cluster shifts onto it.
// = SideTaken in BarMove.lua (2026-11-15, user): a side of a group is taken when another group hangs there, or when the
// group itself hangs on that side of another one (below X = its top is taken). Groups not shown count too (an empty
// area comes back later); groups of the dragged cluster do not.
// Since 2026-11-18 (user: eight snap points) per end of a side: align "start"/"end" (slotAlign). The side a group itself
// hangs with is taken at both ends.
// A buff area above or below takes the whole side: its lines reach the width of the group it hangs on.
function sideTaken(id, side, members, align, tEl, mid) {
  const full = (k) => (side === "bottom" || side === "top") && !!(groupById(k) || {}).area;
  for (const [k, q] of Object.entries(profile.groupPos || {})) {
    if (q && q.snap === id && q.side === side && !members[k] && (full(k) || slotAlign(q, tEl) === align)) return true;
  }
  const own = gpos(id);
  if (own && own.snap && !members[own.snap] && OPPOSITE[own.side] === side) return true;
  // the snapping group mid is an area and goes above or below: it would take the whole side, so both ends must be free
  return (side === "bottom" || side === "top") && !!(groupById(mid) || {}).area
    && Object.entries(profile.groupPos || {}).some(([k, q]) => q && q.snap === id && q.side === side && !members[k]);
}
function dragGroup(e) {
  const d = moverDrag;
  if (!d.started) {
    if (Math.hypot(e.clientX - d.x, e.clientY - d.y) < 4) return;
    beginMove(d);
  }
  const dx = e.clientX - d.x, dy = e.clientY - d.y;
  let best = null;
  for (const [mid, r0] of Object.entries(d.members)) {
    const m = { x: r0.x + dx, y: r0.y + dy, w: r0.w, h: r0.h };
    for (const x of groupEls) {
      if (d.members[x.g.id] || x.el._hidden || x.el.style.display === "none") continue;
      const t = outlineOf(x.el);
      for (const side of ["bottom", "top", "right", "left"]) {
        const vert = side === "bottom" || side === "top";
        // which end (2026-11-18, user): the half of the side the dragged group's middle is over; that end taken = the
        // other one, both taken = none (only free ends, 2026-11-15)
        const want = vert ? (m.x + m.w / 2 < t.x + t.w / 2 ? "start" : "end") : (m.y + m.h / 2 < t.y + t.h / 2 ? "start" : "end");
        const align = [want, want === "start" ? "end" : "start"].find((a) => !sideTaken(x.g.id, side, d.members, a, x.el, mid));
        if (!align) continue;
        const mEl = (groupEls.find((g) => g.g.id === mid) || {}).el; // beside the target the icons line up (2026-11-15)
        const p = snapXY(t, side, m.w, m.h, align, mEl ? iconInset(mEl) - iconInset(x.el) : 0, mEl ? iconBottomInset(mEl) - iconBottomInset(x.el) : 0);
        const dist = vert ? Math.abs(p.Y - m.y) : Math.abs(p.X - m.x);
        const overlap = vert ? (m.x < t.x + t.w && m.x + m.w > t.x) : (m.y < t.y + t.h && m.y + m.h > t.y);
        if (overlap && dist < SNAP_DIST && (!best || dist < best.dist)) best = { member: mid, id: x.g.id, side, align, dist, ox: p.X - m.x, oy: p.Y - m.y };
      }
    }
  }
  d.snap = best; d.moved = true;
  const r = d.members[d.el._g.id];
  placeOutline(d.el, r.x + dx + (best ? best.ox : 0), r.y + dy + (best ? best.oy : 0));
  setFree(d.el); layoutGroups();
  updateMover();
}

// = CursorOverGroup() in Bar.lua: the shown group under the cursor, or null. A group whose outline contains the cursor
// wins; else one within HOVER_PAD of its outline (2026-11-11: neighbours sit closer than that)
function cursorOverGroup() {
  if (cursorX == null) return null;
  const { mx, my } = screenXY(cursorX, cursorY);
  return groupAt(mx, my);
}
const cursorOverBar = () => !!cursorOverGroup();

// = UpdateMover() in Bar.lua
function updateMover() {
  const m = document.getElementById("mover");
  if (!m) return;
  // options window open: outlines and preview stay visible (editing mode), not during the demo (2026-11-10)
  const edit = !!moverDrag || (sim.optionsOpen && !demo);
  const over = !sim.combat && !moverDrag && (edit || shiftDown) ? cursorOverGroup() : null;
  // what would move (hover) or moves (drag): middle = the docked cluster, edge = the group alone (2026-11-11)
  let hot = new Set();
  if (moverDrag) hot = moverDrag.started || !moverDrag.edge ? clusterOf(moverDrag.el._g.id) : new Set([moverDrag.el._g.id]);
  else if (over) {
    const { mx, my } = screenXY(cursorX, cursorY);
    hot = onEdge(over, mx, my) ? new Set([over._g.id]) : clusterOf(over._g.id);
  }
  for (const x of groupEls) {
    const mv = x.el._mover, h = hot.has(x.g.id);
    sizeMover(x);
    mv.classList.toggle("show", !sim.combat && x.el.style.display !== "none" && (edit || h));
    mv.classList.toggle("edit", edit && !sim.combat);
    mv.classList.toggle("mouse", shiftDown && !sim.combat); // = EnableMouse with Shift in Bar.lua (2026-11-14)
    mv.classList.toggle("hot", h && !moverDrag);
    mv.classList.toggle("drag", !!moverDrag && h);
    mv.classList.toggle("snap", !!moverDrag && h && !!moverDrag.snap);
  }
  const show = m.classList.contains("show");
  // "Demo-Modus" beside the outline box (also while the box is hidden): left of a bar in the right half, else right
  const dl = document.getElementById("demoLabel");
  if (dl) {
    const on = !!demo && barEl.style.display !== "none";
    dl.style.display = on ? "block" : "none";
    if (on) {
      // since 2026-11-15 (user: "Unwanted Buffs" docked on the left covered it; = UpdateMover in BarGroups.lua): on the
      // screen, 10 px beyond every shown group whose outline reaches into the line of the text, centred on Buffs & Cons
      if (dl.parentNode !== screenEl) screenEl.appendChild(dl);
      const r = barEl.getBoundingClientRect(), sr = screenEl.getBoundingClientRect();
      let leftSide = r.left + r.width / 2 > sr.left + sr.width / 2;
      // what is really drawn, not the outline (2026-11-15, user: in the game the text ended up in the middle of the
      // screen; the outline of "Unwanted Buffs" keeps room for every buff of its list) = ShownRect in BarGroups.lua
      const shownRect = (el) => {
        let q = null;
        for (const c of el.querySelectorAll(".cb-btn, .cb-other, .cb-unwrow, .cb-label, .cb-gname, .cb-xname")) {
          const b = c.getBoundingClientRect();
          if (!c.offsetParent || !b.width || !b.height || getComputedStyle(c).visibility === "hidden") continue;
          const x0 = b.left - sr.left - screenEl.clientLeft, y0 = b.top - sr.top - screenEl.clientTop;
          q = q ? { l: Math.min(q.l, x0), t: Math.min(q.t, y0), r: Math.max(q.r, x0 + b.width), b: Math.max(q.b, y0 + b.height) }
            : { l: x0, t: y0, r: x0 + b.width, b: y0 + b.height };
        }
        return q;
      };
      const o = outlineOf(barEl), m0 = shownRect(barEl) || { l: o.x, t: o.y, r: o.x + o.w, b: o.y + o.h };
      const cy = (m0.t + m0.b) / 2, half = dl.offsetHeight / 2 + 4;
      let left = m0.l, right = m0.r;
      for (const x of groupEls) {
        if (x.el === barEl || x.el._hidden || x.el.style.display === "none") continue;
        const t = shownRect(x.el);
        if (t && t.t < cy + half && t.b > cy - half) { left = Math.min(left, t.l); right = Math.max(right, t.r); }
      }
      // no room on that side of the screen: the other side (= UpdateMover)
      if (leftSide && left - 10 - dl.offsetWidth < 0) leftSide = false;
      else if (!leftSide && right + 10 + dl.offsetWidth > screenEl.clientWidth) leftSide = true;
      dl.style.top = (cy - dl.offsetHeight / 2) + "px";
      if (leftSide) { dl.style.left = ""; dl.style.right = (screenEl.clientWidth - left + 10) + "px"; }
      else { dl.style.right = ""; dl.style.left = (right + 10) + "px"; }
    }
  }
  // together with the outlines (2026-11-11: options open, dragging, or Shift over any group): every buff area shows its
  // preview box ("Sonstige" at its maximum size, debuffs, an empty "Unerwünscht"), so empty ones can be dragged too
  void show;
  const pvNow = !sim.combat && barWanted() && (edit || !!over);
  if (pvNow !== areaPreview) { areaPreview = pvNow; renderExtras(now()); }
}
window.addEventListener("keydown", (e) => { if (e.key === "Shift" && !shiftDown) { shiftDown = true; updateMover(); } });
window.addEventListener("keyup", (e) => { if (e.key === "Shift") { shiftDown = false; updateMover(); } });
window.addEventListener("blur", () => { shiftDown = false; updateMover(); });

function drawCooldown(canvas, start, dur, t) {
  const ctx = canvas.getContext("2d"), w = canvas.width, h = canvas.height;
  ctx.clearRect(0, 0, w, h);
  if (!dur || start + dur <= t) return;
  ctx.fillStyle = "rgba(0,0,0,.65)";
  ctx.beginPath(); ctx.moveTo(w / 2, h / 2);
  ctx.arc(w / 2, h / 2, w, -Math.PI / 2, -Math.PI / 2 + (1 - (t - start) / dur) * Math.PI * 2);
  ctx.closePath(); ctx.fill();
}

function updateAll() {
  const t = now();
  detectLosses(t);
  for (const b of barButtons) {
    const id = shownVariant(b._entry), info = itemInfo(id);
    // weapon entries: state of the hand (Windfury on the main hand shows the Windfury icon, counts as active)
    const ws = isWeaponEntry(b._entry) ? weaponEntryState(b._entry) : null;
    let st = ws || itemBuffState(id);
    const count = sim.counts[id] || 0;
    // demo (2026-11-10): some inactive icons look active (= UpdateButton in Bar.lua); key = row,index
    if (!st.active && demo && demo.rows[b.dataset.key]) st = { active: true, exp: demo.rows[b.dataset.key], dur: itemInfo(id).dur };
    // mount entry (2026-11-17, = UpdateButton in BarState.lua): the icon of the real mount while riding, else the
    // mount Ctrl+click would mount (2026-11-19, mountPick); none = the catalog icon
    const mountIcon = !info.mount ? null : st.active && st.sp ? spellInfo(st.sp).icon : !st.active && mountPick() ? mountPick().icon : null;
    const iconKey = ws && ws.wf ? "wf" : mountIcon ? "m:" + mountIcon : String(id);
    if (b.dataset.id !== iconKey) {
      b.dataset.id = iconKey;
      if (ws && ws.wf) b.querySelector(".icon").style.backgroundImage = `url(${ICON_URL(WINDFURY.icon)})`;
      else if (mountIcon) b.querySelector(".icon").style.backgroundImage = `url(${ICON_URL(mountIcon)})`;
      else setIcon(b.querySelector(".icon"), id);
    }
    b.classList.toggle("wf", !!(ws && ws.wf));
    b.classList.toggle("missing", !st.active);
    b.classList.toggle("lost", entIds(b._entry).some((x) => (sim.lost[auraOfItem(x)] || 0) > t));
    b.querySelector(".border").style.background = st.active ? `var(--bc-active, ${BORDER.active})` : `var(--bc-missing, ${BORDER.missing})`; // colours per group (2026-11-14)
    // status mark: lock = Flask/Zanza locked in combat; green check / red ⊘ only with SHOW_STATUS_MARKS (= Bar.lua)
    const mark = b.querySelector(".st"), locked = sim.combat && sim.locked.has(btnKey(b));
    mark.className = "st " + (locked ? "lock" : st.active ? "ok" : "no");
    mark.style.display = locked || SHOW_STATUS_MARKS ? "" : "none"; // check/cross off since 2026-11-10 (user), lock stays
    mark.textContent = locked ? "🔒" : st.active ? "✓" : "⊘";
    const c = b.querySelector(".count");
    // "Anzahl in Taschen" per group (session 4d) = GroupOpt in Bar.lua; the live group of the profile like btn.grp in
    // Lua (2026-11-22, user: in combat the snapshot _g only changed after combat, so the box had no effect there)
    const lg = b.parentElement && b.parentElement._g, bg = lg && (groupById(lg.id) || lg);
    c.style.display = bg && bg.showCount === true && !info.isBuff ? "" : "none"; // buffs have no bag count; per group only since session 20
    c.textContent = count;
    c.style.color = count > 0 ? "#fff" : "rgb(255,51,51)";
    const tm = b.querySelector(".timer"), showT = st.active && st.exp !== Infinity;
    tm.textContent = showT ? fmtTime(Math.max(st.exp - t, 0)) : "";
    tm.classList.toggle("low", showT && isLowTime(st.exp - t, st.dur)); // yellow at 10 % (2026-11-12)
    // cooldown swipe only on inactive icons (user 2026-11-10: after drinking, the dark "clock" over the
    // now active icon is just noise; while the buff is missing it tells when the next one can be used)
    const cd = st.active ? null : sim.cooldowns[info.cat === "potion" ? "potion" : ("item" + id)];
    drawCooldown(b.querySelector(".cd"), cd && cd.start, cd && cd.dur, t);
  }
  renderExtras(t);
  renderBuffFake();
}

/* ----- Buff area below the bar (proposal 2026-11-09) ----- */
// spells shown by a visible row (all variants); everything else active goes to "Sonstige"
function coveredSpells() {
  const s = new Set();
  for (const row of barLayout.rows) for (const en of row.items) for (const id of entIds(en)) for (const sp of buffSpellsForItem(id)) s.add(String(sp));
  return s;
}
// warning before hiding "Sonstige Buffs" / "Debuffs" (texts chosen by the user 2026-11-12; = Options.lua)
const AREA_HIDE_TEXT = {
  other: L("Hide \"Other Buffs\"?\n\nYou will no longer see buffs that are not in any row: procs, HoTs, trinkets and buffs from others. As long as RaidKit Buffs replaces the Blizzard bar, they show up nowhere.\n\nNot recommended. Only hide them if another addon shows them.") + "\n\n[OK = " + L("Hide anyway") + "]",
  debuff: L("Hide \"Debuffs\"?\n\nAs long as RaidKit Buffs replaces the Blizzard bar, you will no longer see any debuffs on yourself, not even curses, poisons or boss debuffs.\n\nNot recommended. Only hide them if another addon shows them.") + "\n\n[OK = " + L("Hide anyway") + "]",
};
// "Unerwünschte Buffs" hidden (eye of the group, 2026-11-12): no unwanted buffs, they show under "Sonstige"
const unwantedSpells = () => (groupById("unw") || {}).hidden ? new Set() : new Set((profile.unwanted || []).flatMap((id) => buffSpellsForItem(id).map(String)));
const activeUnwanted = (t) => { const u = unwantedSpells(); return activeAuras(t).filter((sp) => u.has(sp)); };
// row "Unerwünschte Buffs" (2026-11-10): real ones as { s } plus the demo's as { a }, real ones first
const unwantedNow = () => { const u = unwantedSpells(); return activeUnwanted(now()).map((s) => ({ s }))
  .concat(demo ? demo.buffs.filter((a) => u.has(String(a.id))).map((a) => ({ a })) : []); };

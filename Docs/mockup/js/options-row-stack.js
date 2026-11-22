"use strict";
/* RaidKit Buffs mockup: the rows of a group on its Layout tab (= OptionsRowStack.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// Since 2026-11-16 (user): the list on the left shows only groups; a group shows all its rows on the Layout tab (instead
// of the grey preview), one line per row, the options of the group below them. No row names any more.
// A line: grip (drag = move the row: onto another line = there, onto a group in the list = into that group), the places
// of the group (light squares, "Per line"), the icons, a split row with its X (bar-split.js); right of it the checkbox
// separator choice (2026-11-17, before the checkbox "Split row"), the eye (row hidden on the bar) and "-" (delete the row). Click on a free spot = active row (gold): a click
// in the catalog adds there. Icons: drag within the row, into another row of the group, out (= removed); right-click
// removes; the alternatives column opens below every icon. Below the lines: "+ Row" (empty or template, at most
// MAX_GROUP_ROWS per group).
const STK_PL = 16; // x of the first place of a full line (grip before it)
// x of the first place of a line of a group with W places (2026-11-20, user): the places stand centred between the grip
// and the separator box, so a smaller "Per line" shrinks the row towards the middle instead of towards the left
const stkPL = (W) => STK_PL + Math.floor((ITEMS_PER_LINE - W) * ITEM_STEP / 2);
// SEP_HIT: width of the grip around the separator line of a split row (session 20)
const SEP_HIT = 10;
const STK_END = STK_PL + ITEMS_PER_LINE * ITEM_STEP - ITEM_GAP; // 494: right edge of the last place
// centres 18 px apart (session 20, user: "take a little room from between the three"): 11 px after the last place, 3 px
// between box, eye and "-"
// since the fourth in-game test of 2026-11-17 the separator box is 28 px wide (dot variants): centres +22, +47, +65
const STK_CB = STK_END + 22, STK_EYE = STK_END + 47, STK_DEL = STK_END + 65;
function createRowStack() {
  C.stack = Place(mk("div", "grid-area sstack"), GRID_X - 4, GRID_Y + STAB_DY);
  C.stack.style.width = (MID_W + 8) + "px"; C.stack.style.display = "none";
  C.addRowBtn = Place(Button(L("+ Row"), 76, () => {
    if (C.addRowBtn.classList.contains("dis")) return;
    C.addMenu.style.left = C.addRowBtn.style.left; C.addMenu.style.top = (parseFloat(C.addRowBtn.style.top) + 22) + "px";
    C.addMenu.style.display = C.addMenu.style.display === "block" ? "none" : "block";
  }), GRID_X, 0);
  C.addRowBtn.classList.add("tiny"); C.addRowBtn.style.display = "none";
  withTip(C.addRowBtn, () => `<div class="w">${L("Add row (empty or template)")}</div><div class="d">${fmt(L("At most %d rows per group."), MAX_GROUP_ROWS)}</div>`);
  // = CreateSepMenu in OptionsRowStack.lua (2026-11-17, user): the looks of the separator, symbol in front of the name.
  // Since 2026-11-18 (user) the alignment of the row on top (ROW_ALIGNS), each part under a grey heading
  C.sepMenu = Place(mk("div", "menu sepmenu"), 0, 0);
  const item = (mini, label, onClick) => {
    const it = mk("div", "it"), sym = mk("span", "sym"); drawMini(sym, mini); it.append(sym, label);
    it.addEventListener("click", (e) => { e.stopPropagation(); if (it.classList.contains("dis")) return; C.sepMenu.style.display = "none"; if (C.sepMenu._row) onClick(C.sepMenu._row); });
    C.sepMenu.appendChild(it);
    return it;
  };
  C.sepMenu.appendChild(mk("div", "hd", L("Alignment")));
  C.alignMenuItems = ROW_ALIGNS.map((a) => item(a.mini, a.label(), (r) => setRowAlign(r, a.key)));
  C.sepMenu.appendChild(mk("div", "hd", L("Separator")));
  C.sepMenuItems = SEP_KINDS.map((k) => item(k.mini, k.label(), (r) => setRowSep(r, k.key)));
}
// = DrawSepMini in OptionsRowStack.lua: the small drawing of a look (SEP_KINDS mini) in the middle of el
function drawSepMini(el, key) { drawMini(el, sepKind(key).mini); }
// pieces [x, y, w, h] around the middle of el (keep = do not remove the pieces drawn before)
function drawMini(el, list, keep) {
  if (!keep) el.querySelectorAll(".mini").forEach((x) => x.remove());
  for (const [x, y, w, h] of list) {
    const d = mk("div", "mini");
    Object.assign(d.style, { left: `calc(50% + ${x}px)`, top: `calc(50% + ${y}px)`, width: w + "px", height: h + "px" });
    el.appendChild(d);
  }
}
// opens the separator menu of row r below its button (a second click on the same button closes it)
function openSepMenu(r, btn) {
  const m = C.sepMenu, open = m.style.display === "block" && m._row === r;
  content.querySelectorAll(".menu").forEach((x) => { x.style.display = "none"; });
  if (open) return;
  m._row = r;
  // coordinates of the button on the page the menu lives on; the window may be scaled (screen px / k)
  const pg = m.parentElement, b = btn.getBoundingClientRect(), c = pg.getBoundingClientRect(), k = c.width / pg.offsetWidth || 1;
  m.style.left = Math.round((b.left - c.left) / k - 4) + "px"; m.style.top = Math.round((b.bottom - c.top) / k + 2) + "px";
  const cur = rowSepStyle(r), al = rowAlign(r);
  C.sepMenuItems.forEach((it, i) => it.classList.toggle("sel", SEP_KINDS[i].key === cur));
  // "Both sides" only for a split row
  C.alignMenuItems.forEach((it, i) => { it.classList.toggle("sel", ROW_ALIGNS[i].key === al); it.classList.toggle("dis", ROW_ALIGNS[i].key === "both" && !isSplitRow(r)); });
  m.style.display = "block";
}
// = StackSlots in OptionsRowStack.lua (2026-11-18, user: "alignment and separator visible in the options at once"):
// the place of every icon of row r in a line of W places, like on the bar. A normal row from the left or the right; a
// split row "left"/"right": both halves together at that edge with g empty places between them (the separator: its
// places, else 1; none if the row is full); "both": the left half from the left, the right half from the right, the
// free places between them. Returns { slots (place of icon i, 0-based), gapFrom, gapTo (places of the gap, gapTo
// exclusive) }; gapFrom = gapTo = the place after the left half when there is no gap.
function stackSlots(r, W) {
  const n = r.items.length, al = rowAlign(r);
  if (!isSplitRow(r)) { const off = al === "right" ? W - n : 0; return { slots: r.items.map((_, i) => off + i) }; }
  const s = rowSplit(r), k = sepKind(rowSepStyle(r));
  let off = 0, g;
  if (al === "both") g = W - n;
  else { g = n < W ? Math.min(k.places || 1, W - n) : 0; if (al === "right") off = W - n - g; }
  return { slots: r.items.map((_, i) => off + (i < s ? i : i + g)), gapFrom: off + s, gapTo: off + s + g };
}
// rows of group g as [row, index in profile.rows]
const groupRows = (g) => activeRows().map((r, i) => [r, i]).filter(([r]) => (r.group || "main") === g.id);
// row of group g that holds id (the catalog marks and removes per group since 2026-11-16)
const groupRowOf = (g, id) => (g && !g.area ? groupRows(g).map(([r]) => r).find((r) => rowIndexOf(r, id) >= 0) : null);
// icon button of the stack for row object r, index i (the alternatives column opens below it)
function stackButton(r, i) { return C.stack.querySelector(`.sitm[data-r="${activeRows().indexOf(r)}"][data-i="${i}"]`); }

// draws the rows of the selected group and sets C.stackBottom (where "Options" starts), null = not shown
function layoutRowStack() {
  const grp = curGroup(), st = C.stack, styled = styleTab !== "layout";
  const show = !!grp && !grp.area && !styled;
  C.stackBottom = null;
  st.innerHTML = "";
  C.addRowBtn.style.display = show ? "" : "none";
  if (!show) { st.style.display = "none"; if (flyRow) flyRow = null, flyIndex = null; return; }
  const mine = groupRows(grp), W = groupWidth(grp), active = curRow(), top = GRID_Y + STAB_DY;
  const h = Math.max(mine.length, 1) * ITEM_STEP - ITEM_GAP + 8;
  st.style.display = ""; st.style.top = top + "px"; st.style.height = h + "px";
  if (!mine.length) st.appendChild(mk("div", "grid-empty", L("No rows yet - add one with \"+ Row\"")));
  mine.forEach(([r, ri], k) => {
    const line = mk("div", "sline" + (r === active ? " sel" : "") + (r.hidden ? " off" : "")); line.dataset.r = ri;
    line.style.top = (3 + k * ITEM_STEP) + "px"; line.style.height = (ITEM_SIZE + 2) + "px";
    const pl = stkPL(W), sx = (slot) => pl + slot * ITEM_STEP;
    const grip = mk("div", "sgrip", "≡"); grip.style.left = "2px"; // = Lua (was 3)
    grip.addEventListener("mousedown", (e) => { startPending(e, r.items.length ? entMain(r.items[0]) : undefined, "srow", ri); });
    tipOn(grip, () => `<div class="w">${L("Drag: move the row")}</div><div class="d">${L("Onto another row = there; onto a group in the list = into that group.")}</div>`);
    line.appendChild(grip);
    const split = isSplitRow(r), lay = stackSlots(r, W);
    // = LayoutRowStack in OptionsRowStack.lua: a split row keeps all W places (session 20, user; before one was the
    // separator X). Since 2026-11-18 (user) the icons stand like on the bar (stackSlots: alignment, the gap of the
    // separator); from session 20 to then always in their order from the left with the yellow line after the left half.
    // While the line is dragged the icons stay where they are (third in-game test of session 20).
    for (let slot = 0; slot < W; slot++) { const c = mk("div", "scell"); c.style.left = sx(slot) + "px"; c.style.top = "1px"; line.appendChild(c); }
    if (split) {
      // no gap: the yellow line (3 px) in the middle of SEP_HIT px to grab it, between the halves. A gap of empty
      // places: a yellow frame around them with the look of the separator in grey in its middle (2026-11-18)
      const sep = mk("div", "ssep"), gw = (lay.gapTo - lay.gapFrom) * ITEM_STEP - ITEM_GAP;
      if (gw > 0) {
        sep.classList.add("box"); sep.style.left = sx(lay.gapFrom) + "px"; sep.style.width = gw + "px";
        drawMini(sep, sepKind(rowSepStyle(r)).mini);
      } else sep.style.left = (sx(lay.gapFrom) - ITEM_GAP / 2 - SEP_HIT / 2) + "px";
      sep.style.top = "0px";
      sep.addEventListener("mousedown", (e) => { if (e.button !== 0) return; e.stopPropagation(); e.preventDefault(); hideTip(); startSepDrag(r, ri, e); });
      sep.addEventListener("click", (e) => e.stopPropagation());
      tipOn(sep, () => `<div class="w">${L("Separator")}</div><div class="d">${L("Drag left or right: icons change between the halves.")}</div>`);
      line.appendChild(sep);
    }
    r.items.forEach((en, i) => line.appendChild(stackIcon(r, ri, en, i, sx(lay.slots[i]))));
    // right of the places: separator, eye, "-" (2026-11-16, user). Since 2026-11-17 (user) the separator is a choice
    // instead of the checkbox "Split row": the button shows the look as a small drawing (empty = not split; text
    // symbols until the second in-game test), a click opens C.sepMenu
    const style = rowSepStyle(r);
    // since 2026-11-18 (user) the box also shows the alignment of the row: marks along its bottom (ROW_ALIGNS bar)
    const cb = mk("div", "scb ssepbtn" + (split ? " on" : "")); drawSepMini(cb, style); cb.style.left = (STK_CB - 14) + "px";
    drawMini(cb, rowAlignKind(rowAlign(r)).bar, true);
    cb.addEventListener("click", (e) => { e.stopPropagation(); hideTip(); openSepMenu(r, cb); });
    tipOn(cb, () => `<div class="w">${L("Alignment")}: ${rowAlignKind(rowAlign(r)).label()}</div><div class="w">${L("Separator")}: ${sepKind(rowSepStyle(r)).label()}</div><div class="d">${L("Click: choose alignment and separator. Left / Right: the whole row sits at that edge, a separator is only its gap. Both sides (split rows only): the left half fills from the left, the right half from the right. The yellow line shows where the separator is; drag it or drop icons left or right of it.")}</div>`);
    const eye = mk("div", "seye" + (r.hidden ? " off" : ""), "\u{1F441}"); eye.style.left = (STK_EYE - 8) + "px";
    eye.addEventListener("click", (e) => { e.stopPropagation(); hideTip(); if (r.hidden) delete r.hidden; else r.hidden = true; changed(); });
    tipOn(eye, () => `<div class="w">${r.hidden ? L("Hidden - click shows the row in the bar") : L("Visible - click hides the row in the bar")}</div>`);
    const del = mk("div", "sdel", "-"); del.style.left = (STK_DEL - 7) + "px";
    del.addEventListener("click", (e) => { e.stopPropagation(); hideTip(); askDeleteRow(r); });
    tipOn(del, () => `<div class="w">${L("Delete row")}</div>`);
    line.append(cb, eye, del);
    line.addEventListener("click", (e) => {
      if (justDragged || e.target.closest(".sitm")) return;
      selectedRow = ri; refreshOptions();
    });
    st.appendChild(line);
  });
  // "+ Row" below the lines, "Options" below it
  C.addRowBtn.style.top = (top + h + 4) + "px";
  C.addRowBtn.classList.toggle("dis", mine.length >= MAX_GROUP_ROWS);
  C.stackBottom = top + h + 4 + 22 + 6;
}
// = StartSepDrag in OptionsRowStack.lua: while held, only the separator of split row r follows the mouse as the yellow
// line (over all places of the row; the icons stay where they are). Letting go snaps it into the nearest gap: the left
// half = every icon whose centre lies left of it (third in-game test of session 20, user); since 2026-11-18 the icons
// stand where stackSlots puts them, then the row is laid out again.
function startSepDrag(r, ri, e0) {
  const line = C.stack.querySelector(`.sline[data-r="${ri}"]`), sep = line && line.querySelector(".ssep");
  if (!sep) return;
  const n = r.items.length, W = groupWidth(rowGroupOf(r)), slots = stackSlots(r, W).slots;
  const o = line.getBoundingClientRect(), pl = stkPL(W), lo = pl - ITEM_GAP / 2, hi = pl + W * ITEM_STEP - ITEM_GAP / 2;
  let x = lo;
  sep.classList.remove("box"); sep.style.width = ""; sep.querySelectorAll(".mini").forEach((m) => m.remove());
  const move = (ev) => {
    x = Math.max(lo, Math.min(hi, ev.clientX - o.left));
    sep.style.left = x - SEP_HIT / 2 + "px"; sep.classList.add("drag");
  };
  const up = () => {
    document.removeEventListener("mousemove", move); document.removeEventListener("mouseup", up); document.body.style.cursor = "";
    let s = 0;
    for (let i = 0; i < n; i++) if (pl + slots[i] * ITEM_STEP + ITEM_SIZE / 2 < x) s = i + 1;
    r.split = s; changed();
  };
  document.addEventListener("mousemove", move); document.addEventListener("mouseup", up);
  document.body.style.cursor = "ew-resize";
  move(e0);
}
function tipOn(el, html) {
  el.addEventListener("mousemove", (e) => { if (drag) return; e.stopPropagation(); tip.innerHTML = html(); placeTip(e); });
  el.addEventListener("mouseleave", hideTip);
}
function stackIcon(r, ri, en, i, x) {
  const id = entMain(en), b = mk("div", "itm ic sitm");
  b.dataset.r = ri; b.dataset.i = i; b.dataset.id = id;
  setIcon(b, id); b.style.left = x + "px"; b.style.top = "1px";
  b.classList.toggle("hasalt", isSlot(en) && en.v.length > 1);
  b.classList.toggle("pick", isSlot(en) && en.pick === id);
  if (isWeaponEntry(en)) {
    // weapon entries: hand mark, click switches the hand (2026-11-09)
    const hm = mk("div", "handmark", HAND_LETTER[en.hand]);
    hm.addEventListener("mousedown", (ev) => ev.stopPropagation());
    hm.addEventListener("click", (ev) => { ev.stopPropagation(); en.hand = en.hand === "main" ? "off" : "main"; hideTip(); changed(); });
    b.appendChild(hm);
  }
  b.addEventListener("mousedown", (e) => { startPending(e, id, "stack", i); if (pending) pending.r = ri; });
  b.addEventListener("click", () => { if (justDragged) return; if (isSlot(en) && en.pick !== id) { en.pick = id; changed(); } });
  b.addEventListener("contextmenu", (e) => { e.preventDefault(); hideTip(); spliceItem(r, i); changed(); });
  b.addEventListener("mousemove", (e) => {
    if (drag) return;
    tip.innerHTML = `<div class="n">${itemInfo(id).name}</div><div class="d">(Item-Tooltip)</div>` +
      `<br><div class="d">${L("Drag: change order, also into another row of the group")}</div><div class="d">${L("Drag out or right-click: remove")}</div>` +
      (isFlaskEntry(en) || isBuffId(id) ? "" : `<div class="d">${L("Below: alternatives (drag an item into the empty field)")}</div>`);
    placeTipBeside(b);
  });
  b.addEventListener("mouseleave", hideTip);
  return b;
}
const overStack = (el) => !!(el && el.closest && el.closest(".sstack"));
// = FinishDrag for the stack: d.from "catalog", "alt" (d.row = row of the column) or "stack" (d.r, d.index)
function stackDrop(d, el, clientX) {
  const rows = activeRows(), line = el && el.closest(".sline");
  if (!line) { // dragged out of the stack: removed
    if (d.from === "stack" && !overStack(el)) { const src = rows[d.r]; if (src && src.items[d.index] !== undefined) { spliceItem(src, d.index); changed(); } }
    return;
  }
  const dst = rows[Number(line.dataset.r)]; if (!dst) return;
  const b = el.closest(".sitm"), target = b ? Number(b.dataset.i) : undefined;
  // a split row: the half comes from the icon dropped on or the side of the X
  const s = rowSplit(dst), sep = line.querySelector(".ssep");
  const side = !isSplitRow(dst) ? null : target !== undefined ? (target < s ? "L" : "R")
    : (clientX < sep.getBoundingClientRect().left + sep.offsetWidth / 2 ? "L" : "R");
  const run = (id, fn) => (side ? splitDo(dst, side, id, fn) : (fn(), changed()));
  const at = target ?? (side === "L" ? s : dst.items.length);
  if (d.from === "catalog") return run(d.itemID, () => insertItem(d.itemID, at, dst));
  if (d.from === "alt") {
    const src = d.row || curRow();
    return run(d.itemID, () => { if (src !== dst) takeFromRow(src, d.itemID); insertItem(d.itemID, at, dst); });
  }
  if (d.from !== "stack") return;
  const src = rows[d.r], i = d.index; if (!src || src.items[i] === undefined) return;
  const en = src.items[i], id = entMain(en);
  if (src === dst) {
    if (target === i) return;
    const to = target !== undefined ? target : side === "L" ? s - 1 : side === "R" ? s : dst.items.length - 1;
    return run(id, () => { const [v] = dst.items.splice(i, 1); dst.items.splice(Math.max(0, Math.min(to, dst.items.length)), 0, v); });
  }
  // into another row of the group: the whole icon with its alternatives, only while that row has room
  if (dst.items.length >= rowCap(dst)) return print(rowFullText(dst));
  run(id, () => {
    spliceItem(src, i);
    for (const x of entIds(en)) takeFromRow(dst, x);
    dst.items.splice(Math.min(at, dst.items.length), 0, en);
  });
}
// = RowDropIndex in OptionsRowStack.lua (2026-11-16, user): where the dragged row (index from) ends up when it is
// dropped above (before) or below line i; the green line shows that gap
function rowDropIndex(from, i, before) {
  if (from === i) return from; // its own line: stays
  if (before) return from < i ? i - 1 : i;
  return from < i ? i : i + 1;
}
// a row dragged by its grip: onto a line of the stack = above it (upper half) or below it (lower half), onto a group in
// the list = into that group. y = mouse y; before 2026-11-16 the line was always below, the row went to the line's place
function rowDragTarget(el, from, y) {
  const line = el && el.closest && el.closest(".sstack .sline");
  if (line) {
    const i = Number(line.dataset.r), b = line.getBoundingClientRect(), before = y < b.top + b.height / 2;
    return { line, i, before, to: rowDropIndex(from, i, before) };
  }
  const t = listTarget(el);
  return t && t.m && t.m.g ? { k: t.k, g: t.m.g } : null;
}
function rowDragDrop(d, el, y) {
  const t = rowDragTarget(el, d.index, y), rows = activeRows(), r = rows[d.index];
  if (!t || !r) return;
  if (t.g) return moveRowToGroup(r, t.g);
  if (t.to === d.index) return;
  selectedRow = moveRowTo(d.index, t.to);
  changed();
}

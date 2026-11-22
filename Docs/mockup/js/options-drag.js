"use strict";
/* RaidKit Buffs mockup: drag & drop, fold-out column with alternatives (= OptionsDrag.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ----- Drag & drop (like Options.lua: StartDrag / FinishDrag) ----- */
const dragIcon = document.getElementById("dragicon");
let drag = null, pending = null, justDragged = false;
function startPending(e, itemID, from, index) {
  if (e.button !== 0) return;
  e.preventDefault();
  pending = { x: e.clientX, y: e.clientY, itemID, from, index };
}
// list line under the cursor: { k = line, m = model entry { g } or { i } } (2026-11-11: lines with group headers)
function listTarget(el) { const l = el && el.closest(".rowline"); if (!l || l.style.display === "none") return undefined; const k = Number(l.dataset.k); return { k, m: C.listModel[k] }; }
function gridTargetIndex(el) { const b = el && el.closest(".itm"); return b && b.dataset.id ? Number(b.dataset.index) : undefined; }
function overGrid(el) { return !!(el && (el.closest(".grid-area") || el.closest(".itm"))); }
// Shift+right-click anywhere on a group (icons, frame, gaps; outline takes the mouse with Shift) = options
// (2026-11-14, = ShiftOptions in Bar.lua; before only the row icons did, a visible frame invited misses)
window.addEventListener("contextmenu", (e) => {
  if (!e.shiftKey || !e.target.closest || !e.target.closest(".cb-container")) return;
  e.preventDefault(); e.stopPropagation(); hideTip();
  document.getElementById("viewWindow").scrollIntoView({ behavior: "smooth" });
}, true);
window.addEventListener("mousemove", (e) => {
  cursorX = e.clientX; cursorY = e.clientY; shiftDown = e.shiftKey;
  updateMover();
  if (moverDrag) { dragGroup(e); return; }
  if (pending && !drag && Math.hypot(e.clientX - pending.x, e.clientY - pending.y) > 4) {
    drag = pending; pending = null;
    if (drag.itemID) setIcon(dragIcon, drag.itemID); else dragIcon.style.backgroundImage = `url(${ICON_URL("inv_misc_questionmark")})`;
    dragIcon.style.display = "block"; hideTip();
  }
  if (drag) { dragIcon.style.left = e.clientX + "px"; dragIcon.style.top = e.clientY + "px"; }
  const el = document.elementFromPoint(e.clientX, e.clientY);
  if (!drag || drag.from !== "srow") flyHover(el);
  if (!drag) return;
  const og = overGrid(el);
  if (drag.from !== "srow") {
    const ft = flyTarget(el);
    C.flyout.querySelectorAll(".fcell").forEach((c) => c.classList.remove("drop", "hot"));
    if (ft && !ft.self) {
      ft.cell.classList.add(ft.k === undefined ? "hot" : "drop");
      C.gridArea.classList.remove("glow");
      const hint = dragIcon.querySelector(".hint"); hint.textContent = drag.from === "alt" && drag.index === flyIndex ? L("Move") : L("As alternative"); hint.style.color = "#40ff40";
      return;
    }
  }
  if (drag.from === "srow") { // a row by its grip (2026-11-16): onto another line or onto a group in the list
    const t = rowDragTarget(el, drag.index, e.clientY), moves = !!t && t.line && t.to !== drag.index;
    C.rowLines.forEach((l, k) => l.classList.toggle("drop", !!t && t.g && k === t.k));
    // green line above (upper half) or below (lower half) the line under the mouse = where the row will go; shown from
    // the start of the drag, also at the row's own place (2026-11-16, user: no waiting for the first move)
    C.stack.querySelectorAll(".sline").forEach((l) => {
      const on = !!t && t.line === l; l.classList.toggle("drop", on && !t.before); l.classList.toggle("dropup", on && t.before);
    });
    const hint = dragIcon.querySelector(".hint");
    hint.textContent = t && t.g ? fmt(L("Into \"%s\""), groupName(t.g)) : moves ? L("Move") : ""; hint.style.color = "#ffd100";
    return;
  }
  const hint = dragIcon.querySelector(".hint");
  C.gridArea.classList.toggle("glow", og);
  if ((drag.from === "grid" || drag.from === "alt" || drag.from === "stack") && !og) { hint.textContent = L("Remove"); hint.style.color = "#ff4040"; }
  else if (drag.from === "catalog" && og && curRow() && curRow().unwanted && !isBuffId(drag.itemID)) { hint.textContent = L("Buffs only"); hint.style.color = "#ff4040"; }
  else if (drag.from === "catalog" && og) { const inRow = rowIndexOf(curRow(), drag.itemID) >= 0; hint.textContent = inRow ? L("Move") : L("Add"); hint.style.color = inRow ? "#ffd100" : "#40ff40"; }
  else hint.textContent = "";
});
window.addEventListener("mouseup", (e) => {
  if (moverDrag) {
    // the member that snapped becomes the root of the cluster, then hangs on the target (= StopMove, session 4b)
    const s = moverDrag.snap;
    if (s) {
      if (s.member !== moverDrag.el._g.id) reroot(s.member);
      profile.groupPos[s.member] = { snap: s.id, side: s.side, align: s.align }; // + the end of the side (2026-11-18)
      flash(fmt(L("%s snapped %s %s."), groupName(groupById(s.member) || { name: "?" }), slotName(s.side, s.align), groupName(groupById(s.id) || { name: "?" })));
    }
    // a drag that moved must not also click (the X of "Unerwünscht" would remove every unwanted buff)
    if (moverDrag.moved) { justMoved = true; setTimeout(() => { justMoved = false; }, 0); }
    moverDrag = null; barLayout.point = clone(profile.point);
    // rebuild: a buff area's line width depends on the group it hangs on (free: just "Pro Zeile")
    refreshOptions(); requestRebuild();
  }
  pending = null;
  if (!drag) return;
  const d = drag; drag = null; justDragged = true; setTimeout(() => { justDragged = false; }, 0);
  dragIcon.style.display = "none"; C.gridArea.classList.remove("glow");
  C.rowLines.forEach((l) => l.classList.remove("drop"));
  const el = document.elementFromPoint(e.clientX, e.clientY);
  if (d.from === "srow") return rowDragDrop(d, el, e.clientY); // a row by its grip (2026-11-16, options-row-stack.js)
  C.flyout.querySelectorAll(".fcell").forEach((c) => c.classList.remove("drop", "hot"));
  const ft = flyTarget(el, d);
  if (ft) { if (!ft.self) dropOnFlyout(d, ft); return; }
  const target = gridTargetIndex(el), og = overGrid(el);
  if (d.from === "stack" || overStack(el)) return stackDrop(d, el, e.clientX); // rows of the group (2026-11-16, options-row-stack.js)
  if (d.from === "alt") {
    const row = d.row || curRow(), id = d.itemID;
    if (og) insertItem(id, target); // alternative becomes its own icon
    else { takeFromRow(row, id); changed(); } // dragged out = removed
    return;
  }
  if (d.from === "grid") {
    if (target !== undefined) { if (target !== d.index) moveTo(d.index, target); }
    else if (og) moveTo(d.index, curRow().items.length);
    else removeAt(d.index);
  } else if (og) insertItem(d.itemID, target);
});
/* ----- Fold-out column with alternatives (proposal, like ItemRack) -----
   Hovering an icon of the grid (also while dragging) opens a column below it: the alternatives of that
   icon and an empty field. Dropping on the empty field adds an alternative; then a new empty field appears. */
let flyIndex = null; // grid index whose column is open
let flyRow = null; // row of the open column when it belongs to the row stack of a split group (2026-11-15), else the selected row
function flyHover(el) {
  const sb = el && el.closest(".sitm");
  if (sb) { const r = activeRows()[Number(sb.dataset.r)], i = Number(sb.dataset.i); if (r !== flyRow || i !== flyIndex) { flyRow = r; flyIndex = i; renderFlyout(); } return; }
  const b = el && el.closest(".itm");
  if (b && b.dataset.id) { const i = Number(b.dataset.index); if (i !== flyIndex || flyRow) { flyRow = null; flyIndex = i; renderFlyout(); } return; }
  if (el && el.closest(".flyout")) return;
  if (drag) return; // while dragging the column stays open until another icon is hovered
  if (flyIndex !== null) { flyIndex = null; flyRow = null; renderFlyout(); }
}
function renderFlyout() {
  const f = C.flyout, row = flyRow || curRow(), en = row && flyIndex !== null ? row.items[flyIndex] : undefined;
  f.classList.toggle("stackfly", !!flyRow); // column of the split stack: shown on the group page too (2026-11-15)
  f.innerHTML = "";
  if (en === undefined || row.unwanted) { f.style.display = "none"; return; } // unwanted list: no alternatives
  const ids = entIds(en);
  // = RenderFlyout: Flasks and Zanza get no alternatives (no empty field, no column if nothing is in it)
  // buffs: only the fixed pairs of DEFAULT_ALTS (mage armors, 2026-11-15, user), no empty field, no warning
  const allowAdd = !isFlaskEntry(en) && !isBuffId(ids[0]) && ids.length < maxVariants(ids[0]);
  const fields = ids.length - 1 + (allowAdd ? 1 : 0);
  f.style.gridTemplateRows = `repeat(${Math.max(1, Math.min(fields, FLY_PER_COL))}, ${ITEM_SIZE}px)`;
  if (ids.length === 1 && !allowAdd) { f.style.display = "none"; return; }
  // below its icon, in page coordinates (the row stack of a split group has its own icons, 2026-11-15)
  const fb = flyRow ? stackButton(flyRow, flyIndex) : C.itemButtons[flyIndex];
  if (!fb) { f.style.display = "none"; return; }
  const pr = pages.rows.getBoundingClientRect(), br = fb.getBoundingClientRect();
  f.style.left = (br.left - pr.left - 3) + "px";
  f.style.top = (br.bottom - pr.top) + "px";
  ids.slice(1).forEach((id, n) => {
    const k = n + 1, c = mk("div", "fcell ic" + (isSlot(en) && id === en.pick ? " pick" : ""));
    setIcon(c, id); c.dataset.k = k;
    c.addEventListener("mousedown", (e) => { startPending(e, id, "alt", flyIndex, k); if (pending) pending.row = row; });
    c.addEventListener("click", () => { if (justDragged) return; const r = row.items[flyIndex]; r.pick = id; changed(); });
    c.addEventListener("contextmenu", (e) => { e.preventDefault(); takeFromRow(row, id); changed(); });
    c.addEventListener("mousemove", (e) => {
      if (drag) return;
      tip.innerHTML = `<div class="n">${itemInfo(id).name}</div><div class="d">(Item-Tooltip)</div><br>` +
        `<div class="${id === en.pick ? "y" : "d"}">${id === en.pick ? L("Picked (Ctrl+click uses this one first)") : L("Click: mark as picked")}</div>` +
        `<div class="d">${L("Drag: order (= replacement order)")}</div><div class="d">${L("Drag out or right-click: remove")}</div>`;
      placeTipBeside(c);
    });
    c.addEventListener("mouseleave", hideTip);
    f.appendChild(c);
  });
  if (allowAdd) {
    const empty = mk("div", "fcell empty"); empty.dataset.empty = "1";
    empty.addEventListener("mousemove", (e) => { if (drag) return; tip.innerHTML = `<div class="w">${L("Drag an alternative here")}</div><div class="d">${L("Catalog item or icon from the row")}</div>`; placeTip(e); });
    empty.addEventListener("mouseleave", hideTip);
    f.appendChild(empty);
  }
  // no yellow "!" below the cells any more (2026-11-18, user: = RenderFlyout in OptionsDrag.lua)
  f.style.display = "";
}
// drop target in the open column: { cell, k } (k undefined = empty field), self = no-op
function flyTarget(el, d) {
  d = d || drag;
  const cell = el && el.closest(".flyout .fcell");
  if (!cell || flyIndex === null) return null;
  if ((d.from === "grid" && !flyRow && d.index === flyIndex) || (d.from === "stack" && flyRow === activeRows()[d.r] && d.index === flyIndex)) return { cell, self: true };
  return { cell, k: cell.dataset.empty ? undefined : Number(cell.dataset.k) };
}
function dropOnFlyout(d, ft) {
  const row = flyRow || curRow(), gi0 = flyIndex;
  // source of a whole icon: the grid (selected row) or the row stack of a split group (any row of it, 2026-11-15)
  const srcRow = d.from === "stack" ? activeRows()[d.r] : row, whole = d.from === "grid" || d.from === "stack";
  // buffs get no alternatives by hand, only the fixed pairs of DEFAULT_ALTS (mage armors, 2026-11-15, user)
  const srcMain = whole ? entMain(srcRow.items[d.index]) : d.itemID;
  if (srcMain && (isBuffId(srcMain) || isBuffId(entMain(row.items[gi0])))) return print(L("Buffs have no alternatives."));
  let gi = gi0, ids;
  if (whole) {
    ids = entIds(srcRow.items[d.index]).slice();
    spliceItem(srcRow, d.index); if (srcRow === row && d.index < gi) gi--; // the whole icon (with its alternatives) moves in
  } else ids = [d.itemID];
  let en = row.items[gi];
  for (const id of ids) {
    if (entIds(en).includes(id) && !(d.from === "alt" && d.index === gi0)) continue;
    const j = rowIndexOf(row, id);
    if (j >= 0 && j !== gi) { if (takeFromRow(row, id) >= 0 && j < gi) gi--; en = row.items[gi]; }
  }
  const slot = isSlot(en) ? en : { v: [en], pick: en };
  let k = ft.k === undefined ? slot.v.length : ft.k;
  for (const id of ids) {
    const old = slot.v.indexOf(id);
    if (old >= 0) { if (old === 0) continue; slot.v.splice(old, 1); if (old < k) k--; }
    if (slot.v.length >= maxVariants(slot.v[0])) { print(fmt(L("At most %d variants per icon."), maxVariants(slot.v[0]))); break; }
    slot.v.splice(k++, 0, id);
    if (sim.counts[id] === undefined) sim.counts[id] = 0;
  }
  row.items[gi] = normEntry(slot);
  flyIndex = gi;
  changed();
}

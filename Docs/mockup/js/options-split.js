"use strict";
/* RaidKit Buffs mockup: split rows in the options: option "Split row", width rules for the rows of a group
   (= OptionsSplit.lua). The rows of a group with the split line: options-row-stack.js.
   Part of raidkit_buffs.html, loaded in order by js/boot.js. */

// Since 2026-11-16 (user; replaces the split groups of 2026-11-15; data and bar: bar-split.js):
// - Every row line of a group has the choice of the separator (options-row-stack.js; 2026-11-16 to 2026-11-17 the
//   checkbox "Split row"): "None" = a normal row, any look = split (setRowSep). Splitting: the separator starts in the
//   middle of the icons (odd number: the left half gets one more), session 20, user; before every icon started left.
//   It is a yellow line between the icons, so the row keeps all its places (before one place was the separator X), and
//   it can be dragged with the mouse. Off: both halves become one row again (left, then right).
// - "Per line" of a group (and of "All Groups") is the most icons a row of the group holds. It cannot go below what a
//   row of the group needs (message, the change is refused).
// - A row that does not fit cannot be dragged into a group; a template longer than the group's rows is cut.
// = SetRowSplit in OptionsSplit.lua
function setRowSplit(row, on) {
  if (!row || row.unwanted || on === isSplitRow(row)) return;
  // off keeps the place of the separator in row.splitOff, on brings it back (2026-11-16, user); first time: middle
  if (on) {
    // the row keeps its alignment (2026-11-18, user): without an own choice a split row would become "both"
    if (row.align == null) row.align = rowAlign(row);
    const s = typeof row.splitOff === "number" ? row.splitOff : Math.ceil(row.items.length / 2); // middle (session 20)
    row.split = Math.max(0, Math.min(row.items.length, Math.floor(s))); delete row.splitOff;
  } else { row.splitOff = row.split; delete row.split; }
  changed();
}
// = SetRowSep in OptionsSplit.lua (2026-11-17, user; replaces the checkbox "Split row"): the choice of a row line.
// "none" = a normal row (like the checkbox off), any other look splits the row (like on) and keeps the look in
// row.sepStyle ("gap", the look of session 20, is not stored)
function setRowSep(row, key) {
  if (!row || row.unwanted) return;
  if (key === "none") return setRowSplit(row, false);
  if (key === "gap") delete row.sepStyle; else row.sepStyle = key;
  if (!isSplitRow(row)) setRowSplit(row, true); else changed();
}
// = SetRowAlign in OptionsSplit.lua (2026-11-18, user): alignment of a row (bar-split.js ROW_ALIGNS), always stored
// once chosen; "both" only for a split row
function setRowAlign(row, key) {
  if (!row || row.unwanted || !rowAlignKind(key) || (key === "both" && !isSplitRow(row))) return;
  row.align = key;
  changed();
}
// = WidthOK in OptionsSplit.lua: may "Per line" of group g (nil = "All Groups") become v? Refuses with a message when a
// row would not fit any more (user 2026-11-16)
function widthOk(g, v) {
  const W = v > 0 && v < ROW_MAX ? v : ROW_MAX;
  for (const x of g ? [g] : rowGroups().filter((y) => y.perLine == null)) {
    const n = groupNeed(x);
    if (n > W) { flash(fmt(L("Too narrow: a row of group \"%s\" needs %d places."), groupName(x), n)); refreshOptions(); return false; }
  }
  return true;
}
const rowFullText = (row) => fmt(L("The row is full: group \"%s\" has %d places per row."), groupName(rowGroupOf(row)), groupWidth(rowGroupOf(row)));
// a row added to group g (template, copy): cut to its places with a message
function fitRow(row, g) {
  const cap = groupWidth(g);
  if (row.items.length <= cap) return;
  const cut = row.items.splice(cap);
  if (row.split != null) row.split = Math.min(row.split, cap);
  print(fmt(L("Only %d icons fit in a row of group \"%s\", left out: %s"), cap, groupName(g), cut.map((en) => itemInfo(entMain(en)).name).join(", ")));
}
// group g takes rows from elsewhere (a deleted group): it gets wider if one of them needs more places
function widenFor(g) {
  const n = groupNeed(g);
  if (n <= groupWidth(g)) return;
  g.perLine = n >= ROW_MAX ? 0 : n;
  flash(fmt(L("Group \"%s\" now has %d places per row."), groupName(g), n));
}

// runs a change of a split row and puts the icon id into the given half; the order inside each half is kept
function splitDo(row, side, id, fn) {
  const left = new Set(row.items.slice(0, rowSplit(row)).map(entMain));
  fn();
  if (id != null) { if (side === "L") left.add(id); else left.delete(id); }
  const L_ = row.items.filter((en) => left.has(entMain(en))), R_ = row.items.filter((en) => !left.has(entMain(en)));
  row.items.splice(0, row.items.length, ...L_, ...R_);
  row.split = L_.length;
  changed();
}
// removes icon i of a row; a removed left icon makes the left half one shorter
function spliceItem(row, i) {
  const [en] = row.items.splice(i, 1);
  if (row.split != null && i < row.split) row.split--;
  return en;
}

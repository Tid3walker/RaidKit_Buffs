"use strict";
/* RaidKit Buffs mockup: split rows and the width of a group's rows (= BarSplit.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// Split rows (2026-11-16, user; replaces the split groups of 2026-11-15): every row of a group can be "split".
// "Per line" of the group (or "All Groups") is the most icons a row of the group holds, 20 = the maximum; a split row
// holds as many as a normal one (since session 20; before one place was the separator). Rows never wrap (only Other
// and Debuffs do; Unwanted grows sideways as before), and a row has no own size.
// Width on the bar (session 20, user): a normal row is as long as its icons; a split row spans the widest row of the
// group (left half from the left edge, right half from the right edge, the rest stays free in the middle). Its own
// length is its icons plus SPLIT_GAP between the halves, so a full split row makes the group that much wider.
// In the options the separator is a yellow line (it can be dragged). On the bar it is the gap, since 2026-11-17 (user)
// with a look of its own per row (SEP_KINDS: a dash, a line, a dot, an icon-wide gap ...), drawn in the middle of the
// free space between the halves.
// Data: row.split = number of icons in the left half (nil = normal row); row.sepStyle = look of the separator on the bar
// (nil = "gap", the plain gap of session 20, so older split rows look the same). Row names are not shown since 2026-11-16.
const ROW_MAX = 20, SPLIT_GAP = 10; // = BarSplit.lua: smallest extra gap between the halves of a split row on the bar
const rowGroupOf = (row) => groupById((row && row.group) || "main");
const isSplitRow = (row) => !!row && !row.unwanted && row.split != null;
// = SEP_KINDS in BarSplit.lua (2026-11-17, user): the choice per row. "none" = not split. mini = small drawing in the
// box of a row line and in the menu, [x, y, w, h] around its centre, at most 24 px wide (gold; second in-game test, user:
// instead of the text symbols "< >", "[ ]", "|" ...). marks(size) = the pieces drawn on the bar as [x, y, w, h] around
// the centre of the gap; pad = free px left and right of the marks (default 4; the dot 10 since the first in-game test,
// user: "more room left and right"); places = the gap is that many empty icon places (+ mid px), no pad then.
// Line and double line were removed in the fourth in-game test (user) for the dot variants dotIcon "[.]" (dot in one
// icon place), dotPair "[].[]" (dot between two empty places) and dotWide "[ ] . [ ]" (dot in the middle of three
// places); a stored "line" / "line2" is unknown now and shows as "gap".
// Lines (fifth in-game test, user; instead of "Dash" and "Two dashes"): gapOf = the gap is the one of that look (each
// line as wide as the matching dot, the user: line plus room left and right = the dot), marks(size, sp) = a 2 px line
// across that gap with 8 px to the icons (4 until the sixth in-game test, user: "a little more room"). The key "dash" stays for the short "Line", so a stored dash becomes it;
// "dash2" is unknown now and shows as "gap".
// = LineMarks in BarSplit.lua: a horizontal line across the smallest gap of look key (free room = spacing + gap)
const lineMarks = (key) => (s, sp) => { const w = sp + sepGap(key, s, sp) - 16; return [[-w / 2, -1, w, 2]]; };
const SEP_KINDS = [
  { key: "none", mini: [], label: () => L("None") },
  { key: "gap", mini: [[-4, -4, 1, 8], [-6, -4, 2, 1], [-6, 3, 2, 1], [3, -4, 1, 8], [4, -4, 2, 1], [4, 3, 2, 1]], label: () => L("Gap") },
  { key: "icon", mini: [[-5, -5, 10, 1], [-5, 4, 10, 1], [-5, -4, 1, 8], [4, -4, 1, 8]], label: () => L("Gap (1 place)"), places: 1 },
  { key: "dot", mini: [[-2, -2, 4, 4]], label: () => L("Dot"), pad: 10, marks: () => [[-2, -2, 4, 4]] },
  { key: "dotIcon", mini: [[-5, -5, 10, 1], [-5, 4, 10, 1], [-5, -4, 1, 8], [4, -4, 1, 8], [-1, -1, 2, 2]], label: () => L("Dot (1 place)"), places: 1, marks: () => [[-2, -2, 4, 4]] },
  { key: "dotPair", mini: [[-9, -3, 6, 1], [-9, 2, 6, 1], [-9, -2, 1, 4], [-4, -2, 1, 4], [-1, -1, 2, 2], [3, -3, 6, 1], [3, 2, 6, 1], [3, -2, 1, 4], [8, -2, 1, 4]], label: () => L("Dot (2 places)"), places: 2, mid: 12, marks: () => [[-2, -2, 4, 4]] },
  { key: "dotWide", mini: [[-12, -3, 6, 1], [-12, 2, 6, 1], [-12, -2, 1, 4], [-7, -2, 1, 4], [-1, -1, 2, 2], [6, -3, 6, 1], [6, 2, 6, 1], [6, -2, 1, 4], [11, -2, 1, 4]], label: () => L("Dot (3 places)"), places: 3, marks: () => [[-2, -2, 4, 4]] },
  { key: "dash", mini: [[-4, -1, 8, 2]], label: () => L("Line"), gapOf: "dot", marks: lineMarks("dash") },
  { key: "hline1", mini: [[-6, -1, 12, 2]], label: () => L("Line (1 place)"), gapOf: "dotIcon", marks: lineMarks("hline1") },
  { key: "hline2", mini: [[-9, -1, 18, 2]], label: () => L("Line (2 places)"), gapOf: "dotPair", marks: lineMarks("hline2") },
  { key: "hline3", mini: [[-12, -1, 24, 2]], label: () => L("Line (3 places)"), gapOf: "dotWide", marks: lineMarks("hline3") },
];
const SEP_COLOR = "rgba(200, 200, 210, .85)"; // = SEP_R, SEP_G, SEP_B, SEP_A in BarSplit.lua
const sepKind = (key) => SEP_KINDS.find((k) => k.key === key);
// look of the separator of a row: "none" for a normal row, else its sepStyle (unknown or nil = "gap")
const rowSepStyle = (row) => (!isSplitRow(row) ? "none" : sepKind(row.sepStyle) && row.sepStyle !== "none" ? row.sepStyle : "gap");
// = SepGap in BarSplit.lua: extra room between the halves for a look (on top of the normal spacing): k.places empty icon
// places (+ k.mid), else the marks plus its pad on each side, at least SPLIT_GAP
function sepGap(style, size, sp) {
  const k = sepKind(style);
  if (k && k.gapOf) return sepGap(k.gapOf, size, sp);
  if (k && k.places) return k.places * (size + sp) + (k.mid || 0);
  const m = k && k.marks ? k.marks(size, sp) : [];
  const w = m.length ? Math.max(...m.map(([x, , ww]) => x + ww)) - Math.min(...m.map(([x]) => x)) : 0;
  return Math.max(SPLIT_GAP, Math.ceil(w) + 2 * (k && k.pad ? k.pad : 4));
}
// = ROW_ALIGNS in BarSplit.lua (2026-11-18, user): alignment of one row, chosen in the separator menu. "left" / "right":
// the whole row at that edge of the group, a split row only as wide as its icons plus the gap of its separator; "both":
// a split row spans the widest row of the group (left half from the left, right half from the right; the look before
// 2026-11-18). row.align nil = a split row "both", a normal row "right" (until the same day like "Icons:" of its
// group, which groups with rows no longer have; migrateRowAlign); a normal row never "both".
// mini = drawing in the menu, bar = marks along the bottom of the row's separator box (both [x, y, w, h] around the centre)
const ROW_ALIGNS = [
  { key: "left", label: () => L("Left"), mini: [[-13, -4, 7, 8], [-5, -4, 7, 8]], bar: [[-12, 6, 10, 1]] },
  { key: "right", label: () => L("Right"), mini: [[-2, -4, 7, 8], [6, -4, 7, 8]], bar: [[2, 6, 10, 1]] },
  { key: "both", label: () => L("Both sides"), mini: [[-13, -4, 7, 8], [6, -4, 7, 8]], bar: [[-12, 6, 6, 1], [6, 6, 6, 1]] },
];
const rowAlignKind = (key) => ROW_ALIGNS.find((a) => a.key === key);
// effective alignment of a row
function rowAlign(row) {
  const a = row && rowAlignKind(row.align) ? row.align : null;
  if (isSplitRow(row)) return a || "both";
  return a && a !== "both" ? a : "right";
}
// = B.RowsAlignRight in BarSplit.lua: the corner a group with rows grows away from and how a group docked above or below
// it lines up (2026-11-18, before "Icons:" of the group): left only when every row stands left
const rowsAlignRight = (rows) => !rows.length || rows.some((r) => rowAlign(r) !== "left");
// number of icons in the left half
const rowSplit = (row) => Math.max(0, Math.min(row.items.length, row.split ?? row.items.length));
// most icons of every row of a group (perLine 0 or 20 = 20)
const groupWidth = (g) => { const v = gEff(g, "perLine") ?? 0; return v > 0 && v < ROW_MAX ? v : ROW_MAX; };
// places a row needs (split or not, since session 20)
const rowNeed = (row) => row.items.length;
// how many icons fit into a row
const rowCap = (row) => groupWidth(rowGroupOf(row));
// most places one row of group g needs (the width cannot go below it, user 2026-11-16)
const groupNeed = (g) => profile.rows.filter((r) => (r.group || "main") === g.id).reduce((m, r) => Math.max(m, rowNeed(r)), 0);
// = B.RowLength in BarSplit.lua: own length of a row on the bar (a split row: its icons plus the gap of its look)
const rowLength = (row, size, sp) => Math.max(row.items.length * (size + sp) - sp + (isSplitRow(row) ? sepGap(rowSepStyle(row), size, sp) : 0), size);

// = PlaceSplitRow in BarSplit.lua: icons of one split row, rowW px wide (x0 = left edge of the row). No names since
// 2026-11-16 (user: only group names stay; before a name per half, row.nameR). makeMark(x, y, w, h): one piece of the
// separator (2026-11-17), in the middle of the free space between the halves, vertically in the middle of the icons.
function placeSplitRow(row, x0, y, size, sp, rowW, makeButton, makeMark) {
  const s = rowSplit(row), n = row.items.length;
  row.items.forEach((en, i) => makeButton(row, en, i, x0 + (i < s ? i * (size + sp) : rowW - (n - i) * (size + sp) + sp), y, size));
  const k = sepKind(rowSepStyle(row));
  if (!k || !k.marks) return;
  const a = s > 0 ? x0 + s * (size + sp) - sp : x0, b = n > s ? x0 + rowW - (n - s) * (size + sp) + sp : x0 + rowW;
  const cx = Math.round((a + b) / 2), cy = y + Math.round(size / 2);
  for (const [dx, dy, w, h] of k.marks(size, sp)) makeMark(cx + Math.round(dx), cy + Math.round(dy), w, Math.round(h));
}

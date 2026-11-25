"use strict";
/* RaidKit Buffs mockup: rows and groups of the options: insert, move, rename, delete (= OptionsModel.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

const activeRows = () => profile.rows;
// session 4b (= CurrentRow in Options.lua): with the group "Unerwünschte Buffs" selected the grid edits profile.unwanted
// through a pseudo row (plain buff IDs, no alternatives); before, the list was a field below the catalog
const curRow = () => {
  if (selectedGroup === "unw") { profile.unwanted = profile.unwanted || []; return { name: L("Unwanted Buffs"), unwanted: true, items: profile.unwanted }; }
  // the active row of the selected group (2026-11-16: rows are on the group's Layout tab; click on a line = active),
  // else its first row; a catalog click adds there
  const g = curGroup(); if (!g || g.area) return null;
  const r = activeRows()[selectedRow];
  return r && (r.group || "main") === g.id ? r : activeRows().find((x) => (x.group || "main") === g.id) || null;
};
const rowIndexOf = (row, id) => row ? row.items.findIndex((en) => entIds(en).includes(id)) : -1;
// removes id from the row: a plain entry disappears, a slot loses that variant; returns the removed entry index (plain) or -1
function takeFromRow(row, id, keepIndex) {
  const j = rowIndexOf(row, id);
  if (j < 0 || j === keepIndex) return -1;
  const en = row.items[j];
  if (!isSlot(en)) { spliceItem(row, j); return j; }
  en.v = en.v.filter((x) => x !== id);
  row.items[j] = normEntry(en);
  return -1;
}
function changed() { refreshOptions(); requestRebuild(); }

function insertItem(id, pos, rowArg) { // rowArg: a row of the split stack (2026-11-15), else the selected row
  if (!id) return;
  const row = rowArg || curRow();
  if (!row) return print(L("Please create a row first."));
  if (row.unwanted) {
    // unwanted list: only buffs, plain IDs (a buff already there is just moved)
    if (!isBuffId(id) || itemInfo(id).counter) return print(L("Only buffs can be unwanted.")); // not the buff counter
    const at = row.items.indexOf(id);
    if (at >= 0) row.items.splice(at, 1);
    else if (row.items.length >= MAX_UNWANTED) return print(fmt(L("At most %d unwanted buffs."), MAX_UNWANTED));
    row.items.splice(Math.min(pos ?? row.items.length, row.items.length), 0, id);
    return changed();
  }
  // since 2026-11-11 every row takes consumables and buffs
  // = InsertItem in Options.lua
  const existing = rowIndexOf(row, id);
  let entry;
  if (existing >= 0 && entMain(row.items[existing]) === id) entry = row.items.splice(existing, 1)[0]; // moved with its alternatives
  else if (row.items.length >= rowCap(row)) return print(rowFullText(row));
  else if (existing >= 0) { takeFromRow(row, id); entry = id; } // alternative of another icon: becomes its own icon
  // new: with its default alternatives; a weapon item takes the hand that the row does not cover yet
  else entry = defaultEntry(id, (x) => rowIndexOf(row, x) >= 0,
    row.items.some((e) => isWeaponEntry(e) && e.hand === "main") && !row.items.some((e) => isWeaponEntry(e) && e.hand === "off") ? "off" : "main");
  pos = Math.min(pos === undefined ? row.items.length : pos, row.items.length);
  row.items.splice(pos, 0, entry);
  for (const x of entIds(entry)) if (sim.counts[x] === undefined) sim.counts[x] = 0;
  changed();
}
function removeAt(i) { const r = curRow(); if (r && r.items[i] !== undefined) { spliceItem(r, i); changed(); } }
function moveTo(from, to) {
  const r = curRow(); if (!r) return;
  const [v] = r.items.splice(from, 1);
  to = Math.max(0, Math.min(to, r.items.length));
  r.items.splice(to, 0, v);
  changed();
}
function moveRowTo(from, to) {
  const rows = activeRows();
  if (!rows[from]) return from;
  to = Math.max(0, Math.min(to, rows.length - 1));
  if (to === from) return from;
  const [r] = rows.splice(from, 1);
  rows.splice(to, 0, r);
  return to;
}
// "+ Row" on the Layout tab of a group (2026-11-16): the row goes to the end of the selected group and becomes active;
// at most MAX_GROUP_ROWS per group (before 10 rows in the whole profile)
function addRow(row) {
  const g = curGroup(); if (!g || g.area) return;
  const rows = activeRows(), mine = groupRows(g);
  if (mine.length >= MAX_GROUP_ROWS) return print(fmt(L("At most %d rows per group."), MAX_GROUP_ROWS));
  row.group = g.id;
  fitRow(row, g); // a template longer than the group's rows is cut (2026-11-16)
  const pos = mine.length ? mine[mine.length - 1][1] + 1 : rows.length;
  rows.splice(pos, 0, row);
  normalizeGroups(); selectedRow = rows.indexOf(row); changed();
}
/* ----- Groups in the options (proposal 2026-11-11) ----- */
const LIST_LINES = 12, ROW_LINE_H = 17; // line pool: "All Groups" + 2 categories + main + 5 groups + 3 areas (no rows since 2026-11-16); the list reaches down to COL_BOTTOM
let groupRenameId = null;
function startGroupRename(id) { hideTip(); selectedGroup = id; groupRenameId = id; refreshOptions(); }
// "+ Gruppe" (2026-11-15, user): an empty group with the defaults of "All Groups", free without a position entry, so the
// layout puts it diagonally next to the main group towards the screen middle (newGroupPos) and keeps that place; it
// shows as a placeholder while editing; in the list it comes last (listGroups)
// Since 2026-11-20 (user) "+" is a menu: "Empty group" or a preset (groupPresets: the default groups of a new profile).
// A preset group gets the preset's name (a number behind it if taken), its values and fresh copies of its rows; its
// default place (Battle Shout: left of Buffs & Cons, at the end) only while that side is free (= AddGroup in OptionsModel.lua)
const SIDE_OPPOSITE = { bottom: "top", top: "bottom", left: "right", right: "left" };
// = SideFree in OptionsModel.lua: beside the target only the end align must be free (missing align = "start"), above
// or below the whole side
function sideFree(target, side, align) {
  if (!groupById(target)) return false;
  const vert = side === "bottom" || side === "top";
  if (Object.values(profile.groupPos || {}).some((q) => q && q.snap === target && q.side === side
    && (vert || (q.align || "start") === (align || "start")))) return false;
  const own = (profile.groupPos || {})[target];
  return !(own && own.snap && SIDE_OPPOSITE[own.side] === side);
}
function addGroup(preset) {
  if (rowGroups().length >= MAX_GROUPS) return print(fmt(L("At most %d groups with rows."), MAX_GROUPS));
  const used = (name) => profile.groups.some((g) => g.name === name || groupName(g) === name);
  let name;
  if (preset) { name = L(preset.name); for (let n = 2; used(name); n++) name = L(preset.name) + " " + n; }
  else { let n = 2; while (used(fmt(L("Group %d"), n))) n++; name = fmt(L("Group %d"), n); }
  let id = 1; while (groupById("g" + id)) id++;
  const g = Object.assign({ id: "g" + id, name, capTint: true }, clone(preset ? preset.values : {})); // empty: addon defaults (user 2026-11-15)
  profile.groups.splice(rowGroups().length, 0, g); // before the buff areas
  delete profile.groupPos["g" + id];
  if (preset) {
    if (preset.snap && sideFree(preset.snap, preset.side, preset.align)) profile.groupPos[g.id] = { snap: preset.snap, side: preset.side, align: preset.align };
    defaultRows(preset.key).slice(0, MAX_GROUP_ROWS).forEach((r) => { r.group = g.id; profile.rows.push(r); });
    normalizeGroups(); // rows in the order of the groups; widens the group if a row needs more places (not cut)
  }
  selectedGroup = g.id;
  changed();
  if (!preset) flash(L("Add rows with \"+ Row\" or drag rows of another group onto it in the list."));
}
// delete a group together with its rows (user 2026-11-20; before they moved to the main group), groups snapped to it
// take over its own position (= DeleteGroup in OptionsModel.lua)
// = DeleteMainGroup in OptionsModel.lua (user 2026-11-20): "main" is the anchor of the bar, so its rows go and the
// next group with rows moves into it (name as shown, values, rows) at that group's current place; without one the
// main group stays empty with default values
function deleteMainGroup() {
  const mainG = groupById("main");
  profile.rows = profile.rows.filter((r) => (r.group || "main") !== "main");
  const nextG = profile.groups.find((g) => g.id !== "main" && !g.area);
  for (const k of Object.keys(mainG)) if (k !== "id") delete mainG[k];
  if (!nextG) {
    Object.assign(mainG, { name: "Buffs & Cons", capTint: true });
    flash(L("The first group stays as the anchor of the bar; its rows and settings were removed."));
  } else {
    const name = groupName(nextG), x = groupEls.find((e) => e.g.id === nextG.id);
    if (x && !x.el._placeholder) { setFree(x.el); const q = profile.groupPos[nextG.id]; profile.point = [q.pt, "UIParent", q.pt, q.x, q.y, "outline"]; }
    for (const [k, v] of Object.entries(nextG)) if (k !== "id") mainG[k] = v;
    mainG.name = name;
    for (const r of profile.rows) if (r.group === nextG.id) r.group = "main";
    delete profile.groupPos[nextG.id];
    for (const o of Object.values(profile.groupPos)) if (o && o.snap === nextG.id) o.snap = "main";
    profile.groups = profile.groups.filter((g) => g !== nextG);
  }
  delete profile.groupPos.main;
  selectedRow = Math.max(0, Math.min(selectedRow, profile.rows.length - 1));
  selectedGroup = "main"; changed();
}
function deleteGroup(id) {
  if (id === "main") return deleteMainGroup();
  if (groupById(id) && groupById(id).area) return;
  const q = gpos(id);
  profile.rows = profile.rows.filter((r) => (r.group || "main") !== id); // its rows go with it (no icons into other rows)
  selectedRow = Math.max(0, Math.min(selectedRow, profile.rows.length - 1));
  for (const k of Object.keys(profile.groupPos)) {
    const o = profile.groupPos[k];
    if (o && o.snap === id) profile.groupPos[k] = q && q.snap ? { snap: q.snap, side: o.side, align: o.align } : Object.assign({}, freePos(id));
  }
  delete profile.groupPos[id];
  profile.groups = profile.groups.filter((g) => g.id !== id);
  selectedGroup = null; changed();
}
function askDeleteGroup() {
  const g = curGroup(); if (!g) return;
  if (g.area) return flash(L("This area cannot be deleted, only moved."));
  const n = profile.rows.filter((r) => (r.group || "main") === g.id).length;
  if (n === 0 || confirm(fmt(L("Delete group \"%s\" together with its %d rows?"), groupName(g), n))) deleteGroup(g.id);
}
// a row dragged by its grip onto a group in the list (2026-11-16): to the end of that group, if it fits
function moveRowToGroup(r, g) {
  if (g.area) return flash(L("This area takes no rows."));
  if (g.id === (r.group || "main")) return;
  // every row of a group has the same places (2026-11-16): a longer row does not fit into the target group
  if (rowNeed(r) > groupWidth(g)) return flash(fmt(L("Does not fit: the row needs %d places, group \"%s\" has %d per row."), rowNeed(r), groupName(g), groupWidth(g)));
  if (groupRows(g).length >= MAX_GROUP_ROWS) return flash(fmt(L("At most %d rows per group."), MAX_GROUP_ROWS));
  const rows = activeRows();
  rows.splice(rows.indexOf(r), 1); r.group = g.id; rows.push(r); // normalizeGroups puts it last in its group
  normalizeGroups();
  flash(fmt(L("Row moved to \"%s\"."), groupName(g)));
  changed();
}
const addEmptyRow = () => addRow({ name: "", items: [] });
const addTemplateRow = (tpl) => addRow({ name: tpl.name, items: templateItems(tpl) }); // the name stays in the data
function deleteRow(row) {
  const rows = activeRows(), i = rows.indexOf(row); if (i < 0) return;
  rows.splice(i, 1);
  selectedRow = Math.max(0, Math.min(selectedRow, rows.length - 1)); changed();
}
// "-" of a row line; in game: StaticPopup "RAIDKITBUFFS_DELETE_ROW", only if the row contains items
function askDeleteRow(row) {
  if (!row) return;
  if (row.items.length === 0 || confirm(fmt(L("Delete this row with %d icons?"), row.items.length))) deleteRow(row);
}
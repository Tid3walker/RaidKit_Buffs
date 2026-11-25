"use strict";
/* RaidKit Buffs mockup: options constants, slots, state, groups, chat, auras, rebuild (= Core.lua, Auras.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

const USE_MODES = ["ctrl", "off"];
const USE_MODE_LABEL = { ctrl: L("Ctrl+click"), off: L("Off (display only)") };
const USE_MODE_HINT = { ctrl: L("Ctrl+click: use") };
const MAX_ROWS = 10, MAX_ITEMS = 20 /* 30 until 2026-11-16: rows never wrap now, at most 20 places */, ITEM_SIZE = 22, ITEMS_PER_LINE = 20, CAT_LINES = 18 /* 19 until 2026-11-14 */, CAT_LINE_H = 20, GRID_Y = 88, LINE_H = 20;
const MAX_UNWANTED = 18; // "Unerwünschte Buffs": 3 lines in the grid, the group settings below (2026-11-11, user)
// COL_BOTTOM = end of all three columns (558). The five size sliders are on the Layout tab again since 2026-11-16
// (user; tab "Size" from 2026-11-15, SIZE_SL), placed by flowLayout below the checkboxes.
// Groups, "All Groups", "Bars" and the style tabs (2026-11-15, user): top-aligned from TOP_Y, one line below the other
// without gaps or overlaps (flowLayout in refreshOptions = O.Flow in Options.lua); the values below are only the
// first positions. Checkbox lines CB_STEP apart (24 = height of a checkbox, 22 until 2026-11-15).
// OPT_Y (2026-11-15, user): heading "Options" of the Layout tab, below the one icon line of "Unerwünschte Buffs".
// STAB_DY: the style tabs take one line below the heading (2026-11-16, user; two lines from 2026-11-15 = 44, before
// one line): everything below them (TOP_Y, OPT_Y, the grid of "Unerwünschte Buffs", the preview) sits 22 lower than
// the heading line.
const STAB_DY = 22;
const CB_Y = 198, CB_STEP = 24, ORIENT_Y = 338, POS_Y = 368, TOP_Y = 92 + STAB_DY, OPT_Y = 124 + STAB_DY, COL_BOTTOM = 558; // 114, 146
// proposal 2026-11-09: navigation list on the left (NAV_W), pages to the right (PAGE_X, PAGE_W x CONTENT_H)
// proposal 2026-11-14 (user): the navigation is a tab line at the top (TAB_H) instead of a column on the left, the
// pages start at x 0 and get the full width. Before: NAV_W 130, PAGE_X 140, PAGE_W 660, CONTENT_H 552.
const TAB_H = 36, PAGE_X = 0, PAGE_W = 984 /* 960 until 2026-11-16, in session 20 974, 980, 972; 984 since 2026-11-17 (wider separator box) */, CONTENT_W = PAGE_X + PAGE_W, CONTENT_H = 552 + TAB_H, ROWS_DY = -56;
// middle column twice as wide (user): 20 icons per line (the bar's maximum) at 22 px + a reserve in the middle for
// split rows later (MID_GAP). Before: ITEM_SIZE 30, gap 4, 6 per line, CAT_X 420.
// row list 140 px wide (2026-11-16; 190 from 2026-11-14, 150 before), the middle column follows (GRID_X 165)
// 2026-11-16 (user): the list shows only groups (the rows are on the Layout tab of their group), 140 px; the middle
// column gets the room: grip + 20 places + "split" checkbox, eye and "-" of every row line (MID_EXTRA)
const ITEM_GAP = 2, MID_GAP = 10, ROWS_W = 140, MID_EXTRA = 84; // 60 until 2026-11-16; session 20: row line controls (74, 80 with the shift of a full split row, 72); 84 since 2026-11-17 (separator box 28 px)
const ROWS_X = 10, GRID_X = ROWS_X + ROWS_W + 15, ITEM_STEP = ITEM_SIZE + ITEM_GAP;
const MID_W = ITEMS_PER_LINE * ITEM_STEP - ITEM_GAP + MID_EXTRA, CAT_X = GRID_X + MID_W + 13; // 550, 728 (the catalog keeps its 234 px)
const MAX_GROUP_ROWS = 6; // rows per group (2026-11-16, user: "probably not more than 5 or 6"; 8 would fit)
// "Like All Groups" (150 px) in the heading line, right edge = right edge of the last style tab in a line (3 x 162 = 486)
// "Leisten" since 2026-11-12 (user; before "Reihen"). "Common" (language, 2026-11-14) removed 2026-11-15 (user): the
// language is in the bottom line of "Bars" now
const OPT_PAGES = [{ key: "profiles", label: L("Profiles") }, { key: "rows", label: L("Bars") }, { key: "info", label: L("Info") }]; // "Info" since 2026-11-20 (user)
const CHAR = "Oxymooron - Pyrewood Village";

function itemInfo(id) {
  const e = CAT_BY_ID[id] || EXTRA[id] || BUFF_BY_ID[id];
  if (e) return e;
  return { id, name: fmt(L("Item #%d (loading ...)"), id), icon: "inv_misc_questionmark", dur: 1800 };
}
function setIcon(el, id) { el.style.backgroundImage = `url(${ICON_URL(itemInfo(id).icon)})`; }
const clone = (o) => JSON.parse(JSON.stringify(o));

/* ===================== Slots / alternatives (proposal, Roadmap topic 2) ===================== */
// A row entry is an itemID or a slot { v: [itemID, ...], pick: itemID }.
// v[0] is the icon in the options grid, v[1..] the alternatives in the fold-out column; v order = fallback order.
const MAX_VARIANTS = 6, MAX_VARIANTS_FOOD = 11; // = ns.MaxVariants: food/drinks icon + 10 alternatives (user 2026-11-11)
const maxVariants = (mainId) => itemInfo(mainId).cat === "food" ? MAX_VARIANTS_FOOD : MAX_VARIANTS;
const FLY_PER_COL = 6; // the fold-out column wraps into a second column after 6 fields
const isSlot = (e) => e !== null && typeof e === "object";
const entIds = (e) => isSlot(e) ? e.v : [e];
const entMain = (e) => entIds(e)[0];
const entPick = (e) => isSlot(e) ? e.pick : e;
// a slot with one variant becomes a plain itemID again
function normEntry(e) {
  if (!isSlot(e)) return e;
  e.v = [...new Set(e.v)];
  if (e.v.length === 1 && !e.hand) return e.v[0]; // weapon entries stay slots: they carry the hand
  if (!e.v.includes(e.pick)) e.pick = e.v[0];
  return e;
}
// buff place: items with the same place overwrite each other (Buff-Detection.md). In Lua this becomes a
// "slot" field in Data.lua; the mockup only knows the common ones, everything else is its own place.
const BUFF_PLACE = {
  // = ns.BUFF_PLACE in Data.lua
  13452: "agi", 9187: "agi", 8949: "agi", 3390: "agi", 2457: "agi",
  9206: "str", 12451: "str",
  12460: "ap", 12820: "ap",
  20079: "zanza", 20081: "zanza", 20080: "zanza",
  3825: "fort", 2458: "fort",
  13445: "def", 8951: "def", 3389: "def", 5997: "def",
  20004: "troll", 3826: "troll", 3388: "troll", 3382: "troll",
  21151: "rum", 21114: "rum", 20709: "rum", 18269: "rum",
  13457: "fireprot", 6049: "fireprot", 13456: "frostprot", 6050: "frostprot",
  13458: "natureprot", 6052: "natureprot", 13459: "shadowprot", 6048: "shadowprot",
  13455: "stoneshield", 4623: "stoneshield", 13442: "rage", 5633: "rage",
};
// = ns.DEFAULT_ALTS in Data.lua: default alternatives when an item is added or comes from a template
const DEFAULT_ALTS = {
  13452: [9187, 10309], 9206: [10310], 3825: [10307], 9179: [10308], 13447: [10306], // + strongest scroll (2026-11-25)
  12451: [9206, 10310], 12460: [12820], 20452: [13810, 13928, 21023, 12215, 12218, 12216, 17222, 18045], 21023: [12215, 12218, 12216, 17222, 18045], 21151: [18269],
  13445: [8951, 10305], 13457: [6049], 13456: [6050], 13458: [6052], 13459: [6048], 13455: [4623], 13442: [5633],
  20004: [3388],
  18262: [12404, 12643], // weapon: Elemental, then Dense Sharpening Stone, Dense Weightstone (blunt; user 2026-11-10)
  [-22783]: [-10220], [-10220]: [-22783], // mage armors (2026-11-15, user): Mage Armor <-> Ice Armor
};
// = ns.DefaultEntry / ns.TemplateItems in Core.lua
function defaultEntry(id, skip, hand) {
  const alts = DEFAULT_ALTS[id];
  // weapon items always become a slot with a hand (main unless the caller says otherwise)
  if (isWeapon(id)) return normEntry({ v: [id, ...(alts || [])], pick: id, hand: hand || "main" });
  if (!alts) return id;
  return normEntry({ v: [id, ...alts.filter((a) => !(skip && skip(a)))], pick: id });
}
// buffs of the other faction are left out (Alliance: no totems, Horde: no blessings/auras)
const fitsFaction = (id) => !isBuffId(id) || buffFits(itemInfo(id));
// noAlts (2026-11-10, "Essen & Co"): plain icons without DEFAULT_ALTS; weapon items stay a slot with a hand
function templateEntry(e, noAlts) {
  if (typeof e === "number" && noAlts && !isBuffId(e)) return isWeapon(e) ? normEntry({ v: [e], pick: e, hand: "main" }) : e;
  if (typeof e === "number") return fitsFaction(e) ? defaultEntry(e) : undefined;
  const v = (Array.isArray(e) ? e : e.v).filter(fitsFaction);
  return v.length ? normEntry(e.hand ? { v, pick: v[0], hand: e.hand } : { v, pick: v[0] }) : undefined;
}
// noAltsFrom (2026-11-14, "Selbst verantwortlich"): noAlts from that entry on (1-based like Lua, the "Essen & Co" part)
const templateItems = (tpl) => tpl.items.map((e, i) => templateEntry(e, tpl.noAlts || (tpl.noAltsFrom && i + 1 >= tpl.noAltsFrom)))
  .filter((e) => e !== undefined);
function buffPlace(id) {
  const i = itemInfo(id);
  if (BUFF_PLACE[id]) return BUFF_PLACE[id];
  if (i.cat === "flask") return "flask";
  if (i.cat === "food") return "food";
  return "item" + id;
}
// isMixed (= ns.IsMixedEntry, the yellow "!" below the alternatives) removed 2026-11-18 (user)
// weapon enchant items (stones, oils, poisons) and weapon entries in a row
const isWeapon = (id) => !!(CAT_BY_ID[id] && CAT_BY_ID[id].cat === "weapon");
const isWeaponEntry = (e) => isSlot(e) && !!e.hand;
const HAND_LETTER = { main: L("MH"), off: L("OH") }, HAND_NAME = { main: L("Main hand"), off: L("Off hand") };
// Flasks and Zanza (type "Flasks, Zanza") stay locked in combat if they were active at the pull
const isFlaskEntry = (e) => entIds(e).some((id) => itemInfo(id).cat === "flask");

/* ===================== State ===================== */
let db, profile, barLayout, sim, selectedRow = 0;
let filterIndex = 0, catList = "raid:" + playerClass, catSearch = "", catOffset = 0;
let catTab = "consume", buffFilterIndex = 0; // catalog tab: only switched by hand (2026-11-11)

// like Core.lua: a new profile gets a copy of every row template, only the visible ones are shown
const rowTemplates = () => ROW_TEMPLATES[playerClass] || [];
// = DefaultRows in Rows.lua: copies of the visible templates; groupId (2026-11-20, presets): only those of that group
// ("main" = templates without t.group), undefined = all
function defaultRows(groupId) {
  // only the visible templates (user 2026-11-11); the others stay available through "+". visible = place in the new
  // profile (2026-11-14), true = template order
  const rank = (t, i) => (typeof t.visible === "number" ? t.visible : 100) * 1000 + i;
  return rowTemplates().map((t, i) => ({ t, k: rank(t, i) }))
    .filter((x) => x.t.visible && (groupId === undefined || (x.t.group || "main") === groupId)).sort((a, b) => a.k - b.k).map(({ t }) => {
    const r = { name: t.name, items: templateItems(t) };
    if (t.group) r.group = t.group; // the row starts in that class group (2026-11-18, CLASS_GROUPS)
    // separator and eye of the template (user 2026-11-19, = DefaultRows in Core.lua): split = icons left, splitLast =
    // icons right (after the faction filter)
    const split = t.split || (t.splitLast ? r.items.length - t.splitLast : 0);
    if (split > 0 && split < r.items.length) { r.split = split; r.sepStyle = t.sepStyle; }
    if (t.hidden) r.hidden = true;
    return r;
  });
}
// = ns.GroupPresets in Rows.lua (user 2026-11-20): the default groups of a new profile as presets of "+" in the list
// "Bars"; key = group id in a new profile, name = English key, values = group values, snap/side/align = default place
function groupPresets() {
  return [{ key: "main", name: "Buffs & Cons", values: {} }].concat((CLASS_GROUPS[playerClass] || []).map(({ id, name, snap, side, align, ...values }) => ({ key: id, name, values, snap, side, align })));
}
function newProfile(source) {
  if (source) return clone(source);
  const p = clone(PROFILE_DEFAULTS);
  p.rows = defaultRows();
  // the groups of the class (2026-11-18, = EnsureRows in Core.lua), without their default place
  p.groups = (CLASS_GROUPS[playerClass] || []).map(({ snap, side, align, ...g }) => clone(g));
  return p;
}
/* ===================== Groups (proposal 2026-11-11, Docs/Plan-Groups.md) ===================== */
// A group holds one or more rows, has its own position (free or snapped to another group's edge), an optional frame
// like the "Unerwünschte Buffs" button and own settings. profile.groups (part of "Reihen"), row.group = group id
// (missing = "main"). Positions are character keys: main = profile.point (free) and profile.groupPos[id] =
// { x, y } (free, centre offset like point) or { snap = id, side = "bottom" | "top" | "left" | "right" }.
// Phase 1: "Unerwünscht", "Sonstige" and "Debuffs" still hang below the main group (own groups in phase 2).
const MAX_GROUPS = 6, SNAP_DIST = 16, FRAME_PAD = 5, GNAME_H = 14; // MAX_GROUPS: row groups (areas extra)
// buff areas as groups (phase 2): not deletable, no rows; name = shown name of the area
// snap/side = default place (= ns.AREA_GROUPS, 2026-11-14, user's layout): Other below Buffs & Cons, Debuffs below
// Other, Unwanted left of Buffs & Cons. Before: unw, other, debuff below each other under main.
const AREA_GROUPS = [
  { id: "unw", area: "unw", name: "Unwanted Buffs", capTint: true, snap: "main", side: "left" }, // no own showName since 2026-11-15 (user): follows "All Groups" (= MigrateAreaNames)
  { id: "other", area: "other", name: "Other Buffs", capTint: true, snap: "main", side: "bottom" },
  // own separator in red (style proposal 2026-11-14: before the fixed .cb-sep.deb colour)
  { id: "debuff", area: "debuff", name: "Debuffs", snap: "other", side: "bottom", style: { sep: { color: "#ff5959", alpha: 0.45 } } }, // only the colour is own, the rest follows "Alle Gruppen"
];
const rowGroups = () => profile.groups.filter((g) => !g.area);
let selectedGroup = "main"; // options: group selected in the list; "Buffs & Cons" when the options open (session 20)
let styleTab = "layout"; // sub-tab of the middle column for "Alle Gruppen" and groups (style proposal 2026-11-14)
// colour picker of the options (= ColorPickerFrame): opens beside the swatch, live preview, Cancel restores
function openColorPicker(anchor, o) {
  const p = C.cpick, start = { c: o.color, a: o.alpha };
  p.innerHTML = `<div class="h"></div><div class="row"><input type="color"><span class="hex"></span></div>` +
    (o.alpha != null ? `<div class="row"><span class="al"></span><input type="range" min="0" max="1" step="0.05"><span class="av"></span></div>` : "") +
    `<div class="btns"></div>`;
  p.querySelector(".h").textContent = o.title;
  const col = p.querySelector("input[type=color]"), rng = p.querySelector("input[type=range]");
  col.value = o.color;
  const show = () => { p.querySelector(".hex").textContent = col.value.toUpperCase(); if (rng) p.querySelector(".av").textContent = Math.round(rng.value * 100) + "%"; };
  if (rng) { p.querySelector(".al").textContent = L("Opacity"); rng.value = o.alpha; }
  const apply = () => { show(); o.set(col.value, rng ? +rng.value : null); };
  col.addEventListener("input", apply); if (rng) rng.addEventListener("input", apply);
  const ok = Button("OK", 80, () => closeColorPicker());
  const cancel = Button(L("Cancel"), 80, () => { o.set(start.c, start.a); closeColorPicker(); });
  p.querySelector(".btns").append(ok, cancel);
  show();
  // beside the swatch, inside the page (coordinates of the page the swatch is on)
  const page = anchor.parentElement; page.appendChild(p);
  p.style.display = "block";
  p.style.left = Math.min(anchor.offsetLeft + anchor.offsetWidth + 8, page.offsetWidth - p.offsetWidth - 6) + "px";
  p.style.top = (anchor.offsetTop - 6) + "px";
}
function closeColorPicker() { if (C.cpick) C.cpick.style.display = "none"; }
const groupById = (id) => profile.groups.find((g) => g.id === id);
const curGroup = () => (selectedGroup ? groupById(selectedGroup) : null);
// = ns.GroupDisplayName in Core.lua (2026-11-14): a stored default name (German or English) shows the localized default
const DEFAULT_GROUP_NAMES = {
  main: { key: "Buffs & Cons", names: ["Buffs & Cons", "Hauptleiste"] },
  unw: { key: "Unwanted Buffs", names: ["Unwanted Buffs", "Unerwünschte Buffs"] },
  other: { key: "Other Buffs", names: ["Other Buffs", "Sonstige Buffs"] },
  debuff: { key: "Debuffs", names: ["Debuffs"] },
  shout: { key: "Battle Shout", names: ["Battle Shout"] }, // warrior group (2026-11-18, CLASS_GROUPS)
};
function groupName(g) {
  if (!g || typeof g !== "object") return L("Group");
  const name = typeof g.name === "string" ? g.name : "";
  const def = DEFAULT_GROUP_NAMES[g.id];
  if (def && (name === "" || def.names.includes(name))) return L(def.key);
  return name === "" ? L("Group") : name;
}
// old profiles have no groups: one group "main" with every row; rows are kept in group order (stable)
function ensureGroups(p) {
  if (!Array.isArray(p.groups) || !p.groups.length) p.groups = [];
  if (!p.groups.some((g) => g.id === "main")) p.groups.unshift({ id: "main", name: "Buffs & Cons", capTint: true });
  const mainG = p.groups.find((g) => g.id === "main"); if (mainG.name === "Hauptleiste") mainG.name = "Buffs & Cons"; // renamed 2026-11-12
  if (!p.groupPos) p.groupPos = {};
  // phase 2 (2026-11-11): the buff areas are fixed groups at the end of the list; default place from AREA_GROUPS
  for (const a of AREA_GROUPS) {
    const { snap, side, ...grp } = a;
    if (!p.groups.some((g) => g.id === a.id)) p.groups.push(clone(grp)); // clone: style is an object (2026-11-14)
    if (!p.groupPos[a.id]) p.groupPos[a.id] = { snap, side };
  }
  // groups of the class (2026-11-18, = EnsureGroupPos in Core.lua): their default place while the profile has them
  for (const c of CLASS_GROUPS[playerClass] || []) {
    if (p.groups.some((g) => g.id === c.id) && !p.groupPos[c.id]) p.groupPos[c.id] = { snap: c.snap, side: c.side, align: c.align };
  }
  const unwG = p.groups.find((g) => g.id === "unw"); if (unwG) delete unwG.frame; // no "Rahmen" option there (2026-11-14, user)
  p.groups = p.groups.filter((g) => !g.area).concat(p.groups.filter((g) => g.area));
  const order = new Map(p.groups.map((g, i) => [g.id, i]));
  for (const r of p.rows) if (!order.has(r.group)) r.group = "main";
  p.rows = p.rows.map((r, i) => [r, i]).sort((a, b) => order.get(a[0].group) - order.get(b[0].group) || a[1] - b[1]).map((x) => x[0]);
  migrateAllGroups(p);
  migrateRowAlign(p);
  // row spacing at most 20 since 2026-11-18 (user; before 40) = EnsureGroups in Core.lua
  for (const g of p.groups) if (typeof g.rowSpacing === "number" && g.rowSpacing > 20) g.rowSpacing = 20;
  // = end of FitRowWidths in Migrations.lua: a group whose rows need more places gets wider (12 places by default since
  // 2026-11-20, a template row may be longer)
  for (const g of p.groups) {
    if (g.area) continue;
    const n = p.rows.filter((r) => (r.group || "main") === g.id).reduce((m, r) => Math.max(m, r.items.length), 0);
    if (n > groupWidth(g)) g.perLine = n >= ROW_MAX ? 0 : n;
  }
}
// = MigrateRowAlign in Core.lua (2026-11-18, user): "Icons:" of a group with rows is gone, every row has its own
// alignment (row.align, bar-split.js). Every time, a no-op once done: a group on "Left" hands it to its normal rows
// without an own choice (split rows without one stay "Both sides"), then the group forgets its orientation.
function migrateRowAlign(p) {
  for (const g of p.groups) {
    if (g.area || !g.orientation) continue;
    if (g.orientation === "hleft") for (const r of p.rows) if ((r.group || "main") === g.id && r.split == null && r.align == null) r.align = "left";
    delete g.orientation;
  }
}
// = MigrateAllGroups in Core.lua (session 20, user: "Alle Gruppen" is gone, every group decides on its own). Every time,
// a no-op once done: a value of "Alle Gruppen" that differs from the default goes into every group without its own
// value (areas too), then the profile keeps only the default. Old saved and imported profiles keep their look.
function migrateAllGroups(p) {
  for (const [k, a] of Object.entries(GROUP_INHERIT)) {
    if (p[a] == null || p[a] === PROFILE_DEFAULTS[a]) continue;
    for (const g of p.groups) if (g[k] == null) g[k] = p[a];
    p[a] = PROFILE_DEFAULTS[a];
  }
  if (p.showBorders === true) { for (const g of p.groups) if (g.showBorders == null) g.showBorders = true; }
  p.showBorders = false;
  if (p.nameAlign && p.nameAlign !== "right") { for (const g of p.groups) if (!g.area && !g.nameAlign) g.nameAlign = p.nameAlign; }
  p.nameAlign = "right";
  for (const [sec, vals] of Object.entries(p.style || {})) {
    for (const g of p.groups) for (const [k, v] of Object.entries(vals || {})) {
      if (v == null || v === STYLE_DEF[sec][k]) continue;
      g.style = g.style || {}; g.style[sec] = g.style[sec] || {};
      if (g.style[sec][k] == null) g.style[sec][k] = v;
    }
  }
  delete p.style;
}
// keeps the selected row selected while ensureGroups reorders the rows
function normalizeGroups() {
  const r = profile.rows[selectedRow];
  ensureGroups(profile);
  if (r) selectedRow = Math.max(profile.rows.indexOf(r), 0);
  if (selectedGroup && !groupById(selectedGroup)) selectedGroup = null;
}
// effective settings of a group: its own values or the defaults (orientation, sizes; no "Alle Gruppen" since session 20)
function groupLayout(P, g) {
  const q = Object.assign({}, P);
  q.orientation = g.orientation || "hright";
  q.showBorders = g.showBorders === true;
  // every size value on its own (2026-11-14, user; before all five with "Eigene Größe")
  for (const k of ["iconSize", "spacing", "scale", "perLine", "rowSpacing"]) q[k] = gEff(g, k, P);

  q.rows = P.rows.filter((r) => (r.group || "main") === g.id);
  return q;
}

// snapshot for the bar (like BuildBar: hidden rows and, since 2026-11-16 (user), empty rows take no line)
// _src = index in profile.rows (the mouse wheel writes the chosen variant back into the profile)
const layoutFromProfile = () => { normalizeGroups(); return Object.assign(clone(profile), { rows: clone(profile.rows).map((r, i) => Object.assign(r, { _src: i })).filter((r) => !r.hidden && r.items.length > 0 && !(groupById(r.group || "main") || {}).hidden) }); }; // eye of a group: 2026-11-12
// Start place of the bar in the mockup only (2026-11-22, user): top right, just left of the minimap dummy (css .minimap,
// right 14 + 140 wide + gap). The addon itself still starts at the top center (PROFILE_DEFAULTS.point = Core.lua),
// because in the game the options window would cover a bar there on small screens; the mockup screen has no such window.
const MOCKUP_START_POINT = ["TOPRIGHT", "UIParent", "TOPRIGHT", -168, -12, "outline"];
function resetAll() {
  // proposal: chars[CHAR].settings = own settings incl. position; profiles = saved copies only
  db = { profiles: {}, chars: { [CHAR]: { settings: newProfile(), base: null } } };

  profile = db.chars[CHAR].settings;
  profile.point = clone(MOCKUP_START_POINT);
  sim = { auras: {}, durs: {}, counts: {}, cooldowns: {}, combat: false, pending: false, locked: new Set(),
    applied: {}, seq: 0, cancelled: new Set(), prev: {}, lost: {},
    group: "raid", optionsOpen: false, debuffs: {}, // group: "solo" | "party" | "raid"
    // weapon enchants per hand: { id, exp } (= GetWeaponEnchantInfo); wf = Windfury Totem on the main hand.
    // Working assumption (user 2026-11-09, unconfirmed): the stone stays on the weapon and only pauses while
    // Windfury is up. RaidKit Buffs itself does not depend on it: it shows what the game reports per hand.
    weapon: { main: null, off: null }, wf: false, offhand: true,
    zone: "world" }; // "world" | "aq40" (2026-11-19, = GetInstanceInfo() instanceID 531)
  for (const e of CATALOG) sim.counts[e.id] = 3;
  // mount items in the bags (2026-11-19): a 100 % horse, a 60 % pinto (taken once the horse is gone), blue before red
  // crystal (AQ40 still takes red first)
  for (const m of MOUNT_SIM) sim.counts[m.item] = [18777, 2414, 21218, 21321].includes(m.item) ? 1 : 0;
  sim.counts[3825] = 0;
  sim.counts[13452] = 0; // Mongoose missing: Ctrl+click falls back to Greater Agility
  sim.counts[6948] = 1;
  selectedRow = 0; filterIndex = 0; catList = "raid:" + playerClass; catSearch = ""; catOffset = 0;
  catTab = "consume"; buffFilterIndex = 0;
  barLayout = layoutFromProfile();
}

/* ===================== Chat ===================== */
function print(msg) {
  const c = document.getElementById("chat");
  const line = document.createElement("div");
  line.innerHTML = '<span class="p">RaidKit Buffs</span>: ';
  // WoW colour codes |cffRRGGBB ... |r (2026-11-14, the localized texts carry them like in Lua)
  const parts = String(msg).split(/(\|c[0-9a-fA-F]{8}|\|r)/);
  let target = line;
  for (const part of parts) {
    if (/^\|c[0-9a-fA-F]{8}$/.test(part)) { const sp = document.createElement("span"); sp.style.color = "#" + part.slice(4); line.appendChild(sp); target = sp; }
    else if (part === "|r") target = line;
    else if (part) target.appendChild(document.createTextNode(part));
  }
  c.appendChild(line);
  c.scrollTop = c.scrollHeight;
}
let flashTimer;
function flash(msg) {
  const f = document.getElementById("flash");
  f.textContent = msg; f.classList.add("show");
  clearTimeout(flashTimer); flashTimer = setTimeout(() => f.classList.remove("show"), 1600);
}

/* ===================== Time / auras (Auras.lua) ===================== */
const clock = { f: 1, offset: 0 };
const now = () => performance.now() / 1000 * clock.f + clock.offset;
function setTimeFactor(f) { const t = now(); clock.f = f; clock.offset = t - performance.now() / 1000 * f; }

function auraOfItem(id) { const i = itemInfo(id); return i.buff || ("use:" + id); }
function buffSpellsForItem(id) { return CAT_BY_ID[id] ? [CAT_BY_ID[id].buff] : BUFF_BY_ID[id] ? BUFF_BY_ID[id].spells : ["use:" + id]; }
// name and icon of any aura (catalog item, foreign buff or simulated proc)
const SPELL_INFO = {};
for (const e of CATALOG) SPELL_INFO[e.buff] = { name: e.name, icon: e.icon, item: e };
for (const b of BUFFS) for (const s of b.spells) SPELL_INFO[s] = { name: b.name, icon: b.icon, buffEntry: b };
for (const o of OTHER_SIM) SPELL_INFO[o.buff] = { name: o.name, icon: o.icon };
for (const o of MOUNT_SIM) SPELL_INFO[o.buff] = { name: o.name, icon: o.icon, buffEntry: BUFF_BY_ID[-458] }; // the real mount in "Sonstige"
const spellInfo = (sp) => SPELL_INFO[sp] || { name: "Buff " + sp, icon: "inv_misc_questionmark" };
// = ns:MountPick() in Auras.lua (2026-11-19, user): what Ctrl+click on the mount icon mounts while not riding.
// In AQ40 the first Qiraji crystal in MOUNT_QIRAJI order (red first), elsewhere the first 100 % mount in the bags
// (bag order; in the game a paladin's Charger / warlock's Dreadsteed comes first), without one the first 60 % mount
// (2026-11-19, MOUNT_SLOW; in the game Warhorse / Felsteed first). null = none, no click.
function mountPick() {
  const have = MOUNT_SIM.filter((m) => (sim.counts[m.item] || 0) > 0);
  if (sim.zone === "aq40") {
    for (const id of MOUNT_QIRAJI) { const m = have.find((x) => x.item === id); if (m) return m; }
    return null;
  }
  return have.find((m) => MOUNT_FAST.has(m.item)) || have.find((m) => MOUNT_SLOW.has(m.item)) || null;
}
const noMountText = () => L(sim.zone === "aq40" ? "No Qiraji crystal in the bags" : "No mount in the bags");
// never pushed off at the cap (working assumption): Flask/Zanza and world buffs
function capProtected(sp) {
  const i = SPELL_INFO[sp];
  return !!(i && ((i.item && i.item.cat === "flask") || (i.buffEntry && i.buffEntry.cat === "world")));
}
const activeAuras = (t) => Object.keys(sim.auras).filter((sp) => sim.auras[sp] > t);
// = applying a buff in the game; dur 0 = aura/totem without duration
function applyAura(sp, dur) {
  const t = now();
  sim.auras[sp] = dur ? t + dur : Infinity;
  sim.durs[sp] = dur || 0; // full duration for the yellow timer (2026-11-12)
  sim.applied[sp] = ++sim.seq; // refreshing a buff makes it the newest
  enforceCap();
}
// simulation of the cap: the oldest buff that is not protected drops (the game decides, not RaidKit Buffs)
function enforceCap() {
  const t = now();
  let act = activeAuras(t);
  while (act.length > BUFF_CAP) {
    const victim = act.filter((sp) => !capProtected(sp)).sort((a, b) => sim.applied[a] - sim.applied[b])[0];
    if (!victim) break;
    delete sim.auras[victim];
    act = activeAuras(t);
  }
}
function cancelAura(sp) { delete sim.auras[sp]; sim.cancelled.add(String(sp)); }
// = loss alarm (proposal): a consumable buff disappeared although time was left and the player did not
// remove it himself -> icon blinks red, chat message. In Lua: UNIT_AURA, compare with the last known state.
function detectLosses(t) {
  const cur = {};
  for (const sp of activeAuras(t)) cur[sp] = sim.auras[sp];
  for (const [sp, exp] of Object.entries(sim.prev)) {
    if (cur[sp] !== undefined) continue;
    const i = SPELL_INFO[sp];
    if (exp > t + 1 && !sim.cancelled.has(sp) && i && i.item) lossAlarm(sp, i.name, exp - t);
  }
  sim.cancelled.clear();
  sim.prev = cur;
}
// Sound of the loss alarm (2026-11-20, user; = LOSS_SOUNDS / LossAlarm / TestLoss in BarState.lua): game sounds the
// user picked with the temporary sound browser, or nothing. The mockup plays the game's files from Wowhead like the
// icons (FileDataID per sound kit from wago.tools SoundKitEntry: kit 8959 -> 567397 RaidWarning.ogg, 846 -> 567459,
// 416 -> 556000); a later own sound (s.file) would come from RaidKit_Buffs/Media/Sounds.
const SOUND_URL = (fileId) => "https://wow.zamimg.com/wowsounds/" + fileId;
const LOSS_SOUNDS = [{ key: "off", label: "Off" }, { header: true, label: "Game sounds" },
  { key: "RAID_WARNING", label: "Raid warning", url: SOUND_URL(567397) },
  { key: "IG_QUEST_LOG_ABANDON_QUEST", label: "Quest abandoned", url: SOUND_URL(567459) },
  { key: "MURLOC_AGGRO", label: "Murloc", url: SOUND_URL(556000) },
  // single game files (2026-11-20, user, = fileId entries in BarState.lua)
  ...[[539959, "Dwarf warrior"], [540824, "Human pirate"], [540831, "Human peasant"], [540839, "Human warrior 1"],
    [540849, "Human warrior 2"], [541306, "Orc warrior"], [542792, "Undead"], [547797, "Dryad"]].map(([id, label]) => ({ key: "F" + id, label, url: SOUND_URL(id) })),
  // own sounds (2026-11-20, user; the addon's files, licences in RaidKit_Buffs/Media/Sounds/CREDITS.txt)
  { header: true, label: "Own sounds" },
  { key: "fail", label: "Fail (retro)", file: "Fail.mp3" }, { key: "nooo", label: "Nooo!", file: "Nooo.mp3" }];
let lossSound = "nooo"; // = RaidKitBuffsDB.lossSound (account wide; nil there = "nooo" since 2026-11-20, user; before MURLOC_AGGRO)
let lossSoundAt = 0;
function playLossSound(key) {
  const s = LOSS_SOUNDS.find((x) => !x.header && x.key === (key || lossSound));
  if (!s || s.key === "off") return;
  const src = s.url || (s.file && "../../RaidKit_Buffs/Media/Sounds/" + s.file);
  if (src) new Audio(src).play().catch(() => {});
}
// icon blinks red 10 s, chat line, red text in the middle, sound (several at once: one sound)
function lossAlarm(sp, name, left, test) {
  const t = now();
  sim.lost[sp] = t + 10;
  print((test ? L("[Test] ") : "") + fmt(L("|cffff4040%s has vanished|r although %s were left (buff cap?)."), name, fmtTimeLong(left)));
  flash(fmt(L("%s lost!"), name));
  if (!test) recordLoss(name, left); // boss fight / raid summary (loss-report.js)
  if (t - lossSoundAt < 1) return;
  lossSoundAt = t;
  playLossSound();
}
// "Test" in the bottom line (= ns:TestLoss): a RANDOM elixir (2026-11-21, user: flasks/Zanza are not pushed off by
// the cap, the 1 h consumables are). Order: active elixirs (real time), elixirs on the bar (25 minutes), other active /
// other consumables, flasks only if nothing else is on the bar; no buff is touched
function testLoss() {
  const t = now();
  const tiers = [[], [], [], [], []];
  for (const b of barButtons) {
    if (isWeaponEntry(b._entry)) continue;
    const ids = entIds(b._entry).filter((id) => itemInfo(id).item || id > 0); // buffs (negative ids) are not consumables
    if (!ids.length) continue;
    // like the button: the active variant, else the shown one
    let id = ids.find((x) => itemBuffState(x).active), st = id !== undefined ? itemBuffState(id) : null;
    if (id === undefined) id = ids[0];
    const info = itemInfo(id), cat = (info.item || info).cat;
    const tier = cat === "flask" ? 4 : (cat === "elixir" ? 0 : 2) + (st ? 0 : 1);
    tiers[tier].push({ sp: auraOfItem(id), name: info.name, left: st ? st.exp - t : 1500 });
  }
  const list = tiers.find((l) => l.length);
  if (!list) { print(L("No consumable on the bar to test the loss alarm with.")); playLossSound(); return; }
  const pick = list[Math.floor(Math.random() * list.length)];
  lossAlarm(pick.sp, pick.name, pick.left, true);
  updateAll();
}
function itemBuffState(id) {
  const t = now();
  for (const sp of buffSpellsForItem(id)) {
    const exp = sim.auras[sp];
    if (exp !== undefined && exp > t) return { active: true, exp, dur: sim.durs[sp] || itemInfo(id).dur, sp }; // sp: the mount's icon
  }
  return { active: false };
}
function useItem(id) {
  const info = itemInfo(id), t = now();
  // mockup-only texts (in the game the client reports these)
  if ((sim.counts[id] || 0) <= 0) { print(fmt(L("No %s in the bags."), info.name)); return; }
  const cdKey = info.cat === "potion" ? "potion" : ("item" + id);
  const cd = sim.cooldowns[cdKey];
  if (cd && cd.start + cd.dur > t) { print(L("Item is not ready yet.")); return; }
  sim.counts[id]--;
  if (info.dur) applyAura(auraOfItem(id), info.dur);
  if (info.cat === "potion") sim.cooldowns[cdKey] = { start: t, dur: 120 };
  print(fmt(L("%s used."), info.name));
  updateAll();
}

/* ===================== Rebuild (Core.lua) ===================== */
function requestRebuild() {
  if (sim.combat) {
    if (!sim.pending) print(L("Change will be applied after combat."));
    sim.pending = true;
    updateAll(); // display only (bag count ...) right away, = UpdateAll in RequestRebuild (Core.lua, 2026-11-22)
    return;
  }
  sim.pending = false;
  barLayout = layoutFromProfile();
  buildBar();
  updateAll();
}

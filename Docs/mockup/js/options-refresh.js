"use strict";
/* RaidKit Buffs mockup: refreshOptions (= OptionsRefresh.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

function refreshOptions() {
  if (C.fitSearch) C.fitSearch(); // search box right after its label (2026-11-14)
  // proposal 2026-11-20 (user): the name of the loaded/saved profile while the settings equal it, otherwise "Own"
  // (the own settings are always stored for the character anyway); no "(changed)", no "- not saved -"
  const st = charState(), mod = isModified();
  C.profName.innerHTML = st.base && !mod ? esc(st.base) : `<span class="pnone">${L("Own##profile")}</span>`;
  C.profLoad.classList.toggle("dis", savedNames().length === 0);
  refreshProfilesPage();
  refreshInfoPage(); // live counter and error count of the page "Info" (2026-11-20)
  // the profile text right of the tabs (2026-11-14) is gone since 2026-11-20 (user): demo buttons at the right edge,
  // "+" 10 px from the edge, the demo button 4 px before "+"
  const addX = CONTENT_W - 10 - 22;
  C.demoAddBtn.style.left = addX + "px"; C.demoBtn.style.left = (addX - 4 - 150) + "px";
  C.showBtn.style.left = C.showBtn._menu.style.left = (addX - 4 - 150 - 4 - 180) + "px"; // "Show" left of the demo
  C.useModeBtn.textContent = USE_MODE_LABEL[profile.useMode];
  updateDemoButton();
  normalizeGroups();
  // something is always selected since 2026-11-16 (no row selection any more): nothing = the main group
  if (!selectedGroup) selectedGroup = "main";
  const rows = activeRows(), grp = curGroup();
  C.rowDelBtn.classList.toggle("dis", !grp || !!grp.area); // "Buffs & Cons" too since 2026-11-20
  C.addGroupBtn.classList.toggle("dis", rowGroups().length >= MAX_GROUPS);
  if (selectedRow >= rows.length) selectedRow = Math.max(rows.length - 1, 0);
  const edit = C.rowNameEdit;
  let editing = document.activeElement === edit;
  if (!editing) edit.style.display = "none";
  // list model (2026-11-11): per group a header, then its rows (rows are kept in group order by normalizeGroups).
  // 2026-11-12 (user, proposal B): last = last line of a group's box. "Alle Gruppen" (first entry from 2026-11-12) is
  // gone since session 20 (user): the heading "Bars" is the first line, with "+" and "-"
  C.listModel = [];
  // order of the list (2026-11-15, user): main group, the three areas, then the other groups in the order they were
  // added (a new one comes last); the data keeps groups with rows before the areas. The list is for managing rows,
  // where a group lies on the screen is shown by the bar itself.
  // 2026-11-15 (proposal): two categories, "Bars" (groups with rows: main first, new ones last) and "Areas" (Unwanted,
  // Other, Debuffs; filled by the addon, no rows)
  // the rows are on the Layout tab of their group since 2026-11-16 (user): the list shows the groups only
  const pushGroup = (g) => C.listModel.push({ g, n: rows.filter((r) => r.group === g.id).length, last: true });
  C.listModel.push({ cat: "bars" });
  profile.groups.filter((g) => !g.area).forEach(pushGroup);
  C.listModel.push({ cat: "areas" });
  profile.groups.filter((g) => g.area).forEach(pushGroup);
  C.rowLines.forEach((l, k) => {
    const m = C.listModel[k];
    l.style.display = m ? "" : "none";
    if (!m) return;
    const nm = l.querySelector(".nm");
    l.classList.toggle("cat", !!m.cat); l.classList.remove("catsel"); // headings only (session 20)
    l.classList.toggle("grp", !!(m.g && m.i === undefined)); l.classList.toggle("sub", m.i !== undefined);
    l.classList.toggle("area", !!(m.g && m.g.area && m.i === undefined)); l.classList.toggle("glast", !!m.last);
    if (m.cat) {
      nm.textContent = m.cat === "bars" ? L("Bars") : L("Areas"); nm.style.visibility = "";
      l.querySelector(".n").textContent = "";
      l.classList.remove("sel", "off", "goff");
      return;
    }
    // a group or an area (no rows in the list since 2026-11-16)
    const g = m.g, n = m.n;
    nm.textContent = groupName(g);
    nm.style.visibility = editing && edit.groupId === g.id ? "hidden" : "";
    l.querySelector(".n").textContent = g.area ? "" : n;
    l.classList.toggle("sel", selectedGroup === g.id);
    l.classList.toggle("off", !!g.hidden); l.classList.remove("goff");
    if (groupRenameId === g.id && !editing) {
      groupRenameId = null;
      nm.style.visibility = "hidden";
      edit.groupId = g.id; edit.rowIndex = null; edit.value = groupName(g); // the shown (localized) name, not the stored key (user 2026-11-20)
      edit.style.left = "4px"; edit.style.top = (k * ROW_LINE_H) + "px"; edit.style.display = "";
      edit.focus(); edit.select();
      editing = true;
    }
  });
  // middle column: group settings instead of the row (2026-11-11)
  pages.rows.classList.toggle("grpmode", !!grp);
  pages.rows.classList.toggle("areamode", !!(grp && grp.area));
  pages.rows.classList.toggle("unwmode", !!(grp && grp.area === "unw"));
  pages.rows.classList.toggle("debuffmode", !!(grp && grp.area === "debuff"));
  // style tabs (2026-11-14): layout or one of the style panels
  const styled = !!grp && styleTab !== "layout";
  pages.rows.classList.toggle("stylemode", styled);
  for (const k of ["frame", "sep", "icon"]) pages.rows.classList.toggle("s-" + k, styled && styleTab === k);
  C.styleTabs.forEach((b) => b.classList.toggle("on", b.dataset.key === styleTab));
  C.itemsLabel.style.maxWidth = MID_W + "px"; // "Like All Groups" is gone (session 20): the heading has the full width
  if (!styled) closeColorPicker();
  if (styled && styleTab === "icon") C.layoutIconColours();
  C.frameUnwNote.classList.toggle("retired", !!grp && grp.area !== "unw");
  // "Unerwünschte Buffs" (session 4b): its list in the grid like a row, the group settings below the grid
  const unwSel = !!(grp && grp.area === "unw");
  const gridLines = Math.ceil((unwSel ? MAX_UNWANTED : MAX_ITEMS) / ITEMS_PER_LINE);
  C.gridArea.style.height = (gridLines * ITEM_STEP - ITEM_GAP + 8) + "px";
  // "Unerwünschte Buffs" has the style tabs on the line below the heading (2026-11-14): its grid one line lower;
  // rows have no tabs, their grid stays at GRID_Y (= Options.lua RefreshRows). +4: 2 px between the tabs and the grid
  // frame, as below a heading
  const gridY = GRID_Y + (unwSel ? STAB_DY + 4 : 0);
  if (C.gridY !== gridY) {
    C.gridY = gridY;
    C.gridArea.style.top = (gridY - 4) + "px";
    C.itemButtons.forEach((b, i) => { b.style.top = (gridY + Math.floor(i / ITEMS_PER_LINE) * ITEM_STEP) + "px"; });
  }
  if (grp) {
    const q = gpos(grp.id), tg = q && q.snap ? groupById(q.snap) : null;
    // with the end of the side (2026-11-18, eight snap points); another group on the same side of the same target: a
    // note, they can overlap when one of them grows (= RefreshRows in OptionsRefresh.lua)
    const tEl = tg && (groupEls.find((x) => x.g.id === tg.id) || {}).el;
    const mate = tg && Object.entries(profile.groupPos || {}).find(([k, o]) => k !== grp.id && o && o.snap === q.snap && o.side === q.side);
    C.gPosText.style.whiteSpace = "pre"; // two lines, each cut with "..." like the single line before (= SetWordWrap(false))
    C.gPosText.textContent = (tg ? fmt(L("Position: snapped %s \"%s\""), slotName(q.side, slotAlign(q, tEl)), groupName(tg)) : L("Position: free"))
      + (mate ? "\n" + fmt(L("Shares this side with \"%s\": they can overlap if one grows."), groupName(groupById(mate[0]) || { name: "?" })) : "");
    C.gFreeBtn.style.visibility = tg ? "" : "hidden";
  }
  // top-aligned (2026-11-15, user): every visible line of the middle column one below the other from the top, nothing
  // overlaps and nothing is kept free that the view does not need; groups, "All Groups", "Bars" and the notes of the
  // style tabs alike (= O.Flow in Options.lua). "Unwanted Buffs" starts below its grid. Rows keep their size block at
  // the bottom (room for the alternatives column below the grid).
  layoutRowStack(); // the rows of the group on its Layout tab (2026-11-16): "Options" starts below them
  const shown = (el) => getComputedStyle(el).display !== "none";
  const flowLayout = (list, y) => {
    for (const e of list) {
      if (!e.el || !shown(e.el)) continue;
      const top = y + (e.dy || 0);
      e.el.style.top = top + "px"; if (e.el._menu) e.el._menu.style.top = (top + 24) + "px";
      // the control right of a checkbox, centred on it (22 px on 24 px; Lua: 20 px buttons +2)
      if (e.pair && shown(e.pair)) { const pt = top + (e.pairDy ?? 1); e.pair.style.top = pt + "px"; if (e.pair._menu) e.pair._menu.style.top = (pt + 24) + "px"; }
      if (e.also) e.also.style.top = (top + e.alsoDy) + "px";
      y += e.h != null ? e.h : e.el.offsetHeight + (e.gap || 0);
    }
    return y;
  };
  const cbLine = (el) => ({ el, h: CB_STEP, pair: el._pair });
  // Layout tab (2026-11-15, user): heading "Options" with a line at OPT_Y on every page (below the icon line of
  // "Unerwünschte Buffs", the same height everywhere), the options below it top-aligned; notes at the very bottom
  // since 2026-11-15 (user) also for rows: their size block right below "Options" (the alternatives column opens on
  // hover above it, like a menu)
  const optOn = !styled && !!grp;
  for (const el of C.optHead) el.style.display = optOn ? "" : "none";
  const optY = C.stackBottom || OPT_Y; // a group with rows: below its rows and "+ Row" (2026-11-16, user)
  C.optHead[0].style.top = optY + "px"; C.optHead[1].style.top = (optY + 20) + "px";
  const bottomFlow = (els) => {
    const vis = els.filter(shown);
    flowLayout(vis.map((el) => ({ el, gap: 6 })), COL_BOTTOM - vis.reduce((sum, el) => sum + el.offsetHeight + 6, -6));
  };
  if (grp && !styled) {
    // 2026-11-16 (user): checkboxes on the left, their controls on the right; "Icons: ..." right of the first checkbox
    // line without a partner ("Bag count", or "Buff cap tint" for the areas), own line on the right if there is none
    // (Debuffs; a checkbox line high like there, so the gap to "Orientation" is the same as on Other Buffs). Below them
    // a fine line and the five size sliders in two columns (tab "Size" gone), then the position.
    const free = [C.gCountCb, C.gCapCb].find(shown);
    const lines = [cbLine(C.gCountCb), cbLine(C.gCapCb), { ...cbLine(C.gNameCb), pair: C.gNameAlignBtn }, cbLine(C.gTimeCb)];
    // only the three areas have it since 2026-11-18 (user)
    if (!grp.area) { /* groups with rows: alignment per row */ } else if (free) lines.find((e) => e.el === free).pair = C.gOrientBtn;
    else lines.unshift({ el: C.gOrientBtn, dy: 1, h: CB_STEP });
    const [iconSz, spacing, scale, perLine, rowSp] = C.gSizes;
    lines.push({ el: C.gSizeLine, dy: 6, h: 12 }, { el: iconSz, h: 24, pair: perLine, pairDy: 0 }, { el: spacing, h: 24, pair: rowSp, pairDy: 0 }, { el: scale, h: 24 },
      { el: C.gPosText, dy: 8, h: 32, also: C.gFreeBtn, alsoDy: -5 });
    flowLayout(lines, optY + 24);
  }
  if (styled) { const sn = C.styleNotes[styleTab]; flowLayout(sn.els.map((el) => ({ el, gap: 6 })), sn.y); }
  // preview of the icons (2026-11-15, user): examples for Other / Debuffs, grey and without mouse, only on the Layout tab
  // (Unwanted Buffs shows its real list there, a group with rows its real rows since 2026-11-16)
  let pv = [];
  if (grp && !styled && (grp.area === "other" || grp.area === "debuff")) pv = PREVIEW_ICONS[grp.area].map((ic) => ICON_URL(ic));
  C.preview.style.display = pv.length ? "" : "none";
  C.previewIcons.forEach((t, i) => { t.style.display = pv[i] ? "" : "none"; if (pv[i]) t.style.backgroundImage = `url(${pv[i]})`; });
  const row = curRow(); // active row of the group, or the unwanted list (pseudo row, session 4b)
  // since 2026-11-11 the catalog tab no longer follows the selected row: every row takes both kinds
  C.itemsLabel.textContent = fmt(L("Group: %s"), groupName(grp));
  const items = unwSel && row ? row.items : []; // the grid is only for the unwanted list since 2026-11-16
  C.itemButtons.forEach((b, i) => {
    const en = unwSel && i >= MAX_UNWANTED ? undefined : items[i];
    if (en !== undefined) {
      const id = entMain(en);
      b.style.display = ""; b.dataset.id = id; setIcon(b, id);
      b.querySelector(".slotmark").style.display = isSlot(en) && !isWeaponEntry(en) ? "" : "none";
      const hm = b.querySelector(".handmark");
      hm.style.display = isWeaponEntry(en) ? "" : "none";
      hm.textContent = isWeaponEntry(en) ? HAND_LETTER[en.hand] : "";
      b.classList.toggle("pick", isSlot(en) && en.pick === id);
      // gold corner: the icon has alternatives (2026-11-12, = b.altMark in Options.lua)
      b.classList.toggle("hasalt", isSlot(en) && en.v.length > 1);
    }
    else { b.style.display = "none"; delete b.dataset.id; }
  });
  if (flyRow && !activeRows().includes(flyRow)) flyRow = null, flyIndex = null;
  if (flyIndex !== null && !(flyRow ? flyRow.items : items)[flyIndex]) flyIndex = null, flyRow = null;
  renderFlyout();
  C.gridEmpty.style.display = unwSel && items.length === 0 ? "" : "none";
  // Catalog: tabs
  const isB = catTab === "buff";
  C.tabConsume.classList.toggle("on", !isB); C.tabBuff.classList.toggle("on", isB);
  for (const el of [C.listBtn, C.filterBtn, C.sortBtn]) el.style.display = isB ? "none" : "";
  C.buffFilterBtn.style.display = isB ? "" : "none"; // the unwanted list lives in its group since session 4b
  if (isB) { C.listMenu.style.display = "none"; C.menu.style.display = "none"; C.sortMenu.style.display = "none"; } else C.buffMenu.style.display = "none";
  C.buffFilterBtn.textContent = fmt(L("Category: %s"), BUFF_FILTERS[buffFilterIndex].label);
  C.buffMenuItems.forEach((it, i) => it.classList.toggle("sel", i === buffFilterIndex));
  C.filterBtn.textContent = fmt(L("Category: %s"), FILTERS[filterIndex].label);
  C.menuItems.forEach((it, i) => it.classList.toggle("sel", i === filterIndex));
  const list = filteredCatalog();
  C.listBtn.textContent = fmt(L("List: %s"), currentList().label);
  C.listItems.forEach((it, i) => it.classList.toggle("sel", CATALOG_LISTS[i].key === currentList().key));
  catOffset = Math.max(0, Math.min(catOffset, Math.max(0, list.length - CAT_LINES)));
  C.sortBtn.textContent = fmt(L("Sort: %s"), currentSort().label);
  C.sortItems.forEach((it, i) => it.classList.toggle("sel", CATALOG_SORTS[i] === currentSort()));
  C.catLines.forEach((line, i) => {
    const e = list[catOffset + i];
    line._alts = e && !e.header && !e.isBuff ? DEFAULT_ALTS[e.id] : null;
    line.style.visibility = e ? "visible" : "hidden";
    // section header: gold text with a line below, no icon, not clickable or draggable
    line.classList.toggle("head", !!(e && e.header));
    // first entry of a later part of a category (2026-11-20, = line.subLine in Lua): faint line on the top edge
    line.classList.toggle("subtop", !!(e && list.subTop && list.subTop.has(e)));
    if (e && e.header) {
      line.entry = null;
      line.querySelector(".ic").style.backgroundImage = "none";
      line.querySelector(".nm").textContent = e.header;
      line.querySelector(".ck").textContent = ""; line._places = null;
      setAltMark(line.querySelector(".am"), null);
      line.classList.remove("in");
      return;
    }
    line.entry = e;
    if (!e) return;
    const inRow = unwSel ? rowIndexOf(row, e.id) >= 0 : !!groupRowOf(grp, e.id), unw = (profile.unwanted || []).includes(e.id);
    setIcon(line.querySelector(".ic"), e.id);
    line.querySelector(".nm").textContent = e.name;
    // buffs (2026-11-20): buff of a trinket / trigger of a proc (buffLink)
    setAltMark(line.querySelector(".am"), e.isBuff ? null : DEFAULT_ALTS[e.id], e.isBuff && buffLink(e) ? buffLink(e).mark : null);
    const ck = line.querySelector(".ck");
    // check = on a bar (2026-11-16, user): gold = in a row of any group, red = only on "Unwanted Buffs" (before a red
    // cross); the name stays green for the selected group; the check's tooltip names the groups (placesOf)
    const pl = placesOf(e.id, unw); line._places = pl;
    ck.textContent = pl.names.length ? "✔" : "";
    ck.classList.toggle("unw", !pl.groups && unw);
    line.classList.toggle("in", inRow);
  });
  C.controls.forEach((c) => c.refresh());
  C.showBtn.refresh();
}

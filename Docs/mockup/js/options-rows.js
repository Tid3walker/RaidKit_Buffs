"use strict";
/* RaidKit Buffs mockup: row list and item grid of the page "Bars" (= OptionsRows.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// left column and grid of the page "Bars" (part of createContent, runs right after Page("rows"))
function createRowsColumn() {

  const small = (text, x, tipText, fn, width) => {
    const b = Place(Button(text, width || 20, () => { if (!b.classList.contains("dis")) fn(); }), x, 66); b.classList.add("tiny");
    b.addEventListener("click", (e) => e.stopPropagation()); // inside the heading line since session 20
    b.addEventListener("mousemove", (e) => { if (b.classList.contains("dis")) return; tip.innerHTML = `<div class="w">${tipText}</div>`; placeTip(e); });
    b.addEventListener("mouseleave", hideTip);
    return b;
  };

  // Proposal 2026-11-12 (user): no heading "Reihen" any more. Since 2026-11-16 (user) the list shows only groups and
  // areas, the rows are on the Layout tab of their group (options-row-stack.js): "+" = new group, "-" = delete the
  // selected group. Since session 20 (user) "Alle Gruppen" is gone and both buttons sit right-aligned in the heading
  // line "Bars" (the first line of the list, = OptionsRows.lua).
  // menu of "+ Row" (empty row or a copy of a row template, like CreateAddMenu in Options.lua); placed below that button
  C.addMenu = Place(mk("div", "menu addmenu"), ROWS_X, 88);
  const addEntry = (label, fn) => {
    const it = mk("div", "it", label);
    it.addEventListener("click", () => { C.addMenu.style.display = "none"; fn(); });
    C.addMenu.appendChild(it);
  };
  // since 2026-11-11 every row takes consumables and buffs: one empty row, one template list
  addEntry(L("Empty row"), () => addEmptyRow());
  C.addMenu.appendChild(mk("div", "h", L("Templates")));
  rowTemplates().forEach((tpl) => addEntry(tpl.name, () => addTemplateRow(tpl)));
  // menu of "+" in the heading line (user 2026-11-20, = CreateGroupAddMenu in OptionsRows.lua): empty group, then
  // below the heading "Presets" the default groups of a new profile (groupPresets; more may follow)
  C.groupAddMenu = Place(mk("div", "menu addmenu"), ROWS_X, 88 + ROW_LINE_H + 2); // below the heading line (= Lua)
  const groupEntry = (label, fn) => {
    const it = mk("div", "it", label);
    it.addEventListener("click", () => { C.groupAddMenu.style.display = "none"; fn(); });
    C.groupAddMenu.appendChild(it);
  };
  groupEntry(L("Empty group"), () => addGroup());
  C.groupAddMenu.appendChild(mk("div", "h", L("Presets")));
  groupPresets().forEach((p) => groupEntry(L(p.name), () => addGroup(p)));
  C.addGroupBtn = small("+", ROWS_X, L("New group (empty or preset)"), () => {
    C.addMenu.style.display = "none";
    C.groupAddMenu.style.display = C.groupAddMenu.style.display === "block" ? "none" : "block";
  });
  withTip(C.addGroupBtn, () => `<div class="w">${L("New group (empty or preset)")}</div><div class="d">${L("It appears next to the first group, then drag it where you want it. Add rows with \"+ Row\" on its Layout tab.")}</div>`);
  C.rowDelBtn = small("-", ROWS_X + 22, L("Delete selected group"), () => askDeleteGroup());
  C.addGroupBtn.classList.add("lhbtn"); C.rowDelBtn.classList.add("lhbtn");
  // list of the groups (proposal 2026-11-11, rows only until 2026-11-16). Click = settings in the middle column; a row
  // dragged by its grip (Layout tab) onto a group = into that group
  const rowList = Place(mk("div", "rowlist"), ROWS_X, 88); rowList.style.width = ROWS_W + "px"; rowList.style.height = (COL_BOTTOM - 88) + "px"; rowList.style.overflow = "hidden"; // to the end of the columns (2026-11-12)
  C.rowLines = []; C.listModel = [];
  const lm = (k) => C.listModel[k];
  for (let k = 0; k < LIST_LINES; k++) {
    const line = mk("div", "rowline");
    line.dataset.k = k;
    line.innerHTML = `<div class="nm"></div><div class="n"></div><div class="pencil small">✎</div><div class="eye">\u{1F441}</div>`;
    // pencil = rename this group right here in the list (double-click does the same)
    const pencil = line.querySelector(".pencil");
    const rename = () => { const m = lm(k); if (m && m.g) startGroupRename(m.g.id); };
    pencil.addEventListener("click", (ev) => { ev.stopPropagation(); rename(); });
    pencil.addEventListener("mousedown", (ev) => ev.stopPropagation());
    pencil.addEventListener("mousemove", (ev) => { ev.stopPropagation(); tip.innerHTML = `<div class="w">${L("Rename group")}</div>`; placeTip(ev); });
    pencil.addEventListener("mouseleave", hideTip);
    // eye of a group (2026-11-12, g.hidden, whole group)
    const eye = line.querySelector(".eye");
    eye.addEventListener("click", (ev) => {
      ev.stopPropagation(); hideTip(); const m = lm(k); if (!m || !m.g) return;
      // hiding "Sonstige Buffs" / "Debuffs" asks every time (user 2026-11-12, = StaticPopup in Options.lua)
      if (!m.g.hidden && AREA_HIDE_TEXT[m.g.area] && !confirm(AREA_HIDE_TEXT[m.g.area])) return;
      if (m.g.hidden) delete m.g.hidden; else m.g.hidden = true; changed();
    });
    eye.addEventListener("mousedown", (ev) => ev.stopPropagation());
    eye.addEventListener("mousemove", (ev) => {
      ev.stopPropagation();
      const m = lm(k), g = m && m.g; if (!g) return;
      tip.innerHTML = `<div class="w">${g.hidden ? L("Hidden - click shows the group in the bar") : L("Visible - click hides the whole group in the bar")}</div>` +
        (g.area === "unw" ? `<div class="d">${L("While hidden, unwanted buffs appear under \"Other Buffs\".")}</div>` : "");
      placeTip(ev);
    });
    eye.addEventListener("mouseleave", hideTip);
    line.addEventListener("click", () => {
      if (justDragged) return;
      const m = lm(k); if (!m) return;
      if (m.cat) return; // "Bars" and "Areas" are headings only (session 20, user; "All Groups" is gone)
      selectedGroup = m.g.id;
      refreshOptions();
    });
    line.addEventListener("dblclick", rename);
    rowList.appendChild(line);
    C.rowLines.push(line);
  }
  // "+" and "-" right-aligned in the first line (always the heading "Bars", session 20)
  C.rowLines[0].append(C.addGroupBtn, C.rowDelBtn);
  // inline rename of a group: the edit box replaces the name of the line (Enter = save, Escape or clicking elsewhere = cancel)
  C.rowNameEdit = EditBox(ROWS_W - 40, () => {
    const ed = C.rowNameEdit, v = ed.value.trim();
    // unchanged text keeps the stored name (a default like "Battle Shout" stays localized, user 2026-11-20)
    if (ed.groupId) { const g = groupById(ed.groupId); if (g && v !== groupName(g)) { g.name = v; changed(); } }
  });
  C.rowNameEdit.classList.add("a"); C.rowNameEdit.style.display = "none"; rowList.appendChild(C.rowNameEdit);
  const endRename = () => { C.rowNameEdit.style.display = "none"; refreshOptions(); };
  C.rowNameEdit.addEventListener("blur", endRename);
  // also on Enter/Escape: blur does not fire while the page itself has no focus
  C.rowNameEdit.addEventListener("keydown", (ev) => { if (ev.key === "Enter" || ev.key === "Escape") endRename(); });
  // Items of the row: header = name of the selected row
  C.itemsLabel = Place(Label(""), GRID_X, 67);
  C.itemsLabel.style.maxWidth = MID_W + "px"; C.itemsLabel.style.overflow = "hidden"; C.itemsLabel.style.textOverflow = "ellipsis";
  const gridW = MID_W, gridH = Math.ceil(MAX_ITEMS / ITEMS_PER_LINE) * ITEM_STEP - ITEM_GAP; // whole column (2026-11-14)
  C.gridArea = Place(mk("div", "grid-area"), GRID_X - 4, GRID_Y - 4);
  C.gridArea.style.width = (gridW + 8) + "px"; C.gridArea.style.height = (gridH + 8) + "px";
  C.gridEmpty = mk("div", "grid-empty", L("Empty - drag items from the\ncatalog here")); C.gridEmpty.style.whiteSpace = "pre-line";
  C.gridArea.appendChild(C.gridEmpty);
  // preview of a group's icons on the Layout tab (2026-11-15, user): in the line where "Unerwünschte Buffs" has its
  // icons (grid y GRID_Y + STAB_DY + 4), grey, no mouse; filled by refreshOptions (= content.preview in OptionsRows.lua)
  C.preview = Place(mk("div", "grid-area pvbox"), GRID_X - 4, GRID_Y + STAB_DY);
  C.preview.style.width = (gridW + 8) + "px"; C.preview.style.height = (ITEM_STEP - ITEM_GAP + 8) + "px";
  C.previewIcons = [];
  for (let i = 0; i < PREVIEW_MAX; i++) { const t = mk("div", "pvic"); t.style.left = (4 + i * ITEM_STEP) + "px"; C.preview.appendChild(t); C.previewIcons.push(t); }
  C.preview.appendChild(mk("div", "pvlbl", L("Preview")));
  C.itemButtons = [];
  for (let i = 0; i < MAX_ITEMS; i++) {
    const b = Place(mk("div", "itm ic"), GRID_X + (i % ITEMS_PER_LINE) * ITEM_STEP, GRID_Y + Math.floor(i / ITEMS_PER_LINE) * ITEM_STEP);
    b.dataset.index = i;
    b.appendChild(mk("div", "slotmark"));
    // weapon entries: H/N mark, click switches the hand (2026-11-09)
    const hm = mk("div", "handmark"); b.appendChild(hm);
    hm.addEventListener("mousedown", (ev) => ev.stopPropagation());
    hm.addEventListener("click", (ev) => {
      ev.stopPropagation();
      const en = curRow().items[i];
      if (!isWeaponEntry(en)) return;
      en.hand = en.hand === "main" ? "off" : "main"; hideTip(); changed();
    });
    hm.addEventListener("mousemove", (ev) => { ev.stopPropagation(); tip.innerHTML = `<div class="w">${fmt(L("Hand: %s"), HAND_NAME[(curRow().items[i] || {}).hand] || "-")}</div><div class="d">${L("Click: switch main hand/off hand")}</div>`; placeTip(ev); });
    hm.addEventListener("mouseleave", hideTip);
    // click on an icon with alternatives: this one becomes the chosen variant again
    b.addEventListener("click", () => { if (justDragged || !b.dataset.id) return; const en = curRow().items[i]; if (isSlot(en) && en.pick !== entMain(en)) { en.pick = entMain(en); changed(); } });
    b.addEventListener("mousedown", (e) => { if (b.dataset.id) startPending(e, Number(b.dataset.id), "grid", i); });
    b.addEventListener("contextmenu", (e) => { e.preventDefault(); removeAt(i); });
    b.addEventListener("mousemove", (e) => {
      if (drag || !b.dataset.id) return;
      tip.innerHTML = `<div class="n">${itemInfo(Number(b.dataset.id)).name}</div><div class="d">(Item-Tooltip)</div>` +
        `<br><div class="d">${L("Drag: change order")}</div><div class="d">${L("Drag out or right-click: remove")}</div>` +
        (isFlaskEntry(curRow().items[i]) || isBuffId(entMain(curRow().items[i])) ? "" : `<div class="d">${L("Below: alternatives (drag an item into the empty field)")}</div>`);
      placeTipBeside(b);
    });
    b.addEventListener("mouseleave", hideTip);
    C.itemButtons.push(b);
  }
  C.flyout = Place(mk("div", "flyout"), 0, 0); C.flyout.style.display = "none";

}

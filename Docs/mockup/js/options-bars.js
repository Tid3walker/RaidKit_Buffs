"use strict";
/* RaidKit Buffs mockup: middle column of a group (= OptionsBars.lua; "All Groups" and "Bars" are gone since session 20).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// middle column of the page "Bars" (part of createContent). Returns the helpers the style tabs and the profile page use.
function createBarsPanel() {
  const get = (k) => () => profile[k];
  const set = (k) => (v) => { profile[k] = v; changed(); };
  const fmt2 = (v) => v.toFixed(2);
  const perTip = () => `<div class="w">${L("Per line (max.)")}</div><div class="d">${L("Places of every row of the group: a row holds at most this many icons and does not wrap. Not less than a row of the group needs.")}</div>`; // 2026-11-16, user

  // the inherit buttons "↺" (2026-11-14) are gone since session 20 (user): no "Alle Gruppen", every group decides alone
  const COL2 = GRID_X + 242; // right column of the options (Icons, Orientation, Font size)
  // right column flush with the right edge of the middle column (2026-11-16, user: the size sliders looked squeezed,
  // the style tabs had room on the right): COL_R for 222 px controls, COL_RS for a slider with its reset button
  // (224 + 14 = 238 px)
  const COL_R = GRID_X + MID_W - 222, COL_RS = GRID_X + MID_W - 238;
  C.controls = [];

  // A row has no own size since 2026-11-16 (user; before icon size, spacing, scale, per line with "↺"): every row of a
  // group uses the group's values and has as many places as the group's "Per line". Below the grid of a row: "Split
  // row" (options-split.js).
  // "Pro Zeile (max.)" 1-20 (user 2026-11-14): 20 = all 20 places, stored as 0 like before ("alle" is gone)
  const PER_MAX = 20, perGet = (g) => () => { const v = g(); return v > 0 && v < PER_MAX ? v : PER_MAX; }, perSet = (s) => (v) => s(v >= PER_MAX ? 0 : v);
  // the middle column shows either the selected row (grid) or the selected group (2026-11-11)
  for (const el of [C.gridArea, ...C.itemButtons, C.flyout]) el.classList.add("rowpanel");

  // group settings (proposal 2026-11-11). Since session 20 (user) every group decides on its own (no "Alle Gruppen"):
  // no own value = the default of the addon (gEff). "Buff-Limit-Färbung" stays per group (its default depends on the kind
  // of group). Frame / separator / icon borders: "Visible" on the style tabs.
  const G = () => curGroup();
  const gset = (k) => (v) => { const g = G(); if (g) { g[k] = v; changed(); } };
  // the default is not stored (a group without the value has the default)
  const gOwnSet = (k) => (v) => { const g = G(); if (!g) return; if (v === gDefault(g, k)) delete g[k]; else g[k] = v; changed(); };
  const gsz = (k) => () => gEff(G(), k);
  const gOn = (k) => () => !!G() && !!gEff(G(), k);
  // reset button "↺" behind every slider (2026-11-16, user; 2026-11-14 until session 20 the inherit button): gold = the
  // group has its own value, click = back to the default of the addon; grey = the default. Follows its control
  // (IB_DX right of it, same visibility); placed in refresh, after flowLayout.
  const IB_DX = 224; // 2 px after a 222 px control
  const fv = (v) => (Number.isInteger(v) ? String(v) : v.toFixed(2));
  const resetBtn = (el, k, f) => {
    const own = () => !!G() && G()[k] != null, show = (v) => (f || fv)(v);
    const b = Place(mk("div", "ibtn", "↺"), 0, 0);
    b.addEventListener("click", (e) => { e.stopPropagation(); if (!own()) return; hideTip(); delete G()[k]; changed(); });
    b.refresh = () => {
      b.style.left = (parseFloat(el.style.left) + IB_DX) + "px"; b.style.top = (parseFloat(el.style.top) + 4) + "px";
      b.style.display = getComputedStyle(el).display === "none" ? "none" : "";
      b.classList.toggle("dis", !own());
    };
    withTip(b, () => (own()
      ? `<div class="w">${fmt(L("Changed: %s (default: %s)"), show(gEff(G(), k)), show(gDefault(G(), k)))}</div><div class="d">${L("Click: back to the default value.")}</div>`
      : `<div class="w">${L("Default value")}</div>`));
    C.controls.push(b);
    return el;
  };
  C.gNameCb = Place(CheckBox(L("Show group name"), gOn("showName"), gOwnSet("showName")), GRID_X, 112);
  // "Show row names" and the position of the row names are gone since 2026-11-16 (user: only group names stay)
  C.gCapCb = withTip(Place(CheckBox(L("Buff cap tint"), () => { const g = G(); return !!g && (g.id === "main" ? g.capTint !== false : g.capTint === true); }, gset("capTint")), GRID_X, 156),
    () => `<div class="w">${L("Background is tinted when few buff slots are free")}</div><div class="d">${L("From 4 free slots yellow, then orange, at 1 red.")}</div>`);
  // bag count: the group's own value, no inheritance and no reset button (session 20, user: "Bars" is a heading only;
  // = MigrateBagCount in Core.lua, which copies the old value of "Bars" into every group with rows)
  C.gCountCb = Place(CheckBox(L("Bag count"), () => { const g = G(); return !!g && g.showCount === true; }, (v) => { const g = G(); if (!g) return; if (v) g.showCount = true; else delete g.showCount; changed(); }), GRID_X, 200);
  // remaining time in the icons (2026-11-14, user; = gTimeCb in Options.lua), font size right of it
  C.gTimeCb = withTip(Place(CheckBox(L("Show time"), gOn("showTime"), gOwnSet("showTime")), GRID_X, 244),
    () => `<div class="w">${L("Show time")}</div><div class="d">${L("Remaining time in the icons of this group.")}</div>`);
  C.gTimeSizeSl = withTip(Place(Slider(L("Font size"), gsz("timeSize"), gOwnSet("timeSize"), 1, 6, 20, null, gOn("showTime")), COL2, 242),
    () => `<div class="w">${L("Font size")}</div><div class="d">${L("Size of the remaining time in the icons of this group.")}</div>`);
  C.gTimeCb._pair = C.gTimeSizeSl;
  // size of the group on the Layout tab again since 2026-11-16 (user; own tab "Size" from 2026-11-15): two columns
  // below the checkboxes, left icon size / spacing / scale, right per line / row spacing (refreshOptions places them)
  const gSizes = [
    Place(Slider(L("Icon size"), gsz("iconSize"), gOwnSet("iconSize"), 2, 12, 64), GRID_X, OPT_Y),
    Place(Slider(L("Spacing"), gsz("spacing"), gOwnSet("spacing"), 1, 0, 20), GRID_X, OPT_Y),
    Place(Slider(L("Scale"), gsz("scale"), gOwnSet("scale"), 0.05, 0.5, 2, fmt2), GRID_X, OPT_Y),
    withTip(Place(Slider(L("Per line (max.)"), perGet(gsz("perLine")), perSet((v) => { const g = G(); if (g && !g.area && !widthOk(g, v)) return; gOwnSet("perLine")(v); }), 1, 1, PER_MAX), COL_RS, OPT_Y),
      () => perTip() + `<div class="d">${L("Other, Debuffs: at most this many icons in one line, then they wrap; snapped above or below a group at most as wide as that group (20 = as many as fit; free: 10).")}</div>`),
    withTip(Place(Slider(L("Row spacing"), gsz("rowSpacing"), gOwnSet("rowSpacing"), 1, 0, 20), COL_RS, OPT_Y), // max 20 since 2026-11-18 (user; before 40)
      () => `<div class="w">${L("Row spacing")}</div><div class="d">${L("Spacing between two rows of this group. Unwanted, Other, Debuffs: spacing between their lines.")}</div>`),
  ];
  const perF = (v) => String(v > 0 && v < PER_MAX ? v : PER_MAX);
  ["iconSize", "spacing", "scale", "perLine", "rowSpacing"].forEach((k, i) => resetBtn(gSizes[i], k, k === "perLine" ? perF : null));
  resetBtn(C.gTimeSizeSl, "timeSize");
  // fine line above the size sliders (2026-11-16, user; "Font size" stays with the options above it)
  C.gSizeLine = Place(mk("div", "sep"), GRID_X, OPT_Y); C.gSizeLine.style.width = MID_W + "px";
  // orientation: dropdown since 2026-11-12, created after choiceButton below (C.gOrientBtn)
  // one line (2026-11-15; before 165 px and wrapping), "Lösen" at the right end of the column in the same line
  C.gPosText = Place(Label("", "small"), GRID_X, POS_Y); C.gPosText.style.width = (MID_W - 70) + "px"; C.gPosText.style.whiteSpace = "nowrap"; C.gPosText.style.overflow = "hidden"; C.gPosText.style.textOverflow = "ellipsis";
  C.gFreeBtn = Place(Button(L("Detach"), 60, () => {
    const g = G(), x = g && groupEls.find((e) => e.g.id === g.id);
    if (!x || !gpos(g.id) || !gpos(g.id).snap) return;
    setFree(x.el); refreshOptions(); requestRebuild();
  }), GRID_X + MID_W - 60, POS_Y - 2);
  C.gSizes = gSizes;
  // heading "Options" with a line on the Layout tab (2026-11-15, user; like "Background" on the Frame tab), the same
  // height on every page; shown by refreshOptions
  C.optHead = [Place(Label(L("Options")), GRID_X, OPT_Y), Place(mk("div", "sep"), GRID_X, OPT_Y + 20)];
  C.optHead[1].style.width = MID_W + "px";
  C.gCountCb.classList.add("notarea");
  C.gCapCb.classList.add("notdebuff"); // "Buff-Limit-Färbung" makes no sense for debuffs (session 4c, user)
  const gpanel = [C.gNameCb, C.gCapCb, C.gCountCb, C.gTimeCb, C.gTimeSizeSl, ...gSizes];
  for (const el of [...gpanel, C.gPosText, C.gFreeBtn, C.gSizeLine]) el.classList.add("grppanel");
  C.controls.push(...gpanel);

  // bottom line of "Reihen": how the bar is used (stays here for now, own page later if it grows)
  const sep = Place(mk("div", "sep"), 10, COL_BOTTOM + 10); sep.style.width = (PAGE_W - 20) + "px";
  // "Use:" at the right end since 2026-11-15 (user; the language takes the left end, created with choiceButton below):
  // button right-aligned with the catalog (PAGE_W - 10), its label right-aligned in front of it
  const useLbl = Place(Label(L("Use:")), PAGE_W - 10 - 150 - 8 - 150, COL_BOTTOM + 21); // Lua: +23 (label templates sit differently)
  useLbl.style.width = "150px"; useLbl.style.textAlign = "right";
  C.useModeBtn = Place(Button("", 150, () => {
    profile.useMode = USE_MODES[(USE_MODES.indexOf(profile.useMode) + 1) % USE_MODES.length];
    changed();
  }), PAGE_W - 10 - 150, COL_BOTTOM + 19);

  // proposal 2026-11-09: display mode, orientation of the bar, where "Sonstige" docks (popup opens downwards)
  // opt (2026-11-12): { get, set } instead of profile[key] (orientation of a group); the list is the same
  const choiceButton = (x, y, list, key, prefix, width, opt) => {
    const get = opt && opt.get ? opt.get : () => profile[key], put = opt && opt.set ? opt.set : (v) => { profile[key] = v; };
    const menu = Place(mk("div", "menu posmenu"), x, y + 24);
    // opt.up (2026-11-15, language in the bottom line): the menu opens upwards, its lower edge 2 px above the button
    if (opt && opt.up) menu.style.transform = "translateY(calc(-100% - 26px))";
    const btn = Place(Button("", width || 150, () => { if (btn.classList.contains("dis")) return; const open = menu.style.display === "block"; content.querySelectorAll(".menu").forEach((m) => { m.style.display = "none"; }); menu.style.display = open ? "none" : "block"; }), x, y);
    // o.header (2026-11-20, alarm sounds "Game sounds" / "Own sounds"; = CreateChoiceButton in OptionsBase.lua): a gold
    // heading line, not clickable, never the current value
    const items = list.map((o) => {
      const it = mk("div", o.header ? "hd" : "it", typeof o.label === "function" ? o.label() : o.label);
      if (!o.header) it.addEventListener("click", () => { put(o.key); menu.style.display = "none"; changed(); });
      menu.appendChild(it);
      return it;
    });
    btn.refresh = () => {
      const cur = list.find((o) => !o.header && o.key === get()) || list.find((o) => !o.header);
      btn.textContent = prefix + (typeof cur.label === "function" ? cur.label() : cur.label);
      items.forEach((it, i) => { if (typeof list[i].label === "function") it.textContent = list[i].label(); });
      items.forEach((it, i) => it.classList.toggle("sel", list[i] === cur));
      // opt.preview (style 2026-11-14): small sample of the texture / line in front of every entry (current colours)
      if (opt && opt.preview) items.forEach((it, i) => {
        const old = it.querySelector(".prev"); if (old) old.remove();
        const sw = mk("span", "prev"); Object.assign(sw.style, opt.preview(list[i].key)); it.prepend(sw);
      });
      if (opt && opt.menuWidth) menu.style.width = opt.menuWidth + "px";
      // opt.enabled (2026-11-12): greyed out, the menu closes (row names off, columns)
      if (opt && opt.enabled) { const on = opt.enabled(); btn.classList.toggle("dis", !on); if (!on) menu.style.display = "none"; }
    };
    btn._menu = menu;
    return btn;
  };
  // orientation of a group as a dropdown (2026-11-12, user). Since session 20 (user) without "Automatic": every group,
  // the three areas too, has its own value; none stored = the default "Rows right" (= ns.Orientation in Bar.lua)
  // icon alignment in the right column since 2026-11-16 (user; own line on the left from 2026-11-15, before right of
  // "Show group name"): right of the first checkbox line without a partner (refreshOptions)
  C.gOrientBtn = withTip(choiceButton(COL2, ORIENT_Y, ORIENTATIONS, null, L("Icons: "), 222, {
    get: () => (curGroup() ? curGroup().orientation || "hright" : null),
    set: (v) => { const g = curGroup(); if (g) g.orientation = v; },
  }), () => `<div class="w">${L("Orientation")}</div><div class="d">${L("How the icons of this group are laid out: rows left- or right-aligned.")}</div>`);
  // only Unwanted, Other and Debuffs since 2026-11-18 (user): a group with rows sets it per row (separator menu)
  for (const el of [C.gOrientBtn, C.gOrientBtn._menu]) el.classList.add("grppanel", "areaonly");
  C.controls.push(C.gOrientBtn);
  // alignment of the group name (2026-11-15, user): only the name, right of "Show group name", grey without the name.
  // Own value only since session 20 (default "right")
  C.gNameAlignBtn = withTip(choiceButton(COL2, 0, NAME_ALIGNS, null, L("Orientation: "), 222, {
    get: () => (curGroup() ? curGroup().nameAlign || "right" : null),
    set: (v) => { const g = curGroup(); if (g) g.nameAlign = v; },
    enabled: () => !!G() && !!gEff(G(), "showName"),
  }), () => `<div class="w">${L("Alignment of the group name")}</div><div class="d">${L("Where the name of this group stands.")}</div>`);
  for (const el of [C.gNameAlignBtn, C.gNameAlignBtn._menu]) el.classList.add("grppanel");
  C.controls.push(C.gNameAlignBtn);
  // "Like All Groups" (Layout, Size and every style tab) and the panel of "All Groups" are gone since session 20 (user):
  // every group decides on its own. The note on moving the bar (MOVE_HINT) went with that panel.

  return { COL_R, COL_RS, choiceButton };
}

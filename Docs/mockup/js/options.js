"use strict";
/* RaidKit Buffs mockup: createContent: tabs, pages, parts of the page "Bars" (= Options.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

function createContent() {
  // Navigation as tabs at the top (proposal 2026-11-14, user; before 2026-11-09 a list of pages on the left): the pages
  // get the full width. Right of the tabs: the current profile, so a change is visible on every page (click = page).
  placeTarget = null;
  C.navItems = OPT_PAGES.map((pg, i) => {
    const it = Place(Button(pg.label, 110, () => showPage(pg.key)), 10 + i * 114, 10);
    it.classList.add("tab", "navtab");
    it.dataset.key = pg.key;
    return it;
  });
  const navLine = Place(mk("div", "navline"), 0, 34); navLine.style.width = CONTENT_W + "px";
  // the profile text right of the tabs (2026-11-14 to 2026-11-20, C.navProf) is gone (user): the own settings are always
  // stored for the character, the page "Profiles" shows the name
  // demo (2026-11-10) in the tab line since 2026-11-15 (user; before in the right column of "All Groups"): right, just
  // left of the profile name (placeDemoButtons), on every page. "+" = more fake buffs (before "Add buffs").
  C.demoBtn = Place(Button("", 150, () => toggleDemo()), 0, 10); C.demoBtn.classList.add("navdemo");
  C.demoAddBtn = Place(Button("+", 22, (e) => { if (!C.demoAddBtn.classList.contains("dis")) demoAddBuffs(e && e.shiftKey ? 5 : 1); }), 0, 10);
  C.demoAddBtn.classList.add("navdemo");
  withTip(C.demoAddBtn, () => `<div class="w">${L("Add buffs")}</div><div class="d">${L("Only during the demo: click = 1 buff, Shift+click = 5 buffs more, until the cap is full. Random every time: an icon of your rows (elixir, potion, food, world buff ...), an unwanted buff (e.g. polymorph) or another buff. This way you can check the color of the bar (from 4 free slots yellow, then orange, at 1 red).")}</div>`);
  withTip(C.demoBtn, () => `<div class="w">Demo</div><div class="d">${L("For one minute: 5 to 20 icons of your rows look active, other buffs (HoTs, procs, trinkets), your unwanted buffs (the red button removes them) and a few debuffs come and go. None of it is real; meanwhile real buffs cannot be removed with a right-click. Only starts out of combat. Click again or close the window to end it.")}</div>`);

  /* ----- Page "Reihen": rows, items, catalog, unwanted, use mode ----- */
  Page("rows", ROWS_DY);
  createRowsColumn();
  createCatalogColumn();
  const ctx = createBarsPanel();
  createRowStack(); // rows of a group on its Layout tab (2026-11-16, options-row-stack.js)
  createStyleTabs(ctx);
  createProfilesPage(ctx.choiceButton);
  createInfoPage(); // third tab (2026-11-20, user; options-info.js)

  placeTarget = null;
  showPage(optPage);
}

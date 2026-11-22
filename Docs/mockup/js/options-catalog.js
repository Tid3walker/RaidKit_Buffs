"use strict";
/* RaidKit Buffs mockup: catalog: filter, sort, its column in the options (= OptionsCatalog.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ----- Catalog ----- */
// = CurrentList() in Options.lua: active entry of CATALOG_LISTS
// = PlacesOf in OptionsCatalog.lua (2026-11-16, user): names of the groups whose rows hold id, in group order, then
// "Unwanted Buffs" when id is on the unwanted list; groups = how many of the names are groups
function placesOf(id, unwanted) {
  const inGroup = new Set(activeRows().filter((r) => !r.unwanted && rowIndexOf(r, id) >= 0).map((r) => r.group || "main"));
  const names = profile.groups.filter((g) => inGroup.has(g.id)).map(groupName), groups = names.length;
  if (unwanted) { const ug = profile.groups.find((g) => g.area === "unw"); names.push(ug ? groupName(ug) : L("Unwanted Buffs")); }
  return { names, groups };
}
function currentList() {
  return CATALOG_LISTS.find((l) => l.key === catList) || CATALOG_LISTS[1];
}
// = FilteredCatalog() in Options.lua: active tab, category, class and search text
function filteredCatalog() {
  if (catTab === "buff") return filteredBuffs();
  const f = FILTERS[filterIndex], s = catSearch.toLowerCase(), cur = currentList(), hide = (cur.cls && CLASS_HIDE[cur.cls]) || new Set();
  const list = CATALOG.filter((e) => (!cur.raid || RAID_ITEMS.has(e.id)) && !hide.has(e.primary) && f.match(e) &&
    (!s || e.name.toLowerCase().includes(s) || L(e.note || "").toLowerCase().includes(s)));
  sortByName(list); // like OptionsCatalog.lua: alphabetical by culture
  return withHeaders(list);
}
// = SortByName in OptionsCatalog.lua (2026-11-20, user): A-Z by the culture of the page language (ä = a, é = e ...),
// equal names by ID
function sortByName(list) {
  list.sort((a, b) => a.name.localeCompare(b.name, LANG, { sensitivity: "base" }) || a.id - b.id);
}
// "Buffs" tab (proposal): sections per category; buffs of the other faction are not shown at all, buffs
// useless for the class come last under "Unpassend für <class>" (e.g. to drag them into "Unerwünscht")
function filteredBuffs() {
  const f = BUFF_FILTERS[buffFilterIndex], s = catSearch.toLowerCase();
  const list = BUFFS.filter((b) => buffFits(b) && (!f.cat || b.cat === f.cat) &&
    (!s || b.name.toLowerCase().includes(s) || L(b.note || "").toLowerCase().includes(s)));
  sortByName(list);
  // per category: the entries without sub, then each part of g.subs (2026-11-20, user: auras before totems, long buffs
  // before cooldowns); out.subTop = first entries of a later part, drawn with a faint line above (= subTop in Lua)
  const out = [];
  out.subTop = new Set();
  for (const g of BUFF_FILTERS) {
    if (!g.cat) continue;
    const head = out.length;
    for (const sub of [undefined, ...(g.subs || [])]) {
      const part = list.filter((b) => b.cat === g.cat && b.sub === sub && buffForClass(b));
      if (!part.length) continue;
      if (out.length === head) out.push({ header: g.label }); else out.subTop.add(part[0]);
      out.push(...part);
    }
  }
  const unfit = list.filter((b) => !buffForClass(b));
  if (unfit.length) out.push({ header: fmt(L("Unsuitable for %s"), CLASS_NAMES[playerClass]) }, ...unfit);
  return out;
}
// = CurrentSort() in Options.lua
function currentSort() {
  return CATALOG_SORTS.find((s) => s.key === db.catSort) || CATALOG_SORTS.find((s) => s.key === "type");
}
// = WithHeaders() in Options.lua: "Typ"/"Werte" split the A-Z list into sections ({ header } lines),
// in the order of FILTERS; empty sections are left out.
function withHeaders(list) {
  const sort = currentSort();
  if (!sort.group) return list;
  const out = [];
  for (const f of FILTERS) {
    if (f.group !== sort.group || !(f.cat || f.stats)) continue;
    const part = list.filter((e) => (f.cat ? e.cat === f.cat : f.stats.includes(e.primary)));
    if (part.length) out.push({ header: f.label }, ...part);
  }
  return out;
}


// = LinkOf in OptionsCatalog.lua (user 2026-11-20): a trinket shows the icon of its buff (b.aura), a proc what triggers
// it (b.src, class = only that class); { label, list: [{ icon, name }], mark: icon behind the name or null } or null
function buffLink(b) {
  if (!b || !b.isBuff) return null;
  if (b.aura) return { label: L("Buff:"), list: [{ icon: b.aura.icon, name: b.aura.name }], mark: b.aura.icon };
  if (!b.src) return null;
  const list = b.src.filter((s) => !s.class || s.class === playerClass);
  if (!list.length) return null;
  const m = list.find((s) => s.icon !== b.icon);
  return { label: L("Triggered by:"), list, mark: m ? m.icon : null };
}
// catalog column of the page "Bars" (part of createContent)
function createCatalogColumn() {
  // Catalog (its elements get the class "catpanel": hidden while "Alle Gruppen" uses the right column, session 4d)
  const catStart = placeTarget.children.length;
  // proposal 2026-11-09: two tabs instead of the header "Katalog"; selecting a row switches to its tab
  const closeMenus = () => { for (const m of [C.addMenu, C.groupAddMenu, C.menu, C.listMenu, C.sortMenu, C.buffMenu]) if (m) m.style.display = "none"; };
  const tab = (text, w, x, key) => {
    const b = Place(Button(text, w, () => { closeMenus(); catTab = key; catOffset = 0; refreshOptions(); }), x, 66);
    b.classList.add("tiny", "tab");
    return b;
  };
  // each half of the 234 px line (2026-11-14, user; = Options.lua, before 84 + 50 px)
  C.tabConsume = tab("Consumables", 116, CAT_X, "consume");
  C.tabBuff = tab("Buffs", 116, CAT_X + 118, "buff");
  // = CreateSortMenu in Options.lua: sort (A-Z / Type / Stats), saved; only consumables. Own line below the tabs, as
  // wide as "List" since 2026-11-14 (user: right of the tabs it was far too small in other languages)
  C.sortBtn = Place(Button("", 234, () => { C.addMenu.style.display = "none"; C.menu.style.display = "none"; C.listMenu.style.display = "none"; C.sortMenu.style.display = C.sortMenu.style.display === "block" ? "none" : "block"; }), CAT_X, 88);
  C.sortMenu = Place(mk("div", "menu listmenu"), CAT_X, 112);
  C.sortItems = CATALOG_SORTS.map((s) => {
    const it = mk("div", "it", s.label);
    it.addEventListener("click", () => { db.catSort = s.key; catOffset = 0; C.sortMenu.style.display = "none"; refreshOptions(); });
    C.sortMenu.appendChild(it);
    return it;
  });
  C.filterBtn = Place(Button("", 234, () => { C.addMenu.style.display = "none"; C.listMenu.style.display = "none"; C.sortMenu.style.display = "none"; C.menu.style.display = C.menu.style.display === "block" ? "none" : "block"; }), CAT_X, 138); // below "List", like Options.lua (113 until 2026-11-14)
  C.menu = Place(mk("div", "menu"), CAT_X - 98, 162);
  const cols = { type: mk("div", "col"), stat: mk("div", "col") };
  cols.type.appendChild(mk("div", "h", L("Type"))); cols.stat.appendChild(mk("div", "h", L("Stats")));
  C.menuItems = FILTERS.map((f, i) => {
    const it = mk("div", "it", f.label);
    it.addEventListener("click", () => { filterIndex = i; catOffset = 0; C.menu.style.display = "none"; refreshOptions(); });
    cols[f.group].appendChild(it);
    return it;
  });
  C.menu.append(cols.type, cols.stat);
  // = CreateListMenu in Options.lua: one dropdown "Liste" (Alle / Raid / Raid: <class>)
  C.listBtn = Place(Button("", 234, () => { C.addMenu.style.display = "none"; C.menu.style.display = "none"; C.sortMenu.style.display = "none"; C.listMenu.style.display = C.listMenu.style.display === "block" ? "none" : "block"; }), CAT_X, 113); // 88 until 2026-11-14
  C.listMenu = Place(mk("div", "menu listmenu"), CAT_X, 137);
  C.listItems = CATALOG_LISTS.map((l, i) => {
    const it = mk("div", "it", l.label);
    if (l.cls && !CATALOG_LISTS[i - 1].cls) it.style.marginTop = "6px";
    it.addEventListener("click", () => { catList = l.key; catOffset = 0; C.listMenu.style.display = "none"; refreshOptions(); });
    C.listMenu.appendChild(it);
    return it;
  });
  // "Buffs" tab: category in place of "Liste" (slider "Proc-Reserve" removed 2026-11-10: fixed steps, see CAP_LEVELS)
  C.buffFilterBtn = Place(Button("", 234, () => { const open = C.buffMenu.style.display === "block"; closeMenus(); C.buffMenu.style.display = open ? "none" : "block"; }), CAT_X, 88);
  C.buffMenu = Place(mk("div", "menu listmenu"), CAT_X, 112);
  C.buffMenuItems = BUFF_FILTERS.map((f, i) => {
    const it = mk("div", "it", f.label);
    it.addEventListener("click", () => { buffFilterIndex = i; catOffset = 0; C.buffMenu.style.display = "none"; refreshOptions(); });
    C.buffMenu.appendChild(it);
    return it;
  });

  C.catList = Place(mk("div", "catlist"), CAT_X, 165); // 140 until 2026-11-14 C.catList.style.height = (CAT_LINES * CAT_LINE_H) + "px";
  C.catList.addEventListener("wheel", (e) => { e.preventDefault(); catOffset += Math.sign(e.deltaY) * 3; refreshOptions(); }, { passive: false });
  C.catLines = [];
  for (let i = 0; i < CAT_LINES; i++) {
    const line = mk("div", "catline");
    line.innerHTML = `<div class="ic"></div><div class="nm"></div><div class="am"></div><div class="sp"></div><div class="ck"></div>`;
    line.addEventListener("mousedown", (e) => { if (line.entry) startPending(e, line.entry.id, "catalog"); });
    line.addEventListener("click", () => {
      if (!line.entry || justDragged) return;
      // since 2026-11-16 the rows are on the Layout tab of their group: in the group = removed from its row, else added
      // to the active row (gold line); "All Groups", Other and Debuffs take nothing
      const g = curGroup(), row = curRow();
      if (!row || styleTab !== "layout" && !(g && g.area === "unw")) return print(L("Select a group with rows (tab Layout) first."));
      const has = row.unwanted ? row : groupRowOf(g, line.entry.id);
      if (has) { const i = rowIndexOf(has, line.entry.id); spliceItem(has, i); changed(); } else insertItem(line.entry.id);
    });
    line.addEventListener("mousemove", (ev) => {
      const e = line.entry; if (!e || drag) return;
      // on the check: which groups hold the icon (= line.checkHit in OptionsCatalog.lua)
      const pl = line._places;
      if (ev.target.classList.contains("ck") && pl && pl.names.length) {
        tip.innerHTML = `<div class="n" style="font-size:12px">${L("Used in:")}</div>` + pl.names.map((n, i) =>
          `<div style="color:${i < pl.groups ? "#fff" : "#ff4d4d"}">${n}</div>`).join("");
        return placeTip(ev);
      }
      const alts = line._alts; // default alternatives as a list with icons (user 2026-11-10)
      tip.innerHTML = `<div class="n">${e.name}</div><div class="d">${e.isBuff ? "(Buff-Tooltip)" : "(Item-Tooltip)"}</div><br><div class="b">${e.note ? L(e.note) : ""}</div>
        ${alts && alts.length ? `<br><div class="n" style="font-size:12px">${L("Alternatives:")}</div>` + alts.map((id) =>
          `<div><span style="display:inline-block;width:14px;height:14px;vertical-align:-3px;margin-right:4px;background:url(${ICON_URL(itemInfo(id).icon)}) center/cover"></span>${itemInfo(id).name}</div>`).join("") + "<br>" : ""}
        ${(() => { const k = buffLink(e); return k ? `<br><div class="n" style="font-size:12px">${k.label}</div>` + k.list.map((s) =>
          `<div><span style="display:inline-block;width:14px;height:14px;vertical-align:-3px;margin-right:4px;background:url(${ICON_URL(s.icon)}) center/cover"></span>${s.name}</div>`).join("") + "<br>" : ""; })()}
        <div class="d">${L("Drag into the row or click: add/remove")}</div>${e.isBuff ? `<div class="d">${L("Unwanted: select \"Unwanted Buffs\" in the row list, then add")}</div>` : ""}`;
      placeTip(ev);
    });
    line.addEventListener("mouseleave", hideTip);
    C.catList.appendChild(line);
    C.catLines.push(line);
  }
  // search field ends at 456 like the other columns (2026-11-11); starts right after its label (2026-11-14, user: the
  // label is longer in other languages; = GetStringWidth in Options.lua), always ends at CAT_X + 222
  C.searchLbl = Place(Label(L("Search:"), "small"), CAT_X, COL_BOTTOM - 15);
  C.catSearch = Place(EditBox(180), CAT_X + 42, COL_BOTTOM - 22);
  // measured in refreshOptions: the window is hidden while it is built (width 0 then)
  C.fitSearch = () => {
    const lw = C.searchLbl.scrollWidth; if (!lw) return;
    C.catSearch.style.left = (CAT_X + lw + 8) + "px"; C.catSearch.style.width = (222 - (lw + 8)) + "px";
  };
  C.catSearch.addEventListener("input", () => { catSearch = C.catSearch.value; catOffset = 0; refreshOptions(); });
  [...placeTarget.children].slice(catStart).forEach((el) => el.classList.add("catpanel"));
  // "Unerwünscht" (Buffs tab): buffs dragged in here show the red remove button below the bar while active

}

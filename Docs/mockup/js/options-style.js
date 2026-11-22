"use strict";
/* RaidKit Buffs mockup: style tabs Size / Separator / Frame / Icon borders and the "Show" button (= OptionsBars.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// style tabs of the middle column (part of createContent); ctx = helpers from createBarsPanel
function createStyleTabs({ COL_RS, choiceButton }) {
  /* ----- Style tabs (proposal 2026-11-14, user; mockup only): "Layout | Frame | Separator | Icon borders" in the
     heading line of the middle column, for "Alle Gruppen" and every group. Layout = everything that was there before.
     "Alle Gruppen" sets the default values. A group (second round 2026-11-14, user): first line "Visible" (the former
     checkboxes "Rahmen" / "Trenner anzeigen" / "Rahmen um die Icons" of Layout), every value comes from "Alle Gruppen"
     until it is changed at the group (then only that value is its own); "Like All Groups" drops the own values of the
     tab. Two columns (left x = GRID_X, right x = GRID_X + 250), same places for every group. */
  // two lines since 2026-11-15 (user): "Layout | Size | Separator" and "Background/Frame | Icon borders", three
  // columns of 160 px (+3 gap) = 486, so every label has room in every language (before 4 x 120 in one line, "Rahmen um
  // die Icons" did not fit). Same tabs and places for "All Groups" and every group.
  // one line again since 2026-11-16 (user): the tab "Size" is gone (its sliders are on Layout), "Layout" and
  // "Separator" narrower, the two long labels keep 160 px (90 + 110 + 160 + 160 + 3 x 3 = 529 of MID_W 550)
  const STABS = [{ key: "layout", label: L("Layout"), w: 90 }, { key: "sep", label: L("Separator"), w: 110 },
    { key: "frame", label: L("Background/Frame"), w: 160 }, { key: "icon", label: L("Icon borders"), w: 160 }];
  // own line below the heading since 2026-11-14 (user): the heading has the full width
  const closeAllMenus = () => { content.querySelectorAll(".menu").forEach((m) => { m.style.display = "none"; }); closeColorPicker(); };
  let stabX = GRID_X;
  C.styleTabs = STABS.map((t) => {
    const b = Place(Button(t.label, t.w, () => { closeAllMenus(); styleTab = t.key; refreshOptions(); }), stabX, 88);
    stabX += t.w + 3;
    b.classList.add("tiny", "tab", "stab"); b.dataset.key = t.key;
    return b;
  });
  // right column at COL_RS since 2026-11-17 (user: reset buttons on the style tabs too): its colour fields and sliders
  // end 16 px before the edge, their "↺" fills it (like "Per line" on Layout); before COL_R (flush with the edge)
  const SL = GRID_X, SR = COL_RS, SG = () => curGroup(); // always a group since session 20 (no "Alle Gruppen")
  const sGet = (sec, k) => () => styleOf(SG(), sec)[k];
  // shown per group = the stored flags as before (g.separator, g.showBorders; = Bar.lua). The frame has no checkbox
  // since 2026-11-15 (user): texture and border "None"; its values are always editable
  const VIS = {
    frame: { get: () => true },
    sep: { get: (g) => sepOn(g), set: (g, v) => { g.separator = v; } },
    icon: { get: (g) => g.showBorders === true, set: (g, v) => { if (v) g.showBorders = true; else delete g.showBorders; } },
  };
  // stores a value of the group; the default (STYLE_DEF) is not stored (no "Alle Gruppen" since session 20)
  const sStore = (holder, sec, k, v, parentV) => {
    if (v === parentV) { if (holder.style && holder.style[sec]) { delete holder.style[sec][k]; if (!Object.keys(holder.style[sec]).length) delete holder.style[sec]; if (!Object.keys(holder.style).length) delete holder.style; } return; }
    holder.style = holder.style || {}; (holder.style[sec] = holder.style[sec] || {})[k] = v;
  };
  const sSet = (sec, k) => (v) => {
    const g = SG(); if (!g) return; sStore(g, sec, k, v, STYLE_DEF[sec][k]);
    changed();
  };
  // values can be changed while the element is visible
  const sOn = (sec, extra) => () => !!SG() && VIS[sec].get(SG()) && (!extra || extra());
  const spanel = (sec, els) => { for (const el of els) el.classList.add("spanel", "sp-" + sec); return els; };
  const sHead = (sec, text, x, y) => { const h = Place(Label(text), x, y), s = Place(mk("div", "sep"), x, y + 20); s.style.width = "222px"; return spanel(sec, [h, s]); };
  // notes of a tab: below its controls, one below the other (flowLayout from C.styleNotes[sec].y)
  C.styleNotes = { frame: { y: TOP_Y + 118, els: [] }, sep: { y: TOP_Y + 118, els: [] }, icon: { y: TOP_Y + 62, els: [] } };
  const sNote = (sec, text, cls) => {
    const n = Place(Label(text, "note"), SL, TOP_Y); n.style.width = "480px"; n.style.whiteSpace = "normal";
    if (cls) n.classList.add(cls);
    C.styleNotes[sec].els.push(n);
    return spanel(sec, [n]);
  };
  // top line of the left column (2026-11-15, user): the checkbox that shows the element, with a line below (Separator,
  // Icon borders; the frame has "None" in its lists instead). "Like All Groups" and the heading of "Alle Gruppen" are
  // gone since session 20.
  const sTop = (sec, cbText, tipText) => {
    const cb = withTip(Place(CheckBox(cbText, () => !!SG() && VIS[sec].get(SG()), (v) => { const g = SG(); if (g) { VIS[sec].set(g, v); changed(); } }), SL, TOP_Y - 4),
      () => `<div class="w">${cbText}</div><div class="d">${tipText}</div>`);
    cb.classList.add("grppanel"); C.controls.push(cb);
    const s = Place(mk("div", "sep"), SL, TOP_Y + 20); s.style.width = "222px";
    spanel(sec, [cb, s]);
  };
  // reset button "↺" behind every colour field and slider of the style tabs (2026-11-17, user; = SReset in
  // OptionsBars.lua, looks like resetBtn on Layout): gold = the group has its own value (one of keys), click = back to
  // the default (STYLE_DEF); grey = the default. Child of its control, IB_DX right of its left edge, so it moves and
  // hides with it (the icon colours are stacked by layoutIconColours). show(style) -> text for the tooltip.
  const IB_DX = 224;
  const sReset = (el, sec, keys, show, top) => {
    const own = () => { const s = SG() && SG().style && SG().style[sec]; return !!s && keys.some((k) => s[k] != null); };
    const b = mk("div", "ibtn", "↺");
    Object.assign(b.style, { position: "absolute", left: IB_DX + "px", top: top + "px" });
    b.addEventListener("click", (e) => {
      e.stopPropagation(); if (!own()) return; hideTip();
      for (const k of keys) sStore(SG(), sec, k, STYLE_DEF[sec][k], STYLE_DEF[sec][k]);
      changed();
    });
    b.refresh = () => b.classList.toggle("dis", !own());
    withTip(b, () => (own()
      ? `<div class="w">${fmt(L("Changed: %s (default: %s)"), show(styleOf(SG(), sec)), show(STYLE_DEF[sec]))}</div><div class="d">${L("Click: back to the default value.")}</div>`
      : `<div class="w">${L("Default value")}</div>`));
    el.appendChild(b); C.controls.push(b);
    return el;
  };
  // tooltip texts: "#a0a0aa 50%" (colour with opacity), numbers like resetBtn
  const colourText = (key, alphaKey) => (st) => String(st[key]).toLowerCase() + (alphaKey ? ` ${Math.round(st[alphaKey] * 100)}%` : "");
  const numText = (key) => (st) => (Number.isInteger(st[key]) ? String(st[key]) : Number(st[key]).toFixed(2));
  // = ColorSwatch in Options.lua later: label + colour field, click opens the colour picker (= ColorPickerFrame with
  // opacity when alphaKey is given); with "↺" since 2026-11-17
  const swatch = (sec, text, key, alphaKey, x, y, extra) => {
    const w = Place(mk("div", "cswatch"), x, y);
    w.innerHTML = `<div class="t"></div><div class="box"><div class="fill"></div></div>`;
    w.querySelector(".t").textContent = text;
    const on = sOn(sec, extra);
    w.addEventListener("click", (e) => {
      e.stopPropagation(); if (!on()) return;
      const st = styleOf(SG(), sec);
      openColorPicker(w, { color: st[key], alpha: alphaKey ? st[alphaKey] : null, title: text,
        set: (c, a) => { sSet(sec, key)(c); if (alphaKey && a != null) sSet(sec, alphaKey)(a); } });
    });
    w.refresh = () => { const st = styleOf(SG(), sec); w.querySelector(".fill").style.background = hexA(st[key], alphaKey ? st[alphaKey] : 1); w.classList.toggle("dis", !on()); };
    C.controls.push(w);
    sReset(w, sec, alphaKey ? [key, alphaKey] : [key], colourText(key, alphaKey), 3);
    return spanel(sec, [w]);
  };
  const sSlider = (sec, text, key, step, min, max, x, y, f, extra) => {
    const s = Place(Slider(text, sGet(sec, key), sSet(sec, key), step, min, max, f, sOn(sec, extra)), x, y);
    C.controls.push(s);
    sReset(s, sec, [key], numText(key), 4);
    return spanel(sec, [s]);
  };
  // choice button; "↺" behind it since 2026-11-20 (user: texture, border style, separator look, fade ends; = SChoice in
  // OptionsBars.lua). The button clips its children and rewrites its text, so the ↺ sits on its own holder at the
  // same place (x, y) instead of inside it
  const sChoice = (sec, text, key, list, x, y, preview, extra) => {
    const b = choiceButton(x, y, list, null, text, 222, { get: sGet(sec, key), set: (v) => sSet(sec, key)(v), enabled: sOn(sec, extra), preview, menuWidth: 200 });
    C.controls.push(b);
    const hold = Place(mk("div", "ihold"), x, y);
    sReset(hold, sec, [key], (st) => { const e = list.find((o) => o.key === st[key]); return e ? e.label() : String(st[key]); }, 4);
    return spanel(sec, [b, b._menu, hold]);
  };
  // Frame: background left, border right. Not for "Unerwünschte Buffs" (own button frame). No checkbox since 2026-11-15
  // (user): texture "None" = no background, border "None" = no border; the frame shows with either (frameOn).
  // Since session 20 (user) without "Automatic": texture and style are the group's own values (default "None").
  const notUnw = () => !(SG() && SG().area === "unw");
  sHead("frame", L("Background"), SL, TOP_Y); sHead("frame", L("Border"), SR, TOP_Y);
  const texPrev = (k) => (k === "none" ? { background: "transparent", boxShadow: "inset 0 0 0 1px #555" } : frameCss(Object.assign(styleOf(SG(), "frame"), { bgTex: k, edge: "none" })));
  const edgePrev = (k) => Object.assign(frameCss(Object.assign(styleOf(SG(), "frame"), { edge: k, edgeSize: 1, bgAlpha: 0.9 })), { margin: "3px 10px 3px 4px" });
  sChoice("frame", L("Texture: "), "bgTex", BG_TEXTURES, SL, TOP_Y + 26, texPrev, notUnw);
  sChoice("frame", L("Style: "), "edge", EDGE_STYLES, SR, TOP_Y + 26, edgePrev, notUnw);
  // colours and thickness: while its part is not "None"
  const bgOn = () => notUnw() && styleOf(SG(), "frame").bgTex !== "none";
  const edgeOn = () => notUnw() && styleOf(SG(), "frame").edge !== "none";
  swatch("frame", L("Color and opacity"), "bgColor", "bgAlpha", SL, TOP_Y + 58, bgOn);
  swatch("frame", L("Color and opacity"), "edgeColor", "edgeAlpha", SR, TOP_Y + 58, edgeOn);
  sSlider("frame", L("Thickness"), "edgeSize", 1, 1, 8, SR, TOP_Y + 86, null, edgeOn);
  // only where it matters: "Unerwünschte Buffs" itself (2026-11-14)
  C.frameUnwNote = sNote("frame", L("\"Unwanted Buffs\" has its own button frame."))[0];
  // Separator: the checkbox instead of the heading "Line" (2026-11-15, user)
  sTop("sep", L("Show separator"), L("Thin line on the side where this group is docked. Only when it is snapped to another group."));
  sHead("sep", L("Size"), SR, TOP_Y);
  // samples in the menus: the look with the current fade, the fade with the current look
  const sepPrev = (look, fade) => {
    const st = styleOf(SG(), "sep"), c = hexA(st.color, Math.max(st.alpha, 0.8)), mask = sepFadeMask(fade, "90deg");
    return { width: "40px", height: "2px", verticalAlign: "middle", marginRight: "8px", maskImage: mask, webkitMaskImage: mask,
      background: look === "dashed" ? `repeating-linear-gradient(90deg, ${c} 0 6px, transparent 6px 10px)`
        : look === "dotted" ? `repeating-linear-gradient(90deg, ${c} 0 2px, transparent 2px 5px)` : c };
  };
  sChoice("sep", L("Look: "), "look", SEP_LOOKS, SL, TOP_Y + 26, (k) => sepPrev(k, styleOf(SG(), "sep").fade));
  // fading ends as its own choice (2026-11-15, user; before the look "Fading at the ends", solid only), in the line of
  // "Shorten" (both are about the ends)
  withTip(sChoice("sep", L("Fade ends: "), "fade", SEP_FADES, SL, TOP_Y + 52, (k) => sepPrev(styleOf(SG(), "sep").look, k))[0],
    () => `<div class="w">${L("Fade ends")}</div><div class="d">${L("The line fades out toward these ends over half of its length (both sides: from the middle), whatever its look. Lines beside a group: left = top, right = bottom.")}</div>`);
  swatch("sep", L("Color and opacity"), "color", "alpha", SL, TOP_Y + 84);
  sSlider("sep", L("Thickness"), "size", 1, 1, 6, SR, TOP_Y + 26);
  withTip(sSlider("sep", L("Shorten"), "inset", 1, 0, 60, SR, TOP_Y + 52)[0], () => `<div class="w">${L("Shorten")}</div><div class="d">${L("The line ends this many pixels before both ends of the group.")}</div>`);
  sNote("sep", L("Only shown when the group is snapped to another one."));
  // Icon borders: the checkbox instead of the heading "Size" (2026-11-15, user)
  sTop("icon", L("Show icon borders"), L("Without borders the colors are missing too (green active, red unwanted, debuff type). The red loss alarm still flashes."));
  const iconColHead = sHead("icon", L("Colors"), SR, TOP_Y);
  sSlider("icon", L("Thickness"), "size", 1, 1, 4, SL, TOP_Y + 26);
  // only the colours that occur in the selected group (2026-11-14, user): rows = active/missing, Unwanted = unwanted,
  // Other = other buffs, Debuffs = none (type colour).
  // Stacked from the top without gaps (refreshOptions -> C.layoutIconColours); the notes follow below
  const ICON_COLOURS = [
    { key: "active", text: L("Active"), where: L("Active (rows)"), on: (g) => !g.area },
    { key: "missing", text: L("Missing"), where: L("Missing (rows)"), on: (g) => !g.area },
    { key: "unwanted", text: L("Unwanted"), where: L("Unwanted (Unwanted Buffs)"), on: (g) => g.area === "unw" },
    { key: "other", text: L("Other buffs"), where: L("Other (Other Buffs)"), on: (g) => g.area === "other" },
  ].map((c) => Object.assign(c, { el: swatch("icon", c.text, c.key, null, SR, TOP_Y + 26)[0] }));
  C.layoutIconColours = () => {
    const g = curGroup();
    let y = TOP_Y + 26;
    for (const c of ICON_COLOURS) {
      const show = !!g && c.on(g);
      c.el.classList.toggle("retired", !show);
      c.el.querySelector(".t").textContent = c.text;
      if (show) { c.el.style.top = y + "px"; y += 24; }
    }
    for (const el of iconColHead) el.classList.toggle("retired", y === TOP_Y + 26); // Debuffs: no colours, no heading
    C.styleNotes.icon.y = Math.max(TOP_Y + 48, y - 4) + 14; // below the thickness and the last colour
  };
  sNote("icon", L("Debuffs keep the color of their type, a lost consumable still flashes red."));
  // the tab "Size" (2026-11-15) is gone since 2026-11-16 (user): its five sliders are on Layout (createBarsPanel)

  // colour picker (= ColorPickerFrame: colour, opacity, OK / Cancel; changes show at once, Cancel restores)
  C.cpick = Place(mk("div", "cpick"), 0, 0); C.cpick.style.display = "none";
  C.cpick.addEventListener("click", (e) => e.stopPropagation());
  content.addEventListener("click", () => closeColorPicker());

  // where the bar is shown (= replaces the Blizzard buff bar there); explanation only in the tooltip. In the tab line
  // left of the demo since 2026-11-15 (user; placed by refreshOptions). Created here because choiceButton lives in
  // createContent; it is moved out of the page into the content so it shows on every page.
  C.showBtn = choiceButton(0, 0, SHOW_MODES, "showMode", L("Show: "), 180);
  withTip(C.showBtn, () => `<div class="w">${L("Show")}</div><div class="d">${L("Where RaidKit Buffs replaces the Blizzard buff bar (buffs and debuffs). Never: always the Blizzard bar. Party: only in a party without a raid. While the options window is open the bar is always shown.")}</div>`);
  for (const el of [C.showBtn, C.showBtn._menu]) content.appendChild(el);
  C.showBtn.classList.add("navdemo"); C.showBtn._menu.style.zIndex = 7;
  C.showBtn._menu.style.top = "34px"; C.showBtn.style.top = "10px";
}

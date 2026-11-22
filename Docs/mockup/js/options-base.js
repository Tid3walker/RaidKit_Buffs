"use strict";
/* RaidKit Buffs mockup: pages, Place(), widgets (= OptionsBase.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Options (Options.lua) ===================== */
const content = document.createElement("div");
content.className = "content";
content.style.width = CONTENT_W + "px"; content.style.height = CONTENT_H + "px"; // from the constants (core.js), not fixed in the CSS
const C = {};

// Place() puts widgets on the page that is currently being built (placeTarget), coordinates relative to that page
let placeTarget = null, optPage = "rows";
const pages = {};
function Place(el, x, y) { el.classList.add("a"); el.style.left = x + "px"; el.style.top = y + "px"; (placeTarget || content).appendChild(el); return el; }
// dy: the page "Reihen" keeps its old coordinates (profile area used to be above it) and is moved up as a whole
function Page(key, dy) {
  const p = mk("div", "page a"); p.style.left = PAGE_X + "px"; p.style.top = (TAB_H + (dy || 0)) + "px"; p.style.width = PAGE_W + "px"; // below the tabs (2026-11-14)
  content.appendChild(p); pages[key] = p; placeTarget = p;
  return p;
}
function showPage(key) {
  optPage = key;
  content.querySelectorAll(".menu").forEach((m) => { m.style.display = "none"; });
  for (const k in pages) pages[k].style.display = k === key ? "" : "none";
  C.navItems.forEach((it) => it.classList.toggle("on", it.dataset.key === key));
  if (key === "info") alignInfoColumns(); // needs the shown page (options-info.js)
  hideTip();
}
function mk(tag, cls, text) { const e = document.createElement(tag); if (cls) e.className = cls; if (text !== undefined) e.textContent = text; return e; }
function Button(text, width, onClick) {
  const b = mk("div", "wbtn", text);
  b.style.width = (width || 80) + "px";
  b.addEventListener("click", onClick);
  return b;
}
function Label(text, cls) { return mk("div", "lbl " + (cls || ""), text); }
function EditBox(width, onEnter) {
  const e = mk("input", "wedit"); e.style.width = width + "px";
  e.addEventListener("keydown", (ev) => { if (ev.key === "Enter") { if (onEnter) onEnter(e); e.blur(); } if (ev.key === "Escape") e.blur(); });
  return e;
}
function CheckBox(text, get, set, enabled) {
  const c = mk("div", "cbx");
  c.innerHTML = `<div class="box"></div><div class="t"></div>`;
  c.querySelector(".t").textContent = text;
  const on = () => !enabled || enabled();
  c.addEventListener("click", () => { if (on()) set(!get()); });
  c.refresh = () => { c.classList.toggle("on", !!get()); c.classList.toggle("dis", !on()); };
  return c;
}
// = Slider() in Options.lua: "Label  value  [-] ===o=== [+]", 230 px wide.
// enabled (optional): function; when it returns false the control is grey and does nothing.
function Slider(text, get, set, step, min, max, fmt, enabled) {
  const f = mk("div", "wslider");
  const l = Label(text, "hl"); l.classList.add("sl-l");
  const v = Label(""); v.classList.add("sl-v");
  const r = mk("input", "sl-r"); r.type = "range"; r.min = min; r.max = max; r.step = step;
  const on = () => !enabled || enabled();
  const show = (x) => { x = x === undefined ? get() : x; v.textContent = fmt ? fmt(x) : String(x); r.value = x; };
  const apply = (x) => {
    if (!on()) return;
    x = Math.max(min, Math.min(max, Math.round(x / step) * step)); x = +x.toFixed(2);
    show(x); set(x);
  };
  r.addEventListener("input", () => apply(+r.value));
  const minus = Button("-", 18, () => apply(get() - step)); minus.classList.add("tiny", "sl-m");
  const plus = Button("+", 18, () => apply(get() + step)); plus.classList.add("tiny", "sl-p");
  f.append(l, v, minus, r, plus);
  f.refresh = () => { f.classList.toggle("dis", !on()); r.disabled = !on(); show(); };
  return f;
}

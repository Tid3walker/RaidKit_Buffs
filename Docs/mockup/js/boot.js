"use strict";
/* RaidKit Buffs mockup: start. Loads the language table (locale.js), then the scripts below one after the other.
   They are classic scripts (no modules): top-level const/let/function are shared between them like in one file, so
   the order matters for code that runs while loading (data tables call L(), page.js starts the mockup). Same order
   idea as RaidKit_Buffs.toc. Paths relative to the page. */
const MOCKUP_SCRIPTS = [
  "js/data.js",
  "js/demo.js",
  "js/core.js",
  "js/bar-base.js",
  "js/bar-groups.js",
  "js/bar-split.js",
  "js/bar-move.js",
  "js/bar-areas.js",
  "js/tooltip.js",
  "js/options-base.js",
  "js/options-model.js",
  "js/options-drag.js",
  "js/options-catalog.js",
  "js/options-rows.js",
  "js/options-bars.js",
  "js/options-split.js",
  "js/options-row-stack.js",
  "js/options-style.js",
  "js/options-profiles.js",
  "js/options-info.js",
  "js/options-refresh.js",
  "js/options.js",
  "js/loss-report.js",
  "js/page.js",
];
function loadScript(src) {
  return new Promise((resolve, reject) => {
    const s = document.createElement("script");
    s.src = src;
    s.onload = resolve;
    s.onerror = () => reject(new Error("could not load " + src));
    document.body.appendChild(s);
  });
}
// the scripts run only after the language table is there (their data tables call L() while they are defined, like
// the Lua files at load time)
(async () => {
  await loadLocale();
  // the main script (and the rest of the page) is parsed after this script
  if (document.readyState === "loading") await new Promise((res) => document.addEventListener("DOMContentLoaded", res, { once: true }));
  localizeStatic();
  setupPageLang();
  setupPageHelp();
  for (const src of MOCKUP_SCRIPTS) await loadScript(src);
})();

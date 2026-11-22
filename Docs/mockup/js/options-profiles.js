"use strict";
/* RaidKit Buffs mockup: profiles, dialogs, profile list, demo button (= Profiles.lua, OptionsProfiles.lua).
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

/* ===================== Profiles (proposal) ===================== */
// Character keys: position of the bar. Never saved into / loaded from a profile.
// orientation and otherDock depend on where the bar sits on the screen, so they belong to the character too (proposal)
const POS_KEYS = ["point", "orientation", "otherDock", "groupPos"]; // groupPos: proposal 2026-11-11 (groups)
// "Reihen" part of a profile; everything else (sizes, names, use mode ...) is "Darstellung"
const ROW_KEYS = ["rows", "buffOverrides", "unwanted", "groups"]; // groups belong to the rows (2026-11-11)
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
const charState = () => db.chars[CHAR];
const savedNames = () => Object.keys(db.profiles).sort((a, b) => a.localeCompare(b));
function profileData(p) { const d = clone(p); for (const k of POS_KEYS) delete d[k]; return d; }
// Profiles are fixed copies (user 2026-11-20, "a"): the own settings are always stored for the character, a profile
// changes only by "Save" / "Save as ...". Gone: the automatic profile per character (2026-11-09 to 2026-11-20, Lua
// schema 10 deleted them) and the self-saving "own profile" ("Weg 2", 2026-11-20, charState().own).
function isModified() {
  const b = charState().base, s = b && db.profiles[b];
  return !!s && JSON.stringify(profileData(profile)) !== JSON.stringify(s.data);
}
const today = () => new Date().toLocaleDateString("de-DE", { day: "2-digit", month: "2-digit", year: "numeric" });
function storeProfile(name, data, cls) { db.profiles[name] = { class: cls || playerClass, saved: today(), data }; }
function saveProfileAs(name) {
  storeProfile(name, profileData(profile));
  charState().base = name;
  print(fmt(L("Profile '%s' saved."), name)); refreshOptions();
}
function saveOver(name) {
  popup(fmt(L("Overwrite profile \"%s\" with the current settings?"), name), {
    buttons: [{ text: L("Overwrite"), fn: () => saveProfileAs(name) }, { text: L("Cancel") }] });
}
function askSaveAs() {
  popup(L("Name for the profile:"), {
    edit: charState().base || CHAR.split(" - ")[0], // nothing saved yet: the character's name
    buttons: [{ text: L("Save"), fn: (v) => {
      const name = v.trim();
      if (!name) { print(L("Please enter a profile name.")); return false; }
      if (db.profiles[name]) { saveOver(name); return; }
      saveProfileAs(name);
    } }, { text: L("Cancel") }] });
}
// copies a saved profile into the own settings: everything except the position (session 20, user; before rows and/or
// appearance by choice: the appearance lived in "Alle Gruppen", now the groups carry it with them)
function loadProfile(name) {
  const data = db.profiles[name].data;
  for (const k of Object.keys(data)) if (!POS_KEYS.includes(k)) profile[k] = clone(data[k]);
  charState().base = name; selectedRow = 0;
  print(fmt(L("Profile '%s' loaded (%s). Position unchanged."), name, L("Rows + Appearance")));
  refreshOptions(); requestRebuild();
}
function resetToClassDefault() {
  const fresh = newProfile();
  for (const k of Object.keys(fresh)) if (!POS_KEYS.includes(k)) profile[k] = fresh[k];
  charState().base = null; selectedRow = 0; // the top shows "Own"
  print(fmt(L("Own settings reset to default (%s). Position unchanged."), CLASS_NAMES[playerClass]));
  refreshOptions(); requestRebuild();
}
// export string: in game later a real serializer (e.g. LibSerialize + LibDeflate); mockup: JSON + base64
const EXPORT_PREFIX = "!RKB1!";
function exportString(name) {
  const p = db.profiles[name];
  return EXPORT_PREFIX + btoa(unescape(encodeURIComponent(JSON.stringify({ name, class: p.class, data: p.data }))));
}
function parseExport(s) {
  s = (s || "").trim();
  if (!s.startsWith(EXPORT_PREFIX)) return null;
  try { const o = JSON.parse(decodeURIComponent(escape(atob(s.slice(EXPORT_PREFIX.length))))); return o && o.data && Array.isArray(o.data.rows) ? o : null; }
  catch (e) { return null; }
}
function profileSummary(name) {
  const p = db.profiles[name], rows = p.data.rows || [];
  const items = rows.reduce((n, r) => n + r.items.length, 0), vis = rows.filter((r) => !r.hidden).length;
  return { p, rows: rows.length, vis, items };
}

function withTip(el, html) {
  el.addEventListener("mousemove", (e) => { if (el.classList.contains("dis") && el.classList.contains("wbtn") && el !== C.profLoad && el !== C.profSave) return; tip.innerHTML = html(); tip.style.display = "block"; placeTip(e); });
  el.addEventListener("mouseleave", hideTip);
  return el;
}

/* ----- Dialogs: StaticPopup-like popups (flow layout); loading and managing profiles happen on the page "Profile" ----- */
const dialogs = [];
function openShade() {
  const shade = mk("div", "dlg-shade"); content.appendChild(shade);
  return shade;
}
function closeTopDialog() {
  const d = dialogs.pop(); if (!d) return;
  d.shade.remove(); d.el.remove(); hideTip();
  if (d.onClose) d.onClose();
}
window.addEventListener("keydown", (e) => { if (e.key === "Escape" && dialogs.length && !(e.target.tagName === "INPUT" && e.target.closest(".dlg") == null)) closeTopDialog(); });

// = StaticPopup_Show: text, optional edit box / multi-line box, up to 2 buttons
function popup(text, opts) {
  const shade = openShade();
  const el = mk("div", "dlg popup"); el.style.width = (opts.wide ? 420 : 320) + "px";
  el.appendChild(mk("div", "ptext", text));
  let input = null;
  if (opts.edit !== undefined) { input = mk("input", "wedit"); input.value = opts.edit; input.style.width = "220px"; el.appendChild(input); }
  if (opts.text !== undefined) {
    input = mk("textarea", "wtext"); input.value = opts.text; input.readOnly = !!opts.readOnly; input.spellcheck = false;
    el.appendChild(input);
  }
  if (opts.note) el.appendChild(mk("div", "pnote", opts.note));
  const bar = mk("div", "pbtns");
  const d = { shade, el };
  (opts.buttons || [{ text: "OK" }]).forEach((b, i) => {
    const btn = Button(b.text, 110, () => {
      if (b.fn && b.fn(input ? input.value : undefined, d) === false) return;
      if (dialogs.includes(d)) { dialogs.splice(dialogs.indexOf(d), 1); shade.remove(); el.remove(); }
    });
    bar.appendChild(btn);
    if (i === 0 && input && !input.readOnly) input.addEventListener("keydown", (ev) => { if (ev.key === "Enter" && input.tagName === "INPUT") btn.click(); });
  });
  el.appendChild(bar);
  content.appendChild(el);
  el.style.left = Math.round((CONTENT_W - el.offsetWidth) / 2) + "px";
  el.style.top = Math.round((CONTENT_H - el.offsetHeight) / 2 - 40) + "px";
  dialogs.push(d);
  if (input) { input.focus(); input.select(); }
  return d;
}


// Page "Profile" (proposal 2026-11-09): list, info, load and manage on the page itself, no extra frames.
// Selection and "Übernehmen" choice live for the session only.
const PROF_LINES = 13;
let profSel = null;
// list of saved profiles: lines of 20 px (scrolls with the wheel), click = select, double-click = load
function ProfileList(x, y, width, lines, getSel, onSel, onDouble) {
  const box = Place(mk("div", "plist"), x, y); box.style.width = width + "px"; box.style.height = (lines * 20) + "px";
  let offset = 0;
  box.addEventListener("wheel", (e) => { e.preventDefault(); offset = Math.max(0, Math.min(savedNames().length - lines, offset + Math.sign(e.deltaY))); box.refresh(); });
  box.refresh = () => {
    box.innerHTML = "";
    const names = savedNames();
    offset = Math.max(0, Math.min(offset, names.length - lines));
    if (!names.length) { box.appendChild(mk("div", "pempty", L("No profiles saved yet.\n\"Save as ...\" creates one."))); return; }
    names.slice(offset, offset + lines).forEach((n) => {
      const l = mk("div", "pline" + (n === getSel() ? " sel" : ""));
      l.appendChild(mk("span", "nm", n));
      // "loaded" only while the settings equal it, like the name at the top (2026-11-20); no "own" any more
      if (n === charState().base && !isModified()) l.appendChild(mk("span", "cur", L("loaded")));
      l.appendChild(mk("span", "cls", CLASS_NAMES[db.profiles[n].class] || db.profiles[n].class));
      l.addEventListener("click", () => onSel(n));
      if (onDouble) l.addEventListener("dblclick", () => onDouble(n));
      box.appendChild(l);
    });
  };
  return box;
}
function doLoadSelected() {
  if (!profSel) return;
  const name = profSel;
  if (isModified() || !charState().base) {
    popup(fmt(L("Your own settings are not saved as a profile.\nLoad \"%s\" anyway?"), name), {
      buttons: [{ text: L("Load"), fn: () => loadProfile(name) }, { text: L("Cancel") }] });
  } else loadProfile(name);
}
function refreshProfilesPage() {
  const names = savedNames();
  if (!names.includes(profSel)) profSel = names.includes(charState().base) ? charState().base : (names[0] || null);
  C.profList.refresh();
  C.profNeedSel.forEach((b) => b.classList.toggle("dis", !profSel));
  C.profLoad.classList.toggle("dis", !profSel);
  C.profSave.classList.toggle("dis", !profSel); // overwrites the selected profile, any time (user 2026-11-20)
  if (!profSel) { C.profInfo.innerHTML = `<div class="d">${L("No profile selected.")}</div>`; return; }
  const s = profileSummary(profSel);
  C.profInfo.innerHTML = `<div class="n">${esc(profSel)}</div>`
    + `<div class="d">${CLASS_NAMES[s.p.class] || s.p.class} · ${fmt(L("saved %s"), s.p.saved)}</div>`
    + `<div>${fmt(L("%s rows (%s visible), %s items"), s.rows, s.vis, s.items)}</div>`
    + `<div>${fmt(L("Use: %s"), USE_MODE_LABEL[s.p.data.useMode])}</div>`
    + (s.p.class !== playerClass ? `<div class="warn">${fmt(L("Profile for %s - the rows may not suit your class."), CLASS_NAMES[s.p.class] || s.p.class)}</div>` : "");
}

// mockup only: a few saved profiles to try loading / managing
function addExampleProfiles() {
  const base = profileData(newProfile());
  const raid = clone(base); raid.rows.forEach((r) => { if (r.name === L("Combat")) delete r.hidden; });
  const tank = clone(base); tank.rows.forEach((r) => { r.hidden = !(r.name === L("Tank") || r.name === L("Protection")) || undefined; if (!r.hidden) delete r.hidden; });
  tank.iconSize = 36; tank.useMode = "off";
  const mage = clone(base); mage.useMode = "ctrl";
  mage.rows = [{ name: "Raid", items: [13512, 13454, 20007, 9264, 21546, 13931] }, { name: L("Food & Co"), items: [21023, 13810] }];
  storeProfile(P("Raid Warrior"), raid, "WARRIOR");
  storeProfile("Tank MC", tank, "WARRIOR");
  storeProfile(P("Mage BWL (guild)"), mage, "MAGE");
  print(fmt(P("Example profiles created: %s."), [P("Raid Warrior"), "Tank MC", P("Mage BWL (guild)")].join(", ")));
  refreshOptions();
}

// = ns:UpdateDemoButton() in Options.lua: text with the time left, updated every second by the demo
function updateDemoButton() {
  if (!C.demoBtn) return;
  const left = demoLeft();
  C.demoBtn.textContent = left != null ? fmt(L("Stop demo (%d:%02d)"), Math.floor(left / 60), left % 60) : L("Start demo (1 min.)");
  if (C.demoAddBtn) C.demoAddBtn.classList.toggle("dis", left == null || demoFree() <= 0);
}

// page "Profiles" and the language button (part of createContent); choiceButton from createBarsPanel
function createProfilesPage(choiceButton) {
  /* ----- Page "Profile" ----- */
  // Profile (proposal 2026-11-08): the character always edits its OWN settings.
  // Saved profiles are named copies; loading copies them in, nothing switches automatically.
  /* ----- Language (2026-11-14, user; = CreateLanguageButton in OptionsProfiles.lua): for the whole addon. Since
     2026-11-15 (user) at the left end of the bottom line of "Bars" (before its own page "Common"); the menu opens
     upwards. In the game: RaidKitBuffsDB.language (nil = client) and /reload. Here: the URL parameter lang (none =
     automatic, the simulated client is English) and a page reload. ----- */
  const langParam = new URLSearchParams(location.search).get("lang");
  const LANGS = [{ key: "enUS", label: "English" }, { key: "deDE", label: "Deutsch" }, { key: "frFR", label: "Français" },
    { key: "esES", label: "Español" }]; // = ns.LANGUAGES
  const PARAM_OF = { enUS: "en", deDE: "de", frFR: "fr", esES: "es" };
  C.languageBtn = withTip(choiceButton(10, COL_BOTTOM + 19, [{ key: null, label: () => fmt(L("Automatic (%s)"), "English") }, ...LANGS], null, L("Language: "), 260, {
    up: true,
    get: () => (Object.keys(PARAM_OF).find((k) => PARAM_OF[k] === langParam) || null),
    set: (v) => {
      const p = new URLSearchParams(location.search);
      if (!v) p.delete("lang"); else p.set("lang", PARAM_OF[v]);
      const q = p.toString();
      location.href = location.pathname + (q ? "?" + q : "") + location.hash; // = ReloadUI after the question
    },
  }), () => `<div class="w">${L("Language")}</div><div class="d">${L("For every character. Automatic = the language of the game client; if RaidKit Buffs does not offer it, English. Takes effect after reloading the interface.")}</div>`);
  C.controls.push(C.languageBtn);
  /* ----- Sound of the loss alarm (2026-11-20, user; = CreateLossSoundButtons in OptionsProfiles.lua): right of the
     language, 230 px, menu upwards, choosing plays the sound once; "Test" = the whole alarm (testLoss in core.js) ----- */
  C.lossSoundBtn = withTip(choiceButton(290, COL_BOTTOM + 19, LOSS_SOUNDS.map((s) => ({ key: s.key, label: L(s.label), header: s.header })), null, L("Alarm sound: "), 230, {
    up: true,
    get: () => lossSound,
    set: (v) => { lossSound = v; playLossSound(v); },
  }), () => `<div class="w">${L("Alarm sound")}</div><div class="d">${L("Played when a consumable vanishes although time was left (usually the buff cap). For every character. Choosing a sound plays it once.")}</div>`);
  C.controls.push(C.lossSoundBtn);
  C.lossTestBtn = withTip(Place(Button(L("Test"), 60, () => testLoss()), 290 + 236, COL_BOTTOM + 19),
    () => `<div class="w">${L("Test the loss alarm")}</div><div class="d">${L("Shows the alarm as if the buff cap had pushed off a consumable of the bar: red blinking icon, chat line, sound. No buff is removed.")}</div>`);
  C.lossSoundBtn.classList.add("caponly"); C.lossTestBtn.classList.add("caponly"); // no alarm without a cap (2026-11-21)

  Page("profiles");
  Place(Label(L("Profile:")), 10, 12);
  C.profName = Place(mk("div", "lbl hl pname"), 58, 12); C.profName.style.width = "420px";
  withTip(C.profName, () => charState().base && !isModified()
    ? `<div class="n">${esc(charState().base)}</div><div class="w">${L("Your settings equal this profile (last loaded or saved).")}</div>`
    : `<div class="n">${L("Own##profile")}</div><div class="w">${L("Your own settings. They are always stored for this character; \"Save\" or \"Save as ...\" puts them into a profile.")}</div>`);
  // 2026-11-20 (user, proposal C with the middle buttons on top): no button row at the top any more. Left the list,
  // middle Load / Default and below the info on the selected profile (everything that fetches settings), right
  // Save / Save as and the actions on the list (everything that writes into the list). "Save" overwrites the
  // profile SELECTED in the list, any time.
  const PX = 490, PW = 160, MX = 262, Y0 = 70, STEP = 26;
  C.profSave = Place(Button(L("Save"), PW, () => { if (!C.profSave.classList.contains("dis")) saveOver(profSel); }), PX, Y0);
  withTip(C.profSave, () => `<div class="n">${L("Save")}</div><div class="w">${esc(fmt(L("Overwrites the profile \"%s\" with the current settings."), profSel || "-"))}</div><div class="d">${L("Select the profile in the list first.")}</div>`);
  C.profSaveAs = Place(Button(L("Save as ..."), PW, askSaveAs), PX, Y0 + STEP);
  withTip(C.profSaveAs, () => `<div class="n">${L("Save as")}</div><div class="w">${L("Save the current settings as a profile with a new name. Without the position of the bar - it belongs to the character.")}</div>`);
  // = former "Standard" in the manage dialog: resets the own settings, not a saved profile ("special Load", user)
  C.profDefault = Place(Button(fmt(L("Default (%s) ..."), CLASS_NAMES[playerClass]), 160, () => popup(fmt(L("Reset your own settings to the default for %s?\nThe position of the bar stays."), CLASS_NAMES[playerClass]), {
    buttons: [{ text: L("Reset"), fn: resetToClassDefault }, { text: L("Cancel") }] })), MX, Y0 + STEP);
  withTip(C.profDefault, () => `<div class="n">${L("Default")}</div><div class="w">${L("Rows and appearance like a new character of this class. Saved profiles stay untouched.")}</div>`);
  const psep = Place(mk("div", "sep"), 10, 40); psep.style.width = (PAGE_W - 20) + "px";

  // saved profiles (former dialogs "Laden" and "Verwalten", now on the page):
  // left the list, middle info + load, right actions on the selected profile
  Place(Label(L("Saved profiles:")), 10, 50);
  C.profList = ProfileList(10, 70, 240, PROF_LINES, () => profSel, (n) => { profSel = n; refreshOptions(); }, (n) => { profSel = n; doLoadSelected(); });
  C.profInfo = Place(mk("div", "lbl pinfo"), MX, Y0 + 2 * STEP + 10); C.profInfo.style.width = "214px";
  // "Take over: Rows / Appearance" is gone since session 20 (user): loading takes everything except the position
  C.profLoad = Place(Button(L("Load"), PW, () => { if (!C.profLoad.classList.contains("dis")) doLoadSelected(); }), MX, Y0);
  withTip(C.profLoad, () => `<div class="n">${L("Load")}</div><div class="w">${esc(fmt(L("Copy \"%s\" into your own settings."), profSel || "-"))}</div><div class="d">${L("Everything except the position of the bar.")}</div><div class="d">${L("Double-click in the list does the same.")}</div>`);
  const ssep = Place(mk("div", "sep"), PX, Y0 + 2 * STEP + 6); ssep.style.width = PW + "px";

  C.profNeedSel = [];
  const act = (text, y, fn, tipHtml, needsSelection) => {
    const b = Place(Button(text, PW, () => { if (!b.classList.contains("dis")) fn(); }), PX, y + 32); // below Save / Save as and their line (Rename at 136)
    if (tipHtml) withTip(b, tipHtml);
    if (needsSelection) C.profNeedSel.push(b);
    return b;
  };
  act(L("Rename ..."), 104, () => popup(fmt(L("New name for \"%s\":"), profSel), { edit: profSel, buttons: [{ text: L("Rename"), fn: (v) => {
    const name = v.trim();
    if (!name) { print(L("Please enter a profile name.")); return false; }
    if (name === profSel) return;
    if (db.profiles[name]) { print(fmt(L("Profile '%s' already exists."), name)); return false; }
    db.profiles[name] = db.profiles[profSel]; delete db.profiles[profSel];
    if (charState().base === profSel) charState().base = name;
    print(fmt(L("Profile '%s' is now called '%s'."), profSel, name)); profSel = name; refreshOptions();
  } }, { text: L("Cancel") }] }), null, true);
  act(L("Copy ..."), 130, () => popup(fmt(L("Name for the copy of \"%s\":"), profSel), { edit: fmt(L("%s (copy)"), profSel), buttons: [{ text: L("Copy"), fn: (v) => {
    const name = v.trim();
    if (!name) { print(L("Please enter a profile name.")); return false; }
    if (db.profiles[name]) { print(fmt(L("Profile '%s' already exists."), name)); return false; }
    db.profiles[name] = clone(db.profiles[profSel]); db.profiles[name].saved = today();
    print(fmt(L("Profile '%s' copied to '%s'."), profSel, name)); profSel = name; refreshOptions();
  } }, { text: L("Cancel") }] }), () => `<div class="w">${L("Copy a saved profile under a new name, e.g. as a starting point for a variant.")}</div>`, true);
  act(L("Delete"), 156, () => popup(fmt(L("Delete profile \"%s\"?\nThis cannot be undone."), profSel), { buttons: [{ text: L("Delete"), fn: () => {
    delete db.profiles[profSel];
    if (charState().base === profSel) charState().base = null;
    print(fmt(L("Profile '%s' deleted."), profSel)); profSel = null; refreshOptions();
  } }, { text: L("Cancel") }] }), () => `<div class="w">${L("Deletes only the saved profile. Characters that loaded it keep their settings.")}</div>`, true);
  const xsep = Place(mk("div", "sep"), PX, 188 + 32); xsep.style.width = PW + "px";
  act(L("Export ..."), 196, () => popup(fmt(L("Export of \"%s\""), profSel), { wide: true, text: exportString(profSel), readOnly: true,
    note: L("The text is selected - Ctrl+C to copy, e.g. for the guild Discord."), buttons: [{ text: L("Close") }] }),
    () => `<div class="w">${L("Output the profile as text to share it with others.")}</div>`, true);
  act(L("Import ..."), 222, () => popup(L("Paste the export text here (Ctrl+V):"), { wide: true, text: "",
    note: L("The profile is only saved, not loaded."), buttons: [{ text: L("Import"), fn: (v) => {
      const o = parseExport(v), s = (v || "").trim();
      if (!o) { print(s.startsWith(EXPORT_PREFIX) ? L("The export text is incomplete or damaged.") : fmt(L("This is not a RaidKit Buffs export (it starts with %s)."), s.slice(0, 8))); return false; }
      let name = o.name || "Import", n = 2;
      while (db.profiles[name]) name = `${o.name || "Import"} (${n++})`;
      storeProfile(name, o.data, o.class);
      print(fmt(L("Profile '%s' imported. Click \"Load\" to use it."), name)); profSel = name; refreshOptions();
    } }, { text: L("Cancel") }] }), () => `<div class="w">${L("Save an export text as a new profile. If the name already exists, the import gets a number.")}</div>`);

  // own helper (2026-11-14): "note" above belongs to the right column of "Alle Gruppen" (x = RX, no x/width), so these
  // two texts used to land top right on this page
  const pnote = (text, x, y, w) => { const n = Place(Label(text, "note"), x, y); n.style.width = w + "px"; return n; };
  pnote(L("Every character has its own settings, always stored for it. A profile is a saved copy: \"Save\" and \"Save as ...\" write one, \"Load\" copies one in."), 10, 350, 640);
  // orientation is per group since session 20 and travels with the profile
  pnote(L("Never in the profile: the position of the bar - it depends on where the bar sits on the screen."), 10, 395, 640);
}

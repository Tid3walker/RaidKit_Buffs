"use strict";
/* ===================== Localization (2026-11-14, = Locale.lua / Locale_deDE.lua) =====================
   The game UI parts of the mockup (bar, tooltips, options window, chat lines of the addon) are English by default,
   German with ?lang=de. The German table is read from Locale_deDE.lua (single source of truth), so the page has to be
   opened through tools\serve-mockups.ps1 (http://localhost:8765/...). L(key) = German value or the key itself, like
   ns.L. The developer texts of the page (explanations, simulation buttons) stay German. */
// ?lang=de|fr|es (2026-11-14: French and Spanish too, = ns.LANGUAGES); anything else = English
const LANG_FILES = { de: "deDE", fr: "frFR", es: "esES" };
const LANG = LANG_FILES[new URLSearchParams(location.search).get("lang")] ? new URLSearchParams(location.search).get("lang") : "en";
const LOCALE_DE = Object.create(null); // table of the chosen language (name kept from the German-only version)
// a key may carry "##context" (2026-11-15): same English text, different translations ("None##texture"); English
// shows the part before it (= Locale.lua)
function L(key) { return LANG !== "en" && key in LOCALE_DE ? LOCALE_DE[key] : key.replace(/##.*$/, ""); }
// = string.format for the placeholders the addon uses: %s, %d, %02d, %+.1f, %.2f, %%
function fmt(s, ...args) {
  let i = 0;
  return String(s).replace(/%([+0]*)(\d*)(?:\.(\d+))?([sdf%])/g, (m, flags, width, prec, type) => {
    if (type === "%") return "%";
    const v = args[i++];
    let out;
    if (type === "s") out = String(v);
    else if (type === "d") out = String(Math.trunc(Number(v)));
    else out = Number(v).toFixed(prec !== undefined ? Number(prec) : 6);
    if (flags.includes("+") && type !== "s" && Number(v) >= 0) out = "+" + out;
    if (width && out.length < Number(width)) out = (flags.includes("0") && type !== "s" ? "0" : " ").repeat(Number(width) - out.length) + out;
    return out;
  });
}
// reads the lines L["English"] = "German" of Locale_deDE.lua (Lua escapes \" \\ \n)
async function loadLocale() {
  if (LANG === "en") return;
  try {
    // relative to this page (2026-11-14): also works below a sub path, e.g. on GitHub Pages
    // game files in Addon-RaidKit_Buffs/RaidKit_Buffs/ since 2026-11-20 (only that folder is linked into the game), languages in Locales/
    const res = await fetch("../../RaidKit_Buffs/Locales/Locale_" + LANG_FILES[LANG] + ".lua", { cache: "no-store" });
    if (!res.ok) throw new Error("HTTP " + res.status);
    const text = await res.text();
    const unesc = (s) => s.replace(/\\(.)/g, (m, c) => (c === "n" ? "\n" : c === "t" ? "\t" : c));
    const re = /^L\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)"/gm;
    let m;
    while ((m = re.exec(text))) LOCALE_DE[unesc(m[1])] = unesc(m[2]);
  } catch (err) {
    console.warn("Locale_deDE.lua could not be loaded, English is shown:", err);
  }
}
// Texts of the page itself (explanations, simulation buttons, mockup messages; 2026-11-14, user: the page may go to
// GitHub Pages for others to try): English, German from this table. French and Spanish switch the game texts, the
// page texts stay English there. P(key) = German value or the key itself; long HTML parts have a short key.
const PAGE_DE = {
  "Language": "Sprache",
  intro: `Leisten-Icon: <kbd>Strg</kbd>+Klick = benutzen (Standard, in den Optionen abschaltbar), Rechtsklick = Buff entfernen (simuliert <kbd>/cancelaura</kbd>). <kbd>Umschalt</kbd>+Ziehen = verschieben, <kbd>Umschalt</kbd>+Rechtsklick = Optionen.
    Optionen: Items aus dem Katalog in die Reihe ziehen, in der Reihe verschieben, rausziehen oder Rechtsklick = entfernen.
    Reihen: + = leere Reihe oder Vorlage, ->+ = Reihe kopieren, Auge = in der Leiste anzeigen/ausblenden. Umbenennen per Stift oder Doppelklick. Simulierte Klasse: Krieger.`,
  profiles: `<b>Profile:</b> Der Charakter bearbeitet immer seine eigene Einstellung. „Speichern unter …“ legt eine benannte Kopie an, „Laden“ kopiert ein gespeichertes Profil (ganz oder nur Reihen/Darstellung) hinein. Die Position der Leiste gehört zum Charakter und wird nie gespeichert oder geladen. Zum Ausprobieren: „Beispielprofile anlegen“.`,
  groups: `<b>Gruppen:</b> In der Reihenliste legt „+ Gruppe“ eine Gruppe mit Rahmen an (die gewählte Reihe kommt hinein), Reihen auf eine Gruppen-Kopfzeile ziehen. Klick auf die Kopfzeile = Gruppen-Einstellungen (Rahmen, Namen, Buff-Limit-Färbung, Ausrichtung, Größe). Auf der Leiste mit offenem Fenster Icons einer Gruppe ziehen (sonst Umschalt+Ziehen): nah an einer anderen Gruppe rastet sie ein (grüner Umriss) und wandert danach mit. Auch „Unerwünschte Buffs“, „Sonstige Buffs“ und „Debuffs“ sind eigene Gruppen (am Ende der Reihenliste): bei offenem Fenster sind sie auch leer als Vorschau-Kasten zu sehen und lassen sich ziehen; ohne Inhalt verschwinden sie sonst, was an ihnen hängt, rückt nach.`,
  buffs: `<b>Buffs:</b> Jede Reihe nimmt Consumables und fremde Buffs (die Katalog-Reiter schalten nur die Liste um). Buff-Icons (z. B. in Weltbuffs, Raidbuffs) sind grau oder farbig, benutzen kann man sie nicht (Ausnahme: eigene Klassen-Buffs wie Battle Shout). <b>Buff-Limit:</b> ab 4 freien Plätzen färbt sich der Hintergrund der Leiste gelb, dann orange, bei 1 rot. Unter der Leiste: <b>Unerwünschte Buffs</b> (Klick aufs X entfernt alle, auch im Kampf), <b>Sonstige Buffs</b> mit allen übrigen aktiven Buffs und die <b>Debuffs</b>.
    Zum Ausprobieren: „Raid-Situation“, dann mehrmals „Procs“. Am Limit fällt der älteste Buff weg, außer Flask, Zanza und Weltbuffs; ein verlorenes Consumable blinkt rot und meldet sich im Chat.`,
  bagsHint: "Ein Item in eine Reihe der Optionen ziehen, wie aus einer Tasche im Spiel. Enthält auch ein Item, das nicht im Katalog steht.",
  "Bags (real items, drag & drop)": "Taschen (echte Items, Drag &amp; Drop)",
  "Combat: off": "Kampf: aus", "Combat: on": "Kampf: an",
  "All buffs active": "Alle Buffs aktiv", "Remove all buffs": "Alle Buffs entfernen", "Raid situation": "Raid-Situation",
  "Version: Era (cap 32)": "Version: Era (Limit 32)", "Version: no buff cap": "Version: ohne Buff-Limit",
  "Windfury: off": "Windfury: aus", "Windfury: on": "Windfury: an",
  "Off hand: weapon": "Nebenhand: Waffe", "Off hand: none": "Nebenhand: keine",
  "Group: Solo": "Gruppe: Solo", "Group: Party": "Gruppe: Gruppe", "Group: Raid": "Gruppe: Raid",
  "Options window: closed": "Optionsfenster: zu", "Options window: open": "Optionsfenster: offen",
  "Fill bags": "Taschen auffüllen", "Empty bags": "Taschen leeren", "Time: 1×": "Zeit: 1×", "Time: 60×": "Zeit: 60×",
  "Reset mockup": "Mockup zurücksetzen", "Create example profiles": "Beispielprofile anlegen", "In combat": "Im Kampf",
  "Own window (/rkb)": "Eigenes Fenster (/rkb)", "Esc → Options → AddOns": "Esc → Optionen → AddOns",
  "How to use the mockup": "Bedienung des Mockups",
  "Mockup loaded. Ctrl+click uses an item, right-click removes the buff.": "Mockup geladen. Strg+Klick benutzt ein Item, Rechtsklick entfernt den Buff.",
  "Mockup reset.": "Mockup zurückgesetzt.",
  "Mount": "Reittier", "Mounted: ": "Aufgesessen: ", "Dismounted.": "Abgesessen.",
  "Zone: world": "Zone: Welt", "Zone: AQ40": "Zone: AQ40",
  "Raid situation: world buffs, consumables, raid buffs, Int/Spirit (unwanted), blessings, aura, Renew.": "Raid-Situation: Weltbuffs, Consumables, Raidbuffs, Int/Willen (unerwünscht), Segen, Aura, Renew.",
  "Example profiles created: %s.": "Beispielprofile angelegt: %s.",
  "Raid Warrior": "Raid Krieger", "Mage BWL (guild)": "Magier BWL (Gilde)",
};
function P(key) { return LANG === "de" && key in PAGE_DE ? PAGE_DE[key] : key; }
// static texts in the HTML: data-l = game text (L), data-p = page text (P, may contain HTML)
function localizeStatic() {
  for (const el of document.querySelectorAll("[data-l]")) el.textContent = L(el.dataset.l);
  if (LANG === "de") for (const el of document.querySelectorAll("[data-p]")) if (el.dataset.p in PAGE_DE) el.innerHTML = PAGE_DE[el.dataset.p];
  document.documentElement.lang = LANG;
}
// language of the whole page (2026-11-14, user; before a button "Sprache: ..." in the toolbar that cycled): dropdown
// top right, default English. Reloads the page with ?lang=, other parameters (class=...) stay.
// page help above the toolbar can be folded (2026-11-22, user); folded at first (user, same day), this browser remembers
// an opened one (only a convenience, the page works without storage)
function setupPageHelp() {
  const d = document.getElementById("pageHelp"), KEY = "rkbMockupHelpOpen";
  if (!d) return;
  try { if (localStorage.getItem(KEY) === "1") d.open = true; } catch (e) { /* storage blocked */ }
  d.addEventListener("toggle", () => { try { localStorage.setItem(KEY, d.open ? "1" : "0"); } catch (e) { /* ignore */ } });
}
function setupPageLang() {
  const sel = document.getElementById("pageLang");
  sel.value = LANG;
  sel.addEventListener("change", () => {
    const p = new URLSearchParams(location.search);
    if (sel.value === "en") p.delete("lang"); else p.set("lang", sel.value);
    const q = p.toString();
    location.href = location.pathname + (q ? "?" + q : "") + location.hash;
  });
}

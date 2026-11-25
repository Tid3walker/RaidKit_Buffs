"use strict";
/* RaidKit Buffs mockup: page "Info" (= OptionsInfo.lua). Third tab next to "Profiles" and "Bars" (user 2026-11-20):
   header, how the bar is used, legend, buff cap with a live counter, chat commands, credits, error report.
   Three columns; inside a column the blocks follow each other (Lua: font strings chained below each other), so the
   heights may differ a little from the game but nothing overlaps.
   Part of raidkit_buffs.html, loaded in order by js/boot.js (classic scripts sharing one global scope). */

// maker: only a short tag the user chooses, NEVER his real name (user 2026-11-20). In game: "## Author" in the .toc;
// without it the line is hidden. "Tid3walker" (the CurseForge name) since 2026-11-21, before "Addon Forge" (user).
const AUTHOR_TAG = "Tid3walker";

// [key, text] pairs; the key is gold, the text white (= INFO_* tables in OptionsInfo.lua)
const INFO_USE = [
  ["Ctrl+click", "use the item, cast your own class buff or mount up"],
  ["Right-click", "remove the buff (not in combat)"],
  ["Mouse wheel", "switch to another variant of the slot (not in combat)"],
  ["Shift+drag", "move a group; it snaps to other groups"],
  ["Shift+right-click", "open these options"],
  ["Red X", "remove all unwanted buffs, also in combat"],
];
const INFO_LEGEND = [
  ["Gray icon", "buff missing"],
  ["Colored icon", "buff active, minutes left at the top"],
  ["Yellow time", "less than 10 % of the duration left"],
  ["Number", "how many are in your bags (red: none), if switched on"],
  ["Lock", "can only be used after combat"],
  ["Red border", "unwanted buff"],
  ["MH / OH", "weapon enchant on the main hand / off hand"],
  ["Number in a row", "used buff slots (buff counter, from the buff catalog)"],
  ["Yellow, orange, red bar", "few free buff slots: yellow from 4, red at 1"],
  ["Blinking red", "a consumable vanished early (buff cap?), with chat line and sound"],
];
const INFO_COMMANDS = [
  ["/rkb, /rkbc", "open or close these options"],
  ["/rkb show | hide | toggle", "show or hide the bar (hidden = Blizzard buff bar)"],
  ["/rkb profile", "list the saved profiles"],
  ["/rkb profile <name>", "load a profile, e.g. in a macro for tank and damage"],
  ["/rkb reset", "move the bar back to its default place"],
];
const INFO_CREDITS = [
  ["Sounds", "from Freesound.org: \"Noooh!\" by jorickhoofd (CC BY 4.0), \"Retro video game sfx - Fail\" by OwlStorm (CC0)"],
  ["Icons and game sounds", "Blizzard Entertainment"],
  ["Languages", "English, Deutsch, Français, Español"],
];

const LOGO_SRC = "../../Assets/Logos/" + encodeURIComponent("RaidKit_Buffs - v1 - 400x400.jpg");
const INFO_X = [10, 338, 666], INFO_W = 308, INFO_GAP = 14; // = INFO_X, INFO_W, GAP in OptionsInfo.lua

function infoPairs(list) {
  const box = mk("div", "ipairs");
  for (const [k, t] of list) {
    const line = mk("div", "ipair");
    line.appendChild(mk("span", "k", L(k)));
    line.appendChild(document.createTextNode(": " + L(t)));
    box.appendChild(line);
  }
  return box;
}
function infoHead(col, text) { col.appendChild(mk("div", "ihead", L(text))); }

// error report (= ErrorReport in OptionsInfo.lua): version, client, language, class, buff cap, counts, errors.
// Never the character or realm name (privacy).
function infoReport() {
  const groups = profile.groups ? profile.groups.filter((g) => !g.area).length : 1;
  return ["RaidKit Buffs 0.8.3",
    "Client: 1.15.8 (mockup), " + ({ en: "enUS", de: "deDE", fr: "frFR", es: "esES" }[LANG] || "enUS"),
    "Class: " + playerClass + ", buff cap: " + BUFF_CAP,
    "Groups: " + groups + ", rows: " + profile.rows.length + ", saved profiles: " + savedNames().length,
    "Errors (0):", "-"].join("\n");
}

function createInfoPage() {
  Page("info");
  const cols = INFO_X.map((x) => { const c = Place(mk("div", "infocol"), x, 12); c.style.width = INFO_W + "px"; return c; });
  C.infoCols = cols;

  // column 1: header, use, legend
  const head = mk("div", "ihdr");
  // addon logo, 80 px (user 2026-11-21, variant "A header" of four proposals; before the potion icon, 32 px). In the
  // game Media/Textures/Logo.tga (256x256, tools/image-to-tga.ps1), here the JPG it was made from.
  const ic = mk("img", "ilogo"); ic.src = LOGO_SRC; head.appendChild(ic);
  const ht = mk("div", "ihtext");
  ht.appendChild(mk("div", "ititle", "RaidKit - Buffs & Consumables"));
  ht.appendChild(mk("div", "isub", fmt(L("Version %s - WoW Classic Era"), "0.8.3")));
  if (AUTHOR_TAG) ht.appendChild(mk("div", "isub", fmt(L("by %s"), AUTHOR_TAG)));
  head.appendChild(ht);
  cols[0].appendChild(head);
  infoHead(cols[0], "On the bar");
  cols[0].appendChild(infoPairs(INFO_USE));
  infoHead(cols[0], "Colors and signs");
  cols[0].appendChild(infoPairs(INFO_LEGEND));

  // column 2: buff cap, chat commands
  infoHead(cols[1], "Buff cap");
  cols[1].appendChild(mk("div", "itext", L("Classic Era shows at most 32 buffs on you. When all slots are full, a new buff pushes another one off, consumables included. RaidKit Buffs colors the bar when slots run short and raises an alarm when a consumable vanished early; after a boss fight and when leaving the raid it lists what was lost. Tip: put useless buffs into \"Unwanted Buffs\" and remove them with the red X.")));
  infoHead(cols[1], "Chat commands");
  cols[1].appendChild(infoPairs(INFO_COMMANDS));
  cols[1].appendChild(mk("div", "itext idim", L("Macro example: a macro with \"/rkb profile Tank\" loads that profile with one click.")));

  // column 3: credits, error report
  infoHead(cols[2], "Credits");
  cols[2].appendChild(infoPairs(INFO_CREDITS));
  infoHead(cols[2], "Report a problem");
  cols[2].appendChild(mk("div", "itext", L("A red error line in the chat? The button puts the version, the game client and the errors into a text you can copy (Ctrl+C) and pass on. It contains no character name.")));
  C.infoErrors = mk("div", "itext icap"); cols[2].appendChild(C.infoErrors);
  const rb = Button(L("Error report ..."), 160, () => popup(L("Error report"), { wide: true, text: infoReport(), readOnly: true,
    note: L("The text is selected - Ctrl+C to copy."), buttons: [{ text: L("Close") }] }));
  rb.classList.add("inforeport"); // not "ibtn": that is the reset button (options-bars.js)
  cols[2].appendChild(rb);

  // error count: once a second while the page is shown (= OnUpdate of the page in OptionsInfo.lua)
  setInterval(() => { if (optPage === "info") refreshInfoPage(); }, 1000);
}

// columns 2 and 3 start at the height of the first heading of column 1 ("On the bar"), below the header (user
// 2026-11-21; = alignTo in OptionsInfo.lua). Measured while shown (a hidden page has no layout).
function alignInfoColumns() {
  const cols = C.infoCols, first = (c) => c.querySelector(".ihead");
  if (!cols || !cols[0].offsetHeight) return;
  const top = 12 + first(cols[0]).offsetTop - first(cols[1]).offsetTop;
  cols[1].style.top = cols[2].style.top = top + "px";
}

function refreshInfoPage() {
  if (!C.infoErrors) return;
  alignInfoColumns();
  C.infoErrors.textContent = fmt(L("Errors this session: %d"), 0);
}

local addonName, ns = ...

------------------------------------------------------------------------
-- Localization (2026-11-14, user): English is the default language, German is offered too, more may follow.
-- Code always writes the ENGLISH text as key: L["Show separator"]. A key without a translation shows itself,
-- so English needs no table. Every other language is a table ns.LOCALES[code] (Locale_deDE.lua ...).
-- Format strings keep their placeholders in all languages: L["%d free slots"] = "%d freie Plätze".
-- In-game texts: Latin-1 characters only (no arrows, en dashes, ellipsis), files in UTF-8.
--
-- Choosing the language (2026-11-14, user; bottom line of the page "Bars" since 2026-11-15, before a page "Common"): RaidKitBuffsDB.language = nil (follow the client) or a
-- code from ns.LANGUAGES. SavedVariables only exist after every file of the addon has run (ADDON_LOADED), so:
--   * while the files load, ns.activeLocale is nil and L returns the English key. Texts stored at load time
--     (catalog notes, list labels, template names ...) are therefore English keys;
--   * ns.SetLanguage (Core.lua, ADDON_LOADED) picks the language; from then on L translates at every access;
--   * code that shows a text stored at load time translates it again: L[entry.note], L[filter.label] ...
--     (L of an English key is the translation, L of a translated text is itself). Tables of texts built at load
--     time can use ns.LocalizedTable (translates on access).
-- Switching the language needs /reload: frames built earlier keep their texts.
------------------------------------------------------------------------

ns.CLIENT_LOCALE = GetLocale and GetLocale() or "enUS"
ns.LOCALES = {}       -- [code] = { [English] = translation }, filled by Locale_<code>.lua
ns.activeLocale = nil -- nil = English (also during loading)

-- Languages offered in the options (key nil = follow the client). English first, then the translations.
ns.LANGUAGES = {
    { key = "enUS", label = "English" },
    { key = "deDE", label = "Deutsch" },
    { key = "frFR", label = "Français" }, -- 2026-11-14 (user)
    { key = "esES", label = "Español" },  -- 2026-11-14 (user), also for esMX clients
}

-- client locales that use another one's table (Latin American Spanish, British English)
local LOCALE_ALIAS = { esMX = "esES", enGB = "enUS" }

ns.L = setmetatable({}, {
    __index = function(_, key)
        local t = ns.activeLocale and ns.LOCALES[ns.activeLocale]
        local v = t and t[key]
        if v then return v end
        -- "##context" in a key (2026-11-15): same English text, different translations ("None##texture")
        return type(key) == "string" and key:match("^(.-)##") or key
    end,
})

-- Language code that "follow the client" means: the client's if we have it, else English
function ns.ClientLanguage()
    local code = LOCALE_ALIAS[ns.CLIENT_LOCALE] or ns.CLIENT_LOCALE
    if ns.LOCALES[code] then return code end
    return "enUS"
end

-- choice = nil (client) or a code; unknown codes fall back to English
function ns.SetLanguage(choice)
    local code = choice or ns.ClientLanguage()
    if code ~= "enUS" and not ns.LOCALES[code] then code = "enUS" end
    ns.activeLocale = code ~= "enUS" and code or nil
end

-- true while German is shown (for the few places that need more than a string)
function ns.IsGerman()
    return ns.activeLocale == "deDE"
end

-- Shows a text stored at load time: a function is called (texts built from pieces, e.g. "Raid: <class>"),
-- a string is translated (an English key gives the translation, anything else stays as it is)
function ns.Text(x)
    if type(x) == "function" then return x() end
    if x == nil then return nil end
    return ns.L[x]
end

-- Sort key for names (2026-11-20, user: catalog A-Z by culture). Lua compares bytes, so "Öl" would come after "Z":
-- lower case, accented letters fold to their base letter (German ä = a like a dictionary, French é = e), ß = ss,
-- Spanish ñ after n ("n~", "~" sorts after every letter). Works for names in any client language, which need
-- not be the addon language. Mockup: localeCompare with the page language.
local FOLD = {}
for base, chars in pairs({
    a = "àáâãäåÀÁÂÃÄÅ", c = "çÇ", e = "èéêëÈÉÊË", i = "ìíîïÌÍÎÏ", o = "òóôõöøÒÓÔÕÖØ", u = "ùúûüÙÚÛÜ", y = "ýÿÝ",
    ["n~"] = "ñÑ", ss = "ß", ae = "æÆ", oe = "œŒ",
}) do
    for ch in chars:gmatch("[\192-\223][\128-\191]") do FOLD[ch] = base end
end
function ns.SortKey(name)
    return (tostring(name or ""):lower():gsub("[\192-\223][\128-\191]", FOLD))
end

-- A table of English texts that translates on access: t[k] = L[raw[k]]. Only for indexing (no pairs/ipairs).
function ns.LocalizedTable(raw)
    return setmetatable({}, {
        __index = function(_, k)
            local v = raw[k]
            if v == nil then return nil end
            return ns.L[v]
        end,
    })
end

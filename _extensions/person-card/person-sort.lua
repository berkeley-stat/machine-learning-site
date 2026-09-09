
-- Builds the sort key used to order person cards on the rendered page.
-- Cards are emitted with a data-sortkey attribute; sort-cards.lua reorders
-- them, so the order inside the .qmd files does not matter.

local M = {}

-- Accented letters fold to their ASCII base so that e.g. "Pérez" sorts with
-- "Perez". string.lower only handles ASCII, so uppercase forms are listed too.
local FOLD = {
  ["á"]="a", ["à"]="a", ["â"]="a", ["ã"]="a", ["ä"]="a", ["å"]="a", ["ā"]="a",
  ["é"]="e", ["è"]="e", ["ê"]="e", ["ë"]="e", ["ē"]="e",
  ["í"]="i", ["ì"]="i", ["î"]="i", ["ï"]="i", ["ī"]="i",
  ["ó"]="o", ["ò"]="o", ["ô"]="o", ["õ"]="o", ["ö"]="o", ["ø"]="o", ["ō"]="o",
  ["ú"]="u", ["ù"]="u", ["û"]="u", ["ü"]="u", ["ū"]="u",
  ["ñ"]="n", ["ç"]="c", ["ý"]="y", ["ÿ"]="y",
  ["š"]="s", ["ś"]="s", ["ž"]="z", ["ź"]="z", ["ż"]="z", ["č"]="c", ["ć"]="c",
  ["ł"]="l", ["ń"]="n", ["ř"]="r", ["ť"]="t", ["ď"]="d", ["ğ"]="g", ["ı"]="i",
  ["Á"]="a", ["À"]="a", ["Â"]="a", ["Ã"]="a", ["Ä"]="a", ["Å"]="a", ["Ā"]="a",
  ["É"]="e", ["È"]="e", ["Ê"]="e", ["Ë"]="e", ["Ē"]="e",
  ["Í"]="i", ["Ì"]="i", ["Î"]="i", ["Ï"]="i", ["Ī"]="i",
  ["Ó"]="o", ["Ò"]="o", ["Ô"]="o", ["Õ"]="o", ["Ö"]="o", ["Ø"]="o", ["Ō"]="o",
  ["Ú"]="u", ["Ù"]="u", ["Û"]="u", ["Ü"]="u", ["Ū"]="u",
  ["Ñ"]="n", ["Ç"]="c", ["Ý"]="y",
  ["Š"]="s", ["Ś"]="s", ["Ž"]="z", ["Ź"]="z", ["Ż"]="z", ["Č"]="c", ["Ć"]="c",
  ["Ł"]="l", ["Ń"]="n", ["Ř"]="r", ["Ť"]="t", ["Ď"]="d", ["Ğ"]="g",
}

local function fold(s)
  return (s:gsub("[\194-\244][\128-\191]*", function(c) return FOLD[c] or c end))
end

-- "Ishaq Aden-Ali" -> "adenali ishaq"; sorting on this orders by last name and
-- breaks ties on the given names. A card may override the derived key by
-- passing sortkey = "..." (useful for multi-word surnames like "van der Berg").
function M.sort_key(name, override)
  local raw = override
  if raw == nil or raw == "" then
    local given, last = name:match("^(.*)%s+(%S+)$")
    if not last then
      given, last = "", name
    end
    raw = last .. " " .. given
  end
  local key = fold(raw):lower()
  key = key:gsub("[^%w%s]", "")          -- hyphens/periods must not affect order
  key = key:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  return key
end

return M

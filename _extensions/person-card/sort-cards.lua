
-- Reorders person cards inside a ::: {.grid} block by their data-sortkey,
-- so the order of the shortcodes in the .qmd file is irrelevant.
-- Blocks without a sortkey (prose, other shortcodes) keep their position.
-- Must run after Quarto's own filters, which is what the `- quarto` entry
-- ahead of this filter in _quarto.yml arranges: the cards only become
-- RawBlocks once shortcodes have been expanded.

local function sort_key_of(block)
  if block.t ~= "RawBlock" then
    return nil
  end
  if block.format ~= "html" and block.format ~= "html5" then
    return nil
  end
  return block.text:match('data%-sortkey="([^"]*)"')
end

function Div(el)
  if not el.classes:includes("grid") then
    return nil
  end

  local slots, cards = {}, {}
  for i, block in ipairs(el.content) do
    local key = sort_key_of(block)
    if key then
      table.insert(slots, i)
      table.insert(cards, { key = key, block = block })
    end
  end

  if #cards < 2 then
    return nil
  end

  table.sort(cards, function(a, b) return a.key < b.key end)
  for n, i in ipairs(slots) do
    el.content[i] = cards[n].block
  end
  return el
end

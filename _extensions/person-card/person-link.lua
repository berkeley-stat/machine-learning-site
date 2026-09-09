
-- Wraps card content in a link to the person's homepage. Cards whose url is
-- blank render the content bare, so they are not clickable and carry none of
-- the link styling.

local M = {}

function M.wrap(url, style, inner)
  if url == "" then
    return inner
  end
  local attrs = ""
  if style ~= "" then
    attrs = string.format(" style=\"%s\"", style)
  end
  return string.format("<a href=\"%s\" target='_blank'%s>%s</a>", url, attrs, inner)
end

return M

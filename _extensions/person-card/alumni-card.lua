local resize = require("resize-image")
local sorting = require("person-sort")
local linking = require("person-link")

return {
  ['alumni-card'] = function(args, kwargs)
    local name = pandoc.utils.stringify(kwargs["name"] or "")
    local url = pandoc.utils.stringify(kwargs["url"] or "")
    local position = pandoc.utils.stringify(kwargs["position"] or "")
    local year = pandoc.utils.stringify(kwargs["year"] or "")
    local site_root = quarto.project.directory or "."
    local image = resize.card_image(name, pandoc.utils.stringify(kwargs["image"] or ""), site_root)
    local sortkey = sorting.sort_key(name, pandoc.utils.stringify(kwargs["sortkey"] or ""))

    local headshot = linking.wrap(url, "", string.format(
      [[<img src="%s" alt="Headshot" style="width: 100%%; aspect-ratio: 1/1; object-fit: cover; object-position: center; border-radius: 10%%;">]],
      image))
    local nameline = linking.wrap(url, "color: inherit; text-decoration: underline; text-decoration-color: rgba(0,0,0,0.3);", string.format(
      [[<span style="font-size: 1.1em; font-weight: 600;">%s</span>]], name))

    local html = string.format([[
<div class="g-col-12 g-col-sm-6 g-col-md-4 g-col-xl-3" data-sortkey="%s">
<div style="display: flex; gap: 15px; align-items: start;">
<div style="flex-shrink: 1; width: 90px; min-width: 50px;">
%s
</div>
<div style="flex: 1;line-height: 1.1;">
%s
<br><span style="font-size: 0.7em; font-weight: 300;">
%s
<br>
%s
</span>
</div>
</div>
</div>
]], sortkey, headshot, nameline, year, position)
    return pandoc.RawBlock('html', html)
  end
}

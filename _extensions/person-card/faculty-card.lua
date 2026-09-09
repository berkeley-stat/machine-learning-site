local resize = require("resize-image")
local sorting = require("person-sort")
local linking = require("person-link")

return {
  ['faculty-card'] = function(args, kwargs)
    local name = pandoc.utils.stringify(kwargs["name"] or "")
    local url = pandoc.utils.stringify(kwargs["url"] or "")
    local affil = pandoc.utils.stringify(kwargs["affil"] or "")
    local site_root = quarto.project.directory or "."
    local image = resize.card_image(name, pandoc.utils.stringify(kwargs["image"] or ""), site_root)
    local sortkey = sorting.sort_key(name, pandoc.utils.stringify(kwargs["sortkey"] or ""))

    local headshot = linking.wrap(url, "", string.format(
      [[<img src="%s" alt="Headshot" style="width: 100%%; aspect-ratio: 1/1; object-fit: cover; object-position: center; border-radius: 10%%;">]],
      image))
    local nameline = linking.wrap(url, "color: inherit; text-decoration: none;", string.format(
      [[<span style="font-size: 1.05em; font-weight: 600;">%s</span>]], name))

    local html = string.format([[
<div class="g-col-12 g-col-sm-6 g-col-lg-3" data-sortkey="%s">
<div style="display: flex; flex-direction: column; gap: 10px; align-items: center;">
<div style="width: 80%%;">
%s
</div>
<div style="text-align: center; line-height: 1.1;">
%s
<br><span style="font-size: 0.7em; font-weight: 300;">
%s
</span>
</div>
</div>
</div>
]], sortkey, headshot, nameline, affil)
    return pandoc.RawBlock('html', html)
  end
}

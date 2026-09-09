
-- Prepares headshot images for use in person cards.
-- Cards do not spell out their image: it is looked up from the person's name,
-- as images/firstname_lastname.jpg -- see card_image at the bottom of this file.
-- For every image, this crops a center square and resizes to 400x400px JPEG,
-- saving the result to images-resized/. The original file is never modified.

-- Recommended usage:
--     1. Run `quarto preview` on a local machine with `sips` available (MacOS).
--        The processed images will be saved to images-resized/.
--        (cf. If your local is not MacOS, you may need ImageMagick's `convert` instead of `sips`.)
--     2. When ready to publish, commit images-resized/ to the repo as well.
--        Github Actions will then reuse the already-processed images without needing `sips`.

local sorting = require("person-sort")

local M = {}
local TARGET_PX = 400  -- output square size in pixels (covers faculty at 2x retina)

-- Get file size in bytes, or 0 if file doesn't exist or can't be accessed
local function file_exists(path)
  local fh = io.open(path, "r")
  if fh then
    fh:close()
    return true
  end
  return false
end

-- Extracts filename stem without extension (e.g. "images/name.png" -> "name")
local function get_stem(path)
  local filename = path:match("([^/]+)$")
  return filename:match("(.+)%..+$") or filename
end

-- Returns the image path to use in <img src>.
-- Always processes the image to a 400x400px JPEG in images-resized/.
-- Skips processing if the output already exists.
function M.prepare_image(image_path, site_root)
  local stem = get_stem(image_path)
  local abs_src = site_root .. image_path
  local abs_dst = site_root .. "/images-resized/" .. stem .. ".jpg"
  local dst_path = "/images-resized/" .. stem .. ".jpg"

  -- Reuse existing processed image
  if file_exists(abs_dst) then
    return dst_path
  end

  -- Step 1: get image dimensions to compute center crop
  local fh = io.popen(string.format('sips -g pixelWidth -g pixelHeight "%s" 2>/dev/null', abs_src))
  local info = fh and fh:read("*a") or ""
  if fh then fh:close() end

  local w = tonumber(info:match("pixelWidth: (%d+)"))
  local h = tonumber(info:match("pixelHeight: (%d+)"))

  if not w or not h then
    -- sips not available or failed — return original
    return image_path
  end

  -- Step 2: crop center square, then resize to TARGET_PX x TARGET_PX
  local side = math.min(w, h)
  local crop_x = math.floor((w - side) / 2)
  local crop_y = math.floor((h - side) / 2)

  -- sips crop: --cropOffset y x (note: sips uses row, col order)
  local cmd = string.format(
    'sips --cropOffset %d %d --cropToHeightWidth %d %d "%s" --out "%s" > /dev/null 2>&1 && ' ..
    'sips --resampleHeightWidth %d %d "%s" --out "%s" > /dev/null 2>&1',
    crop_y, crop_x, side, side, abs_src, abs_dst,
    TARGET_PX, TARGET_PX, abs_dst, abs_dst
  )
  os.execute(cmd)

  if file_exists(abs_dst) then
    return dst_path
  end

  -- fallback: return original if processing failed
  return image_path
end

-- Headshots are found by name: a card only needs name = "Jane Doe" and the
-- file images/jane_doe.jpg is picked up automatically. Other extensions are
-- accepted too, since the originals are a mix of jpg/jpeg/png; whatever is
-- found gets normalised to a 400x400 JPEG by prepare_image below. People with
-- no headshot on file fall back to the Berkeley bear.
local EXTENSIONS = { "jpg", "jpeg", "png", "JPG", "JPEG", "PNG" }
local PLACEHOLDER = "/images/stat_bear.png"

local function find_image(name, site_root)
  local stem = sorting.slug(name)
  if stem == "" then
    return PLACEHOLDER
  end
  -- An already-processed image is enough on its own: Github Actions renders
  -- from images-resized/ and never needs to look at the original.
  local resized = "/images-resized/" .. stem .. ".jpg"
  if file_exists(site_root .. resized) then
    return resized
  end
  for _, ext in ipairs(EXTENSIONS) do
    local candidate = "/images/" .. stem .. "." .. ext
    if file_exists(site_root .. candidate) then
      return candidate
    end
  end
  return PLACEHOLDER
end

-- Entry point for the card shortcodes: resolves the headshot for `name` and
-- returns the path to use in <img src>. Passing image = "..." on the card
-- overrides the name-based lookup, for files that do not follow the convention.
function M.card_image(name, override, site_root)
  local path = override
  if path == nil or path == "" then
    path = find_image(name, site_root)
  end
  return M.prepare_image(path, site_root)
end

return M

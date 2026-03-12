
-- Prepares headshot images for use in person cards.
-- For every image, this crops a center square and resizes to 400x400px JPEG,
-- saving the result to images-resized/. The original file is never modified.

-- Recommended usage:
--     1. Run `quarto preview` on a local machine with `sips` available (MacOS).
--        The processed images will be saved to images-resized/.
--        (cf. If your local is not MacOS, you may need ImageMagick's `convert` instead of `sips`.)
--     2. When ready to publish, commit images-resized/ to the repo as well.
--        Github Actions will then reuse the already-processed images without needing `sips`.

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

return M

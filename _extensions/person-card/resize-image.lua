
-- Resizes local images that are >= 1MB using sips, saving them to images-resized/.
-- This is done to avoid very large images that can cause performance issues in browsers.

-- Recommended usage:
--     1. Run `quarto preview` on a local machine with `sips` available (MacOS).
--        Then, the resized images will be saved to images-resized/ and used in the preview.
--        (cf. If your local is not MacOS, you may need different resizing commands, e.g., ImageMagick's `convert` instead of `sips`.)
--     3. When ready to publish, commit the resized images to the repo as well.
--        Then, Github Actions will not run the resizing step (with `sips`), but just use the already resized images.

local M = {}
local SIZE_THRESHOLD = 0.5 * 1024 * 1024  -- 0.5MB

-- Get file size in bytes, or 0 if file doesn't exist or can't be accessed
local function get_file_size(path)
  local fh = io.popen('stat -f%z "' .. path .. '" 2>/dev/null')
  if fh then
    local result = fh:read("*n")
    fh:close()
    if result and result > 0 then return result end
  end
  -- fallback for Linux (Github Actions runs on Linux)
  fh = io.popen('stat -c%s "' .. path .. '" 2>/dev/null')
  if fh then
    local result = fh:read("*n")
    fh:close()
    return result or 0
  end
  return 0
end

-- Extracts filename from a path (e.g. "images/name.jpg" -> "name.jpg")
local function get_filename(path)
  return path:match("([^/]+)$")
end

-- Returns the image path to use in <img src>.
-- (1) If the image is >= 1MB, resizes it into images-resized/ and returns that path.
-- (2) Otherwise returns the original path unchanged.
function M.maybe_resize(image_path, site_root)
  -- Build absolute path to the source image
  local abs_src = site_root .. image_path
  local size = get_file_size(abs_src)

  -- (1) If the image is >= 1MB, resizes it into images-resized/ and returns that path.
  if size < SIZE_THRESHOLD then
    return image_path
  end

  -- (2) Otherwise returns the original path unchanged.
  -- Build destination path: images-resized/<filename>
  local filename = get_filename(image_path) 
  local abs_dst_dir = site_root .. "/images-resized"
  local abs_dst = abs_dst_dir .. "/" .. filename
  local dst_path = "/images-resized/" .. filename

  -- If resized copy already exists and is small enough, reuse it
  local existing = get_file_size(abs_dst)
  if existing > 0 and existing < SIZE_THRESHOLD then
    return dst_path
  end

  -- Try progressively smaller dimensions until under 1MB
  local dims = {1600, 1200, 1000, 800, 600, 400}
  for _, dim in ipairs(dims) do
    local cmd = string.format(
      'sips --resampleHeightWidthMax %d "%s" --out "%s" > /dev/null 2>&1', -- ACTUAL RESIZE COMMAND
      dim, abs_src, abs_dst
    )
    os.execute(cmd)
    local new_size = get_file_size(abs_dst)
    if new_size > 0 and new_size < SIZE_THRESHOLD then
      return dst_path
    end
  end

  -- Just in case: If still over 1MB after all attempts, return the last resized version anyway
  local fallback = get_file_size(abs_dst)
  if fallback > 0 then
    return dst_path
  end

  -- Just in case: If sips not available or failed — return original
  return image_path
end

return M

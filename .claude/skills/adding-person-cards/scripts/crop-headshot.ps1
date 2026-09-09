# 400x400 centre-crop to JPEG q90 — the Windows stand-in for resize-image.lua's `sips` calls.
# -OffsetXFrac / -OffsetYFrac shift the crop window within the long axis (0 = left/top,
# 0.5 = centred, 1 = right/bottom) so an off-centre subject can be framed by hand.
param(
  [Parameter(Mandatory=$true)][string]$In,
  [Parameter(Mandatory=$true)][string]$Out,
  [double]$OffsetXFrac = 0.5,
  [double]$OffsetYFrac = 0.5,
  [int]$Size = 400
)

Add-Type -AssemblyName System.Drawing

$img = [System.Drawing.Image]::FromFile((Resolve-Path $In).Path)
try {
  $side = [Math]::Min($img.Width, $img.Height)
  $x = [int][Math]::Round(($img.Width  - $side) * $OffsetXFrac)
  $y = [int][Math]::Round(($img.Height - $side) * $OffsetYFrac)
  $srcRect = New-Object System.Drawing.Rectangle $x, $y, $side, $side

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $dstRect = New-Object System.Drawing.Rectangle 0, 0, $Size, $Size
    $g.DrawImage($img, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  } finally { $g.Dispose() }

  $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
           Where-Object { $_.MimeType -eq 'image/jpeg' }
  $prm = New-Object System.Drawing.Imaging.EncoderParameters 1
  $prm.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
    [System.Drawing.Imaging.Encoder]::Quality, [int64]90)

  $outDir = Split-Path -Parent $Out
  if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force $outDir | Out-Null }
  $bmp.Save($Out, $codec, $prm)
  Write-Output ("{0}  {1}x{2} -> {3}x{3} (crop {4},{5} {6}px)" -f (Split-Path -Leaf $Out), $img.Width, $img.Height, $Size, $x, $y, $side)
} finally {
  if ($bmp) { $bmp.Dispose() }
  $img.Dispose()
}

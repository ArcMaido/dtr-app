Add-Type -AssemblyName System.Drawing
$sourcePath = "C:\DTR-APP\assets\branding\app_logo.png"
$destPath = "C:\DTR-APP\assets\branding\app_logo_transparent.png"

$bmp = [System.Drawing.Bitmap]::FromFile($sourcePath)
$width = $bmp.Width
$height = $bmp.Height

$newBmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppPArgb)
$graphics = [System.Drawing.Graphics]::FromImage($newBmp)
$graphics.DrawImage($bmp, 0, 0, $width, $height)
$graphics.Dispose()
$bmp.Dispose()

$targetColor = $newBmp.GetPixel(0, 0)
$tolerance = 28

function IsMatch($c1, $c2, $tol) {
    $dr = [Math]::Abs($c1.R - $c2.R)
    $dg = [Math]::Abs($c1.G - $c2.G)
    $db = [Math]::Abs($c1.B - $c2.B)
    return ($dr -le $tol -and $dg -le $tol -and $db -le $tol)
}

$visited = New-Object 'bool[,]' $width,$height
$stack = New-Object System.Collections.Generic.Stack[System.Drawing.Point]
$transparentCount = 0

# Initial Seeds from borders
for ($x = 0; $x -lt $width; $x++) {
    if (IsMatch ($newBmp.GetPixel($x, 0)) $targetColor $tolerance) { $stack.Push((New-Object System.Drawing.Point($x, 0))) }
    if (IsMatch ($newBmp.GetPixel($x, $height-1)) $targetColor $tolerance) { $stack.Push((New-Object System.Drawing.Point($x, $height-1))) }
}
for ($y = 0; $y -lt $height; $y++) {
    if (IsMatch ($newBmp.GetPixel(0, $y)) $targetColor $tolerance) { $stack.Push((New-Object System.Drawing.Point(0, $y))) }
    if (IsMatch ($newBmp.GetPixel($width-1, $y)) $targetColor $tolerance) { $stack.Push((New-Object System.Drawing.Point($width-1, $y))) }
}

while ($stack.Count -gt 0) {
    $p = $stack.Pop()
    if ($p.X -lt 0 -or $p.X -ge $width -or $p.Y -lt 0 -or $p.Y -ge $height) { continue }
    if ($visited[$p.X, $p.Y]) { continue }
    
    $pixel = $newBmp.GetPixel($p.X, $p.Y)
    if (IsMatch $pixel $targetColor $tolerance) {
        $visited[$p.X, $p.Y] = $true
        $newBmp.SetPixel($p.X, $p.Y, [System.Drawing.Color]::FromArgb(0, $pixel.R, $pixel.G, $pixel.B))
        $transparentCount++
        
        $stack.Push((New-Object System.Drawing.Point($p.X + 1, $p.Y)))
        $stack.Push((New-Object System.Drawing.Point($p.X - 1, $p.Y)))
        $stack.Push((New-Object System.Drawing.Point($p.X, $p.Y + 1)))
        $stack.Push((New-Object System.Drawing.Point($p.X, $p.Y - 1)))
    }
}

$newBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
$newBmp.Dispose()
Write-Output "Transparent pixels: $transparentCount"

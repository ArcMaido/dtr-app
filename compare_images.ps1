[Reflection.Assembly]::LoadWithPartialName('System.Drawing') | Out-Null
$bmp1 = New-Object System.Drawing.Bitmap('c:\DTR-APP\assets\branding\app_logo.png')
$bmp2 = New-Object System.Drawing.Bitmap('c:\DTR-APP\assets\branding\app_logo_transparent.png')
$a0 = 0
$rc = 0
$rcn = 0
for ($x = 0; $x -lt $bmp1.Width; $x++) {
    for ($y = 0; $y -lt $bmp1.Height; $y++) {
        $p1 = $bmp1.GetPixel($x, $y)
        $p2 = $bmp2.GetPixel($x, $y)
        if ($p2.A -eq 0) { $a0++ }
        if ($p1.R -ne $p2.R -or $p1.G -ne $p2.G -or $p1.B -ne $p2.B) {
            $rc++
            if ($p2.A -gt 0) { $rcn++ }
        }
    }
}
$bmp1.Dispose()
$bmp2.Dispose()
Write-Host "Alpha0: $a0"
Write-Host "RGBChanged: $rc"
Write-Host "RGBChangedNonAlpha: $rcn"

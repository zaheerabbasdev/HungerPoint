Add-Type -AssemblyName System.Drawing

$srcPath = "D:\HungerPoint\screenshots\icon.jpg"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source icon not found at $srcPath"
    exit 1
}

$srcImage = [System.Drawing.Image]::FromFile($srcPath)

function Resize-Image {
    param(
        [System.Drawing.Image]$img,
        [int]$w,
        [int]$h,
        [string]$outPath,
        [System.Drawing.Imaging.ImageFormat]$format = [System.Drawing.Imaging.ImageFormat]::Png
    )
    $dir = [System.IO.Path]::GetDirectoryName($outPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $dest = New-Object System.Drawing.Bitmap($w, $h)
    $dest.SetResolution($img.HorizontalResolution, $img.VerticalResolution)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $dest.Save($outPath, $format)
    $g.Dispose()
    $dest.Dispose()
    Write-Output "Generated: $outPath ($w x $h)"
}

function Save-Ico {
    param(
        [System.Drawing.Image]$img,
        [int]$w,
        [int]$h,
        [string]$outPath
    )
    $dir = [System.IO.Path]::GetDirectoryName($outPath)
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $dest = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($img, 0, 0, $w, $h)
    $hIcon = $dest.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $fs = [System.IO.File]::Open($outPath, [System.IO.FileMode]::Create)
    $icon.Save($fs)
    $fs.Close()
    $fs.Dispose()
    $icon.Dispose()
    $g.Dispose()
    $dest.Dispose()
    Write-Output "Generated ICO: $outPath ($w x $h)"
}

# 1. Flutter app asset images
$flutterApps = @("hpcustomer", "hprider", "hpwaiter")
foreach ($app in $flutterApps) {
    Resize-Image $srcImage 512 512 "D:\HungerPoint\$app\assets\images\app_icon.png"
    Resize-Image $srcImage 1024 1024 "D:\HungerPoint\$app\assets\images\app_icon_1024.png"
}

# 2. Android launcher icons
$androidSizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}
foreach ($app in $flutterApps) {
    foreach ($k in $androidSizes.Keys) {
        $sz = $androidSizes[$k]
        Resize-Image $srcImage $sz $sz "D:\HungerPoint\$app\android\app\src\main\res\$k\ic_launcher.png"
    }
}

# 3. iOS icons
$iosSizes = @{
    "Icon-App-20x20@1x.png" = 20
    "Icon-App-20x20@2x.png" = 40
    "Icon-App-20x20@3x.png" = 60
    "Icon-App-29x29@1x.png" = 29
    "Icon-App-29x29@2x.png" = 58
    "Icon-App-29x29@3x.png" = 87
    "Icon-App-40x40@1x.png" = 40
    "Icon-App-40x40@2x.png" = 80
    "Icon-App-40x40@3x.png" = 120
    "Icon-App-60x60@2x.png" = 120
    "Icon-App-60x60@3x.png" = 180
    "Icon-App-76x76@1x.png" = 76
    "Icon-App-76x76@2x.png" = 152
    "Icon-App-83.5x83.5@2x.png" = 167
    "Icon-App-1024x1024@1x.png" = 1024
}
foreach ($app in $flutterApps) {
    $iosDir = "D:\HungerPoint\$app\ios\Runner\Assets.xcassets\AppIcon.appiconset"
    if (Test-Path $iosDir) {
        foreach ($name in $iosSizes.Keys) {
            $sz = $iosSizes[$name]
            Resize-Image $srcImage $sz $sz "$iosDir\$name"
        }
    }
}

# 4. Web icons in flutter apps
foreach ($app in $flutterApps) {
    $webDir = "D:\HungerPoint\$app\web"
    if (Test-Path $webDir) {
        Resize-Image $srcImage 192 192 "$webDir\icons\Icon-192.png"
        Resize-Image $srcImage 512 512 "$webDir\icons\Icon-512.png"
        Resize-Image $srcImage 192 192 "$webDir\icons\Icon-maskable-192.png"
        Resize-Image $srcImage 512 512 "$webDir\icons\Icon-maskable-512.png"
        Resize-Image $srcImage 32 32 "$webDir\favicon.png"
    }
}

# 5. hpadmin web app icons
Resize-Image $srcImage 512 512 "D:\HungerPoint\hpadmin\hpadmin\public\icon.png"
Resize-Image $srcImage 512 512 "D:\HungerPoint\hpadmin\hpadmin\public\logo.png"
Resize-Image $srcImage 32 32 "D:\HungerPoint\hpadmin\hpadmin\public\favicon.png"
Save-Ico $srcImage 48 48 "D:\HungerPoint\hpadmin\hpadmin\public\favicon.ico"

# 6. Windows ico if exists
if (Test-Path "D:\HungerPoint\hpwaiter\windows\runner\resources") {
    Save-Ico $srcImage 48 48 "D:\HungerPoint\hpwaiter\windows\runner\resources\app_icon.ico"
}

$srcImage.Dispose()
Write-Output "ALL ICONS GENERATED SUCCESSFULLY!"

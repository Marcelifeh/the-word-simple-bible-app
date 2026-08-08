param(
    [string]$InputDirectory = "docs/play-store/screenshots/raw",
    [string]$OutputDirectory = "docs/play-store/screenshots/final"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [System.Drawing.RectangleF]$Rectangle,
        [float]$Radius
    )

    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $diameter = $Radius * 2
    $arc = [System.Drawing.RectangleF]::new(
        $Rectangle.X,
        $Rectangle.Y,
        $diameter,
        $diameter
    )

    $path.AddArc($arc, 180, 90)
    $arc.X = $Rectangle.Right - $diameter
    $path.AddArc($arc, 270, 90)
    $arc.Y = $Rectangle.Bottom - $diameter
    $path.AddArc($arc, 0, 90)
    $arc.X = $Rectangle.X
    $path.AddArc($arc, 90, 90)
    $path.CloseFigure()
    return $path
}

function Save-Jpeg {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Path,
        [long]$Quality = 95
    )

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object MimeType -eq "image/jpeg" |
        Select-Object -First 1
    $parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
        [System.Drawing.Imaging.Encoder]::Quality,
        $Quality
    )
    $Bitmap.Save($Path, $codec, $parameters)
    $parameters.Dispose()
}

$screenshots = @(
    @{
        File = "01-home.jpg"
        Output = "01-grow-in-gods-word.jpg"
        Headline = "Grow in God's Word Every Day"
        Supporting = "A complete rhythm for daily faith"
        Accent = "violet"
    },
    @{
        File = "02-bible-reader.png"
        Output = "02-read-scripture.jpg"
        Headline = "Read Scripture. Go Deeper."
        Supporting = "Beautiful reading, built for focus"
        Accent = "cyan"
    },
    @{
        File = "03-devotional.jpg"
        Output = "03-daily-truth.jpg"
        Headline = "Daily Truth for Everyday Life"
        Supporting = "Scripture-centered insight for each day"
        Accent = "gold"
    },
    @{
        File = "04-logos-notes.png"
        Output = "04-capture-sermons.jpg"
        Headline = "Capture Sermons. Remember What Matters."
        Supporting = "Write, record, and revisit every message"
        Accent = "cyan"
    },
    @{
        File = "05-scripture-memory.jpg"
        Output = "05-hide-gods-word.jpg"
        Headline = "Hide God's Word in Your Heart"
        Supporting = "Review verses with active recall"
        Accent = "violet"
    },
    @{
        File = "06-word-studio.jpg"
        Output = "06-create-share-inspire.jpg"
        Headline = "Create. Share. Inspire."
        Supporting = "Turn truth into beautiful, shareable designs"
        Accent = "gold"
    }
)

$accentColors = @{
    violet = [System.Drawing.Color]::FromArgb(139, 83, 246)
    cyan = [System.Drawing.Color]::FromArgb(48, 193, 232)
    gold = [System.Drawing.Color]::FromArgb(241, 178, 61)
}

$inputRoot = Join-Path (Get-Location) $InputDirectory
$outputRoot = Join-Path (Get-Location) $OutputDirectory
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$missing = @()

foreach ($item in $screenshots) {
    $inputPath = Join-Path $inputRoot $item.File
    if (-not (Test-Path -LiteralPath $inputPath)) {
        $missing += $item.File
        continue
    }

    $source = [System.Drawing.Image]::FromFile($inputPath)
    try {
        # Samsung captures include a status bar and gesture/navigation bar. Removing
        # both keeps personal notification icons out of the public store artwork.
        $topCrop = [Math]::Min(96, [Math]::Floor($source.Height * 0.04))
        $bottomCrop = [Math]::Min(132, [Math]::Floor($source.Height * 0.055))
        $sourceRect = [System.Drawing.Rectangle]::new(
            0,
            $topCrop,
            $source.Width,
            $source.Height - $topCrop - $bottomCrop
        )

        $canvas = [System.Drawing.Bitmap]::new(1080, 1920)
        $graphics = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
            $graphics.Clear([System.Drawing.Color]::FromArgb(8, 14, 28))

            $accent = $accentColors[$item.Accent]
            $graphics.FillRectangle(
                [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 13, 22, 42)),
                0,
                0,
                1080,
                294
            )
            $graphics.FillRectangle(
                [System.Drawing.SolidBrush]::new($accent),
                72,
                252,
                132,
                8
            )

            $brandFont = [System.Drawing.Font]::new("Segoe UI Semibold", 22)
            $headlineSize = 56
            $headlineFont = [System.Drawing.Font]::new("Segoe UI Semibold", $headlineSize)
            while (
                $graphics.MeasureString($item.Headline, $headlineFont).Width -gt 936 -and
                $headlineSize -gt 28
            ) {
                $headlineFont.Dispose()
                $headlineSize -= 2
                $headlineFont = [System.Drawing.Font]::new("Segoe UI Semibold", $headlineSize)
            }
            $supportFont = [System.Drawing.Font]::new("Segoe UI", 24)
            $headlineFormat = [System.Drawing.StringFormat]::new()
            $headlineFormat.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
            try {
                $graphics.DrawString(
                    "THE WORD APP",
                    $brandFont,
                    [System.Drawing.SolidBrush]::new($accent),
                    [System.Drawing.RectangleF]::new(72, 42, 936, 38)
                )
                $graphics.DrawString(
                    $item.Headline,
                    $headlineFont,
                    [System.Drawing.Brushes]::White,
                    [System.Drawing.RectangleF]::new(72, 88, 936, 112),
                    $headlineFormat
                )
                $graphics.DrawString(
                    $item.Supporting,
                    $supportFont,
                    [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(196, 205, 220)),
                    [System.Drawing.RectangleF]::new(72, 202, 936, 42)
                )
            }
            finally {
                $brandFont.Dispose()
                $headlineFont.Dispose()
                $supportFont.Dispose()
                $headlineFormat.Dispose()
            }

            $availableHeight = 1540
            $availableWidth = 780
            $scale = [Math]::Min(
                $availableWidth / $sourceRect.Width,
                $availableHeight / $sourceRect.Height
            )
            $drawWidth = [float]($sourceRect.Width * $scale)
            $drawHeight = [float]($sourceRect.Height * $scale)
            $drawX = [float]((1080 - $drawWidth) / 2)
            $drawY = [float](314 + (($availableHeight - $drawHeight) / 2))
            $screenRect = [System.Drawing.RectangleF]::new($drawX, $drawY, $drawWidth, $drawHeight)
            $frameRect = [System.Drawing.RectangleF]::new(
                $drawX - 10,
                $drawY - 10,
                $drawWidth + 20,
                $drawHeight + 20
            )

            $shadowPath = New-RoundedRectanglePath `
                -Rectangle ([System.Drawing.RectangleF]::new(
                    $frameRect.X + 12,
                    $frameRect.Y + 18,
                    $frameRect.Width,
                    $frameRect.Height
                )) `
                -Radius 38
            $graphics.FillPath(
                [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(115, 0, 0, 0)),
                $shadowPath
            )
            $shadowPath.Dispose()

            $framePath = New-RoundedRectanglePath -Rectangle $frameRect -Radius 38
            $graphics.FillPath(
                [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(21, 29, 49)),
                $framePath
            )
            $graphics.DrawPath([System.Drawing.Pen]::new($accent, 3), $framePath)
            $framePath.Dispose()

            $screenPath = New-RoundedRectanglePath -Rectangle $screenRect -Radius 30
            $previousClip = $graphics.Clip
            $graphics.SetClip($screenPath)
            $graphics.DrawImage($source, $screenRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
            $graphics.Clip = $previousClip
            $screenPath.Dispose()

            $outputPath = Join-Path $outputRoot $item.Output
            Save-Jpeg -Bitmap $canvas -Path $outputPath
            Write-Host "Created $outputPath"
        }
        finally {
            $graphics.Dispose()
            $canvas.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

if ($missing.Count -gt 0) {
    Write-Warning "Missing raw screenshots: $($missing -join ', ')"
    exit 2
}

Write-Host "All six Play Store screenshots are ready in $outputRoot"

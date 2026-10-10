<# Regenerate original SuiteDock SVG artwork on Windows without external rendering libraries.
   The deliberately small SVG subset is rect, circle, polygon and polyline, with solid colours.
   Sources, including the geometric wordmark, are in docs/brand and assets/app-icons.
   Every render is generated from those sources; no upstream artwork is used. #>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$Root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$Culture = [Globalization.CultureInfo]::InvariantCulture
function Number($Node, [string]$Name, [double]$Default = 0) {
    $value = $Node.GetAttribute($Name)
    if (-not $value) { return $Default }
    return [double]::Parse($value, $Culture)
}
function Render([string]$Source, [string]$Out, [int]$Width = 0, [int]$Height = 0) {
    [xml]$xml = [IO.File]::ReadAllText($Source)
    $svg = $xml.DocumentElement
    $baseWidth = Number $svg 'width'; $baseHeight = Number $svg 'height'
    if (-not $Width) { $Width = [int]$baseWidth }
    if (-not $Height) { $Height = [int]$baseHeight }
    $bmp = [Drawing.Bitmap]::new($Width * 4, $Height * 4)
    $g = [Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.ScaleTransform([single]($Width * 4 / $baseWidth), [single]($Height * 4 / $baseHeight))
        foreach ($node in $svg.ChildNodes) {
            if ($node.NodeType -ne [Xml.XmlNodeType]::Element) { continue }
            $brush = $null; $pen = $null
            $fill = $node.GetAttribute('fill'); $stroke = $node.GetAttribute('stroke')
            if ($fill -and $fill -ne 'none') { $brush = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($fill)) }
            if ($stroke -and $stroke -ne 'none') {
                $pen = [Drawing.Pen]::new([Drawing.ColorTranslator]::FromHtml($stroke), [single](Number $node 'stroke-width' 1))
                $pen.LineJoin = [Drawing.Drawing2D.LineJoin]::Miter
            }
            try {
                switch ($node.LocalName) {
                    'rect' {
                        $rect = [Drawing.RectangleF]::new((Number $node 'x'), (Number $node 'y'), (Number $node 'width'), (Number $node 'height'))
                        if ($brush) { $g.FillRectangle($brush, $rect) }
                        if ($pen) { $g.DrawRectangle($pen, $rect.X, $rect.Y, $rect.Width, $rect.Height) }
                    }
                    'circle' {
                        $radius = Number $node 'r'
                        $rect = [Drawing.RectangleF]::new((Number $node 'cx') - $radius, (Number $node 'cy') - $radius, 2*$radius, 2*$radius)
                        if ($brush) { $g.FillEllipse($brush, $rect) }
                        if ($pen) { $g.DrawEllipse($pen, $rect) }
                    }
                    { $_ -in 'polygon', 'polyline' } {
                        [Drawing.PointF[]]$points = @($node.GetAttribute('points').Trim() -split '\s+' | ForEach-Object {
                            $pair = $_ -split ','
                            [Drawing.PointF]::new([single]::Parse($pair[0], $Culture), [single]::Parse($pair[1], $Culture))
                        })
                        if ($node.LocalName -eq 'polygon') {
                            if ($brush) { $g.FillPolygon($brush, $points) }
                            if ($pen) { $g.DrawPolygon($pen, $points) }
                        } elseif ($pen) { $g.DrawLines($pen, $points) }
                    }
                    default { throw "Unsupported SVG element: $($node.LocalName) in $Source" }
                }
            } finally { if ($brush) { $brush.Dispose() }; if ($pen) { $pen.Dispose() } }
        }
        $result = [Drawing.Bitmap]::new($Width, $Height)
        $down = [Drawing.Graphics]::FromImage($result)
        try {
            $down.CompositingMode = [Drawing.Drawing2D.CompositingMode]::SourceCopy
            $down.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $down.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $down.DrawImage($bmp, 0, 0, $Width, $Height)
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($Out)) | Out-Null
            $result.Save($Out, [Drawing.Imaging.ImageFormat]::Png)
        } finally { $down.Dispose(); $result.Dispose() }
    } finally { $g.Dispose(); $bmp.Dispose() }
}
$Brand = Join-Path $Root 'docs/brand'
$Icon = Join-Path $Root 'assets/app-icon'
$Mark = Join-Path $Brand 'suitedock-mark.svg'
$Id = 'io.github.ripdzl.suitedock'
foreach ($size in @(16,24,32,48,64,128,256,512)) {
    Render $Mark (Join-Path $Icon "hicolor/${size}x${size}/apps/$Id.png") $size $size
}
$Scalable = Join-Path $Icon 'hicolor/scalable/apps'
[IO.Directory]::CreateDirectory($Scalable) | Out-Null
Copy-Item -LiteralPath $Mark -Destination (Join-Path $Scalable "$Id.svg")
Copy-Item -LiteralPath $Mark -Destination (Join-Path $Icon 'suitedock.svg')
Render $Mark (Join-Path $Icon 'suitedock-1024.png') 1024 1024
Render $Mark (Join-Path $Brand 'suitedock-mark-64.png') 64 64
Render (Join-Path $Brand 'suitedock-mark-black.svg') (Join-Path $Brand 'suitedock-mark-black-44.png') 44 44
foreach ($variant in @('suitedock-logo', 'suitedock-logo-white')) {
    Render (Join-Path $Brand "$variant.svg") (Join-Path $Brand "$variant.png")
}
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root 'assets/app-icons') -Filter '*.svg') {
    Render $file.FullName ([IO.Path]::ChangeExtension($file.FullName, '.png')) 128 128
}
# Use a fresh temp directory and remove only that verified child of the system temp directory.
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$Temp = Join-Path $TempRoot ('suitedock-icons-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($Temp) | Out-Null
try {
    $sizes = @(16,20,24,32,40,48,64,128,256)
    $images = @($sizes | ForEach-Object {
        $file = Join-Path $Temp "ico-$_.png"
        Render $Mark $file $_ $_
        ,([IO.File]::ReadAllBytes($file))
    })
    $stream = [IO.MemoryStream]::new(); $writer = [IO.BinaryWriter]::new($stream)
    try {
        $writer.Write([uint16]0); $writer.Write([uint16]1); $writer.Write([uint16]$images.Count)
        $offset = 6 + 16 * $images.Count
        for ($i = 0; $i -lt $images.Count; $i++) {
            $dim = if ($sizes[$i] -eq 256) { 0 } else { $sizes[$i] }
            $writer.Write([byte]$dim); $writer.Write([byte]$dim); $writer.Write([uint16]0)
            $writer.Write([uint16]1); $writer.Write([uint16]32)
            $writer.Write([uint32]$images[$i].Length); $writer.Write([uint32]$offset)
            $offset += $images[$i].Length
        }
        foreach ($bytes in $images) { $writer.Write([byte[]]$bytes) }
        [IO.File]::WriteAllBytes((Join-Path $Icon 'suitedock.ico'), $stream.ToArray())
    } finally { $writer.Dispose(); $stream.Dispose() }
    $chunks = [IO.MemoryStream]::new(); $writer = [IO.BinaryWriter]::new($chunks)
    try {
        $types = @('icp4','icp5','icp6','ic07','ic08','ic09','ic10')
        $sizes = @(16,32,64,128,256,512,1024)
        for ($i = 0; $i -lt $types.Count; $i++) {
            $file = Join-Path $Temp "icns-$($sizes[$i]).png"
            Render $Mark $file $sizes[$i] $sizes[$i]
            $bytes = [IO.File]::ReadAllBytes($file)
            $writer.Write([Text.Encoding]::ASCII.GetBytes($types[$i]))
            $len = [BitConverter]::GetBytes([uint32]($bytes.Length + 8)); [Array]::Reverse($len)
            $writer.Write($len); $writer.Write($bytes)
        }
        $payload = $chunks.ToArray()
        $len = [BitConverter]::GetBytes([uint32]($payload.Length + 8)); [Array]::Reverse($len)
        $complete = [byte[]]([Text.Encoding]::ASCII.GetBytes('icns') + $len + $payload)
        [IO.File]::WriteAllBytes((Join-Path $Icon 'suitedock.icns'), $complete)
    } finally { $writer.Dispose(); $chunks.Dispose() }
} finally {
    $Resolved = [IO.Path]::GetFullPath($Temp)
    if (-not $Resolved.StartsWith($TempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($Resolved) -notlike 'suitedock-icons-*') { throw "Unexpected temporary path: $Resolved" }
    Remove-Item -LiteralPath $Resolved -Recurse -Force
}
Write-Output 'Original SuiteDock artwork regenerated.'

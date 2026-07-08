$root = Split-Path -Parent $PSScriptRoot
$htmlIn = Join-Path $root "proposal_input.html"
$pdfOut = Join-Path $root "proposal_output.pdf"

$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edge)) {
    $edge = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

$resolvedHtml = (Resolve-Path $htmlIn).Path
$uri = "file:///" + ($resolvedHtml -replace "\\", "/")
& $edge --headless --disable-gpu --allow-file-access-from-files --print-to-pdf="$pdfOut" --no-pdf-header-footer $uri
Start-Sleep -Seconds 2

if (Test-Path $pdfOut) {
    $size = (Get-Item $pdfOut).Length
    Write-Output "OK: $pdfOut ($size bytes)"
} else {
    Write-Output "FAILED"
}

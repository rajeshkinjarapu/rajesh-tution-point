$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path "lib\screens", "lib\widgets" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $originalContent = $content

    $content = $content.Replace('const Color(0xFF1E293B).withOpacity(0.7)', 'const Color(0xB21E293B)')
    $content = $content.Replace('const Color(0xFF64748B).withOpacity(0.7)', 'const Color(0xB264748B)')

    if ($content -cne $originalContent) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed opacity in $($file.FullName)"
    }
}
Write-Host "Opacity fixes complete!"

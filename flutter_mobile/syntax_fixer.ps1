$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path "lib\screens", "lib\widgets" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    $originalContent = $content

    # Fix lowercase properties that were ruined by case-insensitive replace
    $content = $content -creplace 'foregroundcolor:', 'foregroundColor:'
    $content = $content -creplace 'dropdowncolor:', 'dropdownColor:'
    $content = $content -creplace 'backgroundcolor:', 'backgroundColor:'
    $content = $content -creplace 'iconcolor:', 'iconColor:'
    $content = $content -creplace 'textcolor:', 'textColor:'
    $content = $content -creplace 'hovercolor:', 'hoverColor:'
    $content = $content -creplace 'splashcolor:', 'splashColor:'
    $content = $content -creplace 'highlightcolor:', 'highlightColor:'
    $content = $content -creplace 'cursorcolor:', 'cursorColor:'
    $content = $content -creplace 'focuscolor:', 'focusColor:'
    $content = $content -creplace 'dividercolor:', 'dividerColor:'

    # Fix 70 opacity syntaxes
    $content = $content -creplace 'const Color\(0xFF1E293B\)70', 'const Color(0xFF1E293B).withOpacity(0.7)'
    $content = $content -creplace 'const Color\(0xFF64748B\)70', 'const Color(0xFF64748B).withOpacity(0.7)'

    if ($content -cne $originalContent) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fixed syntax in $($file.FullName)"
    }
}
Write-Host "Syntax fixes complete!"

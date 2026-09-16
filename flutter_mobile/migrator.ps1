$ErrorActionPreference = "Stop"

$files = Get-ChildItem -Path "lib\screens", "lib\widgets" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $originalContent = [System.IO.File]::ReadAllText($file.FullName)
    $content = $originalContent

    # 1. Backgrounds
    $content = $content -replace 'color:\s*const\s*Color\(0xFF1E293B\)', 'color: Colors.white'

    # 2. Text colors
    $evaluator1 = [System.Text.RegularExpressions.MatchEvaluator] {
        param($m)
        $block = $m.Groups[0].Value
        $block = $block.Replace("color: Colors.white", "color: const Color(0xFF1E293B)")
        $block = $block.Replace("color: const Color(0xFFFFFFFF)", "color: const Color(0xFF1E293B)")
        $block = $block.Replace("color: const Color(0xFFE2E8F0)", "color: const Color(0xFF64748B)")
        $block = $block.Replace("color: const Color(0xFF94A3B8)", "color: const Color(0xFF475569)")
        return $block
    }
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'GoogleFonts\.[a-zA-Z]+\([^)]+\)', $evaluator1, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # 3. Icons
    $evaluator2 = [System.Text.RegularExpressions.MatchEvaluator] {
        param($m)
        $block = $m.Groups[0].Value
        $block = $block.Replace("color: Colors.white", "color: const Color(0xFF64748B)")
        $block = $block.Replace("color: const Color(0xFFE2E8F0)", "color: const Color(0xFF64748B)")
        return $block
    }
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, 'Icon\([^)]+\)', $evaluator2, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    if ($content -cne $originalContent) {
        [System.IO.File]::WriteAllText($file.FullName, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Updated $($file.FullName)"
    }
}
Write-Host "Migration Complete!"

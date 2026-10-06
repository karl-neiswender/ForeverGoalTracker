# Balance check for the Lua files when Python (tools/check.py) is not available, e.g. on the PC.
# Usage (PowerShell, repo root): & tools/balance.ps1 Core.lua
param([string]$path)
$s = [IO.File]::ReadAllText($path)
# strip long comments/strings, line comments, quoted strings
$s = [regex]::Replace($s, '--\[(=*)\[[\s\S]*?\]\1\]', ' ')
$s = [regex]::Replace($s, '\[(=*)\[[\s\S]*?\]\1\]', '""')
$sb = New-Object System.Text.StringBuilder
$i = 0; $n = $s.Length
while ($i -lt $n) {
  $c = $s[$i]
  if ($c -eq '-' -and $i + 1 -lt $n -and $s[$i+1] -eq '-') { while ($i -lt $n -and $s[$i] -ne "`n") { $i++ }; continue }
  if ($c -eq '"' -or $c -eq "'") {
    $q = $c; $i++
    while ($i -lt $n -and $s[$i] -ne $q) { if ($s[$i] -eq '\') { $i++ }; $i++ }
    $i++; [void]$sb.Append('""'); continue
  }
  [void]$sb.Append($c); $i++
}
$t = $sb.ToString()
$open = ([regex]::Matches($t, '\b(function|if|do|repeat)\b')).Count
# "while/for ... do" share one end via do; "elseif ... then" has no end
$close = ([regex]::Matches($t, '\b(end|until)\b')).Count
"{0}: blocks open {1} close {2} | {{ {3} }} {4} | ( {5} ) {6}" -f (Split-Path $path -Leaf), $open, $close, ($t.Split('{').Count-1), ($t.Split('}').Count-1), ($t.Split('(').Count-1), ($t.Split(')').Count-1)

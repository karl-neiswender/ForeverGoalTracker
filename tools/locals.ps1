param([string]$path)
# Rough count of active locals in a Lua file's main chunk (outside any
# function), tracking do/if/loop blocks so their locals are freed at "end".
$s = [IO.File]::ReadAllText($path)
$s = [regex]::Replace($s, '--\[(=*)\[[\s\S]*?\]\1\]', ' ')
$s = [regex]::Replace($s, '\[(=*)\[[\s\S]*?\]\1\]', '""')
$sb = New-Object System.Text.StringBuilder
$i = 0; $n = $s.Length
while ($i -lt $n) {
  $c = $s[$i]
  if ($c -eq '-' -and $i + 1 -lt $n -and $s[$i+1] -eq '-') { while ($i -lt $n -and $s[$i] -ne "`n") { $i++ }; continue }
  if ($c -eq '"' -or $c -eq "'") { $q = $c; $i++; while ($i -lt $n -and $s[$i] -ne $q) { if ($s[$i] -eq '\') { $i++ }; $i++ }; $i++; [void]$sb.Append('""'); continue }
  [void]$sb.Append($c); $i++
}
$t = $sb.ToString()
$toks = [regex]::Matches($t, '[A-Za-z_][A-Za-z0-9_]*|\n|,|=|\(|\)|\{|\}|\.|:|[^\sA-Za-z0-9_]')
$stack = New-Object System.Collections.ArrayList   # each: @{kind; locals}
$base = 0; $max = 0; $maxLine = 0; $line = 1; $pendingLoop = 0
function InFunc { foreach ($f in $stack) { if ($f.kind -eq 'function') { return $true } }; return $false }
function Active { $a = $script:base; foreach ($f in $script:stack) { $a += $f.locals }; return $a }
for ($k = 0; $k -lt $toks.Count; $k++) {
  $w = $toks[$k].Value
  if ($w -eq "`n") { $line++; continue }
  switch -CaseSensitive ($w) {
    'function' { [void]$stack.Add(@{kind='function'; locals=0}) }
    'if'       { [void]$stack.Add(@{kind='if'; locals=0}) }
    'for'      { [void]$stack.Add(@{kind='loop'; locals=0}); $pendingLoop++ }
    'while'    { [void]$stack.Add(@{kind='loop'; locals=0}); $pendingLoop++ }
    'repeat'   { [void]$stack.Add(@{kind='repeat'; locals=0}) }
    'do'       { if ($pendingLoop -gt 0) { $pendingLoop-- } else { [void]$stack.Add(@{kind='do'; locals=0}) } }
    'end'      { if ($stack.Count) { $stack.RemoveAt($stack.Count - 1) } }
    'until'    { if ($stack.Count) { $stack.RemoveAt($stack.Count - 1) } }
    'local' {
      if (-not (InFunc)) {
        $cnt = 0
        $j = $k + 1
        while ($j -lt $toks.Count -and $toks[$j].Value -eq "`n") { $j++ }
        if ($toks[$j].Value -eq 'function') { $cnt = 1 }
        else {
          while ($j -lt $toks.Count) {
            $v = $toks[$j].Value
            if ($v -eq '=' -or $v -eq "`n") { break }
            if ($v -match '^[A-Za-z_]') { $cnt++ }
            $j++
          }
        }
        if ($stack.Count) { $stack[$stack.Count - 1].locals += $cnt } else { $script:base += $cnt }
        $a = Active
        if ($a -gt $max) { $max = $a; $maxLine = $line }
      }
    }
  }
}
"{0}: max active main-chunk locals {1} (at line {2}); top-level total {3}; open blocks at end {4}" -f (Split-Path $path -Leaf), $max, $maxLine, $base, $stack.Count

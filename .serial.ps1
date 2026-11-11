$p = New-Object System.IO.Ports.SerialPort "COM14",115200
$p.DtrEnable=$false; $p.RtsEnable=$false
$p.Open(); $p.RtsEnable=$true; Start-Sleep -Milliseconds 200; $p.RtsEnable=$false; $end=(Get-Date).AddSeconds(30)
while((Get-Date) -lt $end){ $s=$p.ReadExisting(); if($s){[Console]::Write($s)}; Start-Sleep -Milliseconds 100 }
$p.Close()

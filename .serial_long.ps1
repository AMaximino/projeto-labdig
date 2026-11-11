$p = New-Object System.IO.Ports.SerialPort "COM14",115200
$p.DtrEnable=$false; $p.RtsEnable=$false
$p.Open(); $end=(Get-Date).AddSeconds(120)
while((Get-Date) -lt $end){ $s=$p.ReadExisting(); if($s){[Console]::Write($s)}; Start-Sleep -Milliseconds 100 }
$p.Close()

# Janela de teste do RC522 + ESP32 (requer o sketch rfid_test.ino gravado).
# Uso (Windows):  powershell -ExecutionPolicy Bypass -File rfid_test_gui.ps1 [-Port COM14]
param([string]$Port = "")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

if ($Port -eq "") {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames()
    if ($ports.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhuma porta COM encontrada. Conecte a ESP32.", "Teste RFID") | Out-Null
        exit 1
    }
    $Port = $ports[-1]
}

# ---------------- interface ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Teste RFID - ESP32 + RC522 ($Port)"
$form.Size = New-Object System.Drawing.Size(560, 520)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

$title = New-Object System.Windows.Forms.Label
$title.Text = "Teste do leitor RFID"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.AutoSize = $true
$form.Controls.Add($title)

$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 60)
$panel.Size = New-Object System.Drawing.Size(505, 150)
$form.Controls.Add($panel)

$instr = New-Object System.Windows.Forms.Label
$instr.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$instr.ForeColor = [System.Drawing.Color]::White
$instr.Dock = "Fill"
$instr.TextAlign = "MiddleCenter"
$panel.Controls.Add($instr)

$sub = New-Object System.Windows.Forms.Label
$sub.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$sub.Location = New-Object System.Drawing.Point(20, 218)
$sub.Size = New-Object System.Drawing.Size(505, 40)
$form.Controls.Add($sub)

$steps = New-Object System.Windows.Forms.Label
$steps.Font = New-Object System.Drawing.Font("Consolas", 10)
$steps.Location = New-Object System.Drawing.Point(20, 260)
$steps.Size = New-Object System.Drawing.Size(505, 90)
$form.Controls.Add($steps)

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = "Vertical"
$log.Font = New-Object System.Drawing.Font("Consolas", 9)
$log.Location = New-Object System.Drawing.Point(20, 355)
$log.Size = New-Object System.Drawing.Size(505, 70)
$form.Controls.Add($log)

$btnRetry = New-Object System.Windows.Forms.Button
$btnRetry.Text = "Repetir teste"
$btnRetry.Location = New-Object System.Drawing.Point(320, 435)
$btnRetry.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($btnRetry)

$btnClose = New-Object System.Windows.Forms.Button
$btnClose.Text = "Fechar"
$btnClose.Location = New-Object System.Drawing.Point(425, 435)
$btnClose.Size = New-Object System.Drawing.Size(100, 30)
$btnClose.Add_Click({ $form.Close() })
$form.Controls.Add($btnClose)

$C_BLUE  = [System.Drawing.Color]::FromArgb(37, 99, 235)
$C_AMBER = [System.Drawing.Color]::FromArgb(217, 119, 6)
$C_GREEN = [System.Drawing.Color]::FromArgb(22, 163, 74)
$C_RED   = [System.Drawing.Color]::FromArgb(220, 38, 38)
$C_GRAY  = [System.Drawing.Color]::FromArgb(100, 116, 139)

function Show-Step($text, $color, $hint) {
    $instr.Text = $text
    $panel.BackColor = $color
    $sub.Text = $hint
}
function Log($msg) {
    $log.AppendText((Get-Date -Format "HH:mm:ss") + "  " + $msg + "`r`n")
}

# ---------------- estado do teste ----------------
# Etapas: CONNECT -> APPROACH1 -> REMOVE -> APPROACH2 -> DONE / FAIL
$script:state = "CONNECT"
$script:deadline = (Get-Date).AddSeconds(6)
$script:uid1 = ""
$script:buffer = ""
$script:results = [ordered]@{
    "1. RC522 responde pelo SPI   " = "..."
    "2. Cartao detectado          " = "..."
    "3. Retirada detectada        " = "..."
    "4. Segunda leitura (mesmo UID)" = "..."
}
function Set-Result($index, $value) {
    $key = @($script:results.Keys)[$index]
    $script:results[$key] = $value
    $steps.Text = ($script:results.GetEnumerator() | ForEach-Object { "$($_.Key)  $($_.Value)" }) -join "`r`n"
}
function Fail($text, $hint) {
    $script:state = "FAIL"
    Show-Step $text $C_RED $hint
    Log "FALHOU: $text"
}
function Start-Test {
    $script:uid1 = ""
    for ($i = 0; $i -lt 4; $i++) { Set-Result $i "..." }
    $script:state = "CONNECT"
    $script:deadline = (Get-Date).AddSeconds(6)
    Show-Step "Conectando ao leitor..." $C_GRAY "Verificando se o RC522 responde."
    try { $serial.Write("V") } catch {}
}
function Wait-Card($label) {
    $script:deadline = (Get-Date).AddSeconds(20)
    Show-Step $label $C_BLUE "Encoste o cartao ou chaveiro no centro do leitor (ate ~3 cm). Tempo: 20 s."
}

$serial = New-Object System.IO.Ports.SerialPort $Port, 115200
$serial.DtrEnable = $false
$serial.RtsEnable = $false
$serial.NewLine = "`n"
try {
    $serial.Open()
} catch {
    [System.Windows.Forms.MessageBox]::Show("Nao foi possivel abrir $Port.`nFeche o Monitor Serial do Arduino IDE e tente de novo.`n`n$($_.Exception.Message)", "Teste RFID") | Out-Null
    exit 1
}
Log "Porta $Port aberta (115200 baud)."

function Handle-Line($line) {
    if ($line -eq "") { return }
    if ($line -notmatch '^(READY|ERROR|CARD|REMOVED)') { return }  # ignora mensagens de boot
    Log "ESP32: $line"
    $parts = $line.Split(" ")
    switch ($script:state) {
        "CONNECT" {
            if ($parts[0] -eq "READY") {
                Set-Result 0 "OK  (versao $($parts[1]))"
                $script:state = "APPROACH1"
                Wait-Card "APROXIME O CARTAO"
            } elseif ($parts[0] -eq "ERROR") {
                Set-Result 0 "FALHOU (versao $($parts[1]))"
                Fail "RC522 NAO RESPONDE" "Confira SDA->GPIO5, SCK->18, MOSI->23, MISO->19, RST->22, 3V3 e GND."
            }
        }
        "APPROACH1" {
            if ($parts[0] -eq "CARD") {
                $script:uid1 = $parts[1]
                Set-Result 1 "OK  (UID $($script:uid1))"
                $script:state = "REMOVE"
                $script:deadline = (Get-Date).AddSeconds(20)
                Show-Step "CARTAO LIDO! AGORA RETIRE" $C_AMBER "UID: $($script:uid1)   -   afaste o cartao do leitor."
            }
        }
        "REMOVE" {
            if ($parts[0] -eq "REMOVED") {
                Set-Result 2 "OK"
                $script:state = "APPROACH2"
                Wait-Card "APROXIME DE NOVO"
            }
        }
        "APPROACH2" {
            if ($parts[0] -eq "CARD") {
                if ($parts[1] -eq $script:uid1) {
                    Set-Result 3 "OK  (UID $($parts[1]))"
                    $script:state = "DONE"
                    Show-Step "RFID FUNCIONANDO" $C_GREEN "UID do cartao: $($script:uid1)   (anote para o config.h)"
                    Log "SUCESSO. UID = $($script:uid1)"
                } else {
                    Set-Result 3 "UID diferente ($($parts[1]))"
                    $script:state = "DONE"
                    Show-Step "LEU OUTRO CARTAO" $C_AMBER "1a leitura $($script:uid1), 2a leitura $($parts[1]). Leitor OK; use o mesmo cartao para comparar."
                }
            }
        }
    }
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 100
$timer.Add_Tick({
    try {
        $script:buffer += $serial.ReadExisting()
    } catch {
        $timer.Stop()
        Fail "CONEXAO PERDIDA" "A porta $Port foi desconectada."
        return
    }
    while (($idx = $script:buffer.IndexOf("`n")) -ge 0) {
        $line = $script:buffer.Substring(0, $idx).Trim()
        $script:buffer = $script:buffer.Substring($idx + 1)
        Handle-Line $line
    }
    if ($script:state -in @("CONNECT", "APPROACH1", "REMOVE", "APPROACH2")) {
        $left = [int][Math]::Ceiling(($script:deadline - (Get-Date)).TotalSeconds)
        if ($left -le 0) {
            switch ($script:state) {
                "CONNECT"   { Set-Result 0 "SEM RESPOSTA"; Fail "ESP32 NAO RESPONDE" "Grave esp/tools/rfid_test/rfid_test.ino e confira a porta $Port." }
                "APPROACH1" { Set-Result 1 "NAO DETECTADO"; Fail "NENHUM CARTAO LIDO" "RC522 responde, mas nao leu o cartao. Aproxime mais ou teste outro cartao (13,56 MHz / MIFARE)." }
                "REMOVE"    { Set-Result 2 "NAO DETECTADA"; Fail "CARTAO NAO FOI RETIRADO" "Afaste o cartao do leitor e repita." }
                "APPROACH2" { Set-Result 3 "NAO DETECTADO"; Fail "SEGUNDA LEITURA FALHOU" "A primeira leitura funcionou; a leitura pode estar instavel (mau contato ou distancia)." }
            }
        } elseif ($script:state -ne "CONNECT") {
            $sub.Text = ($sub.Text -replace "Tempo: \d+ s\.?$", "") + $(if ($script:state -ne "REMOVE") { "Tempo: $left s." } else { "" })
        }
    }
})

$btnRetry.Add_Click({ Log "Repetindo teste."; Start-Test })
$form.Add_Shown({ Start-Test; $timer.Start() })
$form.Add_FormClosed({ $timer.Stop(); if ($serial.IsOpen) { $serial.Close() } })
[void]$form.ShowDialog()

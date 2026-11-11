@echo off
cd /d "%~dp0fpga\quartus"
"C:\intelFPGA_lite\24.1std\quartus\bin64\quartus_sh.exe" --flow compile projeto_labdig -c circuito_jogo_financeiro > "%~dp0.quartus.log" 2>&1
echo exit=%ERRORLEVEL% >> "%~dp0.quartus.log"

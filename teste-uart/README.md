# Teste UART FPGA -> ESP8266

Sketch minimo para verificar a recepcao UART da FPGA no ESP8266. Os bytes
recebidos sao encaminhados sem alteracao para a serial USB; nao usa Wi-Fi,
MQTT ou outras bibliotecas alem da `SoftwareSerial` incluida no pacote ESP8266.

## Preparacao

1. Abra `teste-uart.ino` na Arduino IDE, selecione sua placa ESP8266 e grave.
2. Conecte `uart_tx` da FPGA ao GPIO14 (D5 em NodeMCU/D1 mini) do ESP8266 e
   conecte os GNDs. Confira que o sinal UART da FPGA e compativel com 3,3 V;
   nao conecte sinais de 5 V diretamente ao ESP8266.
3. Abra o Monitor Serial em **115200 baud**.
4. Execute a FPGA. Os quadros CSV enviados aparecerao no Monitor Serial.

A comunicacao FPGA -> ESP8266 usa **115200 baud, 8-N-1**. O pino de recepcao
pode ser alterado em `FPGA_RX_PIN` no inicio do sketch.

# Teste da telemetria UART no ESP32

Este sketch recebe os quadros de telemetria UART da FPGA usando a UART de
hardware 2 do ESP32 e os encaminha sem alteracao para o Monitor Serial USB. Nao
usa Wi-Fi nem MQTT.

## Como testar

1. Abra `teste-uart-esp32.ino` na Arduino IDE e selecione a placa ESP32 correta.
2. Ligue `uart_tx` da FPGA ao pino **GPIO16 (RX2)** do ESP32.
3. Ligue o GND da FPGA ao GND do ESP32. Deixe o TX do ESP32 desconectado.
4. Grave o sketch e abra o Monitor Serial em **115200 baud**.
5. Gere eventos na FPGA; cada quadro recebido deve aparecer como uma linha CSV.

O sketch configura a UART da FPGA em **115200 baud, 8-N-1**. O pino RX inicial
e definido por `FPGA_RX_PIN` no sketch. GPIO16 esta disponivel em muitas placas
ESP32 classicas, mas a disponibilidade depende do modelo; se sua placa nao o
expor ou o reservar para outro recurso, altere `FPGA_RX_PIN` para um GPIO livre
que aceite entrada. Use a UART de hardware 2 (`HardwareSerial(2)`), sem
`SoftwareSerial`.

Os sinais devem ser compativeis com **3,3 V**. Nao conecte sinal de 5 V ao
ESP32. Compartilhe o GND, mas nao conecte VCC entre a FPGA e o ESP32.

Se nao aparecerem linhas legiveis, confirme o pino RX, o GND comum e que a UART
da FPGA tambem esta configurada para 115200 baud, 8-N-1.

## Formato recebido

O quadro e uma linha CSV terminada por `LF` (`\n`):

```text
AEF1,sequencia,event_code,item_id,saldo,salario,investimento,gastos_fixos,gastos_unicos,inventario,rodada,jogada,status
```

Para a descricao dos campos, codigos de evento, status e um exemplo decodificado,
consulte o [README do teste UART geral](../teste-uart/README.md#formato-recebido).

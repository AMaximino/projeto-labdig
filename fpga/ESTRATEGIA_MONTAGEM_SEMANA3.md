# Estratégia de montagem e validação — semana 3

## Objetivo

Integrar o leitor RC522 à ESP32 e enviar o item reconhecido para a DE0-CV.
A FPGA permanece responsável por aceitar ou recusar a compra, atualizar saldo
e inventário e emitir a telemetria. O painel não envia comandos ao jogo.

## Plano de montagem

1. **Validar cada placa separadamente.** Grave o leitor UID da ESP32 e confirme
   a leitura dos cartões pelo Monitor Serial. Depois grave o firmware integrado
   com `config.h` preenchido a partir de `esp/aef_bridge/config.example.h`.
2. **Configurar o Quartus.** Abra `fpga/quartus/projeto_labdig.qpf`, selecione a
   revisão DE0-CV indicada no projeto e compile. Confirme no QSF `rfid_rx` em
   `PIN_C15`/`GPIO_1_D22` e `uart_tx` em `PIN_A14`/`GPIO_1_D20`.
3. **Desenergizar antes de ligar fios.** Conecte o RC522 à ESP32 conforme a
   pinagem de `GUIA_IMPLEMENTACAO_FISICA_E_INTERFACE.md`. Conecte depois a UART
   ESP32–FPGA e GND comum; não interligue os pinos VCC das placas.
4. **Carregar o jogo.** Programe a DE0-CV com o arquivo de programação produzido
   pelo Quartus. Os fios UART da ESP32 (GPIO16/17) podem ficar ligados durante a
   gravação do firmware, porque o USB usa outra UART.
5. **Validar por etapas.** Rode a suíte ModelSim da semana 3; em seguida
   confirme a inicialização do jogo, aproxime um cartão cadastrado e observe o
   item no inventário e o evento de compra. Teste também uma compra sem saldo
   (deve ser aprovada, deixar o saldo negativo e levar a `FIM_FALENCIA`) e um
   item já adquirido (deve ser recusado). Isso confirma que a decisão continua na FPGA.
6. **Validar telemetria e painel.** Com o broker MQTT acessível pelas duas
   placas, inicie o backend, abra o painel e confira o evento e o snapshot. Não
   use UID real em logs ou capturas compartilhadas.

## Ligações

| Origem | Destino | Sinal / pino | Observação |
|---|---|---|---|
| RC522 SDA/SS | ESP32 GPIO5 | SPI | Seletor do leitor |
| RC522 SCK | ESP32 GPIO18 | SPI | Clock SPI |
| RC522 MOSI | ESP32 GPIO23 | SPI | Dados ESP → leitor |
| RC522 MISO | ESP32 GPIO19 | SPI | Dados leitor → ESP |
| RC522 RST | ESP32 GPIO22 | Reset | |
| RC522 3.3V/GND | ESP32 3V3/GND | Alimentação | Somente 3,3 V |
| ESP32 TX2/GPIO17 | DE0-CV JP2 GPIO_1_D22/PIN_C15 | `rfid_rx` | Comando `RNN\n` |
| DE0-CV JP2 GPIO_1_D20/PIN_A14 | ESP32 RX2/GPIO16 | `uart_tx` | Telemetria `AEF1` |
| GND ESP32 | GND DE0-CV | Referência comum | Necessário para UART |

UART entre ESP32 e FPGA: 115200 baud, 8-N-1, níveis lógicos de 3,3 V.
Confirme o nome dos pinos no manual da revisão da placa antes de ligar. Não
aplique 5 V aos GPIOs nem conecte/desconecte fios com as placas energizadas.

## Simulação da semana 3

Na raiz do repositório, com ModelSim/QuestaSim instalado:

```tcl
vsim -do fpga/testbench/semana3/run_semana3.do
```

A suíte verifica a faixa e o latch do comando RFID e as transições principais
da FSM (início, ação, despesa, rodada, falência, fim de jogo e seleção de
display). Consulte [os diagramas de estados](testbench/semana3/DIAGRAMA_ESTADOS_SEMANA3.md).

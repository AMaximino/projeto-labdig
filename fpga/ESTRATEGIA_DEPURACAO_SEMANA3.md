# Estratégia de depuração — semana 3

## Objetivo

Esta estratégia orienta a identificação de falhas na integração RFID, FPGA e
telemetria. A depuração será feita por etapas, começando pela montagem e
comunicação física, avançando para a lógica RTL e, por fim, para o envio dos
eventos ao sistema. A FPGA permanece responsável pelas regras de compra, saldo
e inventário.

## Sinais observados

O circuito não possui uma saída dedicada de depuração. Serão usados os sinais
funcionais já disponíveis:

| Sinal | Uso na depuração |
|---|---|
| `rfid_rx` | Recebe o comando `RNN\n` da ESP8266, em 115200 baud, 8-N-1. O repouso UART é nível alto. |
| `uart_tx` | Envia quadros de telemetria `AEF1` para a ESP8266, em 115200 baud, 8-N-1. |
| `indicador_itens[9:0]` | Indica no conjunto de LEDs os itens registrados no inventário. |
| `display_jogadas` e `display_rodadas` | Permitem conferir visualmente o avanço de jogadas e rodadas. |
| `display_dinheiro` | Apresenta o valor financeiro nos displays de sete segmentos. |
| `ultima_jogada`, `ultima_rodada` | Indicam o fim de jogada e de rodada. |
| `terminou`, `perdeu` | Indicam os estados terminais de conclusão e falência. |

No QSF atual, `rfid_rx` está em GPIO_1_D22/PIN_C15 e `uart_tx` em
GPIO_1_D20/PIN_A14, ambos configurados como 3,3 V LVTTL. O estado da FSM,
`rfid_item_valid`, `rfid_ack` e os sinais de telemetria são internos; serão
observados no ModelSim/QuestaSim ou, se necessário, por uma captura temporária
no SignalTap II. Não se prevê ligar sinais internos a pinos físicos.

## Instrumentação de bancada

O Analog Discovery ou analisador lógico será conectado como observador: GND
comum e entrada digital de alta impedância em `rfid_rx` ou `uart_tx`. O
decodificador será configurado para 115200 baud, 8-N-1, idle alto; espera-se
`RNN\n` na entrada RFID e uma linha `AEF1` na telemetria. O tempo de bit
esperado é aproximadamente 8,68 µs.

O osciloscópio será usado para verificar nível, ruído e temporização da UART,
com ponta de alta impedância e referência ao GND. O multímetro será usado para
verificar continuidade com as placas desligadas e tensão de alimentação nos
pontos indicados pelos manuais. Nenhum instrumento será configurado para dirigir
uma linha que já esteja conectada a uma saída ativa.

## Procedimento

1. Registrar o sintoma e conferir, com a bancada desligada, pinagem, GND comum,
   continuidade e alimentação prevista para cada placa.
2. Confirmar no Quartus o top-level, a revisão da DE0-CV e as atribuições do
   QSF; compilar antes de programar a FPGA.
3. Executar primeiro os testes da semana 3 e, depois, a suíte FPGA existente:

   ```tcl
   vsim -do fpga/testbench/semana3/run_semana3.do
   vsim -do fpga/testbench/run_all.do
   ```

4. Capturar `rfid_rx`. Se não houver quadro, verificar RC522, cadastro do cartão
   e firmware ESP8266. Se o quadro estiver correto, mas não for aceito, conferir
   baud, formato, nível lógico e parser RFID.
5. Se o comando for aceito, acompanhar no simulador ou SignalTap
   `rfid_item_valid`, `rfid_ack`, `w_acao_pulso` e `w_estado`. Confirmar que a
   ação percorre o caminho normal da FSM e que o inventário e os displays
   correspondem ao resultado esperado.
6. Capturar `uart_tx`. Caso o jogo atualize, mas não haja telemetria, verificar
   os sinais internos de envio e evento. Se o quadro sair corretamente, seguir
   a investigação na ESP8266, MQTT, backend e painel.

No ModelSim/QuestaSim, os sinais internos serão adicionados à janela Wave. Na
placa, uma captura SignalTap será temporária e usará o clock adequado ao domínio
observado. A versão instrumentada será mantida separada da versão de produção.

## Alterações e regressão

As alterações lógicas serão feitas somente após localizar a primeira divergência
e reproduzi-la em teste. Será modificado um bloco por vez, com atualização do
testbench correspondente. Alterações na montagem também serão pontuais: a
bancada deve estar desligada, e a ligação deve ser conferida no QSF e no manual
antes de energizar novamente.

Após cada alteração, serão repetidos os testbenches direcionados, os testes da
semana 3 e a suíte FPGA existente. A validação final inclui compilação no
Quartus, conferência de avisos de pino e verificação de que controles, displays,
compra, inventário, UART e sinais terminais continuam operacionais. As placas
devem permanecer desligadas durante mudanças de fios; usar GND comum, fontes
separadas e níveis compatíveis com 3,3 V.

## Referências

- [RTL, pinos e simulação FPGA](README.md)
- [Estratégia de montagem da semana 3](ESTRATEGIA_MONTAGEM_SEMANA3.md)
- [Testbenches FPGA](testbench/README.md)
- [Diagramas de estados da semana 3](testbench/semana3/DIAGRAMA_ESTADOS_SEMANA3.md)
- [Guia de montagem e execução](../GUIA_IMPLEMENTACAO_FISICA_E_INTERFACE.md)

# Diagramas de estados — semana 3

Diagramas derivados da RTL presente em `fpga/rtl/`. O primeiro descreve a FSM
de jogo em `unidade_controle.v`; o segundo, a recepção UART de
`rfid_uart_rx.v`.

## Unidade de controle do jogo

![Máquina de estados da unidade de controle — semana 3](maquina-estados-semana3.png)

Em `ESPERA_ACAO`, `acao_pulso` tem prioridade sobre `display_pulso`, conforme a
ordem das condições na RTL.

```mermaid
stateDiagram-v2
    [*] --> INICIO
    INICIO --> ESPERA_INICIO
    ESPERA_INICIO --> ESPERA_INICIO: !iniciar
    ESPERA_INICIO --> INICIALIZA_JOGO: iniciar
    INICIALIZA_JOGO --> PREPARA_JOGO
    PREPARA_JOGO --> ESPERA_ACAO

    ESPERA_ACAO --> REGISTRA_ACAO: acao_pulso
    ESPERA_ACAO --> REGISTRA_DISPLAY: !acao_pulso && display_pulso
    ESPERA_ACAO --> ESPERA_ACAO: sem entrada
    REGISTRA_ACAO --> PROCESSA_ACAO
    PROCESSA_ACAO --> VERIFICA_FALENCIA
    VERIFICA_FALENCIA --> FIM_FALENCIA: fim_perdeu
    VERIFICA_FALENCIA --> VERIFICA_JOGADA: !fim_perdeu
    VERIFICA_JOGADA --> APLICA_DESPESA: eh_jogada
    VERIFICA_JOGADA --> ESPERA_ACAO: !eh_jogada
    APLICA_DESPESA --> VERIFICA_FALENCIA_DESPESA
    VERIFICA_FALENCIA_DESPESA --> FIM_FALENCIA: fim_perdeu
    VERIFICA_FALENCIA_DESPESA --> VERIFICA_FIM_JOGO: !fim_perdeu
    VERIFICA_FIM_JOGO --> FIM_JOGO: fim_jogo
    VERIFICA_FIM_JOGO --> VERIFICA_FIM_RODADA: !fim_jogo
    VERIFICA_FIM_RODADA --> AVANCA_RODADA: fim_rodada
    VERIFICA_FIM_RODADA --> AVANCA_JOGADA: !fim_rodada
    AVANCA_JOGADA --> ESPERA_ACAO
    AVANCA_RODADA --> ESPERA_ACAO

    REGISTRA_DISPLAY --> ESPERA_ACAO

    FIM_JOGO --> INICIALIZA_JOGO: iniciar
    FIM_JOGO --> REGISTRA_DISPLAY_FINAL: !iniciar && display_pulso
    FIM_JOGO --> FIM_JOGO: !iniciar && !display_pulso
    REGISTRA_DISPLAY_FINAL --> FIM_JOGO

    FIM_FALENCIA --> INICIALIZA_JOGO: iniciar
    FIM_FALENCIA --> REGISTRA_DISPLAY_FALENCIA: !iniciar && display_pulso
    FIM_FALENCIA --> FIM_FALENCIA: !iniciar && !display_pulso
    REGISTRA_DISPLAY_FALENCIA --> FIM_FALENCIA
```

## Receptor UART RFID

O receptor amostra UART 8-N-1 e monta os bytes em ordem LSB-first. A validação
dos bytes compõe o comando `RNN\n`; somente itens de `01` a `10` elevam
`item_valid`. O acknowledge limpa `item_valid` de forma sincronizada; enquanto
o comando continua pendente, novos starts são ignorados.

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> START: rx_sync == 0 && !item_valid
    IDLE --> IDLE: rx_sync == 1 || item_valid
    START --> DATA: amostra central continua baixa
    START --> IDLE: falso start
    DATA --> DATA: amostra bit 0..6
    DATA --> STOP: amostra bit 7
    STOP --> IDLE: stop válido / avaliar byte e avançar comando
    STOP --> IDLE: stop inválido / descartar comando parcial
```

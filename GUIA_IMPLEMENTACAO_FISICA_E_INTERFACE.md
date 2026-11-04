# Guia de implementação física e conexão com a interface web

Este guia descreve a cadeia de telemetria da partida:

```text
Controles → FPGA (uart_tx) → UART → ESP8266 → Wi-Fi/MQTT
          → backend → WebSocket → painel web
```

A FPGA continua executando as regras do jogo. A ESP8266 envia os eventos pela
rede, e a interface apenas os apresenta: não há comandos de retorno do painel
para a FPGA.

> **Atenção: não conecte o sinal à FPGA antes de concluir a etapa 2.** O módulo
> superior já tem a saída `uart_tx`, mas o arquivo Quartus
> `quartus/circuito_jogo_financeiro.qsf` ainda não atribui essa saída a um pino
> físico. O dispositivo definido no projeto é `5CEBA4F23C7`, mas isso, sozinho,
> não identifica qual pino do conector da sua placa deve ser usado. Confirme o
> modelo/revisão da placa, o conector e a tensão de I/O no manual e na pinagem
> correspondente. Não escolha um pino por tentativa.

## 1. Materiais e requisitos

- Placa FPGA do projeto e seu cabo/fonte de programação e alimentação.
- Placa ESP8266, por exemplo NodeMCU ou D1 mini, com cabo USB e alimentação
  apropriada.
- Fios jumper para `uart_tx` e GND.
- Computador na mesma rede local do ESP8266, para executar o broker MQTT,
  o backend e o painel. Esses serviços também podem ser distribuídos por
  computadores diferentes na mesma rede.
- Arduino IDE, pacote de placas ESP8266 e biblioteca `PubSubClient`.
- Node.js 20 ou superior e um broker MQTT acessível pela rede.
- Opcional: analisador lógico com entrada de alta impedância para observar a
  UART.

## 2. Atribuir e validar o pino da FPGA

1. Abra o projeto Quartus em `quartus/projeto_labdig.qpf` e confirme
   o modelo e a revisão da sua placa. Consulte o manual e
   `configuracoes_e_pinagens/` para localizar um pino de expansão livre e
   compatível com UART.
2. Confira que o pino escolhido não está conectado a outro componente da placa
   nem atribuído a outro sinal no QSF. Não use pinos de clock, configuração,
   alimentação ou pinos reservados.
3. Adicione a atribuição do pino escolhido ao QSF, substituindo o marcador pelo
   pino **confirmado no manual**:

   ```tcl
   set_location_assignment <PINO_CONFIRMADO> -to uart_tx
   ```

4. Configure o padrão elétrico de I/O conforme a documentação da placa e do
   banco ao qual o pino pertence. A entrada da ESP8266 exige sinal compatível
   com 3,3 V. Se os níveis não forem compatíveis, use um conversor de nível
   apropriado; nunca aplique 5 V à entrada da ESP8266.
5. Compile o projeto no Quartus e resolva erros ou avisos de pino não atribuído,
   conflito ou padrão elétrico antes de programar a FPGA.
6. Programe a FPGA pelo procedimento normal da placa. Mantenha a saída `uart_tx`
   desconectada da ESP8266 enquanto valida a compilação e a tensão do pino.

O transmissor está configurado para 115200 baud, 8 bits, sem paridade e 1 stop
bit (8-N-1). A linha permanece em nível alto quando ociosa.

## 3. Preparar e gravar o firmware da ESP8266

1. Na Arduino IDE, instale o pacote de placas **ESP8266 by ESP8266 Community**
   e a biblioteca **PubSubClient**.
2. Duplique `esp8266/aef_bridge/config.example.h` como
   `esp8266/aef_bridge/config.h`. Esse arquivo contém configurações locais e
   não deve ser publicado.
3. Edite o arquivo local:
   - `AEF_WIFI_SSID` e `AEF_WIFI_PASSWORD`: rede Wi-Fi que alcança o broker.
   - `AEF_MQTT_HOST` e `AEF_MQTT_PORT`: endereço do computador/servidor do
     broker e sua porta TCP (normalmente `1883`). **Não use `localhost`** aqui:
     para a ESP8266, `localhost` é a própria placa.
   - `AEF_MQTT_USERNAME` e `AEF_MQTT_PASSWORD`: credenciais, se usadas.
   - `AEF_DEVICE_ID`: identificador único para a placa.
   - `AEF_FPGA_RX_PIN`: GPIO da ESP8266 ligado ao TX da FPGA. O exemplo usa
     GPIO14 (D5 em algumas placas NodeMCU/D1 mini); confirme o mapeamento e o
     suporte a `SoftwareSerial` no modelo utilizado.
4. Abra `esp8266/aef_bridge/aef_bridge.ino`, selecione a placa e a porta serial
   corretas e grave o firmware.
5. Abra o monitor serial a 115200 baud. Ele deve mostrar que a ponte iniciou;
   depois, deve indicar as conexões Wi-Fi/MQTT e os eventos UART recebidos.

A ESP8266 recebe a UART por `SoftwareSerial`, enquanto a serial USB (`Serial`)
fica disponível para diagnóstico. Se houver perda de caracteres durante o uso
do Wi-Fi, teste a recepção no modelo exato da placa; o README do firmware
descreve alternativas de UART e suas limitações.

## 4. Iniciar o broker MQTT e o backend

1. Inicie um broker MQTT, por exemplo Mosquitto, em um computador alcançável
   tanto pela ESP8266 quanto pelo backend. Configure o listener para a rede
   local e libere a porta TCP do broker no firewall apenas para a rede
   necessária.
2. Use o tópico `aventura_financeira/telemetria`. Para desenvolvimento, a
   ESP8266 e o backend devem conseguir publicar/assinar nesse tópico.
3. Entre na pasta `backend/`, instale as dependências e inicie o servidor,
   apontando para o broker. Se o broker estiver no mesmo computador:

   Linux/macOS:

   ```sh
   cd backend
   npm install
   MQTT_URL=mqtt://localhost:1883 npm start
   ```

   PowerShell:

   ```powershell
   cd backend
   npm install
   $env:MQTT_URL = "mqtt://localhost:1883"
   npm start
   ```

   Se o broker estiver em outro computador, substitua `localhost` pelo
   endereço desse servidor em `MQTT_URL` e em `AEF_MQTT_HOST`.
4. Verifique o backend em `http://localhost:3000/health`. A resposta deve
   indicar `"status":"ok"` e, quando a conexão estiver pronta,
   `"mqtt_connected":true`.
5. Se o broker oferecer uma ferramenta cliente, assine
   `aventura_financeira/telemetria` para verificar a chegada de mensagens JSON.

> **Segurança:** a configuração atual do backend é para desenvolvimento local:
> ele não configura autenticação MQTT, TLS ou autorização. Para o fluxo descrito
> neste guia, use um broker isolado em uma rede confiável e não exponha as
> portas MQTT/HTTP/WebSocket à internet. Embora o firmware aceite credenciais
> MQTT, o backend atual não tem configuração para elas; um broker que exige
> autenticação requer uma alteração do backend antes de conectar.

## 5. Conectar fisicamente a FPGA à ESP8266

Desligue as placas antes de fazer a ligação. Depois de confirmar o pino, o
padrão elétrico e a compatibilidade de tensão, faça estas conexões:

Mantenha os botões, seletores e demais periféricos do jogo ligados à FPGA
conforme a pinagem da placa e o projeto atual. A ESP8266 não substitui esses
controles; ela recebe apenas a telemetria da FPGA.

| Origem | Destino | Observação |
|---|---|---|
| Pino FPGA atribuído a `uart_tx` | GPIO definido em `AEF_FPGA_RX_PIN` da ESP8266 | Saída TX da FPGA para entrada RX da ESP; somente esse sentido de dados. |
| GND da FPGA | GND da ESP8266 | Referência elétrica comum obrigatória. |
| Fonte/USB da FPGA | Alimentação da placa FPGA | Usar a fonte prevista pelo fabricante. |
| USB/fonte da ESP8266 | Alimentação da ESP8266 | Usar a alimentação prevista para o modelo da placa. |

Não conecte TX da ESP8266 à FPGA: esta implementação é unidirecional. Não
alimente a ESP8266 pelo pino `uart_tx` e não una os pinos VCC das duas placas.
Uma sonda lógica opcional pode ser ligada em paralelo ao sinal TX, com sua
referência GND no GND comum e somente após confirmar os limites elétricos do
instrumento.

Confira novamente as ligações antes de ligar as placas. Se tiver qualquer
dúvida sobre o pino, o banco de I/O ou a tensão, pare e consulte o manual da
placa ou uma pessoa qualificada em hardware.

## 6. Servir a interface e conectar ao backend

1. Mantenha o backend ativo.
2. Na raiz do repositório, sirva a pasta `frontend`:

   ```sh
   python3 -m http.server 8000 --directory frontend
   ```

3. No mesmo computador, abra `http://localhost:8000` em um navegador de
   computador. O painel requer uma janela com pelo menos 1100 pixels de largura.
4. Na interface, abra **Conexão de dados**, selecione **Backend do jogo** e
   informe:

   ```text
   ws://localhost:3000/ws/telemetria
   ```

   Se o navegador estiver em outro computador, troque `localhost` pelo IP ou
   nome de rede do computador onde o backend está executando. Os computadores
   precisam estar na mesma rede, e o firewall deve permitir a porta TCP `3000`.
5. Clique em **Conectar**. A interface deve indicar a conexão com o backend e
   aguardar dados do jogo. Faça uma ação física na partida: quando a FPGA
   transmitir um evento, o backend o encaminhará e o painel atualizará os
   indicadores e o histórico.

O modo recomendado é **Backend do jogo**. A opção **Broker MQTT direto** é para
testes/compatibilidade e exige um endpoint MQTT sobre WebSocket (`ws://` ou
`wss://`); a porta MQTT TCP `1883` não pode ser usada diretamente no navegador.

## 7. Verificação por etapas e diagnóstico

Verifique cada trecho separadamente para localizar falhas:

1. **FPGA:** confirme que o projeto compila, foi programado e que `uart_tx` foi
   atribuído ao pino físico correto. Um analisador lógico compatível pode
   confirmar atividade UART em 115200 baud, 8-N-1.
2. **UART/ESP8266:** abra o monitor serial a 115200 baud e faça uma ação. A
   mensagem `Evento ... recebido e enfileirado` indica que a ESP8266 reconheceu
   um quadro. `Linha UART rejeitada` indica que o quadro recebido não passou
   pela validação do protocolo.
3. **Wi-Fi/MQTT:** confira no monitor serial se a ESP8266 se conectou à rede e
   ao broker. Verifique IP, porta, credenciais, tópico e regras do firewall.
4. **Backend:** confira `http://localhost:3000/health`, os logs do processo e
   `backend/data/events.jsonl`. Payloads rejeitados aparecem no log do backend.
5. **WebSocket/interface:** confira o endereço informado, a porta `3000`, o
   firewall e o indicador de conexão. Se o navegador estiver em outra máquina,
   não use `localhost` para o backend.

Se a interface estiver conectada antes de a partida enviar um evento, ela pode
mostrar os dados de demonstração ou aguardar atualizações; execute uma ação no
jogo para verificar a telemetria ao vivo. O painel é somente leitura: continue
usando os controles físicos conectados à FPGA para jogar.

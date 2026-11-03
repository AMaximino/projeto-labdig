# Backend de telemetria

Subscriber MQTT e servidor WebSocket somente de leitura para o painel web.

## Executar localmente

Requer Node.js 20+ e um broker MQTT acessivel. Na pasta `backend/`:

```sh
npm install
MQTT_URL=mqtt://localhost:1883 npm start
```

Variaveis:

- `MQTT_URL`: broker MQTT (padrao `mqtt://localhost:1883`).
- `MQTT_TOPIC`: topico de entrada (padrao `aventura_financeira/telemetria`).
- `PORT`: porta HTTP/WebSocket (padrao `3000`).
- `DATA_FILE`: diario JSONL persistente (padrao `./data/events.jsonl`).

Abra `http://localhost:3000/health` para verificar o processo e conecte o
front-end em `ws://localhost:3000/ws/telemetria`. O navegador recebe primeiro o
ultimo evento como snapshot e depois as atualizacoes MQTT. Historico/snapshot:

```text
GET /api/sessions
GET /api/sessions/<device_id>%3A<session_id>/snapshot
GET /api/sessions/<device_id>%3A<session_id>/events?limit=100
```

Os eventos validos sao gravados em JSON Lines; eventos repetidos/fora de ordem
sao ignorados pela combinacao dispositivo, sessao e sequencia. Lacunas de
sequencia sao registradas, sem criar eventos artificiais. Payloads invalidos
sao rejeitados e aparecem no log. O backend aceita timestamp nulo e anota o
instante de recebimento.

O servidor e destinado a desenvolvimento local: nao implementa autenticacao,
autorizacao, TLS nem rate limiting. Para rede compartilhada ou producao, use
broker e proxy WebSocket com TLS/autenticacao, ACLs de publicacao para a ESP8266 e
ACLs de leitura para o backend.

## Testes

```sh
npm test
```

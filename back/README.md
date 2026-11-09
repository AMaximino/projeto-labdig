# Backend e painel web

O backend assina MQTT, valida e persiste os eventos, expõe API HTTP e envia
snapshots/eventos por WebSocket. Ele também serve `../front`, então basta um
endereço para abrir a interface e receber atualizações.

## Executar

Requer Node.js 20+ e um broker MQTT. Na raiz do repositório:

```sh
npm --prefix back install
MQTT_URL=mqtt://localhost:1883 npm --prefix back start
```

No PowerShell:

```powershell
npm --prefix back install
$env:MQTT_URL = "mqtt://localhost:1883"
npm --prefix back start
```

Abra `http://localhost:3000`. Para clientes em outra máquina, use o IP do
computador servidor, por exemplo `http://192.168.1.20:3000`. O navegador deriva
o WebSocket do mesmo host (`/ws/telemetria`) e reconecta automaticamente após
quedas breves.

Variáveis de ambiente: `MQTT_URL` (padrão `mqtt://localhost:1883`),
`MQTT_TOPIC` (padrão `aventura_financeira/telemetria`), `PORT` (padrão `3000`) e
`DATA_FILE` (padrão `back/data/events.jsonl`). O servidor escuta em todas as
interfaces de rede para permitir acesso LAN.

## Rotas

- `GET /health`: estado do processo e conexão MQTT.
- `GET /api/sessions`: sessões conhecidas e último snapshot.
- `GET /api/sessions/<device_id>%3A<session_id>/snapshot`.
- `GET /api/sessions/<device_id>%3A<session_id>/events?limit=100`.
- `ws://<host>:3000/ws/telemetria`: envia snapshot inicial e envelopes
  `{"type":"event","data":{...}}`.

Eventos são deduplicados por dispositivo/sessão/sequência e persistidos em
JSON Lines. O painel consome o mesmo contrato em centavos de BRL.

O serviço é para desenvolvimento em rede local; não configura autenticação,
TLS ou ACL de MQTT. Não o exponha diretamente à internet.

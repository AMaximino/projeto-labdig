import { appendFileSync, mkdirSync, readFileSync, statSync, createReadStream } from "node:fs";
import { dirname, extname, resolve, sep } from "node:path";
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import { fileURLToPath } from "node:url";
import mqtt from "mqtt";
import { WebSocketServer, WebSocket } from "ws";

import { validateTelemetry } from "./contract.js";
import { PlayerStore, summarizeSession, validateCardRead } from "./players.js";

const port = Number(process.env.PORT || 3000);
const topic = process.env.MQTT_TOPIC || "aventura_financeira/telemetria";
const mqttUrl = process.env.MQTT_URL || "mqtt://localhost:1883";
const backendRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const journalPath = resolve(process.env.DATA_FILE || resolve(backendRoot, "data/events.jsonl"));
const cardTopic = process.env.MQTT_CARD_TOPIC || "aventura_financeira/cartao";
const players = new PlayerStore(resolve(process.env.PLAYERS_FILE || resolve(dirname(journalPath), "players.json")));
const latestSessionByDevice = new Map();
const frontendRoot = resolve(backendRoot, "../front");
const MIME_TYPES = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".svg": "image/svg+xml",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
  ".jpe": "image/jpeg", ".ico": "image/x-icon", ".pdf": "application/pdf",
};
const maxEventsPerSession = 5000;
const sessions = new Map();
const sockets = new Set();
const acceptedSequences = new Map();
let latestEvent = null;

function sessionKey(deviceId, sessionId) {
  return `${deviceId}:${sessionId}`;
}

function loadJournal() {
  try {
    const lines = readFileSync(journalPath, "utf8").split(/\r?\n/);
    for (const [index, line] of lines.entries()) {
      if (!line.trim()) continue;
      try {
        const event = validateTelemetry(JSON.parse(line), JSON.parse(line).received_at);
        storeEvent(event, false);
      } catch (error) {
        console.error(`Ignorando registro invalido no diario, linha ${index + 1}:`, error.message);
      }
    }
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}

function storeEvent(event, persist = true) {
  const key = sessionKey(event.device_id, event.session_id);
  const previous = acceptedSequences.get(key) || 0;
  if (event.seq <= previous) return false;
  if (previous > 0 && event.seq > previous + 1) {
    console.warn(`Lacuna de sequencia para ${key}: ${previous} -> ${event.seq}; nao foram inventados eventos.`);
  }

  acceptedSequences.set(key, event.seq);
  const history = sessions.get(key) || [];
  history.push(event);
  if (history.length > maxEventsPerSession) history.shift();
  sessions.set(key, history);
  latestEvent = event;
  latestSessionByDevice.set(event.device_id, key);

  if (persist) {
    mkdirSync(dirname(journalPath), { recursive: true });
    appendFileSync(journalPath, `${JSON.stringify(event)}\n`, "utf8");
  }
  return true;
}

function sendToSocket(socket, message) {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(message));
}

function broadcast(message) {
  for (const socket of sockets) sendToSocket(socket, message);
}

function jsonResponse(response, status, value) {
  response.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
  });
  response.end(JSON.stringify(value));
}

function sessionMeta(key) {
  const history = sessions.get(key) || [];
  return { ...players.session(key), ...summarizeSession(history) };
}

function readJsonBody(request, limit = 2048) {
  return new Promise((resolvePromise, reject) => {
    let body = "";
    request.setEncoding("utf8");
    request.on("data", (chunk) => {
      body += chunk;
      if (body.length > limit) {
        reject(new TypeError("corpo grande demais"));
        request.destroy();
      }
    });
    request.on("end", () => {
      try {
        resolvePromise(JSON.parse(body || "{}"));
      } catch {
        reject(new TypeError("JSON invalido"));
      }
    });
    request.on("error", reject);
  });
}

async function handlePlayerUpdate(request, response, key) {
  if (!sessions.has(key)) {
    jsonResponse(response, 404, { error: "Sessao nao encontrada." });
    return;
  }
  try {
    const body = await readJsonBody(request);
    players.setPlayerName(key, body.name);
  } catch (error) {
    jsonResponse(response, 400, { error: error.message });
    return;
  }
  const meta = sessionMeta(key);
  broadcast({ type: "session_meta", data: meta });
  jsonResponse(response, 200, meta);
}

function handleCardRead(raw) {
  let card;
  try {
    card = validateCardRead(raw);
  } catch (error) {
    console.error("Leitura de cartao rejeitada:", error.message);
    return;
  }
  const key = card.session_id
    ? `${card.device_id}:${card.session_id}`
    : latestSessionByDevice.get(card.device_id);
  if (!key || !sessions.has(key)) {
    console.warn(`Cartao ${card.uid} lido sem sessao conhecida; ignorado.`);
    return;
  }
  const { cardName, nameFromCard } = players.recordCard(key, card.uid, card.received_at);
  broadcast({
    type: "card",
    data: { session_key: key, uid: card.uid, item_id: card.item_id, card_name: cardName, name_from_card: nameFromCard },
  });
  broadcast({ type: "session_meta", data: sessionMeta(key) });
}

function handleHttpRequest(request, response) {
  const url = new URL(request.url, `http://${request.headers.host || "localhost"}`);
  if ((request.method === "GET" || request.method === "HEAD") &&
      !url.pathname.startsWith("/api/") && url.pathname !== "/health" &&
      url.pathname !== "/ws/telemetria") {
    let requestedPath;
    try {
      requestedPath = decodeURIComponent(url.pathname === "/" ? "/index.html" : url.pathname);
    } catch {
      jsonResponse(response, 400, { error: "Caminho inválido." });
      return;
    }
    const filePath = resolve(frontendRoot, `.${requestedPath}`);
    if (!filePath.startsWith(`${frontendRoot}${sep}`)) {
      jsonResponse(response, 403, { error: "Acesso negado." });
      return;
    }
    try {
      if (!statSync(filePath).isFile()) throw new Error("not a file");
      response.writeHead(200, {
        "content-type": MIME_TYPES[extname(filePath).toLowerCase()] || "application/octet-stream",
        "cache-control": "no-cache",
      });
      if (request.method === "HEAD") response.end();
      else createReadStream(filePath).pipe(response);
    } catch {
      jsonResponse(response, 404, { error: "Arquivo não encontrado." });
    }
    return;
  }
  if (request.method === "GET" && url.pathname === "/health") {
    jsonResponse(response, 200, {
      status: "ok",
      mqtt_connected: mqttClient.connected,
      sessions: sessions.size,
      events: [...sessions.values()].reduce((total, items) => total + items.length, 0),
    });
    return;
  }
  if (request.method === "GET" && url.pathname === "/api/sessions") {
    const list = [...sessions.entries()].map(([key, history]) => ({
      key,
      device_id: history.at(-1)?.device_id,
      session_id: history.at(-1)?.session_id,
      event_count: history.length,
      ...sessionMeta(key),
      snapshot: history.at(-1),
    }));
    jsonResponse(response, 200, list);
    return;
  }
  const playerMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/player$/);
  if (request.method === "POST" && playerMatch) {
    let key;
    try {
      key = decodeURIComponent(playerMatch[1]);
    } catch {
      jsonResponse(response, 400, { error: "Sessao invalida." });
      return;
    }
    handlePlayerUpdate(request, response, key).catch((error) => {
      console.error("Falha ao salvar jogador:", error.message);
      if (!response.headersSent) jsonResponse(response, 500, { error: "Falha ao salvar jogador." });
    });
    return;
  }
  const sessionMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/(snapshot|events|meta)$/);
  if (request.method === "GET" && sessionMatch) {
    const key = decodeURIComponent(sessionMatch[1]);
    const history = sessions.get(key);
    if (!history) {
      jsonResponse(response, 404, { error: "Sessao nao encontrada." });
      return;
    }
    if (sessionMatch[2] === "meta") {
      jsonResponse(response, 200, sessionMeta(key));
      return;
    }
    if (sessionMatch[2] === "snapshot") {
      jsonResponse(response, 200, history.at(-1));
      return;
    }
    const requestedLimit = Number(url.searchParams.get("limit") || 100);
    const limit = Number.isInteger(requestedLimit) ? Math.min(Math.max(requestedLimit, 1), 500) : 100;
    jsonResponse(response, 200, history.slice(-limit));
    return;
  }
  jsonResponse(response, 404, { error: "Rota nao encontrada." });
}

loadJournal();
const server = createServer(handleHttpRequest);
const webSocketServer = new WebSocketServer({ server, path: "/ws/telemetria" });

webSocketServer.on("connection", (socket) => {
  sockets.add(socket);
  if (latestEvent) {
    sendToSocket(socket, { type: "snapshot", data: latestEvent });
    sendToSocket(socket, {
      type: "session_meta",
      data: sessionMeta(sessionKey(latestEvent.device_id, latestEvent.session_id)),
    });
  }
  socket.on("close", () => sockets.delete(socket));
  socket.on("error", (error) => console.error("Erro no cliente WebSocket:", error.message));
});

const mqttClient = mqtt.connect(mqttUrl, {
  clientId: `aef-backend-${randomUUID()}`,
  clean: true,
  reconnectPeriod: 3000,
  connectTimeout: 8000,
});

mqttClient.on("connect", () => {
  console.info(`MQTT conectado em ${mqttUrl}; assinando ${topic}.`);
  mqttClient.subscribe([topic, cardTopic], { qos: 0 }, (error) => {
    if (error) console.error(`Falha ao assinar ${topic} / ${cardTopic}:`, error.message);
  });
});
mqttClient.on("reconnect", () => console.info("Reconectando ao broker MQTT..."));
mqttClient.on("error", (error) => console.error("Erro MQTT:", error.message));
mqttClient.on("message", (receivedTopic, buffer) => {
  if (receivedTopic !== topic && receivedTopic !== cardTopic) return;
  let raw;
  try {
    raw = JSON.parse(buffer.toString("utf8"));
  } catch (error) {
    console.error("Payload MQTT ignorado: JSON invalido.", error.message);
    return;
  }
  if (receivedTopic === cardTopic) {
    handleCardRead(raw);
    return;
  }
  let event;
  try {
    event = validateTelemetry(raw);
  } catch (error) {
    console.error("Payload MQTT rejeitado pelo contrato:", error.message);
    return;
  }
  if (!storeEvent(event)) {
    console.warn(`Evento duplicado ou fora de ordem ignorado: ${event.device_id}/${event.session_id}/${event.seq}`);
    return;
  }
  broadcast({ type: "event", data: event });
  if (event.event === "inicio_sessao" || event.event === "falencia" || event.event === "fim_jogo") {
    broadcast({ type: "session_meta", data: sessionMeta(sessionKey(event.device_id, event.session_id)) });
  }
});

server.listen(port, "0.0.0.0", () => {
  console.info(`Backend pronto em http://localhost:${port} e ws://localhost:${port}/ws/telemetria.`);
});

function shutdown() {
  console.info("Encerrando backend...");
  mqttClient.end(true);
  for (const socket of sockets) socket.close(1001, "Servidor encerrando");
  server.close(() => process.exit(0));
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);

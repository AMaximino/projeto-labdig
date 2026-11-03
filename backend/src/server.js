import { appendFileSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { createServer } from "node:http";
import { randomUUID } from "node:crypto";
import mqtt from "mqtt";
import { WebSocketServer, WebSocket } from "ws";

import { validateTelemetry } from "./contract.js";

const port = Number(process.env.PORT || 3000);
const topic = process.env.MQTT_TOPIC || "aventura_financeira/telemetria";
const mqttUrl = process.env.MQTT_URL || "mqtt://localhost:1883";
const journalPath = resolve(process.env.DATA_FILE || "./data/events.jsonl");
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

function handleHttpRequest(request, response) {
  const url = new URL(request.url, `http://${request.headers.host || "localhost"}`);
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
      snapshot: history.at(-1),
    }));
    jsonResponse(response, 200, list);
    return;
  }
  const sessionMatch = url.pathname.match(/^\/api\/sessions\/([^/]+)\/(snapshot|events)$/);
  if (request.method === "GET" && sessionMatch) {
    const key = decodeURIComponent(sessionMatch[1]);
    const history = sessions.get(key);
    if (!history) {
      jsonResponse(response, 404, { error: "Sessao nao encontrada." });
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
  if (latestEvent) sendToSocket(socket, { type: "snapshot", data: latestEvent });
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
  mqttClient.subscribe(topic, { qos: 0 }, (error) => {
    if (error) console.error(`Falha ao assinar ${topic}:`, error.message);
  });
});
mqttClient.on("reconnect", () => console.info("Reconectando ao broker MQTT..."));
mqttClient.on("error", (error) => console.error("Erro MQTT:", error.message));
mqttClient.on("message", (receivedTopic, buffer) => {
  if (receivedTopic !== topic) return;
  let raw;
  try {
    raw = JSON.parse(buffer.toString("utf8"));
  } catch (error) {
    console.error("Payload MQTT ignorado: JSON invalido.", error.message);
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
});

server.listen(port, () => {
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

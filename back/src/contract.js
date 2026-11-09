export const EVENTS = new Set([
  "inicio_sessao",
  "trabalhar",
  "estudar",
  "investir",
  "resgatar",
  "compra_aprovada",
  "compra_recusada",
  "venda_aprovada",
  "venda_recusada",
  "fim_rodada",
  "fim_jogo",
  "falencia",
]);

const MONEY_FIELDS = [
  "saldo_centavos",
  "salario_centavos",
  "valor_investido_centavos",
  "rendimento_centavos",
  "gastos_fixos_centavos",
  "gastos_unicos_centavos",
];
const MAX_MONEY_CENTS = 10_485_760_000;

export function validateTelemetry(payload, receivedAt = new Date().toISOString()) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new TypeError("payload precisa ser um objeto JSON");
  }
  if (payload.schema_version !== 1) throw new TypeError("schema_version deve ser 1");
  if (typeof payload.device_id !== "string" || !/^[A-Za-z0-9._-]{1,48}$/.test(payload.device_id)) {
    throw new TypeError("device_id invalido");
  }
  if (typeof payload.session_id !== "string" || !/^[A-Za-z0-9._-]{1,64}$/.test(payload.session_id)) {
    throw new TypeError("session_id invalido");
  }
  if (!Number.isSafeInteger(payload.seq) || payload.seq < 1 || payload.seq > 999999) {
    throw new TypeError("seq deve ser um inteiro entre 1 e 999999");
  }
  if (!EVENTS.has(payload.event)) throw new TypeError("event desconhecido");
  if (!Number.isInteger(payload.item_id) || payload.item_id < 0 || payload.item_id > 10) {
    throw new TypeError("item_id deve estar entre 0 e 10");
  }
  if (!["ok", "recusada", "info"].includes(payload.status)) {
    throw new TypeError("status invalido");
  }
  if (!Number.isInteger(payload.rodada) || payload.rodada < 1 || payload.rodada > 15) {
    throw new TypeError("rodada deve estar entre 1 e 15");
  }
  if (!Number.isInteger(payload.jogada) || payload.jogada < 1 || payload.jogada > 3) {
    throw new TypeError("jogada deve estar entre 1 e 3");
  }
  for (const field of MONEY_FIELDS) {
    if (!Number.isSafeInteger(payload[field]) || Math.abs(payload[field]) > MAX_MONEY_CENTS) {
      throw new TypeError(`${field} deve ser um inteiro de centavos dentro do limite`);
    }
  }
  if (!Number.isInteger(payload.inventario_mask) || payload.inventario_mask < 0 || payload.inventario_mask > 1023) {
    throw new TypeError("inventario_mask deve estar entre 0 e 1023");
  }
  if (!Number.isSafeInteger(payload.delta_saldo_centavos) ||
      Math.abs(payload.delta_saldo_centavos) > MAX_MONEY_CENTS * 2) {
    throw new TypeError("delta_saldo_centavos invalido");
  }
  if (payload.timestamp !== null &&
      (typeof payload.timestamp !== "string" ||
       !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(payload.timestamp) ||
       !Number.isFinite(Date.parse(payload.timestamp)))) {
    throw new TypeError("timestamp deve ser ISO-8601 ou null");
  }
  if (payload.event === "compra_recusada" &&
      (payload.status !== "recusada" || payload.delta_saldo_centavos !== 0)) {
    throw new TypeError("compra_recusada deve ter status recusada e delta zero");
  }
  if (payload.event === "venda_recusada" && payload.status !== "recusada") {
    throw new TypeError("venda_recusada deve ter status recusada");
  }
  if (["compra_aprovada", "venda_aprovada"].includes(payload.event) && payload.status !== "ok") {
    throw new TypeError("acao aprovada deve ter status ok");
  }

  return {
    ...payload,
    timestamp: payload.timestamp || receivedAt,
    device_timestamp: payload.timestamp,
    received_at: receivedAt,
  };
}

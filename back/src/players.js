// Jogador e cartão de cada sessão.
//
// - Cada sessão (device_id:session_id) pode ter um nome de jogador e um cartão.
// - Cada cartão (UID) lembra o último nome usado com ele. Assim, ao aproximar um
//   cartão já conhecido numa sessão nova, o nome do jogador vem do cartão.
// Tudo fica num JSON pequeno ao lado do diário de eventos.
import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export const MAX_NAME_LENGTH = 40;

export function normalizePlayerName(value) {
  if (typeof value !== "string") throw new TypeError("nome precisa ser texto");
  const name = value.replace(/\s+/g, " ").trim();
  if (!name) throw new TypeError("nome vazio");
  if (name.length > MAX_NAME_LENGTH) throw new TypeError(`nome com mais de ${MAX_NAME_LENGTH} caracteres`);
  if (/[\u0000-\u001f<>]/.test(name)) throw new TypeError("nome com caracteres invalidos");
  return name;
}

export function validateCardRead(payload, receivedAt = new Date().toISOString()) {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    throw new TypeError("leitura de cartao precisa ser um objeto JSON");
  }
  if (payload.schema_version !== 1) throw new TypeError("schema_version deve ser 1");
  if (typeof payload.device_id !== "string" || !/^[A-Za-z0-9._-]{1,48}$/.test(payload.device_id)) {
    throw new TypeError("device_id invalido");
  }
  if (typeof payload.session_id !== "string" || !/^[A-Za-z0-9._-]{0,64}$/.test(payload.session_id)) {
    throw new TypeError("session_id invalido");
  }
  if (typeof payload.uid !== "string" || !/^[0-9A-Fa-f]{8,20}$/.test(payload.uid)) {
    throw new TypeError("uid deve ser hexadecimal com 8 a 20 digitos");
  }
  if (!Number.isInteger(payload.item_id) || payload.item_id < 0 || payload.item_id > 10) {
    throw new TypeError("item_id deve estar entre 0 e 10");
  }
  return {
    device_id: payload.device_id,
    session_id: payload.session_id,
    uid: payload.uid.toUpperCase(),
    item_id: payload.item_id,
    received_at: receivedAt,
  };
}

export class PlayerStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.sessions = {};
    this.cards = {};
    this.load();
  }

  load() {
    try {
      const data = JSON.parse(readFileSync(this.filePath, "utf8"));
      this.sessions = data.sessions && typeof data.sessions === "object" ? data.sessions : {};
      this.cards = data.cards && typeof data.cards === "object" ? data.cards : {};
    } catch (error) {
      if (error.code !== "ENOENT") console.error("Arquivo de jogadores ignorado:", error.message);
    }
  }

  save() {
    mkdirSync(dirname(this.filePath), { recursive: true });
    const temporary = `${this.filePath}.tmp`;
    writeFileSync(temporary, JSON.stringify({ sessions: this.sessions, cards: this.cards }, null, 2), "utf8");
    renameSync(temporary, this.filePath);
  }

  session(key) {
    return { key, player_name: null, card_uid: null, ...(this.sessions[key] || {}) };
  }

  card(uid) {
    return this.cards[uid] || null;
  }

  setPlayerName(key, rawName, now = new Date().toISOString()) {
    const name = normalizePlayerName(rawName);
    const meta = this.session(key);
    meta.player_name = name;
    meta.updated_at = now;
    this.sessions[key] = { player_name: meta.player_name, card_uid: meta.card_uid, updated_at: now };
    if (meta.card_uid) this.cards[meta.card_uid] = { ...(this.cards[meta.card_uid] || {}), name, last_seen: now };
    this.save();
    return this.session(key);
  }

  // Registra o cartão na sessão. O primeiro cartão da sessão identifica o jogador:
  // - cartão que já tem nome: a sessão passa a ser desse jogador;
  // - cartão novo: ele passa a guardar o nome que a sessão já tem.
  // Retorna a sessão e se o nome do jogador mudou por causa do cartão.
  recordCard(key, uid, now = new Date().toISOString()) {
    const meta = this.session(key);
    const known = this.cards[uid];
    let nameFromCard = false;
    if (!meta.card_uid) meta.card_uid = uid;
    if (meta.card_uid === uid) {
      if (known?.name) {
        nameFromCard = known.name !== meta.player_name;
        meta.player_name = known.name;
      } else if (meta.player_name) {
        this.cards[uid] = { ...(known || {}), name: meta.player_name };
      }
    }
    this.cards[uid] = { ...(this.cards[uid] || {}), last_seen: now };
    this.sessions[key] = { player_name: meta.player_name, card_uid: meta.card_uid, updated_at: now };
    this.save();
    return { session: this.session(key), cardName: this.cards[uid]?.name || null, nameFromCard };
  }
}

// Resumo de uma sessão para a lista de partidas e para o progresso do jogador.
export function summarizeSession(history) {
  const first = history[0];
  const last = history.at(-1);
  const count = (pattern) => history.filter((event) => pattern.test(event.event)).length;
  let result = "em_andamento";
  if (history.some((event) => event.event === "falencia")) result = "faliu";
  else if (history.some((event) => event.event === "fim_jogo")) result = "venceu";
  return {
    started_at: first?.received_at || null,
    updated_at: last?.received_at || null,
    result,
    rodada: last?.rodada || 1,
    saldo_final_centavos: last?.saldo_centavos ?? null,
    salario_final_centavos: last?.salario_centavos ?? null,
    investido_final_centavos: last?.valor_investido_centavos ?? null,
    trabalhou: count(/^trabalhar$/),
    estudou: count(/^estudar$/),
    investiu: count(/^investir$/),
    resgatou: count(/^resgatar$/),
    compras: count(/^compra_aprovada$/),
    compras_recusadas: count(/^compra_recusada$/),
    vendas: count(/^venda_aprovada$/),
  };
}

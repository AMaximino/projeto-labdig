import test from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { PlayerStore, normalizePlayerName, summarizeSession, validateCardRead } from "../src/players.js";

function freshStore() {
  const dir = mkdtempSync(join(tmpdir(), "aef-players-"));
  return { store: new PlayerStore(join(dir, "players.json")), path: join(dir, "players.json"), dir };
}

test("normalizes and rejects player names", () => {
  assert.equal(normalizePlayerName("  Ana   Clara "), "Ana Clara");
  assert.throws(() => normalizePlayerName("   "), /vazio/);
  assert.throws(() => normalizePlayerName("<b>x</b>"), /invalidos/);
  assert.throws(() => normalizePlayerName("x".repeat(41)), /40/);
});

test("validates a card read", () => {
  const card = validateCardRead({ schema_version: 1, device_id: "aef-fpga-01", session_id: "abc-1", uid: "f382862a", item_id: 6 });
  assert.equal(card.uid, "F382862A");
  assert.throws(() => validateCardRead({ schema_version: 1, device_id: "d", session_id: "s", uid: "xyz", item_id: 1 }), /uid/);
});

test("a new card learns the session player's name", () => {
  const { store, dir } = freshStore();
  store.setPlayerName("d:s1", "Ana");
  const result = store.recordCard("d:s1", "F382862A");
  assert.equal(result.cardName, "Ana");
  assert.equal(result.nameFromCard, false);
  rmSync(dir, { recursive: true, force: true });
});

test("a known card identifies the player in a new session and survives reload", () => {
  const { store, path, dir } = freshStore();
  store.setPlayerName("d:s1", "Ana");
  store.recordCard("d:s1", "F382862A");
  const reloaded = new PlayerStore(path);
  reloaded.setPlayerName("d:s2", "Bruno");
  const result = reloaded.recordCard("d:s2", "F382862A");
  assert.equal(result.session.player_name, "Ana");
  assert.equal(result.nameFromCard, true);
  // Corrigir o nome depois renomeia o cartão.
  reloaded.setPlayerName("d:s2", "Bruno");
  assert.equal(reloaded.card("F382862A").name, "Bruno");
  rmSync(dir, { recursive: true, force: true });
});

test("only the first card of a session identifies the player", () => {
  const { store, dir } = freshStore();
  store.setPlayerName("d:s0", "Carla");
  store.recordCard("d:s0", "8E9263A3");
  store.setPlayerName("d:s1", "Ana");
  store.recordCard("d:s1", "F382862A");
  const second = store.recordCard("d:s1", "8E9263A3");
  assert.equal(second.session.player_name, "Ana");
  assert.equal(second.session.card_uid, "F382862A");
  rmSync(dir, { recursive: true, force: true });
});

test("summarizes a session result", () => {
  const summary = summarizeSession([
    { event: "inicio_sessao", rodada: 1, saldo_centavos: 1500000, received_at: "a" },
    { event: "trabalhar", rodada: 1, saldo_centavos: 1740000 },
    { event: "compra_aprovada", rodada: 1, saldo_centavos: -100000 },
    { event: "falencia", rodada: 1, saldo_centavos: -100000, received_at: "b" },
  ]);
  assert.equal(summary.result, "faliu");
  assert.equal(summary.trabalhou, 1);
  assert.equal(summary.compras, 1);
  assert.equal(summary.saldo_final_centavos, -100000);
});

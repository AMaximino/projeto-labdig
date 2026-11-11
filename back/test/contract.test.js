import test from "node:test";
import assert from "node:assert/strict";

import { validateTelemetry } from "../src/contract.js";

const sample = {
  schema_version: 1,
  device_id: "aef-fpga-01",
  session_id: "esp8266-abcd-1234",
  seq: 18,
  timestamp: "2026-11-02T23:46:00.000Z",
  event: "compra_aprovada",
  item_id: 7,
  status: "ok",
  rodada: 2,
  jogada: 1,
  saldo_centavos: 300000,
  salario_centavos: 640000,
  valor_investido_centavos: 0,
  rendimento_centavos: 0,
  gastos_fixos_centavos: 400000,
  gastos_unicos_centavos: 1200000,
  inventario_mask: 64,
  delta_saldo_centavos: -1200000,
};

test("validates the full version 1 telemetry snapshot", () => {
  const accepted = validateTelemetry(sample);
  assert.equal(accepted.saldo_centavos, 300000);
  assert.equal(accepted.timestamp, sample.timestamp);
  assert.equal(accepted.device_timestamp, sample.timestamp);
  assert.ok(accepted.received_at);
});

test("rejects an unsupported schema and malformed money units", () => {
  assert.throws(() => validateTelemetry({ ...sample, schema_version: 2 }), /schema_version/);
  assert.throws(() => validateTelemetry({ ...sample, saldo_centavos: 1.5 }), /saldo_centavos/);
});

test("rejects a refused purchase that changes the balance", () => {
  assert.throws(() => validateTelemetry({
    ...sample,
    event: "compra_recusada",
    status: "recusada",
  }), /delta zero/);
});

test("accepts a rejected purchase with no balance delta", () => {
  const accepted = validateTelemetry({
    ...sample,
    event: "compra_recusada",
    status: "recusada",
    delta_saldo_centavos: 0,
  });
  assert.equal(accepted.event, "compra_recusada");
});

test("fills a missing device timestamp from backend receive time", () => {
  const accepted = validateTelemetry({ ...sample, timestamp: null }, "2026-11-02T23:47:00.000Z");
  assert.equal(accepted.timestamp, "2026-11-02T23:47:00.000Z");
  assert.equal(accepted.device_timestamp, null);
});

test("accepts the selector position event", () => {
  const accepted = validateTelemetry({
    ...sample, event: "seletor_item", item_id: 5, status: "info", delta_saldo_centavos: 0,
  });
  assert.equal(accepted.event, "seletor_item");
  assert.equal(accepted.item_id, 5);
});

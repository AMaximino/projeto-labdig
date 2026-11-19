// Métricas do modo professor (front/analytics.js).
import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const analytics = require("../../front/analytics.js");

const catalog = [
  { id: 1, name: "Carro pequeno", price: 60000, expense: 3600 },
  { id: 8, name: "Jogos", price: 8000, expense: 0 },
];

let seq = 0;
function event(name, values = {}) {
  seq += 1;
  return {
    seq, event: name, item_id: 0, rodada: 1, jogada: 1, vidas: 3,
    timestamp: new Date(Date.UTC(2026, 10, 18, 12, 0, seq * 5)).toISOString(),
    saldo_centavos: 1500000, salario_centavos: 640000, valor_investido_centavos: 0,
    rendimento_centavos: 0, gastos_fixos_centavos: 400000, gastos_unicos_centavos: 0, inventario_mask: 0,
    ...values,
  };
}

function sampleGame() {
  seq = 0;
  return [
    event("inicio_sessao"),
    event("trabalhar", { saldo_centavos: 1740000 }),
    event("estudar", { jogada: 2, saldo_centavos: 1340000, salario_centavos: 1040000 }),
    event("investir", { jogada: 3, saldo_centavos: 340000, salario_centavos: 1040000, valor_investido_centavos: 1000000 }),
    event("trabalhar", { jogada: 3, saldo_centavos: 980000, salario_centavos: 1040000, valor_investido_centavos: 1000000 }),
    event("fim_rodada", { rodada: 2, saldo_centavos: 980000, salario_centavos: 1040000, valor_investido_centavos: 1250000 }),
    event("seletor_item", { rodada: 2, item_id: 1, saldo_centavos: 980000, salario_centavos: 1040000, valor_investido_centavos: 1250000 }),
    event("compra_aprovada", { rodada: 2, item_id: 1, saldo_centavos: -5020000, salario_centavos: 1040000, valor_investido_centavos: 1250000, inventario_mask: 1, gastos_fixos_centavos: 760000 }),
    event("vida_perdida", { rodada: 2, vidas: 2, saldo_centavos: 980000, salario_centavos: 1040000, valor_investido_centavos: 1250000 }),
    event("compra_aprovada", { rodada: 2, item_id: 8, saldo_centavos: 180000, salario_centavos: 1040000, valor_investido_centavos: 1250000, inventario_mask: 128 }),
  ];
}

test("conta as decisões e ignora a jogada desfeita pela vida perdida", () => {
  const result = analytics.analyzeSession(sampleGame(), catalog);
  assert.equal(result.counts.trabalhar, 2);
  assert.equal(result.counts.estudar, 1);
  assert.equal(result.counts.investir, 1);
  assert.equal(result.counts.compra_aprovada, 1); // o carro foi desfeito
  assert.equal(result.livesLost, 1);
  assert.deepEqual(result.riskyMoves, [{ event: "compra_aprovada", round: 2, item: "Carro pequeno", undone: true }]);
  assert.equal(result.spentOnItems, 8000);
  assert.equal(result.recurringBought, 0);
});

test("calcula renda, estudo, custo de vida, rendimento e patrimônio", () => {
  const result = analytics.analyzeSession(sampleGame(), catalog);
  assert.equal(result.income, 6400 + 10400);
  assert.equal(result.extraIncomeFromStudy, 4000);
  assert.equal(result.livingCostPaid, 4000 * 3);
  assert.equal(result.yieldEarned, 2500);
  assert.equal(result.firstStudyRound, 1);
  assert.equal(result.netWorth, 1800 + 12500 + 8000);
  assert.equal(result.result, "em_andamento");
  assert.equal(result.selectorViews, 1);
});

test("resume as partidas do aluno e gera frases para o professor", () => {
  const game = analytics.analyzeSession(sampleGame(), catalog);
  const lost = analytics.analyzeSession([...sampleGame(), event("falencia", { vidas: 0, rodada: 2 })], catalog);
  const summary = analytics.analyzeStudent([game, lost]);
  assert.equal(summary.games, 2);
  assert.equal(summary.losses, 1);
  assert.equal(summary.inProgress, 1);
  assert.equal(summary.averageRound, 2);
  const titles = analytics.insights(game).map((entry) => entry.title);
  assert.ok(titles.includes("Estudo"));
  assert.ok(titles.includes("Gastou mais do que tinha"));
  assert.equal(analytics.studentLabel({ player_name: null, card_uid: "ABCD1234" }), "Cartão ABCD1234");
});

test("RESGATAR sem nada investido não conta como resgate", () => {
  seq = 0;
  const s = analytics.analyzeSession([
    event("inicio_sessao"),
    event("resgatar"),
    event("investir", { saldo_centavos: 500000, valor_investido_centavos: 1000000 }),
    event("resgatar", { saldo_centavos: 1500000, valor_investido_centavos: 0 }),
  ], catalog);
  assert.equal(s.counts.resgatar, 1);
  assert.equal(s.counts.investir, 1);
});

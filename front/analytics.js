// Métricas de uma partida e de um aluno, para o modo professor.
// Funções puras: recebem os eventos do contrato (centavos, como o backend
// guarda em back/data/events.jsonl) e devolvem números e frases em reais.
(function (root) {
  "use strict";

  const BASE_SALARY_CENTS = 640000; // salário inicial (fpga/rtl/inicializador.v)
  const ACTIONS = ["trabalhar", "estudar", "investir", "resgatar", "compra_aprovada", "venda_aprovada"];
  const NOT_ACTIONS = new Set(["seletor_item", "vida_perdida", "fim_rodada", "inicio_sessao", "fim_jogo", "falencia"]);

  const BRL = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL", maximumFractionDigits: 0 });
  const money = (reais) => BRL.format(Number.isFinite(reais) ? reais : 0);
  const reais = (cents) => (Number.isFinite(cents) ? cents / 100 : 0);
  const plural = (count, one, many) => `${count} ${count === 1 ? one : many}`;
  const timeOf = (event) => Date.parse(event.timestamp || event.received_at || "") || null;

  function itemById(catalog, id) {
    return catalog.find((item) => item.id === id) || null;
  }

  function ownedItems(mask, catalog) {
    return catalog.filter((item) => (mask || 0) & (1 << (item.id - 1)));
  }

  function median(values) {
    if (!values.length) return null;
    const sorted = [...values].sort((a, b) => a - b);
    const middle = Math.floor(sorted.length / 2);
    return sorted.length % 2 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  // Vida perdida: a FPGA desfaz a jogada anterior. Devolve os índices das
  // jogadas desfeitas (não contam) e das jogadas arriscadas (gastaram mais do
  // que o aluno tinha: as desfeitas e a que causou a falência).
  function markRisky(events) {
    const undone = new Set();
    const risky = new Set();
    const lastAction = (before) => {
      for (let index = before - 1; index >= 0; index -= 1) {
        if (!NOT_ACTIONS.has(events[index].event) && !undone.has(index)) return index;
      }
      return -1;
    };
    events.forEach((event, index) => {
      if (event.event !== "vida_perdida" && event.event !== "falencia") return;
      const culprit = lastAction(index);
      if (culprit < 0) return;
      risky.add(culprit);
      if (event.event === "vida_perdida") undone.add(culprit);
    });
    return { undone, risky };
  }

  // Analisa uma partida. "events" pode vir em qualquer ordem; vale a do seq.
  function analyzeSession(rawEvents, catalog = []) {
    const sorted = [...(rawEvents || [])].filter(Boolean).sort((a, b) => (a.seq || 0) - (b.seq || 0));
    // A partida termina no fim de jogo ou na falência; o que vem depois é ruído.
    const endIndex = sorted.findIndex((event) => event.event === "fim_jogo" || event.event === "falencia");
    const events = endIndex >= 0 ? sorted.slice(0, endIndex + 1) : sorted;
    const { undone, risky } = markRisky(events);

    const counts = { trabalhar: 0, estudar: 0, investir: 0, resgatar: 0, compra_aprovada: 0, venda_aprovada: 0, compra_recusada: 0, venda_recusada: 0 };
    const cents = { income: 0, extraIncome: 0, livingCost: 0, yield: 0, spent: 0, sold: 0, recurringAdded: 0 };
    let firstStudyRound = null;
    let recurringBought = 0;
    let livesLost = 0;
    const riskyMoves = [];
    const purchases = [];
    const viewed = new Set();
    let selectorViews = 0;
    const gaps = [];
    let lastActionTime = null;
    const timeline = [];

    events.forEach((event, index) => {
      const previous = events[index - 1] || event;
      const code = event.event;
      if (code === "seletor_item") {
        selectorViews += 1;
        if (event.item_id) viewed.add(event.item_id);
        return;
      }
      if (code === "vida_perdida" || code === "falencia") livesLost += 1;
      // RESGATAR sem nada investido não muda nada na FPGA: não conta como resgate.
      if (code === "resgatar" && !(previous.valor_investido_centavos > 0) && index > 0) return;
      if (code in counts && !undone.has(index)) counts[code] += 1;
      if (ACTIONS.includes(code) || code === "compra_recusada" || code === "venda_recusada") {
        const at = timeOf(event);
        if (at && lastActionTime && at > lastActionTime) gaps.push((at - lastActionTime) / 1000);
        if (at) lastActionTime = at;
      }
      if (risky.has(index)) {
        const item = itemById(catalog, event.item_id);
        riskyMoves.push({ event: code, round: event.rodada, item: item?.name || "", undone: undone.has(index) });
      }
      if (!undone.has(index)) {
        if (code === "trabalhar") {
          cents.income += previous.salario_centavos || 0;
          cents.extraIncome += Math.max(0, (previous.salario_centavos || 0) - BASE_SALARY_CENTS);
          cents.livingCost += previous.gastos_fixos_centavos || 0;
        } else if (code === "estudar") {
          cents.livingCost += previous.gastos_fixos_centavos || 0;
          if (firstStudyRound === null) firstStudyRound = event.rodada || 1;
        } else if (code === "fim_rodada") {
          cents.yield += Math.max(0, (event.valor_investido_centavos || 0) - (previous.valor_investido_centavos || 0));
        } else if (code === "compra_aprovada") {
          const item = itemById(catalog, event.item_id);
          if (item) {
            cents.spent += item.price * 100;
            purchases.push(item.name);
            if (item.expense) {
              recurringBought += 1;
              cents.recurringAdded += item.expense * 100;
            }
          }
        } else if (code === "venda_aprovada") {
          const item = itemById(catalog, event.item_id);
          if (item) cents.sold += item.price * 100;
        }
      }
      // Gráfico: uma marca por jogada (o estado depois dela).
      timeline.push({
        event: code,
        round: event.rodada,
        balance: reais(event.saldo_centavos),
        invested: reais(event.valor_investido_centavos),
        undone: undone.has(index),
      });
    });

    const last = events.at(-1) || {};
    const items = ownedItems(last.inventario_mask, catalog);
    const itemsValue = items.reduce((sum, item) => sum + item.price, 0);
    const finalBalance = reais(last.saldo_centavos);
    const finalInvested = reais(last.valor_investido_centavos);
    const finalSalary = reais(last.salario_centavos);
    let result = "em_andamento";
    if (events.some((event) => event.event === "falencia")) result = "faliu";
    else if (events.some((event) => event.event === "fim_jogo")) result = "venceu";
    const moves = counts.trabalhar + counts.estudar;
    const decisions = ACTIONS.reduce((sum, code) => sum + counts[code], 0);
    // Patrimônio: dinheiro (pode ser negativo) + investido + valor dos itens.
    const netWorth = finalBalance + finalInvested + itemsValue;
    const startedAt = timeOf(events[0] || {});
    const endedAt = timeOf(last);

    return {
      result,
      startedAt,
      endedAt,
      durationSeconds: startedAt && endedAt ? Math.max(0, (endedAt - startedAt) / 1000) : null,
      roundReached: last.rodada || 1,
      finalBalance,
      finalInvested,
      finalSalary,
      studyLevel: Math.max(0, Math.round((last.salario_centavos - BASE_SALARY_CENTS) / 400000)) || 0,
      items: items.map((item) => item.name),
      itemsValue,
      netWorth,
      counts,
      moves,
      decisions,
      livesLost,
      riskyMoves,
      firstStudyRound,
      income: reais(cents.income),
      extraIncomeFromStudy: reais(cents.extraIncome),
      livingCostPaid: reais(cents.livingCost),
      yieldEarned: reais(cents.yield),
      spentOnItems: reais(cents.spent),
      soldItems: reais(cents.sold),
      purchases,
      recurringBought,
      recurringCostAdded: reais(cents.recurringAdded),
      selectorViews,
      distinctItemsViewed: viewed.size,
      medianSecondsPerDecision: median(gaps),
      studyShare: moves ? counts.estudar / moves : null,
      investedShare: netWorth > 0 ? finalInvested / netWorth : 0,
      timeline,
    };
  }

  // Frases curtas para o professor: o que o aluno fez e o que isso mostra.
  // tone: "good" (bom sinal), "warn" (vale conversar) ou "info".
  function insights(session) {
    const list = [];
    const s = session;
    if (s.counts.estudar > 0) {
      list.push({
        tone: s.firstStudyRound <= 3 ? "good" : "info",
        title: "Estudo",
        text: `Estudou ${plural(s.counts.estudar, "vez", "vezes")}, a primeira na rodada ${s.firstStudyRound}. `
          + `O estudo trouxe ${money(s.extraIncomeFromStudy)} a mais de salário nas jogadas de trabalho.`,
      });
    } else if (s.moves > 0) {
      list.push({ tone: "warn", title: "Estudo", text: "Não estudou: o salário ficou em R$ 6.400 a partida toda." });
    }
    if (s.counts.investir > 0) {
      list.push({
        tone: s.yieldEarned > 0 ? "good" : "info",
        title: "Investimento",
        text: `Investiu ${plural(s.counts.investir, "vez", "vezes")} e o investimento rendeu ${money(s.yieldEarned)}. `
          + `No fim, ${Math.round(s.investedShare * 100)}% do patrimônio estava investido.`,
      });
    } else if (s.moves > 0) {
      list.push({ tone: "warn", title: "Investimento", text: "Não investiu: o dinheiro guardado não rendeu nada." });
    }
    if (s.counts.compra_aprovada > 0) {
      const recurring = s.recurringBought
        ? ` ${plural(s.recurringBought, "item tem", "itens têm")} conta por jogada (+ ${money(s.recurringCostAdded)} no custo de vida).`
        : " Nenhum deles tem conta por jogada.";
      list.push({
        tone: s.recurringBought ? "warn" : "info",
        title: "Compras",
        text: `Comprou ${plural(s.counts.compra_aprovada, "item", "itens")} (${money(s.spentOnItems)}).${recurring}`,
      });
    }
    if (s.selectorViews > 0 && s.counts.compra_aprovada > 0) {
      const perPurchase = s.selectorViews / s.counts.compra_aprovada;
      list.push({
        tone: perPurchase >= 2 ? "good" : "info",
        title: "Pesquisa de preço",
        text: `Olhou ${plural(s.distinctItemsViewed, "item diferente", "itens diferentes")} no seletor `
          + `(${plural(s.selectorViews, "giro", "giros")}, cerca de ${perPurchase.toFixed(1).replace(".", ",")} por compra).`,
      });
    }
    if (s.riskyMoves.length) {
      const names = { trabalhar: "trabalhar", estudar: "estudar", investir: "investir", compra_aprovada: "comprar", resgatar: "resgatar", venda_aprovada: "vender" };
      const first = s.riskyMoves.slice(0, 3).map((move) => `${names[move.event] || move.event}${move.item ? ` ${move.item}` : ""} (rodada ${move.round})`).join(", ");
      list.push({
        tone: "warn",
        title: "Gastou mais do que tinha",
        text: `${plural(s.riskyMoves.length, "jogada deixou", "jogadas deixaram")} o saldo negativo: ${first}.`,
      });
    } else if (s.decisions >= 5) {
      list.push({ tone: "good", title: "Controle do saldo", text: "Nenhuma jogada deixou o saldo negativo." });
    }
    if (s.counts.compra_recusada > 1) {
      list.push({
        tone: "info",
        title: "Tentativas repetidas",
        text: `Tentou comprar um item que já tinha ${plural(s.counts.compra_recusada, "vez", "vezes")}. Vale revisar como funciona o inventário.`,
      });
    }
    if (s.medianSecondsPerDecision !== null && s.decisions >= 4) {
      const seconds = Math.round(s.medianSecondsPerDecision);
      list.push({
        tone: seconds < 2 ? "warn" : "info",
        title: "Ritmo",
        text: seconds < 2
          ? `Decidiu muito rápido (cerca de ${seconds} s por jogada): pode estar apertando sem ler a tela.`
          : `Levou cerca de ${seconds} s por decisão.`,
      });
    }
    return list;
  }

  // Resumo de várias partidas do mesmo aluno, da mais antiga para a mais nova.
  function analyzeStudent(sessions) {
    const played = sessions.filter((session) => session.decisions > 0);
    const totals = played.reduce((sum, session) => {
      for (const [key, value] of Object.entries(session.counts)) sum[key] = (sum[key] || 0) + value;
      return sum;
    }, {});
    const moves = (totals.trabalhar || 0) + (totals.estudar || 0);
    const finished = played.filter((session) => session.result !== "em_andamento");
    return {
      games: played.length,
      wins: played.filter((session) => session.result === "venceu").length,
      losses: played.filter((session) => session.result === "faliu").length,
      inProgress: played.filter((session) => session.result === "em_andamento").length,
      bestNetWorth: played.length ? Math.max(...played.map((session) => session.netWorth)) : null,
      averageRound: finished.length ? finished.reduce((sum, session) => sum + session.roundReached, 0) / finished.length : null,
      livesLost: played.reduce((sum, session) => sum + session.livesLost, 0),
      studyShare: moves ? (totals.estudar || 0) / moves : null,
      totals,
      trend: played.map((session) => ({ startedAt: session.startedAt, netWorth: session.netWorth, result: session.result, round: session.roundReached })),
    };
  }

  // Nome que identifica o aluno de uma sessão do backend.
  function studentLabel(meta) {
    if (meta?.player_name) return meta.player_name;
    if (meta?.card_uid) return `Cartão ${meta.card_uid}`;
    return "Sem identificação";
  }

  const api = { analyzeSession, analyzeStudent, insights, studentLabel, markRisky };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.AEFAnalytics = api;
})(typeof globalThis !== "undefined" ? globalThis : this);

// Regras do jogo, sugestões de jogada e métricas de aprendizado.
// Funções puras: recebem números, devolvem números e frases. A linguagem é
// literal e previsível (causa → efeito, com o valor exato), pensada para
// jovens autistas aprendendo economia.
(function (root) {
  "use strict";

  // Mesmos valores do RTL (fpga/rtl/inicializador.v e processador_acao.v).
  const RULES = Object.freeze({
    initialBalance: 15000,
    initialSalary: 6400,
    initialFixedExpenses: 4000,
    studyCost: 12000,
    studyRaise: 4000,
    investStep: 1000,
    yieldRate: 0.25, // o investimento rende 25% no fim de cada rodada
    rounds: 15,
    movesPerRound: 3,
  });

  const BRL = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });
  const money = (value) => BRL.format(Number.isFinite(value) ? value : 0);

  // Jogadas de trabalho/estudo que ainda faltam, contando a atual.
  function movesLeft(round, move) {
    const r = Math.min(Math.max(Number(round) || 1, 1), RULES.rounds);
    const m = Math.min(Math.max(Number(move) || 1, 1), RULES.movesPerRound);
    return (RULES.rounds - r) * RULES.movesPerRound + (RULES.movesPerRound - m + 1);
  }

  // Quanto sobra em uma jogada de trabalho, depois das despesas fixas.
  function netPerWork(salary, fixedExpenses) {
    return salary - fixedExpenses;
  }

  // Quantas jogadas de trabalho pagam um valor (null se trabalhar não sobra nada).
  function workMovesFor(amount, net) {
    if (!(net > 0)) return null;
    return Math.max(1, Math.ceil(amount / net));
  }

  function plural(count, one, many) {
    return `${count} ${count === 1 ? one : many}`;
  }

  // Sugere as próximas jogadas. Cada opção diz: qual botão apertar, o que
  // acontece com o dinheiro (valor exato) e por quê. Uma delas vem marcada
  // como "sugestão"; as outras mostram o que também é possível ou arriscado.
  function suggestNextMoves(ctx) {
    const {
      balance, salary, fixedExpenses, investments = 0, inventory = [],
      selectorItem = null, catalog = [], round = 1, move = 1, gameOver = false,
    } = ctx;
    if (gameOver || !Number.isFinite(balance)) return [];
    const left = movesLeft(round, move);
    const net = netPerWork(salary, fixedExpenses);
    const options = [];

    // TRABALHAR
    const afterWork = balance + net;
    options.push({
      action: "trabalhar",
      button: "TRABALHAR",
      icon: "💼",
      title: "Trabalhar",
      result: `Seu saldo vai de ${money(balance)} para ${money(afterWork)}.`,
      why: net > 0
        ? `Você recebe ${money(salary)} de salário e paga ${money(fixedExpenses)} de despesas. Sobram ${money(net)}.`
        : `Suas despesas (${money(fixedExpenses)}) são maiores que o salário (${money(salary)}). Mesmo trabalhando, o saldo diminui ${money(-net)}.`,
      tone: afterWork < 0 ? "danger" : net > 0 ? "ok" : "warning",
      usesMove: true,
      after: afterWork,
    });

    // ESTUDAR
    const afterStudy = balance - RULES.studyCost - fixedExpenses;
    const studyPayback = Math.ceil(RULES.studyCost / RULES.studyRaise); // 3 jogadas
    const studyTimeOk = left - 1 >= studyPayback;
    options.push({
      action: "estudar",
      button: "ESTUDAR",
      icon: "📚",
      title: "Estudar",
      result: afterStudy < 0
        ? `Seu saldo ficaria em ${money(afterStudy)}. Saldo negativo: você perde o jogo.`
        : `Seu saldo vai de ${money(balance)} para ${money(afterStudy)}. Seu salário passa de ${money(salary)} para ${money(salary + RULES.studyRaise)}.`,
      why: studyTimeOk
        ? `Estudar custa ${money(RULES.studyCost)} agora, mas cada trabalho depois paga ${money(RULES.studyRaise)} a mais. Em ${studyPayback} trabalhos o estudo se paga.`
        : `Estudar só se paga depois de ${studyPayback} trabalhos. Faltam ${plural(left - 1, "jogada", "jogadas")} depois desta: não dá tempo de recuperar.`,
      tone: afterStudy < 0 ? "danger" : studyTimeOk ? "ok" : "warning",
      usesMove: true,
      after: afterStudy,
    });

    // INVESTIR
    const afterInvest = balance - RULES.investStep;
    const yieldPerStep = RULES.investStep * RULES.yieldRate;
    options.push({
      action: "investir",
      button: "INVESTIR",
      icon: "🌱",
      title: "Investir",
      result: afterInvest < 0
        ? `Seu saldo ficaria em ${money(afterInvest)}. Saldo negativo: você perde o jogo.`
        : `Você guarda ${money(RULES.investStep)}. Seu saldo vai para ${money(afterInvest)}.`,
      why: `No fim de cada rodada, o investimento cresce 25%: cada ${money(RULES.investStep)} rende ${money(yieldPerStep)}. Investir não gasta jogada.`,
      tone: afterInvest < 0 ? "danger" : afterInvest < fixedExpenses ? "warning" : "ok",
      usesMove: false,
      after: afterInvest,
    });

    // RESGATAR
    if (investments > 0) {
      const redeem = Math.min(investments, RULES.investStep);
      options.push({
        action: "resgatar",
        button: "RESGATAR",
        icon: "🏦",
        title: "Resgatar investimento",
        result: `Volta ${money(redeem)} para o saldo: ${money(balance)} vira ${money(balance + redeem)}.`,
        why: "Resgatar é útil quando falta dinheiro para as despesas. O que fica investido continua rendendo.",
        tone: "ok",
        usesMove: false,
        after: balance + redeem,
      });
    }

    // COMPRAR / VENDER o item do seletor
    const item = catalog.find((entry) => entry.id === selectorItem);
    if (item && !inventory.includes(item.id)) {
      const afterBuy = balance - item.price;
      const newNet = netPerWork(salary, fixedExpenses + item.expense);
      const moves = workMovesFor(item.price, net);
      let why = moves
        ? `Esse item custa o mesmo que ${plural(moves, "trabalho", "trabalhos")} (sobram ${money(net)} por trabalho).`
        : "Hoje trabalhar não sobra dinheiro, então fica difícil juntar para esse item.";
      if (item.expense) {
        why += ` Ele aumenta as despesas em ${money(item.expense)} por jogada: depois de comprar, cada trabalho sobra ${money(newNet)}.`;
      }
      options.push({
        action: "comprar",
        button: "COMPRAR (ou aproxime o cartão)",
        icon: "🛒",
        title: `Comprar ${item.name}`,
        result: afterBuy < 0
          ? `Seu saldo ficaria em ${money(afterBuy)}. Saldo negativo: você perde o jogo.`
          : `Seu saldo vai de ${money(balance)} para ${money(afterBuy)}.`,
        why,
        tone: afterBuy < 0 ? "danger" : newNet <= 0 || afterBuy < fixedExpenses ? "warning" : "ok",
        usesMove: false,
        after: afterBuy,
        itemId: item.id,
      });
    } else if (item) {
      const newNet = netPerWork(salary, fixedExpenses - item.expense);
      options.push({
        action: "vender",
        button: "VENDER",
        icon: "🏷️",
        title: `Vender ${item.name}`,
        result: `Você recebe ${money(item.price)}. Seu saldo vai para ${money(balance + item.price)}.`,
        why: item.expense
          ? `Sem esse item, as despesas diminuem ${money(item.expense)}: cada trabalho passa a sobrar ${money(newNet)}.`
          : "Esse item não tem despesa. Vender só faz sentido se você precisar do dinheiro.",
        tone: "ok",
        usesMove: false,
        after: balance + item.price,
        itemId: item.id,
      });
    }

    // Escolhe UMA sugestão, com uma regra simples e explicável.
    const byAction = (name) => options.find((option) => option.action === name);
    let suggested = null;
    let reason = "";
    const sell = byAction("vender");
    const study = byAction("estudar");
    const invest = byAction("investir");
    if (net <= 0 && sell && item && item.expense > 0) {
      suggested = sell;
      reason = "Suas despesas estão maiores que o salário. Vender um item com despesa ajuda a equilibrar.";
    } else if (study.tone === "ok" && afterStudy >= fixedExpenses) {
      suggested = study;
      reason = "Ainda há tempo de jogo: estudar cedo aumenta tudo o que você vai ganhar depois.";
    } else if (byAction("trabalhar").tone !== "danger" && net > 0) {
      suggested = byAction("trabalhar");
      reason = "Trabalhar é a jogada segura: o saldo aumenta e as despesas ficam pagas.";
    } else if (invest.tone === "ok") {
      suggested = invest;
      reason = "Dinheiro guardado rende no fim da rodada.";
    }
    for (const option of options) option.suggested = option === suggested;
    if (suggested) suggested.reason = reason;
    // Ordem fixa e previsível: sugestão primeiro, depois a ordem dos botões.
    const order = ["trabalhar", "estudar", "investir", "resgatar", "comprar", "vender"];
    options.sort((a, b) => (b.suggested - a.suggested) || order.indexOf(a.action) - order.indexOf(b.action));
    return options;
  }

  // Métricas da sessão atual, a partir dos eventos normalizados (mais novo primeiro
  // ou mais antigo primeiro: a função ordena por sequência quando houver).
  function sessionStats(events, catalog = []) {
    const list = [...events].filter((event) => !event.isSelector)
      .sort((a, b) => (a.seq ?? 0) - (b.seq ?? 0));
    const priceOf = (id) => catalog.find((item) => item.id === id)?.price ?? 0;
    const stats = {
      counts: { trabalhar: 0, estudar: 0, investir: 0, resgatar: 0, compras: 0, recusadas: 0, vendas: 0, rodadas: 0 },
      income: { salario: 0, vendas: 0, resgates: 0, rendimento: 0 },
      spending: { despesas: 0, estudo: 0, compras: 0, investido: 0 },
      salaryStart: null, salaryEnd: null,
      balanceStart: null, balanceEnd: null, balanceMin: null, balanceMax: null,
      purchasedWithoutDebt: 0,
      extraFromStudy: 0, // salário a mais recebido por causa dos estudos
      roundsWithMoreMoney: 0,
      finished: false, bankrupt: false,
    };
    let previousInvestments = null;
    let roundStartBalance = null;
    for (const event of list) {
      const code = String(event.event || "").toLowerCase();
      if (Number.isFinite(event.balance)) {
        if (stats.balanceStart === null) stats.balanceStart = event.balance;
        stats.balanceEnd = event.balance;
        stats.balanceMin = stats.balanceMin === null ? event.balance : Math.min(stats.balanceMin, event.balance);
        stats.balanceMax = stats.balanceMax === null ? event.balance : Math.max(stats.balanceMax, event.balance);
        if (roundStartBalance === null) roundStartBalance = event.balance;
      }
      if (Number.isFinite(event.salary)) {
        if (stats.salaryStart === null) stats.salaryStart = event.salary;
        stats.salaryEnd = event.salary;
      }
      const fixed = Number.isFinite(event.fixedExpenses) ? event.fixedExpenses : 0;
      if (code === "trabalhar") {
        stats.counts.trabalhar += 1;
        stats.income.salario += Number.isFinite(event.salary) ? event.salary : 0;
        if (stats.counts.estudar > 0 && Number.isFinite(event.salary) && stats.salaryStart !== null) {
          stats.extraFromStudy += Math.max(0, event.salary - stats.salaryStart);
        }
        stats.spending.despesas += fixed;
      } else if (code === "estudar") {
        stats.counts.estudar += 1;
        stats.spending.estudo += RULES.studyCost;
        stats.spending.despesas += fixed;
      } else if (code === "investir") {
        stats.counts.investir += 1;
        stats.spending.investido += RULES.investStep;
      } else if (code === "resgatar") {
        stats.counts.resgatar += 1;
        const back = Number.isFinite(event.amount) ? Math.abs(event.amount) : RULES.investStep;
        stats.income.resgates += back;
      } else if (code === "compra_aprovada") {
        stats.counts.compras += 1;
        stats.spending.compras += priceOf(event.itemId);
        if (Number.isFinite(event.balance) && event.balance >= 0) stats.purchasedWithoutDebt += 1;
      } else if (code === "compra_recusada") {
        stats.counts.recusadas += 1;
      } else if (code === "venda_aprovada") {
        stats.counts.vendas += 1;
        stats.income.vendas += priceOf(event.itemId);
      } else if (code === "fim_rodada") {
        stats.counts.rodadas += 1;
        if (Number.isFinite(event.investments) && previousInvestments !== null && event.investments > previousInvestments) {
          stats.income.rendimento += event.investments - previousInvestments;
        }
        if (Number.isFinite(event.balance) && roundStartBalance !== null && event.balance > roundStartBalance) {
          stats.roundsWithMoreMoney += 1;
        }
        if (Number.isFinite(event.balance)) roundStartBalance = event.balance;
      } else if (code === "fim_jogo") {
        stats.finished = true;
      } else if (code === "falencia") {
        stats.bankrupt = true;
      }
      if (Number.isFinite(event.investments)) previousInvestments = event.investments;
    }
    stats.totalIn = Object.values(stats.income).reduce((sum, value) => sum + value, 0);
    stats.totalOut = Object.values(stats.spending).reduce((sum, value) => sum + value, 0);
    stats.salaryGrowth = stats.salaryStart !== null && stats.salaryEnd !== null ? stats.salaryEnd - stats.salaryStart : 0;
    return stats;
  }

  // Conquistas de aprendizado: cada uma ensina uma ideia de economia.
  function lessons(stats) {
    return [
      { id: "salario", icon: "💼", title: "Primeiro salário", idea: "Trabalhar traz dinheiro novo.",
        done: stats.counts.trabalhar > 0 },
      { id: "estudo", icon: "📚", title: "Investiu em você", idea: "Estudar custa agora e aumenta o salário depois.",
        done: stats.counts.estudar > 0 },
      { id: "estudo-pago", icon: "🎓", title: "O estudo se pagou", idea: `Depois de estudar, o salário a mais já devolveu o custo do estudo.`,
        done: stats.counts.estudar > 0 && stats.extraFromStudy >= RULES.studyCost * stats.counts.estudar },
      { id: "rendimento", icon: "🌱", title: "Dinheiro que cresce", idea: "Dinheiro investido rende no fim da rodada.",
        done: stats.income.rendimento > 0 },
      { id: "compra-planejada", icon: "🛒", title: "Compra planejada", idea: "Comprou um item e o saldo continuou positivo.",
        done: stats.purchasedWithoutDebt > 0 },
      { id: "rodada-positiva", icon: "📈", title: "Rodada no azul", idea: "Terminou uma rodada com mais dinheiro do que começou.",
        done: stats.roundsWithMoreMoney > 0 },
      { id: "fim", icon: "🏆", title: "Chegou ao fim", idea: "Jogou as 15 rodadas sem ficar com saldo negativo.",
        done: stats.finished && !stats.bankrupt },
    ];
  }

  // Identidade divertida e fixa para cada cartão (mesmo UID → mesmo bicho).
  const CARD_ANIMALS = [
    ["🦊", "Raposa"], ["🐢", "Tartaruga"], ["🦉", "Coruja"], ["🐬", "Golfinho"],
    ["🦁", "Leão"], ["🐼", "Panda"], ["🐸", "Sapo"], ["🦋", "Borboleta"],
    ["🐙", "Polvo"], ["🦒", "Girafa"], ["🐧", "Pinguim"], ["🐝", "Abelha"],
  ];
  const CARD_COLORS = ["#ef8c45", "#4bb7dc", "#55b85a", "#9f82cf", "#f0bf38", "#e78d76"];
  function cardIdentity(uid) {
    if (typeof uid !== "string" || !uid) return null;
    let hash = 0;
    for (const char of uid.toUpperCase()) hash = (hash * 31 + char.charCodeAt(0)) >>> 0;
    const [emoji, animal] = CARD_ANIMALS[hash % CARD_ANIMALS.length];
    return { uid: uid.toUpperCase(), emoji, animal, label: `Cartão ${animal}`, color: CARD_COLORS[(hash >>> 4) % CARD_COLORS.length] };
  }

  const api = { RULES, movesLeft, netPerWork, workMovesFor, suggestNextMoves, sessionStats, lessons, cardIdentity };
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.AEFLearning = api;
})(typeof globalThis !== "undefined" ? globalThis : this);

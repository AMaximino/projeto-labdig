(() => {
  "use strict";

  const TOPIC_DEFAULT = "aventura_financeira/telemetria";
  const SESSION_KEY = "aef-session-v1";
  const PREFS_KEY = "aef-preferences-v1";
  const MAX_EVENTS = 300;
  const BRL = new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" });

  const catalog = [
    { id: 1, name: "Carro compacto", icon: "🚗", price: 60000, expense: 3600 },
    { id: 2, name: "Carro familiar", icon: "🚙", price: 100000, expense: 4800 },
    { id: 3, name: "Carro premium", icon: "🚘", price: 200000, expense: 8000 },
    { id: 4, name: "Casa pequena", icon: "🏠", price: 500000, expense: 2400 },
    { id: 5, name: "Casa confortável", icon: "🏡", price: 900000, expense: 3200 },
    { id: 6, name: "Casa dos sonhos", icon: "🏰", price: 1900000, expense: 6000 },
    { id: 7, name: "Computador gamer", icon: "🖥️", price: 12000, expense: 0 },
    { id: 8, name: "Jogos de tabuleiro", icon: "🎲", price: 8000, expense: 0 },
    { id: 9, name: "Coleção de livros", icon: "📚", price: 20000, expense: 0 },
    { id: 10, name: "Kit de LEGO", icon: "🧱", price: 42000, expense: 0 },
  ];
  const demoInitial = {
    balance: 15000,
    salary: 6400,
    investments: 0,
    yield: 0,
    fixedExpenses: 4000,
    uniqueExpenses: 0,
    round: 1,
    move: 1,
  };
  const $ = (selector) => document.querySelector(selector);
  const ui = {
    balance: $("#balance-value"),
    income: $("#income-value"),
    investment: $("#investment-value"),
    yield: $("#yield-value"),
    fixedExpenses: $("#fixed-expenses-value"),
    uniqueExpenses: $("#variable-expenses-value"),
    round: $("#round-current"),
    moves: $("#moves-value"),
    history: $("#history-list"),
    historyEmpty: $("#history-empty"),
    historyCount: $("#history-count"),
    historySummary: $("#history-summary"),
    chartLine: $("#chart-line"),
    chartArea: $("#chart-area"),
    chartPoint: $("#chart-point"),
    connectionPill: $("#connection-pill"),
    connectionLabel: $("#connection-label"),
    sidebarDot: $("#sidebar-device-dot"),
    sidebarTitle: $("#sidebar-device-title"),
    sidebarSubtitle: $("#sidebar-device-subtitle"),
    feedback: $("#connection-feedback"),
    connectButton: $("#connect-button"),
    disconnectButton: $("#disconnect-button"),
    settingsDialog: $("#settings-dialog"),
    form: $("#settings-form"),
    toastRegion: $("#toast-region"),
  };

  const readStored = (key, fallback) => {
    try {
      const saved = localStorage.getItem(key);
      return saved ? JSON.parse(saved) : fallback;
    } catch (error) {
      console.warn(`Não foi possível ler ${key} do armazenamento local.`, error);
      return fallback;
    }
  };

  const prefs = readStored(PREFS_KEY, {});
  const savedSession = readStored(SESSION_KEY, null);
  const state = {
    ...demoInitial,
    ...(savedSession?.metrics || {}),
    move: savedSession?.metrics?.move || 1,
    events: Array.isArray(savedSession?.events) ? savedSession.events : [],
    history: Array.isArray(savedSession?.history) ? savedSession.history : [demoInitial.balance],
    inventory: Array.isArray(savedSession?.inventory) ? savedSession.inventory : [],
    metricAvailable: {
      balance: true,
      salary: true,
      investments: true,
      yield: true,
      fixedExpenses: true,
      uniqueExpenses: true,
      ...(savedSession?.metricAvailable || {}),
    },
    hasLiveConnection: false,
    mode: "demo",
    playerName: typeof prefs.playerName === "string" ? prefs.playerName : "",
    mqttClient: null,
    reconnectTimer: null,
    visibleLimit: 5,
  };

  function persistSession() {
    const { mqttClient, reconnectTimer, ...persisted } = state;
    try {
      localStorage.setItem(SESSION_KEY, JSON.stringify({
        metrics: {
          balance: persisted.balance,
          salary: persisted.salary,
          investments: persisted.investments,
          yield: persisted.yield,
          fixedExpenses: persisted.fixedExpenses,
          uniqueExpenses: persisted.uniqueExpenses,
          round: persisted.round,
          move: persisted.move,
        },
        metricAvailable: persisted.metricAvailable,
        events: persisted.events.slice(0, MAX_EVENTS),
        history: persisted.history.slice(-30),
        inventory: persisted.inventory,
      }));
    } catch (error) {
      console.warn("Não foi possível salvar a sessão no navegador.", error);
      showToast("Não foi possível salvar a sessão neste navegador.", true);
    }
  }

  function persistPreferences() {
    try {
      localStorage.setItem(PREFS_KEY, JSON.stringify({
        broker: $("#broker-url").value.trim(),
        topic: $("#mqtt-topic").value.trim() || TOPIC_DEFAULT,
        backendUrl: $("#backend-url").value.trim(),
        transport: $("#connection-mode").value,
        playerName: state.playerName,
      }));
    } catch (error) {
      console.warn("Não foi possível salvar as preferências no navegador.", error);
      showToast("Não foi possível salvar as preferências.", true);
    }
  }

  function showToast(message, isError = false) {
    const toast = document.createElement("div");
    toast.className = `toast${isError ? " error" : ""}`;
    toast.textContent = message;
    ui.toastRegion.append(toast);
    window.setTimeout(() => toast.remove(), 4200);
  }

  function displayMoney(amount) {
    return BRL.format(Number.isFinite(amount) ? amount : 0);
  }

  function displayCompactMoney(amount) {
    if (!Number.isFinite(amount)) return "Aguardando…";
    if (Math.abs(amount) >= 1_000_000) {
      return `R$ ${new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 }).format(amount / 1_000_000)} mi`;
    }
    if (Math.abs(amount) >= 1_000) {
      return `R$ ${new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 }).format(amount / 1_000)} mil`;
    }
    return `R$ ${new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 0 }).format(amount)}`;
  }

  function setMoneyDisplay(selector, amount) {
    const element = $(selector);
    const exact = Number.isFinite(amount) ? displayMoney(amount) : "Aguardando dados";
    element.textContent = Number.isFinite(amount) ? displayCompactMoney(amount) : "Aguardando…";
    element.title = exact;
    element.setAttribute("aria-label", `Valor exato: ${exact}`);
    const exactElement = $(`${selector}-exact`);
    if (exactElement) exactElement.textContent = `Valor exato: ${exact}`;
  }

  function safeText(value, fallback = "") {
    return typeof value === "string" ? value.trim() : fallback;
  }

  function setConnection(mode, message = "") {
    state.mode = mode;
    const connected = mode === "connected";
    const error = mode === "error";
    ui.connectionPill.className = `connection-pill${connected ? " connected" : error ? " error" : " demo"}`;
    ui.sidebarDot.className = `device-dot${connected ? " connected" : error ? " error" : ""}`;
    ui.connectionLabel.textContent = connected
      ? state.transport === "backend" ? "Backend conectado" : "ESP8266 conectada"
      : error ? "Falha na conexão" : "Modo demonstração";
    ui.sidebarTitle.textContent = connected ? "Recebendo dados" : error ? "Conexão indisponível" : "Modo demonstração";
    ui.sidebarSubtitle.textContent = connected
      ? state.transport === "backend" ? "WebSocket • ao vivo" : "MQTT • ao vivo"
      : error ? "Verifique a conexão" : "Dados de exemplo";
    $("#balance-live-label").textContent = connected ? "AO VIVO" : "DEMO";
    ui.disconnectButton.hidden = !connected && !state.mqttClient && !state.backendSocket;
    const demoButton = $("#demo-event-button");
    if (demoButton) demoButton.hidden = connected;
    if ($("#game-round-value")) renderGame();
    if (message) setFeedback(message, error ? "error" : connected ? "success" : "");
  }

  function setFeedback(message, kind = "") {
    ui.feedback.textContent = message;
    ui.feedback.className = `connection-feedback${kind ? ` ${kind}` : ""}`;
  }

  function eventPresentation(event) {
    const value = (event.event || event.label || "").toLowerCase();
    if (/recus|insuficiente|rejeitad|negad/.test(value)) return { icon: "!", className: "refused", label: "Compra não realizada" };
    if (/trabalh|sal.rio|renda/.test(value)) return { icon: "↗", className: "income", label: "Salário recebido" };
    if (/resgat/.test(value)) return { icon: "↗", className: "income", label: "Resgate de investimento" };
    if (/compra|comprar|pagamento|item/.test(value)) {
      return { icon: "↘", className: "expense", label: event.itemName || (event.label && event.label !== event.event ? event.label : "Compra realizada") };
    }
    if (/estud/.test(value)) return { icon: "↘", className: "expense", label: "Estudo" };
    if (/invest/.test(value)) return { icon: "✳", className: "expense", label: "Investimento realizado" };
    if (/vender|venda/.test(value)) return { icon: "↗", className: "income", label: event.itemName ? `Venda: ${event.itemName}` : "Venda realizada" };
    if (/rodada|fim_de_rodada|fim_rodada/.test(value)) return { icon: "◎", className: "neutral", label: "Nova rodada" };
    return { icon: "•", className: "neutral", label: event.label || event.event || "Atualização do jogo" };
  }

  function renderEvent(event, index) {
    const presentation = eventPresentation(event);
    const row = document.createElement("div");
    row.className = "history-row";
    row.setAttribute("role", "listitem");

    const activity = document.createElement("span");
    activity.className = "history-activity";
    const icon = document.createElement("span");
    icon.className = `activity-icon ${presentation.className}`;
    icon.setAttribute("aria-hidden", "true");
    icon.textContent = presentation.icon;
    const text = document.createElement("span");
    const label = document.createElement("strong");
    label.textContent = presentation.label;
    text.append(label);
    if (event.detail || (event.itemName && presentation.label !== event.itemName)) {
      const detail = document.createElement("small");
      detail.textContent = event.detail || event.itemName;
      text.append(detail);
    }
    activity.append(icon, text);

    const round = document.createElement("span");
    round.textContent = `Rodada ${event.round ?? state.round}`;
    const amount = document.createElement("span");
    amount.className = `amount${presentation.className === "expense" ? " negative" : presentation.className === "neutral" || presentation.className === "refused" ? " neutral" : ""}`;
    if (presentation.className === "refused") {
      amount.textContent = "Não realizada";
      const refusedTag = document.createElement("span");
      refusedTag.className = "event-status";
      refusedTag.textContent = "RECUSADA";
      amount.append(refusedTag);
    } else {
      const numericAmount = Number(event.amount);
      amount.textContent = Number.isFinite(numericAmount) && numericAmount !== 0
        ? `${numericAmount > 0 ? "+" : "−"} ${displayMoney(Math.abs(numericAmount))}`
        : "—";
    }
    const afterBalance = document.createElement("span");
    afterBalance.className = "after-balance";
    afterBalance.textContent = typeof event.balance === "number" && Number.isFinite(event.balance)
      ? displayMoney(event.balance) : "—";
    const time = document.createElement("span");
    time.textContent = event.time || "Agora";
    row.append(activity, round, amount, afterBalance, time);
    row.dataset.index = String(index);
    return row;
  }

  function drawChart() {
    const values = state.history.slice(-12);
    if (values.length < 2) {
      ui.chartLine.setAttribute("d", "M 10 34 L 230 34");
      ui.chartArea.setAttribute("d", "M 10 34 L 230 34 L 230 48 L 10 48 Z");
      ui.chartPoint.setAttribute("cx", "230");
      ui.chartPoint.setAttribute("cy", "34");
      $("#stats-chart-line").setAttribute("d", "M 10 48 L 230 48");
      $("#stats-chart-area").setAttribute("d", "M 10 48 L 230 48 L 230 70 L 10 70 Z");
      $("#stats-chart-point").setAttribute("cx", "230");
      $("#stats-chart-point").setAttribute("cy", "48");
      return;
    }
    const min = Math.min(...values);
    const max = Math.max(...values);
    const range = max - min || 1;
    const points = values.map((value, index) => {
      const x = 10 + (220 * index) / Math.max(values.length - 1, 1);
      const y = 39 - ((value - min) / range) * 28;
      return `${x.toFixed(1)} ${y.toFixed(1)}`;
    });
    const line = `M ${points.join(" L ")}`;
    ui.chartLine.setAttribute("d", line);
    ui.chartArea.setAttribute("d", `${line} L 230 48 L 10 48 Z`);
    const [lastX, lastY] = points[points.length - 1].split(" ");
    ui.chartPoint.setAttribute("cx", lastX);
    ui.chartPoint.setAttribute("cy", lastY);
    const statsPoints = values.map((value, index) => {
      const x = 10 + (220 * index) / Math.max(values.length - 1, 1);
      const y = 61 - ((value - min) / range) * 48;
      return `${x.toFixed(1)} ${y.toFixed(1)}`;
    });
    const statsLine = `M ${statsPoints.join(" L ")}`;
    $("#stats-chart-line").setAttribute("d", statsLine);
    $("#stats-chart-area").setAttribute("d", `${statsLine} L 230 70 L 10 70 Z`);
    const [statsLastX, statsLastY] = statsPoints[statsPoints.length - 1].split(" ");
    $("#stats-chart-point").setAttribute("cx", statsLastX);
    $("#stats-chart-point").setAttribute("cy", statsLastY);
  }

  function renderGame() {
    $("#game-round-value").textContent = String(state.round);
    $("#game-move-value").textContent = String(Math.min(Math.max(state.move, 1), 3));
    setMoneyDisplay("#game-balance-value", state.metricAvailable.balance ? state.balance : Number.NaN);
    $("#game-balance-hint").textContent = state.metricAvailable.balance
      ? state.mode === "connected"
        ? state.transport === "backend" ? "Saldo recebido pelo backend do jogo." : "Saldo recebido pelo ESP8266."
        : "Esse é o valor que você tem para usar."
      : "Aguardando o primeiro dado do jogo.";
    setMoneyDisplay("#game-income-value", state.metricAvailable.salary ? state.salary : Number.NaN);
    setMoneyDisplay("#game-investment-value", state.metricAvailable.investments ? state.investments : Number.NaN);
    setMoneyDisplay("#game-expenses-value", state.metricAvailable.fixedExpenses ? state.fixedExpenses : Number.NaN);
    for (let move = 1; move <= 3; move += 1) {
      const progress = $(`#move-step-${move}`);
      progress.classList.toggle("done", move < state.move);
      progress.classList.toggle("current", move === state.move);
      progress.setAttribute("aria-label", `Jogada ${move}${move === state.move ? ", atual" : ""}`);
    }

    renderLastMove();
    renderInventory();
    renderShop();
    renderStats();
    syncCalculatorWithGame();
  }

  function renderLastMove() {
    const event = state.events[0];
    if (!event) return;
    const presentation = eventPresentation(event);
    const icon = $("#last-move-icon");
    icon.className = `last-move-icon ${presentation.className}`;
    icon.textContent = presentation.icon;
    $("#last-move-label").textContent = presentation.className === "refused" ? "COMPRA NÃO REALIZADA" : "ÚLTIMA ATUALIZAÇÃO";
    $("#last-move-title-value").textContent = presentation.label;
    const detail = event.detail || (typeof event.amount === "number" && event.amount !== 0
      ? `${event.amount > 0 ? "+" : "−"} ${displayMoney(Math.abs(event.amount))}${typeof event.balance === "number" ? ` · saldo ${displayMoney(event.balance)}` : ""}`
      : typeof event.balance === "number" ? `Saldo após a jogada: ${displayMoney(event.balance)}` : "Dados recebidos do tabuleiro.");
    $("#last-move-description").textContent = detail;
    $("#last-move-time").textContent = event.time || "Agora";
  }

  function renderInventory() {
    const inventory = state.inventory
      .map((id) => catalog.find((item) => item.id === id))
      .filter(Boolean);
    $("#inventory-count").textContent = `${inventory.length} ${inventory.length === 1 ? "item no inventário" : "itens no inventário"}`;
    const list = $("#inventory-list");
    if (!inventory.length) {
      list.innerHTML = '<span class="inventory-empty-icon" aria-hidden="true">✦</span><strong>Seu inventário está vazio</strong><span>Suas conquistas vão aparecer aqui.</span>';
      return;
    }
    list.replaceChildren(...inventory.map((item) => {
      const badge = document.createElement("span");
      badge.className = "inventory-item";
      const icon = document.createElement("span");
      icon.setAttribute("aria-hidden", "true");
      icon.textContent = item.icon;
      const name = document.createElement("span");
      name.textContent = item.name;
      badge.append(icon, name);
      return badge;
    }));
  }

  function renderShop() {
    const shop = $("#shop-grid");
    $("#shop-count").textContent = `${catalog.length} itens`;
    shop.replaceChildren(...catalog.map((item) => {
      const owned = state.inventory.includes(item.id);
      const canAfford = state.metricAvailable.balance && state.balance >= item.price;
      const card = document.createElement("article");
      card.className = `product-card${owned ? " owned" : !canAfford ? " unaffordable" : ""}`;
      const top = document.createElement("div");
      top.className = "product-top";
      const glyph = document.createElement("span");
      glyph.className = "product-glyph";
      glyph.setAttribute("aria-hidden", "true");
      glyph.textContent = item.icon;
      const status = document.createElement("span");
      status.className = `product-status${!owned && !canAfford ? " locked" : ""}`;
      status.textContent = owned ? "NO INVENTÁRIO" : !state.metricAvailable.balance ? "AGUARDANDO" : canAfford ? "PODE COMPRAR" : "AINDA NÃO";
      top.append(glyph, status);
      const title = document.createElement("strong");
      title.textContent = item.name;
      const price = document.createElement("span");
      price.className = "product-price";
      price.textContent = displayCompactMoney(item.price);
      price.title = `Valor exato: ${displayMoney(item.price)}`;
      price.setAttribute("aria-label", `Valor exato: ${displayMoney(item.price)}`);
      const expense = document.createElement("span");
      expense.className = `product-expense${item.expense ? " has-expense" : ""}`;
      expense.textContent = item.expense ? `+ ${displayCompactMoney(item.expense)} por rodada` : "Sem despesa por rodada";
      if (item.expense) expense.title = `Valor exato: ${displayMoney(item.expense)} por rodada`;
      if (!owned && state.metricAvailable.balance && !canAfford) {
        const gap = document.createElement("span");
        gap.className = "product-gap";
        gap.textContent = `Faltam ${displayCompactMoney(item.price - state.balance)}`;
        gap.title = `Faltam ${displayMoney(item.price - state.balance)}`;
        card.append(top, title, price, gap, expense);
      } else {
        card.append(top, title, price, expense);
      }
      const stateLabel = document.createElement("span");
      stateLabel.className = "product-display-status";
      if (owned) {
        stateLabel.textContent = "✓ No seu inventário";
      } else if (!state.metricAvailable.balance) {
        stateLabel.textContent = "Aguardando saldo";
      } else if (canAfford) {
        stateLabel.textContent = "Cabe no seu saldo";
      } else {
        stateLabel.textContent = `Faltam ${displayMoney(item.price - state.balance)}`;
      }
      card.append(stateLabel);
      return card;
    }));
  }

  function renderStats() {
    const entries = state.events;
    const countEvent = (pattern) => entries.filter((event) => pattern.test(`${event.event || ""} ${event.label || ""}`.toLowerCase())).length;
    $("#stats-events").textContent = String(entries.length);
    $("#stats-purchases").textContent = String(countEvent(/compra_aprov|compra_feita|comprar/));
    $("#stats-refusals").textContent = String(entries.filter((event) => event.kind === "refused").length);
    setMoneyDisplay("#stats-balance", state.metricAvailable.balance ? state.balance : Number.NaN);
    $("#stats-session-note").textContent = entries.length
      ? `${entries.length} atualizações registradas. Os valores acompanham o estado enviado pelo tabuleiro.`
      : state.mode === "connected"
        ? "Conectado. Aguardando a primeira atualização da partida."
        : "Ainda não há jogadas recebidas. Os dados iniciais são apenas uma demonstração.";
  }

  function fillCalculatorItemOptions() {
    const select = $("#calc-item");
    select.replaceChildren(new Option("Não escolher um item", ""));
    for (const item of catalog) {
      const option = new Option(`${item.icon} ${item.name} · ${displayCompactMoney(item.price)}`, String(item.id));
      select.add(option);
    }
  }

  function syncCalculatorWithGame() {
    const form = $("#calculator-form");
    if (!form || form.dataset.edited === "true") return;
    $("#calc-balance").value = String(state.balance);
    $("#calc-income").value = String(state.salary);
    $("#calc-expenses").value = String(state.fixedExpenses);
  }

  function calculateEstimate(event) {
    event.preventDefault();
    const form = $("#calculator-form");
    if (!form.reportValidity()) return;
    const balance = Number($("#calc-balance").value);
    const income = Number($("#calc-income").value);
    const purchase = Number($("#calc-purchase").value);
    const expenses = Number($("#calc-expenses").value);
    if (![balance, income, purchase, expenses].every((value) => Number.isFinite(value) && value >= 0)) {
      showToast("Use valores iguais ou maiores que zero.", true);
      return;
    }
    const remaining = balance + income - purchase - expenses;
    $("#calc-result-value").textContent = displayCompactMoney(remaining);
    $("#calc-result-value").title = `Valor exato: ${displayMoney(remaining)}`;
    $("#calc-result-exact").textContent = `Valor exato: ${displayMoney(remaining)}`;
    const message = $("#calc-result-message");
    message.className = `calculator-message${remaining < 0 ? " negative" : " positive"}`;
    message.textContent = remaining < 0
      ? `Faltariam ${displayMoney(Math.abs(remaining))} para cobrir esses valores.`
      : "Esse valor sobraria depois das entradas e despesas informadas.";
  }

  function activateTab(tabName, scrollTarget) {
    document.querySelectorAll("[data-tab-panel]").forEach((panel) => {
      panel.hidden = panel.dataset.tabPanel !== tabName;
    });
    document.querySelectorAll("[data-app-tab]").forEach((link) => {
      const active = link.dataset.appTab === tabName && !link.dataset.appScroll;
      link.classList.toggle("active", active);
      if (active) link.setAttribute("aria-current", "page");
      else link.removeAttribute("aria-current");
    });
    if (scrollTarget) {
      window.setTimeout(() => document.getElementById(scrollTarget)?.scrollIntoView({ behavior: "smooth", block: "start" }), 0);
    } else {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }

  function render() {
    setMoneyDisplay("#balance-value", state.metricAvailable.balance ? state.balance : Number.NaN);
    $("#balance-caption").textContent = state.metricAvailable.balance
      ? "Esse é o valor que você tem para usar."
      : "Aguardando o primeiro dado do jogo.";
    setMoneyDisplay("#income-value", state.metricAvailable.salary ? state.salary : Number.NaN);
    setMoneyDisplay("#investment-value", state.metricAvailable.investments ? state.investments : Number.NaN);
    ui.yield.textContent = state.metricAvailable.yield ? `${displayCompactMoney(state.yield)} de rendimento` : "Aguardando dados";
    ui.yield.title = state.metricAvailable.yield ? `Valor exato: ${displayMoney(state.yield)} de rendimento` : "Aguardando dados";
    setMoneyDisplay("#fixed-expenses-value", state.metricAvailable.fixedExpenses ? state.fixedExpenses : Number.NaN);
    setMoneyDisplay("#variable-expenses-value", state.metricAvailable.uniqueExpenses ? state.uniqueExpenses : Number.NaN);
    ui.round.textContent = String(state.round);
    ui.moves.textContent = `${state.events.length} ${state.events.length === 1 ? "jogada registrada" : "jogadas registradas"}`;
    ui.historyCount.textContent = String(state.events.length);
    ui.historyEmpty.hidden = state.events.length > 0;
    ui.history.replaceChildren(...state.events.slice(0, state.visibleLimit).map(renderEvent));
    ui.history.setAttribute("role", "list");
    ui.historySummary.textContent = state.events.length
      ? `Mostrando ${Math.min(state.visibleLimit, state.events.length)} de ${state.events.length} movimentações`
      : "Aguardando movimentações";
    $("#view-all-button").hidden = state.events.length <= state.visibleLimit;
    const maxExpense = Math.max(state.salary + state.fixedExpenses + state.uniqueExpenses, 1);
    $("#fixed-expenses-bar").style.width = state.metricAvailable.fixedExpenses
      ? `${Math.min(100, (state.fixedExpenses / maxExpense) * 100)}%` : "0%";
    $("#variable-expenses-bar").style.width = state.metricAvailable.uniqueExpenses
      ? `${Math.min(100, (state.uniqueExpenses / maxExpense) * 100)}%` : "0%";
    $("#player-name-heading").textContent = state.playerName || "Jogador";
    $("#player-avatar").textContent = (state.playerName || "J").trim().charAt(0).toLocaleUpperCase("pt-BR");
    drawChart();
    renderGame();
  }

  function firstValue(source, keys) {
    for (const key of keys) {
      const value = source[key];
      if (value !== undefined && value !== null && value !== "") return value;
    }
    return undefined;
  }

  function toAmount(value) {
    if (typeof value === "number" && Number.isFinite(value)) return value;
    if (typeof value !== "string") return undefined;
    const cleaned = value.trim().replace(/[R$\s]/g, "");
    if (!cleaned) return undefined;
    const normalized = cleaned.includes(",")
      ? cleaned.replace(/\./g, "").replace(",", ".")
      : cleaned;
    const amount = Number(normalized);
    return Number.isFinite(amount) ? amount : undefined;
  }

  function readMoney(source, realFields, centFields) {
    const cents = toAmount(firstValue(source, centFields));
    if (cents !== undefined) return cents / 100;
    return toAmount(firstValue(source, realFields));
  }

  function normalizeEvent(payload) {
    const nested = payload.dados && typeof payload.dados === "object"
      ? payload.dados
      : payload.data && typeof payload.data === "object"
        ? payload.data
        : payload;
    const eventCode = String(firstValue(nested, ["evento", "event", "tipo_evento", "tipo", "type", "acao", "action"]) || "atualizacao");
    const lowerCode = eventCode.toLowerCase();
    const balance = readMoney(
      nested,
      ["saldo", "balance", "saldo_atual", "saldo_final", "valor_saldo", "valor_resultante"],
      ["saldo_centavos", "balance_cents"],
    );
    const itemValue = firstValue(nested, ["item", "item_id", "id_item", "produto"]);
    const itemIndex = Number(itemValue);
    const itemName = Number.isInteger(itemIndex) && itemIndex > 0 && itemIndex <= catalog.length
      ? catalog[itemIndex - 1].name
      : (typeof itemValue === "string" && Number.isNaN(itemIndex) ? itemValue : "");
    const explicitAmount = readMoney(
      nested,
      ["valor_transacao", "valor_compra", "amount", "transaction_amount"],
      ["delta_saldo_centavos", "valor_transacao_centavos", "transaction_amount_cents"],
    );
    const previousBalance = state.balance;
    const hasPreviousBalance = state.metricAvailable.balance;
    let amount = balance !== undefined
      ? hasPreviousBalance ? balance - previousBalance : explicitAmount
      : explicitAmount;
    if (!hasPreviousBalance && amount !== undefined) {
      if (amount > 0 && /compra|comprar|estud|investir|investimento_realizado/.test(lowerCode)) amount = -amount;
      if (amount < 0 && /resgat|vender|venda/.test(lowerCode)) amount = Math.abs(amount);
    }

    const roundValue = Number(firstValue(nested, ["rodada", "round", "rodada_atual"]));
    const moveValue = Number(firstValue(nested, ["jogada", "move", "jogada_atual"]));
    const labelValue = firstValue(nested, ["descricao", "description", "nome_evento"]);
    const event = {
      event: eventCode,
      label: typeof labelValue === "string" ? labelValue : eventCode,
      kind: /recus|insuficiente|negad/.test(lowerCode) || nested.status === "recusada" ? "refused" : undefined,
      itemName,
      detail: safeText(firstValue(nested, ["detalhe", "detail"])),
      amount,
      balance: balance === undefined ? undefined : balance,
      round: Number.isFinite(roundValue) && roundValue > 0 ? roundValue : undefined,
      time: new Date().toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" }),
    };

    if (balance !== undefined) state.metricAvailable.balance = true;
    for (const [property, keys] of Object.entries({
      salary: { real: ["salario", "salary", "renda"], cents: ["salario_centavos", "salary_cents"] },
      investments: { real: ["investido", "investimentos", "valor_investido", "investment"], cents: ["valor_investido_centavos", "investment_cents"] },
      yield: { real: ["rendimento", "yield"], cents: ["rendimento_centavos", "yield_cents"] },
      fixedExpenses: { real: ["gastos_fixos", "despesas_fixas", "fixed_expenses"], cents: ["gastos_fixos_centavos", "fixed_expenses_cents"] },
      uniqueExpenses: { real: ["gastos_unicos", "gastos_únicos", "despesas_variaveis", "unique_expenses"], cents: ["gastos_unicos_centavos", "unique_expenses_cents"] },
    })) {
      const value = readMoney(nested, keys.real, keys.cents);
      if (value !== undefined) {
        state[property] = value;
        state.metricAvailable[property] = true;
      }
    }
    const previousRound = state.round;
    if (event.round) state.round = event.round;
    const roundEnded = /fim_de_rodada|fim_rodada|rodada_encerrada/.test(lowerCode);
    if (roundEnded) {
      state.round = event.round > previousRound ? event.round : previousRound + 1;
      state.move = 1;
    } else if (Number.isInteger(moveValue) && moveValue >= 1 && moveValue <= 3) {
      state.move = moveValue;
    } else if (/trabalh|estud/.test(lowerCode)) {
      state.move = Math.min(state.move + 1, 3);
    }
    const incomingItems = firstValue(nested, ["inventario", "inventario_mask", "inventory", "itens", "items", "inventory_mask"]);
    if (Array.isArray(incomingItems)) {
      state.inventory = incomingItems
        .map((entry) => Number(entry))
        .filter((id) => Number.isInteger(id) && catalog.some((item) => item.id === id));
    } else if (Number.isInteger(Number(incomingItems)) && incomingItems !== undefined) {
      const mask = Number(incomingItems);
      state.inventory = catalog.filter((item) => mask & (1 << (item.id - 1))).map((item) => item.id);
    } else if (itemName && !event.kind) {
      const item = catalog.find((entry) => entry.name === itemName);
      if (item && /compra_aprov|comprar|compra_feita/.test(lowerCode)) {
        state.inventory = [...new Set([...state.inventory, item.id])];
      } else if (item && /vender|venda_aprov|item_vendido/.test(lowerCode)) {
        state.inventory = state.inventory.filter((id) => id !== item.id);
      }
    }
    if (balance !== undefined) {
      state.balance = balance;
      state.history.push(balance);
    }
    return event;
  }

  function recordPayload(payload, topic) {
    const event = normalizeEvent(payload);
    event.topic = topic;
    state.events.unshift(event);
    state.events = state.events.slice(0, MAX_EVENTS);
    persistSession();
    render();
    if (event.kind === "refused") showToast("Compra não realizada. O saldo não foi alterado.");
  }

  function openSettings() {
    $("#broker-url").value = prefs.broker || "";
    $("#mqtt-topic").value = prefs.topic || TOPIC_DEFAULT;
    $("#backend-url").value = prefs.backendUrl || "ws://localhost:3000/ws/telemetria";
    $("#connection-mode").value = prefs.transport || "backend";
    updateConnectionFields();
    $("#player-name-input").value = state.playerName || "";
    $("#mqtt-username").value = "";
    $("#mqtt-password").value = "";
    setFeedback(state.backendSocket
      ? "Conexão ativa com o backend."
      : state.mqttClient
        ? "Conexão ativa. Usuário e senha não ficam armazenados."
        : "Suas credenciais são usadas apenas para esta conexão.");
    ui.connectButton.textContent = state.mqttClient || state.backendSocket ? "Reconectar" : "Conectar";
    ui.disconnectButton.hidden = !state.mqttClient && !state.backendSocket;
    ui.settingsDialog.showModal();
  }

  function updateConnectionFields() {
    const backendMode = $("#connection-mode").value === "backend";
    $("#backend-fields").hidden = !backendMode;
    $("#mqtt-fields").hidden = backendMode;
    $("#settings-title").textContent = backendMode ? "Conexão com o backend" : "Conexão MQTT";
  }

  function handleConnectionError(error) {
    console.error("Erro na conexão de telemetria:", error);
    setConnection("error", `Falha ao conectar: ${error.message || "verifique o endereço e tente novamente."}`);
    ui.connectButton.disabled = false;
  }

  function resetLiveSession() {
    state.events = state.events.filter((event) => event.source !== "demo");
    state.history = [];
    state.inventory = [];
    state.round = 1;
    state.move = 1;
    state.balance = demoInitial.balance;
    state.salary = demoInitial.salary;
    state.investments = 0;
    state.yield = 0;
    state.fixedExpenses = demoInitial.fixedExpenses;
    state.uniqueExpenses = 0;
    for (const key of Object.keys(state.metricAvailable)) state.metricAvailable[key] = false;
    state.hasLiveConnection = true;
    persistSession();
    render();
  }

  function connectBackend(endpoint) {
    if (typeof window.WebSocket !== "function") {
      handleConnectionError(new Error("WebSocket não está disponível neste navegador."));
      return;
    }
    if (state.mqttClient) {
      state.mqttClient.removeAllListeners();
      state.mqttClient.end(true);
      state.mqttClient = null;
    }
    if (state.backendSocket) {
      state.backendSocket.close();
      state.backendSocket = null;
    }
    clearTimeout(state.reconnectTimer);
    state.transport = "backend";
    let socket;
    try {
      socket = new WebSocket(endpoint);
    } catch (error) {
      handleConnectionError(error);
      return;
    }
    state.backendSocket = socket;
    ui.connectButton.disabled = true;
    setFeedback("Conectando ao backend…");
    setConnection("demo");
    socket.addEventListener("open", () => {
      if (state.backendSocket !== socket) return;
      ui.connectButton.disabled = false;
      resetLiveSession();
      setConnection("connected", "Conexão ativa com o backend.");
      showToast("Conexão ativa. Aguardando dados do jogo.");
    });
    socket.addEventListener("message", (message) => {
      if (typeof message.data !== "string") {
        setFeedback("Mensagem ignorada: o backend deve enviar JSON em texto.", "error");
        return;
      }
      let payload;
      try {
        payload = JSON.parse(message.data);
      } catch (error) {
        console.error("Mensagem do backend não contém JSON válido:", error);
        setFeedback("Mensagem ignorada: JSON inválido recebido do backend.", "error");
        return;
      }
      if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
        setFeedback("Mensagem ignorada: esperado um objeto JSON do backend.", "error");
        return;
      }
      recordPayload(payload, "backend");
    });
    socket.addEventListener("error", () => {
      handleConnectionError(new Error("Não foi possível conectar ao WebSocket do backend."));
    });
    socket.addEventListener("close", () => {
      if (state.backendSocket !== socket) return;
      state.backendSocket = null;
      ui.connectButton.disabled = false;
      setConnection("demo", "Conexão com o backend encerrada.");
    });
  }

  function connectMqtt({ broker, topic, username, password }) {
    if (!window.mqtt || typeof window.mqtt.connect !== "function") {
      setConnection("error", "A biblioteca MQTT não carregou. Verifique sua conexão e atualize a página.");
      return;
    }
    try {
      if (state.mqttClient) {
        state.mqttClient.removeAllListeners();
        state.mqttClient.end(true);
      }
      clearTimeout(state.reconnectTimer);
      const options = {
        clean: true,
        connectTimeout: 8000,
        reconnectPeriod: 3000,
        clientId: `aef_${Math.random().toString(16).slice(2, 10)}`,
      };
      if (username) options.username = username;
      if (password) options.password = password;

      if (state.backendSocket) {
        state.backendSocket.close();
        state.backendSocket = null;
      }
      state.transport = "mqtt";
      const client = window.mqtt.connect(broker, options);
      state.mqttClient = client;
      ui.connectButton.disabled = true;
      setFeedback("Conectando ao broker…");
      setConnection("demo");
      client.on("connect", () => {
        client.subscribe(topic, { qos: 0 }, (error) => {
          if (error) {
            handleConnectionError(error);
            return;
          }
          ui.connectButton.disabled = false;
          if (!state.hasLiveConnection) resetLiveSession();
          setConnection("connected", `Conectado e ouvindo ${topic}.`);
          showToast("Conexão ativa. Aguardando dados do jogo.");
        });
      });
      client.on("message", (receivedTopic, message) => {
        let payload;
        try {
          payload = JSON.parse(message.toString());
        } catch (error) {
          console.error("Mensagem MQTT recebida não contém JSON válido:", error);
          setFeedback(`Mensagem ignorada: JSON inválido em ${receivedTopic}.`, "error");
          return;
        }
        if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
          setFeedback(`Mensagem ignorada: esperado um objeto JSON em ${receivedTopic}.`, "error");
          return;
        }
        recordPayload(payload, receivedTopic);
      });
      client.on("error", handleConnectionError);
      client.on("close", () => {
        if (state.mqttClient === client) setConnection("demo", "Conexão encerrada. Confira o broker e tente novamente.");
      });
      client.on("reconnect", () => setFeedback("Conexão interrompida. Tentando novamente…"));
    } catch (error) {
      handleConnectionError(error);
    }
  }

  function disconnectTelemetry() {
    clearTimeout(state.reconnectTimer);
    if (state.mqttClient) {
      state.mqttClient.removeAllListeners();
      state.mqttClient.end(true);
      state.mqttClient = null;
    }
    if (state.backendSocket) {
      state.backendSocket.close();
      state.backendSocket = null;
    }
    ui.connectButton.disabled = false;
    setConnection("demo", "Desconectado. O painel está em modo demonstração.");
  }

  function exportSession() {
    const rows = [
      ["jogador", state.playerName || ""],
      [],
      ["horario", "evento", "item", "rodada", "valor_transacao_BRL", "saldo_apos_BRL", "topico"],
      ...state.events.map((event) => [
        event.time || "",
        event.label || event.event || "",
        event.itemName || "",
        event.round ?? "",
        event.amount ?? "",
        event.balance ?? "",
        event.topic || "",
      ]),
    ];
    const csv = rows.map((row) => row.map((field) => `"${String(field).replaceAll('"', '""')}"`).join(";")).join("\r\n");
    const file = new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(file);
    const link = document.createElement("a");
    link.href = url;
    link.download = `aventura-financeira-${new Date().toISOString().slice(0, 10)}.csv`;
    link.click();
    URL.revokeObjectURL(url);
    showToast("Arquivo da sessão exportado.");
  }

  function initialize() {
    $("#today-label").textContent = new Intl.DateTimeFormat("pt-BR", { dateStyle: "long" }).format(new Date());
    $("#broker-url").value = prefs.broker || "";
    $("#mqtt-topic").value = prefs.topic || TOPIC_DEFAULT;
    $("#backend-url").value = prefs.backendUrl || "ws://localhost:3000/ws/telemetria";
    $("#connection-mode").value = prefs.transport || "backend";
    updateConnectionFields();
    $("#player-name-input").value = state.playerName || "";
    fillCalculatorItemOptions();
    render();

    const savedTab = [...document.querySelectorAll("[data-app-tab]")].find((link) => link.getAttribute("href") === window.location.hash);
    if (savedTab) activateTab(savedTab.dataset.appTab, savedTab.dataset.appScroll);
    document.querySelectorAll("[data-app-tab]").forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        activateTab(link.dataset.appTab, link.dataset.appScroll);
        history.replaceState(null, "", link.getAttribute("href"));
      });
    });
    $("#calculator-form").addEventListener("submit", calculateEstimate);
    $("#calculator-form").addEventListener("input", () => {
      $("#calculator-form").dataset.edited = "true";
    });
    $("#calc-item").addEventListener("change", (event) => {
      const item = catalog.find((entry) => entry.id === Number(event.target.value));
      if (item) $("#calc-purchase").value = String(item.price);
      $("#calculator-form").dataset.edited = "true";
    });
    $("#calc-use-game-data").addEventListener("click", () => {
      $("#calculator-form").dataset.edited = "";
      syncCalculatorWithGame();
      $("#calc-purchase").value = "0";
      $("#calc-item").value = "";
      $("#calc-result-value").textContent = "Preencha os valores";
      $("#calc-result-exact").textContent = "O resultado aparecerá aqui.";
      $("#calc-result-message").textContent = "A conta considera dinheiro atual + entrada − compra − despesas.";
      $("#calc-result-message").className = "calculator-message";
    });
    $("#open-settings").addEventListener("click", openSettings);
    $("#open-settings-side").addEventListener("click", openSettings);
    $("#connection-mode").addEventListener("change", updateConnectionFields);
    $("#close-settings").addEventListener("click", () => ui.settingsDialog.close());
    $("#cancel-settings").addEventListener("click", () => ui.settingsDialog.close());
    ui.settingsDialog.addEventListener("close", () => {
      $("#mqtt-username").value = "";
      $("#mqtt-password").value = "";
    });
    $("#player-avatar").addEventListener("click", openSettings);
    $("#player-name-input").addEventListener("input", (event) => {
      state.playerName = event.target.value.trim();
      prefs.playerName = state.playerName;
      persistPreferences();
      render();
    });
    ui.settingsDialog.addEventListener("click", (event) => {
      if (event.target === ui.settingsDialog) ui.settingsDialog.close();
    });
    $("#disconnect-button").addEventListener("click", () => {
      disconnectTelemetry();
      setFeedback("Desconectado. Credenciais removidas da memória.", "");
    });
    ui.form.addEventListener("submit", (event) => {
      event.preventDefault();
      const transport = $("#connection-mode").value;
      const backendUrl = $("#backend-url").value.trim();
      const broker = $("#broker-url").value.trim();
      const topic = $("#mqtt-topic").value.trim() || TOPIC_DEFAULT;
      const username = $("#mqtt-username").value.trim();
      const password = $("#mqtt-password").value;
      state.playerName = $("#player-name-input").value.trim();
      if (transport === "backend") {
        if (!backendUrl) {
          setFeedback("Informe o endereço WebSocket do backend.", "error");
          $("#backend-url").focus();
          return;
        }
        if (!/^wss?:\/\//i.test(backendUrl)) {
          setFeedback("O endereço precisa começar com ws:// ou wss://.", "error");
          $("#backend-url").focus();
          return;
        }
        prefs.transport = transport;
        prefs.backendUrl = backendUrl;
        prefs.playerName = state.playerName;
        persistPreferences();
        ui.settingsDialog.close();
        connectBackend(backendUrl);
        render();
        return;
      }
      if (!broker) {
        setFeedback("Informe o endereço WebSocket do broker MQTT.", "error");
        $("#broker-url").focus();
        return;
      }
      if (!/^wss?:\/\//i.test(broker)) {
        setFeedback("O endereço precisa começar com ws:// ou wss://.", "error");
        $("#broker-url").focus();
        return;
      }
      if (!topic) {
        setFeedback("Informe o tópico MQTT para receber a telemetria.", "error");
        $("#mqtt-topic").focus();
        return;
      }
      prefs.broker = broker;
      prefs.topic = topic;
      prefs.transport = transport;
      prefs.backendUrl = backendUrl;
      prefs.playerName = state.playerName;
      persistPreferences();
      ui.settingsDialog.close();
      connectMqtt({ broker, topic, username, password });
      $("#mqtt-password").value = "";
      $("#mqtt-username").value = "";
      render();
    });
    $("#export-button").addEventListener("click", exportSession);
    $("#clear-session-button").addEventListener("click", () => {
      if (!window.confirm("Começar uma nova sessão? O histórico atual será apagado deste dispositivo.")) return;
      state.events = [];
      state.history = [state.balance];
      state.round = 1;
      state.salary = demoInitial.salary;
      state.investments = 0;
      state.yield = 0;
      state.fixedExpenses = demoInitial.fixedExpenses;
      state.uniqueExpenses = 0;
      state.balance = demoInitial.balance;
      state.move = 1;
      state.inventory = [];
      state.hasLiveConnection = false;
      for (const key of Object.keys(state.metricAvailable)) state.metricAvailable[key] = state.mode !== "connected";
      persistSession();
      render();
      showToast("Nova sessão iniciada.");
    });
    $("#view-all-button").addEventListener("click", () => {
      state.visibleLimit = state.visibleLimit >= state.events.length ? 5 : state.events.length;
      render();
    });
    if (prefs.playerName) state.playerName = prefs.playerName;
    if (!savedSession) persistSession();
  }

  initialize();
})();

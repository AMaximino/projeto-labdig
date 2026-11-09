#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct TelemetryFrame {
  uint32_t sequence;
  uint8_t eventCode;
  uint8_t itemId;
  int32_t balanceRaw;
  int32_t salaryRaw;
  int32_t investmentRaw;
  int32_t fixedExpensesRaw;
  int32_t uniqueExpensesRaw;
  uint16_t inventoryMask;
  uint8_t roundIndex;
  uint8_t moveIndex;
  uint8_t status;
};

inline const char *eventName(uint8_t code) {
  switch (code) {
    case 1: return "inicio_sessao";
    case 2: return "trabalhar";
    case 3: return "estudar";
    case 4: return "investir";
    case 5: return "resgatar";
    case 6: return "compra_aprovada";
    case 7: return "compra_recusada";
    case 8: return "venda_aprovada";
    case 9: return "venda_recusada";
    case 11: return "fim_rodada";
    case 12: return "fim_jogo";
    case 13: return "falencia";
    default: return nullptr;
  }
}

inline bool parseUnsigned(const char *text, size_t width, uint32_t maximum, uint32_t &value) {
  if (strlen(text) != width) return false;
  for (size_t i = 0; i < width; ++i) {
    if (text[i] < '0' || text[i] > '9') return false;
  }
  char *end = nullptr;
  unsigned long parsed = strtoul(text, &end, 10);
  if (end == text || *end != '\0' || parsed > maximum) return false;
  value = static_cast<uint32_t>(parsed);
  return true;
}

inline bool parseSignedRaw(const char *text, int32_t &value) {
  if (strlen(text) != 8 || (text[0] != '+' && text[0] != '-')) return false;
  for (size_t i = 1; i < 8; ++i) {
    if (text[i] < '0' || text[i] > '9') return false;
  }
  char *end = nullptr;
  long parsed = strtol(text, &end, 10);
  if (end == text || *end != '\0' || parsed < -1048576L || parsed > 1048575L) return false;
  value = static_cast<int32_t>(parsed);
  return true;
}

inline bool parseHexMask(const char *text, uint16_t &mask) {
  if (strlen(text) != 4) return false;
  for (size_t i = 0; i < 4; ++i) {
    if (!((text[i] >= '0' && text[i] <= '9') ||
          (text[i] >= 'A' && text[i] <= 'F'))) return false;
  }
  char *end = nullptr;
  unsigned long parsed = strtoul(text, &end, 16);
  if (end == text || *end != '\0' || parsed > 1023) return false;
  mask = static_cast<uint16_t>(parsed);
  return true;
}

inline bool parseFrame(char *line, TelemetryFrame &frame) {
  char *fields[13] = {};
  size_t fieldCount = 0;
  for (char *token = strtok(line, ","); token != nullptr; token = strtok(nullptr, ",")) {
    if (fieldCount == 13) return false;
    fields[fieldCount++] = token;
  }
  if (fieldCount != 13 || strcmp(fields[0], "AEF1") != 0) return false;

  uint32_t parsed = 0;
  if (!parseUnsigned(fields[1], 6, 999999, parsed) || parsed == 0) return false;
  frame.sequence = parsed;
  if (!parseUnsigned(fields[2], 2, 13, parsed) || parsed == 0 ||
      eventName(static_cast<uint8_t>(parsed)) == nullptr) return false;
  frame.eventCode = static_cast<uint8_t>(parsed);
  if (!parseUnsigned(fields[3], 2, 10, parsed)) return false;
  frame.itemId = static_cast<uint8_t>(parsed);
  if (!parseSignedRaw(fields[4], frame.balanceRaw) ||
      !parseSignedRaw(fields[5], frame.salaryRaw) ||
      !parseSignedRaw(fields[6], frame.investmentRaw) ||
      !parseSignedRaw(fields[7], frame.fixedExpensesRaw) ||
      !parseSignedRaw(fields[8], frame.uniqueExpensesRaw)) return false;
  if (!parseHexMask(fields[9], frame.inventoryMask)) return false;
  if (!parseUnsigned(fields[10], 2, 15, parsed)) return false;
  frame.roundIndex = static_cast<uint8_t>(parsed);
  if (!parseUnsigned(fields[11], 2, 3, parsed)) return false;
  frame.moveIndex = static_cast<uint8_t>(parsed);
  if (!parseUnsigned(fields[12], 1, 2, parsed)) return false;
  frame.status = static_cast<uint8_t>(parsed);

  if ((frame.eventCode == 7 || frame.eventCode == 9) != (frame.status == 2)) return false;
  if ((frame.eventCode == 6 || frame.eventCode == 8) && frame.status != 1) return false;
  if (frame.eventCode >= 2 && frame.eventCode <= 5 && frame.status != 1) return false;
  if ((frame.eventCode == 1 || frame.eventCode >= 10) && frame.status != 0) return false;
  return true;
}

inline int64_t rtlToCents(int32_t rawValue) {
  return static_cast<int64_t>(rawValue) * 10000LL;
}

inline bool formatTelemetryJson(
    char *output,
    size_t capacity,
    const TelemetryFrame &frame,
    const char *deviceId,
    const char *sessionId,
    const char *timestamp,
    int64_t deltaCents) {
  const char *name = eventName(frame.eventCode);
  if (name == nullptr) return false;
  int written = snprintf(
      output, capacity,
      "{\"schema_version\":1,\"device_id\":\"%s\",\"session_id\":\"%s\","
      "\"seq\":%lu,\"timestamp\":%s,\"event\":\"%s\",\"item_id\":%u,"
      "\"status\":\"%s\",\"rodada\":%u,\"jogada\":%u,"
      "\"saldo_centavos\":%lld,\"salario_centavos\":%lld,"
      "\"valor_investido_centavos\":%lld,\"rendimento_centavos\":%lld,"
      "\"gastos_fixos_centavos\":%lld,\"gastos_unicos_centavos\":%lld,"
      "\"inventario_mask\":%u,\"delta_saldo_centavos\":%lld}",
      deviceId, sessionId, static_cast<unsigned long>(frame.sequence),
      timestamp, name, static_cast<unsigned>(frame.itemId),
      frame.status == 1 ? "ok" : frame.status == 2 ? "recusada" : "info",
      static_cast<unsigned>(frame.roundIndex + 1),
      static_cast<unsigned>(frame.moveIndex + 1),
      static_cast<long long>(rtlToCents(frame.balanceRaw)),
      static_cast<long long>(rtlToCents(frame.salaryRaw)),
      static_cast<long long>(rtlToCents(frame.investmentRaw)),
      static_cast<long long>(rtlToCents(frame.investmentRaw / 4)),
      static_cast<long long>(rtlToCents(frame.fixedExpensesRaw)),
      static_cast<long long>(rtlToCents(frame.uniqueExpensesRaw)),
      static_cast<unsigned>(frame.inventoryMask),
      static_cast<long long>(deltaCents));
  return written >= 0 && static_cast<size_t>(written) < capacity;
}

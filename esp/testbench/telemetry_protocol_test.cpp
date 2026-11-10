#include "../aef_bridge/telemetry_protocol.h"

#include <stdio.h>
#include <string.h>

namespace {

int failures = 0;

bool parseTestLine(const char *source, TelemetryFrame &frame) {
  char line[160];
  size_t length = strlen(source);
  if (length >= sizeof(line)) return false;
  memcpy(line, source, length + 1);
  return parseFrame(line, frame);
}

void check(bool condition, const char *description) {
  if (condition) {
    printf("PASS %s\n", description);
  } else {
    fprintf(stderr, "FAIL %s\n", description);
    ++failures;
  }
}

}  // namespace

int main() {
  const char *approvedPurchase =
      "AEF1,000018,06,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,01,00,1";
  TelemetryFrame frame = {};

  check(parseTestLine(approvedPurchase, frame), "valid purchase frame parses");
  check(frame.sequence == 18 && frame.eventCode == 6 && frame.itemId == 7,
        "sequence, event code and item are decoded");
  check(frame.balanceRaw == 150 && frame.salaryRaw == 64 &&
        frame.fixedExpensesRaw == 40 && frame.inventoryMask == 64,
        "signed money and inventory mask are decoded");
  check(frame.roundIndex == 1 && frame.moveIndex == 0 && frame.status == 1,
        "zero-based counters and approved status are decoded");
  check(rtlToCents(frame.balanceRaw) == 1500000,
        "150 RTL units convert to 1,500,000 BRL cents");
  char json[512];
  check(formatTelemetryJson(
            json, sizeof(json), frame, "aef-fpga-01", "session-01",
            "\"2026-11-02T23:46:00.000Z\"", -250000),
        "valid frame formats into JSON");
  check(strstr(json, "\"event\":\"compra_aprovada\"") != nullptr &&
        strstr(json, "\"saldo_centavos\":1500000") != nullptr,
        "JSON has event name and cent-value snapshot");
  check(strstr(json, "\"rodada\":2,\"jogada\":1") != nullptr &&
        strstr(json, "\"delta_saldo_centavos\":-250000") != nullptr,
        "JSON converts counters and preserves signed delta");
  check(!formatTelemetryJson(
            json, 8, frame, "aef-fpga-01", "session-01", "null", 0),
        "undersized JSON buffer is rejected");

  const char *refusedPurchase =
      "AEF1,000019,07,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,01,01,2";
  check(parseTestLine(refusedPurchase, frame) && frame.status == 2,
        "refused purchase frame parses with refused status");

  const char *negativeBalance =
      "AEF1,000020,13,00,-0000010,+0000064,+0000000,+0000040,+0000000,0000,02,02,0";
  check(parseTestLine(negativeBalance, frame) && frame.balanceRaw == -10,
        "negative signed balance is preserved");
  check(rtlToCents(frame.balanceRaw) == -100000,
        "negative RTL balance converts to negative cents");
  check(strcmp(eventName(frame.eventCode), "falencia") == 0,
        "terminal event maps to the JSON event name");

  check(!parseTestLine("AEF1,000021,06,07,+0000150", frame),
        "incomplete UART frame is rejected");
  check(!parseTestLine(
      "AEF1,000021,06,07,+0000150,+0000064,+0000000,+0000040,+0000000,0G40,01,01,1",
      frame), "malformed inventory mask is rejected");
  check(!parseTestLine(
      "AEF1,000021,14,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,01,01,1",
      frame), "unknown event code is rejected");
  check(!parseTestLine(
      "AEF1,000021,07,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,01,01,1",
      frame), "refused event with success status is rejected");
  check(!parseTestLine(
      "AEF1,000000,06,07,+0000150,+0000064,+0000000,+0000040,+0000000,0040,01,01,1",
      frame), "zero sequence is rejected");

  if (failures != 0) {
    fprintf(stderr, "%d ESP32 protocol test(s) failed\n", failures);
    return 1;
  }
  puts("All ESP32 protocol tests passed.");
  return 0;
}

#include <Arduino.h>

static constexpr uint32_t UART_BAUD_RATE = 115200;
static constexpr int FPGA_RX_PIN = 16;

HardwareSerial fpgaSerial(2);

void setup() {
  Serial.begin(UART_BAUD_RATE);
  fpgaSerial.begin(UART_BAUD_RATE, SERIAL_8N1, FPGA_RX_PIN, -1);

  Serial.println();
  Serial.println("Teste da telemetria UART FPGA -> ESP32");
  Serial.println("Aguardando quadros; UART 115200, 8-N-1.");
}

void loop() {
  while (fpgaSerial.available() > 0) {
    Serial.write(static_cast<uint8_t>(fpgaSerial.read()));
  }
}

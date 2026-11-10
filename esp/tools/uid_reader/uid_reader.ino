// Ferramenta de bancada: le o UID dos cartoes no RC522 e imprime no Monitor
// Serial (USB, 115200 baud). Mesma pinagem do firmware aef_bridge (ESP32).
#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>

static constexpr uint8_t RFID_SCK_PIN = 18;
static constexpr uint8_t RFID_MISO_PIN = 19;
static constexpr uint8_t RFID_MOSI_PIN = 23;
static constexpr uint8_t RFID_SS_PIN = 5;
static constexpr uint8_t RFID_RST_PIN = 22;
MFRC522 reader(RFID_SS_PIN, RFID_RST_PIN);

void setup() {
  Serial.begin(115200);
  delay(200);
  SPI.begin(RFID_SCK_PIN, RFID_MISO_PIN, RFID_MOSI_PIN, RFID_SS_PIN);
  reader.PCD_Init();
  const byte version = reader.PCD_ReadRegister(MFRC522::VersionReg);
  if (version == 0x00 || version == 0xFF) {
    Serial.printf("RC522 nao respondeu (VersionReg=0x%02X). Confira SPI e 3V3.\n", version);
  } else {
    Serial.printf("RC522 pronto (VersionReg=0x%02X).\n", version);
  }
  Serial.println("Aproxime um cartão para ler o UID hexadecimal.");
}

void loop() {
  if (!reader.PICC_IsNewCardPresent() || !reader.PICC_ReadCardSerial()) return;
  for (byte index = 0; index < reader.uid.size; ++index) {
    if (reader.uid.uidByte[index] < 0x10) Serial.print('0');
    Serial.print(reader.uid.uidByte[index], HEX);
  }
  Serial.println();
  reader.PICC_HaltA();
  reader.PCD_StopCrypto1();
  delay(500);
}

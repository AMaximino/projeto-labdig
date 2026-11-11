// Teste rapido do RC522 na ESP32, usado pela janela rfid_test_gui.ps1.
// Protocolo (Serial USB, 115200), uma mensagem por linha:
//   READY <versao>   RC522 respondeu (ex.: READY 0x92)
//   ERROR <versao>   RC522 nao respondeu (0x00 ou 0xFF): fios/alimentacao
//   CARD <UID>       cartao detectado (UID hexadecimal)
//   REMOVED          cartao saiu do campo por 300 ms
// Comando aceito: 'V' -> reenvia READY/ERROR.
// Mesma pinagem do aef_bridge: SCK 18, MISO 19, MOSI 23, SS 5, RST 22.
#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>

static constexpr uint8_t PIN_SCK = 18, PIN_MISO = 19, PIN_MOSI = 23, PIN_SS = 5, PIN_RST = 22;
static constexpr uint32_t POLL_MS = 100, REMOVE_MS = 300;

MFRC522 reader(PIN_SS, PIN_RST);
bool latched = false;
uint32_t lastPoll = 0, absentSince = 0;

void reportVersion() {
  const byte v = reader.PCD_ReadRegister(MFRC522::VersionReg);
  Serial.printf("%s 0x%02X\n", (v == 0x00 || v == 0xFF) ? "ERROR" : "READY", v);
}

void setup() {
  Serial.begin(115200);
  delay(300);
  SPI.begin(PIN_SCK, PIN_MISO, PIN_MOSI, PIN_SS);
  reader.PCD_Init();
  reader.PCD_SetAntennaGain(MFRC522::RxGain_max);
  reportVersion();
}

void loop() {
  while (Serial.available()) {
    if (toupper(Serial.read()) == 'V') reportVersion();
  }
  const uint32_t now = millis();
  if (now - lastPoll < POLL_MS) return;
  lastPoll = now;

  if (!latched) {
    if (!reader.PICC_IsNewCardPresent() || !reader.PICC_ReadCardSerial()) return;
    Serial.print("CARD ");
    for (byte i = 0; i < reader.uid.size; ++i) Serial.printf("%02X", reader.uid.uidByte[i]);
    Serial.println();
    reader.PICC_HaltA();
    reader.PCD_StopCrypto1();
    latched = true;
    absentSince = 0;
    return;
  }

  byte atqa[2];
  byte size = sizeof(atqa);
  const MFRC522::StatusCode st = reader.PICC_WakeupA(atqa, &size);
  if (st == MFRC522::STATUS_OK || st == MFRC522::STATUS_COLLISION) {
    absentSince = 0;
    reader.PICC_HaltA();
  } else if (st == MFRC522::STATUS_TIMEOUT) {
    if (absentSince == 0) absentSince = now;
    if (now - absentSince >= REMOVE_MS) {
      latched = false;
      Serial.println("REMOVED");
    }
  }
}

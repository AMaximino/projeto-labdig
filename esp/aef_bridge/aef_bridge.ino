#include <Arduino.h>
#include <PubSubClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <strings.h>
#include <WiFi.h>
#include <esp_random.h>
#include <time.h>

#include "config.h"
#include "telemetry_protocol.h"

// ---------------------------------------------------------------------------
// Pinagem ESP32 (ESP32-WROOM-32U). Pode ser sobrescrita em config.h.
// ---------------------------------------------------------------------------
// RC522 no barramento VSPI (SPI padrao do Arduino-ESP32).
#ifndef AEF_PIN_RFID_SCK
#define AEF_PIN_RFID_SCK 18
#endif
#ifndef AEF_PIN_RFID_MISO
#define AEF_PIN_RFID_MISO 19
#endif
#ifndef AEF_PIN_RFID_MOSI
#define AEF_PIN_RFID_MOSI 23
#endif
#ifndef AEF_PIN_RFID_SS
#define AEF_PIN_RFID_SS 5
#endif
#ifndef AEF_PIN_RFID_RST
#define AEF_PIN_RFID_RST 22
#endif
// UART2 dedicada a FPGA. A UART0 (USB) fica livre para gravacao e logs.
#ifndef AEF_PIN_FPGA_RX
#define AEF_PIN_FPGA_RX 16
#endif
#ifndef AEF_PIN_FPGA_TX
#define AEF_PIN_FPGA_TX 17
#endif
#ifndef AEF_FPGA_BAUD
#define AEF_FPGA_BAUD 115200
#endif
// 1 = imprime eventos no Monitor Serial (USB). 0 = silencioso.
#ifndef AEF_DEBUG
#define AEF_DEBUG 1
#endif

#if AEF_DEBUG
#define LOG(...) Serial.printf(__VA_ARGS__)
#else
#define LOG(...) do {} while (0)
#endif

#ifndef AEF_RFID_TAG_1_UID
#define AEF_RFID_TAG_1_ITEM 1
#define AEF_RFID_TAG_1_UID ""
#define AEF_RFID_TAG_2_ITEM 2
#define AEF_RFID_TAG_2_UID ""
#define AEF_RFID_TAG_3_ITEM 3
#define AEF_RFID_TAG_3_UID ""
#define AEF_RFID_TAG_4_ITEM 4
#define AEF_RFID_TAG_4_UID ""
#define AEF_RFID_TAG_5_ITEM 5
#define AEF_RFID_TAG_5_UID ""
#define AEF_RFID_TAG_6_ITEM 6
#define AEF_RFID_TAG_6_UID ""
#define AEF_RFID_TAG_7_ITEM 7
#define AEF_RFID_TAG_7_UID ""
#define AEF_RFID_TAG_8_ITEM 8
#define AEF_RFID_TAG_8_UID ""
#define AEF_RFID_TAG_9_ITEM 9
#define AEF_RFID_TAG_9_UID ""
#define AEF_RFID_TAG_10_ITEM 10
#define AEF_RFID_TAG_10_UID ""
#endif

static constexpr size_t LINE_CAPACITY = 160;
static constexpr size_t MQTT_QUEUE_CAPACITY = 4;
static constexpr size_t JSON_CAPACITY = 512;
#ifndef AEF_MQTT_TOPIC
#define AEF_MQTT_TOPIC "aventura_financeira/telemetria"
#endif
// 1 = modo de teste: cartao sem cadastro recebe automaticamente o proximo item
// livre (do mais barato ao mais caro), valido ate a ESP32 reiniciar.
#ifndef AEF_RFID_AUTO_ASSIGN
#define AEF_RFID_AUTO_ASSIGN 0
#endif
static constexpr char MQTT_TOPIC[] = AEF_MQTT_TOPIC;
// Leituras de cartao (UID) para o backend identificar o jogador da sessao.
#ifndef AEF_MQTT_CARD_TOPIC
#define AEF_MQTT_CARD_TOPIC "aventura_financeira/cartao"
#endif
static constexpr char MQTT_CARD_TOPIC[] = AEF_MQTT_CARD_TOPIC;
static constexpr uint32_t RFID_POLL_MS = 120;
static constexpr uint32_t RFID_REMOVE_MS = 300;

struct QueuedMessage {
  char payload[JSON_CAPACITY];
};

HardwareSerial &fpgaSerial = Serial2;
MFRC522 rfid(AEF_PIN_RFID_SS, AEF_PIN_RFID_RST);
WiFiClient networkClient;
PubSubClient mqttClient(networkClient);
char inputLine[LINE_CAPACITY];
size_t inputLength = 0;
bool droppingLongLine = false;
QueuedMessage messageQueue[MQTT_QUEUE_CAPACITY];
size_t queueHead = 0;
size_t queueTail = 0;
size_t queueCount = 0;
char sessionId[48] = {};
bool hasPreviousBalance = false;
int32_t previousBalanceRaw = 0;
uint32_t lastWiFiAttempt = 0;
uint32_t lastMqttAttempt = 0;
uint32_t clientNumber = 0;
uint32_t lastRfidPoll = 0;
uint32_t noCardSince = 0;
bool cardLatched = false;
char latchedUid[21] = {};

// 1 = o cartao funciona como "pagar": compra o item que esta no seletor da placa
// (a FPGA informa a posicao pelo evento 14, seletor_item). Qualquer cartao serve.
// 0 = cada cartao compra o item fixo cadastrado em config.h (modo antigo).
#ifndef AEF_RFID_USE_SELECTOR
#define AEF_RFID_USE_SELECTOR 1
#endif
uint8_t selectorItem = 0;  // ultima posicao do seletor recebida da FPGA (0 = desconhecida)

struct RfidTag { const char *uid; uint8_t item; };
const RfidTag rfidTags[] = {
  {AEF_RFID_TAG_1_UID, AEF_RFID_TAG_1_ITEM}, {AEF_RFID_TAG_2_UID, AEF_RFID_TAG_2_ITEM},
  {AEF_RFID_TAG_3_UID, AEF_RFID_TAG_3_ITEM}, {AEF_RFID_TAG_4_UID, AEF_RFID_TAG_4_ITEM},
  {AEF_RFID_TAG_5_UID, AEF_RFID_TAG_5_ITEM}, {AEF_RFID_TAG_6_UID, AEF_RFID_TAG_6_ITEM},
  {AEF_RFID_TAG_7_UID, AEF_RFID_TAG_7_ITEM}, {AEF_RFID_TAG_8_UID, AEF_RFID_TAG_8_ITEM},
  {AEF_RFID_TAG_9_UID, AEF_RFID_TAG_9_ITEM}, {AEF_RFID_TAG_10_UID, AEF_RFID_TAG_10_ITEM}
};

void uidToHex(const MFRC522::Uid &uid, char *output, size_t capacity) {
  size_t offset = 0;
  for (byte index = 0; index < uid.size && offset + 2 < capacity; ++index) {
    offset += snprintf(output + offset, capacity - offset, "%02X", uid.uidByte[index]);
  }
  output[offset] = '\0';
}

// Itens em ordem crescente de preco: 8 (8k), 7 (12k), 9 (20k), 10 (42k), 1..6.
static const uint8_t AUTO_ITEM_ORDER[10] = {8, 7, 9, 10, 1, 2, 3, 4, 5, 6};
char autoUids[10][21] = {};
size_t autoCount = 0;

bool itemConfigured(uint8_t item) {
  for (const auto &tag : rfidTags) {
    if (tag.uid[0] != '\0' && tag.item == item) return true;
  }
  return false;
}

uint8_t itemForUid(const char *uid) {
  for (const auto &tag : rfidTags) {
    if (tag.uid[0] != '\0' && strcasecmp(uid, tag.uid) == 0) return tag.item;
  }
#if AEF_RFID_AUTO_ASSIGN
  size_t slot = 0;
  for (size_t i = 0; i < 10; ++i) {
    const uint8_t item = AUTO_ITEM_ORDER[i];
    if (itemConfigured(item)) continue;
    if (slot < autoCount && strcasecmp(uid, autoUids[slot]) == 0) return item;
    if (slot == autoCount) {
      strlcpy(autoUids[slot], uid, sizeof(autoUids[slot]));
      ++autoCount;
      LOG("[RFID] modo teste: UID %s associado ao item %u\n", uid, item);
      return item;
    }
    ++slot;
  }
#endif
  return 0;
}

void sendRfidPurchase(uint8_t item) {
  if (item < 1 || item > 10) return;
  char command[5];
  snprintf(command, sizeof(command), "R%02u\n", item);
  fpgaSerial.write(reinterpret_cast<const uint8_t *>(command), 4);
  fpgaSerial.flush();
  LOG("[RFID] comando enviado a FPGA: R%02u\n", item);
}

void publishCardRead(const char *uid, uint8_t item);  // definida mais abaixo

void serviceRfid() {
  const uint32_t now = millis();
  if (now - lastRfidPoll < RFID_POLL_MS) return;
  lastRfidPoll = now;

  if (!cardLatched) {
    if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) return;
    uidToHex(rfid.uid, latchedUid, sizeof(latchedUid));
    cardLatched = true;
    noCardSince = 0;
#if AEF_RFID_USE_SELECTOR
    if (selectorItem != 0) {
      LOG("[RFID] UID %s -> item %u do seletor\n", latchedUid, selectorItem);
      sendRfidPurchase(selectorItem);
      publishCardRead(latchedUid, selectorItem);
    } else {
      LOG("[RFID] UID %s lido, mas a posicao do seletor ainda nao chegou da FPGA "
          "(aperte iniciar e gire o seletor)\n", latchedUid);
      publishCardRead(latchedUid, 0);
    }
#else
    const uint8_t item = itemForUid(latchedUid);
    if (item != 0) {
      LOG("[RFID] UID %s -> item %u\n", latchedUid, item);
      sendRfidPurchase(item);
    } else {
      LOG("[RFID] UID %s nao cadastrado (nenhum comando enviado)\n", latchedUid);
    }
#endif
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();
    return;
  }

  byte atqa[2];
  byte atqaSize = sizeof(atqa);
  const MFRC522::StatusCode status = rfid.PICC_WakeupA(atqa, &atqaSize);
  if (status == MFRC522::STATUS_OK || status == MFRC522::STATUS_COLLISION) {
    noCardSince = 0;
    rfid.PICC_HaltA();
    return;
  }
  if (status == MFRC522::STATUS_TIMEOUT) {
    if (noCardSince == 0) noCardSince = now;
    if (now - noCardSince >= RFID_REMOVE_MS) {
      LOG("[RFID] cartao removido, leitor liberado\n");
      cardLatched = false;
      latchedUid[0] = '\0';
      noCardSince = 0;
    }
  }
}

// Equivalente ao ESP.getChipId() do ESP8266: ultimos 3 bytes do MAC de fabrica.
uint32_t chipId() {
  const uint64_t mac = ESP.getEfuseMac();
  return static_cast<uint32_t>((mac >> 24) & 0xFFFFFFULL);
}

void makeSessionId() {
  uint32_t randomPart = esp_random();
  snprintf(sessionId, sizeof(sessionId), "%06lx-%08lx",
           static_cast<unsigned long>(chipId()),
           static_cast<unsigned long>(randomPart));
}

void formatTimestamp(char *output, size_t capacity) {
  time_t now = time(nullptr);
  if (now < 1577836800) {
    snprintf(output, capacity, "null");
    return;
  }
  struct tm utc;
  gmtime_r(&now, &utc);
  snprintf(output, capacity, "\"%04d-%02d-%02dT%02d:%02d:%02d.000Z\"",
           utc.tm_year + 1900, utc.tm_mon + 1, utc.tm_mday,
           utc.tm_hour, utc.tm_min, utc.tm_sec);
}

bool enqueueMessage(const TelemetryFrame &frame) {
  if (frame.eventCode == 1 || sessionId[0] == '\0') {
    makeSessionId();
    hasPreviousBalance = false;
  }
  if (queueCount == MQTT_QUEUE_CAPACITY) {
    LOG("[MQTT] fila cheia, evento seq=%lu descartado\n", static_cast<unsigned long>(frame.sequence));
    return false;
  }

  const int64_t balanceCents = rtlToCents(frame.balanceRaw);
  const int64_t deltaCents = hasPreviousBalance
      ? balanceCents - rtlToCents(previousBalanceRaw)
      : 0;
  previousBalanceRaw = frame.balanceRaw;
  hasPreviousBalance = true;

  QueuedMessage &message = messageQueue[queueTail];
  char timestamp[32];
  formatTimestamp(timestamp, sizeof(timestamp));
  if (!formatTelemetryJson(
          message.payload, sizeof(message.payload), frame, AEF_DEVICE_ID,
          sessionId, timestamp, deltaCents)) {
    return false;
  }
  queueTail = (queueTail + 1) % MQTT_QUEUE_CAPACITY;
  ++queueCount;
  return true;
}

void processLine(char *line) {
  if (line[0] == '\0') return;
  char parseBuffer[LINE_CAPACITY];
  strlcpy(parseBuffer, line, sizeof(parseBuffer));
  TelemetryFrame frame = {};
  if (!parseFrame(parseBuffer, frame)) {
    LOG("[FPGA] quadro invalido ignorado: %s\n", line);
    return;
  }
  LOG("[FPGA] seq=%lu evento=%s item=%u\n", static_cast<unsigned long>(frame.sequence),
      eventName(frame.eventCode), static_cast<unsigned>(frame.itemId));
  if (frame.eventCode == 14 && frame.itemId >= 1 && frame.itemId <= 10) {
    selectorItem = frame.itemId;  // o proximo cartao compra este item
  }
  if (!enqueueMessage(frame)) return;
}

void readUart() {
  while (fpgaSerial.available() > 0) {
    char character = static_cast<char>(fpgaSerial.read());
    if (character == '\n') {
      if (!droppingLongLine) {
        inputLine[inputLength] = '\0';
        if (inputLength > 0 && inputLine[inputLength - 1] == '\r') {
          inputLine[inputLength - 1] = '\0';
        }
        processLine(inputLine);
      } else {
        LOG("[FPGA] linha longa demais descartada\n");
      }
      inputLength = 0;
      droppingLongLine = false;
    } else if (!droppingLongLine) {
      if (inputLength + 1 < sizeof(inputLine)) {
        inputLine[inputLength++] = character;
      } else {
        droppingLongLine = true;
      }
    }
  }
}

void maintainWiFi() {
  static bool wasConnected = false;
  if (WiFi.status() == WL_CONNECTED) {
    if (!wasConnected) {
      wasConnected = true;
      LOG("[WiFi] conectado, IP %s\n", WiFi.localIP().toString().c_str());
    }
    return;
  }
  if (wasConnected) {
    wasConnected = false;
    LOG("[WiFi] conexao perdida\n");
  }
  uint32_t now = millis();
  if (now - lastWiFiAttempt < 10000) return;
  lastWiFiAttempt = now;
  LOG("[WiFi] tentando conectar em \"%s\"...\n", AEF_WIFI_SSID);
  WiFi.disconnect();
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
}

void maintainMqtt() {
  if (WiFi.status() != WL_CONNECTED || mqttClient.connected()) return;
  uint32_t now = millis();
  if (now - lastMqttAttempt < 5000) return;
  lastMqttAttempt = now;
  char clientId[40];
  snprintf(clientId, sizeof(clientId), "aef-esp32-%06lx-%lu",
           static_cast<unsigned long>(chipId()), static_cast<unsigned long>(clientNumber++));
  bool connected = AEF_MQTT_USERNAME[0] == '\0'
      ? mqttClient.connect(clientId)
      : mqttClient.connect(clientId, AEF_MQTT_USERNAME, AEF_MQTT_PASSWORD);
  if (connected) {
    LOG("[MQTT] conectado a %s:%d como %s\n", AEF_MQTT_HOST, AEF_MQTT_PORT, clientId);
  } else {
    LOG("[MQTT] falha ao conectar em %s:%d (estado %d)\n", AEF_MQTT_HOST, AEF_MQTT_PORT,
        mqttClient.state());
  }
}

// Avisa o backend qual cartao foi usado nesta sessao. Nao entra na fila da
// telemetria: se o MQTT estiver fora do ar, a leitura e so registrada no log.
void publishCardRead(const char *uid, uint8_t item) {
  if (!mqttClient.connected()) {
    LOG("[MQTT] sem conexao, leitura do cartao %s nao publicada\n", uid);
    return;
  }
  char timestamp[32];
  formatTimestamp(timestamp, sizeof(timestamp));
  char payload[256];
  const int written = snprintf(
      payload, sizeof(payload),
      "{\"schema_version\":1,\"device_id\":\"%s\",\"session_id\":\"%s\","
      "\"uid\":\"%s\",\"item_id\":%u,\"timestamp\":%s}",
      AEF_DEVICE_ID, sessionId, uid, static_cast<unsigned>(item), timestamp);
  if (written <= 0 || static_cast<size_t>(written) >= sizeof(payload)) return;
  if (mqttClient.publish(MQTT_CARD_TOPIC, payload, false)) {
    LOG("[MQTT] cartao %s publicado em %s\n", uid, MQTT_CARD_TOPIC);
  }
}

void publishQueuedMessage() {
  if (!mqttClient.connected() || queueCount == 0) return;
  QueuedMessage &message = messageQueue[queueHead];
  if (mqttClient.publish(MQTT_TOPIC, message.payload, false)) {
    queueHead = (queueHead + 1) % MQTT_QUEUE_CAPACITY;
    --queueCount;
    LOG("[MQTT] publicado em %s\n", MQTT_TOPIC);
  } else {
    LOG("[MQTT] falha ao publicar, reconectando\n");
    mqttClient.disconnect();
  }
}

void setup() {
  Serial.begin(115200);  // USB: apenas logs
  fpgaSerial.begin(AEF_FPGA_BAUD, SERIAL_8N1, AEF_PIN_FPGA_RX, AEF_PIN_FPGA_TX);
  delay(200);
  LOG("\n[AEF] ponte ESP32 iniciando\n");
  LOG("[AEF] FPGA UART2: RX=GPIO%d TX=GPIO%d %d baud\n", AEF_PIN_FPGA_RX, AEF_PIN_FPGA_TX,
      AEF_FPGA_BAUD);

  SPI.begin(AEF_PIN_RFID_SCK, AEF_PIN_RFID_MISO, AEF_PIN_RFID_MOSI, AEF_PIN_RFID_SS);
  rfid.PCD_Init();
  const byte rfidVersion = rfid.PCD_ReadRegister(MFRC522::VersionReg);
  if (rfidVersion == 0x00 || rfidVersion == 0xFF) {
    LOG("[RFID] RC522 nao respondeu (VersionReg=0x%02X): confira fios SPI e 3V3\n", rfidVersion);
  } else {
    LOG("[RFID] RC522 pronto (VersionReg=0x%02X)\n", rfidVersion);
  }

  const char *deviceId = AEF_DEVICE_ID;
  bool validDeviceId = strlen(deviceId) > 0 && strlen(deviceId) <= 48;
  for (size_t i = 0; validDeviceId && deviceId[i] != '\0'; ++i) {
    char character = deviceId[i];
    validDeviceId = (character >= 'A' && character <= 'Z') ||
                    (character >= 'a' && character <= 'z') ||
                    (character >= '0' && character <= '9') ||
                    character == '.' || character == '_' || character == '-';
  }
  if (!validDeviceId) {
    LOG("[AEF] AEF_DEVICE_ID invalido em config.h, reiniciando\n");
    delay(2000);
    ESP.restart();
  }

  WiFi.mode(WIFI_STA);
  mqttClient.setServer(AEF_MQTT_HOST, AEF_MQTT_PORT);
  if (!mqttClient.setBufferSize(JSON_CAPACITY)) {
    LOG("[MQTT] sem memoria para o buffer, reiniciando\n");
    delay(2000);
    ESP.restart();
  }
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  LOG("[WiFi] conectando em \"%s\"...\n", AEF_WIFI_SSID);
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
  lastWiFiAttempt = millis();
}

void loop() {
  readUart();
  serviceRfid();
  maintainWiFi();
  maintainMqtt();
  if (mqttClient.connected()) mqttClient.loop();
  publishQueuedMessage();
  delay(1);
}

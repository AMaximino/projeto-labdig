#include <Arduino.h>
#include <PubSubClient.h>
#include <SoftwareSerial.h>
#include <ESP8266WiFi.h>
#include <time.h>

#include "config.h"
#include "telemetry_protocol.h"

static constexpr size_t LINE_CAPACITY = 160;
static constexpr size_t MQTT_QUEUE_CAPACITY = 4;
static constexpr size_t JSON_CAPACITY = 512;
static constexpr char MQTT_TOPIC[] = "aventura_financeira/telemetria";

struct QueuedMessage {
  char payload[JSON_CAPACITY];
};

SoftwareSerial fpgaSerial(AEF_FPGA_RX_PIN, -1, false);
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

void makeSessionId() {
  uint32_t randomPart = ESP.random();
  snprintf(sessionId, sizeof(sessionId), "%06lx-%08lx",
           static_cast<unsigned long>(ESP.getChipId()),
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
    Serial.println("Fila MQTT cheia; evento UART descartado, sem afetar o jogo.");
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
    Serial.println("Payload JSON excedeu o buffer; evento nao publicado.");
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
    Serial.printf("Linha UART rejeitada: %s\n", line);
    return;
  }
  if (!enqueueMessage(frame)) return;
  Serial.printf("Evento %s seq=%lu recebido e enfileirado.\n",
                eventName(frame.eventCode), static_cast<unsigned long>(frame.sequence));
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
        Serial.println("Linha UART longa demais; descartada.");
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
  if (WiFi.status() == WL_CONNECTED) return;
  uint32_t now = millis();
  if (now - lastWiFiAttempt < 10000) return;
  lastWiFiAttempt = now;
  Serial.println("Conectando ao Wi-Fi...");
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
}

void maintainMqtt() {
  if (WiFi.status() != WL_CONNECTED || mqttClient.connected()) return;
  uint32_t now = millis();
  if (now - lastMqttAttempt < 5000) return;
  lastMqttAttempt = now;
  char clientId[40];
  snprintf(clientId, sizeof(clientId), "aef-esp8266-%06lx-%lu",
           static_cast<unsigned long>(ESP.getChipId()), static_cast<unsigned long>(clientNumber++));
  bool connected = AEF_MQTT_USERNAME[0] == '\0'
      ? mqttClient.connect(clientId)
      : mqttClient.connect(clientId, AEF_MQTT_USERNAME, AEF_MQTT_PASSWORD);
  if (connected) {
    Serial.println("Conectado ao broker MQTT.");
  } else {
    Serial.printf("Falha MQTT, estado=%d. Nova tentativa em 5 s.\n", mqttClient.state());
  }
}

void publishQueuedMessage() {
  if (!mqttClient.connected() || queueCount == 0) return;
  QueuedMessage &message = messageQueue[queueHead];
  if (mqttClient.publish(MQTT_TOPIC, message.payload, false)) {
    queueHead = (queueHead + 1) % MQTT_QUEUE_CAPACITY;
    --queueCount;
  } else {
    Serial.println("Publicacao MQTT falhou; payload mantido na fila para nova tentativa.");
    mqttClient.disconnect();
  }
}

void setup() {
  Serial.begin(115200);
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
    Serial.println("AEF_DEVICE_ID invalido; use letras, numeros, ponto, _ ou -.");
    while (true) delay(1000);
  }

  fpgaSerial.begin(115200, SWSERIAL_8N1, AEF_FPGA_RX_PIN, -1, false, 256);

  WiFi.mode(WIFI_STA);
  mqttClient.setServer(AEF_MQTT_HOST, AEF_MQTT_PORT);
  if (!mqttClient.setBufferSize(JSON_CAPACITY)) {
    Serial.println("Falha ao reservar buffer MQTT.");
  }
  configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  WiFi.begin(AEF_WIFI_SSID, AEF_WIFI_PASSWORD);
  Serial.println("Ponte ESP8266 FPGA UART -> MQTT iniciada (somente publicacao).");
}

void loop() {
  readUart();
  maintainWiFi();
  maintainMqtt();
  if (mqttClient.connected()) mqttClient.loop();
  publishQueuedMessage();
  delay(1);
}
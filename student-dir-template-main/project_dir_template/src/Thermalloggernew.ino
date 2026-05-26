#include <Wire.h>
#include <Adafruit_MCP9600.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// --------- MCP9600 ----------
Adafruit_MCP9600 mcp_in;   // ingresso (Tin)
Adafruit_MCP9600 mcp_out;  // uscita (Tout)

// --------- DS18B20 (Ambient) ----------
#define DS18B20_PIN 2
OneWire oneWire(DS18B20_PIN);
DallasTemperature sensors(&oneWire);

// --------- FLOW SENSOR ----------
#define FLOW_PIN 3 
volatile long pulseCount = 0;
unsigned long lastTime;
float flowRate = 0.0;

void pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);
  while (!Serial);

  // Flow sensor
  pinMode(FLOW_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FLOW_PIN), pulseCounter, RISING);
  lastTime = millis();

  // --------- MCP9600 OUT ----------
  Serial.println("Initializing MCP9600 OUT...");
  if (!mcp_out.begin(0x66)) {
    Serial.println("ERROR: MCP9600 OUT not found!");
    while (1);
  }

  // --------- MCP9600 IN ----------
  Serial.println("Initializing MCP9600 IN...");
  if (!mcp_in.begin(0x67)) {
    Serial.println("ERROR: MCP9600 IN not found!");
    while (1);
  }

  // Configurazione identica per entrambi
  mcp_out.setADCresolution(MCP9600_ADCRESOLUTION_18);
  mcp_out.setThermocoupleType(MCP9600_TYPE_K);
  mcp_out.setFilterCoefficient(3);

  mcp_in.setADCresolution(MCP9600_ADCRESOLUTION_18);
  mcp_in.setThermocoupleType(MCP9600_TYPE_K);
  mcp_in.setFilterCoefficient(3);

  // DS18B20
  sensors.begin();

  Serial.println("SYSTEM READY");
}

void loop() {
  // --- Read temperatures ---
  float T_Out = mcp_out.readThermocouple(); // uscita tubo
  float T_In  = mcp_in.readThermocouple();  // ingresso tubo

  sensors.requestTemperatures();
  float T_Amb = sensors.getTempCByIndex(0); // ambiente

  // --- Flow calculation ---
  unsigned long currentTime = millis();

  if((currentTime - lastTime) > 1000) {
    detachInterrupt(digitalPinToInterrupt(FLOW_PIN));

    float flowFreq = pulseCount / ((currentTime - lastTime) / 1000.0);
    flowRate = flowFreq / 2.5;  // L/min

    pulseCount = 0;
    lastTime = millis();

    attachInterrupt(digitalPinToInterrupt(FLOW_PIN), pulseCounter, RISING);

    // --- Pressure ---
    int rawPressure = analogRead(A0);
    float pVoltage = rawPressure * (5.0 / 1023.0);

    float P_min = 0.47;
    float P_max = 4.5;
    float P_range = 12.0;

    float pressure = ((pVoltage - P_min) * P_range / (P_max - P_min));
    if (pressure < 0) pressure = 0;

    // --- Timestamp ---
    unsigned long totalSeconds = millis() / 1000;
    unsigned int minutes = totalSeconds / 60;
    unsigned int seconds = totalSeconds % 60;

    Serial.print("[");
    if (minutes < 10) Serial.print("0");
    Serial.print(minutes);
    Serial.print(":");
    if (seconds < 10) Serial.print("0");
    Serial.print(seconds);
    Serial.print("] ");

    // --- Output ---
    Serial.print("T_Amb: "); Serial.print(T_Amb); Serial.print(" C, ");
    Serial.print("T_In: ");  Serial.print(T_In);  Serial.print(" C, ");
    Serial.print("T_Out: "); Serial.print(T_Out); Serial.print(" C, ");
    Serial.print("Flow: ");  Serial.print(flowRate); Serial.print(" L/min, ");
    Serial.print("Press: "); Serial.print(pressure + 1); Serial.println(" bar");
  }
}
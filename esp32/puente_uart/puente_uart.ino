// Puente transparente USB <-> UART entre MATLAB y la FPGA DE10-Lite.
// Serial      : USB hacia la computadora (9600 8N1)
// FPGA_Serial : UART2 hacia la FPGA (9600 8N1, RX=GPIO16, TX=GPIO17)
#include <HardwareSerial.h>

HardwareSerial FPGA_Serial(2);

void setup() {
  Serial.begin(9600);

  FPGA_Serial.begin(
    9600,
    SERIAL_8N1,
    16,  // RX2: recibe de FPGA
    17   // TX2: envia a FPGA
  );
}

void loop() {
  // MATLAB -> ESP32 -> FPGA
  while (Serial.available() > 0) {
    FPGA_Serial.write(Serial.read());
  }

  // FPGA -> ESP32 -> MATLAB
  while (FPGA_Serial.available() > 0) {
    Serial.write(FPGA_Serial.read());
  }
}

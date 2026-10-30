# 03 · ESP32 y MATLAB

[← Volver al README](../README.md)

## Programa del ESP32

Archivo: [`esp32/puente_uart/puente_uart.ino`](../esp32/puente_uart/puente_uart.ino)

| Puerto | Uso | Configuración |
|---|---|---|
| `Serial` | USB ↔ PC | 9600 8N1 |
| `FPGA_Serial` (UART2) | ESP32 ↔ FPGA | 9600 8N1, RX = GPIO16, TX = GPIO17 |

`loop()` reenvía en ambos sentidos cualquier byte disponible:

```cpp
while (Serial.available() > 0)      FPGA_Serial.write(Serial.read());   // MATLAB -> FPGA
while (FPGA_Serial.available() > 0) Serial.write(FPGA_Serial.read());   // FPGA -> MATLAB
```

> A diferencia del ejemplo de la guía, este programa **no imprime un mensaje de inicio**. MATLAB toma todos los bytes que llegan como parte del resultado, así que un texto extra se mezclaría con la respuesta.

![Carga del programa en Arduino IDE](img/arduino_carga.png)

## Script de MATLAB

Archivo: [`matlab/potencia_fpga.m`](../matlab/potencia_fpga.m)

1. **Abre el puerto** del ESP32 con un `Timeout` de 5 s y espera 2 s, porque el ESP32 puede reiniciarse al abrirlo.
2. **Valida las entradas:** A debe ser un entero de 0 a 255 y n un entero de 0 a 15.
3. **Envía** los 2 bytes `uint8([A, n])` después de limpiar el búfer de entrada.
4. **Recibe** 13 bytes con `read(s, 13, 'uint8')`.
5. **Reconstruye** el entero de 100 bits con aritmética simbólica:

   ```matlab
   raw = sym(0);
   for k = 1:13
       raw = raw + sym(double(bytes(k))) * sym(256)^(k-1);
   end
   y = raw / sym(2)^20;
   ```

   Se usa `sym` porque 100 bits no caben con exactitud en un `double` (53 bits de mantisa) ni en un `uint64`.
6. **Compara** el resultado con `A^(n/2)` calculado en `double`.

> El script requiere el **Symbolic Math Toolbox**. Antes de ejecutarlo, cierra el Monitor Serial de Arduino IDE, porque ocupa el puerto COM.

![Consola de MATLAB](img/matlab_consola1.png)

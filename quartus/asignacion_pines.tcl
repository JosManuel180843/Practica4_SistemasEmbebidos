# Asignacion de pines para top_uart_de10lite (DE10-Lite, MAX 10 10M50DAF484C7G)
# Uso en Quartus: Tools > Tcl Scripts... o  quartus_sh -t asignacion_pines.tcl
# Completar los pines GPIO que se usaron para UART_RX y UART_TX.

set_global_assignment -name FAMILY "MAX 10"
set_global_assignment -name DEVICE 10M50DAF484C7G
set_global_assignment -name TOP_LEVEL_ENTITY top_uart_de10lite

set_location_assignment PIN_P11 -to CLOCK_50
set_location_assignment PIN_B8  -to RESET_N   ;# KEY[0]

# TODO: pines del header GPIO conectados al ESP32
# set_location_assignment PIN_XXX -to UART_RX  ;# <- GPIO17 (TX2) del ESP32
# set_location_assignment PIN_XXX -to UART_TX  ;# -> GPIO16 (RX2) del ESP32

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to RESET_N
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_RX
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX

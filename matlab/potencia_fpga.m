% potencia_fpga.m
% Envia A (0..255) y n (0..15) a la FPGA a traves del ESP32 y recibe
% A^(n/2) en formato Q80.20 (100 bits, 13 bytes, little-endian).

clear;
clc;

% Configuracion serial
PORT = "COM4";   % Cambiar por el puerto del ESP32
BAUD = 9600;

s = serialport(PORT, BAUD);
s.Timeout = 5;
pause(2);        % El ESP32 puede reiniciarse al abrir el puerto
flush(s);

disp("FPGA: potencia A^(n/2) en Q80.20");

while true
    entrada = strtrim(input( ...
        'A (0..255), o q para salir: ', 's'));

    if strcmpi(entrada, 'q')
        break;
    end

    A = str2double(entrada);
    n = str2double(input('n (0..15): ', 's'));

    if ~isfinite(A) || ~isfinite(n) || ...
            A ~= fix(A) || n ~= fix(n) || ...
            A < 0 || A > 255 || n < 0 || n > 15
        disp('A debe ser entero 0..255');
        disp('n debe ser entero 0..15');
        continue;
    end

    % Limpiar datos anteriores
    flush(s, 'input');

    % Enviar A y n a la FPGA
    write(s, uint8([A, n]), 'uint8');
    fprintf('Enviado: A=%d, n=%d\n', A, n);

    try
        % Recibir 13 bytes del resultado
        bytes = read(s, 13, 'uint8');

        % Reconstruir entero de 100 bits
        raw = sym(0);
        for k = 1:13
            raw = raw + ...
                sym(double(bytes(k))) * sym(256)^(k-1);
        end

        % Convertir Q80.20 a decimal
        y = raw / sym(2)^20;

        fprintf('Resultado Q80.20: %s\n', char(raw));
        fprintf('Resultado decimal: %s\n', ...
            char(vpa(y, 16)));

        % Comparacion con MATLAB
        referencia = double(A)^(double(n)/2);
        fprintf('Referencia MATLAB: %.9g\n', ...
            referencia);
    catch ME
        fprintf('Error o timeout: %s\n', ME.message);
    end
end

clear s;
disp('Comunicacion finalizada');

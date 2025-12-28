% crc5_calc.m
function crc5_result = crc5_calc(addr, endpoint)
%USB CRC5 calculation function
% input: 7-bit address, 4-bit endpoint
% output: 5-bit CRC5 result, 11 bit data vector

%Combining addresses and endpoints into an 11 bit data vector in the USB specification,
% the data transmission order is LSB first
% 11 bit data: [addr [6:0], endpoint [3:0]]

% Ensure that the input is a binary representation
addr_bin = de2bi(addr, 7, 'left-msb');  %7-digit address
endpoint_bin = de2bi(endpoint, 4, 'left-msb');  %4-digit endpoint

% Build an 11 bit data vector (according to USB specifications, LSB first transmission)
data_vector = [addr_bin(7:-1:1),endpoint_bin(4:-1:1)];  %Reverse the bit order to match LSB first

fprintf('MATLAB CRC5 calc:\n');
fprintf('  addr: %s (0x%02X)\n', num2str(addr_bin), addr);
fprintf('  endpoint: %s (0x%01X)\n', num2str(endpoint_bin), endpoint);
fprintf('  data_vector(11位, LSB first): %s\n', num2str(data_vector));

% CRC5 polynomial: x^5 + x^2 + 1 (binary: 00101, hexadecimal: 0x05)
% initial value: 0x1F (All 1)
poly = 5;  % 0x05
crc = uint8(31);  % 0x1F (5 digits all 1)

% Calculate CRC5 bit by bit
for i = 1:11
    % Retrieve the current data bit
    data_bit = data_vector(i);
    
    % Obtain the highest bit of CRC
    crc_msb = bitget(crc, 5);
    
    % XOR operation
    if xor(data_bit, crc_msb)
        % Left shift XOR polynomial
        crc = bitxor(bitshift(crc, 1), poly);
    else
        % Only move left
        crc = bitshift(crc, 1);
    end
    
    % Maintain 5 positions
    crc = bitand(crc, 31);  % 0x1F
    
    fprintf('  bit%d: data_bit=%d, before_CRC=%05s, after_CRC=%05s\n', ...
            i, data_bit, ...
            dec2bin(bitxor(bitshift(crc, -1), poly*(crc_msb~=data_bit)), 5), ...
            dec2bin(crc, 5));
end

% USB CRC5 needs to be reversed and reversed
crc_reversed = 0;
for i = 1:5
    if bitget(crc, i)
        crc_reversed = bitset(crc_reversed, 6-i);
    end
end

crc5_result = bitxor(crc_reversed, 31);  % negate

fprintf('  calc_out CRC5: %05s\n', dec2bin(crc, 5));
fprintf('  reversed CRC5: %05s\n', dec2bin(crc_reversed, 5));
fprintf('  result CRC5(reversed+negate): %05s\n', dec2bin(crc5_result, 5));

end

% test_crc5.m
% 测试特定用例：地址=0x04，端点=0x2
clear all;
close all;

addr = 4;      % 0x04 (0000100)
endpoint = 2;  % 0x2  (0010)

crc5_result = crc5_calc(addr, endpoint);

% 显示结果
fprintf('\n=== CRC5验证结果 ===\n');
fprintf('地址: 0x%02X (%s)\n', addr, dec2bin(addr, 7));
fprintf('端点: 0x%01X (%s)\n', endpoint, dec2bin(endpoint, 4));
% fprintf('数据向量(11位): %s\n', num2str(data_vector));
fprintf('计算出的CRC5: %05s (二进制)\n', dec2bin(crc5_result, 5));
fprintf('计算出的CRC5: 0x%02X (十六进制)\n', crc5_result);

% 验证与接收的CRC5是否匹配
received_crc5 = bin2dec('01001');  % 从frame3接收到的CRC5

fprintf('\n接收到的CRC5: %05s (二进制)\n', dec2bin(received_crc5, 5));
fprintf('接收到的CRC5: 0x%02X (十六进制)\n', received_crc5);

if crc5_result == received_crc5
    fprintf('\n✅ PASS: CRC5校验正确！\n');
else
    fprintf('\n❌ FAIL: CRC5校验错误！\n');
    fprintf('  期望: %05s\n', dec2bin(crc5_result, 5));
    fprintf('  实际: %05s\n', dec2bin(received_crc5, 5));
end

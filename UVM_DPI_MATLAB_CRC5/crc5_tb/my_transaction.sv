`ifndef MY_TRANSACTION__SV
`define MY_TRANSACTION__SV

class my_transaction extends uvm_sequence_item;
  
  // Three frames of data in USB package
  logic [7:0] frame1;  // PID frame: 8'b0100_1001
  logic [7:0] frame2;  // Address+endpoint low 1 bit: 8'b0000_1000  
  logic [7:0] frame3;  // CRC5+endpoint height of 3 digits: 8'b01001_001
  
  // Parsed fields
  logic [3:0] pid;          // PID: 1001 (OUT token)
  logic [6:0] addr;         // Address: 000_0100 (0x04)
  logic [3:0] endpoint;     // Endpoint: {frame3[7:5], frame2[7]} = 0010 (0x2)
  logic [4:0] crc5_received; // Received CRC5: frame3[4:0] = 01001
  
  // Expected output (reference model settings)
  logic [3:0] exp_rx_pid;    // Expected PID: 4'b1001
  logic [3:0] exp_rx_endp;   // Expected endpoint: 4'b0010
  logic       exp_crc5_err;  // Expected CRC5 error flag
  
  // Actual output (collected by Monitor)
  logic [3:0] act_rx_pid;    // Actual PID
  logic [3:0] act_rx_endp;   // Actual endpoints
  logic       act_crc5_err;  // Actual CRC5 error flag
  
  // Fields used for scoreboard comparison
  bit compare_success;       // comparison results
  string compare_message;    // Compare news
  
  `uvm_object_utils_begin(my_transaction)
    `uvm_field_int(frame1, UVM_ALL_ON)
    `uvm_field_int(frame2, UVM_ALL_ON)
    `uvm_field_int(frame3, UVM_ALL_ON)
    `uvm_field_int(pid, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(endpoint, UVM_ALL_ON)
    `uvm_field_int(crc5_received, UVM_ALL_ON)
    `uvm_field_int(exp_rx_pid, UVM_ALL_ON)
    `uvm_field_int(exp_rx_endp, UVM_ALL_ON)
    `uvm_field_int(exp_crc5_err, UVM_ALL_ON)
    `uvm_field_int(act_rx_pid, UVM_ALL_ON)
    `uvm_field_int(act_rx_endp, UVM_ALL_ON)
    `uvm_field_int(act_crc5_err, UVM_ALL_ON)
    `uvm_field_int(compare_success, UVM_ALL_ON)
    `uvm_field_string(compare_message, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "my_transaction");
    super.new(name);
    
    // Set fixed test data
    frame1 = 8'b0110_1001;  // PID frame
    frame2 = 8'b0000_1000;  // Address frame
    frame3 = 8'b01001_001;  // CRC5 frame
    
    // Decoding Fields
    decode_fields();
    
    // Set partial expected values (CRC5 error flag set by reference model)
    exp_rx_pid = 4'b1001;   // OUT token
    exp_rx_endp = endpoint; // Endpoint
    
    compare_success = 0;
    compare_message = "";
  endfunction
  
  // Decoding field function
  function void decode_fields();
    // Decoding PID (lower 4 bits of PID)
    pid = frame1[3:0];
    
    // Decoding address (the lower 7 bits of the second frame)
    addr = frame2[6:0];
    
    // Decoding endpoint (3rd frame high 3 bits+2nd frame highest bit)
    endpoint = {frame3[7:5], frame2[7]};
    
    // Decoding the received CRC5 (the lower 5 bits of the third frame)
    crc5_received = frame3[4:0];
    
    `uvm_info("TRANSACTION", $sformatf("decoding result:\n  PID: %4b\n  Address: %7b (0x%02X)\n  Endpoint: %4b (0x%01X)\n  Received CRC5: %5b", 
              pid, addr, addr, endpoint, endpoint, crc5_received), UVM_MEDIUM)
  endfunction
  
  // data comparison
  function bit compare(my_transaction rhs);
    bit pid_match, endp_match, crc5_err_match;
    
    // Compare PID
    pid_match = (this.act_rx_pid == rhs.exp_rx_pid);
    if (!pid_match) begin
      compare_message = $sformatf("PID mismatch: Actual=%4b, Expected=%4b", 
                                  this.act_rx_pid, rhs.exp_rx_pid);
      `uvm_error("COMPARE", compare_message)
    end
    
    // Compare endpoints
    endp_match = (this.act_rx_endp == rhs.exp_rx_endp);
    if (!endp_match) begin
      compare_message = $sformatf("Endpoint mismatch: Actual=%4b, Expected=%4b", 
                                  this.act_rx_endp, rhs.exp_rx_endp);
      `uvm_error("COMPARE", compare_message)
    end
    
    // Compare CRC5 error flags
    crc5_err_match = (this.act_crc5_err == rhs.exp_crc5_err);
    if (!crc5_err_match) begin
      compare_message = $sformatf("CRC5 error flag mismatch: Actual=%b, Expected=%b", 
                                  this.act_crc5_err, rhs.exp_crc5_err);
      `uvm_error("COMPARE", compare_message)
    end
    
    // Overall results
    compare_success = pid_match && endp_match && crc5_err_match;
    
    if (compare_success) begin
      compare_message = $sformatf("Relatively successful:\n  PID: %4b ✓\n  Endpoint: %4b ✓\n  CRC5 error flag: %b ✓", 
                                  this.act_rx_pid, this.act_rx_endp, this.act_crc5_err);
      `uvm_info("COMPARE", compare_message, UVM_LOW)
    end else begin
      compare_message = $sformatf("Comparison failure:\n  PID matching: %b\n  Endpoint matching: %b\n  CRC5 error flag matching: %b", 
                                  pid_match, endp_match, crc5_err_match);
      `uvm_error("COMPARE", compare_message)
    end
    
    return compare_success;
  endfunction
  

endclass

`endif

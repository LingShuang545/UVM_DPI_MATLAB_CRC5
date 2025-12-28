`ifndef MY_MODEL__SV
`define MY_MODEL__SV


import "DPI-C" function chandle DPI_CRC5_initialize(input chandle existhandle);
import "DPI-C" function void DPI_CRC5_terminate(input chandle existhandle);
import "DPI-C" function void DPI_CRC5(input chandle existhandle,
                                      output int unsigned crc5_result[],
                                      input int unsigned addr[],
                                      input int unsigned endpoint[]);

class my_model extends uvm_component;
   
   uvm_blocking_get_port #(my_transaction)  port;
   uvm_analysis_port #(my_transaction)  ap;
   
   chandle dpi_ch;
   // Prepare data array
   int unsigned addr[1];
   int unsigned endpoint[1];
   int unsigned crc5_result[1];  
   logic [4:0] matlab_crc5;
   logic [4:0] received_crc5;
   extern function new(string name, uvm_component parent);
   extern function void build_phase(uvm_phase phase);
   extern virtual  task main_phase(uvm_phase phase);
   extern function void connect_phase(uvm_phase phase);
   
   `uvm_component_utils(my_model)
endclass 

function my_model::new(string name, uvm_component parent);
   super.new(name, parent);
endfunction 

function void my_model::build_phase(uvm_phase phase);
   super.build_phase(phase);
   port = new("port", this);
   ap = new("ap", this);
endfunction

function void my_model::connect_phase(uvm_phase phase);
   super.connect_phase(phase);
endfunction

task my_model::main_phase(uvm_phase phase);
   my_transaction tr;
   my_transaction new_tr;
   
   super.main_phase(phase);
   
   // Initialize MATLAB DPI
   dpi_ch = DPI_CRC5_initialize(null);
   
   while(1) begin
      port.get(tr);
      new_tr = new("new_tr");
      new_tr.copy(tr);
      
      #10ns;
       
      // Set the address and endpoint of the test case
      // address: 0000_100[6:0] = 000_0100 = 0x04 (7 bit)
      // endpoint: {frame3[7:5], frame2[7]} = {001, 0} = 0010 = 0x2 (4 bit)
      addr[0] = 7'h08;      // 0x04
      endpoint[0] = 4'h2;   // 0x2
      
      `uvm_info("MODEL", $sformatf("MATLAB crc5_calc: addr=0x%02X, endpoint=0x%01X", 
                addr[0], endpoint[0]), UVM_LOW)
      
      // Call DPI function
      DPI_CRC5(dpi_ch,
               crc5_result,
               addr,
               endpoint);
      
      // Obtain the results of MATLAB calculations
      //matlab_crc5 = logic'(crc5_result[0] & 5'b11111);
      received_crc5 = 5'b01001;  // CRC5 received from frame3
      
      // Compare CRC5
      //new_tr.exp_crc5_err = (matlab_crc5 != received_crc5);
      new_tr.exp_crc5_err = (crc5_result[0] != received_crc5);
      `uvm_info("MODEL", $sformatf("CRC5 result:\n  MATLAB calc: %5b\n  received_crc5: %5b\n  error flag: %b",
               crc5_result[0] , received_crc5, new_tr.exp_crc5_err), UVM_LOW)
      
      // Set expected output
      new_tr.exp_rx_pid = 4'b1001;  // OUT token
      new_tr.exp_rx_endp = 4'b0010; // Endpoint 0x2
      
      ap.write(new_tr);
   end
endtask

`endif

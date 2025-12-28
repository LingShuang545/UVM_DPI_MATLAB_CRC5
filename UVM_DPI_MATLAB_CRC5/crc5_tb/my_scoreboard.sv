`ifndef MY_SCOREBOARD__SV
`define MY_SCOREBOARD__SV
class my_scoreboard extends uvm_scoreboard;
   my_transaction  expect_queue[$];
   uvm_blocking_get_port #(my_transaction)  exp_port;
   uvm_blocking_get_port #(my_transaction)  act_port;
   `uvm_component_utils(my_scoreboard)

   extern function new(string name, uvm_component parent = null);
   extern virtual function void build_phase(uvm_phase phase);
   extern virtual task main_phase(uvm_phase phase);
endclass 

function my_scoreboard::new(string name, uvm_component parent = null);
   super.new(name, parent);
endfunction 

function void my_scoreboard::build_phase(uvm_phase phase);
   super.build_phase(phase);
   exp_port = new("exp_port", this);
   act_port = new("act_port", this);
endfunction 

task my_scoreboard::main_phase(uvm_phase phase);
   my_transaction  exp_tr, act_tr;

   bit result;
 
   super.main_phase(phase);
   fork 
      // Obtain expected values from reference models
      while (1) begin
         exp_port.get(exp_tr);
         expect_queue.push_back(exp_tr);
      end
      // Retrieve actual values from the monitor and compare them
      while(1) begin
         act_port.get(act_tr);
         exp_tr = expect_queue.pop_front();
         result = act_tr.compare(exp_tr);
         `uvm_info("scoreboard", $sformatf("result = %s",result ), UVM_LOW)
         if(result) `uvm_info("PASS", "CRC5 verification passed", UVM_LOW)
         else `uvm_error("FAIL", "CRC5 verification failed")
      end

   join
endtask
`endif

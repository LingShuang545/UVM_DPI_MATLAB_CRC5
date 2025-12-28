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
   my_transaction  get_expect,  get_actual, tmp_tran;
   string actual_file_name;
   string golden_file_name;
   int actual_file_h;
   int golden_file_h;
   int tr_id = -1;
   bit result;
 
   super.main_phase(phase);
   fork 
      while (1) begin
         exp_port.get(get_expect);
         expect_queue.push_back(get_expect);
      end
//      while (0) begin
//         act_port.get(get_actual);
//         if(expect_queue.size() > 0) begin
//            tmp_tran = expect_queue.pop_front();
//            result = get_actual.compare(tmp_tran);
//            $display("get_actual.dat1.size=%d",get_actual.dat1.size);
//            tr_id++;
//            actual_file_name = $sformatf("dbg_log/tr_%0d_actual.dat",tr_id);
//            golden_file_name = $sformatf("dbg_log/tr_%0d_golden.dat",tr_id);
//            actual_file_h = $fopen(actual_file_name,"w");
//            golden_file_h = $fopen(golden_file_name,"w");
//            foreach(tmp_tran.dat1[i]) begin
//               $fwrite(golden_file_h,"DAT1[%4d]:%3h    DAT2[%4d]:%3h    DAT3[%4d]:%3h\n",i,tmp_tran.dat1[i],i,tmp_tran.dat2[i],i,tmp_tran.dat3[i]);
//            end
//            foreach(get_actual.dat1[i]) begin
//               $fwrite(actual_file_h,"DAT1[%4d]:%3h    DAT2[%4d]:%3h    DAT3[%4d]:%3h\n",i,get_actual.dat1[i],i,get_actual.dat2[i],i,get_actual.dat3[i]);
//            end
//            $fclose(actual_file_h);
//            $fclose(golden_file_h);
//            if(result) begin 
//               `uvm_info("my_scoreboard", "Compare SUCCESSFULLY", UVM_LOW);
//            end
//            else begin
//               `uvm_error("my_scoreboard", "Compare FAILED");
//               $display("the expect pkt is");
//               tmp_tran.print();
//               $display("the actual pkt is");
//               get_actual.print();
//            end
//         end
//         else begin
//            `uvm_error("my_scoreboard", "Received from DUT, while Expect Queue is empty");
//            $display("the unexpected pkt is");
//            get_actual.print();
//         end 
//      end
   join
endtask
`endif

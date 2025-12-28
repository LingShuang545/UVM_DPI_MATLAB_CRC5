`ifndef MY_MONITOR__SV
`define MY_MONITOR__SV
class my_monitor extends uvm_monitor;

   virtual my_if vif;

   uvm_analysis_port #(my_transaction)  ap;


   
   `uvm_component_utils(my_monitor)
   function new(string name = "my_monitor", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
         `uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")
      ap = new("ap", this);
   endfunction

   extern task main_phase(uvm_phase phase);
   extern task collect_one_frame(my_transaction tr);
endclass

task my_monitor::main_phase(uvm_phase phase);
   my_transaction tr;
   while(1) begin
      //tr = my_transaction::type_id::create("tr");

      //tr.rx_data = new[3];

      //collect_one_frame(tr);
      //ap.write(tr);
   end
endtask

task my_monitor::collect_one_frame(my_transaction tr);
   int cnt;
   //while(1) begin
   //   @(posedge vif.clk);
   //   if(vif.vsync_vld_o&&vif.href_vld_o) begin
   //      tr.dat1[cnt] = vif.Y_dat_o;
   //      tr.dat2[cnt] = vif.Cb_dat_o;
   //      tr.dat3[cnt] = vif.Cr_dat_o;
   //      cnt++;
   //   end
   //   if(cnt==frame_size) begin
   //      break;
   //   end
   //end
   //`uvm_info("my_monitor", "end collect one frame", UVM_LOW);
endtask


`endif

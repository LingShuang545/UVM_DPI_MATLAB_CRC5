`ifndef MY_MODEL__SV
`define MY_MODEL__SV
import "DPI-C" function chandle DPI_RGB888_to_YCbCr444_initialize(input chandle existhandle);
import "DPI-C" function void DPI_RGB888_to_YCbCr444_terminate(input chandle existhandle);
import "DPI-C" function void DPI_RGB888_to_YCbCr444(input chandle existhandle,
                                                   output int unsigned Y_dat_o[],
                                                   output int unsigned Cb_dat_o[],
                                                   output int unsigned Cr_dat_o[],
                                                   input int unsigned R_dat_o[],
                                                   input int unsigned G_dat_o[],
                                                   input int unsigned B_dat_o[]
                                                   //input my_ctrl_s my_ctrl_struct
                                                   );
class my_model extends uvm_component;
   
   uvm_blocking_get_port #(my_transaction)  port;
   uvm_analysis_port #(my_transaction)  ap;

   extern function new(string name, uvm_component parent);
   extern function void build_phase(uvm_phase phase);
   extern virtual  task main_phase(uvm_phase phase);

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

task my_model::main_phase(uvm_phase phase);
   //chandle dpi_ch;
   my_transaction tr;
   my_transaction new_tr;
   super.main_phase(phase);
   //dpi_ch = DPI_RGB888_to_YCbCr444_initialize(null);
   while(1) begin
      port.get(tr);
      new_tr = new("new_tr");
      new_tr.copy(tr);
      #10ns;
      //DPI_RGB888_to_YCbCr444(dpi_ch,
      //                       new_tr.dat1,                       
      //                       new_tr.dat2,                       
      //                       new_tr.dat3,                       
      //                       tr.dat1,
      //                       tr.dat2,
      //                       tr.dat3,
      //                       tr.my_ctrl_struct);
      new_tr.init_data;
      `uvm_info("my_model", "call matlab gen new tr:", UVM_LOW)
      new_tr.print();
      ap.write(new_tr);
   end
endtask
`endif

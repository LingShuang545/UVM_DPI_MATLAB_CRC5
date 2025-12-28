`ifndef MY_DRIVER__SV
`define MY_DRIVER__SV
class my_driver extends uvm_driver#(my_transaction);

   virtual my_if vif;

   uvm_analysis_port #(my_transaction)  ap;

   `uvm_component_utils(my_driver)
   function new(string name = "my_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
         `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
      ap = new("ap", this);
   endfunction

   extern task main_phase(uvm_phase phase);
   extern task drive_one_frame(my_transaction tr);
endclass

task my_driver::main_phase(uvm_phase phase);
   my_transaction tr;

$display("waitting rst.....");

   while(1) begin
      $display("starting driver.....");   
      seq_item_port.get_next_item(req);
      $display("get_next_item.....");
      `uvm_info("my_driver", $sformatf("req.rx_data = %s",req.sprint ), UVM_LOW);
      $cast(tr,req.clone());
      ap.write(tr);
      //uvm_config_db#(my_ctrl_s)::set(null, "", "my_cfg", req.my_ctrl_struct);
      drive_one_frame(req);
      seq_item_port.item_done();
   end
endtask

task my_driver::drive_one_frame(my_transaction tr);
   //------------register----------
   vif.self_addr=7'b000_1000;
   vif.time_threshold=16'h00c8;
   vif.delay_threshole=6'h3f;
   //------------clk rst-----------
   //RX
   vif.ms=1'b0;
   vif.rx_lp_valid=1'b0;
   vif.rx_lp_sop=1'b0;
   vif.rx_lp_eop=1'b0;
   vif.rx_lt_ready=1'b1;
   //TX
   vif.tx_lt_cancle=1'b0;
   vif.tx_lt_sop=1'b0;	
   vif.tx_lt_eop=1'b0;
   vif.tx_lt_valid=1'b0;	
   vif.tx_lp_ready=1'b1;	
   vif.tx_lt_data=8'h0;	
   vif.tx_pid = 4'b0;
   vif.tx_addr= 7'b0;
   vif.tx_endp= 4'b0;
   vif.tx_valid=1'b0;
   vif.rx_lp_data = 8'b0;

    repeat(5) @(posedge vif.clk);

    `uvm_info("my_driver", "begin to drive one frame", UVM_LOW);
    `uvm_info("my_driver", $sformatf("tr.rx_data = %s",tr.sprint ), UVM_LOW);
    foreach(tr.rx_data[i])begin
        if(i==0)begin
            vif.rx_lp_data = tr.rx_data[0];
            vif.rx_lp_sop = 1'b1;
            #100 @(posedge vif.clk); 
            #1  vif.rx_lp_valid = 1'b1;
            #20 vif.rx_lp_valid = 1'b0;
            #0  vif.rx_lp_sop =1'b0;
        end
        else if(i==2)begin
            #0  vif.rx_lp_data = tr.rx_data[2];
            #0  vif.rx_lp_eop = 1'b1;
            #100 @(posedge vif.clk); 
            #1  vif.rx_lp_valid = 1'b1;
            #20 vif.rx_lp_valid = 1'b0;
            #0  vif.rx_lp_eop =1'b0;
        end
        else begin
            #0  vif.rx_lp_data = tr.rx_data[1];
            #100 @(posedge vif.clk); 
            #1  vif.rx_lp_valid = 1'b1;
            #20 vif.rx_lp_valid = 1'b0;
            #1000;
        end
    end


    `uvm_info("my_driver", "end drive one frame", UVM_LOW);
endtask


`endif

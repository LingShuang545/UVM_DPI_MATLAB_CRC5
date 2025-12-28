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
   extern task drive_usb_packet(my_transaction tr);
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
    drive_usb_packet(tr);

    `uvm_info("my_driver", "end drive one frame", UVM_LOW);
endtask

task my_driver::drive_usb_packet(my_transaction tr);
    `uvm_info("DRIVER", "Start driving USB CRC5 test package", UVM_LOW)
    
    // Drive the first frame: PID frame
    
    vif.rx_lp_sop = 1'b1;
    vif.rx_lp_data = tr.frame1;  // 8'b0100_1001
    #100 @(posedge vif.clk);
    #1  vif.rx_lp_valid = 1'b1;
    #20 vif.rx_lp_valid = 1'b0;
    #0  vif.rx_lp_sop <= 1'b0;
    `uvm_info("DRIVER", $sformatf("Drive frame 1: PID = 8'b%08b", tr.frame1), UVM_HIGH)
    
    // Drive the second frame: address+endpoint low 1 bit
    vif.rx_lp_data <= tr.frame2;  // 8'b0000_1000
    `uvm_info("DRIVER", $sformatf("Drive frame 2: Address+Endpoint = 8'b%08b (Address=0x%02X, EP_bit0=%b)", 
              tr.frame2, tr.addr, tr.frame2[7]), UVM_HIGH)
    
    #100 @(posedge vif.clk);
    #1  vif.rx_lp_valid = 1'b1;
    #20 vif.rx_lp_valid = 1'b0;
    
    // Drive the third frame: CRC5+endpoint high 3 bits
    vif.rx_lp_data <= tr.frame3;  // 8'b01001_001
    vif.rx_lp_eop <= 1'b1;  // the last frame
    
    `uvm_info("DRIVER", $sformatf("Drive frame 3: CRC5+ Endpoint height of 3 digits = 8'b%08b (CRC5=%5b, EP_high=%3b)", 
              tr.frame3, tr.crc5_received, tr.frame3[7:5]), UVM_HIGH)
    
    #100 @(posedge vif.clk);
    
   
    #1 vif.rx_lp_valid <= 1'b1;
    #20 vif.rx_lp_valid = 1'b0;
    vif.rx_lp_eop <= 1'b0;
    
    `uvm_info("DRIVER", "USB package driver completed", UVM_LOW)
    
    // delay
    repeat(10) @(posedge vif.clk);
  endtask

`endif

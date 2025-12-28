`ifndef MY_MONITOR__SV
`define MY_MONITOR__SV

class my_monitor extends uvm_monitor;
  
  virtual my_if vif;
  uvm_analysis_port #(my_transaction) ap;
  
  // Internal status
  my_transaction tr_collected;
  int packet_count = 0;
  
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
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      collect_transactions();
    join
  endtask
  
  task collect_transactions();
    forever begin
      // Waiting for reset release
      wait(vif.rst_n == 1'b1);
      
      // Create a new transaction
      tr_collected = my_transaction::type_id::create("tr_collected");
      
      // Waiting for the package to start (rx_pid_en is high)
      wait(vif.rx_pid_en == 1'b1);
      
      `uvm_info("MONITOR", "Detected rx_pid_en, start collecting results", UVM_MEDIUM)
      
      // Collect results
      collect_results();
      
      // Set the actual collected values
      tr_collected.act_rx_pid = vif.rx_pid;
      tr_collected.act_rx_endp = vif.rx_endp;
      tr_collected.act_crc5_err = vif.crc5_err;
      
      packet_count++;
      
      `uvm_info("MONITOR", $sformatf("Collect results for the %d -th package:\n  RX_PID: %4b\n  RX_ENDP: %4b\n  CRC5_ERR: %b", 
                packet_count, tr_collected.act_rx_pid, 
                tr_collected.act_rx_endp, tr_collected.act_crc5_err), UVM_LOW)
      
      // Send to analysis port
      ap.write(tr_collected);
      
    
      @(posedge vif.clk);
    end
  endtask
  
  task collect_results();
    int unsigned wait_count = 0;
    
    // Wait for enough time for DUT to process the package
    // How many clock cycles of pipeline delay does usb_link_rx have
    while(wait_count < 20) begin
      @(posedge vif.clk);
      wait_count++;
      
      // Monitor internal signals 
      if(vif.rx_pid_en) begin
        `uvm_info("MONITOR", $sformatf("clock cycle %d: rx_pid_en=1, rx_pid=%4b", 
                  wait_count, vif.rx_pid), UVM_HIGH)
      end
      
      if(vif.crc5_err) begin
        `uvm_info("MONITOR", $sformatf("clock cycle %d: CRC5 error detected", 
                  wait_count), UVM_HIGH)
      end
    end
    
    `uvm_info("MONITOR", $sformatf("Collection results completed, waiting for %d clock cycles", wait_count), UVM_MEDIUM)
  endtask
  
  // Report statistical information
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("MONITOR", $sformatf("A total of %d USB packets have been collected", packet_count), UVM_LOW)
  endfunction
  
endclass

`endif

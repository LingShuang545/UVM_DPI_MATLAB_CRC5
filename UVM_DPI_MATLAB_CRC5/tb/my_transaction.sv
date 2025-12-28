`ifndef MY_TRANSACTION__SV
`define MY_TRANSACTION__SV


class my_transaction extends uvm_sequence_item;

    //int unsigned rx_data[];
    logic [7:0] rx_data[3]; 
    //constraint my_transaction_c {
    //    rx_data.size == 3;
    //   // rx_data[0] == 8'b0110_1001;
    //   // rx_data[1] == 8'b0000_1000;
    //   // rx_data[2] == 8'b01001_001;
    //}

    extern function void init_data();

   // `uvm_object_utils_begin(my_transaction)
   //    `uvm_field_array_int (rx_data,UVM_ALL_ON)
   // `uvm_object_utils_end

    function new(string name = "my_transaction");
       super.new();
    endfunction
endclass

function void my_transaction::init_data();
    rx_data[0] = 8'b0110_1001;
    rx_data[1] = 8'b0000_1000;
    rx_data[2] = 8'b01001_001;
endfunction

`endif

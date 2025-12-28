# UVM_DPI_MATLAB_CRC5
Interaction between Reference Model of UVM Environment and MATLAB in Linux System


<<<<<<< HEAD


In digital circuit design verification, Matlab is often used as algorithm reference model to verify the correctness of RTL design. Because the project needs to use matlab, it is not suitable to convert matlab to c language in a short time. In this paper,.m file is compiled into.so library, and it is called in UVM environment through SystemVerilog DPI.

This article will record the flow of the experiment, RTL used here is a verification module about crc5 that I wrote on the set creation competition, the main purpose of this article is to explore how to call "Matlab" as a reference model, RTL internal details will not be explained too much, this UVM environment only involves "reference model", for random, coverage will not be discussed too much
=======
The architecture diagram of UVM is roughly drawn, and the DPI interface is simplified

<img width="1062" height="720" alt="UVM_ENV" src="https://github.com/user-attachments/assets/b1ec2299-059a-4717-ab91-3bc733534e9d" />

The actual path to Matlab is something like this.

<img width="751" height="171" alt="数据传递路径" src="https://github.com/user-attachments/assets/c3edd757-5791-47bd-87ff-fb9e21edb55a" />

Compile.m file to.so, use runtime library to realize.so call, use mcc(MatlabCompiler) to compile.m file to.so file, C/CPP completes data interaction with.so by calling corresponding API; because this way only depends on MatlabRuntime(MCR) shared library, it has good portability, and running the program does not need to install complete Matlab.
API supporting C++03 programming, mwArray API, introduced in Matlab_r2009: https://ww2.mathworks.cn/help/compiler_sdk/cxx_mwArray_API_shared_library.html
The gcc compiler version used in this article is 7.3.1 20180303 (Red Hat 7.3.1-5) (GCC)
If the gcc compiler version is too old, it will fail to compile

file catalog:

<img width="446" height="950" alt="文件目录" src="https://github.com/user-attachments/assets/98ee3842-7228-4146-8b6a-80a5e6e83172" />

File directory introduction:
Crc5_tb: UVM Test Environment Component
Matlab: Matlab compilation environment
RTL: RTL design file
Sim: Simulation Environment

The following is an experiment using RTL for my USB2.0 link layer design, mainly focusing on the internal crc5 module, setting up a UVM environment, and using DPI to call Matlab's. so library to implement a "beginner version" reference_madel.

Matlab compilation environment
DPI calls the API in libCRC5. h, which requires the use of the mwArray API for data structure conversion;
The header files corresponding to mwArray are mclmcrrt. h, mclcppclass. h, and the runtime shared library libmwmclmcrrt. so
How to use C++to transform data structures in the validation environment
Here is a diagram of the data types between SV and C attached

<img width="1024" height="525" alt="sv与c数据转换" src="https://github.com/user-attachments/assets/c672f81f-9e48-49ca-97a4-3663ae581a28" />

The Matlab for crc5 verification is as follows, which is only used as a testing environment. It is recommended to use English for printing data. After compiling into the SO library, it cannot be printed in Chinese
crc5_calc.m：
```MATLAB
% crc5_calc.m
function crc5_result = crc5_calc(addr, endpoint)
%USB CRC5 calculation function
% input: 7-bit address, 4-bit endpoint
% output: 5-bit CRC5 result, 11 bit data vector

%Combining addresses and endpoints into an 11 bit data vector in the USB specification,
% the data transmission order is LSB first
% 11 bit data: [addr [6:0], endpoint [3:0]]

% Ensure that the input is a binary representation
addr_bin = de2bi(addr, 7, 'left-msb');  %7-digit address
endpoint_bin = de2bi(endpoint, 4, 'left-msb');  %4-digit endpoint

% Build an 11 bit data vector (according to USB specifications, LSB first transmission)
data_vector = [addr_bin(7:-1:1),endpoint_bin(4:-1:1)];  %Reverse the bit order to match LSB first

fprintf('MATLAB CRC5 calc:\n');
fprintf('  addr: %s (0x%02X)\n', num2str(addr_bin), addr);
fprintf('  endpoint: %s (0x%01X)\n', num2str(endpoint_bin), endpoint);
fprintf('  data_vector(11位, LSB first): %s\n', num2str(data_vector));

% CRC5 polynomial: x^5 + x^2 + 1 (binary: 00101, hexadecimal: 0x05)
% initial value: 0x1F (All 1)
poly = 5;  % 0x05
crc = uint8(31);  % 0x1F (5 digits all 1)

% Calculate CRC5 bit by bit
for i = 1:11
    % Retrieve the current data bit
    data_bit = data_vector(i);
    
    % Obtain the highest bit of CRC
    crc_msb = bitget(crc, 5);
    
    % XOR operation
    if xor(data_bit, crc_msb)
        % Left shift XOR polynomial
        crc = bitxor(bitshift(crc, 1), poly);
    else
        % Only move left
        crc = bitshift(crc, 1);
    end
    
    % Maintain 5 positions
    crc = bitand(crc, 31);  % 0x1F
    
    fprintf('  bit%d: data_bit=%d, before_CRC=%05s, after_CRC=%05s\n', ...
            i, data_bit, ...
            dec2bin(bitxor(bitshift(crc, -1), poly*(crc_msb~=data_bit)), 5), ...
            dec2bin(crc, 5));
end

% USB CRC5 needs to be reversed and reversed
crc_reversed = 0;
for i = 1:5
    if bitget(crc, i)
        crc_reversed = bitset(crc_reversed, 6-i);
    end
end

crc5_result = bitxor(crc_reversed, 31);  % negate

fprintf('  calc_out CRC5: %05s\n', dec2bin(crc, 5));
fprintf('  reversed CRC5: %05s\n', dec2bin(crc_reversed, 5));
fprintf('  result CRC5(reversed+negate): %05s\n', dec2bin(crc5_result, 5));

end

```

The function of converting C++to a data format that Matlab can recognize:

```C++
#include "CRC5_common.h"
#include "mclmcr.h"
#include "mclcppclass.h"
#include "vcsuser.h"
#include <iostream>
#include <vector>

using namespace std;

//============================================================================================
// init_CRC5
//============================================================================================
void init_CRC5() {
    bool isok = false;
    
    // Initialize MATLAB runtime
    if (!mclInitializeApplication(NULL, 0)) {
        io_printf("[CRC5_common] Error: Could not initialize MATLAB application\n");
        return;
    }
    
    // Initialize CRC5 library
    isok = libcrc5_calcInitialize();
    
    if (isok) {
        io_printf("[CRC5_common] MATLAB CRC5 library initialized successfully\n");
    } else {
        io_printf("[CRC5_common] Error: MATLAB CRC5 library initialization failed\n");
    }
}

//============================================================================================
// term_CRC5
//============================================================================================
void term_CRC5() {
    libcrc5_calcTerminate();
    mclTerminateApplication();
    io_printf("[CRC5_common] MATLAB CRC5 library terminated\n");
}

//============================================================================================
// CRC5_main_process
//============================================================================================
void CRC5_main_process(uint32_t* crc5_result,
                      const uint32_t* addr,
                      const uint32_t* endpoint) {
    
    try {
        // Create MATLAB array
        mwArray m_addr(1, 1, mxUINT32_CLASS);
        mwArray m_endpoint(1, 1, mxUINT32_CLASS);
        mwArray m_crc5_result(1, 1, mxUINT32_CLASS);
        
        // Set input data
        uint32_t addr_value = *addr;
        uint32_t endpoint_value = *endpoint;
        
        m_addr(1, 1) = addr_value;
        m_endpoint(1, 1) = endpoint_value;
        
        io_printf("[CRC5_common] Calling MATLAB crc5_calc: addr=0x%X, endpoint=0x%X\n", 
                  addr_value, endpoint_value);

        //*******************************************************************     
        // Call MATLAB functions crc5_calc
        // Attention：The MATLAB function prototype is: crc5_result = crc5_calc(addr, endpoint)
        crc5_calc(1, m_crc5_result, m_addr, m_endpoint); 
        io_printf("[CRC5_common] MATLAB crc5_calc function completed\n");
        
        // Get the results
        uint32_t result;
        m_crc5_result.GetData(&result, 1);
        
        // Store results
        *crc5_result = result;
        
        io_printf("[CRC5_common] MATLAB CRC5 result: 0x%X (%d)\n", result, result);
        
    } catch (const mwException& e) {
        io_printf("[CRC5_common] MATLAB exception: %s\n", e.what());
    } catch (...) {
        io_printf("[CRC5_common] Unknown exception in CRC5 calculation\n");
    }
}

```

CRC5_common.h:

```C++
#ifndef CRC5_common_h_
#define CRC5_common_h_
#include "libcrc5_calc.h"
#include "CRC5_dpi.h"
#include <stdint.h>

// Declare public functions
void init_CRC5();
void term_CRC5();
void CRC5_main_process(uint32_t* crc5_result,
                      const uint32_t* addr,
                      const uint32_t* endpoint);

#endif

```

Functions that convert DPI-C to C++data format: These functions can be directly called in the reference model

```C++
#include "CRC5_dpi.h"
#include "CRC5_common.h"
//#include <iostream>

using namespace std;

//=============================================================================================
// DPI_CRC5_initialize
//=============================================================================================
DPI_DLL_EXPORT void* DPI_CRC5_initialize(void* existhandle) {
    //cout << "[DPI_CRC5] Initializing MATLAB CRC5 library..." << endl;
    init_CRC5();
    existhandle = NULL;
    return NULL;
}

//=============================================================================================
// DPI_CRC5_terminate
//=============================================================================================
DPI_DLL_EXPORT void DPI_CRC5_terminate(void* existhandle) {
    //cout << "[DPI_CRC5] Terminating MATLAB CRC5 library..." << endl;
    term_CRC5();
    existhandle = NULL;
}

//=============================================================================================
// DPI_CRC5
//=============================================================================================
DPI_DLL_EXPORT void DPI_CRC5(void* objhandle,
                            const svOpenArrayHandle crc5_result,
                            const svOpenArrayHandle addr,
                            const svOpenArrayHandle endpoint
                            ) {
    
    // Get SystemVerilog array pointer
    uint32_t* u_crc5_result = (uint32_t*)svGetArrayPtr(crc5_result);
    uint32_t* u_addr = (uint32_t*)svGetArrayPtr(addr);
    uint32_t* u_endpoint = (uint32_t*)svGetArrayPtr(endpoint);
    
    // Get array size
    int addr_size = svSize(addr, 1);
    int endpoint_size = svSize(endpoint, 1);
    
    //cout << "[DPI_CRC5] CRC5 calculation called" << endl;
    //cout << "[DPI_CRC5] Addr size: " << addr_size << ", Endpoint size: " << endpoint_size << endl;
    
    // Call the main processing function
    CRC5_main_process(u_crc5_result, u_addr, u_endpoint);
    
    //cout << "[DPI_CRC5] CRC5 calculation completed" << endl;
    
    objhandle = NULL;
}

```

CRC5_dpi.h:
```C++
#ifndef RTW_HEADER_CRC5_dpi_h_
#define RTW_HEADER_CRC5_dpi_h_

#ifdef __cplusplus
#define DPI_LINK_DECL extern "C"
#else
#define DPI_LINK_DECL
#endif

#ifndef DPI_DLL_EXPORT
#ifdef _MSC_VER
#define DPI_DLL_EXPORT __declspec(dllexport)
#else
#define DPI_DLL_EXPORT 
#endif
#endif

#include <svdpi.h>


// DPI Function Declaration
DPI_LINK_DECL
DPI_DLL_EXPORT void* DPI_CRC5_initialize(void* existhandle);
DPI_LINK_DECL
DPI_DLL_EXPORT void DPI_CRC5(void* objhandle,
                             const svOpenArrayHandle crc5_result,
                             const svOpenArrayHandle addr,
                             const svOpenArrayHandle endpoint
                             );
DPI_LINK_DECL
DPI_DLL_EXPORT void DPI_CRC5_terminate(void* existhandle);

#endif

```

Only crc5_calc. m, crc5_strc_cpp, and Makefile are needed, and all other files are generated through Makefile

```Makefile
CUR_DIR_PATH := $(shell echo $(CURDIR))

all:create_folder matlab_gen gen_lib

# filename
FOLDER_NAME := output

# src_cpp
#cpp := src_cpp
cpp := crc_src_cpp
# Check if the folder exists
ifeq ($(wildcard $(FOLDER_NAME)),)
# If the folder does not exist, create a folder
create_folder:
	@echo "Creating $(FOLDER_NAME) folder"
	mkdir -p $(FOLDER_NAME)
else
# If the folder already exists, no action will be taken
create_folder:
	@echo "$(FOLDER_NAME) folder already exists"
endif

# default target
.PHONY: default
default: create_folder


matlab_gen:
	${MATLAB_HOME}/bin/mcc -W cpplib:libcrc5_calc crc5_calc.m  -g -d output/

gen_lib:
	g++ -shared -fPIC -g -Wno-write-strings \
	-Ioutput -I${VCS_HOME}/include -Icrc_src_cpp -I${MATLAB_HOME}/extern/include \
	-lmwmclmcrrt -L${MATLAB_HOME}/runtime/glnxa64 \
	-lcrc5_calc -Loutput \
	-Wl,-rpath=${CUR_DIR_PATH} -Wl,-rpath=${CUR_DIR_PATH}/output \
	./crc_src_cpp/CRC5_common.cpp \
	./crc_src_cpp/CRC5_dpi.cpp \
	-o libcrc5_calc_sim.so

clean:
	-rm -rf output *.so

```

Before starting, there is another shell script that needs to be sourced, including VCS simulation later on. You can find the location of source_ce.csh based on the file architecture diagram
source_me.csh：
Modify the MATLAB HOME here according to your own path

```Shell
#!/bin/tcsh -f
setenv MATLAB_HOME /usr/local/MATLAB/R2021b
setenv LD_LIBRARY_PATH ${MATLAB_HOME}/runtime/glnxa64:${MATLAB_HOME}/bin/glnxa64:${MATLAB_HOME}/extern/bin/glnxa64:${MATLAB_HOME}/sys/os/glnxa64:${MATLAB_HOME}/sys/opengl/lib/glnxa64:/usr/local/MATLAB/R2021b/bin/glnxa64:/usr/local/MATLAB/R2021b/sys/os/glnxa64:${LD_LIBRARY_PATH}
```

Execute Makefile
```Shell
make all
```

UVM reference model calls DPI
my_model.sv：
Here we import the function from CRC5_depi.cpp just now. If you want to use this DPI, you need to make slight modifications to DPI-CRC5_initialize and DPI-CRC5_terminate. DPI-CRC5 needs to be written according to your own Matlab function

```SystemVerilog
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

```



Only one Makefile or filelist. f file is needed in the sim directory
The content of the Makefile file is as follows:
Include the. so library generated from the Matlab file in pre_Sim

```Makefile

all: clean comp run

pre_sim:
	mkdir -p dbg_log;
	rm -rf bootstrap.file ;
	touch bootstrap.file ;
	echo '#'!SV_LIBRARIES >> bootstrap.file;
	echo ../matlab/output/libcrc5_calc >> bootstrap.file;
	echo ../matlab/libcrc5_calc_sim >> bootstrap.file;

comp: pre_sim
	vcs -full64 \
	-kdb -lca \
	-debug_access+all \
	-sverilog \
	-ntb_opts uvm \
	-timescale=1ns/1ns \
	+incdir+../crc5_tb \
	-l comp.log \
	-f ./filelist.f 
	
run:
	./simv \
	+UVM_TESTNAME=my_case0 \
	+ntb_solver_array_size_warn=100000 \
	+ntb_random_seed_automatic \
	-sv_liblist ./bootstrap.file \
	-l sim.log

verdi:
	verdi -ssf top_tb.fsdb &

clean:
	-rm -rf simv* csrc *.log *.fsdb dbg_log novas.* ucli.key vc_hdrs.h  verdi_config_file verdiLog

	#-LDFLAGS '-Wl,-rpath=../matlab/output -Wl,-rpath=../matlab' \

```

simulation results
It can be observed that when calling Matlab, the information printed in the Matlab function and the error flag of the scoreboard at the end are 0

<img width="1096" height="750" alt="仿真结果" src="https://github.com/user-attachments/assets/ee4b100b-b4bb-4ad8-a63a-eca1a90877a9" />

Veridi waveform display

<img width="1911" height="837" alt="verdi波形" src="https://github.com/user-attachments/assets/75facfda-e1e8-4f21-b488-18af3c8f40ac" />
>>>>>>> 8113e42ba7d4f30782b3a797d388d5bcf0a9d9bd



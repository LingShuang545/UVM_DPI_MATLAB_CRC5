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

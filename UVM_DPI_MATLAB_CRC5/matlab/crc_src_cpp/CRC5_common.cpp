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

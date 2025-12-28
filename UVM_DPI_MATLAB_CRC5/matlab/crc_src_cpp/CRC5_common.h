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

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

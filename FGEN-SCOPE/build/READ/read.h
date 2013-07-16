#include "extcode.h"
#pragma pack(push)
#pragma pack(1)

#ifdef __cplusplus
extern "C" {
#endif

void __stdcall READ(int32_t Slope, uint16_t TriggerType, 
	uint16_t TriggerSource, uint16_t ChA_Source, int16_t ChA_Coupling, 
	uint16_t ChB_Source, int16_t ChB_Coupling, int32_t RecordLength, 
	double SampleRateHz, uint16_t Acquire, uint16_t WaveformType, 
	double Frequency, double DCOffset, double Amplitude, 
	uint8_t input_FG_Connection, int32_t len, double interleavedArray[]);

long __cdecl LVDLLStatus(char *errStr, int errStrLen, void *module);

#ifdef __cplusplus
} // extern "C"
#endif

#pragma pack(pop)


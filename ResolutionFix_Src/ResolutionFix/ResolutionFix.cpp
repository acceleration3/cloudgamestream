#include <iostream>
#include <nvapi.h>
#include <Windows.h>
#include <fstream>

int main()
{
	if (NvAPI_Initialize() != NVAPI_OK)
	{
		std::cout << "NvAPI failed to initialize" << std::endl;
		return 1;
	}

	NvU32 gpu_count = 0;
	NvPhysicalGpuHandle physical_gpus[NVAPI_MAX_PHYSICAL_GPUS];

	if (NvAPI_EnumPhysicalGPUs(physical_gpus, &gpu_count) != NVAPI_OK)
	{
		std::cout << "Failed to query GPUs." << std::endl;
		return 2;
	}

	NvU32 display_count = 0;

	if (NvAPI_GPU_GetAllDisplayIds(physical_gpus[0], NULL, &display_count) != NVAPI_OK)
	{
		std::cout << "Failed to get display count." << std::endl;
		return 3;
	}

	NV_GPU_DISPLAYIDS displays[NVAPI_MAX_DISPLAYS];
	displays[0].version = NV_GPU_DISPLAYIDS_VER;

	if (NvAPI_GPU_GetAllDisplayIds(physical_gpus[0], displays, &display_count))
	{
		std::cout << "Failed to query displays." << std::endl;
		return 4;
	}
	
	NV_EDID edid;
	unsigned char edid_data[129] = "\x00\xFF\xFF\xFF\xFF\xFF\xFF\x00\x3A\xC4\x00\x00\x00\x00\x00\x00\x0F\x19\x01\x04\xA5\x3E\x22\x64\x06\x92\xB1\xA3\x54\x4C\x99\x26\x0F\x50\x54\x00\x00\x00\x95\x00\x81\x00\xD1\x00\xD1\xC0\x81\xC0\xB3\x00\x00\x00\x00\x00\x1A\x36\x80\xA0\x70\x38\x1E\x40\x30\x20\x35\x00\x13\x2B\x21\x00\x00\x1A\x39\x1C\x58\xA0\x50\x00\x16\x30\x30\x20\x3A\x00\x6D\x55\x21\x00\x00\x1A\x00\x00\x00\xFD\x00\x1E\x46\x1E\x8C\x36\x01\x0A\x20\x20\x20\x20\x20\x20\x00\x00\x00\xFC\x00\x4E\x56\x49\x44\x49\x41\x20\x56\x47\x58\x20\x0A\x20\x00\x08";
	
	memset(&edid, 0, sizeof(edid));
	edid.version = NV_EDID_VER;
	memcpy(edid.EDID_Data, edid_data, sizeof(edid_data));
	edid.sizeofEDID = sizeof(edid_data);
	
	if (NvAPI_GPU_SetEDID(physical_gpus[0], displays[0].displayId, &edid))
	{
		std::cout << "Failed to query displays." << std::endl;
		return 5;
	}

	std::cout << "Successfully set EDID." << std::endl;
	return 0;
}
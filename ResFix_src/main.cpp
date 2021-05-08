#include <windows.h>

#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <map>
#include <fstream>
#include <sstream>
#include <filesystem>

#include "nvapi.h"

#define NVAPI_EXIT_IF_ERROR(func, msg) \
{ \
    NvAPI_Status status; \
    NvAPI_ShortString string; \
    if ((status = func) != NVAPI_OK) { \
        NvAPI_GetErrorMessage(status, string); \
        std::cout << msg << " Error: " << string << std::endl; \
        NvAPI_Unload(); \
        return false; \
    } \
}

bool nv_set_edid(const std::uint32_t gpu_index, const std::uint32_t display_index, const std::string_view edid_file)
{
    std::fstream edid_stream(edid_file);
    if (!edid_stream.good()) {
        std::cout << "ERROR: Failed to open EDID file." << std::endl;
        return false;
    }
    
    std::vector<std::uint8_t> edid_data;
    std::uint32_t byte;
    while(!edid_stream.eof()) {
        edid_stream >> std::hex >> byte;
        edid_data.push_back(byte);
    }
    if (edid_data.size() != 256) {
        std::cout << "ERROR: Invalid EDID data (size != 256 bytes). The data is either malformed or not in the NVIDIA format." << std::endl;
        return false;
    }

    NVAPI_EXIT_IF_ERROR(NvAPI_Initialize(), "ERROR: Failed to initialize NVAPI.");

    NvU32 gpu_count = 0;
    NvPhysicalGpuHandle physical_gpus[NVAPI_MAX_PHYSICAL_GPUS];
    NVAPI_EXIT_IF_ERROR(NvAPI_EnumPhysicalGPUs(physical_gpus, &gpu_count), "ERROR: NvAPI_EnumPhysicalGPUs failed to get GPU info.");
    if (gpu_count <= 0) {
        std::cout << "ERROR: Invalid GPU count: " << gpu_count << std::endl;
        return false;
    }

    NvU32 display_count = 0;
    NVAPI_EXIT_IF_ERROR(NvAPI_GPU_GetAllDisplayIds(physical_gpus[0], NULL, &display_count), "ERROR: NvAPI_GPU_GetAllDisplayIds failed to get available display count.");
    
    NV_GPU_DISPLAYIDS displays[NVAPI_MAX_DISPLAYS];
    displays[0].version = NV_GPU_DISPLAYIDS_VER;
    NVAPI_EXIT_IF_ERROR(NvAPI_GPU_GetAllDisplayIds(physical_gpus[0], displays, &display_count), "ERROR: NvAPI_GPU_GetAllDisplayIds failed to get display info.");

    if (gpu_index >= gpu_count) {
        std::cout << "ERROR: Invalid GPU index: count=" << gpu_count << ", index=" << gpu_index << std::endl;
        return false;
    }
    if (display_index >= display_count) {
        std::cout << "ERROR: Invalid display index: count=" << display_count << ", index=" << display_index << std::endl;
        return false;
    }

    NV_EDID edid{};
    edid.version = NV_EDID_VER;
    std::copy(edid_data.begin(), edid_data.end(), edid.EDID_Data);
    edid.sizeofEDID = edid_data.size();
    NVAPI_EXIT_IF_ERROR(NvAPI_GPU_SetEDID(physical_gpus[gpu_index], displays[display_index].displayId, &edid), "ERROR: NvAPI_GPU_SetEDID failed to set EDID.");

    NvAPI_Unload();
    return true;
}

int main(int argc, char *argv[])
{
    std::vector<std::string> args;
    for (int i = 0; i < argc; i++) {
        args.push_back(std::string(argv[i]));
    }

    for (auto arg = args.begin(); arg != args.end(); arg++) {
        if (*arg == "set-edid") {
            auto gpu_index_arg = std::next(arg);
            if(gpu_index_arg == args.end()) {
                std::cout << "ERROR: set-edid command missing GPU index argument." << std::endl;
                return -1;  
            }

            auto display_index_arg = std::next(gpu_index_arg);
            if(display_index_arg == args.end()) {
                std::cout << "ERROR: set-edid command missing display index argument." << std::endl;
                return -1;  
            }

            auto edid_file_arg = std::next(display_index_arg);
            if(edid_file_arg == args.end()) {
                std::cout << "ERROR: set-edid command missing EDID file argument." << std::endl;
                return -1;
            }
            
            std::string edid_file = *edid_file_arg;
            if (!std::filesystem::exists(edid_file)) {
                std::cout << "ERROR: EDID file \"" << edid_file << "\" does not exist." << std::endl;
                return -1;
            }

            std::uint32_t gpu_index = std::atoi(gpu_index_arg->c_str());
            std::uint32_t display_index = std::atoi(display_index_arg->c_str());
            if (!nv_set_edid(gpu_index, display_index, edid_file)) {
                return -1;
            }    
            std::cout << "Success: Set EDID file sucessfully." << std::endl;
        }
    }

    return 0;
}
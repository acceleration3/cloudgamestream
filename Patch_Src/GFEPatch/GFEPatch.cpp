#include <iostream>
#include <windows.h>
#include <regex>
#include <fstream>
#include <string_view>

int main()
{
	const std::string target_file = "C:\\Program Files\\NVIDIA Corporation\\NvContainer\\plugins\\LocalSystem\\GameStream\\Main\\_NvStreamControl.dll";

	DISPLAY_DEVICEA display_device{ 0 };
	display_device.cb = sizeof(display_device);
	
	for (int i = 0; EnumDisplayDevicesA(NULL, i, &display_device, 0); i++)
	{
		auto gpu_name = std::string(display_device.DeviceString);

		if (gpu_name.find("NVIDIA") != std::string::npos)
		{
			auto device_id = std::string(display_device.DeviceID);
			std::cout << "Dev Name: " << gpu_name << std::endl;

			const std::regex device_regex("DEV_(\\w*)&");
			std::smatch matches;
			std::string device_string = std::string(display_device.DeviceID);

			std::regex_search(device_string, matches, device_regex);

			if (matches.size() != 2)
			{
				std::cout << "Failed to match regex." << std::endl;
				return 1;
			}

			std::cout << "Dev ID: " << matches[1] << std::endl;

			uint64_t target_device_id = std::stoll(matches[1], nullptr, 16);

			std::ifstream target_dll_in(target_file, std::ios::binary);

			if (!target_dll_in.is_open())
			{
				std::cout << "Target file not found." << std::endl;
				return 2;
			}

			std::vector<char> contents((std::istreambuf_iterator<char>(target_dll_in)), std::istreambuf_iterator<char>());

			bool found = false;

			for (int i = 0; i < contents.size(); i++)
			{
				uint64_t memory = *(uint64_t*)(contents.data() + i);

				if (memory == 0x13D9ULL)
				{
					found = true;
					std::cout << "found: 0x" << std::hex << i << std::endl;
					*(uint64_t*)(contents.data() + i) = target_device_id;
				}
			}

			if (!found)
			{
				std::cout << "Found no signature." << std::endl;
				return 3;
			}

			target_dll_in.close();

			std::string backup = target_file + ".bak";
			rename(target_file.c_str(), backup.c_str());

			std::ofstream target_dll_out(target_file, std::ios::binary);
			target_dll_out.write(contents.data(), contents.size());
			target_dll_out.close();

			return 0;
		}
	}
	
	std::cout << "Found no NVIDIA device to patch." << std::endl;
	return 4;
}
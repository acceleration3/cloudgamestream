A PowerShell script that automatically prepares a cloud Windows Server for usage with what you favor. Automatically installs Openstream for use with Moonlight. 

# What is this?
This a fork of the cloudgamestream GitHub repo available here: https://github.com/acceleration3/cloudgamestream

It automatically install Openstream, Visual Studio Redist, Firefox, VBCable, and a cool GPU updater. 

In order to use it, make sure to disable the IE enhanced security configuration in the server manager and install AnyDesk. 

Download AnyDesk: https://anydesk.com/en

The "cool" GPU updater is compatible with...

### These Operating Systems:
* Windows Server 2016
* Windows Server 2019

### These GPUs:
* AWS G3.4xLarge (Tesla M60)
* AWS G2.2xLarge (GRID K520)
* AWS G4dn.xLarge (Tesla T4 with vGaming driver)
* AWS G4ad.2xlarge (AMD V520 with AMD driver)
* Azure NV6 (Tesla M60)
* Paperspace P4000 (Quadro P4000)
* Paperspace P5000 (Quadro P5000)
* Google P100 VW (Tesla P100 with Virtual Workstation Driver)
* Google P4 VW (Tesla P4 with Virtual Workstation Driver)
* Google T4 VW (Tesla T4 with Virtual Workstation Driver)

If your server type is not here, just choose "n" when asked about the GPU updater. Please stay in tune for a version for AMD GPUs and Windows 10. 

### What is Openstream?
Openstream is a remote desktop like application that allows users of the popular Moonlight application to use the desktop instead of their library of games. 
For this to work with AMD GPUs, you need to join the Moonlight Discord. 

Join here: https://moonlight-stream.org/discord

Openstream repo is here: https://github.com/LS3solutions/openstream-server

### What would this be useful for?
This would be useful for video/creative, obviously gaming, but also great for general remote desktoping in case your current computer is a bit low powered.

Keep in mind Openstream is essentially alpha software, once again, there are newer versions on the Moonlight Discord.

# How to start the script
You just need to install the newest release here: 
https://github.com/rionthedeveloper/cloudopenstream/releases

When you download it, extract the ZIP and you should see a folder with the name of the archive. Open it. *While holding shift*, right click the folder and click "Open in Powershell window" 

On the PowerShell window, type `.\setup.ps1` and follow the script from there! After it's exectuted, head back to the folder with all the resources and find the "bin" folder. 

Once you do that, extract the updater ZIP archive, right click "GPU Updater Tool.ps1" and run with Powershell - if the script immediately closes, right click and click edit, then the green play button in the Powershell ISE toolbar.

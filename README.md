Green Beret for MEGA65
======================

Green Beret, also known as Rush'n Attack, is a side-scrolling arcade game released by Konami in 1985. Players take on the role of an elite soldier on a mission to infiltrate enemy territory using only a knife and limited weapon pickups, such as flamethrowers, bazookas, and grenades. The game is set against a Cold War backdrop, featuring intense action as players battle waves of enemy troops, attack dogs, and fortified bunkers. With its fast-paced gameplay, strategic combat, and memorable soundtrack, Green Beret remains a standout title in the run-and-gun arcade genre, beloved by retro gaming enthusiasts for its challenging mechanics and classic arcade feel.

This core is based on the
[Arcade-RushnAttack_MiSTer](https://github.com/MiSTer-devel/Arcade-RushnAttack_MiSTer)
Green Beret / Rush'n Attack core which
itself is based on the wonderful work of [MrX-8B](AUTHORS).

The core uses the [MiSTer2MEGA65](https://github.com/sy2002/MiSTer2MEGA65)
framework and [QNICE-FPGA](https://github.com/sy2002/QNICE-FPGA) for
FAT32 support (loading ROMs, mounting disks) and for the
on-screen-menu.

How to install on your MEGA65
---------------------------------------------
Download the powershell or shell script from the **CORE** directory depending on your preferred platform ( Windows, Linux/Unix and MacOS supported )

Run the script: a) First extract all the files within the zip to any working folder.

b) Copy the powershell or shell script to the same folder and execute it to create the following files.

**Ensure the following files are present and sizes are correct**
![image](https://github.com/user-attachments/assets/a61ae059-2b4d-4665-bd4c-be058ad52bee)

For Windows run the script via PowerShell - gberet_rom_installer.ps1  
Simply select the script and with the right mouse button select the Run with Powershell.

For Linux/Unix/MacOS execute ./gberet_rom_installer.sh  
The script will automatically create the /arcade/gberet folder where the generated ROMs will reside.  

The output produced as a result of running the script(s) from the cmd line should match the following depending on your target platform.
![image](https://github.com/user-attachments/assets/59214ce5-d996-4f3a-b287-1be72eeb35aa)

Copy or move "arcade/gberet" to your MEGA65 SD card: You may either use the bottom SD card tray of the MEGA65 or the tray at the backside of the computer (the latter has precedence over the first).  

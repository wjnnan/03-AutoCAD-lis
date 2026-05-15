# Network-Design-Tools
This is a collection of automation scripts for AutoCAD and ArcGIS. Languages include Python, VBA, Lisp, and AHK. These scripts are being used to automate repetitive aspects of Fiber and Coax design.

## Code Environment Setup
1. Install VSCode: https://code.visualstudio.com/Download
2. Install Git: https://git-scm.com/downloads
3. In this Github repository, click the green "Code" button above. Copy the Clone web URL.
4. Open VSCode. On the Home page, select the option to clone a Git repository. Paste the Clone URL you copied and hit enter. This will re-create the repository on your computer.

## Lisp AutoCAD Scripts
1. Follow AutoDesk's tutorial to setup the AutoLISP VSCode Extension: https://help.autodesk.com/view/ACDLT/2024/ENU/?guid=GUID-8EADDE55-CD92-422A-8493-9C7A19880629
2. Use this repo's "lisp" subfolder as the workspace for AutoLISP.
3. In AutoCAD, run the "APPLOAD" command. When the window opens, click the Startup Suite -> Contents button in the bottom right.
4. Navigate to the script(s) you want to auto-load, and select them. This way the macros will be loaded any time AutoCAD starts. Repeat this process whenever you create a new script.

## Python AutoCAD Scripts
1. Install Python: https://www.python.org/downloads/
2. Python automatically installs a utility called "pip", but VSCode isn't configured to use it yet. use these steps to add pip to your PC's PATH:
    1. Find the Scripts folder in Python's Program files. On many PCs this is located at "C:\Users\username\AppData\Local\Programs\Python\Python###\Scripts". Copy the path of this folder.
    2. In the Windows search bar, search for and open the Control Panel.
    3. In the Control Panel search bar, look for "path", and click on "Edit environment variables for your account"
    4. Under "User variables for ____" select Path, then Edit.
    5. Select Add, then paste in the folder path you found earlier.
    6. Your Path variable list should look something like this if everything was successful: 
    ![](https://i.imgur.com/POFUJGZ.png)
3. Restart your computer once pip is added to PATH.
4. After restarting, open VSCode, and open the Terminal with View -> Terminal.
5. Type "pip install pyautocad" and hit enter.
6. You can use the Run And Debug menu to run python scripts, and they will interact with CAD.
7. In the future this setup will be edited to allow running python scripts directly from AutoCAD, including user input.

## Python ArcGIS Scripts
1. This section is WIP
2. Outdated instructions: https://developers.arcgis.com/python/latest/guide/get-started/
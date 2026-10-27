# PersistFinder
As the name suggests, this PowerShell script is designed to identify the presence and persistence mechanisms of an application on a Windows machine. It scans all accessible drives for files matching a specified name and detects associated persistence mechanisms, including registry entries, scheduled tasks, and running processes.

# Note
This script only identifies persistence mechanisms and does not delete or remove anything from the system. Therefore, it is safe to run even on production machine.

# Two Versions of the Script available in the repository for your preference use case
PersistFinder_QuickScan.ps1 → Scans the *C:\* drive only and usually completes in less than a minute.
PersistFinder.ps1 → Dynamically detects all drives connected to the machine and scans them for persistence mechanisms. Takes longer than 10 minutes in some cases.

# Important Note
In the beginning of the script, make sure to enter the file name in the keyword field shown below for which you want to search before running the script.

```$keyword = "<FILE_NAME_GOES_HERE>"```

For example:

```$keyword = "Shift"```

# How to Run?
Copy and paste the script in the CrowdStrike RTR "Edit & run scripts" box and run the script with the timeout argument.

```-Timeout="800" ```

You can also run this script in PowerShell with below command line:

```powershell.exe -ExecutionPolicy Bypass -File .\PersistFinder.ps1```


# Use Case:
This script helps in finding persistence related to PUP or malicious files presence on the machine.

# Snapshot of Script Output:
![output_snap](https://github.com/himanshughub/PersistFinder/blob/main/Snapshots/PersistFinder_Output_snapshot1.png)

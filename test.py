import subprocess
import os

# Get the current script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

try:
    subprocess.run("iwr --help", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
except subprocess.CalledProcessError:
    print("Installing iwr...")

    powershell_script = r"""
    $url = 'https://get.scoop.sh'
    $scoop_dir = Join-Path $env:USERPROFILE 'scoop'
    Invoke-WebRequest -Uri $url -OutFile scoop.ps1
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    .\scoop.ps1 -install -global
    """
    
    subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", powershell_script], shell=True, cwd=script_dir)
    print("iwr (scoop) installed.")

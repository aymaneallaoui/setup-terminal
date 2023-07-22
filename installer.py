import os
import requests
import zipfile
import subprocess


url = "https://github.com/junegunn/fzf/releases/download/0.42.0/fzf-0.42.0-windows_amd64.zip"


download_path = "fzf-0.42.0-windows_amd64.zip"


extract_dir = "C:/Windows/System32/"



def download_and_extract(url, download_path, extract_dir):
    
    print("Downloading file...")
    with requests.get(url, stream=True) as response:
        with open(download_path, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

    
    print("Extracting files...")
    with zipfile.ZipFile(download_path, "r") as zip_ref:
        zip_ref.extractall(extract_dir)

    
    os.remove(download_path)
    print("Extraction complete!")

if __name__ == "__main__":
    
    script_dir = os.path.dirname(os.path.abspath(__file__))

    

    if not os.path.exists(extract_dir):
        print("Destination directory does not exist. Please ensure 'C:/Windows/System32/' exists.")
    else:
        download_and_extract(url, download_path, extract_dir)

        
        try:
            subprocess.run("winget --help", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        except subprocess.CalledProcessError:
            print("Installing winget...")
            subprocess.run("iex (new-object net.webclient).downloadstring('https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.Winget.Source.appxbundle')", shell=True, check=True)
            print("winget installed.")

        
        try:
            subprocess.run("iwr --help", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        except subprocess.CalledProcessError:
            print("Installing iwr...")
            iwr_cmd = "(new-object net.webclient).downloadstring('https://get.scoop.sh')"
            subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", iwr_cmd], cwd=script_dir)
            print("iwr (scoop) installed.")

        
        scripts_to_run = ["setup.bat", "install_dependencies.ps1", "config.bat"]
        for script in scripts_to_run:
            script_path = os.path.join(script_dir, script)
            if os.path.exists(script_path):
                print(f"Running {script}...")
                subprocess.Popen(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "Start-Process", script_path, "-Verb", "RunAs"])
                print(f"{script} launched.")
            else:
                print(f"Script {script} not found in the script directory.")

from typing import Tuple, Optional, List
import subprocess
import platform
import sys
import os

# Define the version number at the top of the file
VERSION = "0.4.0"  # Update this value to change the version number

MULTI_PACKAGE_COMMANDS = {
    'install': 'Installing',
    'download': 'Downloading'
}

def check_winget() -> Tuple[bool, Optional[str]]:
    """
    Check if the system is Windows and has winget installed.
    
    Returns:
        Tuple[bool, Optional[str]]: A tuple containing:
            - bool: True if system is Windows and winget is installed, False otherwise
            - Optional[str]: Error message if check fails, None otherwise
    """
    # Check if system is Windows
    if platform.system() != "Windows":
        return False, "This application requires Windows."
    
    # Check if winget is installed
    try:
        # Run 'winget --version' and capture output
        result = subprocess.run(
            ["winget", "--version"], 
            capture_output=True, 
            text=True, 
            check=False
        )
        
        # Check if command was successful
        if result.returncode == 0:
            return True, None
        else:
            return False, "Winget is not installed or not accessible."
    except FileNotFoundError:
        return False, "Winget is not installed or not in PATH."
    except Exception as e:
        return False, f"Error checking winget: {str(e)}"

def find_latest_download(package_id: str) -> Optional[str]:
    """
    Find the latest downloaded folder for a package in Downloads directory.
    
    Args:
        package_id: The package ID to look for
        
    Returns:
        Optional[str]: Path to the latest download folder if found, None otherwise
    """
    downloads_dir = os.path.expanduser("~\\Downloads")
    package_name = package_id.split('.')[-1]  # Get last part of package ID
    
    # Find all folders that contain the package name
    matching_folders = []
    for item in os.listdir(downloads_dir):
        item_path = os.path.join(downloads_dir, item)
        if os.path.isdir(item_path) and package_name in item:
            matching_folders.append(item_path)
    
    if not matching_folders:
        return None
    
    # Get the most recently modified folder
    return max(matching_folders, key=os.path.getmtime)

def run_winget(args: list) -> Tuple[int, Optional[str]]:
    """
    Run winget with the provided arguments.
    
    Args:
        args: List of arguments to pass to winget
        
    Returns:
        Tuple[int, Optional[str]]: Return code and captured output if any
    """
    try:
        cmd = ["winget"] + args
        process = subprocess.run(cmd, check=False)
        return process.returncode, None
    except Exception as e:
        print(f"Error running winget: {str(e)}")
        return 1, None

def handle_multi_package(packages: List[str], command: str, output_path: Optional[str] = None, archive: bool = False, run_installer: bool = False) -> int:
    """
    Handle processing of multiple packages by launching a new terminal window for each (install/download only).
    For a single package, run in the current window.
    """
    import shlex
    total_packages = len(packages)
    failed_packages = []
    if output_path:
        output_path = os.path.abspath(output_path)
        os.makedirs(output_path, exist_ok=True)
    # Single package: run in current window
    if total_packages == 1:
        package = packages[0]
        result, _ = run_winget([command, package])
        if result != 0:
            print(f"Failed to {command} {package}")
            return 1
        # For download, handle output, archive, run logic after download
        if command == 'download':
            download_folder = find_latest_download(package)
            if download_folder:
                if output_path:
                    target_folder = os.path.join(output_path, os.path.basename(download_folder))
                    try:
                        if os.path.exists(target_folder):
                            import shutil
                            shutil.rmtree(target_folder)
                        import shutil
                        shutil.move(download_folder, target_folder)
                        print(f"Installer moved: {target_folder}")
                    except Exception as e:
                        print(f"Error moving installer: {e}")
                        return 1
                else:
                    target_folder = download_folder
                if archive:
                    print(f"Attempting to archive installer: {target_folder}")
                    archive_folder = f"{target_folder}.zip"
                    try:
                        import shutil
                        shutil.make_archive(archive_folder[:-4], 'zip', target_folder)
                        print(f"Archived installer: {archive_folder}")
                        import shutil
                        shutil.rmtree(target_folder)
                    except Exception as e:
                        print(f"Error during archiving or cleanup: {str(e)}")
                        return 1
                if run_installer and not archive:
                    try:
                        for item in os.listdir(target_folder):
                            item_path = os.path.join(target_folder, item)
                            if item.endswith('.exe') or item.endswith('.msi'):
                                subprocess.run([item_path], check=True)
                                break
                        else:
                            print(f"No executable found in {target_folder} to run.")
                    except Exception as e:
                        print(f"Error running installer: {str(e)}")
                        return 1
                # Remove the downloaded folder after running the installer if not archived
                if not archive:
                    try:
                        import shutil
                        shutil.rmtree(target_folder)
                    except Exception as e:
                        print(f"Error removing downloaded folder: {str(e)}")
                        return 1
            else:
                print(f"Download folder not found for {package}")
                return 1
        return 0
    # Multi-package: open new windows
    for idx, package in enumerate(packages, 1):
        print(f"\nLaunching [{idx}/{total_packages}] {package} in new window...")
        if command == "download" and output_path:
            cmdline = f'start cmd /k "winget {command} {shlex.quote(package)} && exit || pause"'
        else:
            cmdline = f'start cmd /k "winget {command} {shlex.quote(package)} && exit || pause"'
        try:
            subprocess.Popen(cmdline, shell=True)
        except Exception as e:
            print(f"Failed to launch window for {package}: {e}")
            failed_packages.append(package)
    if failed_packages:
        print("\nFailed to launch for packages:")
        for package in failed_packages:
            print(f"- {package}")
        return 1
    return 0

def show_help():
    """Show concise help message focusing on extended capabilities."""
    print(f"weget {VERSION} - winget enhancement wrapper")
    print("\nFeatures:")
    print("  • Multi-package install/download operations (each in a new window)")
    print("  • Custom download paths (-o, --output)          | \"weget download\" exclusive")
    print("  • Archive downloaded installers (-a, --archive) | \"weget download\" exclusive")
    print("  • Run installer after download (-r, --run)      | \"weget download\" exclusive")
    print("\nExamples:")
    print("  weget install pkg1 pkg2 pkg3")
    print("  weget download pkg1 -o C:\\path\\to\\dir")
    print("  weget download pkg1 -a")
    print("  weget download pkg1 -r")
    print("\nInfo:")
    print("  To get winget help, type \"weget -h\" or other common help argument.")

def parse_args() -> Tuple[str, List[str], Optional[str], bool, bool]:
    """Parse command line arguments in any order."""
    if len(sys.argv) < 2:
        show_help()
        sys.exit(0)
    args = sys.argv[1:]
    command = args[0]
    output_path = None
    packages = []
    archive_download = False
    run_installer = False
    run_flag_present = False
    archive_flag_present = False
    
    i = 1
    while i < len(args):
        arg = args[i]
        if arg in ['-o', '--output']:
            if i + 1 < len(args):
                output_path = args[i + 1]
                i += 2
            else:
                print("Error: Output path not specified after -o/--output")
                sys.exit(1)
        elif arg in ['-a', '--archive'] and command == 'download':
            archive_download = True
            archive_flag_present = True
            i += 1
        elif arg in ['-r', '--run'] and command == 'download':
            run_installer = True
            run_flag_present = True
            i += 1
        elif arg.startswith('-'):
            print(f"Unknown option: {arg}")
            sys.exit(1)
        else:
            packages.append(arg)
            i += 1
    if archive_flag_present and run_flag_present:
        print("Warning: --run is ignored when --archive is used. Only archiving will be performed.")
        run_installer = False
    return command, packages, output_path, archive_download, run_installer

def main():
    """Main entry point for the application."""
    # Check if winget is available
    is_winget_available, error_message = check_winget()
    if not is_winget_available:
        print(f"Error: {error_message}")
        return 1
    
    command, packages, output_path, archive_download, run_installer = parse_args()
    command = command.lower()
    
    # Check for multi-package commands
    if command in MULTI_PACKAGE_COMMANDS and packages:
        # Only allow output parameter for download command
        if output_path and command != 'download':
            print("Error: Output path can only be specified for the download command")
            return 1
        return handle_multi_package(packages, command, output_path, archive_download, run_installer)
    
    # Pass all arguments directly to winget
    all_args = [command] + packages
    if output_path:
        all_args.extend(['-o', output_path])
    return_code, _ = run_winget(all_args)
    return return_code

# Example usage
if __name__ == "__main__":
    sys.exit(main())

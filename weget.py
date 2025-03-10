import os
import platform
import subprocess
import sys
import shutil
from typing import Tuple, Optional, List
import re

MULTI_PACKAGE_COMMANDS = {
    'install': 'Installing',
    'upgrade': 'Upgrading',
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

def handle_multi_package(packages: List[str], command: str, output_path: Optional[str] = None, archive: bool = False) -> int:
    """
    Handle processing of multiple packages sequentially.
    
    Args:
        packages: List of package IDs to process
        command: The command to use (install/upgrade/download)
        output_path: Optional path for downloaded files
        archive: Boolean indicating whether to archive downloaded files
        
    Returns:
        int: 0 if all operations succeeded, 1 if any failed
    """
    total_packages = len(packages)
    failed_packages = []
    
    # Convert output path to absolute if specified
    if output_path:
        output_path = os.path.abspath(output_path)
        os.makedirs(output_path, exist_ok=True)
    
    for idx, package in enumerate(packages, 1):
        if total_packages > 1:
            print(f"\n[{idx}/{total_packages}] {package}")
        result, _ = run_winget([command, package])
        
        if result != 0:
            failed_packages.append(package)
        elif command == 'download':
            download_folder = find_latest_download(package)
            if download_folder:
                # If output_path is specified, move the folder; otherwise, use the download folder directly
                if output_path:
                    target_folder = os.path.join(output_path, os.path.basename(download_folder))
                    try:
                        if os.path.exists(target_folder):
                            shutil.rmtree(target_folder)
                        shutil.move(download_folder, target_folder)
                        print(f"Installer moved: {target_folder}")
                    except Exception as e:
                        failed_packages.append(package)
                else:
                    target_folder = download_folder
                
                # Archive the folder if the archive option is set
                if archive:
                    print(f"Attempting to archive installer: {target_folder}")  # Winget-style output with folder
                    archive_folder = f"{target_folder}.zip"
                    try:
                        shutil.make_archive(archive_folder[:-4], 'zip', target_folder)
                        print(f"Archived installer: {archive_folder}")  # Winget-style output with archive path
                        # Remove the original folder after successful archiving
                        shutil.rmtree(target_folder)
                    except Exception as e:
                        print(f"Error during archiving or cleanup: {str(e)}")  # Debugging output
                        failed_packages.append(package)
            else:
                failed_packages.append(package)
    
    if failed_packages:
        if len(failed_packages) < total_packages:
            print("\nFailed packages:")
            for package in failed_packages:
                print(f"- {package}")
        return 1
    return 0

def show_help():
    """Show concise help message focusing on extended capabilities."""
    print("weget - winget enhancement wrapper")
    print("\nFeatures:")
    print("  • Multi-package operations")
    print("  • Custom download paths (-o, --output)          | \"weget download\" exclusive")
    print("  • Archive downloaded installers (-a, --archive) | \"weget download\" exclusive")
    print("\nExamples:")
    print("  weget install pkg1 pkg2 pkg3")
    print("  weget download pkg1 -o C:\\path\\to\\dir")
    print("  weget download pkg1 -a")
    print("\nInfo:")
    print("  To get winget help, type \"weget -h\" or other common help argument.")

def parse_args() -> Tuple[str, List[str], Optional[str], bool, bool]:
    """Parse command line arguments in a simple way."""
    if len(sys.argv) < 2:
        show_help()
        sys.exit(0)
        
    args = sys.argv[1:]
    command = args[0]
    output_path = None
    packages = []
    archive_download = False  # New variable to track archive option
    
    # Look for -o/--output and -a/--archive options
    i = 1
    while i < len(args):
        if args[i] in ['-o', '--output']:
            if i + 1 < len(args):
                output_path = args[i + 1]
                i += 2
            else:
                print("Error: Output path not specified after -o/--output")
                sys.exit(1)
        elif args[i] in ['-a', '--archive'] and command == 'download':
            archive_download = True  # New variable to track archive option
            i += 1
        else:
            packages.append(args[i])
            i += 1
            
    return command, packages, output_path, archive_download

def main():
    """Main entry point for the application."""
    # Check if winget is available
    is_winget_available, error_message = check_winget()
    if not is_winget_available:
        print(f"Error: {error_message}")
        return 1
    
    command, packages, output_path, archive_download = parse_args()
    command = command.lower()
    
    # Check for multi-package commands
    if command in MULTI_PACKAGE_COMMANDS and packages:
        # Only allow output parameter for download command
        if output_path and command != 'download':
            print("Error: Output path can only be specified for the download command")
            return 1
        return handle_multi_package(packages, command, output_path, archive_download)
    
    # Pass all arguments directly to winget
    all_args = [command] + packages
    if output_path:
        all_args.extend(['-o', output_path])
    return_code, _ = run_winget(all_args)
    return return_code

# Example usage
if __name__ == "__main__":
    sys.exit(main())

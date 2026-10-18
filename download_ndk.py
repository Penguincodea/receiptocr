import os
import sys
import urllib.request
import zipfile
import shutil

url = "https://dl.google.com/android/repository/android-ndk-r28c-windows.zip"
temp_dir = r"C:\Users\Vietp\AppData\Local\Android\Sdk\.temp"
target_zip = os.path.join(temp_dir, "ndk_download.zip")
ndk_target_dir = r"C:\Users\Vietp\AppData\Local\Android\Sdk\ndk\28.2.13676358"

os.makedirs(temp_dir, exist_ok=True)

# Check if partially downloaded in PackageOperation01
partial_source = os.path.join(temp_dir, "PackageOperation01", "android-ndk-r28c-windows.zip")
existing_bytes = 0

if not os.path.exists(target_zip) and os.path.exists(partial_source):
    try:
        shutil.copy2(partial_source, target_zip)
    except Exception as e:
        print("Copy failed:", e)

if os.path.exists(target_zip):
    existing_bytes = os.path.getsize(target_zip)

print(f"Existing bytes: {existing_bytes}")

req = urllib.request.Request(url)
if existing_bytes > 0:
    req.add_header("Range", f"bytes={existing_bytes}-")

try:
    with urllib.request.urlopen(req, timeout=30) as response:
        content_range = response.headers.get("Content-Range")
        print(f"Response status: {response.status}, Content-Range: {content_range}")
        
        mode = "ab" if existing_bytes > 0 and response.status == 206 else "wb"
        if mode == "wb":
            existing_bytes = 0
            
        with open(target_zip, mode) as out_file:
            downloaded = existing_bytes
            while True:
                chunk = response.read(1024 * 1024) # 1MB chunks
                if not chunk:
                    break
                out_file.write(chunk)
                downloaded += len(chunk)
                mb = downloaded / (1024 * 1024)
                sys.stdout.write(f"\rDownloaded: {mb:.1f} MB / 713.5 MB")
                sys.stdout.flush()
        print("\nDownload complete!")
except Exception as e:
    print(f"\nDownload error: {e}")

print("Verifying zip file...")
if zipfile.is_zipfile(target_zip):
    print("Zip is valid! Extracting to NDK directory...")
    os.makedirs(ndk_target_dir, exist_ok=True)
    with zipfile.ZipFile(target_zip, 'r') as z:
        # NDK archive contains root folder 'android-ndk-r28c'
        # Extract files stripping root folder
        members = z.namelist()
        total_files = len(members)
        print(f"Total files in archive: {total_files}")
        for i, member in enumerate(members):
            parts = member.split('/', 1)
            if len(parts) > 1 and parts[1]:
                rel_path = parts[1]
                target_path = os.path.join(ndk_target_dir, rel_path.replace('/', os.sep))
                if member.endswith('/'):
                    os.makedirs(target_path, exist_ok=True)
                else:
                    os.makedirs(os.path.dirname(target_path), exist_ok=True)
                    with z.open(member) as src, open(target_path, 'wb') as dst:
                        shutil.copyfileobj(src, dst)
            if i % 1000 == 0:
                sys.stdout.write(f"\rExtracted {i}/{total_files} files...")
                sys.stdout.flush()
    print("\nExtraction complete!")
    
    # Check source.properties
    props = os.path.join(ndk_target_dir, "source.properties")
    if os.path.exists(props):
        print("source.properties exists! NDK 28.2.13676358 is successfully installed!")
    else:
        print("Warning: source.properties missing, writing standard properties...")
        with open(props, "w") as f:
            f.write("Pkg.Desc = Android NDK\nPkg.Revision = 28.2.13676358\n")
else:
    print("Zip file is not yet valid or complete.")

#!/usr/bin/env python3
"""
Download REAL images for all 50 learning questions from Unsplash (FREE)
Uses direct Unsplash URLs for high-quality images
"""

import os
import requests
from PIL import Image
from io import BytesIO
import time

# Create output directory
output_dir = "assets/images/questions"
os.makedirs(output_dir, exist_ok=True)

# Direct image URLs from Unsplash (high-quality, already 256x256 compatible)
# These are carefully selected images for each learning question
direct_urls = {
    # Basic Needs (1-10)
    1: "https://images.unsplash.com/photo-1599599810694-b5ac4dd97a88?w=256&h=256&fit=crop",     # Water
    2: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=256&h=256&fit=crop",         # Food
    3: "https://images.unsplash.com/photo-1503454537688-e6694e7fbb33?w=256&h=256&fit=crop",     # Child
    4: "https://images.unsplash.com/photo-1608270861620-7911c6808cbd?w=256&h=256&fit=crop",    # Drink
    5: "https://images.unsplash.com/photo-1587854692152-cbe660dbde0b?w=256&h=256&fit=crop",    # Medicine
    6: "https://images.unsplash.com/photo-1587854692152-cbe660dbde0b?w=256&h=256&fit=crop",    # Tablet
    7: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=256&h=256&fit=crop",    # Sleep
    8: "https://images.unsplash.com/photo-1552521514-5fefe8c9ef14?w=256&h=256&fit=crop",       # Sitting
    9: "https://images.unsplash.com/photo-1550921296-6de341b1f6d5?w=256&h=256&fit=crop",       # Milk
    10: "https://images.unsplash.com/photo-1476124369162-f4978c03a41f?w=256&h=256&fit=crop",   # Soup
    
    # People (11-18)
    11: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=256&h=256&fit=crop",   # Woman
    12: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Man
    13: "https://images.unsplash.com/photo-1519046904884-53103b34b206?w=256&h=256&fit=crop",   # Boy
    14: "https://images.unsplash.com/photo-1516627145497-ae3ddd112e2e?w=256&h=256&fit=crop",   # Girl
    15: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=256&h=256&fit=crop",   # Sister
    16: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Brother
    17: "https://images.unsplash.com/photo-1612349317150-e539c97b5b4c?w=256&h=256&fit=crop",   # Doctor
    18: "https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=256&h=256&fit=crop",   # Nurse
    
    # Actions (19-28)
    19: "https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=256&h=256&fit=crop",   # Walk
    20: "https://images.unsplash.com/photo-1571731956672-f2b94d7dd0cb?w=256&h=256&fit=crop",   # Go
    21: "https://images.unsplash.com/photo-1552674605-5defe6aa44bb?w=256&h=256&fit=crop",      # Come
    22: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=256&h=256&fit=crop",  # Eat
    23: "https://images.unsplash.com/photo-1552664730-d307ca884978?w=256&h=256&fit=crop",     # Help
    24: "https://images.unsplash.com/photo-1516414447565-b14019b07ff6?w=256&h=256&fit=crop",   # Yes (✓)
    25: "https://images.unsplash.com/photo-1527482797697-8795b1a55a45?w=256&h=256&fit=crop",   # No (✗)
    26: "https://images.unsplash.com/photo-1516989713285-b8b934ee8b6f?w=256&h=256&fit=crop",   # Hello
    27: "https://images.unsplash.com/photo-1516062423079-7ca13cdc7f5a?w=256&h=256&fit=crop",   # Thank You
    28: "https://images.unsplash.com/photo-1516312002032-ad2dc740e5a2?w=256&h=256&fit=crop",   # Please
    
    # Body Parts (29-36)
    29: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Head
    30: "https://images.unsplash.com/photo-1505944270255-72b27e84530d?w=256&h=256&fit=crop",   # Hand
    31: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=256&h=256&fit=crop",   # Foot
    32: "https://images.unsplash.com/photo-1516962712202-907c0fbd4509?w=256&h=256&fit=crop",   # Eye
    33: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Mouth
    34: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Nose
    35: "https://images.unsplash.com/photo-1516534775068-bb4aa4aea708?w=256&h=256&fit=crop",   # Thumb
    36: "https://images.unsplash.com/photo-1505944270255-72b27e84530d?w=256&h=256&fit=crop",   # Arm
    
    # Common Objects (37-42)
    37: "https://images.unsplash.com/photo-1516399520895-73e2e2d4ccb2?w=256&h=256&fit=crop",   # Bed
    38: "https://images.unsplash.com/photo-1517701550927-30cf4ba53dba?w=256&h=256&fit=crop",   # Cup
    39: "https://images.unsplash.com/photo-1578500494198-246f612d03b3?w=256&h=256&fit=crop",   # Plate
    40: "https://images.unsplash.com/photo-1507842217343-583f20270319?w=256&h=256&fit=crop",   # Book
    41: "https://images.unsplash.com/photo-1505873242700-f289a29e7e0f?w=256&h=256&fit=crop",   # Door
    42: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=256&h=256&fit=crop",   # Window
    
    # Feelings (43-50)
    43: "https://images.unsplash.com/photo-1516977080531-61e3e78ba63c?w=256&h=256&fit=crop",   # Happy
    44: "https://images.unsplash.com/photo-1516769159737-18ea4ef17fe9?w=256&h=256&fit=crop",   # Sad
    45: "https://images.unsplash.com/photo-1516534775068-bb4aa4aea708?w=256&h=256&fit=crop",   # Pain
    46: "https://images.unsplash.com/photo-1516914943184-28fb64b13914?w=256&h=256&fit=crop",   # Tired
    47: "https://images.unsplash.com/photo-1516986181033-ebc89e0ce5b5?w=256&h=256&fit=crop",   # Angry
    48: "https://images.unsplash.com/photo-1517836357463-d25ddfcbf042?w=256&h=256&fit=crop",   # Cold
    49: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=256&h=256&fit=crop",   # Hot
    50: "https://images.unsplash.com/photo-1516769159737-18ea4ef17fe9?w=256&h=256&fit=crop",   # Scared
}

# Question names for file naming
question_names = {
    1: "water", 2: "food", 3: "child", 4: "drink", 5: "medicine",
    6: "tablet", 7: "sleep", 8: "sitting", 9: "milk", 10: "soup",
    11: "woman", 12: "man", 13: "boy", 14: "girl", 15: "sister",
    16: "brother", 17: "doctor", 18: "nurse",
    19: "walk", 20: "go", 21: "come", 22: "eat", 23: "help",
    24: "yes", 25: "no", 26: "hello", 27: "thankyou", 28: "please",
    29: "head", 30: "hand", 31: "foot", 32: "eye", 33: "mouth",
    34: "nose", 35: "thumb", 36: "arm",
    37: "bed", 38: "cup", 39: "plate", 40: "book", 41: "door", 42: "window",
    43: "happy", 44: "sad", 45: "pain", 46: "tired", 47: "angry",
    48: "cold", 49: "hot", 50: "scared",
}

def download_image(id, url, filename):
    """Download image from URL and save as PNG"""
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        
        # Open image
        img = Image.open(BytesIO(response.content))
        
        # Convert to RGB if necessary
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'RGBA':
                background.paste(img, mask=img.split()[-1])
            else:
                background.paste(img)
            img = background
        else:
            img = img.convert('RGB')
        
        # Resize to 256x256
        img = img.resize((256, 256), Image.Resampling.LANCZOS)
        
        # Save
        filepath = os.path.join(output_dir, filename)
        img.save(filepath, 'PNG', quality=95)
        return True
    except Exception as e:
        print(f"  ✗ Error: {str(e)[:40]}")
        return False

print("=" * 70)
print("  DOWNLOADING REAL IMAGES FOR 50 VISUAL LEARNING QUESTIONS")
print("  From Unsplash (Free, High Quality)")
print("=" * 70)
print(f"\nDownloading to: {output_dir}/\n")

success = 0
failed = 0
skipped = 0

for id in range(1, 51):
    name = question_names.get(id, f"unknown")
    filename = f"{id}_{name}.png"
    url = direct_urls.get(id, "")
    
    print(f"[{id:2d}/50] {filename:30s}", end=" ", flush=True)
    
    # Check if already exists
    filepath = os.path.join(output_dir, filename)
    if os.path.exists(filepath):
        print("✓ (Already exists)")
        skipped += 1
        continue
    
    if url and download_image(id, url, filename):
        print("✓")
        success += 1
    else:
        print("✗")
        failed += 1
    
    time.sleep(0.3)  # Small delay to avoid rate limiting

print("\n" + "=" * 70)
print(f"  ✓ Downloaded: {success:2d}/50")
print(f"  ✓ Already existed: {skipped:2d}/50")
print(f"  ✗ Failed: {failed:2d}/50")
print("=" * 70)
print(f"\nImages saved to: {os.path.abspath(output_dir)}/")
print("\n📱 NEXT STEPS:")
print("  1. Make sure all 50 images downloaded successfully")
print("  2. Run: flutter pub get")
print("  3. Run: flutter run")
print("\n✨ The images will automatically load in your app!")
print("=" * 70)

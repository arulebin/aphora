#!/usr/bin/env python3
"""
Generate PNG images for the 50 visual questions
This script creates placeholder PNG images that can be replaced with real images later
"""

import os
from PIL import Image, ImageDraw, ImageFont

# Create output directory
output_dir = "assets/images/questions"
os.makedirs(output_dir, exist_ok=True)

# Define questions with emoji/colors for placeholder images
questions_data = [
    # Basic Needs (1-10)
    {"id": 1, "name": "water", "emoji": "💧", "color": "#E8F5E9"},
    {"id": 2, "name": "food", "emoji": "🍽️", "color": "#FFF3E0"},
    {"id": 3, "name": "child", "emoji": "👶", "color": "#FCE4EC"},
    {"id": 4, "name": "drink", "emoji": "🥤", "color": "#E3F2FD"},
    {"id": 5, "name": "medicine", "emoji": "💊", "color": "#F3E5F5"},
    {"id": 6, "name": "tablet", "emoji": "⏱️", "color": "#FFF9C4"},
    {"id": 7, "name": "sleep", "emoji": "😴", "color": "#E0F2F1"},
    {"id": 8, "name": "sitting", "emoji": "🪑", "color": "#EFEBE9"},
    {"id": 9, "name": "milk", "emoji": "🥛", "color": "#F1F8E9"},
    {"id": 10, "name": "soup", "emoji": "🍲", "color": "#FFF0F5"},
    # People (11-18)
    {"id": 11, "name": "woman", "emoji": "👩", "color": "#FCE4EC"},
    {"id": 12, "name": "man", "emoji": "👨", "color": "#E8EAF6"},
    {"id": 13, "name": "boy", "emoji": "👦", "color": "#C8E6C9"},
    {"id": 14, "name": "girl", "emoji": "👧", "color": "#FFE0B2"},
    {"id": 15, "name": "sister", "emoji": "👧", "color": "#F0F4C3"},
    {"id": 16, "name": "brother", "emoji": "👦", "color": "#BBDEFB"},
    {"id": 17, "name": "doctor", "emoji": "👨‍⚕️", "color": "#E1BEE7"},
    {"id": 18, "name": "nurse", "emoji": "👩‍⚕️", "color": "#F0F4C3"},
    # Actions (19-28)
    {"id": 19, "name": "walk", "emoji": "🚶", "color": "#FFEBEE"},
    {"id": 20, "name": "go", "emoji": "🏃", "color": "#C8E6C9"},
    {"id": 21, "name": "come", "emoji": "🤸", "color": "#E0F2F1"},
    {"id": 22, "name": "eat", "emoji": "🍴", "color": "#FFF3E0"},
    {"id": 23, "name": "help", "emoji": "🤝", "color": "#E8F5E9"},
    {"id": 24, "name": "yes", "emoji": "✅", "color": "#E8F5E9"},
    {"id": 25, "name": "no", "emoji": "❌", "color": "#FFEBEE"},
    {"id": 26, "name": "hello", "emoji": "👋", "color": "#E3F2FD"},
    {"id": 27, "name": "thankyou", "emoji": "🙏", "color": "#FCE4EC"},
    {"id": 28, "name": "please", "emoji": "🙏", "color": "#F3E5F5"},
    # Body Parts (29-36)
    {"id": 29, "name": "head", "emoji": "🗣️", "color": "#FFCCBC"},
    {"id": 30, "name": "hand", "emoji": "✋", "color": "#FFCCBC"},
    {"id": 31, "name": "foot", "emoji": "🦶", "color": "#FFCCBC"},
    {"id": 32, "name": "eye", "emoji": "👁️", "color": "#FFCCBC"},
    {"id": 33, "name": "mouth", "emoji": "👄", "color": "#FFCCBC"},
    {"id": 34, "name": "nose", "emoji": "👃", "color": "#FFCCBC"},
    {"id": 35, "name": "thumb", "emoji": "👍", "color": "#FFCCBC"},
    {"id": 36, "name": "arm", "emoji": "💪", "color": "#FFCCBC"},
    # Common Objects (37-42)
    {"id": 37, "name": "bed", "emoji": "🛏️", "color": "#E0F2F1"},
    {"id": 38, "name": "cup", "emoji": "☕", "color": "#FFF3E0"},
    {"id": 39, "name": "plate", "emoji": "🍽️", "color": "#E8EAF6"},
    {"id": 40, "name": "book", "emoji": "📖", "color": "#F1F8E9"},
    {"id": 41, "name": "door", "emoji": "🚪", "color": "#EFEBE9"},
    {"id": 42, "name": "window", "emoji": "🪟", "color": "#E0F2F1"},
    # Feelings (43-50)
    {"id": 43, "name": "happy", "emoji": "😊", "color": "#F1F8E9"},
    {"id": 44, "name": "sad", "emoji": "😢", "color": "#FFEBEE"},
    {"id": 45, "name": "pain", "emoji": "😩", "color": "#FCE4EC"},
    {"id": 46, "name": "tired", "emoji": "😴", "color": "#F3E5F5"},
    {"id": 47, "name": "angry", "emoji": "😠", "color": "#FFCDD2"},
    {"id": 48, "name": "cold", "emoji": "🥶", "color": "#E0F2F1"},
    {"id": 49, "name": "hot", "emoji": "🔥", "color": "#FFF3E0"},
    {"id": 50, "name": "scared", "emoji": "😨", "color": "#F8BBD0"},
]

def hex_to_rgb(hex_color):
    """Convert hex color to RGB tuple"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def create_placeholder_image(id, name, emoji, color):
    """Create a placeholder image with emoji"""
    # Create image with background color
    img_size = 256
    img = Image.new('RGB', (img_size, img_size), hex_to_rgb(color))
    draw = ImageDraw.Draw(img)
    
    # Draw emoji
    try:
        # Try to use system font for emoji
        font = ImageFont.load_default()
    except:
        font = None
    
    # Draw emoji at center
    # Using default character since emoji support varies
    bbox = draw.textbbox((0, 0), emoji, font=font)
    emoji_width = bbox[2] - bbox[0]
    emoji_height = bbox[3] - bbox[1]
    x = (img_size - emoji_width) // 2
    y = (img_size - emoji_height) // 2 - 20
    
    draw.text((x, y), emoji, fill=(0, 0, 0), font=font)
    
    # Save image
    filename = f"{id}_{name}.png"
    filepath = os.path.join(output_dir, filename)
    img.save(filepath)
    print(f"✓ Created: {filename}")

# Generate all images
print("Generating placeholder PNG images...")
print(f"Output directory: {output_dir}")
print()

for q in questions_data:
    create_placeholder_image(q["id"], q["name"], q["emoji"], q["color"])

print()
print(f"✓ Successfully generated {len(questions_data)} placeholder images!")
print(f"✓ Images saved to: {output_dir}/")
print()
print("Next steps:")
print("1. Replace these placeholder images with actual images")
print("2. Ensure images are 256x256 PNG files")
print("3. Keep the naming convention: {id}_{name}.png")

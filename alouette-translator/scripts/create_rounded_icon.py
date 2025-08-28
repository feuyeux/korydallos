#!/usr/bin/env python3
"""
Create a rounded corner version of the app icon.
This script takes the original square icon and applies rounded corners
to make it consistent with modern app icon design standards.
"""

import os
import sys
from PIL import Image, ImageDraw
import argparse

def create_rounded_icon(input_path, output_path, radius_ratio=0.2):
    """
    Create a rounded corner version of an icon.
    
    Args:
        input_path (str): Path to the input square icon
        output_path (str): Path to save the rounded icon
        radius_ratio (float): Ratio of corner radius to width (0.0 to 0.5)
    """
    # Open the original image
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # Calculate corner radius (typically 20% of the width for modern app icons)
    radius = int(min(width, height) * radius_ratio)
    
    # Create a mask for rounded corners
    mask = Image.new("L", (width, height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [(0, 0), (width, height)], 
        radius=radius, 
        fill=255
    )
    
    # Create a new image with transparent background
    rounded_img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    
    # Apply the mask to the original image
    img.putalpha(mask)
    
    # Paste the masked image onto the transparent background
    rounded_img.paste(img, (0, 0), img)
    
    # Save the result
    rounded_img.save(output_path, "PNG")
    print(f"Created rounded icon: {output_path}")

def create_ios_adaptive_icon(input_path, output_path):
    """
    Create an iOS-style adaptive icon with proper padding and rounded corners.
    iOS automatically applies corner radius, so we create a version with subtle rounding.
    """
    # iOS icons should have less aggressive rounding since iOS applies its own
    create_rounded_icon(input_path, output_path, radius_ratio=0.15)

def create_android_adaptive_icon(input_path, output_path):
    """
    Create an Android adaptive icon with more pronounced rounded corners.
    Android allows for more customization in icon shape.
    """
    # Android icons can have more pronounced rounding
    create_rounded_icon(input_path, output_path, radius_ratio=0.22)

def main():
    parser = argparse.ArgumentParser(description="Create rounded app icons")
    parser.add_argument("input", help="Input image path")
    parser.add_argument("-o", "--output", help="Output image path", default=None)
    parser.add_argument("-r", "--radius", type=float, default=0.2, 
                       help="Corner radius ratio (0.0-0.5, default: 0.2)")
    parser.add_argument("--ios", action="store_true", 
                       help="Create iOS-optimized rounded icon")
    parser.add_argument("--android", action="store_true", 
                       help="Create Android-optimized rounded icon")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"Error: Input file '{args.input}' not found")
        sys.exit(1)
    
    # Determine output path
    if args.output is None:
        name, ext = os.path.splitext(args.input)
        args.output = f"{name}_rounded{ext}"
    
    try:
        if args.ios:
            create_ios_adaptive_icon(args.input, args.output)
        elif args.android:
            create_android_adaptive_icon(args.input, args.output)
        else:
            create_rounded_icon(args.input, args.output, args.radius)
            
        print("✓ Rounded icon created successfully!")
        
    except Exception as e:
        print(f"Error creating rounded icon: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

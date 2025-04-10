import os
import sys
from PIL import Image
import glob

def format_screenshot(input_path, output_path, target_size="1280x800"):
    """
    Formats a screenshot to meet Chrome Web Store requirements:
    - Exact size: 1280x800 or 640x400
    - 24-bit PNG with no alpha channel
    
    Args:
        input_path: Path to the original screenshot
        output_path: Path to save the formatted screenshot
        target_size: Either "1280x800" or "640x400"
    """
    if target_size == "1280x800":
        width, height = 1280, 800
    elif target_size == "640x400":
        width, height = 640, 400
    else:
        print(f"Invalid target size: {target_size}. Using 1280x800.")
        width, height = 1280, 800
    
    try:
        # Check if input file exists
        if not os.path.exists(input_path):
            print(f"Error: Input file not found: {input_path}")
            return None
            
        # Open the original image
        original = Image.open(input_path)
        
        # Create a new RGB image (no alpha) with white background
        formatted = Image.new("RGB", (width, height), (255, 255, 255))
        
        # Calculate resize dimensions while preserving aspect ratio
        orig_width, orig_height = original.size
        ratio = min(width / orig_width, height / orig_height)
        new_width = int(orig_width * ratio)
        new_height = int(orig_height * ratio)
        
        # Resize the original image
        resized = original.resize((new_width, new_height), Image.LANCZOS)
        
        # Calculate position to center the image
        left = (width - new_width) // 2
        top = (height - new_height) // 2
        
        # Paste the resized image onto the new canvas
        formatted.paste(resized, (left, top))
        
        # Save as PNG with no alpha channel
        formatted.save(output_path, format="PNG")
        print(f"Successfully formatted screenshot: {output_path}")
        
        return output_path
        
    except Exception as e:
        print(f"Error formatting screenshot: {str(e)}")
        return None

def process_directory(input_dir, output_dir, target_size="1280x800"):
    """
    Process all image files in a directory and convert them to Chrome Web Store format.
    
    Args:
        input_dir: Directory containing screenshots to process
        output_dir: Directory to save formatted screenshots
        target_size: Either "1280x800" or "640x400"
    """
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Find all PNG and JPG files in the input directory
    image_files = []
    image_files.extend(glob.glob(os.path.join(input_dir, "*.png")))
    image_files.extend(glob.glob(os.path.join(input_dir, "*.jpg")))
    image_files.extend(glob.glob(os.path.join(input_dir, "*.jpeg")))
    
    if not image_files:
        print(f"No image files found in {input_dir}")
        return
    
    print(f"Found {len(image_files)} image files to process")
    
    # Process each image
    successful = 0
    for image_path in image_files:
        # Create output filename
        base_name = os.path.basename(image_path)
        name, _ = os.path.splitext(base_name)
        output_path = os.path.join(output_dir, f"{name}_{target_size.replace('x', '_')}.png")
        
        # Format the screenshot
        result = format_screenshot(image_path, output_path, target_size)
        if result:
            successful += 1
    
    print(f"Processed {successful} of {len(image_files)} images successfully")
    print(f"Formatted images saved to: {output_dir}")

# Entry point when script is run directly
if __name__ == "__main__":
    # Default values
    input_dir = "."  # Current directory
    output_dir = "./chrome_screenshots"
    size = "1280x800"
    
    # Override with command line arguments if provided
    if len(sys.argv) > 1:
        input_dir = sys.argv[1]
    if len(sys.argv) > 2:
        output_dir = sys.argv[2]
    if len(sys.argv) > 3:
        size = sys.argv[3]
    
    print(f"Processing screenshots in {input_dir}")
    print(f"Saving formatted screenshots to {output_dir}")
    print(f"Target size: {size}")
    
    process_directory(input_dir, output_dir, size) 
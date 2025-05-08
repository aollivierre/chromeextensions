import os
import sys
from PIL import Image

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
        print(f"New size: {width}x{height}")
        
        return output_path
        
    except Exception as e:
        print(f"Error formatting screenshot: {str(e)}")
        return None

# Entry point when script is run directly
if __name__ == "__main__":
    # Default values
    input_path = "Screenshot 2025-04-10 085911.png"
    output_path = "Chrome_Store_Screenshot_1280x800.png"
    size = "1280x800"
    
    # Override with command line arguments if provided
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    if len(sys.argv) > 2:
        output_path = sys.argv[2]
    if len(sys.argv) > 3:
        size = sys.argv[3]
    
    # If output_path is a directory, create output filename
    if os.path.isdir(output_path):
        base_name = os.path.basename(input_path)
        name, _ = os.path.splitext(base_name)
        output_path = os.path.join(output_path, f"{name}_{size}.png")
    
    print(f"Formatting screenshot {input_path} to {size} PNG")
    format_screenshot(input_path, output_path, size) 
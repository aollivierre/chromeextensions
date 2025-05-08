import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_chrome_extension_icon(input_icon_path, output_icon_path):
    """
    Creates a Chrome extension icon (128x128 PNG) with proper padding and DR indicator.
    
    Args:
        input_icon_path: Path to the original icon file
        output_icon_path: Path where the modified icon will be saved
    """
    # Verify input file exists
    if not os.path.exists(input_icon_path):
        print(f"Error: Input file not found: {input_icon_path}")
        print(f"Current directory: {os.getcwd()}")
        print("Please provide the correct path to the input icon file.")
        return None
    
    try:
        # Open the original icon
        original_icon = Image.open(input_icon_path)
        
        # Create a new transparent 128x128 image (Chrome extension requirement)
        chrome_icon = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
        
        # Resize original to 96x96 (the content size required by Chrome)
        icon_content = original_icon.copy()
        icon_content = icon_content.resize((96, 96), Image.LANCZOS)
        
        # Center the 96x96 content on the 128x128 canvas (16px padding on each side)
        chrome_icon.paste(icon_content, (16, 16), icon_content if icon_content.mode == 'RGBA' else None)
        
        # Create an overlay for the DR indicator
        overlay = Image.new('RGBA', (128, 128), (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        
        # Calculate DR indicator size
        indicator_size = 40  # Size of the red square
        
        # Draw a solid red square in the bottom right corner within the content area
        # (not extending into the padding)
        draw.rectangle(
            [(128-16-indicator_size, 128-16-indicator_size), (128-16, 128-16)],
            fill=(255, 0, 0, 255)  # Pure red, fully opaque
        )
        
        # Add "DR" text
        text = "DR"
        font_size = 20  # Adjust size based on testing
        
        try:
            # Try to load Arial Bold font
            font = ImageFont.truetype("arialbd.ttf", font_size)
        except:
            try:
                # Fall back to Arial
                font = ImageFont.truetype("arial.ttf", font_size)
            except:
                # Last resort: default font
                font = ImageFont.load_default()
        
        # Calculate text position
        if hasattr(font, 'getbbox'):
            text_bbox = font.getbbox(text)
            text_width = text_bbox[2] - text_bbox[0]
            text_height = text_bbox[3] - text_bbox[1]
        else:
            # Fallback for older PIL versions
            try:
                text_width, text_height = font.getsize(text)
            except:
                text_width = font_size * 2
                text_height = font_size
        
        # Center text in the red square
        text_x = 128 - 16 - (indicator_size // 2 + text_width // 2)
        text_y = 128 - 16 - (indicator_size // 2 + text_height // 2)
        
        # Draw the white text
        draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
        
        # Add a subtle white glow to the main icon if it's dark
        # This helps it stand out against dark backgrounds
        icon_with_glow = add_subtle_glow(chrome_icon)
        
        # Composite the DR indicator overlay onto the icon
        final_icon = Image.alpha_composite(icon_with_glow, overlay)
        
        # Ensure output directory exists
        output_dir = os.path.dirname(output_icon_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # Save as PNG (required format for Chrome extensions)
        final_icon.save(output_icon_path, format="PNG")
        print(f"Successfully created Chrome extension icon: {output_icon_path}")
        
        return output_icon_path
        
    except Exception as e:
        print(f"Error creating Chrome extension icon: {str(e)}")
        return None

def add_subtle_glow(image):
    """Adds a subtle white outer glow to help the icon stand out against dark backgrounds"""
    # Create a copy of the image to work with
    result = image.copy()
    
    # Create a mask from the alpha channel
    if image.mode == 'RGBA':
        # Get alpha channel
        r, g, b, a = image.split()
        mask = a
        
        # Create a white glow layer
        glow = Image.new('RGBA', image.size, (255, 255, 255, 0))
        glow_draw = ImageDraw.Draw(glow)
        
        # Create white silhouette with reduced alpha for the glow
        silhouette = Image.new('RGBA', image.size, (255, 255, 255, 60))
        
        # Apply the mask to the silhouette
        glow_base = Image.composite(silhouette, glow, mask)
        
        # Blur the glow
        glow_blur = glow_base.filter(ImageFilter.GaussianBlur(2))
        
        # Create a new image to hold the result
        final = Image.new('RGBA', image.size, (0, 0, 0, 0))
        
        # Composite the blurred glow under the original image
        final = Image.alpha_composite(final, glow_blur)
        final = Image.alpha_composite(final, result)
        
        return final
    
    return result

# Entry point when script is run directly
if __name__ == "__main__":
    # Default paths
    input_path = "GenesysCloud_icon.ico"
    output_path = "GenesysCloud_DR_128.png"
    
    # Override with command line arguments if provided
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    if len(sys.argv) > 2:
        output_path = sys.argv[2]
    
    # Convert relative paths to absolute if needed
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # If input_path is not absolute and doesn't exist, try finding it relative to script dir
    if not os.path.isabs(input_path) and not os.path.exists(input_path):
        script_relative_path = os.path.join(script_dir, input_path)
        if os.path.exists(script_relative_path):
            input_path = script_relative_path
    
    # If output_path is not absolute, make it relative to script dir
    if not os.path.isabs(output_path):
        output_path = os.path.join(script_dir, output_path)
    
    print(f"Creating Chrome extension icon from {input_path} and saving to {output_path}")
    create_chrome_extension_icon(input_path, output_path) 
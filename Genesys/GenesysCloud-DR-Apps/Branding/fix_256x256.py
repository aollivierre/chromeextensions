import os
from PIL import Image, ImageDraw, ImageFont

# Load the original icon
original_icon_path = "GenesysCloud_icon.ico"
output_path = "GenesysCloud_DR_256x256.png"

try:
    # Open the icon and resize to 256x256
    original = Image.open(original_icon_path)
    img = original.copy()
    img = img.resize((256, 256), Image.LANCZOS)
    
    # Ensure RGBA mode
    img = img.convert("RGBA")
    
    # Create a completely new overlay
    overlay = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Draw a solid red box in the bottom right
    box_size = 90  # Large box
    draw.rectangle(
        [(256-box_size, 256-box_size), (256, 256)],
        fill=(255, 0, 0, 255)  # Pure red, fully opaque
    )
    
    # Add "DR" text
    text = "DR"
    font_size = 40  # Very large font
    
    try:
        font = ImageFont.truetype("arialbd.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    # Calculate text position
    try:
        text_bbox = font.getbbox(text)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
    except:
        text_width = font_size * 2
        text_height = font_size
    
    # Center text in the red box
    text_x = 256 - (box_size // 2 + text_width // 2)
    text_y = 256 - (box_size // 2 + text_height // 2)
    
    # Draw the text
    draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
    
    # Composite the overlay onto the original
    final_img = Image.alpha_composite(img, overlay)
    
    # Save the result
    final_img.save(output_path)
    print(f"Successfully created 256x256 DR image: {output_path}")
    
    # Also save directly as ICO
    ico_path = "GenesysCloud_DR_256.ico"
    final_img.save(ico_path, format="ICO")
    print(f"Also saved as ICO: {ico_path}")
    
except Exception as e:
    print(f"Error: {str(e)}") 
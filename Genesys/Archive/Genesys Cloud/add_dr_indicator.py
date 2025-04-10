import os
import sys
from PIL import Image, ImageDraw, ImageFont
import io

def add_dr_indicator_to_icon(input_icon_path, output_icon_path):
    """
    Adds a DR indicator to an existing icon file and saves as a new ICO file
    with multiple resolutions preserved.
    
    Args:
        input_icon_path: Path to the original icon file
        output_icon_path: Path where the modified icon will be saved
    """
    # Load the original icon file
    original_icon = Image.open(input_icon_path)
    
    # Get all available sizes from the original icon
    icon_sizes = []
    if hasattr(original_icon, 'ico'):
        # Get sizes from ICO file
        for entry in original_icon.ico.entry:
            icon_sizes.append((entry.width, entry.height))
    else:
        # Just use the current size
        icon_sizes = [(original_icon.width, original_icon.height)]
    
    # Make sure we have common sizes
    standard_sizes = [16, 32, 48, 64, 128, 256]
    for size in standard_sizes:
        if (size, size) not in icon_sizes:
            icon_sizes.append((size, size))
    
    # Sort sizes for processing
    icon_sizes = sorted(list(set(icon_sizes)))
    print(f"Processing sizes: {icon_sizes}")
    
    # Process each size
    modified_images = []
    
    for size in icon_sizes:
        print(f"Processing size: {size}")
        # Resize original to this size if needed
        try:
            if hasattr(original_icon, 'ico'):
                try:
                    # Try to get this specific size from ico
                    original_icon.size = size
                    img = original_icon.copy()
                except:
                    # Resize if not available
                    img = original_icon.copy()
                    img = img.resize(size, Image.LANCZOS)
            else:
                img = original_icon.copy()
                img = img.resize(size, Image.LANCZOS)
            
            # Convert to RGBA to ensure transparency support
            img = img.convert("RGBA")
            
            # Calculate DR indicator size and position
            width, height = size
            
            # Skip very small sizes
            if width < 20:
                modified_images.append(img)
                continue
            
            # Special handling for 256x256 size
            if width == 256 and height == 256:
                # Create a new RGBA image for the overlay
                overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
                overlay_draw = ImageDraw.Draw(overlay)
                
                # Draw a full corner triangle that's 1/3 of the image
                corner_size = width // 3
                
                # Draw a solid red triangle in the bottom-right corner
                points = [
                    (width - corner_size, height),  # Bottom left
                    (width, height - corner_size),  # Top right
                    (width, height),  # Bottom right
                ]
                overlay_draw.polygon(points, fill=(255, 0, 0, 255))  # Fully opaque red
                
                # Add large "DR" text
                text = "DR"
                font_size = height // 8  # Large text for 256x256
                
                try:
                    font = ImageFont.truetype("arialbd.ttf", int(font_size))
                except:
                    try:
                        font = ImageFont.truetype("arial.ttf", int(font_size))
                    except:
                        font = ImageFont.load_default()
                
                # Position text in center of red corner
                text_bbox = font.getbbox(text) if hasattr(font, 'getbbox') else (0, 0, font_size * 2, font_size)
                text_width = text_bbox[2] - text_bbox[0] if hasattr(font, 'getbbox') else font_size * 2
                text_height = text_bbox[3] - text_bbox[1] if hasattr(font, 'getbbox') else font_size
                
                # Center in bottom-right corner
                text_x = width - (corner_size // 2 + text_width // 2)
                text_y = height - (corner_size // 2 + text_height // 2)
                
                # Draw white text
                overlay_draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
                
                # Composite the overlay onto original image
                img = Image.alpha_composite(img, overlay)
                
            else:
                # REGULAR APPROACH FOR OTHER SIZES
                
                # Create a new RGBA image for the overlay
                overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
                overlay_draw = ImageDraw.Draw(overlay)
                
                # Draw a diagonal banner across the bottom-right corner
                banner_width = width
                banner_height = height // 2
                
                # Define the banner polygon (diagonal ribbon)
                points = [
                    (width - banner_width, height),  # Bottom left
                    (width, height - banner_height),  # Top right
                    (width, height),  # Bottom right
                ]
                
                # Draw the diagonal banner in bright red
                overlay_draw.polygon(points, fill=(255, 0, 0, 240))
                
                # Add "DR" text
                text = "DR"
                try:
                    font_size = max(height // 3, 12)  # Much larger font
                    try:
                        font = ImageFont.truetype("arialbd.ttf", int(font_size))
                    except:
                        try:
                            font = ImageFont.truetype("arial.ttf", int(font_size))
                        except:
                            font = ImageFont.load_default()
                            font_size = max(height // 6, 8)
                except:
                    font = ImageFont.load_default()
                    font_size = max(height // 6, 8)
                
                # Calculate text position - center in bottom-right quadrant
                if hasattr(overlay_draw, 'textlength'):
                    text_width = overlay_draw.textlength(text, font=font)
                    text_height = font_size
                else:
                    try:
                        text_bbox = font.getbbox(text)
                        text_width = text_bbox[2] - text_bbox[0]
                        text_height = text_bbox[3] - text_bbox[1]
                    except:
                        text_width, text_height = font.getsize(text)
                
                # Position text on diagonal banner
                text_x = width - (text_width + banner_width // 8)
                text_y = height - (text_height + banner_height // 3)
                
                # Draw white text on the red banner
                overlay_draw.text((text_x, text_y), text, fill=(255, 255, 255, 255), font=font)
                
                # Composite the overlay onto original image
                img = Image.alpha_composite(img, overlay)
            
            # Convert back to RGB if needed
            if img.mode == 'RGBA':
                # Create a white background
                background = Image.new('RGBA', img.size, (255, 255, 255, 255))
                # Paste using alpha channel as mask
                background.paste(img, (0, 0), img)
                img = background.convert('RGB')
            
            # Debug output for larger sizes
            if width >= 64:
                debug_path = f"debug_size_{width}x{height}.png"
                img.save(debug_path)
                print(f"Saved debug image: {debug_path}")
            
            # Add to our collection
            modified_images.append(img)
            
        except Exception as e:
            print(f"Error processing size {size}: {str(e)}")
            # Just add a copy of the original for this size
            try:
                img = original_icon.copy()
                img = img.resize(size, Image.LANCZOS)
                modified_images.append(img)
            except:
                print(f"Could not fallback for size {size}")
    
    try:
        # Save as multi-size ICO file
        print(f"Saving {len(modified_images)} images")
        modified_images[0].save(
            output_icon_path,
            format="ICO",
            sizes=[(img.width, img.height) for img in modified_images],
            append_images=modified_images[1:]
        )
        print(f"Successfully created DR version at {output_icon_path}")
    except Exception as e:
        print(f"Error saving ICO file: {str(e)}")
        
        # Fallback to save at least one size as ICO
        try:
            largest_img = max(modified_images, key=lambda img: img.width * img.height)
            largest_img.save(output_icon_path, format="ICO")
            print(f"Saved fallback single-size ICO at {output_icon_path}")
        except Exception as e2:
            print(f"Even fallback failed: {str(e2)}")
            
            # Last resort: save as PNG
            png_path = output_icon_path.replace(".ico", ".png")
            largest_img.save(png_path)
            print(f"Saved as PNG instead: {png_path}")
    
    return output_icon_path

# Entry point when script is run directly
if __name__ == "__main__":
    # Default paths
    input_path = "GenesysCloud_icon.ico"
    output_path = "GenesysCloud_DR_icon.ico"
    
    # Override with command line arguments if provided
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    if len(sys.argv) > 2:
        output_path = sys.argv[2]
    
    print(f"Adding DR overlay to {input_path} and saving to {output_path}")
    add_dr_indicator_to_icon(input_path, output_path) 
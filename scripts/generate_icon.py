import os
import struct
import io
from PIL import Image, ImageDraw, ImageFilter

def create_icon():
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))

    margin = 84
    corner_radius = 210
    
    # Shadow
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sdraw.rounded_rectangle(
        [margin, margin + 20, size - margin, size - margin + 20],
        radius=corner_radius,
        fill=(0, 0, 0, 90)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    img.alpha_composite(shadow)

    # Rounded rectangle mask
    mask = Image.new('L', (size, size), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=255
    )

    # Gradient fill
    grad = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    gdraw = ImageDraw.Draw(grad)
    for y in range(size):
        ratio = y / size
        r = int(11 + ratio * (28 - 11))
        g = int(15 + ratio * (19 - 15))
        b = int(25 + ratio * (55 - 25))
        gdraw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    bg_surface = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg_surface.paste(grad, (0, 0), mask)
    img.alpha_composite(bg_surface)

    # Border glow
    border_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bord_draw = ImageDraw.Draw(border_img)
    bord_draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        outline=(99, 102, 241, 100),
        width=4
    )
    img.alpha_composite(border_img)

    # Overlay network nodes
    overlay = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)

    cx, cy = size // 2, size // 2 - 10

    nodes = [
        (cx, cy, 38, (255, 255, 255, 255)),
        (cx - 210, cy - 140, 24, (56, 189, 248, 240)),
        (cx + 210, cy - 140, 24, (168, 85, 247, 240)),
        (cx - 240, cy + 90, 22, (52, 211, 153, 240)),
        (cx + 240, cy + 90, 22, (251, 146, 60, 240)),
        (cx, cy - 230, 26, (96, 165, 250, 240)),
        (cx, cy + 220, 26, (236, 72, 153, 240)),
    ]

    lines = [
        (nodes[0], nodes[1]),
        (nodes[0], nodes[2]),
        (nodes[0], nodes[3]),
        (nodes[0], nodes[4]),
        (nodes[0], nodes[5]),
        (nodes[0], nodes[6]),
        (nodes[1], nodes[5]),
        (nodes[2], nodes[5]),
        (nodes[3], nodes[6]),
        (nodes[4], nodes[6]),
    ]

    line_glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    lg_draw = ImageDraw.Draw(line_glow)
    for (n1, n2) in lines:
        lg_draw.line([(n1[0], n1[1]), (n2[0], n2[1])], fill=(99, 102, 241, 120), width=16)
    line_glow = line_glow.filter(ImageFilter.GaussianBlur(14))
    overlay.alpha_composite(line_glow)

    for (n1, n2) in lines:
        odraw.line([(n1[0], n1[1]), (n2[0], n2[1])], fill=(224, 231, 255, 200), width=6)

    node_glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ng_draw = ImageDraw.Draw(node_glow)
    for (x, y, r, color) in nodes:
        ng_draw.ellipse([x - r * 2.2, y - r * 2.2, x + r * 2.2, y + r * 2.2], fill=(color[0], color[1], color[2], 120))
    node_glow = node_glow.filter(ImageFilter.GaussianBlur(16))
    overlay.alpha_composite(node_glow)

    for (x, y, r, color) in nodes:
        odraw.ellipse([x - r - 6, y - r - 6, x + r + 6, y + r + 6], outline=(color[0], color[1], color[2], 180), width=3)
        odraw.ellipse([x - r, y - r, x + r, y + r], fill=color)

    odraw.ellipse([cx - 75, cy - 75, cx + 75, cy + 75], outline=(129, 140, 248, 180), width=5)

    img.alpha_composite(overlay)
    
    os.makedirs('resources', exist_ok=True)
    png_path = 'resources/icon.png'
    img.save(png_path, 'PNG')
    print(f"Generated {png_path}")

    # Generate ICNS
    entries = [
        (b'ic07', 128),
        (b'ic08', 256),
        (b'ic09', 512),
        (b'ic10', 1024),
        (b'ic11', 32),
        (b'ic12', 64),
        (b'ic13', 256),
        (b'ic14', 512),
    ]
    
    chunks = []
    total_data_size = 8
    
    for tag, sz in entries:
        resized = img.resize((sz, sz), Image.Resampling.LANCZOS)
        buf = io.BytesIO()
        resized.save(buf, format='PNG')
        png_data = buf.getvalue()
        chunk_len = len(png_data) + 8
        chunks.append((tag, chunk_len, png_data))
        total_data_size += chunk_len
        
    icns_path = 'resources/AppIcon.icns'
    with open(icns_path, 'wb') as f:
        f.write(b'icns')
        f.write(struct.pack('>I', total_data_size))
        for tag, chunk_len, png_data in chunks:
            f.write(tag)
            f.write(struct.pack('>I', chunk_len))
            f.write(png_data)
    print(f"Generated {icns_path} ({total_data_size} bytes)")

if __name__ == '__main__':
    create_icon()

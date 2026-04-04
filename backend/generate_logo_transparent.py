"""Gera o logo MicroLaudo com fundo transparente."""
from PIL import Image, ImageDraw

def make_logo(size):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))  # fundo transparente
    draw = ImageDraw.Draw(img)

    color = '#1a5f8a'
    white = '#FFFFFF'

    # Rounded rectangle background
    margin = int(size * 0.08)
    radius = int(size * 0.22)
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=color,
    )

    # Microscópio — base
    cx = size // 2
    base_y = int(size * 0.80)
    base_w = int(size * 0.32)
    base_h = int(size * 0.07)
    draw.rounded_rectangle(
        [cx - base_w, base_y, cx + base_w, base_y + base_h],
        radius=int(base_h * 0.4),
        fill=white,
    )

    # Coluna vertical
    col_w = int(size * 0.07)
    col_top = int(size * 0.48)
    draw.rounded_rectangle(
        [cx - col_w, col_top, cx + col_w, base_y],
        radius=int(col_w * 0.5),
        fill=white,
    )

    # Braço horizontal
    arm_y = int(size * 0.50)
    arm_h = int(size * 0.065)
    arm_right = int(size * 0.68)
    draw.rounded_rectangle(
        [cx, arm_y - arm_h // 2, arm_right, arm_y + arm_h // 2],
        radius=int(arm_h * 0.4),
        fill=white,
    )

    # Tubo ocular (cilindro inclinado simplificado)
    tube_w = int(size * 0.09)
    tube_top = int(size * 0.18)
    tube_bot = int(size * 0.50)
    draw.rounded_rectangle(
        [arm_right - tube_w // 2, tube_top, arm_right + tube_w // 2, tube_bot],
        radius=int(tube_w * 0.5),
        fill=white,
    )

    # Lente (círculo no topo do tubo)
    lens_r = int(size * 0.08)
    draw.ellipse(
        [arm_right - lens_r, tube_top - lens_r,
         arm_right + lens_r, tube_top + lens_r],
        fill=white,
    )

    return img

for size in [512, 1024]:
    logo = make_logo(size)
    logo.save(f'logo_{size}.png')
    print(f'Criado: logo_{size}.png')

print('Logo gerado com sucesso!')

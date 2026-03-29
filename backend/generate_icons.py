"""Gera os ícones PNG necessários para a PWA."""
from PIL import Image, ImageDraw, ImageFont

def make_icon(size):
    img = Image.new('RGB', (size, size), '#1a5f8a')
    draw = ImageDraw.Draw(img)

    # Círculo externo (borda)
    margin = size * 0.08
    draw.ellipse([margin, margin, size - margin, size - margin],
                 outline='#e8f4f8', width=max(2, size // 32))

    # Círculo interno
    inner = size * 0.28
    draw.ellipse([inner, inner, size - inner, size - inner],
                 outline='#e8f4f8', width=max(2, size // 32))

    # Ponto central
    center = size // 2
    r = size * 0.08
    draw.ellipse([center - r, center - r, center + r, center + r], fill='#e8f4f8')

    # Linhas (cruz)
    lw = max(1, size // 64)
    draw.line([(center, int(size * 0.04)), (center, int(size * 0.25))], fill='#e8f4f8', width=lw)
    draw.line([(center, int(size * 0.75)), (center, int(size * 0.96))], fill='#e8f4f8', width=lw)
    draw.line([(int(size * 0.04), center), (int(size * 0.25), center)], fill='#e8f4f8', width=lw)
    draw.line([(int(size * 0.75), center), (int(size * 0.96), center)], fill='#e8f4f8', width=lw)

    return img

for size in [192, 512]:
    icon = make_icon(size)
    icon.save(f'static/icon-{size}.png')
    print(f'Criado: static/icon-{size}.png')

print('Ícones gerados com sucesso!')

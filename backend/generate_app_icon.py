"""Usa o icon PWA existente como base para o app icon."""
from PIL import Image
import os

os.makedirs('../app/assets/icon', exist_ok=True)

# Usa o icon PWA que já está aprovado
src = Image.open('static/icon-192.png').convert('RGBA')

# Redimensiona para 1024x1024 (tamanho padrão para app icons)
icon = src.resize((1024, 1024), Image.LANCZOS)
icon.save('../app/assets/icon/icon.png')
print('Criado: icon.png')

# Foreground para adaptive icon Android — adiciona margem de 25%
size = 1024
margin = int(size * 0.15)
inner_size = size - 2 * margin
fg_base = src.resize((inner_size, inner_size), Image.LANCZOS)
fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
fg.paste(fg_base, (margin, margin), fg_base)
fg.save('../app/assets/icon/icon_foreground.png')
print('Criado: icon_foreground.png')

print('Feito!')

import uuid
import io
from pathlib import Path
from datetime import datetime
from typing import Optional, List

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from PIL import Image as PILImage, ImageDraw

from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Image as RLImage,
    Table, TableStyle, Spacer, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT

app = FastAPI(title="Sistema de Laudos - Relatório de Microscopia")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOADS_DIR = Path("uploads")
UPLOADS_DIR.mkdir(exist_ok=True)

app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
async def root():
    return FileResponse("static/index.html")


@app.get("/images/{image_id}")
async def get_image(image_id: str):
    filepath = UPLOADS_DIR / image_id
    if not filepath.exists():
        raise HTTPException(404, "Imagem não encontrada")
    suffix = filepath.suffix.lower()
    media_map = {".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}
    return FileResponse(str(filepath), media_type=media_map.get(suffix, "image/jpeg"))


@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(400, "Apenas imagens são aceitas")
    ext = Path(file.filename).suffix.lower() or ".jpg"
    if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
        raise HTTPException(400, "Formato inválido. Use JPG ou PNG.")
    filename = f"{uuid.uuid4()}{ext}"
    filepath = UPLOADS_DIR / filename
    content = await file.read()
    if len(content) > 20 * 1024 * 1024:
        raise HTTPException(400, "Imagem muito grande (máx 20MB)")
    filepath.write_bytes(content)
    return {"image_id": filename, "filename": file.filename, "size": len(content)}



class LaudoData(BaseModel):
    paciente: str
    data_nascimento: str
    data_coleta: str
    solicitante: str
    image_ids: List[str]
    nugent_a_qty: str
    nugent_a_pts: int
    nugent_b_qty: str
    nugent_b_pts: int
    nugent_c_qty: str
    nugent_c_pts: int
    nugent_total: int
    nugent_interpretacao: str
    amsel_corrimento: bool
    amsel_ph: bool
    amsel_ph_valor: Optional[str] = None
    amsel_whiff: bool
    amsel_clue_cells: bool
    polimorfonucleares: str
    elementos_fungicos: str
    descricao: str
    flora_tipo: str
    conclusao: str
    observacoes: Optional[str] = None
    examinador: Optional[str] = None
    crm: Optional[str] = None
    data_avaliacao: Optional[str] = None
    circular_crop: bool = False


def make_square_crop(filepath: Path) -> io.BytesIO:
    import math
    from PIL import ImageFilter

    with PILImage.open(filepath) as img:
        img = img.convert('RGB')
        w, h = img.size
        cx, cy = w // 2, h // 2

        # Reduz para 300px e aplica blur forte antes de detectar.
        # Isso elimina o ruído de células escuras — só o anel da moldura sobrevive.
        detect_size = 300
        scale = detect_size / min(w, h)
        sw, sh = int(w * scale), int(h * scale)
        scx, scy = sw // 2, sh // 2

        small = img.convert('L').resize((sw, sh), PILImage.LANCZOS)
        small = small.filter(ImageFilter.GaussianBlur(radius=6))
        spx = small.load()

        threshold = 85
        start_r = detect_size // 10
        detected = []

        for i in range(16):
            angle = (2 * math.pi * i) / 16
            dx, dy = math.cos(angle), math.sin(angle)
            r = float(start_r)
            while r < detect_size * 0.85:
                nx, ny = int(scx + dx * r), int(scy + dy * r)
                if nx < 0 or nx >= sw or ny < 0 or ny >= sh:
                    break
                if spx[nx, ny] < threshold:
                    detected.append(int(r / scale))   # converte de volta para pixels originais
                    break
                r += 1.0

        if len(detected) >= 6:
            detected.sort()
            radius = detected[len(detected) // 2]
        else:
            radius = int(min(w, h) * 0.40)

        radius = min(radius, cx, cy, w - cx, h - cy)

        crop = img.crop((cx - radius, cy - radius, cx + radius, cy + radius))

        buf = io.BytesIO()
        crop.save(buf, format='PNG')
        buf.seek(0)
        return buf


@app.post("/generate-pdf")
async def generate_pdf(data: LaudoData):
    buffer = io.BytesIO()
    CETRUS_BLUE = colors.HexColor('#1a5f8a')
    CETRUS_LIGHT = colors.HexColor('#e8f4f8')
    CETRUS_MID = colors.HexColor('#f0f7ff')

    doc = SimpleDocTemplate(
        buffer, pagesize=A4,
        rightMargin=2*cm, leftMargin=2*cm,
        topMargin=1.5*cm, bottomMargin=2*cm
    )

    def style(name, **kwargs):
        base = ParagraphStyle(name, fontName='Helvetica', fontSize=10, leading=14, spaceAfter=3)
        for k, v in kwargs.items():
            setattr(base, k, v)
        return base

    title_s = style('T', fontSize=13, fontName='Helvetica-Bold', alignment=TA_CENTER, spaceAfter=8)
    label_s = style('L', fontSize=10, fontName='Helvetica-Bold', textColor=CETRUS_BLUE, spaceAfter=4)
    normal_s = style('N', fontSize=9, leading=13)
    small_s = style('S', fontSize=7, fontName='Helvetica-Oblique', textColor=colors.grey, spaceAfter=2)
    bold_s = style('B', fontSize=9, fontName='Helvetica-Bold')
    def b(t): return f"<b>{t}</b>"
    def yn(v): return "Positivo" if v else "Negativo"

    story = []

    # Title
    story.append(Paragraph("RELATÓRIO DE MICROSCOPIA - CONTEÚDO VAGINAL", title_s))
    story.append(HRFlowable(width="100%", thickness=2, color=CETRUS_BLUE))
    story.append(Spacer(1, 0.4*cm))

    # Patient data
    pt_data = [
        [Paragraph(f"{b('Paciente:')} {data.paciente}", normal_s),
         Paragraph(f"{b('Data de nascimento:')} {data.data_nascimento}", normal_s)],
        [Paragraph(f"{b('Data da coleta:')} {data.data_coleta}", normal_s),
         Paragraph(f"{b('Solicitante:')} {data.solicitante}", normal_s)],
        [Paragraph(f"{b('Material:')} Secreção vaginal", normal_s),
         Paragraph(f"{b('Método:')} Microscopia óptica (a fresco e coloração de Gram)", normal_s)],
    ]
    pt = Table(pt_data, colWidths=[8.5*cm, 8.5*cm])
    pt.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(pt)
    story.append(Spacer(1, 0.4*cm))

    # Images
    story.append(Paragraph("Achados microscópicos:", label_s))
    img_cells = []
    for img_id in data.image_ids[:3]:
        fp = UPLOADS_DIR / img_id
        if fp.exists():
            try:
                if data.circular_crop:
                    circ_buf = make_square_crop(fp)
                    img_size = 4.2*cm
                    img = RLImage(circ_buf, width=img_size, height=img_size)
                else:
                    with PILImage.open(fp) as pil_img:
                        w, h = pil_img.size
                    max_w, max_h = 4.8*cm, 3.8*cm
                    ratio = min(max_w/w, max_h/h)
                    img = RLImage(str(fp), width=w*ratio, height=h*ratio)
                img_cells.append(img)
            except Exception:
                img_cells.append(Paragraph("", normal_s))
    while len(img_cells) < 3:
        img_cells.append(Paragraph("", normal_s))
    img_table = Table([img_cells], colWidths=[5.5*cm, 5.5*cm, 5.5*cm])
    img_table.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('TOPPADDING', (0,0), (-1,-1), 3),
        ('BOTTOMPADDING', (0,0), (-1,-1), 3),
    ]))
    story.append(img_table)
    story.append(Spacer(1, 0.4*cm))

    # Description
    story.append(Paragraph("Descrição dos achados microscópicos:", label_s))
    story.append(Paragraph(data.descricao, normal_s))
    story.append(Spacer(1, 0.3*cm))

    # Nugent
    story.append(Paragraph("Escore de Nugent:", label_s))
    nug_data = [
        ['Morfotipo', 'Descrição', 'Achado', 'Pontos'],
        ['A', 'Lactobacillus (bastonetes gram-positivos)', data.nugent_a_qty, str(data.nugent_a_pts)],
        ['B', 'Gardnerella/Prevotella (cocobacilos gram-variáveis)', data.nugent_b_qty, str(data.nugent_b_pts)],
        ['C', 'Mobiluncus (bastonetes curvos)', data.nugent_c_qty, str(data.nugent_c_pts)],
        ['', f'TOTAL - {data.nugent_interpretacao}', '', str(data.nugent_total) + '/10'],
    ]
    col_ws = [1.2*cm, 8.5*cm, 3.5*cm, 2*cm]
    nt = Table(nug_data, colWidths=col_ws)
    nt.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), CETRUS_BLUE),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-2), 0.5, colors.HexColor('#cccccc')),
        ('ROWBACKGROUNDS', (0,1), (-1,-2), [colors.white, CETRUS_MID]),
        ('BACKGROUND', (0,-1), (-1,-1), CETRUS_LIGHT),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('ALIGN', (1,0), (1,-1), 'LEFT'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(nt)
    story.append(Spacer(1, 0.4*cm))

    # Amsel
    story.append(Paragraph("Critérios de Amsel:", label_s))
    pos = sum([data.amsel_corrimento, data.amsel_ph, data.amsel_whiff, data.amsel_clue_cells])
    ph_label = "2. pH vaginal > 4,5"
    if data.amsel_ph_valor:
        ph_label += f" (valor: {data.amsel_ph_valor})"
    amsel_status = "Compativel com Vaginose Bacteriana" if pos >= 3 else "Insuficiente para Vaginose Bacteriana"
    amsel_data = [
        ['Critério', 'Resultado'],
        ['1. Corrimento homogeneo branco-acinzentado', yn(data.amsel_corrimento)],
        [ph_label, yn(data.amsel_ph)],
        ['3. Teste das aminas positivo (Whiff test)', yn(data.amsel_whiff)],
        ['4. Clue cells >= 20% das celulas epiteliais', yn(data.amsel_clue_cells)],
        [f'Total: {pos}/4 criterios positivos  ->  {amsel_status}', ''],
    ]
    at = Table(amsel_data, colWidths=[13*cm, 4*cm])
    at.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), CETRUS_BLUE),
        ('TEXTCOLOR', (0,0), (-1,0), colors.white),
        ('FONTNAME', (0,0), (-1,0), 'Helvetica-Bold'),
        ('FONTNAME', (0,-1), (-1,-1), 'Helvetica-Bold'),
        ('FONTSIZE', (0,0), (-1,-1), 8),
        ('GRID', (0,0), (-1,-2), 0.5, colors.HexColor('#cccccc')),
        ('ROWBACKGROUNDS', (0,1), (-1,-2), [colors.white, CETRUS_MID]),
        ('BACKGROUND', (0,-1), (-1,-1), CETRUS_LIGHT),
        ('SPAN', (0,-1), (-1,-1)),
        ('ALIGN', (1,1), (1,-2), 'CENTER'),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('LEFTPADDING', (0,0), (-1,-1), 5),
    ]))
    story.append(at)
    story.append(Spacer(1, 0.4*cm))

    # Conclusion
    story.append(Paragraph("Conclusão:", label_s))
    story.append(Paragraph(data.conclusao, normal_s))
    if data.observacoes:
        story.append(Spacer(1, 0.2*cm))
        story.append(Paragraph(f"<i>Observações: {data.observacoes}</i>", normal_s))
    story.append(Spacer(1, 0.6*cm))

    # References
    story.append(Paragraph("<b><i>Referências bibliográficas:</i></b>", small_s))
    story.append(Paragraph(
        "Nugent, R. P., Krohn, M. A., & Hillier, S. L. (1991). Reliability of diagnosing bacterial vaginosis is improved by a standardized method of Gram stain interpretation. <i>Journal of Clinical Microbiology, 29</i>(2), 297-301.",
        small_s))
    story.append(Paragraph(
        "Amsel, R., et al. (1983). Nonspecific vaginitis: Diagnostic criteria and microbial and epidemiologic associations. <i>The American Journal of Medicine, 74</i>(1), 14-22.",
        small_s))
    story.append(Spacer(1, 0.8*cm))

    # Signature
    data_aval = data.data_avaliacao or datetime.now().strftime("%d/%m/%Y")
    sig_s8 = style('Sig', fontSize=8)
    sig_s9b = style('Sig9', fontSize=9, fontName='Helvetica-Bold')
    sig_data = [
        [Paragraph("_" * 42, normal_s), Paragraph("_" * 22, normal_s)],
        [Paragraph("Nome e assinatura do examinador", sig_s8), Paragraph("Data da avaliação", sig_s8)],
        [Paragraph(data.examinador or "", sig_s9b), Paragraph(data_aval, sig_s9b)],
        [Paragraph(f"CRM e RQE: {data.crm or ''}", sig_s8), Paragraph("", sig_s8)],
    ]
    st = Table(sig_data, colWidths=[12*cm, 5*cm])
    st.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('TOPPADDING', (0,0), (-1,-1), 2),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2),
    ]))
    story.append(st)

    doc.build(story)
    buffer.seek(0)

    nome = (data.paciente or "paciente").replace(" ", "_")
    data_str = (data.data_coleta or "").replace("/", "")
    filename = f"laudo_{nome}_{data_str}.pdf"

    return Response(
        content=buffer.read(),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)

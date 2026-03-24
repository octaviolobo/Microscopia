/* ============================================================
   MICROSCOPIA VAGINAL — SISTEMA DE LAUDOS
   app.js — Lógica principal da interface
   ============================================================ */

'use strict';

// ----------------------------------------------------------------
// State
// ----------------------------------------------------------------
const state = {
  images: []   // [{image_id, filename, url}]
};

// ----------------------------------------------------------------
// Init
// ----------------------------------------------------------------
function initApp() {
  // Default dates
  const today = fmtDate(new Date());
  document.getElementById('dataColeta').value = today;
  document.getElementById('dataAvaliacao').value = today;

  // Auto-format date inputs
  ['dataNascimento', 'dataColeta', 'dataAvaliacao'].forEach(id => {
    const el = document.getElementById(id);
    el.addEventListener('input', () => autoFormatDate(el));
  });

  updateNugentScore();
  updateAmselCount();
}

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------
function fmtDate(d) {
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  return `${dd}/${mm}/${d.getFullYear()}`;
}

function autoFormatDate(input) {
  let v = input.value.replace(/\D/g, '');
  if (v.length > 2) v = v.slice(0, 2) + '/' + v.slice(2);
  if (v.length > 5) v = v.slice(0, 5) + '/' + v.slice(5);
  input.value = v.slice(0, 10);
}

function getVal(id) {
  return (document.getElementById(id)?.value || '').trim();
}

function setVal(id, val) {
  const el = document.getElementById(id);
  if (el) el.value = val ?? '';
}

function setChecked(id, val) {
  const el = document.getElementById(id);
  if (el) el.checked = !!val;
}

function setSelectVal(id, val) {
  const el = document.getElementById(id);
  if (!el) return;
  const opts = Array.from(el.options).map(o => o.value.toLowerCase());
  const target = (val || '').toLowerCase();
  const idx = opts.findIndex(o => o === target);
  if (idx >= 0) el.selectedIndex = idx;
}

// ----------------------------------------------------------------
// File Upload — Drag & Drop
// ----------------------------------------------------------------
function handleDragOver(e) {
  e.preventDefault();
  e.stopPropagation();
  document.getElementById('dropZone').classList.add('drag-over');
}

function handleDragLeave(e) {
  e.preventDefault();
  document.getElementById('dropZone').classList.remove('drag-over');
}

function handleDrop(e) {
  e.preventDefault();
  e.stopPropagation();
  document.getElementById('dropZone').classList.remove('drag-over');
  const files = Array.from(e.dataTransfer.files).filter(f => f.type.startsWith('image/'));
  processFiles(files);
}

function handleFileSelect(e) {
  const files = Array.from(e.target.files);
  processFiles(files);
  e.target.value = '';
}

function processFiles(files) {
  const remaining = 3 - state.images.length;
  if (remaining <= 0) {
    showToast('Máximo de 3 imagens atingido. Remova uma para adicionar outra.', 'warn');
    return;
  }
  files.slice(0, remaining).forEach(file => uploadFile(file));
}

async function uploadFile(file) {
  if (state.images.length >= 3) return;

  // Immediate preview with placeholder
  const tempId = 'temp_' + Date.now() + '_' + Math.random();
  const objectUrl = URL.createObjectURL(file);

  state.images.push({ image_id: null, filename: file.name, url: objectUrl, tempId, uploading: true });
  renderPreviews();

  const formData = new FormData();
  formData.append('file', file);

  try {
    const res = await fetch('/upload', { method: 'POST', body: formData });
    const data = await res.json();
    if (!res.ok) throw new Error(data.detail || 'Erro no upload');

    // Replace temp with real image_id
    const idx = state.images.findIndex(img => img.tempId === tempId);
    if (idx >= 0) {
      state.images[idx] = {
        image_id: data.image_id,
        filename: data.filename,
        url: `/images/${data.image_id}`,
        uploading: false
      };
    }
    renderPreviews();
    showToast(`Imagem "${file.name}" carregada com sucesso.`, 'success');
  } catch (err) {
    // Remove failed upload
    const idx = state.images.findIndex(img => img.tempId === tempId);
    if (idx >= 0) state.images.splice(idx, 1);
    renderPreviews();
    showToast(`Falha ao enviar "${file.name}": ${err.message}`, 'error');
  }
}

function removeImage(index) {
  state.images.splice(index, 1);
  renderPreviews();
}

function renderPreviews() {
  const strip = document.getElementById('previewStrip');
  const list = document.getElementById('previewList');
  const countEl = document.getElementById('imageCount');

  countEl.textContent = `${state.images.length}/3`;
  list.innerHTML = '';

  if (state.images.length === 0) {
    strip.style.display = 'none';
    return;
  }

  strip.style.display = 'block';

  const isCircular = document.getElementById('circularCrop')?.checked || false;

  state.images.forEach((img, i) => {
    const div = document.createElement('div');
    div.className = isCircular ? 'preview-item circular' : 'preview-item';

    const image = document.createElement('img');
    image.src = img.url;
    image.alt = img.filename;

    const label = document.createElement('div');
    label.className = 'preview-label';
    label.textContent = img.filename;
    label.title = img.filename;

    const removeBtn = document.createElement('button');
    removeBtn.className = 'preview-remove';
    removeBtn.innerHTML = '&times;';
    removeBtn.title = 'Remover imagem';
    removeBtn.onclick = (e) => { e.stopPropagation(); removeImage(i); };

    div.appendChild(image);
    div.appendChild(label);
    div.appendChild(removeBtn);

    if (img.uploading) {
      const overlay = document.createElement('div');
      overlay.className = 'preview-uploading';
      const spin = document.createElement('span');
      spin.className = 'spinner';
      overlay.appendChild(spin);
      div.appendChild(overlay);
    }

    list.appendChild(div);
  });
}

// ----------------------------------------------------------------
// Nugent Score Logic
// ----------------------------------------------------------------
const NUGENT_A = { '4+': 0, '3+': 1, '2+': 2, '1+': 3, 'ausente': 4 };
const NUGENT_B = { 'ausente': 0, '1+': 1, '2+': 2, '3+': 3, '4+': 4 };
const NUGENT_C = { 'ausente': 0, 'poucos': 1, 'muitos': 2 };

function updateNugentScore() {
  const aVal = getVal('nugentA') || '2+';
  const bVal = getVal('nugentB') || 'ausente';
  const cVal = getVal('nugentC') || 'ausente';

  const ptsA = NUGENT_A[aVal] ?? 0;
  const ptsB = NUGENT_B[bVal] ?? 0;
  const ptsC = NUGENT_C[cVal] ?? 0;
  const total = ptsA + ptsB + ptsC;

  document.getElementById('ptsA').textContent = ptsA;
  document.getElementById('ptsB').textContent = ptsB;
  document.getElementById('ptsC').textContent = ptsC;
  document.getElementById('nugentTotal').innerHTML = `${total}<small>/10</small>`;

  const badge = document.getElementById('nugentBadge');
  let interp, cls;

  if (total <= 3) {
    interp = `Normal (${total}/10)`;
    cls = 'normal';
  } else if (total <= 6) {
    interp = `Intermediária (${total}/10)`;
    cls = 'inter';
  } else {
    interp = `Vaginose bacteriana (${total}/10)`;
    cls = 'vb';
  }

  badge.textContent = interp;
  badge.className = `score-badge ${cls}`;
}

function getNugentInterpretacaoText() {
  const total = parseInt(document.getElementById('nugentTotal').textContent) || 0;
  if (total <= 3) return 'Normal';
  if (total <= 6) return 'Intermediária';
  return 'Vaginose bacteriana';
}

function getNugentTotalNumber() {
  const a = NUGENT_A[getVal('nugentA')] ?? 0;
  const b = NUGENT_B[getVal('nugentB')] ?? 0;
  const c = NUGENT_C[getVal('nugentC')] ?? 0;
  return a + b + c;
}

// ----------------------------------------------------------------
// Amsel Count Logic
// ----------------------------------------------------------------
function updateAmselCount() {
  const checkboxes = ['amselCorrimento', 'amselPh', 'amselWhiff', 'amselClue'];
  const itemIds = ['amselItem1', 'amselItem2', 'amselItem3', 'amselItem4'];

  let positives = 0;
  checkboxes.forEach((id, i) => {
    const checked = document.getElementById(id)?.checked || false;
    if (checked) positives++;
    const item = document.getElementById(itemIds[i]);
    if (item) {
      if (checked) item.classList.add('is-positive');
      else item.classList.remove('is-positive');
    }
  });

  const countEl = document.getElementById('amselCount');
  const resultEl = document.getElementById('amselResult');
  const resultText = document.getElementById('amselResultText');

  countEl.textContent = `${positives}/4 positivos`;

  if (positives >= 3) {
    countEl.className = 'amsel-count positive';
    resultEl.className = 'amsel-result vb';
    resultText.textContent = `${positives}/4 critérios positivos — Compatível com Vaginose Bacteriana`;
  } else if (positives > 0) {
    countEl.className = 'amsel-count';
    resultEl.className = 'amsel-result';
    resultText.textContent = `${positives}/4 critérios positivos — Insuficiente para diagnóstico de Vaginose Bacteriana`;
  } else {
    countEl.className = 'amsel-count';
    resultEl.className = 'amsel-result normal';
    resultText.textContent = 'Nenhum critério positivo de Amsel';
  }
}

// ----------------------------------------------------------------
// PDF Generation
// ----------------------------------------------------------------
async function generatePDF() {
  // Validation
  if (!getVal('paciente')) {
    showToast('Informe o nome da paciente antes de gerar o PDF.', 'warn');
    document.getElementById('paciente').focus();
    return;
  }
  if (!getVal('dataColeta')) {
    showToast('Informe a data da coleta antes de gerar o PDF.', 'warn');
    document.getElementById('dataColeta').focus();
    return;
  }
  if (!getVal('descricao')) {
    showToast('Preencha a descrição dos achados microscópicos.', 'warn');
    document.getElementById('descricao').focus();
    return;
  }
  if (!getVal('conclusao')) {
    showToast('Preencha a conclusão do laudo.', 'warn');
    document.getElementById('conclusao').focus();
    return;
  }

  const nugentTotal = getNugentTotalNumber();
  const nugentInterp = nugentTotal <= 3 ? 'Normal' : (nugentTotal <= 6 ? 'Intermediária' : 'Vaginose bacteriana');

  const readyImages = state.images.filter(i => i.image_id && !i.uploading);

  const floraRaw = getVal('floraType') || 'I';

  const payload = {
    paciente:             getVal('paciente'),
    data_nascimento:      getVal('dataNascimento'),
    data_coleta:          getVal('dataColeta'),
    solicitante:          getVal('solicitante'),
    image_ids:            readyImages.map(i => i.image_id),
    nugent_a_qty:         getVal('nugentA') || '2+',
    nugent_a_pts:         NUGENT_A[getVal('nugentA')] ?? 0,
    nugent_b_qty:         getVal('nugentB') || 'ausente',
    nugent_b_pts:         NUGENT_B[getVal('nugentB')] ?? 0,
    nugent_c_qty:         getVal('nugentC') || 'ausente',
    nugent_c_pts:         NUGENT_C[getVal('nugentC')] ?? 0,
    nugent_total:         nugentTotal,
    nugent_interpretacao: nugentInterp,
    amsel_corrimento:     document.getElementById('amselCorrimento')?.checked || false,
    amsel_ph:             document.getElementById('amselPh')?.checked || false,
    amsel_ph_valor:       getVal('amselPhValor') || null,
    amsel_whiff:          document.getElementById('amselWhiff')?.checked || false,
    amsel_clue_cells:     document.getElementById('amselClue')?.checked || false,
    polimorfonucleares:   getVal('polimorfonucleares') || 'ausentes',
    elementos_fungicos:   getVal('elementosFungicos') || 'ausentes',
    descricao:            getVal('descricao'),
    flora_tipo:           floraRaw,
    conclusao:            getVal('conclusao'),
    observacoes:          getVal('observacoes') || null,
    examinador:           getVal('examinador') || null,
    crm:                  getVal('crm') || null,
    data_avaliacao:       getVal('dataAvaliacao') || null,
    circular_crop:        document.getElementById('circularCrop')?.checked || false
  };

  const btn = document.getElementById('pdfBtn');
  const btnText = document.getElementById('pdfBtnText');
  const spinner = document.getElementById('pdfSpinner');
  btn.disabled = true;
  btnText.textContent = 'Gerando PDF...';
  spinner.style.display = 'inline-block';

  try {
    const res = await fetch('/generate-pdf', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({ detail: 'Erro desconhecido' }));
      throw new Error(errData.detail || `Erro ${res.status}`);
    }

    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');

    // Get filename from Content-Disposition header if available
    const cd = res.headers.get('Content-Disposition') || '';
    const match = cd.match(/filename=(.+)/);
    a.download = match ? match[1] : `laudo_${payload.paciente.replace(/\s+/g, '_')}.pdf`;
    a.href = url;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    showToast('PDF gerado e baixado com sucesso!', 'success');

  } catch (err) {
    showToast(`Erro ao gerar PDF: ${err.message}`, 'error');
  } finally {
    btn.disabled = false;
    btnText.textContent = 'Gerar Laudo PDF';
    spinner.style.display = 'none';
  }
}

// ----------------------------------------------------------------
// Toast Notifications
// ----------------------------------------------------------------
const TOAST_ICONS = {
  success: '✓',
  error:   '✕',
  warn:    '⚠',
  info:    'ℹ'
};

function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;

  toast.innerHTML = `
    <span class="toast-icon">${TOAST_ICONS[type] || 'ℹ'}</span>
    <span class="toast-msg">${message}</span>
    <button class="toast-close" onclick="dismissToast(this.parentElement)">&times;</button>
  `;

  container.appendChild(toast);

  const timeout = type === 'error' ? 7000 : 4000;
  setTimeout(() => dismissToast(toast), timeout);
}

function dismissToast(el) {
  if (!el || !el.parentElement) return;
  el.classList.add('fadeout');
  setTimeout(() => { if (el.parentElement) el.parentElement.removeChild(el); }, 320);
}

// ----------------------------------------------------------------
// Start App
// ----------------------------------------------------------------
document.addEventListener('DOMContentLoaded', initApp);

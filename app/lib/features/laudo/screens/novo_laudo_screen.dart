import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:microlaudo/core/theme/app_theme.dart';
import 'package:microlaudo/features/laudo/models/laudo_model.dart';
import 'package:microlaudo/features/laudo/services/laudo_service.dart';
import 'package:microlaudo/features/laudo/repositories/laudo_repository.dart';
import 'package:microlaudo/features/laudo/widgets/section_header.dart';
import 'package:microlaudo/features/laudo/widgets/nugent_row.dart';
import 'package:microlaudo/features/laudo/widgets/image_picker_section.dart';

class NovoLaudoScreen extends StatefulWidget {
  const NovoLaudoScreen({super.key});

  @override
  State<NovoLaudoScreen> createState() => _NovoLaudoScreenState();
}

class _NovoLaudoScreenState extends State<NovoLaudoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LaudoService();
  final _picker = ImagePicker();
  bool _loading = false;

  // Fotos
  final List<XFile> _images = [];
  final List<String> _imageIds = [];
  bool _uploading = false;

  // Dados da paciente
  final _pacienteCtrl = TextEditingController();
  final _dataNascCtrl = TextEditingController();
  final _dataColetaCtrl = TextEditingController();
  final _solicitanteCtrl = TextEditingController();

  // Nugent
  String _nugentA = '4+';
  String _nugentB = '0';
  String _nugentC = '0';

  // Amsel
  bool _amselCorrimento = false;
  bool _amselPh = false;
  final _phValorCtrl = TextEditingController();
  bool _amselWhiff = false;
  bool _amselClueCells = false;

  // Achados
  String _polimorf = polimorfonuclearesOptions.first;
  String _fungicos = elementosFungicosOptions.first;
  final _descricaoCtrl = TextEditingController();
  String _floraTipo = floraTipoOptions.first;

  // Conclusão
  final _conclusaoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  // Assinatura
  final _examinadorCtrl = TextEditingController();
  final _crmCtrl = TextEditingController();
  final _dataAvalCtrl = TextEditingController();

  // Calculados
  int get _ptA => nugentAPts(_nugentA);
  int get _ptB => nugentBPts(_nugentB);
  int get _ptC => nugentCPts(_nugentC);
  int get _total => _ptA + _ptB + _ptC;
  String get _interpretacao => nugentInterpretacao(_total);

  Color get _nugentColor {
    if (_total <= 3) return AppColors.success;
    if (_total <= 6) return const Color(0xFFDD6B20);
    return AppColors.error;
  }

  @override
  void dispose() {
    _pacienteCtrl.dispose();
    _dataNascCtrl.dispose();
    _dataColetaCtrl.dispose();
    _solicitanteCtrl.dispose();
    _phValorCtrl.dispose();
    _descricaoCtrl.dispose();
    _conclusaoCtrl.dispose();
    _observacoesCtrl.dispose();
    _examinadorCtrl.dispose();
    _crmCtrl.dispose();
    _dataAvalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  void _autoFillConclusion() {
    final amselCount = [
      _amselCorrimento, _amselPh, _amselWhiff, _amselClueCells
    ].where((b) => b).length;

    String conclusao;
    if (_total >= 7 || amselCount >= 3) {
      conclusao =
          'Achados compatíveis com vaginose bacteriana. Score de Nugent: $_total/10. '
          'Critérios de Amsel: $amselCount/4.';
    } else if (_total >= 4 || amselCount >= 2) {
      conclusao =
          'Achados sugestivos de flora de transição. Score de Nugent: $_total/10. '
          'Recomenda-se correlação clínica.';
    } else {
      conclusao =
          'Achados dentro da normalidade. Flora vaginal preservada. '
          'Score de Nugent: $_total/10. Ausência de critérios de Amsel.';
    }
    _conclusaoCtrl.text = conclusao;
    setState(() {});
  }

  Future<void> _addImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() {
      _images.add(picked);
      _uploading = true;
    });

    try {
      final id = await _service.uploadImage(picked);
      setState(() => _imageIds.add(id));
    } catch (e) {
      setState(() => _images.removeLast());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao enviar foto: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      if (index < _imageIds.length) _imageIds.removeAt(index);
    });
  }

  Future<void> _gerarPdf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final laudo = LaudoModel(
        paciente: _pacienteCtrl.text,
        dataNascimento: _dataNascCtrl.text,
        dataColeta: _dataColetaCtrl.text,
        solicitante: _solicitanteCtrl.text,
        nugentAQty: _nugentA,
        nugentAPts: _ptA,
        nugentBQty: _nugentB,
        nugentBPts: _ptB,
        nugentCQty: _nugentC,
        nugentCPts: _ptC,
        nugentTotal: _total,
        nugentInterpretacao: _interpretacao,
        amselCorrimento: _amselCorrimento,
        amselPh: _amselPh,
        amselPhValor: _amselPh && _phValorCtrl.text.isNotEmpty
            ? _phValorCtrl.text
            : null,
        amselWhiff: _amselWhiff,
        amselClueCells: _amselClueCells,
        polimorfonucleares: _polimorf,
        elementosFungicos: _fungicos,
        descricao: _descricaoCtrl.text,
        floraTipo: _floraTipo,
        conclusao: _conclusaoCtrl.text,
        observacoes: _observacoesCtrl.text.isNotEmpty
            ? _observacoesCtrl.text
            : null,
        examinador: _examinadorCtrl.text.isNotEmpty
            ? _examinadorCtrl.text
            : null,
        crm: _crmCtrl.text.isNotEmpty ? _crmCtrl.text : null,
        dataAvaliacao: _dataAvalCtrl.text.isNotEmpty
            ? _dataAvalCtrl.text
            : null,
        imageIds: _imageIds,
      );
      await _service.gerarEBaixarPdf(laudo);
      await LaudoRepository().salvar(laudo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF gerado e laudo salvo!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Laudo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 1. DADOS DA PACIENTE ──────────────────────────────
            const SectionHeader(
              icon: Icons.person_outlined,
              title: 'Dados da Paciente',
            ),
            _field(
              controller: _pacienteCtrl,
              label: 'Nome completo *',
              caps: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            _field(
              controller: _dataNascCtrl,
              label: 'Data de nascimento *',
              hint: 'dd/mm/aaaa',
              readOnly: true,
              onTap: () => _pickDate(_dataNascCtrl),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            _field(
              controller: _dataColetaCtrl,
              label: 'Data da coleta *',
              hint: 'dd/mm/aaaa',
              readOnly: true,
              onTap: () => _pickDate(_dataColetaCtrl),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            _field(
              controller: _solicitanteCtrl,
              label: 'Médico solicitante',
              caps: TextCapitalization.words,
            ),
            const SizedBox(height: 8),

            // ── FOTOS DA MICROSCOPIA ──────────────────────────────
            const SectionHeader(
              icon: Icons.camera_alt_outlined,
              title: 'Fotos da Microscopia',
            ),
            ImagePickerSection(
              images: _images,
              uploadedIds: _imageIds,
              uploading: _uploading,
              onAddCamera: () => _addImage(ImageSource.camera),
              onAddGallery: () => _addImage(ImageSource.gallery),
              onRemove: _removeImage,
            ),
            const SizedBox(height: 8),

            // ── 2. SCORE DE NUGENT ────────────────────────────────
            const SectionHeader(
              icon: Icons.bar_chart,
              title: 'Score de Nugent',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Cabeçalho
                    Row(
                      children: [
                        const SizedBox(width: 30),
                        Expanded(
                          child: Text('Morfotipo', style: _headerStyle),
                        ),
                        Text('Achado', style: _headerStyle),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 28,
                          child: Text('Pts',
                              style: _headerStyle,
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    const Divider(),
                    NugentRow(
                      label: 'A',
                      description: 'Lactobacillus',
                      options: nugentAOptions,
                      value: _nugentA,
                      pts: _ptA,
                      onChanged: (v) => setState(() => _nugentA = v!),
                    ),
                    NugentRow(
                      label: 'B',
                      description: 'Gardnerella/Prevotella',
                      options: nugentBOptions,
                      value: _nugentB,
                      pts: _ptB,
                      onChanged: (v) => setState(() => _nugentB = v!),
                    ),
                    NugentRow(
                      label: 'C',
                      description: 'Mobiluncus',
                      options: nugentCOptions,
                      value: _nugentC,
                      pts: _ptC,
                      onChanged: (v) => setState(() => _nugentC = v!),
                    ),
                    const Divider(),
                    // Total
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _nugentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: _nugentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.assessment,
                              color: _nugentColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _interpretacao,
                              style: TextStyle(
                                color: _nugentColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '$_total/10',
                            style: TextStyle(
                              color: _nugentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── 3. CRITÉRIOS DE AMSEL ─────────────────────────────
            const SectionHeader(
              icon: Icons.checklist,
              title: 'Critérios de Amsel',
            ),
            Card(
              child: Column(
                children: [
                  _amselTile(
                    '1. Corrimento homogêneo branco-acinzentado',
                    _amselCorrimento,
                    (v) => setState(() => _amselCorrimento = v!),
                  ),
                  _amselTile(
                    '2. pH vaginal > 4,5',
                    _amselPh,
                    (v) => setState(() => _amselPh = v!),
                    extra: _amselPh
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TextFormField(
                              controller: _phValorCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Valor do pH (opcional)',
                                isDense: true,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          )
                        : null,
                  ),
                  _amselTile(
                    '3. Teste das aminas (Whiff test)',
                    _amselWhiff,
                    (v) => setState(() => _amselWhiff = v!),
                  ),
                  _amselTile(
                    '4. Clue cells ≥ 20% das células epiteliais',
                    _amselClueCells,
                    (v) => setState(() => _amselClueCells = v!),
                  ),
                  // Resumo Amsel
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Builder(builder: (context) {
                      final count = [
                        _amselCorrimento,
                        _amselPh,
                        _amselWhiff,
                        _amselClueCells
                      ].where((b) => b).length;
                      final ok = count >= 3;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: (ok ? AppColors.error : AppColors.success)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              ok ? Icons.warning_amber : Icons.check_circle,
                              color:
                                  ok ? AppColors.error : AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ok
                                  ? 'Compatível com VB ($count/4 critérios)'
                                  : 'Insuficiente para VB ($count/4 critérios)',
                              style: TextStyle(
                                color:
                                    ok ? AppColors.error : AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── 4. ACHADOS MICROSCÓPICOS ──────────────────────────
            const SectionHeader(
              icon: Icons.biotech,
              title: 'Achados Microscópicos',
            ),
            _dropdown(
              label: 'Polimorfonucleares',
              value: _polimorf,
              options: polimorfonuclearesOptions,
              onChanged: (v) => setState(() => _polimorf = v!),
            ),
            _dropdown(
              label: 'Elementos fúngicos',
              value: _fungicos,
              options: elementosFungicosOptions,
              onChanged: (v) => setState(() => _fungicos = v!),
            ),
            _dropdown(
              label: 'Tipo de flora',
              value: _floraTipo,
              options: floraTipoOptions,
              onChanged: (v) => setState(() => _floraTipo = v!),
            ),
            _field(
              controller: _descricaoCtrl,
              label: 'Descrição adicional (opcional)',
              maxLines: 3,
            ),
            const SizedBox(height: 8),

            // ── 5. CONCLUSÃO ──────────────────────────────────────
            const SectionHeader(
              icon: Icons.summarize_outlined,
              title: 'Conclusão',
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _autoFillConclusion,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Preencher automaticamente'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _conclusaoCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Conclusão *'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacoesCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(labelText: 'Observações (opcional)'),
            ),
            const SizedBox(height: 8),

            // ── 6. ASSINATURA ─────────────────────────────────────
            const SectionHeader(
              icon: Icons.badge_outlined,
              title: 'Assinatura',
            ),
            _field(
              controller: _examinadorCtrl,
              label: 'Nome do examinador',
              caps: TextCapitalization.words,
            ),
            _field(
              controller: _crmCtrl,
              label: 'CRM / RQE',
              hint: 'ex: CRM 12345/SP  RQE 4121',
            ),
            _field(
              controller: _dataAvalCtrl,
              label: 'Data da avaliação',
              hint: 'dd/mm/aaaa',
              readOnly: true,
              onTap: () => _pickDate(_dataAvalCtrl),
            ),
            const SizedBox(height: 24),

            // ── BOTÃO GERAR PDF ───────────────────────────────────
            ElevatedButton.icon(
              onPressed: _loading ? null : _gerarPdf,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_loading ? 'Gerando...' : 'Gerar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  TextStyle get _headerStyle => const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        textCapitalization: caps,
        validator: validator,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _amselTile(
    String label,
    bool value,
    ValueChanged<bool?> onChanged, {
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(label, style: const TextStyle(fontSize: 13)),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          dense: true,
        ),
        if (extra != null) extra,
      ],
    );
  }
}

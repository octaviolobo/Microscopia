import 'package:flutter/material.dart';
import 'package:microlaudo/core/theme/app_theme.dart';
import 'package:microlaudo/features/laudo/models/laudo_model.dart';
import 'package:microlaudo/features/laudo/repositories/laudo_repository.dart';
import 'package:microlaudo/features/laudo/services/laudo_service.dart';

class DetalheLaudoScreen extends StatefulWidget {
  final LaudoSummary laudo;
  const DetalheLaudoScreen({super.key, required this.laudo});

  @override
  State<DetalheLaudoScreen> createState() => _DetalheLaudoScreenState();
}

class _DetalheLaudoScreenState extends State<DetalheLaudoScreen> {
  bool _loading = false;

  Future<void> _regenarPdf() async {
    setState(() => _loading = true);
    try {
      await LaudoService().gerarEBaixarPdf(widget.laudo.model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('PDF gerado!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deletar laudo?'),
        content: Text('O laudo de ${widget.laudo.paciente} será removido permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await LaudoRepository().deletar(widget.laudo.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.laudo;
    final m = l.model;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.paciente, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deletar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: 'Paciente', children: [
              _Row('Nome', m.paciente),
              _Row('Nascimento', m.dataNascimento),
              _Row('Data da coleta', m.dataColeta),
              _Row('Solicitante', m.solicitante),
            ]),
            _Section(title: 'Score de Nugent', children: [
              _Row('A — Lactobacillus', '${m.nugentAQty} (${m.nugentAPts} pts)'),
              _Row('B — Gardnerella', '${m.nugentBQty} (${m.nugentBPts} pts)'),
              _Row('C — Mobiluncus', '${m.nugentCQty} (${m.nugentCPts} pts)'),
              _Row('Total', '${m.nugentTotal}/10 — ${m.nugentInterpretacao}'),
            ]),
            _Section(title: 'Critérios de Amsel', children: [
              _Row('Corrimento', m.amselCorrimento ? 'Presente' : 'Ausente'),
              _Row('pH vaginal', m.amselPh ? 'Alterado (${m.amselPhValor ?? ''})' : 'Normal'),
              _Row('Whiff test', m.amselWhiff ? 'Positivo' : 'Negativo'),
              _Row('Clue cells', m.amselClueCells ? 'Presente' : 'Ausente'),
            ]),
            _Section(title: 'Achados', children: [
              _Row('Polimorfonucleares', m.polimorfonucleares),
              _Row('Elementos fúngicos', m.elementosFungicos),
              _Row('Tipo de flora', m.floraTipo),
              if (m.descricao.isNotEmpty) _Row('Descrição', m.descricao),
            ]),
            _Section(title: 'Conclusão', children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(m.conclusao, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ),
              if (m.observacoes != null && m.observacoes!.isNotEmpty)
                _Row('Observações', m.observacoes!),
            ]),
            if (m.examinador != null) _Section(title: 'Assinatura', children: [
              _Row('Examinador', m.examinador!),
              if (m.crm != null) _Row('CRM', m.crm!),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _regenarPdf,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_loading ? 'Gerando...' : 'Re-gerar PDF'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary)),
            const Divider(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

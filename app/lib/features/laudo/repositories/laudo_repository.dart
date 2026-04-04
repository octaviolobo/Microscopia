import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:microlaudo/features/laudo/models/laudo_model.dart';

class LaudoRepository {
  final _db = Supabase.instance.client;

  Future<void> salvar(LaudoModel laudo) async {
    final userId = _db.auth.currentUser!.id;
    await _db.from('laudos').insert({
      'user_id': userId,
      'paciente': laudo.paciente,
      'data_nascimento': laudo.dataNascimento,
      'data_coleta': laudo.dataColeta,
      'solicitante': laudo.solicitante,
      'nugent_a_qty': laudo.nugentAQty,
      'nugent_a_pts': laudo.nugentAPts,
      'nugent_b_qty': laudo.nugentBQty,
      'nugent_b_pts': laudo.nugentBPts,
      'nugent_c_qty': laudo.nugentCQty,
      'nugent_c_pts': laudo.nugentCPts,
      'nugent_total': laudo.nugentTotal,
      'nugent_interpretacao': laudo.nugentInterpretacao,
      'amsel_corrimento': laudo.amselCorrimento,
      'amsel_ph': laudo.amselPh,
      'amsel_ph_valor': laudo.amselPhValor,
      'amsel_whiff': laudo.amselWhiff,
      'amsel_clue_cells': laudo.amselClueCells,
      'polimorfonucleares': laudo.polimorfonucleares,
      'elementos_fungicos': laudo.elementosFungicos,
      'descricao': laudo.descricao,
      'flora_tipo': laudo.floraTipo,
      'conclusao': laudo.conclusao,
      'observacoes': laudo.observacoes,
      'examinador': laudo.examinador,
      'crm': laudo.crm,
      'data_avaliacao': laudo.dataAvaliacao,
      'image_ids': laudo.imageIds,
    });
  }

  Future<List<LaudoSummary>> listar() async {
    final userId = _db.auth.currentUser!.id;
    final data = await _db
        .from('laudos')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => LaudoSummary.fromJson(e)).toList();
  }

  Future<void> deletar(String id) async {
    await _db.from('laudos').delete().eq('id', id);
  }
}

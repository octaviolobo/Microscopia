class LaudoModel {
  final String paciente;
  final String dataNascimento;
  final String dataColeta;
  final String solicitante;
  final String nugentAQty;
  final int nugentAPts;
  final String nugentBQty;
  final int nugentBPts;
  final String nugentCQty;
  final int nugentCPts;
  final int nugentTotal;
  final String nugentInterpretacao;
  final bool amselCorrimento;
  final bool amselPh;
  final String? amselPhValor;
  final bool amselWhiff;
  final bool amselClueCells;
  final String polimorfonucleares;
  final String elementosFungicos;
  final String descricao;
  final String floraTipo;
  final String conclusao;
  final String? observacoes;
  final String? examinador;
  final String? crm;
  final String? dataAvaliacao;
  final bool circularCrop;
  final List<String> imageIds;

  const LaudoModel({
    required this.paciente,
    required this.dataNascimento,
    required this.dataColeta,
    required this.solicitante,
    required this.nugentAQty,
    required this.nugentAPts,
    required this.nugentBQty,
    required this.nugentBPts,
    required this.nugentCQty,
    required this.nugentCPts,
    required this.nugentTotal,
    required this.nugentInterpretacao,
    required this.amselCorrimento,
    required this.amselPh,
    this.amselPhValor,
    required this.amselWhiff,
    required this.amselClueCells,
    required this.polimorfonucleares,
    required this.elementosFungicos,
    required this.descricao,
    required this.floraTipo,
    required this.conclusao,
    this.observacoes,
    this.examinador,
    this.crm,
    this.dataAvaliacao,
    this.circularCrop = false,
    this.imageIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'paciente': paciente,
        'data_nascimento': dataNascimento,
        'data_coleta': dataColeta,
        'solicitante': solicitante,
        'nugent_a_qty': nugentAQty,
        'nugent_a_pts': nugentAPts,
        'nugent_b_qty': nugentBQty,
        'nugent_b_pts': nugentBPts,
        'nugent_c_qty': nugentCQty,
        'nugent_c_pts': nugentCPts,
        'nugent_total': nugentTotal,
        'nugent_interpretacao': nugentInterpretacao,
        'amsel_corrimento': amselCorrimento,
        'amsel_ph': amselPh,
        'amsel_ph_valor': amselPhValor,
        'amsel_whiff': amselWhiff,
        'amsel_clue_cells': amselClueCells,
        'polimorfonucleares': polimorfonucleares,
        'elementos_fungicos': elementosFungicos,
        'descricao': descricao,
        'flora_tipo': floraTipo,
        'conclusao': conclusao,
        'observacoes': observacoes,
        'examinador': examinador,
        'crm': crm,
        'data_avaliacao': dataAvaliacao,
        'circular_crop': circularCrop,
        'image_ids': imageIds,
      };
}

// Nugent scoring helpers
const nugentAOptions = ['4+', '3+', '2+', '1+', '0'];
const nugentBOptions = ['0', '1+', '2+', '3+', '4+'];
const nugentCOptions = ['0', '1+/2+', '3+/4+'];

int nugentAPts(String qty) {
  switch (qty) {
    case '4+': return 0;
    case '3+': return 1;
    case '2+': return 2;
    case '1+': return 3;
    case '0':  return 4;
    default:   return 0;
  }
}

int nugentBPts(String qty) {
  switch (qty) {
    case '0':  return 0;
    case '1+': return 1;
    case '2+': return 2;
    case '3+': return 3;
    case '4+': return 4;
    default:   return 0;
  }
}

int nugentCPts(String qty) {
  switch (qty) {
    case '0':      return 0;
    case '1+/2+':  return 1;
    case '3+/4+':  return 2;
    default:       return 0;
  }
}

String nugentInterpretacao(int total) {
  if (total <= 3) return 'Flora Normal (score $total/10)';
  if (total <= 6) return 'Flora de Transição (score $total/10)';
  return 'Vaginose Bacteriana (score $total/10)';
}

const polimorfonuclearesOptions = [
  'Ausente',
  'Raro (<5/campo)',
  'Moderado (5–10/campo)',
  'Abundante (>10/campo)',
];

const elementosFungicosOptions = [
  'Ausente',
  'Presente (esporos)',
  'Presente (hifas)',
  'Presente (hifas + esporos)',
];

const floraTipoOptions = [
  'Flora normal (Lactobacillus dominante)',
  'Flora de transição',
  'Vaginose bacteriana',
  'Flora mista',
  'Flora ausente/escassa',
];

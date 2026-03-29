import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:microlaudo/features/laudo/models/laudo_model.dart';
import 'package:microlaudo/core/utils/pdf_saver.dart';

const _baseUrl = 'http://10.0.2.2:8000';

class LaudoService {
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Faz upload de uma imagem e retorna o image_id
  Future<String> uploadImage(XFile file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      ),
    });
    final response = await _dio.post('/upload', data: formData);
    return response.data['image_id'] as String;
  }

  /// Gera e baixa o PDF
  Future<void> gerarEBaixarPdf(LaudoModel laudo) async {
    final response = await _dio.post(
      '/generate-pdf',
      data: laudo.toJson(),
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = Uint8List.fromList(response.data as List<int>);
    final nome = laudo.paciente.replaceAll(' ', '_');
    final data = laudo.dataColeta.replaceAll('/', '');
    final filename = 'laudo_${nome}_$data.pdf';

    await savePdf(bytes, filename);
  }
}

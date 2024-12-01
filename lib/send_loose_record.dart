import 'dart:convert';
import 'package:avaguard/config.dart';
import 'package:avaguard/resources/firestore_methods.dart';
import 'package:http/http.dart' as http;

class SendLooseRecord {
  final FirebaseStorageService _storageService = FirebaseStorageService();

  Future<bool> sendLooseEmployeesRecording({
    required String userId,
    required List<String> urls,
    required String date,
    required String description,
  }) async {
    final payload = {
      "userId": userId,
      "urls": urls,
      "date": date,
      "description": description,
    };

    try {
      final response = await http.post(
        Uri.parse(sendLooseRecords),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        print("Arquivo enviado com sucesso!");
        return true;
      } else {
        print(
            "Erro ao enviar arquivo: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erro ao enviar arquivo: $e");
      return false;
    }
  }

  Future<String?> getUrlFirebase(
      String? recordingId, String? localFilePath) async {
    try {
      final downloadUrl =
          await _storageService.uploadFile(localFilePath!, 'audio-files');
      if (downloadUrl != null) {
        print("Arquivo enviado para o Firebase Storage com URL: $downloadUrl");
        return downloadUrl;
      } else {
        return null;
      }
    } catch (e) {
      print("Erro na requisição ao firebase: $e");
      return null;
    }
  }
}

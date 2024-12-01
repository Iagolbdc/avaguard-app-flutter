import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  /// Faz o upload do arquivo para o Firebase Storage.
  Future<String?> uploadFile(String filePath, String folderName) async {
    try {
      final file = File(filePath);
      final fileName = file.uri.pathSegments.last;

      final ref = _firebaseStorage.ref().child('$folderName/$fileName');

      // Realiza o upload
      final uploadTask = ref.putFile(file);

      // Aguarda o upload e retorna o URL de download
      final snapshot = await uploadTask.whenComplete(() => {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print("Upload bem-sucedido! URL: $downloadUrl");
      return downloadUrl;
    } catch (e) {
      print("Erro ao enviar o arquivo para o Firebase Storage: $e");
      return null;
    }
  }
}

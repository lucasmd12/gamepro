import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class MediaService {
  final ApiService _apiService;

  MediaService(this._apiService);

  Future<String> uploadImage(File imageFile, String uploadPath) async {
    try {
      final uri = Uri.parse('${_apiService.baseUrl}/api/$uploadPath');
      var request = http.MultipartRequest('POST', uri);

      final token = await _apiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        Logger.info('Image uploaded successfully: $responseBody');
        // Assumindo que o backend retorna a URL da imagem no corpo da resposta
        // Você pode precisar ajustar isso dependendo da sua API
        return responseBody; // Ou parsear JSON se for o caso
      } else {
        final errorBody = await response.stream.bytesToString();
        Logger.error('Failed to upload image. Status: ${response.statusCode}, Body: $errorBody');
        throw Exception('Failed to upload image: ${response.statusCode} - $errorBody');
      }
    } catch (e, stackTrace) {
      Logger.error('Error uploading image', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Adicione outros métodos para gerenciamento de mídia conforme necessário
  // Ex: downloadImage, deleteImage, etc.
}



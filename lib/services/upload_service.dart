import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucasbeatsfederacao/utils/constants.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/services/cache_service.dart';


class UploadService {
  final String _baseUrl = backendBaseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CacheService _cacheService = CacheService.instance;
  
  static const Duration _uploadTimeout = Duration(minutes: 5);
  
  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{};
    if (includeAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Upload de avatar do usuário
  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      Logger.info('Iniciando upload de avatar...');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/profile-picture');
      final request = http.MultipartRequest('POST', url);
      
      // Adicionar headers de autenticação
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Adicionar arquivo
      // O backend espera o campo 'profilePicture' conforme definido no uploadController.js
      final multipartFile = await http.MultipartFile.fromPath(
        'profilePicture', 
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      Logger.info('Enviando arquivo de avatar para: $url');
      
      // Enviar requisição
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      Logger.info('Upload response status: ${response.statusCode}');
      Logger.info('Upload response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        // Invalidar cache de usuário após upload de avatar
        await _cacheService.invalidatePattern('user_*');
        
        Logger.info('Avatar enviado com sucesso');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Avatar enviado com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro no upload do avatar';
        Logger.error('Erro no upload de avatar: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção no upload de avatar: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno no upload: ${e.toString()}'
      };
    }
  }

  /// Upload de imagem de missão
  Future<Map<String, dynamic>> uploadMissionImage(File imageFile) async {
    try {
      Logger.info('Iniciando upload de imagem de missão...');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/multiple');
      final request = http.MultipartRequest('POST', url);
      
      // Adicionar headers de autenticação
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Adicionar arquivo
      final multipartFile = await http.MultipartFile.fromPath(
        'files',
        imageFile.path,
      );
      request.files.add(multipartFile);
      
      Logger.info('Enviando arquivo de missão: ${imageFile.path}');
      
      // Enviar requisição
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        // Invalidar cache de missões após upload
        await _cacheService.invalidatePattern('mission_*');
        
        Logger.info('Imagem de missão enviada com sucesso');
        return {
          'success': true,
          'data': responseData['data'] is List ? responseData['data'] : [responseData['data']],
          'message': responseData['message'] ?? 'Imagem enviada com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro no upload da imagem';
        Logger.error('Erro no upload de imagem de missão: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção no upload de imagem de missão: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno no upload: ${e.toString()}'
      };
    }
  }

  /// Upload múltiplo de arquivos
  Future<Map<String, dynamic>> uploadMultipleFiles(List<File> files, {String fieldName = 'files'}) async {
    try {
      if (files.isEmpty) {
        return {
          'success': false,
          'message': 'Nenhum arquivo selecionado'
        };
      }

      if (files.length > 5) {
        return {
          'success': false,
          'message': 'Máximo de 5 arquivos permitidos'
        };
      }

      Logger.info('Iniciando upload múltiplo de ${files.length} arquivo(s)...');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/multiple');
      final request = http.MultipartRequest('POST', url);
      
      // Adicionar headers de autenticação
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      
      // Adicionar arquivos
      for (final file in files) {
        final multipartFile = await http.MultipartFile.fromPath(
          fieldName,
          file.path,
        );
        request.files.add(multipartFile);
      }
      
      Logger.info('Enviando ${files.length} arquivo(s)...');
      
      // Enviar requisição
      final streamedResponse = await request.send().timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        Logger.info('Upload múltiplo realizado com sucesso');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Arquivos enviados com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro no upload dos arquivos';
        Logger.error('Erro no upload múltiplo: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção no upload múltiplo: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno no upload: ${e.toString()}'
      };
    }
  }

  /// Deletar arquivo do Cloudinary
  Future<Map<String, dynamic>> deleteFile(String publicId) async {
    try {
      Logger.info('Deletando arquivo: $publicId');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/delete/$publicId');
      final headers = await _getHeaders();
      
      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        Logger.info('Arquivo deletado com sucesso');
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Arquivo removido com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao remover arquivo';
        Logger.error('Erro ao deletar arquivo: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção ao deletar arquivo: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno ao deletar: ${e.toString()}'
      };
    }
  }

  /// Obter informações de um arquivo
  Future<Map<String, dynamic>> getFileInfo(String publicId) async {
    try {
      Logger.info('Obtendo informações do arquivo: $publicId');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/info/$publicId');
      final headers = await _getHeaders();
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Informações obtidas com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao obter informações';
        Logger.error('Erro ao obter informações do arquivo: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção ao obter informações do arquivo: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno: ${e.toString()}'
      };
    }
  }

  /// Listar arquivos de uma pasta
  Future<Map<String, dynamic>> listFiles({String folder = 'federacao_mad', int maxResults = 50}) async {
    try {
      Logger.info('Listando arquivos da pasta: $folder');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/list?folder=$folder&maxResults=$maxResults');
      final headers = await _getHeaders();
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Arquivos listados com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao listar arquivos';
        Logger.error('Erro ao listar arquivos: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção ao listar arquivos: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno no upload: ${e.toString()}'
      };
    }
  }

  /// Obter estatísticas do serviço de upload
  Future<Map<String, dynamic>> getUploadStats() async {
    try {
      Logger.info('Obtendo estatísticas de upload...');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/stats');
      final headers = await _getHeaders();
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Estatísticas obtidas com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao obter estatísticas';
        Logger.error('Erro ao obter estatísticas: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção ao obter estatísticas: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno: ${e.toString()}'
      };
    }
  }

  /// Testar conexão com Cloudinary
  Future<Map<String, dynamic>> testCloudinaryConnection() async {
    try {
      Logger.info('Testando conexão com Cloudinary...');
      
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/test');
      final headers = await _getHeaders();
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'Conexão testada com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro no teste de conexão';
        Logger.error('Erro no teste de conexão: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção no teste de conexão: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno: ${e.toString()}'
      };
    }
  }

  /// Gerar URLs com transformações
  Future<Map<String, dynamic>> getTransformedUrls(String publicId, {List<String> presets = const ['thumbnail', 'medium', 'large']}) async {
    try {
      Logger.info('Gerando URLs transformadas para: $publicId');
      
      final presetsParam = presets.join(',');
      // ✅ CORRIGIDO
      final url = Uri.parse('$_baseUrl/api/uploads/transform/$publicId?presets=$presetsParam');
      final headers = await _getHeaders();
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'data': responseData['data'],
          'message': responseData['message'] ?? 'URLs geradas com sucesso'
        };
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao gerar URLs';
        Logger.error('Erro ao gerar URLs transformadas: $errorMessage');
        
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      Logger.error('Exceção ao gerar URLs transformadas: ${e.toString()}');
      return {
        'success': false,
        'message': 'Erro interno: ${e.toString()}'
      };
    }
  }

  /// Validar arquivo antes do upload
  bool validateFile(File file, {int maxSizeInMB = 10, List<String> allowedExtensions = const ['jpg', 'jpeg', 'png', 'gif', 'webp']}) {
    try {
      // Verificar se o arquivo existe
      if (!file.existsSync()) {
        Logger.error('Arquivo não existe: ${file.path}');
        return false;
      }

      // Verificar tamanho
      final fileSizeInBytes = file.lengthSync();
      final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
      
      if (fileSizeInBytes > maxSizeInBytes) {
        Logger.error('Arquivo muito grande: $fileSizeInBytes bytes (máximo: $maxSizeInBytes bytes)');
        return false;
      }

      // Verificar extensão
      final fileExtension = file.path.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(fileExtension)) {
        Logger.error('Extensão de arquivo não permitida: $fileExtension');
        return false;
      }

      return true;
    } catch (e) {
      Logger.error('Erro na validação do arquivo: ${e.toString()}');
      return false;
    }
  }
}

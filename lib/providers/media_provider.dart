import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:lucasbeatsfederacao/services/media_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

enum UploadStatus {
  idle,
  uploading,
  success,
  error,
}

class MediaProvider extends ChangeNotifier {
  final MediaService _mediaService;

  UploadStatus _uploadStatus = UploadStatus.idle;
  String? _uploadedImageUrl;
  String? _errorMessage;

  UploadStatus get uploadStatus => _uploadStatus;
  String? get uploadedImageUrl => _uploadedImageUrl;
  String? get errorMessage => _errorMessage;

  MediaProvider(this._mediaService);

  void _setUploadStatus(UploadStatus status) {
    _uploadStatus = status;
    notifyListeners();
  }

  void _setUploadedImageUrl(String? url) {
    _uploadedImageUrl = url;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> uploadImage(File imageFile, String uploadPath) async {
    _setUploadStatus(UploadStatus.uploading);
    _setErrorMessage(null);
    _setUploadedImageUrl(null);
    try {
      final imageUrl = await _mediaService.uploadImage(imageFile, uploadPath);
      _setUploadedImageUrl(imageUrl);
      _setUploadStatus(UploadStatus.success);
      Logger.info('MediaProvider: Imagem enviada com sucesso: $imageUrl');
    } catch (e, stackTrace) {
      _setErrorMessage('Erro ao enviar imagem: ${e.toString()}');
      _setUploadStatus(UploadStatus.error);
      Logger.error('MediaProvider: Erro ao enviar imagem', error: e, stackTrace: stackTrace);
    }
  }

  void resetUploadStatus() {
    _setUploadStatus(UploadStatus.idle);
    _setErrorMessage(null);
    _setUploadedImageUrl(null);
  }
}



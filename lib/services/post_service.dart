import 'package:lucasbeatsfederacao/services/api_service.dart';
import 'package:lucasbeatsfederacao/models/post_model.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class PostService {
  final ApiService _apiService;

  PostService(this._apiService);

  Future<PostModel?> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _apiService.post('posts', postData);
      if (response.statusCode == 201) {
        return PostModel.fromJson(response.data);
      } else {
        Logger.error('Failed to create post: ${response.data}');
        return null;
      }
    } catch (e, st) {
      Logger.error('Error creating post', error: e, stackTrace: st);
      return null;
    }
  }

  Future<List<PostModel>> getPosts({String? clanId, String? federationId}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (clanId != null) queryParams['clanId'] = clanId;
      if (federationId != null) queryParams['federationId'] = federationId;

      final response = await _apiService.get('posts', queryParams: queryParams);
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => PostModel.fromJson(json)).toList();
      } else {
        Logger.error('Failed to fetch posts: ${response.data}');
        return [];
      }
    } catch (e, st) {
      Logger.error('Error fetching posts', error: e, stackTrace: st);
      return [];
    }
  }
}


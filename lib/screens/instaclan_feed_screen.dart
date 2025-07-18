import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/models/post_model.dart';
import 'package:lucasbeatsfederacao/services/post_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';

class InstaClanFeedScreen extends StatefulWidget {
  final String? clanId;
  final String? federationId;

  const InstaClanFeedScreen({super.key, this.clanId, this.federationId});

  @override
  State<InstaClanFeedScreen> createState() => _InstaClanFeedScreenState();
}

class _InstaClanFeedScreenState extends State<InstaClanFeedScreen> {
  List<PostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final postService = Provider.of<PostService>(context, listen: false);
      _posts = await postService.getPosts(
        clanId: widget.clanId,
        federationId: widget.federationId,
      );
    } catch (e, st) {
      Logger.error('Error fetching posts', error: e, stackTrace: st);
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao carregar posts: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InstaClã Feed'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: () {
              // TODO: Implement navigation to create new post screen/dialog
              CustomSnackbar.showInfo(context, 'Funcionalidade de criar post em desenvolvimento.');
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum post encontrado. Seja o primeiro a postar!',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.grey[850],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (post.user != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: post.user!.avatar != null
                                        ? NetworkImage(post.user!.avatar!) as ImageProvider<Object>?
                                        : const AssetImage("assets/images_png/default_avatar.png"),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    post.user!.username,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          Image.network(
                            post.imageUrl,
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 250,
                              color: Colors.grey[700],
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              post.description,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Text(
                              '${post.createdAt.day}/${post.createdAt.month}/${post.createdAt.year} ${post.createdAt.hour}:${post.createdAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}



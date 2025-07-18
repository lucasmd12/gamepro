import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/post_service.dart';
import 'package:lucasbeatsfederacao/services/upload_service.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class InstaClanCreatePostScreen extends StatefulWidget {
  const InstaClanCreatePostScreen({super.key});

  @override
  State<InstaClanCreatePostScreen> createState() => _InstaClanCreatePostScreenState();
}

class _InstaClanCreatePostScreenState extends State<InstaClanCreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      CustomSnackbar.showError(context, 'Selecione uma imagem para o post.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uploadService = Provider.of<UploadService>(context, listen: false);
      final postService = Provider.of<PostService>(context, listen: false);

      String? imageUrl;
      final uploadResult = await uploadService.uploadMissionImage(File(_imageFile!.path));
      if (uploadResult['success'] == true && uploadResult['data'] != null) {
        imageUrl = uploadResult["data"][0]["url"];
      } else {
        Logger.error('Erro no upload da imagem: ${uploadResult['message']}');
        CustomSnackbar.showError(context, 'Erro no upload da imagem: ${uploadResult['message']}');
        setState(() => _isLoading = false);
        return;
      }

      final Map<String, dynamic> newPost = {
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
      };

      await postService.createPost(newPost);
      CustomSnackbar.showSuccess(context, 'Post criado com sucesso!');
      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      Logger.error('Erro ao criar post', error: e, stackTrace: st);
      CustomSnackbar.showError(context, 'Erro ao criar post: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Post'),
        backgroundColor: Colors.grey[900],
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _imageFile == null
                        ? ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Selecionar Imagem'),
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          )
                        : Column(
                            children: [
                              Image.file(File(_imageFile!.path), height: 200, fit: BoxFit.cover),
                              TextButton(onPressed: _pickImage, child: const Text('Trocar Imagem')),
                            ],
                          ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição (Opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _createPost,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Publicar Post', style: TextStyle(fontSize: 18)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


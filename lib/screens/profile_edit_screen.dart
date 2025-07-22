import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lucasbeatsfederacao/providers/auth_provider.dart';
import 'package:lucasbeatsfederacao/services/user_service.dart';
import 'package:lucasbeatsfederacao/services/upload_service.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:lucasbeatsfederacao/widgets/custom_snackbar.dart';
// CORREÇÃO: Importando o AuthService para acesso direto
import 'package:lucasbeatsfederacao/services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  XFile? _newProfileImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController = TextEditingController(text: authProvider.currentUser?.username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newProfileImage = image;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    final uploadService = Provider.of<UploadService>(context, listen: false);

    String? newAvatarUrl;
    if (_newProfileImage != null) {
      try {
        final uploadResult = await uploadService.uploadAvatar(File(_newProfileImage!.path));
        if (uploadResult['success'] == true && uploadResult['data'] != null) {
          newAvatarUrl = uploadResult["data"]["url"];
        } else {
          Logger.error('Erro no upload da imagem: ${uploadResult['message']}');
          CustomSnackbar.showError(context, 'Erro no upload da imagem: ${uploadResult['message']}');
          setState(() => _isLoading = false);
          return;
        }
      } catch (e, st) {
        Logger.error('Erro ao fazer upload da imagem de perfil', error: e, stackTrace: st);
        CustomSnackbar.showError(context, 'Erro ao fazer upload da imagem de perfil: ${e.toString()}');
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      final updatedUser = await userService.updateUserProfile(
        authService.currentUser!.id,
        username: _usernameController.text,
        avatar: newAvatarUrl,
      );

      if (updatedUser != null) {
        // ==================== INÍCIO DA CORREÇÃO ====================
        // Chamando o método correto para atualizar os dados do usuário no app
        await authService.fetchUserProfile();
        // ===================== FIM DA CORREÇÃO ======================
        
        CustomSnackbar.showSuccess(context, 'Perfil atualizado com sucesso!');
        if (mounted) Navigator.pop(context);
      } else {
        CustomSnackbar.showError(context, 'Falha ao atualizar o perfil.');
      }
    } catch (e, st) {
      Logger.error('Erro ao salvar perfil', error: e, stackTrace: st);
      CustomSnackbar.showError(context, 'Erro ao salvar perfil: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      // CORREÇÃO: Removido o 'const' do Scaffold
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.grey[900],
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(File(_newProfileImage!.path))
                            : (currentUser.avatar != null && currentUser.avatar!.isNotEmpty
                                ? NetworkImage(currentUser.avatar!)
                                : null) as ImageProvider?,
                        child: _newProfileImage == null && (currentUser.avatar == null || currentUser.avatar!.isEmpty)
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                    TextButton(onPressed: _pickImage, child: const Text('Alterar Foto de Perfil')),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome de Usuário',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira um nome de usuário';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Salvar Alterações', style: TextStyle(fontSize: 18)),
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

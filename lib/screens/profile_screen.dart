import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // For File class
import '../../services/upload_service.dart';
import '../../widgets/custom_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingProfile = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.fetchUserProfile();
    } catch (e) {
      Logger.error('Error loading user profile: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro ao carregar perfil: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _changeProfilePicture() async {
    try {
      final XFile? imageFile = await _picker.pickImage(source: ImageSource.gallery);

      if (imageFile == null) {
        return; // User cancelled
      }

      setState(() {
        _isUploading = true;
      });

      final uploadService = UploadService();
      final uploadResult = await uploadService.uploadAvatar(File(imageFile.path));

      if (uploadResult['success']) {
        Logger.info('Profile picture uploaded successfully: ${uploadResult['data']}');
        if (mounted) {
          CustomSnackbar.showSuccess(context, uploadResult['message'] ?? 'Foto de perfil atualizada!');
        }
        _loadUserProfile(); // Refresh profile data after upload
      } else {
        Logger.error('Profile picture upload failed: ${uploadResult['message']}');
        if (mounted) {
          CustomSnackbar.showError(context, uploadResult['message'] ?? 'Falha ao atualizar foto de perfil.');
        }
      }
    } catch (e) {
      Logger.error('Exception during profile picture upload: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Erro interno ao fazer upload da foto: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (_isLoadingProfile || authService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = authService.currentUser;
          if (user == null) {
            return const Center(
              child: Text(
                'Erro ao carregar dados do usuário',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUploading ? null : _changeProfilePicture,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey.shade700,
                              backgroundImage: user.avatar != null
                                  ? NetworkImage(user.avatar!)
                                  : null,
                              child: user.avatar == null
                                  ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                                  : null,
                            ),
                            if (_isUploading)
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                _buildInfoSection('Informações do Perfil', [
                  _buildInfoItem('ID do Usuário', user.id),
                  _buildInfoItem('Nome de Usuário', user.username),

                  if (user.clanName != null) _buildInfoItem('Clã', user.clanName!),
                  _buildInfoItem('Cargo no Clã', user.clanRole.toString()), // Convertendo Role para String
                  if (user.federationName != null) _buildInfoItem('Federação', user.federationName!),
                  if (user.federationTag != null) _buildInfoItem('Tag da Federação', user.federationTag!),
                  _buildInfoItem('Papel Global', user.role.toString()), // Convertendo Role para String
                  if (user.createdAt != null)
                    _buildInfoItem('Membro desde', _formatDate(user.createdAt!)),
                ]),

                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _loadUserProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Atualizar Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}


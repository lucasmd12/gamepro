import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../widgets/custom_snackbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionsAfterRegister() async {
    Logger.info("Requesting permissions after registration...");
    var statusNotification = await Permission.notification.request();
    Logger.info("Notification permission status: $statusNotification");
    var statusMicrophone = await Permission.microphone.request();
    Logger.info("Microphone permission status: $statusMicrophone");
    Logger.info("Initial permission requests completed.");
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      Logger.info('Attempting registration for username: $username');
      
      bool success = await authService.register(username, password);

      if (success) {
        Logger.info('Registration and auto-login successful for user: $username');
        await _requestPermissionsAfterRegister();
        
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Conta criada com sucesso! Bem-vindo!');
        }
      } else {
        if (mounted) {
          final errorMsg = authService.errorMessage ?? 'Falha no registro. Verifique os dados ou tente novamente.';
          CustomSnackbar.showError(context, errorMsg);
        }
      }
} catch (e) {
  Logger.error('Register Screen Error', error: e);
  if (mounted) {
    CustomSnackbar.showError(
      context,
      'Erro: ${e.toString().replaceFirst("Exception: ", "")}',
    );
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
    final textTheme = Theme.of(context).textTheme;
    final inputDecorationTheme = Theme.of(context).inputDecorationTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Registre-se',
                        textAlign: TextAlign.center,
                        style: textTheme.displayMedium,
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                        decoration: InputDecoration(
                          labelText: 'Usuário',
                          prefixIcon: const Icon(Icons.person_outline),
                          labelStyle: inputDecorationTheme.labelStyle,
                          prefixIconColor: inputDecorationTheme.prefixIconColor,
                          enabledBorder: inputDecorationTheme.enabledBorder,
                          focusedBorder: inputDecorationTheme.focusedBorder,
                          errorBorder: inputDecorationTheme.errorBorder,
                          focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira um nome de usuário';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelStyle: inputDecorationTheme.labelStyle,
                          prefixIconColor: inputDecorationTheme.prefixIconColor,
                          enabledBorder: inputDecorationTheme.enabledBorder,
                          focusedBorder: inputDecorationTheme.focusedBorder,
                          errorBorder: inputDecorationTheme.errorBorder,
                          focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira uma senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Gothic'),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelStyle: inputDecorationTheme.labelStyle,
                          prefixIconColor: inputDecorationTheme.prefixIconColor,
                          enabledBorder: inputDecorationTheme.enabledBorder,
                          focusedBorder: inputDecorationTheme.focusedBorder,
                          errorBorder: inputDecorationTheme.errorBorder,
                          focusedErrorBorder: inputDecorationTheme.focusedErrorBorder,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, confirme sua senha';
                          }
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                           backgroundColor: Theme.of(context).colorScheme.primary,
                           foregroundColor: Theme.of(context).colorScheme.onPrimary,
                           padding: const EdgeInsets.symmetric(vertical: 16),
                           textStyle: textTheme.labelLarge?.copyWith(fontFamily: 'Gothic'),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('REGISTRAR E ENTRAR'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

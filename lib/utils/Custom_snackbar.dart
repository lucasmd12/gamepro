import 'package:flutter/material.dart';

class CustomSnackbar {
  // Método para mostrar uma mensagem de sucesso (verde)
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.green.shade700);
  }

  // Método para mostrar uma mensagem de erro (vermelho)
  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.red.shade800);
  }

  // Método para mostrar uma mensagem de informação (azul)
  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.blue.shade700);
  }

  // Método privado que constrói e exibe o SnackBar
  static void _showSnackbar(BuildContext context, String message, Color backgroundColor) {
    // Remove qualquer SnackBar que já esteja na tela para evitar sobreposição
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Cria e exibe o novo SnackBar
    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating, // Flutua acima da barra de navegação
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: const EdgeInsets.all(10.0),
      duration: const Duration(seconds: 3), // Duração de 3 segundos
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

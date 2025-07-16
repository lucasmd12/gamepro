// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // Import ChangeNotifier
import 'package:lucasbeatsfederacao/utils/logger.dart';

class NotificationService extends ChangeNotifier {
  // Callback para chamadas recebidas
  Function(Map<String, dynamic>)? onIncomingCall;

  NotificationService();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configurações para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Configurações para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permissões
      await _requestPermissions();
      
      _initialized = true;
      Logger.info('Serviço de notificações inicializado');
    } catch (e) {
      Logger.error('Erro ao inicializar notificações: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Permissão para notificações
      final status = await Permission.notification.request();
      if (status.isGranted) {
        Logger.info('Permissão de notificação concedida');
      } else {
        Logger.warning('Permissão de notificação negada');
      }
    } catch (e) {
      Logger.error('Erro ao solicitar permissões: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.info('Notificação tocada: ${response.payload}');
    // Aqui você pode navegar para telas específicas baseado no payload
  }

  // Notificação de chamada recebida
  Future<void> showIncomingCallNotification({
    required String callerName,
    required String callId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'incoming_calls',
        'Chamadas Recebidas',
        channelDescription: 'Notificações de chamadas VoIP recebidas',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.call,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
        actions: [
          AndroidNotificationAction(
            'accept_call',
            'Aceitar',
            icon: DrawableResourceAndroidBitmap('ic_call_accept'),
          ),
          AndroidNotificationAction(
            'reject_call',
            'Rejeitar',
            icon: DrawableResourceAndroidBitmap('ic_call_reject'),
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        categoryIdentifier: 'incoming_call',
        interruptionLevel: InterruptionLevel.critical,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        callId.hashCode,
        'Chamada Recebida',
        '$callerName está chamando...',
        details,
        payload: 'incoming_call:$callId',
      );

      Logger.info('Notificação de chamada exibida para $callerName');
    } catch (e) {
      Logger.error('Erro ao exibir notificação de chamada: $e');
    }
  }

  // Notificação de nova mensagem
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String channelId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'messages',
        'Mensagens',
        channelDescription: 'Notificações de novas mensagens',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Nova mensagem de $senderName',
        message,
        details,
        payload: 'message:$channelId',
      );

      Logger.info('Notificação de mensagem exibida de $senderName');
    } catch (e) {
      Logger.error('Erro ao exibir notificação de mensagem: $e');
    }
  }

  // Notificação de sistema/admin
  Future<void> showSystemNotification({
    required String title,
    required String message,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'system',
        'Sistema',
        channelDescription: 'Notificações do sistema e administração',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        message,
        details,
        payload: payload ?? 'system',
      );

      Logger.info('Notificação de sistema exibida: $title');
    } catch (e) {
      Logger.error('Erro ao exibir notificação de sistema: $e');
    }
  }

  // Cancelar notificação específica
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      Logger.info('Notificação $id cancelada');
    } catch (e) {
      Logger.error('Erro ao cancelar notificação $id: $e');
    }
  }

  // Cancelar todas as notificações
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      Logger.info('Todas as notificações canceladas');
    } catch (e) {
      Logger.error('Erro ao cancelar todas as notificações: $e');
    }
  }

  // Verificar se as notificações estão habilitadas
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      Logger.error('Erro ao verificar status das notificações: $e');
      return false;
    }
  }
}



import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gamepro/services/api_service.dart'; // Import adicionado
import 'dart:async'; // Import adicionado

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService; // Instância do ApiService

  // Stream para notificar a UI sobre novas notificações
  final _onNotificationReceived = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationReceived => _onNotificationReceived.stream;

  NotificationService._privateConstructor(this._apiService); // Construtor modificado
  static final NotificationService _instance = NotificationService._privateConstructor(ApiService()); // Instância com ApiService

  factory NotificationService() {
    return _instance;
  }

  Future<void> initFirebaseMessaging() async {
    // Solicitar permissões de notificação
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Obter o token FCM
    String? fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    await sendFcmTokenToBackend(fcmToken); // Envia o token para o backend

    // Lidar com mensagens em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
      _onNotificationReceived.add(message);
    });

    // Lidar com mensagens quando o aplicativo é aberto a partir de uma notificação
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // TODO: Implementar navegação ou lógica específica ao abrir a notificação
    });

    // Lidar com mensagens quando o aplicativo está em segundo plano ou encerrado
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Handler para mensagens em segundo plano/encerrado
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Se você estiver usando outros serviços do Firebase em segundo plano, certifique-se de inicializá-los aqui
    // await Firebase.initializeApp();
    print('Handling a background message: ${message.messageId}');
    // TODO: Processar a notificação em segundo plano (ex: salvar no banco de dados local)
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Novos métodos para enviar notificações via backend
  Future<void> sendGlobalNotification(String title, String body) async {
    try {
      await _apiService.post('/api/notifications/global', {
        'title': title,
        'body': body,
      });
      print('Notificação global enviada com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar notificação global: $e');
      rethrow;
    }
  }

  Future<void> sendInviteNotification(String userId, String clanId) async {
    try {
      await _apiService.post('/api/notifications/invite', {
        'userId': userId,
        'clanId': clanId,
      });
      print('Convite de clã enviado com sucesso para o backend.');
    } catch (e) {
      print('Erro ao enviar convite de clã: $e');
      rethrow;
    }
  }

  Future<void> sendFcmTokenToBackend(String? fcmToken) async {
    if (fcmToken == null) return;
    try {
      await _apiService.post(
        '/api/users/fcm-token',
        {
          'fcmToken': fcmToken,
        },
      );
      print('FCM Token enviado para o backend com sucesso.');
    } catch (e) {
      print('Erro ao enviar FCM Token para o backend: $e');
      // Não rethrow aqui, pois não queremos que a falha no envio do token impeça o app de funcionar.
    }
  }

  void dispose() {
    _onNotificationReceived.close();
  }
}


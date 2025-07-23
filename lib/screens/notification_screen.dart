import 'package:flutter/material.dart';
import 'package:gamepro/models/notification_model.dart';
import 'package:gamepro/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  late StreamSubscription _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationSubscription = _notificationService.onNotificationReceived.listen((message) {
      // Convert RemoteMessage to NotificationModel
      final newNotification = NotificationModel(
        id: message.messageId ?? UniqueKey().toString(),
        title: message.notification?.title ?? ">Sem Título<",
        body: message.notification?.body ?? ">Sem Conteúdo<",
        type: message.data["type"] ?? "general",
        data: message.data,
        timestamp: message.sentTime ?? DateTime.now(),
        isRead: false,
      );
      setState(() {
        _notifications.insert(0, newNotification); // Adiciona no início para mostrar as mais recentes
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    // TODO: Implementar carregamento de notificações persistidas (se houver)
    // Por enquanto, vamos simular algumas notificações
    setState(() {
      _notifications = [
        NotificationModel(
          id: '1',
          title: 'Convite de Clã',
          body: 'Você foi convidado para o clã "Os Destemidos"!',
          type: 'clan_invite',
          data: {'clanId': 'clan123', 'clanName': 'Os Destemidos', 'senderName': 'Líder Supremo'},
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
          isRead: false,
        ),
        NotificationModel(
          id: '2',
          title: 'Nova Mensagem Global',
          body: 'Atenção, evento especial neste fim de semana!',
          type: 'global_message',
          data: {},
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          isRead: true,
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: _notifications.isEmpty
          ? const Center(child: Text('Nenhuma notificação por enquanto.'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: notification.isRead ? Colors.grey[800] : Colors.blueGrey[700],
                  child: ListTile(
                    leading: Icon(
                      _getNotificationIcon(notification.type),
                      color: Colors.white,
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(color: Colors.white, fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Text(
                      notification.body,
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: notification.type == 'clan_invite'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () {
                                  // TODO: Implementar lógica de aceitar convite
                                  _handleInviteAction(notification, true);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () {
                                  // TODO: Implementar lógica de rejeitar convite
                                  _handleInviteAction(notification, false);
                                },
                              ),
                            ],
                          )
                        : null,
                    onTap: () {
                      // TODO: Marcar notificação como lida e navegar para detalhes (se aplicável)
                      setState(() {
                        notification.isRead = true;
                      });
                      _handleNotificationTap(notification);
                    },
                  ),
                );
              },
            ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'clan_invite':
        return Icons.group_add;
      case 'global_message':
        return Icons.campaign;
      case 'clan_message':
        return Icons.groups;
      case 'federation_message':
        return Icons.public;
      case 'new_message':
        return Icons.message;
      case 'incoming_call':
        return Icons.call;
      default:
        return Icons.notifications;
    }
  }

  void _handleInviteAction(NotificationModel notification, bool accept) {
    // Lógica para aceitar ou rejeitar convite
    print('Convite para ${notification.data?['clanName']} ${accept ? 'aceito' : 'rejeitado'}');
    // Remover notificação da lista após ação
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
    // TODO: Enviar requisição ao backend para aceitar/rejeitar
  }

  void _handleNotificationTap(NotificationModel notification) {
    print('Notificação clicada: ${notification.title}');
    // TODO: Implementar navegação para a tela relevante com base no tipo de notificação
  }
}



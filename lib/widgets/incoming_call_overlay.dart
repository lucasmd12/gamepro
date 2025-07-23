import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
// import 'package:lucasbeatsfederacao/services/notification_service.dart'; // ✅ AÇÃO 2: REMOVIDO IMPORT NÃO UTILIZADO
import 'package:lucasbeatsfederacao/services/socket_service.dart'; // ✅ AÇÃO 1: ADICIONADO O IMPORT QUE FALTAVA
import 'package:lucasbeatsfederacao/screens/call_page.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class IncomingCallOverlay extends StatefulWidget {
  final Widget child;

  const IncomingCallOverlay({
    super.key,
    required this.child,
  });

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  Map<String, dynamic>? _incomingCallData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupIncomingCallListener();
    });
  }

  void _setupIncomingCallListener() {
    if (!mounted) return;
    final voipService = Provider.of<VoIPService>(context, listen: false);
    voipService.setCallbacks(
      onCallStarted: (roomId) {
        // Não precisamos fazer nada aqui, pois a UI de chamada já será exibida pela CallPage
      },
      onCallEnded: (roomId) {
        _dismissOverlay();
      },
    );

    // Temporariamente, vamos usar o `SocketService.incomingCallStream` diretamente aqui
    // para que o overlay possa reagir. Idealmente, o VoIPService deveria orquestrar isso.
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.incomingCallStream.listen((callData) {
      Logger.info("IncomingCallOverlay: Received incoming call via Socket: $callData");
      if (mounted) {
        setState(() {
          _incomingCallData = callData;
        });
      }
    });
  }

  void _dismissOverlay() {
    if (mounted) {
      setState(() {
        _incomingCallData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_incomingCallData != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _CallNotificationWidget(
                callId: _incomingCallData!["callId"],
                callerId: _incomingCallData!["callerId"],
                callerName: _incomingCallData!["callerName"],
                roomName: _incomingCallData!["roomName"],
                onDismiss: _dismissOverlay,
              ),
            ),
        ],
      ),
    );
  }
}

class _CallNotificationWidget extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String roomName;
  final VoidCallback onDismiss;

  const _CallNotificationWidget({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.roomName,
    required this.onDismiss,
  });

  @override
  State<_CallNotificationWidget> createState() => _CallNotificationWidgetState();
}

class _CallNotificationWidgetState extends State<_CallNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _slideController.forward();

    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _rejectCall();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _acceptCall() async {
    if (!mounted) return;
    
    final voipService = Provider.of<VoIPService>(context, listen: false);

    try {
      await voipService.acceptCall(
        callId: widget.callId,
        displayName: widget.callerName,
        roomId: widget.roomName,
      );
    } catch (e) {
      Logger.error('Error accepting call: $e');
      _rejectCall();
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CallPage(
            contactId: widget.callerId,
            roomName: widget.roomName,
            contactName: widget.callerName,
          ),
        ),
      );
    }

    widget.onDismiss();
  }

  void _rejectCall() async {
    if (!mounted) return;
    
    try {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      await voipService.rejectCall(callId: widget.callId);
    } catch (e) {
      Logger.error('Error rejecting call: $e');
    } finally {
      if (mounted) {
        widget.onDismiss();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.95),
                Colors.black.withOpacity(0.85),
              ],
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.7),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.call, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('Chamada recebida', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      GestureDetector(
                        onTap: _rejectCall,
                        child: const Icon(Icons.close, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue.shade400,
                              child: const Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            const Text('Chamada de voz', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          FloatingActionButton(
                            heroTag: 'reject_call',
                            onPressed: _rejectCall,
                            backgroundColor: Colors.red,
                            mini: true,
                            child: const Icon(Icons.call_end, color: Colors.white),
                          ),
                          const SizedBox(width: 24),
                          FloatingActionButton(
                            heroTag: 'accept_call',
                            onPressed: _acceptCall,
                            backgroundColor: Colors.green,
                            child: const Icon(Icons.call, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

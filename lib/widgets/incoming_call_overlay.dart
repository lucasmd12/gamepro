import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucasbeatsfederacao/services/voip_service.dart';
import 'package:lucasbeatsfederacao/services/notification_service.dart';
import 'package:lucasbeatsfederacao/screens/call_page.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';

class IncomingCallOverlay extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String roomName;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.roomName,
    required this.onDismiss,
  });

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
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
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _slideController.forward();

    // Auto-dismiss after 30 seconds
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.9),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.call,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chamada recebida',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _rejectCall,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Caller info and controls
                  Expanded(
                    child: Row(
                      children: [
                        // Avatar with pulse animation
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 16),

                        // Caller name and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.callerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Chamada de voz',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            // Reject button
                            GestureDetector(
                              onTap: _rejectCall,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                                child: const Icon(
                                  Icons.call_end,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Accept button
                            GestureDetector(
                              onTap: _acceptCall,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                child: const Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _acceptCall() async {
    final voipService = Provider.of<VoIPService>(context, listen: false);

    try {
      // CORREÇÃO APLICADA AQUI:
      // Adicionados os parâmetros 'displayName' e 'roomId' que estavam faltando.
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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            contactId: widget.callerId,
            roomName: widget.roomName,
          ),
        ),
      );
    }

    widget.onDismiss();
  }

  void _rejectCall() async {
    try {
      final voipService = Provider.of<VoIPService>(context, listen: false);
      await voipService.rejectCall(callId: widget.callId);
    } catch (e) {
      Logger.error('Error rejecting call: $e');
    } finally {
      widget.onDismiss();
    }
  }
}

// Widget para mostrar overlay de chamada recebida
class IncomingCallManager extends StatefulWidget {
  final Widget child;

  const IncomingCallManager({
    super.key,
    required this.child,
  });

  @override
  State<IncomingCallManager> createState() => _IncomingCallManagerState();
}

class _IncomingCallManagerState extends State<IncomingCallManager> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _setupIncomingCallListener();
  }

  void _setupIncomingCallListener() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    notificationService.onIncomingCall = (data) {
      final String callId = data["callId"];
      final String callerId = data["callerId"];
      final String callerName = data["callerName"];
      final String roomName = data["roomName"];
      _showIncomingCallOverlay(callId, callerId, callerName, roomName);
    };
  }

  void _showIncomingCallOverlay(String callId, String callerId, String callerName, String roomName) {
    if (_overlayEntry != null) {
      _dismissOverlay();
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: IncomingCallOverlay(
          callId: callId,
          callerId: callerId,
          callerName: callerName,
          roomName: roomName,
          onDismiss: _dismissOverlay,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _dismissOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

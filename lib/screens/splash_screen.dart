import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucasbeatsfederacao/utils/logger.dart';
import 'package:audioplayers/audioplayers.dart' as ap; // Alias para audioplayers
import 'package:lucasbeatsfederacao/screens/login_screen.dart';
import 'package:lucasbeatsfederacao/screens/home_screen.dart'; // Importar HomeScreen
import 'dart:math';
import 'package:just_audio/just_audio.dart' as ja; // Alias para just_audio
import 'package:provider/provider.dart'; // Importar Provider
import 'package:lucasbeatsfederacao/services/auth_service.dart'; // Importar AuthService

class SplashScreen extends StatefulWidget {
  final bool showIndicator;
  final Duration duration;
  
  const SplashScreen({
    super.key, 
    this.showIndicator = true,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer(); // Usando alias
  late ja.AudioPlayer _musicPlayer; // Usando alias
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late AnimationController _gunshotEffectController;
  late Animation<double> _brightnessAnimation;
  late AnimationController _particleAnimationController;

  List<Particle> particles = [];
  final Random random = Random();
  static const int numberOfParticles = 100;

  double _loadingProgress = 0.0;
  Timer? _progressTimer;


// Simulação de autenticação - DEVE SER SUBSTITUÍDA PELA LÓGICA REAL
  Future<bool> _checkAuthentication() async {
    Logger.info("Verificando autenticação...");
    final authService = Provider.of<AuthService>(context, listen: false);
 await authService.fetchUserProfile(); // Tenta carregar o usuário logado
    return authService.currentUser != null; // Retorna true se houver um usuário logado
  }

  @override
  void initState() {
    super.initState();
    Logger.info("SplashScreen initialized. Indicator: ${widget.showIndicator}");

    _musicPlayer = ja.AudioPlayer(); // Usando alias
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _gunshotEffectController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _brightnessAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _gunshotEffectController,
      curve: Curves.easeInOut,
    ));
    
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // _generateParticles() será chamada após a primeira renderização para garantir o context

    _startSplashSequence();
 _startProgressSimulation();

  }

  // Movido para ser chamado após a primeira renderização
  void _generateParticles(BuildContext context) {
    if (particles.isEmpty) { // Gerar partículas apenas uma vez
      particles = List.generate(numberOfParticles, (index) {
        return Particle(position: Offset(random.nextDouble() * MediaQuery.of(context).size.width, random.nextDouble() * MediaQuery.of(context).size.height), size: random.nextDouble() * 1.5 + 0.5, speed: random.nextDouble() * 0.5 + 0.3, opacity: random.nextDouble() * 0.5 + 0.3);
      });
    }
  }


  Future<void> _startSplashSequence() async {
    _fadeController.forward();
    _scaleController.forward();
    
    await _playSplashSound();

    await Future.delayed(const Duration(milliseconds: 500));

    _playGunshotSound();
    _gunshotEffectController.forward(from: 0.0);

    await Future.delayed(const Duration(milliseconds: 300));

    await _startBackgroundMusic();

    bool isAuthenticated = (await Future.wait([
      _checkAuthentication(),
      Future.delayed(const Duration(seconds: 14)), // Duração mínima da splash screen
    ]))[0];

    await _fadeOutBackgroundMusic();

    _navigateToNextScreen(isAuthenticated);}
   void _navigateToNextScreen(bool isAuthenticated) {
     Logger.info("Navegando. Autenticado: $isAuthenticated");
     if (!mounted) {
       Logger.warning("Widget não montado. Não é possível navegar.");
       return;
     }

 Navigator.pushReplacement(
 context,
      PageRouteBuilder(
 pageBuilder: (context, animation, secondaryAnimation) =>
 isAuthenticated ? const HomeScreen() : const LoginScreen(),
 transitionsBuilder: (context, animation, secondaryAnimation, child) {
 return FadeTransition(
 opacity: animation,
 child: child,
 );
 },
 transitionDuration: const Duration(milliseconds: 800), // Duração da animação
 ),
 );
   }

void _startProgressSimulation() {
  if (!widget.showIndicator) return;

  const totalDuration = Duration(seconds: 14);
  const updateInterval = Duration(milliseconds: 100);
  final totalTicks = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds;

  int currentTick = 0;

  _progressTimer = Timer.periodic(updateInterval, (timer) {
    setState(() {
      _loadingProgress = currentTick / totalTicks;
      currentTick++;

      if (_loadingProgress >= 1.0) {
        _loadingProgress = 1.0;
        timer.cancel();
      }
    });
  });
}

  Future<void> _playSplashSound() async {
    try {
      Logger.info("Reproduzindo som de inicialização...");
      await _audioPlayer.setReleaseMode(ap.ReleaseMode.stop); // Usando alias

      await _audioPlayer.play(ap.AssetSource("audio/splash_sound.mp3")); // Usando alias
      Logger.info("Som de inicialização reproduzido com sucesso.");
    } catch (e, stackTrace) {
      Logger.error("Falha ao reproduzir som de inicialização", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _playGunshotSound() async {
     try {
      Logger.info("Reproduzindo som de tiro...");
      await _audioPlayer.setReleaseMode(ap.ReleaseMode.stop); // Usando alias
      await _audioPlayer.play(ap.AssetSource("audio/gunshot.mp3")); // Usando alias
      Logger.info("Som de tiro reproduzido com sucesso.");
    } catch (e, stackTrace) {
      Logger.error("Falha ao reproduzir som de tiro", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _startBackgroundMusic() async {
    try {
      Logger.info("Iniciando música de fundo...");
       await _musicPlayer.setAsset("assets/audio/intro_music.mp3");
      _musicPlayer.setLoopMode(ja.LoopMode.one); // Usando alias
      _musicPlayer.play();
      Logger.info("Música de fundo iniciada com sucesso.");
    } catch (e, stackTrace) {
      Logger.error("Falha ao iniciar música de fundo", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _fadeOutBackgroundMusic() async {
    try {
       Logger.info("Fazendo fade out da música de fundo...");
        if (_musicPlayer.playerState.playing) {
           for (double vol = _musicPlayer.volume; vol > 0; vol -= 0.05) {
          await _musicPlayer.setVolume(vol);
          await Future.delayed(const Duration(milliseconds: 50));


        }
        await _musicPlayer.stop();
       Logger.info("Fade out da música de fundo concluído.");
    }
    } catch (e, stackTrace) {
      Logger.error("Falha ao fazer fade out da música de fundo", error: e, stackTrace: stackTrace);
    }
  }




  @override
  void dispose() {
     _gunshotEffectController.dispose();
     _particleAnimationController.dispose();
    Logger.info("Disposing SplashScreen...");
    _progressTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    _audioPlayer.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Chamar _generateParticles aqui para garantir que o context esteja pronto
    _generateParticles(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images_png/background_splash.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              Logger.error("Falha ao carregar imagem de background", error: error, stackTrace: stackTrace);
              return Container(
                color: Colors.black,
              );
            },
          ),

           Container(
             color: Colors.black.withOpacity(0.5),
           ),

          AnimatedBuilder(
            animation: _gunshotEffectController,
            builder: (context, child) {
              return Opacity(
                opacity: _brightnessAnimation.value,
                child: Container(
                   color: Colors.white.withOpacity(0.3),
                ),
              );
            },
          ),

            AnimatedBuilder(
              animation: _particleAnimationController,
               builder: (context, child) {
                 return CustomPaint(
                   painter: ParticlePainter(_particleAnimationController.value, particles),
                 );
               },
            ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images_png/app_logo.png',
                            height: 120,
                            width: 120,
                            errorBuilder: (context, error, stackTrace) {
                              Logger.error("Falha ao carregar logo", error: error, stackTrace: stackTrace);
                              return Container(
                                height: 120,
                                width: 120,
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shield,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'VOX MAD',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.purple.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Comunicação e organização para o clã',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                if (widget.showIndicator) 
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          value: _loadingProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          backgroundColor: Colors.grey[700],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Carregando recursos... ${(_loadingProgress * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  double size;
  double speed;
  double opacity;

  Particle({required this.position, required this.size, required this.speed, required this.opacity});
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  final List<Particle> particles;

  ParticlePainter(this.animationValue, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (var particle in particles) {
      // Mover a partícula (simulando movimento para cima)
      final newY = particle.position.dy - (particle.speed * animationValue * 100); // Multiplicar para efeito mais visível
      final newPosition = Offset(particle.position.dx, newY % size.height); // Resetar posição Y ao sair da tela

      paint.color = paint.color.withOpacity(particle.opacity); // Aplicar opacidade
      canvas.drawCircle(newPosition, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}




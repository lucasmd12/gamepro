import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';

class AnimationShowcaseScreen extends StatefulWidget {
  const AnimationShowcaseScreen({super.key});

  @override
  State<AnimationShowcaseScreen> createState() => _AnimationShowcaseScreenState();
}

class _AnimationShowcaseScreenState extends State<AnimationShowcaseScreen>
    with TickerProviderStateMixin {
  bool _isLiked = false;
  bool _isExpanded = false;
  late AnimationController _customAnimationController;
  late Animation<double> _customAnimation;

  @override
  void initState() {
    super.initState();
    _customAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _customAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _customAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _customAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo de Animações'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Micro-interações com AnimatedSwitcher
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Micro-interações (AnimatedSwitcher)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Curtir jogador: '),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLiked = !_isLiked;
                            });
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(_isLiked),
                              color: _isLiked ? Colors.red : Colors.grey,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Transições de Layout com AnimatedContainer
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Transições de Layout (AnimatedContainer)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: _isExpanded ? 200 : 80,
                        decoration: BoxDecoration(
                          color: _isExpanded ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isExpanded ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.group),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Clã dos Guerreiros',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ],
                              ),
                              if (_isExpanded) ...[
                                const SizedBox(height: 16),
                                const Text('Membros: 25'),
                                const Text('Ranking: #3'),
                                const Text('Última batalha: Há 2 horas'),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('Entrar no Clã'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Hero Transitions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. Hero Transitions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DetailPage(),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Hero(
                            tag: 'clan_avatar',
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.shield,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Federação Alpha',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Toque para ver detalhes'),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Page Transitions com animations package
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4. Page Transitions (animations package)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OpenContainer(
                      transitionType: ContainerTransitionType.fade,
                      transitionDuration: const Duration(milliseconds: 500),
                      openBuilder: (context, action) => const BattlePage(),
                      closedBuilder: (context, action) => Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Iniciar Batalha',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Animações Explícitas com AnimationController
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '5. Animações Explícitas (AnimationController)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _customAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.5 + (_customAnimation.value * 0.5),
                                child: Transform.rotate(
                                  angle: _customAnimation.value * 2 * 3.14159,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.yellow,
                                          Colors.orange.withAlpha((255 * _customAnimation.value).round()),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(_customAnimation.value * 0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5, // Adjust spreadRadius as needed
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_customAnimationController.isCompleted) {
                                _customAnimationController.reset();
                              } else {
                                _customAnimationController.forward();
                              }
                            },
                            child: const Text('Vitória Épica!'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Flutter Animate Package
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '6. Flutter Animate Package',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.emoji_events, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Novo membro entrou no clã!'),
                            ],
                          ),
                        )
                            .animate()
                            .slideX(
                              begin: 1,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(delay: const Duration(milliseconds: 200)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_up, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('Ranking do clã subiu!'),
                            ],
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              duration: const Duration(milliseconds: 400),
                            )
                            .shimmer(
                              delay: const Duration(milliseconds: 600),
                              duration: const Duration(milliseconds: 1000),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Federação'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Hero(
              tag: 'clan_avatar',
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Federação Alpha',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Membros: 150'),
                    Text('Clãs: 6'),
                    Text('Ranking Global: #1'),
                    Text('Fundada em: Janeiro 2024'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BattlePage extends StatelessWidget {
  const BattlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arena de Batalha'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flash_on,
              size: 100,
              color: Colors.red,
            ),
            SizedBox(height: 24),
            Text(
              'Batalha Iniciada!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text('Prepare-se para o combate...'),
          ],
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Placeholder data for the three onboarding cards.
class _CardData {
  final String title;
  final IconData icon;
  final Color color;
  const _CardData(this.title, this.icon, this.color);
}

const _cards = [
  _CardData('Scan Crop Leaf', Icons.camera_alt_rounded, Color(0xFF66BB6A)),
  _CardData('AI Analysis', Icons.psychology_rounded, Color(0xFF42A5F5)),
  _CardData('Solutions & Remedies', Icons.local_florist_rounded, Color(0xFFFFA726)),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late final AnimationController _anim;
  late Animation<double> _slide;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resetAnimations();
    _autoAdvance();
  }

  void _resetAnimations() {
    _slide = Tween<double>(begin: 0, end: -1.2).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
    _rotate = Tween<double>(begin: 0, end: -0.08).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeIn),
    );
  }

  Future<void> _autoAdvance() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      await _anim.forward();
      if (!mounted) return;
      setState(() => _current = (_current + 1) % _cards.length);
      _anim.reset();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top 80 %: card stack ──
            Expanded(
              flex: 8,
              child: Center(
                child: SizedBox(
                  width: size.width * 0.82,
                  height: size.height * 0.50,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (ctx, _) => _buildStack(size),
                  ),
                ),
              ),
            ),

            // ── Progress dots ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_cards.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: active ? 28 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.primaryGreen
                        : AppTheme.accentGreen.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),

            // ── Bottom 20 %: CTA ──
            Expanded(
              flex: 2,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 6,
                        shadowColor:
                            AppTheme.primaryGreen.withValues(alpha: 0.4),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStack(Size size) {
    final List<Widget> layers = [];

    // Background cards (drawn first → behind)
    for (int offset = 2; offset >= 1; offset--) {
      final idx = (_current + offset) % _cards.length;
      final scale = 1.0 - offset * 0.06;
      final yShift = offset * 14.0;

      layers.add(
        Transform.translate(
          offset: Offset(0, -yShift),
          child: Transform.scale(
            scale: scale,
            child: _card(_cards[idx]),
          ),
        ),
      );
    }

    // Front card (animated swipe)
    layers.add(
      AnimatedBuilder(
        animation: _anim,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(_slide.value * size.width, 0),
            child: Transform.rotate(
              angle: _rotate.value,
              child: _card(_cards[_current]),
            ),
          );
        },
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: layers,
    );
  }

  Widget _card(_CardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            data.color,
            data.color.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// AnimatedBuilder is just an alias for AnimatedWidget-style usage.
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, null);
}

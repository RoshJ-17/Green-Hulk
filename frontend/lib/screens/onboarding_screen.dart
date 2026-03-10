import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

/// Placeholder data for the three onboarding cards.
class _CardData {
  final String titleKey; // localization key
  final String imagePath;
  final bool blendSides;
  const _CardData(this.titleKey, this.imagePath, {this.blendSides = false});
}

const _cards = [
  _CardData('onboard_scan_leaf', 'assets/images/onboarding_scan_leaf.png'),
  _CardData(
    'onboard_ai_analysis',
    'assets/images/onboarding_ai_analysis.png',
    blendSides: true,
  ),
  _CardData(
    'onboard_solutions',
    'assets/images/onboarding_solutions.png',
    blendSides: true,
  ),
];

const String _backgroundImagePath = 'assets/images/onboarding_background.png';
const String _cropCareLogoPath = 'assets/app_icon.png';

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
    final appState = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundImagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.cream),
          ),
          // A light white mask to soften brightness without washing out detail.
          Container(color: Colors.white.withValues(alpha: 0.18)),
          SafeArea(
            child: Column(
              children: [
                // Top 80%: card stack
                Expanded(
                  flex: 8,
                  child: Center(
                    child: SizedBox(
                      width: size.width * 0.82,
                      height: size.height * 0.50,
                      child: AnimatedBuilder(
                        animation: _anim,
                        builder: (ctx, _) => _buildStack(size, appState),
                      ),
                    ),
                  ),
                ),

                // Progress dots
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
                            : AppTheme.accentGreen.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),

                // Bottom 20%: CTA with separator rectangle under the button
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 24,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.95),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 12,
                          child: SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 7,
                                shadowColor:
                                    AppTheme.primaryGreen.withValues(alpha: 0.35),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    appState.tr('get_started'),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStack(Size size, AppState appState) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(_slide.value * size.width, 0),
          child: Transform.rotate(
            angle: _rotate.value,
            child: _card(_cards[_current], appState),
          ),
        );
      },
    );
  }

  Widget _card(_CardData data, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.92),
          width: 1.6,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // For small-width artwork, fill side gaps with a blurred
                  // version of the same image so it blends naturally.
                  if (data.blendSides)
                    ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Image.asset(
                        data.imagePath,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.low,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  if (data.blendSides)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      data.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_not_supported, size: 56),
                      ),
                    ),
                  ),
                  // Crop care logo overlay: bottom-right, ~1/16 of image area.
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortest = constraints.biggest.shortestSide;
                        final logoSize = (shortest * 0.25).clamp(28.0, 54.0);
                        return Container(
                          width: logoSize,
                          height: logoSize,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            _cropCareLogoPath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.spa,
                              size: 18,
                              color: Color(0xFF1D5A2E),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            appState.tr(data.titleKey),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D5A2E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}



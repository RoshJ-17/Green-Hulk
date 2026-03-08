import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';

/// Language data model
class _LangItem {
  final String name;     // native name
  final String code;     // locale code
  final String langWord; // "Language" in that language
  final String desc;     // description sentence
  const _LangItem(this.name, this.code, this.langWord, this.desc);
}

const _languages = [
  _LangItem('English', 'en', 'Language',
      'You are choosing English as your preferred language, the app will proceed in English from here on.'),
  _LangItem('हिन्दी', 'hi', 'भाषा',
      'आप हिन्दी को अपनी पसंदीदा भाषा के रूप में चुन रहे हैं, ऐप यहाँ से हिन्दी में आगे बढ़ेगा।'),
  _LangItem('தமிழ்', 'ta', 'மொழி',
      'நீங்கள் தமிழை உங்கள் விருப்ப மொழியாக தேர்வு செய்கிறீர்கள், பயன்பாடு இங்கிருந்து தமிழில் தொடரும்.'),
  _LangItem('తెలుగు', 'te', 'భాష',
      'మీరు తెలుగును మీ ఇష్టమైన భాషగా ఎంచుకుంటున్నారు, యాప్ ఇక్కడి నుండి తెలుగులో కొనసాగుతుంది.'),
  _LangItem('ಕನ್ನಡ', 'kn', 'ಭಾಷೆ',
      'ನೀವು ಕನ್ನಡವನ್ನು ನಿಮ್ಮ ಆದ್ಯತೆಯ ಭಾಷೆಯಾಗಿ ಆಯ್ಕೆ ಮಾಡುತ್ತಿದ್ದೀರಿ, ಅಪ್ಲಿಕೇಶನ್ ಇಲ್ಲಿಂದ ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಯುತ್ತದೆ.'),
  _LangItem('বাংলা', 'bn', 'ভাষা',
      'আপনি বাংলাকে আপনার পছন্দের ভাষা হিসেবে বেছে নিচ্ছেন, অ্যাপটি এখান থেকে বাংলায় এগিয়ে যাবে।'),
  _LangItem('ਪੰਜਾਬੀ', 'pa', 'ਭਾਸ਼ਾ',
      'ਤੁਸੀਂ ਪੰਜਾਬੀ ਨੂੰ ਆਪਣੀ ਪਸੰਦੀਦਾ ਭਾਸ਼ਾ ਵਜੋਂ ਚੁਣ ਰਹੇ ਹੋ, ਐਪ ਇੱਥੋਂ ਪੰਜਾਬੀ ਵਿੱਚ ਅੱਗੇ ਵਧੇਗੀ।'),
];

class LanguageSelectionScreen extends StatefulWidget {
  final Function(Locale) onLanguageSelected;
  const LanguageSelectionScreen({super.key, required this.onLanguageSelected});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final PageController _pageController;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pageController = PageController(
      viewportFraction: 0.35,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final lang = _languages[_selected];

    // Update AppState (rebuilds MaterialApp.locale immediately)
    if (mounted) {
      context.read<AppState>().changeLanguage(lang.code);
    }

    // Also call the legacy callback if provided
    widget.onLanguageSelected(Locale(lang.code));

    // Mark that the user has gone through language selection at least once
    await AppState.markLanguageSelected();

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final lang = _languages[_selected];

    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 36),

            // ── Spinning Globe ──
            RotationTransition(
              turns: _spinController,
              child: const Text('🌐', style: TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 12),

            // ── Dynamic "Language" word ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Text(
                lang.langWord,
                key: ValueKey(lang.code),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Carousel ──
            SizedBox(
              height: 80,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _languages.length,
                onPageChanged: (i) => setState(() => _selected = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (ctx, i) {
                  final isCentre = i == _selected;
                  return AnimatedScale(
                    scale: isCentre ? 1.2 : 0.85,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: AnimatedOpacity(
                      opacity: isCentre ? 1.0 : 0.45,
                      duration: const Duration(milliseconds: 300),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isCentre
                                ? AppTheme.primaryGreen
                                : Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: AppTheme.primaryGreen
                                  .withValues(alpha: isCentre ? 1 : 0.3),
                              width: 2,
                            ),
                            boxShadow: isCentre
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGreen
                                          .withValues(alpha: 0.35),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            _languages[i].name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isCentre
                                  ? Colors.white
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ── Dots ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_languages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _selected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _selected
                        ? AppTheme.primaryGreen
                        : AppTheme.accentGreen.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const Spacer(),

            // ── Description Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey(lang.code),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        lang.desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      if (lang.code != 'en') ...[
                        const SizedBox(height: 8),
                        Text(
                          'You are choosing ${lang.name} as your preferred language.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Confirm Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 4,
                  ),
                  child: const Text(
                    '✓  Confirm',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

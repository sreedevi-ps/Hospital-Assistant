import 'package:flutter/material.dart';
import 'package:flutter/animation.dart' show CurvedAnimation, AnimationController;
import 'package:flutter/scheduler.dart' show TickerProvider;
import 'package:collection/collection.dart'; // For firstOrNull
import '../../../core/theme/app_theme.dart';
import '../../../features/interaction_flow/interaction_coordinator.dart';

class MenuScreen extends StatefulWidget {
  final Function(String) onTileTap;
  final InteractionCoordinator coordinator;

  const MenuScreen({super.key, required this.onTileTap, required this.coordinator});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  String _selectedLanguage = "ml_IN";

  // Multilingual tile labels
  final Map<String, List<Map<String, dynamic>>> _tileData = {
    "ml_IN": [
      {'title': 'എനിക്ക് എങ്ങനെ സഹായിക്കാം?', 'color': const Color(0xFF0288D1), 'icon': Icons.mic},
      {'title': 'ചെക്ക്-ഇൻ / രജിസ്ട്രേഷൻ', 'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle},
      {'title': 'നിയമനം / പുനഃക്രമീകരണം', 'color': const Color(0xFF1976D2), 'icon': Icons.calendar_today},
      {'title': 'ഫാർമസി ടോക്കൺ', 'color': const Color(0xFF00695C), 'icon': Icons.local_pharmacy},
      {'title': 'ഇൻഷുറൻസ് ', 'color': const Color(0xFFF57C00), 'icon': Icons.shield},
      {'title': 'ബിൽ പേയ്‌മെന്റ്', 'color': const Color(0xFFFFA000), 'icon': Icons.payment},
      {'title': 'ലാബ് & റേഡിയോളജി ഫലങ്ങൾ', 'color': const Color(0xFF6A1B9A), 'icon': Icons.receipt},
      {'title': 'ആശുപത്രി മാപ് & വഴികാട്ടൽ', 'color': const Color(0xFF00BCD4), 'icon': Icons.map},
      {'title': 'ക്യൂ സ്റ്റാറ്റസ്', 'color': const Color(0xFFCDDC39), 'icon': Icons.access_time},
      {'title': 'വെർച്വൽ റിസപ്ഷൻ', 'color': const Color(0xFFE91E63), 'icon': Icons.video_call},
      {'title': 'പുതിയ രോഗി / സന്ദർശക പാസ്', 'color': const Color(0xFF795548), 'icon': Icons.person_add},
      {'title': 'ഫീഡ്ബാക്ക് & സഹായം', 'color': const Color(0xFF9E9E9E), 'icon': Icons.feedback},
    ],
    "ta_IN": [
      {'title': 'எப்படி உதவ முடியும்?', 'color': const Color(0xFF0288D1), 'icon': Icons.mic},
      {'title': 'செக்-இன் / பதிவு', 'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle},
      {'title': 'நியமனம் / மறுசீரமைப்பு', 'color': const Color(0xFF1976D2), 'icon': Icons.calendar_today},
      {'title': 'மருந்தக டோக்கன்', 'color': const Color(0xFF00695C), 'icon': Icons.local_pharmacy},
      {'title': 'இன்சூரன்ஸ்', 'color': const Color(0xFFF57C00), 'icon': Icons.shield},
      {'title': 'பில் பணம் செலுத்துதல்', 'color': const Color(0xFFFFA000), 'icon': Icons.payment},
      {'title': 'லேப் & ரேடியாலஜி முடிவுகள்', 'color': const Color(0xFF6A1B9A), 'icon': Icons.receipt},
      {'title': 'ஆஸ்பத்திரி மேப் & வழிகாட்டி', 'color': const Color(0xFF00BCD4), 'icon': Icons.map},
      {'title': 'கியூ நிலை', 'color': const Color(0xFFCDDC39), 'icon': Icons.access_time},
      {'title': 'வெர்ச்சுவல் ரெசப்ஷன்', 'color': const Color(0xFFE91E63), 'icon': Icons.video_call},
      {'title': 'புதிய நோயாளி / பார்வையாளர் பாஸ்', 'color': const Color(0xFF795548), 'icon': Icons.person_add},
      {'title': 'பீட்பேக் & உதவி', 'color': const Color(0xFF9E9E9E), 'icon': Icons.feedback},
    ],
    "en_US": [
      {'title': 'How Can I Help You?', 'color': const Color(0xFF0288D1), 'icon': Icons.mic},
      {'title': 'Check-In / Registration', 'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle},
      {'title': 'Appointment / Rescheduling', 'color': const Color(0xFF1976D2), 'icon': Icons.calendar_today},
      {'title': 'Pharmacy Token', 'color': const Color(0xFF00695C), 'icon': Icons.local_pharmacy},
      {'title': 'Insurance', 'color': const Color(0xFFF57C00), 'icon': Icons.shield},
      {'title': 'Bill Payment', 'color': const Color(0xFFFFA000), 'icon': Icons.payment},
      {'title': 'Lab & Radiology Results', 'color': const Color(0xFF6A1B9A), 'icon': Icons.receipt},
      {'title': 'Hospital Map & Guidance', 'color': const Color(0xFF00BCD4), 'icon': Icons.map},
      {'title': 'Queue Status', 'color': const Color(0xFFCDDC39), 'icon': Icons.access_time},
      {'title': 'Virtual Reception', 'color': const Color(0xFFE91E63), 'icon': Icons.video_call},
      {'title': 'New Patient / Visitor Pass', 'color': const Color(0xFF795548), 'icon': Icons.person_add},
      {'title': 'Feedback & Help', 'color': const Color(0xFF9E9E9E), 'icon': Icons.feedback},
    ],
  };

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(12, (index) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    ));
    _selectedLanguage = widget.coordinator.selectedLanguage;
    widget.coordinator.setLanguage(_selectedLanguage); // Sync initial language
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coordinator.selectedLanguage != _selectedLanguage) {
      setState(() {
        _selectedLanguage = widget.coordinator.selectedLanguage;
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildTiles(BuildContext context) {
    final tileData = _tileData[_selectedLanguage]!;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: tileData.length,
      itemBuilder: (context, index) {
        final tile = tileData[index];
        final controller = _controllers[index];
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (controller.value * 0.05),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: () {
              controller.forward(from: 0).then((_) => controller.reverse());
              final title = (tile['title'] as String?)?.split('\n').firstOrNull ?? 'Unknown';
              widget.onTileTap(title);
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (tile['color'] as Color).withOpacity(0.9),
                    (tile['color'] as Color).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (tile['color'] as Color).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tile['icon'] as IconData, color: Colors.white, size: 40),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Text(
                          tile['title'] as String? ?? 'Unknown',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildTiles(context);
  }
}
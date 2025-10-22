import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PharmacyTokenScreen extends StatefulWidget {
  final String selectedLanguage;
  const PharmacyTokenScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<PharmacyTokenScreen> createState() => _PharmacyTokenScreenState();
}

class _PharmacyTokenScreenState extends State<PharmacyTokenScreen> {
  String? activeToken;
  int peopleAhead = 8;
  int waitTime = 15;

  @override
  Widget build(BuildContext context) {
    final code = widget.selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "ഫാർമസി ടോക്കൺ",
      "ta_IN": "மருந்தகம் டோக்கன்",
      "en_US": "Pharmacy Token",
    };

    final generateText = {
      "ml_IN": "ടോക്കൺ നേടുക",
      "ta_IN": "டோக்கன் பெறுக",
      "en_US": "Get Token",
    };

    final yourTokenText = {
      "ml_IN": "നിങ്ങളുടെ ടോക്കൺ",
      "ta_IN": "உங்கள் டோக்கன்",
      "en_US": "Your Token",
    };

    final waitTimeText = {
      "ml_IN": "കാത്തിരിപ്പ് സമയം",
      "ta_IN": "காத்திருப்பு நேரம்",
      "en_US": "Estimated Wait",
    };

    final aheadText = {
      "ml_IN": "മുൻപിലുള്ളവർ",
      "ta_IN": "முன்னிலையில் உள்ளோர்",
      "en_US": "People Ahead",
    };

    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          titles[code] ?? titles["en_US"]!,
          maxLines: 1,
          minFontSize: 14,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: activeToken == null
            ? Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.local_pharmacy),
                  label: Text(
                    generateText[code] ?? generateText["en_US"]!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    setState(() {
                      activeToken = "A103"; // example token
                    });
                  },
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        flex: 1,
                        child: _infoCard(
                            Icons.people, aheadText[code]!, "$peopleAhead"),
                      ),
                      Flexible(
                        flex: 1,
                        child: _infoCard(Icons.access_time, waitTimeText[code]!,
                            "$waitTime min"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AutoSizeText(
                            yourTokenText[code] ?? yourTokenText["en_US"]!,
                            maxLines: 1,
                            minFontSize: 12,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          AutoSizeText(
                            activeToken!,
                            maxLines: 1,
                            minFontSize: 20,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel Token",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => activeToken = null),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.45, // Limit to 45% of screen width
        ),
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced from 16 to save space
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: Colors.red.shade800),
              const SizedBox(height: 8),
              AutoSizeText(
                title,
                maxLines: 3, // Increased from 2 to handle longer text
                minFontSize: 10, // Slightly reduced to ensure fit
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              AutoSizeText(
                value,
                maxLines: 1,
                minFontSize: 12,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
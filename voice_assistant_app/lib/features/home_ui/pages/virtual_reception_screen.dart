import 'package:flutter/material.dart';

// 9. VirtualReceptionScreen
class VirtualReceptionScreen extends StatelessWidget {
  final String selectedLanguage;
  const VirtualReceptionScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  Widget build(BuildContext context) {
    final code = selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "വെർച്വൽ റിസപ്ഷൻ (വീഡിയോ കോൾ)",
      "ta_IN": "மெய்நிகர் வரவேற்பு (வீடியோ அழைப்பு)",
      "en_US": "Virtual Reception (Video Call)",
    };

    final introText = {
      "ml_IN":
          "ആശുപത്രി സ്റ്റാഫുമായി തത്സമയം വീഡിയോ കോൾ ചെയ്യാൻ 'കോൾ ആരംഭിക്കുക' അമർത്തുക.",
      "ta_IN":
          "மருத்துவமனை பணியாளர்களுடன் நேரடி வீடியோ அழைப்பை தொடங்க 'அழைப்பு தொடங்க' அழுத்தவும்.",
      "en_US":
          "Press 'Start Call' to connect with hospital staff via live video.",
    };

    final buttonText = {
      "ml_IN": "കോൾ ആരംഭിക്കുക",
      "ta_IN": "அழைப்பு தொடங்க",
      "en_US": "Start Call",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Icon(
              Icons.support_agent,
              size: 100,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 30),

            // Intro text
            Text(
              introText[code] ?? introText["en_US"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),

            // Start Call Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "🚧 Video call feature coming soon!",
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: Colors.grey.shade800,
                  ),
                );
              },
              icon: const Icon(Icons.video_call, size: 28),
              label: Text(
                buttonText[code] ?? buttonText["en_US"]!,
                style: const TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

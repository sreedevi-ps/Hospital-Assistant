import 'package:flutter/material.dart';

// 10. VisitorPassScreen
class VisitorPassScreen extends StatelessWidget {
  final String selectedLanguage;
  const VisitorPassScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  Widget build(BuildContext context) {
    final code = selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "പുതിയ രോഗി / സന്ദർശക പാസ്",
      "ta_IN": "புதிய நோயாளர் / பார்வையாளர் கட்",
      "en_US": "New Patient / Visitor Pass",
    };

    final introText = {
      "ml_IN": "ആശുപത്രിയിൽ പ്രവേശിക്കാനുള്ള ഡിജിറ്റൽ പാസ് സൃഷ്ടിക്കുക.",
      "ta_IN": "மருத்துவமனையில் நுழைய டிஜிட்டல் பாஸை உருவாக்கவும்.",
      "en_US": "Generate a digital pass to enter the hospital.",
    };

    final nameLabel = {
      "ml_IN": "പേര്",
      "ta_IN": "பெயர்",
      "en_US": "Name",
    };

    final purposeLabel = {
      "ml_IN": "സന്ദർശനത്തിന്റെ ഉദ്ദേശ്യം",
      "ta_IN": "வருகையின் நோக்கம்",
      "en_US": "Purpose of Visit",
    };

    final patientIdLabel = {
      "ml_IN": "രോഗി ഐഡി (ഉണ്ടെങ്കിൽ)",
      "ta_IN": "நோயாளர் ஐடி (இருந்தால்)",
      "en_US": "Patient ID (if any)",
    };

    final buttonText = {
      "ml_IN": "പാസ് സൃഷ്ടിക്കുക",
      "ta_IN": "பாஸ் உருவாக்கு",
      "en_US": "Generate Pass",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              introText[code] ?? introText["en_US"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),

            // Name field
            TextField(
              decoration: InputDecoration(
                labelText: nameLabel[code] ?? nameLabel["en_US"]!,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Purpose field
            TextField(
              decoration: InputDecoration(
                labelText: purposeLabel[code] ?? purposeLabel["en_US"]!,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Patient ID field
            TextField(
              decoration: InputDecoration(
                labelText: patientIdLabel[code] ?? patientIdLabel["en_US"]!,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Generate button
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 80, color: Colors.red.shade700),
                        const SizedBox(height: 20),
                        Text(
                          "✅ Pass generated successfully!",
                          style: TextStyle(fontSize: 18, color: Colors.red.shade800),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Show this digital pass at the entrance.",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.badge),
              label: Text(
                buttonText[code] ?? buttonText["en_US"]!,
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

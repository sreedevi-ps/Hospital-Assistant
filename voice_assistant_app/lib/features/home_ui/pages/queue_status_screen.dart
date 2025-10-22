import 'package:flutter/material.dart';

// 8. QueueStatusScreen
class QueueStatusScreen extends StatefulWidget {
  final String selectedLanguage;
  const QueueStatusScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  String currentToken = "P-20"; // dummy
  List<String> upcomingTokens = ["P-21", "P-22", "P-23", "P-24"]; // dummy
  String? searchResult;

  @override
  Widget build(BuildContext context) {
    final code = widget.selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "ക്യൂ സ്റ്റാറ്റസ് (ലൈവ്)",
      "ta_IN": "க்யூ நிலை (நேரடி)",
      "en_US": "Queue Status (Live)",
    };

    final liveNowText = {
      "ml_IN": "ഇപ്പോൾ വിളിക്കുന്നത്",
      "ta_IN": "இப்போது அழைக்கப்படுகிறது",
      "en_US": "Now Serving",
    };

    final upcomingText = {
      "ml_IN": "അടുത്ത ടോക്കണുകൾ",
      "ta_IN": "அடுத்த டோக்கன்கள்",
      "en_US": "Upcoming Tokens",
    };

    final searchHint = {
      "ml_IN": "ടോക്കൺ നമ്പർ തിരയുക...",
      "ta_IN": "டோக்கன் எண்ணை தேடுக...",
      "en_US": "Search token number...",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // dummy refresh shuffle
                currentToken = "P-21";
                upcomingTokens = ["P-22", "P-23", "P-24", "P-25"];
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: searchHint[code] ?? searchHint["en_US"]!,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  searchResult = (value.isNotEmpty &&
                          (upcomingTokens.contains(value) || currentToken == value))
                      ? "✅ $value is in queue"
                      : "❌ Token not found";
                });
              },
            ),
            if (searchResult != null) ...[
              const SizedBox(height: 8),
              Text(
                searchResult!,
                style: TextStyle(
                  fontSize: 16,
                  color: searchResult!.contains("✅") ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Live Now
            Text(
              liveNowText[code] ?? liveNowText["en_US"]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.yellow.shade700,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    currentToken,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Upcoming Tokens
            Text(
              upcomingText[code] ?? upcomingText["en_US"]!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: upcomingTokens.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.confirmation_num, color: Colors.red),
                    title: Text(
                      upcomingTokens[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

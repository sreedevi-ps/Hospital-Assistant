import 'package:flutter/material.dart';

// 5. LabResultsScreen
class LabResultsScreen extends StatelessWidget {
  final String selectedLanguage;
  const LabResultsScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  Widget build(BuildContext context) {
    final code = selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "ലാബ് & റേഡിയോളജി ഫലങ്ങൾ",
      "ta_IN": "லாப் & ரேடியோலஜி முடிவுகள்",
      "en_US": "Lab & Radiology Results",
    };

    final searchHint = {
      "ml_IN": "ടെസ്റ്റ് അല്ലെങ്കിൽ തീയതി തിരയുക...",
      "ta_IN": "சோதனை அல்லது தேதியைத் தேடுக...",
      "en_US": "Search by test or date...",
    };

    final viewText = {
      "ml_IN": "കാണുക",
      "ta_IN": "பார்",
      "en_US": "View",
    };

    final helpText = {
      "ml_IN": "സഹായം വേണോ?",
      "ta_IN": "உதவி தேவை?",
      "en_US": "Need Assistance?",
    };

    // Dummy test reports
    final reports = [
      {"name": "Complete Blood Count", "date": "21 Sep 2025", "status": "Ready"},
      {"name": "Chest X-Ray", "date": "18 Sep 2025", "status": "Pending"},
      {"name": "MRI Brain", "date": "12 Sep 2025", "status": "Collected"},
      {"name": "Lipid Profile", "date": "10 Sep 2025", "status": "Ready"},
    ];

    Color _statusColor(String status) {
      switch (status) {
        case "Ready":
          return Colors.green.shade600;
        case "Pending":
          return Colors.orange.shade600;
        case "Collected":
          return Colors.blue.shade600;
        default:
          return Colors.grey.shade600;
      }
    }

    IconData _statusIcon(String status) {
      switch (status) {
        case "Ready":
          return Icons.check_circle;
        case "Pending":
          return Icons.hourglass_top;
        case "Collected":
          return Icons.inventory_2;
        default:
          return Icons.help;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: searchHint[code] ?? searchHint["en_US"]!,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 📋 Report list
          Expanded(
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: Icon(
                      _statusIcon(report["status"]!),
                      color: _statusColor(report["status"]!),
                    ),
                    title: Text(report["name"]!),
                    subtitle: Text("Date: ${report["date"]}"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow.shade700,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${report["name"]} report opened")),
                        );
                      },
                      child: Text(
                        viewText[code] ?? viewText["en_US"]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🆘 Assistance button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${helpText[code] ?? helpText["en_US"]!} – Redirecting...")),
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: Text(helpText[code] ?? helpText["en_US"]!),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

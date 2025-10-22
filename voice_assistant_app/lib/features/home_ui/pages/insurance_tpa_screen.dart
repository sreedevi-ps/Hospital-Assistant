import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class InsuranceTPAScreen extends StatefulWidget {
  final String selectedLanguage;
  const InsuranceTPAScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<InsuranceTPAScreen> createState() => _InsuranceTPAScreenState();
}

class _InsuranceTPAScreenState extends State<InsuranceTPAScreen> {
  String query = "";
  String? selectedPartner;

  @override
  Widget build(BuildContext context) {
    final code = widget.selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "ഇൻഷുറൻസ് / TPA ഡെസ്ക്",
      "ta_IN": "காப்பீடு / TPA டெஸ்க்",
      "en_US": "Insurance / TPA Desk",
    };

    final searchHint = {
      "ml_IN": "ഇൻഷുറൻസ് / TPA തിരയുക...",
      "ta_IN": "காப்பீடு / TPA தேடுக...",
      "en_US": "Search Insurance / TPA...",
    };

    final helpText = {
      "ml_IN": "സഹായം വേണോ?",
      "ta_IN": "உதவி தேவை?",
      "en_US": "Need Help?",
    };

    final selectText = {
      "ml_IN": "തിരഞ്ഞെടുക്കുക",
      "ta_IN": "தேர்ந்தெடு",
      "en_US": "Select",
    };

    final infoText = {
      "ml_IN": "ക്യാഷ്‌ലെസ്സ് & റീംബഴ്‌സ്‌മെന്റ് ഓപ്ഷനുകൾ ലഭ്യമാണ്",
      "ta_IN": "காசில்லா & ஈடு செலுத்தும் விருப்பங்கள் கிடைக்கும்",
      "en_US": "Cashless & Reimbursement options available",
    };

    final partners = [
      "Star Health Insurance",
      "ICICI Lombard",
      "HDFC Ergo",
      "United India Insurance",
      "MediAssist TPA",
      "Paramount TPA",
    ];

    final filtered = partners
        .where((p) => p.toLowerCase().contains(query.toLowerCase()))
        .toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: searchHint[code] ?? searchHint["en_US"]!,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => query = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final partner = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: selectedPartner == partner ? 6 : 3,
                  color: selectedPartner == partner ? Colors.yellow.shade100 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: const Icon(Icons.verified_user, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                partner,
                                maxLines: 2,
                                minFontSize: 12,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              AutoSizeText(
                                infoText[code] ?? infoText["en_US"]!,
                                maxLines: 2,
                                minFontSize: 11,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow.shade700,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedPartner = partner;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("$partner selected")),
                            );
                          },
                          child: AutoSizeText(
                            selectText[code] ?? selectText["en_US"]!,
                            maxLines: 1,
                            minFontSize: 12,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.support_agent),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${helpText[code] ?? helpText["en_US"]!} – Redirecting...")),
                );
              },
              label: AutoSizeText(
                helpText[code] ?? helpText["en_US"]!,
                maxLines: 1,
                minFontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

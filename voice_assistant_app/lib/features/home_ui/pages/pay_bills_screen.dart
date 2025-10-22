import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class PayBillsScreen extends StatelessWidget {
  final String selectedLanguage;
  const PayBillsScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  Widget build(BuildContext context) {
    final code = selectedLanguage.replaceAll("-", "_");

    final titles = {
      "ml_IN": "ബിൽ പേയ്‌മെന്റ്",
      "ta_IN": "பில் செலுத்தல்",
      "en_US": "Pay Bills",
    };

    final payNowText = {
      "ml_IN": "ഇപ്പോൾ അടയ്ക്കുക",
      "ta_IN": "இப்போது செலுத்து",
      "en_US": "Pay Now",
    };

    final outstandingTitle = {
      "ml_IN": "അടയ്ക്കാനുള്ള ബില്ലുകൾ",
      "ta_IN": "செலுத்த வேண்டிய பில்கள்",
      "en_US": "Outstanding Bills",
    };

    final methodsTitle = {
      "ml_IN": "പേയ്മെന്റ് രീതികൾ",
      "ta_IN": "கட்டண முறைகள்",
      "en_US": "Payment Methods",
    };

    final historyTitle = {
      "ml_IN": "പേയ്മെന്റ് ചരിത്രം",
      "ta_IN": "கட்டண வரலாறு",
      "en_US": "Payment History",
    };

    final outstandingBills = [
      {"id": "INV-2025-001", "date": "22 Sep 2025", "amount": "₹2500", "status": "Unpaid"},
      {"id": "INV-2025-002", "date": "20 Sep 2025", "amount": "₹1200", "status": "Unpaid"},
    ];

    final paidBills = [
      {"id": "INV-2025-000", "date": "10 Sep 2025", "amount": "₹1800", "status": "Paid"},
    ];

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(outstandingTitle[code] ?? outstandingTitle["en_US"]!),
            const SizedBox(height: 8),
            ...outstandingBills.map((bill) => _billCard(context, bill, payNowText[code] ?? payNowText["en_US"]!)),
            const SizedBox(height: 24),
            _sectionTitle(methodsTitle[code] ?? methodsTitle["en_US"]!),
            const SizedBox(height: 8),
            _buildMethodsGrid(),
            const SizedBox(height: 24),
            _sectionTitle(historyTitle[code] ?? historyTitle["en_US"]!),
            const SizedBox(height: 8),
            ...paidBills.map((bill) => _billHistoryCard(bill)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => AutoSizeText(
        text,
        maxLines: 1,
        minFontSize: 14,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFB71C1C)),
      );

  Widget _billCard(BuildContext context, Map<String, String> bill, String payLabel) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.receipt_long, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText("Bill ID: ${bill["id"]}", maxLines: 1, minFontSize: 12, style: const TextStyle(fontWeight: FontWeight.bold)),
                  AutoSizeText("Date: ${bill["date"]}\nAmount: ${bill["amount"]}", maxLines: 2, minFontSize: 12),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade700,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${bill["id"]} – Payment flow coming soon")),
                );
              },
              child: AutoSizeText(payLabel, maxLines: 1, minFontSize: 12, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodsGrid() {
    final methods = [
      {"icon": Icons.credit_card, "label": "Card"},
      {"icon": Icons.account_balance, "label": "Net Banking"},
      {"icon": Icons.qr_code, "label": "UPI"},
      {"icon": Icons.verified, "label": "Insurance / TPA"},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: methods
          .map(
            (m) => Chip(
              avatar: Icon(m["icon"] as IconData, color: Colors.red.shade800),
              label: AutoSizeText(m["label"] as String, maxLines: 1, minFontSize: 11),
              backgroundColor: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
          .toList(),
    );
  }

  Widget _billHistoryCard(Map<String, String> bill) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: AutoSizeText("Bill ID: ${bill["id"]}", maxLines: 1, minFontSize: 12, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: AutoSizeText("Date: ${bill["date"]}\nAmount: ${bill["amount"]}", maxLines: 2, minFontSize: 11),
        trailing: AutoSizeText(
          bill["status"]!,
          maxLines: 1,
          minFontSize: 11,
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

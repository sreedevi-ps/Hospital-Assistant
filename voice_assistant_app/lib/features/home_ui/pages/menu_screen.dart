import 'package:flutter/material.dart';
import '../../interaction_flow/interaction_coordinator.dart';
import 'conversation_screen.dart';
import 'book_appointment_screen.dart';
import 'check_in_screen.dart';
import 'feedback_help_screen.dart';
import 'hospital_map_screen.dart';
import 'insurance_tpa_screen.dart';
import 'lab_results_screen.dart';
import 'pay_bills_screen.dart';
import 'pharmacy_token_screen.dart';
import 'queue_status_screen.dart';
import 'visitor_pass_screen.dart';
import 'virtual_reception_screen.dart';

class MenuScreen extends StatelessWidget {
  final InteractionCoordinator coordinator;
  final Function(String)?
  onTileTap; // Added for voice prompt in ConversationScreen

  const MenuScreen({Key? key, required this.coordinator, this.onTileTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String selectedLang = coordinator.selectedLanguage;
    final String labelCode = selectedLang.isNotEmpty
        ? selectedLang.replaceAll("-", "_")
        : "en_US"; // Safe fallback

    // Multilingual header
    final Map<String, String> localizedHeader = {
      "ml_IN": "നിങ്ങളുടെ ആരോഗ്യoം, ഞങ്ങളുടെ പരിചരണം",
      "ta_IN": "உங்கள் ஆரோக்கியம், எங்கள் பராமரிப்பு",
      "en_US": "Your Health, Our Care",
    };
    final String headerText =
        localizedHeader[labelCode] ?? localizedHeader["en_US"]!;

    // Determine crossAxisCount based on screen width
    // Determine card height
final double cardHeight = 200; // Increased from 180 for more vertical space
final double screenWidth = MediaQuery.of(context).size.width;
final int crossAxisCount = screenWidth >= 600 ? 3 : 2; // tablets vs phones

return Scaffold(
  backgroundColor: Colors.red.shade800,
  body: SafeArea(
    child: Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            headerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Menu Grid
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: (screenWidth / crossAxisCount) / (cardHeight * 1.1), // Adjusted for flexibility
              ),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                return _MenuCard(
                  item: item,
                  labelCode: labelCode,
                  coordinator: coordinator,
                  onTileTap: onTileTap,
                  cardHeight: cardHeight, // pass height to card
                );
              },
            ),
          ),
        ),
      ],
    ),
  ),
);

           
  }
}

// Menu Item Model
class _MenuItem {
  final Map<String, String> title;
  final IconData icon;
  final Map<String, String> buttonText;

  _MenuItem(this.title, this.icon, this.buttonText);
}

// Menu Items with multilingual titles and button texts
final List<_MenuItem> _menuItems = [
  // 1. ConversationScreen
  _MenuItem(
    {
      "en_US": "How Can I Help You?",
      "ml_IN": "സഹായം വേണോ?",
      "ta_IN": "உதவி தேவையா?",
    },
    Icons.mic,
    {"en_US": "Start", "ml_IN": "ആരംഭിക്കുക", "ta_IN": "தொடங்கு"},
  ),
  // 2. BookAppointmentScreen
  _MenuItem(
    {
      "en_US": "Appointment / Rescheduling",
      "ml_IN": "അപോയിന്റ്മെന്റ് / പുനഃക്രമീകരണം",
      "ta_IN": "நியமனம் / மீண்டும் திட்டமிடல்",
    },
    Icons.calendar_today,
    {"en_US": "Book", "ml_IN": "ബുക്ക് ചെയ്യുക", "ta_IN": "பதிவு செய்"},
  ),
  // 3. CheckInScreen
  _MenuItem(
    {
      "en_US": "Check-in / Registration",
      "ml_IN": "ചെക്ക്-ഇൻ / രജിസ്ട്രേഷൻ",
      "ta_IN": "செக்-இன் / பதிவு",
    },
    Icons.login,
    {
      "en_US": "Check-in",
      "ml_IN": "ചെക്ക് ഇൻ ചെയ്യുക",
      "ta_IN": "செக்-இன் செய்",
    },
  ),
  // 4. PharmacyTokenScreen
  _MenuItem(
    {
      "en_US": "Pharmacy Token",
      "ml_IN": "ഫാർമസി ടോക്കൺ",
      "ta_IN": "மருந்தகம் டோக்கன்",
    },
    Icons.local_pharmacy,
    {"en_US": "Get", "ml_IN": "എടുക്കുക", "ta_IN": "பெறு"},
  ),
  // 5. InsuranceTPAScreen
  _MenuItem(
    {
      "en_US": "Insurance & TPA Desk",
      "ml_IN": "ഇൻഷുറൻസ് & TPA ഡെസ്ക്",
      "ta_IN": "காப்பீடு & TPA டெஸ்க்",
    },
    Icons.assignment,
    {"en_US": "Proceed", "ml_IN": "മുന്നോട്ടു പോകുക", "ta_IN": "தொடர்க"},
  ),
  // 6. PayBillsScreen
  _MenuItem(
    {
      "en_US": "Pay Bills",
      "ml_IN": "ബില്ലുകൾ അടയ്‌ക്കുക",
      "ta_IN": "பில்ல்கள் செலுத்து",
    },
    Icons.payment,
    {"en_US": "Pay", "ml_IN": "അടയ്ക്കുക", "ta_IN": "செலுத்து"},
  ),
  // 7. LabResultsScreen
  _MenuItem(
    {
      "en_US": "Lab & Radiology Results",
      "ml_IN": "ലാബ് & റേഡിയോളജി ഫലങ്ങൾ",
      "ta_IN": "லாப் & ரேடியோலஜி முடிவுகள்",
    },
    Icons.receipt,
    {"en_US": "View", "ml_IN": "കാണുക", "ta_IN": "பார்க்க"},
  ),
  // 8. HospitalMapScreen
  _MenuItem(
    {
      "en_US": "Hospital Map & Guidance",
      "ml_IN": "ആസ്പത്രി മാപ്പ് & മാർഗ്ഗനിർദ്ദേശം",
      "ta_IN": "மருத்துவமனை வரைபடம் & வழிகாட்டுதல்",
    },
    Icons.map,
    {"en_US": "Locate", "ml_IN": "കാണിക്കുക", "ta_IN": "காண்பி"},
  ),
  // 9. QueueStatusScreen
  _MenuItem(
    {
      "en_US": "Queue Status",
      "ml_IN": "ക്യൂ സ്റ്റാറ്റസ്",
      "ta_IN": "வரிசை நிலை",
    },
    Icons.view_list,
    {"en_US": "View", "ml_IN": "കാണുക", "ta_IN": "பார்க்க"},
  ),
  // 10. VirtualReceptionScreen
  _MenuItem(
    {
      "en_US": "Virtual Reception",
      "ml_IN": "വെർച്വൽ റിസപ്ഷൻ",
      "ta_IN": "மெய்நிகர் வரவேற்பு",
    },
    Icons.video_call,
    {"en_US": "Call", "ml_IN": "വിളിക്കുക", "ta_IN": "அழை"},
  ),
  // 11. VisitorPassScreen
  _MenuItem(
    {
      "en_US": "New Patient / Visitor Pass",
      "ml_IN": "പുതിയ രോഗി / സന്ദർശക പാസ്",
      "ta_IN": "புதிய நோயாளி / பார்வையாளர் கட்",
    },
    Icons.person_add,
    {"en_US": "Issue", "ml_IN": "അടുക്കുക", "ta_IN": "உள்ளிடு"},
  ),
  // 12. FeedbackHelpScreen
  _MenuItem(
    {
      "en_US": "Feedback & Support",
      "ml_IN": "ഫീഡ്‌ബാക്ക് & സപ്പോർട്ട്",
      "ta_IN": "கருத்து & ஆதரவு",
    },
    Icons.feedback,
    {"en_US": "Submit", "ml_IN": "സമർപ്പിക്കുക", "ta_IN": "சமர்ப்பிக்க"},
  ),
];

// Menu Card Widget
class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  final String labelCode;
  final InteractionCoordinator coordinator;
  final Function(String)? onTileTap;
  final double cardHeight;

  const _MenuCard({
    Key? key,
    required this.item,
    required this.labelCode,
    required this.coordinator,
    this.onTileTap,
    required this.cardHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 16), // Increased for better spacing
            Icon(item.icon, color: Colors.red, size: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Adjusted padding
              child: Text(
                item.title[labelCode] ?? item.title["en_US"]!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                softWrap: true,
                maxLines: 3, // Allow up to 3 lines for longer titles
                overflow: TextOverflow.ellipsis, // Truncate with ellipsis
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 12, right: 12), // Increased bottom padding
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12, // Slightly reduced for balance
                      horizontal: 8,
                    ),
                  ),
                  onPressed: () {
  final String title = item.title[labelCode] ?? item.title["en_US"]!;
  
  switch (title) {
    case "How Can I Help You?":
    case "സഹായം വേണോ?":
    case "உதவி தேவையா?":
      if (onTileTap != null) {
        onTileTap!(title);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationScreen(coordinator: coordinator),
          ),
        );
      }
      break;

    case "Appointment / Rescheduling":
    case "അപോയിന്റ്മെന്റ് / പുനഃക്രമീകരണം":
    case "நியமனம் / மீண்டும் திட்டமிடல்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookAppointmentScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Check-in / Registration":
    case "ചെക്ക്-ഇൻ / രജിസ്ട്രേഷൻ":
    case "செக்-இன் / பதிவு":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CheckInScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Pharmacy Token":
    case "ഫാർമസി ടോക്കൺ":
    case "மருந்தகம் டோக்கன்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PharmacyTokenScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Insurance & TPA Desk":
    case "ഇൻഷുറൻസ് & TPA ഡെസ്ക്":
    case "காப்பீடு & TPA டெஸ்க்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InsuranceTPAScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Pay Bills":
    case "ബില്ലുകൾ അടയ്‌ക്കുക":
    case "பில்ல்கள் செலுத்து":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PayBillsScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Lab & Radiology Results":
    case "ലാബ് & റേഡിയോളജി ഫലങ്ങൾ":
    case "லாப் & ரேடியோலஜி முடிவுகள்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LabResultsScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Hospital Map & Guidance":
    case "ആസ്പത്രി മാപ്പ് & മാർഗ്ഗനിർദ്ദേശം":
    case "மருத்துவமனை வரைபடம் & வழிகாட்டுதல்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalMapScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Queue Status":
    case "ക്യൂ സ്റ്റാറ്റസ്":
    case "வரிசை நிலை":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QueueStatusScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Virtual Reception":
    case "വെർച്വൽ റിസപ്ഷൻ":
    case "மெய்நிகர் வரவேற்பு":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VirtualReceptionScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "New Patient / Visitor Pass":
    case "പുതിയ രോഗി / സന്ദർശക പാസ്":
    case "புதிய நோயாளி / பார்வையாளர் கட்":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitorPassScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    case "Feedback & Support":
    case "ഫീഡ്‌ബാക്ക് & സപ്പോർട്ട്":
    case "கருத்து & ஆதரவு":
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeedbackHelpScreen(selectedLanguage: labelCode),
        ),
      );
      break;

    default:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Screen not found")),
      );
  }
},

                  child: Text(
                    item.buttonText[labelCode] ?? "Open",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
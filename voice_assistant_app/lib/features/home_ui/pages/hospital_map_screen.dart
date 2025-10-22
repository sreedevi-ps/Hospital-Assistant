import 'package:flutter/material.dart';

class HospitalMapScreen extends StatefulWidget {
  final String selectedLanguage;
  const HospitalMapScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final List<Map<String, dynamic>> _departments = [
    {"name": "Emergency", "icon": Icons.local_hospital, "desc": "24/7 care unit"},
    {"name": "Pharmacy", "icon": Icons.local_pharmacy, "desc": "Medicines & supplies"},
    {"name": "Radiology", "icon": Icons.medical_services, "desc": "X-ray, CT, MRI"},
    {"name": "Laboratory", "icon": Icons.biotech, "desc": "Pathology & blood tests"},
    {"name": "Cardiology", "icon": Icons.favorite, "desc": "Heart care unit"},
    {"name": "Orthopedics", "icon": Icons.accessibility_new, "desc": "Bones & joints"},
  ];

  void _showDepartmentSheet(Map<String, dynamic> dept) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(dept["icon"], size: 40, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(
              dept["name"],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(dept["desc"], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.directions),
              label: const Text("Navigate"),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Navigation to ${dept["name"]} coming soon!"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.selectedLanguage.replaceAll("-", "_");
    final titles = {
      "ml_IN": "ആശുപത്രി മാപ് & വഴികാട്ടൽ",
      "ta_IN": "மருத்துவமனை வரைபடம் & வழிகாட்டுதல்",
      "en_US": "Hospital Map & Wayfinding",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
      ),
      body: Column(
        children: [
          // Map image preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.asset(
              "assets/data/navBg.jpg",
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          // Directory grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _departments.length,
              itemBuilder: (context, i) {
                final dept = _departments[i];
                return GestureDetector(
                  onTap: () => _showDepartmentSheet(dept),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(dept["icon"], size: 40, color: Colors.red.shade700),
                        const SizedBox(height: 8),
                        Text(
                          dept["name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

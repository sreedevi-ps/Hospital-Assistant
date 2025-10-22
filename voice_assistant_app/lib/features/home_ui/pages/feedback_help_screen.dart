import 'package:flutter/material.dart';

class FeedbackHelpScreen extends StatefulWidget {
  final String selectedLanguage;
  const FeedbackHelpScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<FeedbackHelpScreen> createState() => _FeedbackHelpScreenState();
}

class _FeedbackHelpScreenState extends State<FeedbackHelpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  String? _feedbackType;

  @override
  Widget build(BuildContext context) {
    final code = widget.selectedLanguage.replaceAll("-", "_");
    final titles = {
      "ml_IN": "ഫീഡ്ബാക്ക് & സഹായം",
      "ta_IN": "கருத்து & உதவி",
      "en_US": "Feedback & Help",
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[code] ?? titles["en_US"]!),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: "Your Name",
                    icon: Icons.person,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _contactController,
                    label: "Email / Phone (Optional)",
                    icon: Icons.contact_mail,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: "Feedback Type",
                    value: _feedbackType,
                    items: ["Complaint", "Suggestion", "Inquiry", "Other"],
                    icon: Icons.category,
                    onChanged: (val) {
                      setState(() => _feedbackType = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _feedbackController,
                    label: "Your Feedback / Issue",
                    icon: Icons.feedback,
                    maxLines: 4,
                    validator: (val) => val == null || val.isEmpty
                        ? "Please enter your feedback"
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitFeedback,
                    child: const Text(
                      "Submit Feedback",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Select $label" : null,
    );
  }

  // --- Submit Action ---
  void _submitFeedback() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Feedback Submitted Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      _formKey.currentState?.reset();
      setState(() => _feedbackType = null);
    }
  }
}

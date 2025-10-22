import 'package:flutter/material.dart';

class CheckInScreen extends StatefulWidget {
  final String selectedLanguage;
  const CheckInScreen({super.key, this.selectedLanguage = "en_US"});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idProofController = TextEditingController();

  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    final String code = widget.selectedLanguage.replaceAll("-", "_");
    final Map<String, String> titles = {
      "ml_IN": "ചെക്ക്-ഇൻ / രജിസ്ട്രേഷൻ",
      "ta_IN": "செய்க்-இன் / பதிவு",
      "en_US": "Check-in / Registration",
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
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _ageController,
                    label: "Age",
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter your age" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: "Gender",
                    value: _selectedGender,
                    items: ["Male", "Female", "Other"],
                    icon: Icons.transgender,
                    onChanged: (val) {
                      setState(() => _selectedGender = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter phone number" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _emailController,
                    label: "Email (Optional)",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _addressController,
                    label: "Address",
                    icon: Icons.home,
                    maxLines: 2,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter address" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _idProofController,
                    label: "ID Proof (e.g., Aadhar, Passport)",
                    icon: Icons.badge,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Enter ID proof" : null,
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
                    onPressed: _registerUser,
                    child: const Text(
                      "Register",
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

  // --- Register Action ---
  void _registerUser() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

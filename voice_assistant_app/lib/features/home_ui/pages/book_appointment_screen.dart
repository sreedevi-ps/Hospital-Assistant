import 'package:flutter/material.dart';
import 'check_in_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String selectedLanguage; // normalized language code: "ml_IN", "ta_IN", "en_US"

  const BookAppointmentScreen({super.key, required this.selectedLanguage});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regIdController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDoctor;

  final List<String> _departments = [
    "Cardiology",
    "Neurology",
    "Orthopedics",
    "Pediatrics",
    "Dermatology"
  ];

  final Map<String, List<String>> _doctorsByDept = {
    "Cardiology": ["Dr. Smith", "Dr. Abraham"],
    "Neurology": ["Dr. Meera", "Dr. Sanjay"],
    "Orthopedics": ["Dr. Raj", "Dr. Nisha"],
    "Pediatrics": ["Dr. John", "Dr. Priya"],
    "Dermatology": ["Dr. Lekha", "Dr. Vivek"],
  };

  @override
  Widget build(BuildContext context) {
    // Multilingual header
    final Map<String, String> headerTextMap = {
      "ml_IN": "അപോയിന്റ്മെന്റ് / പുനഃക്രമീകരണം",
      "ta_IN": "நியமனம் / மீண்டும் திட்டமிடல்",
      "en_US": "Appointment / Rescheduling",
    };

    final String headerText =
        headerTextMap[widget.selectedLanguage] ?? headerTextMap["en_US"]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(headerText),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    validator: (value) =>
                        value == null || value.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _regIdController,
                    label: "Registration ID",
                    icon: Icons.badge,
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter registration ID"
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: "Department",
                    value: _selectedDepartment,
                    items: _departments,
                    icon: Icons.local_hospital,
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                        _selectedDoctor = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: "Doctor",
                    value: _selectedDoctor,
                    items: _selectedDepartment != null
                        ? _doctorsByDept[_selectedDepartment] ?? []
                        : [],
                    icon: Icons.medical_services,
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctor = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(
                    controller: _dateController,
                    label: "Select Date",
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _buildTimePicker(
                    controller: _timeController,
                    label: "Select Time",
                    icon: Icons.access_time,
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
                    onPressed: _bookAppointment,
                    child: const Text(
                      "Book Appointment",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
  child: TextButton(
    onPressed: () {
      // Show SnackBar first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Redirecting to registration..."),
          duration: Duration(seconds: 1), // short duration
        ),
      );

      // Navigate after SnackBar disappears
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CheckInScreen(
              selectedLanguage: widget.selectedLanguage,
            ),
          ),
        );
      });
    },
    child: const Text(
      "New User? Register Here",
      style: TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
)

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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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

  Widget _buildDatePicker({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          controller.text = "${picked.day}-${picked.month}-${picked.year}";
        }
      },
      validator: (val) => val == null || val.isEmpty ? "Pick a date" : null,
    );
  }

  Widget _buildTimePicker({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        TimeOfDay? picked =
            await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked != null) {
          controller.text = picked.format(context);
        }
      },
      validator: (val) => val == null || val.isEmpty ? "Pick a time" : null,
    );
  }

  void _bookAppointment() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking Successful!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

   
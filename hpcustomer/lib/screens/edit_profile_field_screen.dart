import 'package:flutter/material.dart';
import '../services/profile_service.dart';

enum ProfileFieldType {
  fullName,
  email,
  dateOfBirth,
  mobileNumber,
}

class EditProfileFieldScreen extends StatefulWidget {
  final ProfileFieldType fieldType;
  final String initialValue;

  const EditProfileFieldScreen({
    super.key,
    required this.fieldType,
    required this.initialValue,
  });

  @override
  State<EditProfileFieldScreen> createState() => _EditProfileFieldScreenState();
}

class _EditProfileFieldScreenState extends State<EditProfileFieldScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _helperText {
    switch (widget.fieldType) {
      case ProfileFieldType.fullName:
        return "This is how we'll address you";
      case ProfileFieldType.email:
        return "We'll send your receipts and order updates here";
      case ProfileFieldType.dateOfBirth:
        return "Please enter your date of birth";
      case ProfileFieldType.mobileNumber:
        return "We'll use this number to contact you about orders";
    }
  }

  void _onDone() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Field cannot be empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    switch (widget.fieldType) {
      case ProfileFieldType.fullName:
        ProfileService().updateFullName(value);
        break;
      case ProfileFieldType.email:
        ProfileService().updateEmail(value);
        break;
      case ProfileFieldType.dateOfBirth:
        ProfileService().updateDateOfBirth(value);
        break;
      case ProfileFieldType.mobileNumber:
        ProfileService().updateMobileNumber(value);
        break;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1B4B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _onDone,
            child: const Text(
              'DONE',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5722),
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF3F4F6)),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Text(
                _helperText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E1B4B),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

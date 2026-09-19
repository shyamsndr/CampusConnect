import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/services/admin_repository.dart';

/// Screen for adding pre-authorized college members (Students & Staff).
class AddUserScreen extends StatefulWidget {
  final AdminRepository repository;
  final VoidCallback onUserAdded;
  final VoidCallback onCancel;

  const AddUserScreen({
    super.key,
    required this.repository,
    required this.onUserAdded,
    required this.onCancel,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final _memberCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'Student';
  bool _isSubmitting = false;

  final List<String> _departments = [
    'Computer Science',
    'Information Technology',
    'Electronics & Comm.',
    'Mechanical Engineering',
    'Civil Engineering',
    'Electrical Engineering',
    'Science & Humanities',
    'Administration',
  ];

  @override
  void dispose() {
    _memberCodeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final memberCode = _memberCodeController.text.trim();
    final email = _emailController.text.trim();

    if (widget.repository.isMemberCodeExists(memberCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Member code "$memberCode" is already registered.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.repository.isEmailExists(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email "$email" is already registered.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final newUser = UserModel(
      memberCode: memberCode,
      name: _nameController.text.trim(),
      email: email,
      role: _selectedRole,
      department: _departmentController.text.trim().isNotEmpty
          ? _departmentController.text.trim()
          : 'General',
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : '-',
      status: 'Active',
      createdAt: DateTime.now(),
    );

    widget.repository.addUser(newUser);

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Successfully authorized $memberCode (${newUser.name}) as $_selectedRole.',
        ),
        backgroundColor: AppColors.statusResolvedText,
      ),
    );

    widget.onUserAdded();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Back action
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    onPressed: widget.onCancel,
                    tooltip: 'Back to Users',
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Authorized Member',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pre-authorize a college student or staff before mobile app registration.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Container
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Notice banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Members will be able to register and log in on the mobile app once their member code and email match these authorized records.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Member Code & Role
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Member Code *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _memberCodeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. STU-2024-150 / STF-305',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Member code is required';
                                    }
                                    if (value.trim().length < 3) {
                                      return 'Must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Role *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedRole,
                                  decoration: const InputDecoration(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Student',
                                      child: Text('Student'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Staff',
                                      child: Text('Staff'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedRole = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Full Name
                      const Text(
                        'Full Name *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Anjali Verma',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Email
                      const Text(
                        'Email Address *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'e.g. anjali.v@student.college.edu',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address is required';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Department & Phone
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Department',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _departments.first,
                                  decoration: const InputDecoration(),
                                  items: _departments.map((dept) {
                                    return DropdownMenuItem(
                                      value: dept,
                                      child: Text(dept),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      _departmentController.text = value;
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Phone',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. +91 98765 00000',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 18),
                            label: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Add User'),
                            onPressed: _isSubmitting ? null : _handleSubmit,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

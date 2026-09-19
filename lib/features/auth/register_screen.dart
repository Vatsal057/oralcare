import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/session_controller.dart';

/// Registration for either interface (spec section 2.1 "Registration and
/// Consent"). Consent itself is collected on the next screen, because the spec
/// treats it as a gate rather than a registration field.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _fullName = TextEditingController();
  final _patientId = TextEditingController();
  final _age = TextEditingController();
  final _enrolmentCode = TextEditingController();
  final _clinic = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _medicalHistory = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  String? _gender;
  bool _busy = false;
  String? _error;

  static const List<String> _genderOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  bool get _isDoctor => widget.role == UserRole.doctor;

  /// Blank is allowed; anything entered must look like a usable number.
  String? _optionalPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return digits.length >= 10 ? null : 'Enter at least 10 digits.';
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullName.dispose();
    _patientId.dispose();
    _age.dispose();
    _enrolmentCode.dispose();
    _clinic.dispose();
    _phone.dispose();
    _city.dispose();
    _medicalHistory.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final session = context.read<SessionController>();

    try {
      final user = _isDoctor
          ? await session.auth.registerDoctor(
              username: _username.text,
              password: _password.text,
              enrolmentCode: _enrolmentCode.text,
              fullName: _fullName.text,
              clinic: _clinic.text,
            )
          : await session.auth.registerPatient(
              username: _username.text,
              password: _password.text,
              preferredPatientId: _patientId.text,
              fullName: _fullName.text,
              age: int.parse(_age.text.trim()),
              gender: _gender ?? '',
              phone: _phone.text,
              city: _city.text,
              medicalHistory: _medicalHistory.text,
              emergencyContactName: _emergencyName.text,
              emergencyContactPhone: _emergencyPhone.text,
            );

      session.adopt(user);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not create the account. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('New ${widget.role.label.toLowerCase()} account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  NoticeBanner(
                    message: _error!,
                    severity: NoticeSeverity.alert,
                  ),
                  const SizedBox(height: 16),
                ],

                Text('Account', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username *',
                    helperText: 'Letters, numbers, dot, dash, underscore.',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length < 3) {
                      return 'At least 3 characters.';
                    }
                    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(value)) {
                      return 'Letters, numbers, dot, dash and underscore only.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password *',
                    helperText:
                        'At least 8 characters, including a letter and a number.',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    final value = v ?? '';
                    if (value.length < 8) return 'At least 8 characters.';
                    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                      return 'Include at least one letter.';
                    }
                    if (!RegExp(r'\d').hasMatch(value)) {
                      return 'Include at least one number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password *',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == _password.text ? null : 'Passwords do not match.',
                ),

                const SizedBox(height: 24),
                Text(
                  _isDoctor ? 'Clinician details' : 'Your details',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _isDoctor
                        ? 'Name shown to patients *'
                        : 'Name (optional)',
                    helperText: _isDoctor
                        ? 'Patients pick you from this name, so make it '
                              'recognisable.'
                        : null,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if (!_isDoctor) return null;
                    return (v == null || v.trim().length < 3)
                        ? 'Enter the name patients will see.'
                        : null;
                  },
                ),

                if (_isDoctor) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _clinic,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Clinic or centre (optional)',
                      helperText:
                          'Helps a patient tell two clinicians apart in the '
                          'list.',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _enrolmentCode,
                    decoration: const InputDecoration(
                      labelText: 'Clinic enrolment code *',
                      helperText:
                          'Issued by the pilot coordinator. Doctor accounts '
                          'cannot be created without it.',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter the enrolment code.'
                        : null,
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _patientId,
                    decoration: const InputDecoration(
                      labelText: 'Patient ID (optional)',
                      helperText:
                          'If your clinic gave you an ID, enter it. Otherwise '
                          'one is created for you.',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return RegExp(r'^[A-Za-z0-9/_-]{3,32}$').hasMatch(value)
                          ? null
                          : '3 to 32 letters, numbers, dash, slash, underscore.';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age in years *',
                      helperText:
                          'Used as a risk factor, so it must be accurate.',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) {
                      final parsed = int.tryParse(v?.trim() ?? '');
                      if (parsed == null) return 'Enter your age in numbers.';
                      if (parsed < 0 || parsed > 120) {
                        return 'Enter an age between 0 and 120.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender *',
                      helperText: 'Recorded with your clinical record.',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: _genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select your gender.' : null,
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Contact and emergency details',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Optional now — you can add or change these any time under '
                    'My profile.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      helperText: 'So a centre can reach you about a referral.',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: _optionalPhone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Town or city',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _medicalHistory,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Relevant medical history',
                      hintText: 'e.g. diabetes, previous radiotherapy',
                      prefixIcon: Icon(Icons.medical_information_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emergencyName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact name',
                      prefixIcon: Icon(Icons.emergency_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emergencyPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency contact number',
                      prefixIcon: Icon(Icons.phone_in_talk_outlined),
                    ),
                    validator: _optionalPhone,
                  ),
                ],

                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 20),
                NoticeBanner(
                  message: _isDoctor
                      ? 'You will only see records that a patient has chosen to '
                            'send to you.'
                      : 'Your password is handled by Firebase Authentication '
                            'and never stored in the database. Your record is '
                            'visible to a clinician only if you choose to share '
                            'it.',
                  severity: NoticeSeverity.info,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  String? _sex;
  bool _busy = false;
  String? _error;

  static const List<String> _sexOptions = [
    'Female',
    'Male',
    'Other',
    'Prefer not to say',
  ];

  bool get _isDoctor => widget.role == UserRole.doctor;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _fullName.dispose();
    _patientId.dispose();
    _age.dispose();
    _enrolmentCode.dispose();
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
            )
          : await session.auth.registerPatient(
              username: _username.text,
              password: _password.text,
              preferredPatientId: _patientId.text,
              fullName: _fullName.text,
              age: int.parse(_age.text.trim()),
              sex: _sex,
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
      appBar: AppBar(title: Text('New ${widget.role.label.toLowerCase()} account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  NoticeBanner(message: _error!, severity: NoticeSeverity.alert),
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
                    labelText: _isDoctor ? 'Name' : 'Name (optional)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),

                if (_isDoctor) ...[
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
                    initialValue: _sex,
                    decoration: const InputDecoration(
                      labelText: 'Sex (optional)',
                      prefixIcon: Icon(Icons.wc_outlined),
                    ),
                    items: _sexOptions
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (value) => setState(() => _sex = value),
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
                      ? 'Doctor accounts can only see records that a patient '
                          'has explicitly consented to share.'
                      : 'Your password is stored only as a salted hash. Your '
                          'record stays on this device unless you choose to '
                          'share it with a doctor.',
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

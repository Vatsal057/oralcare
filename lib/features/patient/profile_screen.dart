import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/clinical_terms.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/session_controller.dart';

/// Profile and medical background (Section 1 of the CareConnect specification).
///
/// Registration captures these, but they change over time — medication and
/// emergency contacts especially — so they must be editable afterwards.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _medicalHistory = TextEditingController();
  final _allergies = TextEditingController();
  final _medications = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();

  String? _gender;
  bool _busy = false;
  String? _error;

  static const List<String> _genderOptions = ClinicalTerms.genderFormOptions;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().requireUser;
    _fullName.text = user.fullName ?? '';
    _age.text = user.age?.toString() ?? '';
    _gender = user.gender;
    _phone.text = user.phone ?? '';
    _email.text = user.email ?? '';
    _city.text = user.city ?? '';
    _pincode.text = user.pincode ?? '';
    _medicalHistory.text = user.medicalHistory ?? '';
    _allergies.text = user.allergies ?? '';
    _medications.text = user.currentMedications ?? '';
    _emergencyName.text = user.emergencyContactName ?? '';
    _emergencyPhone.text = user.emergencyContactPhone ?? '';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _age.dispose();
    _phone.dispose();
    _email.dispose();
    _city.dispose();
    _pincode.dispose();
    _medicalHistory.dispose();
    _allergies.dispose();
    _medications.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<SessionController>().updateProfile(
        fullName: _fullName.text,
        age: int.tryParse(_age.text.trim()),
        gender: _gender,
        phone: _phone.text,
        email: _email.text,
        city: _city.text,
        pincode: _pincode.text,
        medicalHistory: _medicalHistory.text,
        allergies: _allergies.text,
        currentMedications: _medications.text,
        emergencyContactName: _emergencyName.text,
        emergencyContactPhone: _emergencyPhone.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Profile saved.');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save your profile. $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().requireUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                NoticeBanner(message: _error!, severity: NoticeSeverity.alert),
                const SizedBox(height: 14),
              ],

              if (user.isGuest)
                const NoticeBanner(
                  title: 'Guest mode',
                  message:
                      'Guest profiles are not saved. Create an account to keep '
                      'your details.',
                  severity: NoticeSeverity.caution,
                ),

              SectionCard(
                title: 'About you',
                icon: Icons.person_outline,
                subtitle: 'Patient ID ${user.patientId ?? '—'}',
                children: [
                  TextFormField(
                    controller: _fullName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age in years *',
                      helperText: 'Used as a risk factor, so keep it accurate.',
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
                    decoration: const InputDecoration(labelText: 'Gender *'),
                    items: _genderOptions
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => _gender = value),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select your gender.' : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SectionCard(
                title: 'Contact and location',
                icon: Icons.contact_phone_outlined,
                subtitle:
                    'Used so a centre can reach you about a referral or '
                    'follow-up.',
                children: [
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                    ),
                    validator: _optionalPhone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return value.contains('@') && value.contains('.')
                          ? null
                          : 'Enter a valid email address.';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Town or city',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pincode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'PIN code'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      return RegExp(r'^\d{6}$').hasMatch(value)
                          ? null
                          : 'A PIN code is 6 digits.';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SectionCard(
                title: 'Medical background',
                icon: Icons.medical_information_outlined,
                subtitle:
                    'Shown to a clinician reviewing a record you choose to '
                    'share.',
                children: [
                  TextFormField(
                    controller: _medicalHistory,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Relevant medical history',
                      hintText: 'e.g. diabetes, previous radiotherapy',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _allergies,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Allergies',
                      hintText: 'e.g. penicillin, latex',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _medications,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Current medications',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              SectionCard(
                title: 'Emergency contact',
                icon: Icons.emergency_outlined,
                subtitle: 'Who should be called if you need urgent help.',
                children: [
                  TextFormField(
                    controller: _emergencyName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Contact name',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emergencyPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact number',
                    ),
                    validator: _optionalPhone,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy || user.isGuest ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save profile'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Blank is allowed; anything entered must look like a usable number.
  String? _optionalPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return digits.length >= 10 ? null : 'Enter at least 10 digits.';
  }
}

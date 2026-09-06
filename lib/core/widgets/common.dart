import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared date formats so every screen renders dates identically.
class AppFormats {
  const AppFormats._();

  static final DateFormat date = DateFormat('d MMM yyyy');
  static final DateFormat dateTime = DateFormat('d MMM yyyy, HH:mm');

  static String d(DateTime? value) => value == null ? '—' : date.format(value);
  static String dt(DateTime? value) =>
      value == null ? '—' : dateTime.format(value);

  /// Renders a nullable Yes/No field, keeping "not recorded" distinct from "No".
  static String yesNo(bool? value) => switch (value) {
    true => 'Yes',
    false => 'No',
    null => 'Not recorded',
  };

  /// Human-readable duration from a day count.
  static String duration(int? days) {
    if (days == null) return '—';
    if (days < 7) return '$days day${days == 1 ? '' : 's'}';
    final weeks = days ~/ 7;
    final remainder = days % 7;
    final weekText = '$weeks week${weeks == 1 ? '' : 's'}';
    if (remainder == 0) return weekText;
    return '$weekText $remainder day${remainder == 1 ? '' : 's'}';
  }
}

/// A titled section with optional subtitle, used to structure long forms.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Informational / warning banner. `severity` controls colour and icon, and the
/// icon is always present so meaning never depends on colour alone.
enum NoticeSeverity { info, caution, alert, success }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.message,
    this.severity = NoticeSeverity.info,
    this.title,
  });

  final String message;
  final String? title;
  final NoticeSeverity severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (Color background, Color foreground, IconData icon) = switch (severity) {
      NoticeSeverity.info => (
        isDark ? const Color(0xFF10344F) : const Color(0xFFE7F2FA),
        isDark ? Colors.white : const Color(0xFF0B4A6F),
        Icons.info_outline,
      ),
      NoticeSeverity.caution => (
        isDark ? const Color(0xFF4A3A00) : const Color(0xFFFFF7E0),
        isDark ? Colors.white : const Color(0xFF6B5200),
        Icons.warning_amber_rounded,
      ),
      NoticeSeverity.alert => (
        isDark ? const Color(0xFF5C0F0F) : const Color(0xFFFDECEA),
        isDark ? Colors.white : const Color(0xFF8C1D18),
        Icons.error_outline,
      ),
      NoticeSeverity.success => (
        isDark ? const Color(0xFF11431B) : const Color(0xFFE7F6E9),
        isDark ? Colors.white : const Color(0xFF1B5E20),
        Icons.check_circle_outline,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single-choice question rendered as a vertical list of radio rows.
///
/// Uses full-width tappable rows rather than a compact dropdown, because the
/// intended users include people reading small text on a low-end phone.
class SingleChoiceField<T> extends StatelessWidget {
  const SingleChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.labelBuilder,
    required this.value,
    required this.onChanged,
    this.note,
    this.isRequired = true,
    this.showError = false,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelBuilder;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? note;
  final bool isRequired;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = showError && isRequired && value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              text: label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              children: [
                if (isRequired)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
              ],
            ),
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: hasError ? 2 : 1,
            ),
          ),
          child: RadioGroup<T>(
            groupValue: value,
            onChanged: onChanged,
            child: Column(
              children: [
                for (var i = 0; i < options.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  RadioListTile<T>(
                    value: options[i],
                    title: Text(labelBuilder(options[i])),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        i == 0 || i == options.length - 1 ? 11 : 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Please choose an answer.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Yes / No pair with an explicit unset state, for clinician fields where
/// "not recorded" must stay distinguishable from "No".
class YesNoField extends StatelessWidget {
  const YesNoField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                helper!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
          SegmentedButton<bool?>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
              ButtonSegment(value: null, label: Text('Not recorded')),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

/// Label/value row used throughout the read-only record views.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: emphasise ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen empty state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Shows a short confirmation message.
void showSnack(BuildContext context, String message, {bool isError = false}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

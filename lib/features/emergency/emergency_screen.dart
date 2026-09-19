import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const List<_EmergencyCondition> _conditions = [
    _EmergencyCondition(
      title: 'Severe / Uncontrolled Oral Bleeding',
      icon: Icons.bloodtype_outlined,
      immediateAction:
          'Place a clean sterile gauze or rolled cotton pad directly over the '
          'bleeding site. Bite down firmly or apply continuous finger pressure for '
          '20 full minutes without lifting. Keep your head elevated and lean slightly forward '
          'to avoid swallowing blood. Do NOT rinse vigorously with water.',
      whenToCall:
          'If bleeding does not stop after 20 minutes of firm direct pressure, '
          'or if blood is pooling in large amounts, go to the nearest hospital casualty immediately.',
    ),
    _EmergencyCondition(
      title: 'Difficulty Breathing or Noisy Breathing (Stridor)',
      icon: Icons.air,
      immediateAction:
          'Sit upright immediately. Do not lie flat. Large tumors of the tongue, '
          'floor of mouth, or pharynx can rapidly obstruct the upper airway. '
          'Loosen any tight clothing around the neck.',
      whenToCall:
          'AIRWAY EMERGENCY. Call 112 or 108 immediately or have someone drive you to the '
          'nearest emergency room with ENT / Maxillofacial on-call coverage.',
    ),
    _EmergencyCondition(
      title: 'Rapidly Increasing Swelling in Neck or Face',
      icon: Icons.sentiment_very_dissatisfied,
      immediateAction:
          'Fast-spreading submandibular swelling can indicate deep neck space '
          'infection or acute Ludwig’s angina, which can push the tongue upward and block the airway.',
      whenToCall:
          'Seek emergency clinical attention immediately if swelling is hot, firm, rapidly expanding, '
          'or accompanied by difficulty opening the mouth or speaking.',
    ),
    _EmergencyCondition(
      title: 'Inability to Swallow Saliva or Fluids',
      icon: Icons.water_drop_outlined,
      immediateAction:
          'Acute dysphagia prevents intake of fluids and essential medications, '
          'leading to rapid dehydration and aspiration into the lungs.',
      whenToCall:
          'If you cannot swallow your own saliva or fluids for more than 6 hours, '
          'present to the hospital for intravenous hydration and airway evaluation.',
    ),
    _EmergencyCondition(
      title: 'High Fever (>100.4°F / 38°C) During Chemotherapy',
      icon: Icons.thermostat_outlined,
      immediateAction:
          'Take your oral temperature with a thermometer. Do not take aspirin or ibuprofen '
          'without contacting your oncologist. Chemotherapy suppresses white blood cells (neutropenia).',
      whenToCall:
          'FEBRILE NEUTROPENIA IS A MEDICAL EMERGENCY. Contact your oncology daycare or '
          'hospital emergency department immediately for urgent blood counts and IV antibiotics.',
    ),
    _EmergencyCondition(
      title: 'Severe Post-Operative Complications',
      icon: Icons.healing_outlined,
      immediateAction:
          'If you recently had oral surgery or neck dissection, look for sudden '
          'tightening under the neck skin, active wound leakage, dark/blue discoloration of the reconstructed tissue flap, or foul odor.',
      whenToCall:
          'Contact your operating surgical oncology/OMFS team immediately or present to the '
          'hospital emergency room.',
    ),
  ];

  void _callNumber(BuildContext context, String number, String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Call $label'),
        content: Text(
          'Emergency Helpline Number:\n\n$number\n\n'
          'Use this line for immediate ambulance dispatch and emergency triage.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Guidance'),
        backgroundColor: theme.colorScheme.errorContainer,
        foregroundColor: theme.colorScheme.onErrorContainer,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Top Emergency Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Immediate Emergency Contacts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you are experiencing difficulty breathing, heavy uncontrolled bleeding, '
                    'or sudden acute airway obstruction, call emergency services immediately.',
                    style: TextStyle(color: Colors.white, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callNumber(
                            context,
                            '112',
                            'National Emergency Helpline (112)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.call),
                          label: const Text(
                            'Call 112',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _callNumber(
                            context,
                            '108',
                            'National Ambulance Service (108)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.medical_services),
                          label: const Text(
                            'Ambulance 108',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Urgent Situations Protocol',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Action guides for critical oral conditions specified in clinical protocols.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),

            for (final condition in _conditions)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              condition.icon,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                condition.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'IMMEDIATE FIRST STEP:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          condition.immediateAction,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  condition.whenToCall,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onErrorContainer,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCondition {
  const _EmergencyCondition({
    required this.title,
    required this.icon,
    required this.immediateAction,
    required this.whenToCall,
  });

  final String title;
  final IconData icon;
  final String immediateAction;
  final String whenToCall;
}

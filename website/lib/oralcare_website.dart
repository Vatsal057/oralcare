import 'package:flutter/material.dart';

class OralCareWebsite extends StatelessWidget {
  const OralCareWebsite({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF10201E);
    const teal = Color(0xFF00695C);
    return MaterialApp(
      title: 'OralCare | Early awareness, clearer next steps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        scaffoldBackgroundColor: const Color(0xFFF7FAF8),
        fontFamily: 'Arial',
      ),
      home: const _WebsiteHome(ink: ink, teal: teal),
    );
  }
}

class _WebsiteHome extends StatefulWidget {
  const _WebsiteHome({required this.ink, required this.teal});

  final Color ink;
  final Color teal;

  @override
  State<_WebsiteHome> createState() => _WebsiteHomeState();
}

class _WebsiteHomeState extends State<_WebsiteHome> {
  final _scrollController = ScrollController();
  final _howItWorksKey = GlobalKey();
  final _safetyKey = GlobalKey();
  final _pilotKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _showAndroidNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Built for the Android pilot'),
        content: const Text(
          'OralCare is currently tested as an Android pilot. To use the app, '
          'install the Android build from your approved project distribution. '
          'This website explains the pilot and does not collect health data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _SiteHeader(
                    compact: compact,
                    onHowItWorks: () => _scrollTo(_howItWorksKey),
                    onSafety: () => _scrollTo(_safetyKey),
                    onPilot: () => _scrollTo(_pilotKey),
                    onAndroid: _showAndroidNotice,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Hero(
                    compact: compact,
                    onExplore: () => _scrollTo(_howItWorksKey),
                    onAndroid: _showAndroidNotice,
                  ),
                ),
                SliverToBoxAdapter(child: _TrustStrip(compact: compact)),
                SliverToBoxAdapter(
                  child: _Section(
                    key: _howItWorksKey,
                    tint: const Color(0xFFE3F1ED),
                    child: _HowItWorks(compact: compact),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(child: _PeopleSection(compact: compact)),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    key: _safetyKey,
                    tint: const Color(0xFF143C36),
                    child: _SafetySection(compact: compact),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _Section(
                    key: _pilotKey,
                    child: _PilotSection(
                      compact: compact,
                      onAndroid: _showAndroidNotice,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: _Footer()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({
    required this.compact,
    required this.onHowItWorks,
    required this.onSafety,
    required this.onPilot,
    required this.onAndroid,
  });

  final bool compact;
  final VoidCallback onHowItWorks;
  final VoidCallback onSafety;
  final VoidCallback onPilot;
  final VoidCallback onAndroid;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7FAF8),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 48,
        vertical: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _Wordmark(),
            if (!compact)
              Row(
                children: [
                  _NavButton(label: 'How it works', onPressed: onHowItWorks),
                  _NavButton(label: 'Safety', onPressed: onSafety),
                  _NavButton(label: 'Pilot', onPressed: onPilot),
                  const SizedBox(width: 14),
                  FilledButton.tonal(
                    onPressed: onAndroid,
                    child: const Text('Android app'),
                  ),
                ],
              )
            else
              IconButton(
                tooltip: 'About the Android app',
                onPressed: onAndroid,
                icon: const Icon(Icons.android_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Mark(size: 34),
        SizedBox(width: 10),
        Text(
          'OralCare',
          style: TextStyle(
            color: Color(0xFF10201E),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF00695C),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.health_and_safety_outlined,
        color: Colors.white,
        size: size * .58,
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(color: Color(0xFF24423D))),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.compact,
    required this.onExplore,
    required this.onAndroid,
  });

  final bool compact;
  final VoidCallback onExplore;
  final VoidCallback onAndroid;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Pill(label: 'ORAL HEALTH AWARENESS PILOT'),
        const SizedBox(height: 24),
        Text(
          'Make room for an earlier conversation.',
          style: TextStyle(
            color: const Color(0xFF10201E),
            fontSize: compact ? 42 : 68,
            height: .98,
            letterSpacing: -2.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            'OralCare helps people notice changes, complete a structured self-check, '
            'and take the next sensible step — with a consented clinician review pathway.',
            style: TextStyle(
              color: Color(0xFF36514C),
              fontSize: 18,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.arrow_downward_rounded),
              label: const Text('Explore the pilot'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 17,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAndroid,
              icon: const Icon(Icons.android_rounded),
              label: const Text('Android availability'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00695C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _ClinicalBoundary(),
      ],
    );

    return Container(
      color: const Color(0xFFF7FAF8),
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 48,
        48,
        compact ? 20 : 48,
        72,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: compact
            ? Column(
                children: [
                  content,
                  const SizedBox(height: 44),
                  const _CareIllustration(),
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 11, child: content),
                  const SizedBox(width: 64),
                  const Expanded(flex: 9, child: _CareIllustration()),
                ],
              ),
      ),
    );
  }
}

class _ClinicalBoundary extends StatelessWidget {
  const _ClinicalBoundary();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, color: Color(0xFF00695C), size: 20),
      SizedBox(width: 9),
      Expanded(
        child: Text(
          'Awareness and referral support — not a cancer diagnosis or a substitute for clinical care.',
          style: TextStyle(color: Color(0xFF36514C), height: 1.4),
        ),
      ),
    ],
  );
}

class _CareIllustration extends StatelessWidget {
  const _CareIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFC9E4DB),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 34,
              right: 40,
              child: _Circle(size: 84, color: const Color(0xFFEF9C74)),
            ),
            Positioned(
              bottom: 42,
              left: 36,
              child: _Circle(size: 122, color: const Color(0xFFFAE8B9)),
            ),
            Transform.rotate(
              angle: -.12,
              child: Container(
                width: 210,
                height: 320,
                decoration: BoxDecoration(
                  color: const Color(0xFF143C36),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x330D2B26),
                      blurRadius: 24,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          _Mark(size: 24),
                          SizedBox(width: 7),
                          Text(
                            'OralCare',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Your mouth\nself-check',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.06,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 7,
                        width: 116,
                        decoration: BoxDecoration(
                          color: const Color(0xFF83D1BD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        height: 7,
                        width: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF39655D),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Color(0xFF00695C),
                              size: 17,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Begin',
                              style: TextStyle(
                                color: Color(0xFF00695C),
                                fontWeight: FontWeight.w700,
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
            Positioned(
              right: 19,
              bottom: 80,
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A10201E), blurRadius: 16),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.visibility_outlined, color: Color(0xFF00695C)),
                    SizedBox(height: 7),
                    Text(
                      'Notice changes early',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF00695C),
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 48, vertical: 22),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1240),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 28,
        runSpacing: 16,
        children: const [
          _TrustItem(
            icon: Icons.fact_check_outlined,
            text: 'Structured self-check',
          ),
          _TrustItem(
            icon: Icons.lock_outline_rounded,
            text: 'Consent comes first',
          ),
          _TrustItem(
            icon: Icons.people_outline_rounded,
            text: 'Patient + clinician views',
          ),
          _TrustItem(
            icon: Icons.follow_the_signs_outlined,
            text: 'Clear follow-up steps',
          ),
        ],
      ),
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: const Color(0xFFBCE6DA), size: 20),
      const SizedBox(width: 9),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({super.key, required this.child, this.tint});
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) => Container(
    color: tint ?? const Color(0xFFF7FAF8),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 88),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1144),
        child: child,
      ),
    ),
  );
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Pill(label: 'A CALMER STARTING POINT'),
      const SizedBox(height: 18),
      Text(
        'One guided check.\nA more useful next step.',
        style: TextStyle(
          fontSize: compact ? 36 : 52,
          height: 1.03,
          letterSpacing: -1.7,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF10201E),
        ),
      ),
      const SizedBox(height: 48),
      LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final items = const [
            _Step(
              number: '01',
              title: 'Answer with context',
              body:
                  'A structured check asks about known risks, symptoms, and the duration of any change.',
            ),
            _Step(
              number: '02',
              title: 'Look with guidance',
              body:
                  'A seven-site mouth self-examination gives people a clear, paced way to observe.',
            ),
            _Step(
              number: '03',
              title: 'Act on the result',
              body:
                  'Red flags and persistence rules take priority, making the follow-up direction explicit.',
            ),
          ];
          return narrow
              ? Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: item,
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: [
                    for (final item in items)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: item,
                        ),
                      ),
                  ],
                );
        },
      ),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        style: const TextStyle(
          color: Color(0xFF00695C),
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 17),
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF10201E),
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 11),
      Text(
        body,
        style: const TextStyle(
          color: Color(0xFF36514C),
          fontSize: 16,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 760;
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(label: 'TWO VIEWS, ONE CONSENTED PATHWAY'),
          const SizedBox(height: 18),
          Text(
            'Designed to make the handoff clearer.',
            style: TextStyle(
              fontSize: compact ? 36 : 50,
              height: 1.03,
              letterSpacing: -1.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF10201E),
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              'The pilot keeps the patient in control of what is shared, while clinicians receive the details they need to review a consented record.',
              style: TextStyle(
                color: Color(0xFF36514C),
                fontSize: 17,
                height: 1.55,
              ),
            ),
          ),
        ],
      );
      final paths = const _PathCards();
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 36), paths],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 68),
                const Expanded(child: _PathCards()),
              ],
            );
    },
  );
}

class _PathCards extends StatelessWidget {
  const _PathCards();
  @override
  Widget build(BuildContext context) => Column(
    children: const [
      _PathCard(
        icon: Icons.person_outline_rounded,
        heading: 'For people checking in',
        copy:
            'Risk and symptom prompts, a self-examination guide, and plain-language follow-up direction.',
        color: Color(0xFFE7F4EF),
      ),
      SizedBox(height: 16),
      _PathCard(
        icon: Icons.medical_services_outlined,
        heading: 'For clinician review',
        copy:
            'A consent-filtered queue for reviewing a patient’s shared check and recording next actions.',
        color: Color(0xFFFFEDDF),
      ),
    ],
  );
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.icon,
    required this.heading,
    required this.copy,
    required this.color,
  });
  final IconData icon;
  final String heading;
  final String copy;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF00695C)),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  color: Color(0xFF10201E),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                copy,
                style: const TextStyle(color: Color(0xFF36514C), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SafetySection extends StatelessWidget {
  const _SafetySection({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 760;
      final statement = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(label: 'CLINICAL BOUNDARIES', dark: true),
          const SizedBox(height: 20),
          Text(
            'Clear about what\nOralCare can — and cannot — do.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 36 : 50,
              height: 1.04,
              letterSpacing: -1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'The pilot is designed to support awareness, early recognition, and referral. It does not diagnose, stage, or rule out oral cancer.',
            style: TextStyle(
              color: Color(0xFFCEE2DC),
              fontSize: 17,
              height: 1.55,
            ),
          ),
        ],
      );
      final points = const Column(
        children: [
          _SafetyPoint(
            icon: Icons.priority_high_rounded,
            text:
                'Persistent red-flag findings take priority over a numerical score.',
          ),
          SizedBox(height: 17),
          _SafetyPoint(
            icon: Icons.visibility_outlined,
            text: 'Results explain the reasons behind the next-step guidance.',
          ),
          SizedBox(height: 17),
          _SafetyPoint(
            icon: Icons.lock_outline_rounded,
            text:
                'A patient chooses whether a record enters the clinician review queue.',
          ),
        ],
      );
      return stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [statement, const SizedBox(height: 36), points],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: statement),
                const SizedBox(width: 80),
                const Expanded(child: _SafetyPoints()),
              ],
            );
    },
  );
}

class _SafetyPoints extends StatelessWidget {
  const _SafetyPoints();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      _SafetyPoint(
        icon: Icons.priority_high_rounded,
        text:
            'Persistent red-flag findings take priority over a numerical score.',
      ),
      SizedBox(height: 17),
      _SafetyPoint(
        icon: Icons.visibility_outlined,
        text: 'Results explain the reasons behind the next-step guidance.',
      ),
      SizedBox(height: 17),
      _SafetyPoint(
        icon: Icons.lock_outline_rounded,
        text:
            'A patient chooses whether a record enters the clinician review queue.',
      ),
    ],
  );
}

class _SafetyPoint extends StatelessWidget {
  const _SafetyPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFF1E5149),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFBCE6DA)),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _PilotSection extends StatelessWidget {
  const _PilotSection({required this.compact, required this.onAndroid});
  final bool compact;
  final VoidCallback onAndroid;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 28 : 48),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8D8),
      borderRadius: BorderRadius.circular(28),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 680;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For the pilot,\nkeep it practical.',
              style: TextStyle(
                color: Color(0xFF10201E),
                fontSize: 38,
                height: 1.03,
                letterSpacing: -1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'OralCare currently runs on Android. The website is a public guide to the project; it does not sign people in or handle medical information.',
              style: TextStyle(
                color: Color(0xFF5B4436),
                fontSize: 17,
                height: 1.5,
              ),
            ),
          ],
        );
        final action = FilledButton.icon(
          onPressed: onAndroid,
          icon: const Icon(Icons.android_rounded),
          label: const Text('About the Android app'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10201E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          ),
        );
        return stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, const SizedBox(height: 28), action],
              )
            : Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: 40),
                  action,
                ],
              );
      },
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.dark = false});
  final String label;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF1E5149) : const Color(0xFFD6EEE7),
      borderRadius: BorderRadius.circular(40),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: dark ? const Color(0xFFCBE7DF) : const Color(0xFF075649),
        fontSize: 11,
        letterSpacing: .7,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF10201E),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1144),
        child: Row(
          children: [
            Expanded(child: _WordmarkFooter()),
            Text(
              'OralCare pilot · Not a diagnostic tool',
              style: TextStyle(color: Color(0xFFB7CBC6)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WordmarkFooter extends StatelessWidget {
  const _WordmarkFooter();
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _Mark(size: 28),
      SizedBox(width: 9),
      Text(
        'OralCare',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

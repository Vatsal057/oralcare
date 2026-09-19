import 'package:flutter/material.dart';

import '../../domain/education/education_catalog.dart';
import '../../domain/education/education_models.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  EducationLanguage _currentLanguage = EducationLanguage.english;
  TopicCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTopics = EducationCatalog.topics.where((t) {
      if (_selectedCategory != null && t.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final titleMatch = t.title(_currentLanguage).toLowerCase().contains(q);
        final summaryMatch = t
            .summary(_currentLanguage)
            .toLowerCase()
            .contains(q);
        return titleMatch || summaryMatch;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oral Cancer Education'),
        actions: [
          PopupMenuButton<EducationLanguage>(
            tooltip: 'Select Language',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language),
                const SizedBox(width: 4),
                Text(
                  _currentLanguage.code.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
              ],
            ),
            initialValue: _currentLanguage,
            onSelected: (lang) => setState(() => _currentLanguage = lang),
            itemBuilder: (context) => [
              for (final lang in EducationLanguage.values)
                PopupMenuItem(
                  value: lang,
                  child: Row(
                    children: [
                      if (lang == _currentLanguage)
                        const Icon(Icons.check, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(lang.label),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search symptoms, risk factors, biopsy...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),

            // Category Filter Carousel
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Topics'),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  for (final cat in TopicCategory.values) ...[
                    ChoiceChip(
                      label: Text(cat.label),
                      selected: _selectedCategory == cat,
                      onSelected: (sel) =>
                          setState(() => _selectedCategory = sel ? cat : null),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Special Sections based on filter or view
            if (_selectedCategory == null ||
                _selectedCategory == TopicCategory.mythsFacts) ...[
              if (_searchQuery.isEmpty &&
                  _selectedCategory == TopicCategory.mythsFacts)
                const SizedBox.shrink()
              else if (_selectedCategory == null) ...[
                _buildSectionHeader(
                  context,
                  title: 'Myths vs. Facts',
                  subtitle:
                      'Common misconceptions dispelled by clinical evidence',
                  icon: Icons.psychology_alt_outlined,
                ),
                const SizedBox(height: 10),
                for (final item in EducationCatalog.mythsAndFacts.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MythFactCard(item: item),
                  ),
                const SizedBox(height: 16),
              ],
            ],

            if (_selectedCategory == TopicCategory.mythsFacts) ...[
              _buildSectionHeader(
                context,
                title: 'All Myths vs. Facts',
                subtitle: 'Evidence-based clinical clarifications',
                icon: Icons.psychology_alt_outlined,
              ),
              const SizedBox(height: 12),
              for (final item in EducationCatalog.mythsAndFacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MythFactCard(item: item),
                ),
            ] else if (_selectedCategory == TopicCategory.faqs) ...[
              _buildSectionHeader(
                context,
                title: 'Frequently Asked Questions',
                subtitle: 'Common questions from patients and families',
                icon: Icons.help_outline,
              ),
              const SizedBox(height: 12),
              for (final faq in EducationCatalog.faqs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FaqCard(faq: faq),
                ),
            ] else ...[
              _buildSectionHeader(
                context,
                title: 'Core Education Modules',
                subtitle: 'Review clinical guides in your preferred language',
                icon: Icons.menu_book_outlined,
              ),
              const SizedBox(height: 12),
              for (final topic in filteredTopics)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TopicCard(topic: topic, language: _currentLanguage),
                ),

              if (_selectedCategory == null && _searchQuery.isEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader(
                  context,
                  title: 'Frequently Asked Questions',
                  subtitle: 'Quick answers for patients',
                  icon: Icons.help_outline,
                ),
                const SizedBox(height: 10),
                for (final faq in EducationCatalog.faqs.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FaqCard(faq: faq),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.language});

  final EducationTopic topic;
  final EducationLanguage language;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  _TopicDetailScreen(topic: topic, initialLanguage: language),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.article_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title(language),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.summary(language),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicDetailScreen extends StatefulWidget {
  const _TopicDetailScreen({
    required this.topic,
    required this.initialLanguage,
  });

  final EducationTopic topic;
  final EducationLanguage initialLanguage;

  @override
  State<_TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<_TopicDetailScreen> {
  late EducationLanguage _language;

  @override
  void initState() {
    super.initState();
    _language = widget.initialLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = widget.topic.sections(_language);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic.title(_language)),
        actions: [
          PopupMenuButton<EducationLanguage>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate),
            initialValue: _language,
            onSelected: (lang) => setState(() => _language = lang),
            itemBuilder: (context) => [
              for (final lang in EducationLanguage.values)
                PopupMenuItem(value: lang, child: Text(lang.label)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.topic.title(_language),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.topic.summary(_language),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const Divider(height: 32),
            for (final section in sections) ...[
              Text(
                section.heading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                section.body,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              if (section.bulletPoints.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final pt in section.bulletPoints)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            pt,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (section.caution != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.caution!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _MythFactCard extends StatelessWidget {
  const _MythFactCard({required this.item});

  final MythFactItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'MYTH',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.myth,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FACT',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.fact,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({required this.faq});

  final FaqItem faq;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            faq.answer,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferAndEarnPage extends StatelessWidget {
  final String referralCode;
  final String userName;

  const ReferAndEarnPage({
    super.key,
    required this.referralCode,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.secondary, scheme.primary],
    );

    final trimmedName = userName.trim();
    final friendlyName = trimmedName.isEmpty
        ? 'there'
        : trimmedName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF4DF),
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradient)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $friendlyName,',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Invite three friends to unlock Level 1 and grow together.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            referralCode,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.secondary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy code',
                          splashRadius: 22,
                          icon: const Icon(Icons.copy_rounded),
                          color: scheme.secondary,
                          onPressed: () => _copyCode(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share this code via WhatsApp, email, or in person. Every successful signup brings you closer to the next level.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _ReferFlowLegend(),
            const SizedBox(height: 18),
            ..._levels.map((level) => _LevelExpansion(level: level)).toList(),
            const SizedBox(height: 18),
            const _SupportCard(),
          ],
        ),
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Referral code copied'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.secondary,
      ),
    );
  }
}

class _ReferFlowLegend extends StatelessWidget {
  const _ReferFlowLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = [
      {
        'title': 'Invite three people',
        'description':
            'Start with B, C, and D. Once they join, you become Level 1.',
      },
      {
        'title': 'Help them repeat',
        'description':
            'Guide each friend to invite their own three partners to level up.',
      },
      {
        'title': 'Grow together',
        'description':
            'As every layer completes its three invites, everyone moves up.',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How the 3x network works',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1F1F1F),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 12),
              child: _LegendRow(
                index: i + 1,
                title: items[i]['title']!,
                description: items[i]['description']!,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _LegendRow({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            index.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF1F1F1F),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B6B6B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelExpansion extends StatelessWidget {
  final _ReferralLevel level;

  const _LevelExpansion({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.secondary, scheme.primary],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: ValueKey(level.badge),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          iconColor: scheme.secondary,
          collapsedIconColor: scheme.secondary,
          title: Text(
            level.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF1F1F1F),
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              level.summary,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ),
          leading: Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              level.badge,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final point in level.bulletPoints) _BulletRow(text: point),
                if (level.networkRows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _NetworkDiagram(rows: level.networkRows),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;

  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF3C3C3C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkDiagram extends StatelessWidget {
  final List<List<String>> rows;

  const _NetworkDiagram({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Network snapshot',
          style: theme.textTheme.titleSmall?.copyWith(
            color: const Color(0xFF1F1F1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: row
                  .map(
                    (entry) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        entry,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: scheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tip: Keep momentum going',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Celebrate every new referral and support teammates with quick answers. A confident team keeps the 3x cycle moving.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B6B6B),
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

class _ReferralLevel {
  final String badge;
  final String title;
  final String summary;
  final List<String> bulletPoints;
  final List<List<String>> networkRows;

  const _ReferralLevel({
    required this.badge,
    required this.title,
    required this.summary,
    required this.bulletPoints,
    this.networkRows = const [],
  });
}

const List<_ReferralLevel> _levels = [
  _ReferralLevel(
    badge: 'L0',
    title: 'Level 0 - Getting started',
    summary: 'Begin by inviting three direct referrals.',
    bulletPoints: [
      'Share your JustStock referral code with friends and family.',
      'As soon as B, C, and D sign up using your code, you reach Level 1.',
      'These first three partners form your personal Level 1 network.',
    ],
    networkRows: [
      ['You (A)'],
      ['B', 'C', 'D'],
    ],
  ),
  _ReferralLevel(
    badge: 'L1',
    title: 'Level 1 - Team building',
    summary: 'Support B, C, and D to complete their own three invites.',
    bulletPoints: [
      'Each of your direct partners now shares the code with three new people.',
      'When they succeed, they also reach Level 1 and you advance to Level 2.',
      'Your total network becomes 12 members: you + 3 partners + their 9 invites.',
    ],
    networkRows: [
      ['You (Level 2)'],
      ['B', 'C', 'D'],
      ['B1', 'B2', 'B3', 'C1', 'C2', 'C3', 'D1', 'D2', 'D3'],
    ],
  ),
  _ReferralLevel(
    badge: 'L2',
    title: 'Level 2 - Momentum',
    summary: 'Every new member repeats the same three-person pattern.',
    bulletPoints: [
      'Encourage each partner on your team to keep the 3x growth going.',
      'This consistent duplication moves you to Level 3 with 39 people overall.',
      'Stay active with guidance, check-ins, and celebrate each milestone.',
    ],
  ),
  _ReferralLevel(
    badge: 'L3+',
    title: 'Levels 3 and beyond - Sustain and reward',
    summary: 'Repeating the 3x system unlocks higher rewards for everyone.',
    bulletPoints: [
      'Help new members get started quickly so their own Level 1 happens fast.',
      'Track your progress here and spot who needs a helping hand.',
      'Rewards unlock each time your team completes another full 3x layer.',
    ],
  ),
];

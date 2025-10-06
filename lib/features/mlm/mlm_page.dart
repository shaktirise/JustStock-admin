import 'package:flutter/material.dart';

import '../../theme.dart';

class MlmPage extends StatefulWidget {
  const MlmPage({super.key, required this.adminName});

  final String adminName;

  @override
  State<MlmPage> createState() => _MlmPageState();
}

class _MlmPageState extends State<MlmPage> {
  late final List<MlmMember> _leaders;
  late MlmMember _selectedLeader;

  @override
  void initState() {
    super.initState();
    _leaders = _buildSampleLeaders();
    _selectedLeader = _leaders.first;
  }

  List<MlmMember> _buildSampleLeaders() {
    final rootName = widget.adminName.trim().isEmpty
        ? 'Admin'
        : widget.adminName.trim();

    final rootNetwork = MlmMember(
      name: rootName,
      referrals: [
        MlmMember(
          name: 'Arjun',
          referrals: [
            MlmMember(name: 'Isha'),
            MlmMember(name: 'Kabir'),
            MlmMember(name: 'Maya'),
          ],
        ),
        MlmMember(
          name: 'Bhavna',
          referrals: [
            MlmMember(name: 'Nikhil'),
            MlmMember(name: 'Ojas'),
            MlmMember(name: 'Pia'),
          ],
        ),
        MlmMember(
          name: 'Chirag',
          referrals: [
            MlmMember(name: 'Ridhi'),
            MlmMember(name: 'Samar'),
            MlmMember(name: 'Tara'),
          ],
        ),
      ],
    );

    final legacyNetwork = MlmMember(
      name: 'Legacy Leader',
      referrals: [
        MlmMember(name: 'Uma'),
        MlmMember(name: 'Vivan'),
        MlmMember(
          name: 'Waseem',
          referrals: [
            MlmMember(name: 'Xena'),
            MlmMember(name: 'Yash'),
            MlmMember(name: 'Zara'),
          ],
        ),
      ],
    );

    return [rootNetwork, legacyNetwork];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Text('MLM Network'),
        toolbarHeight: 88,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: buildHeaderGradient()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the leader whose tree you want to inspect.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Downline root',
                prefixIcon: const Icon(Icons.account_tree_rounded),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MlmMember>(
                  value: _selectedLeader,
                  isExpanded: true,
                  items: [
                    for (final leader in _leaders)
                      DropdownMenuItem(value: leader, child: Text(leader.name)),
                  ],
                  onChanged: (leader) {
                    if (leader == null) return;
                    setState(() => _selectedLeader = leader);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            _MlmSummaryCard(member: _selectedLeader),
            const SizedBox(height: 24),
            _MlmMemberBranch(member: _selectedLeader, depth: 0),
          ],
        ),
      ),
    );
  }
}

class MlmMember {
  MlmMember({required this.name, List<MlmMember>? referrals})
    : referrals = referrals ?? const <MlmMember>[];

  final String name;
  final List<MlmMember> referrals;
}

class _MlmSummaryCard extends StatelessWidget {
  const _MlmSummaryCard({required this.member});

  final MlmMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = calculateMemberLevel(member);
    final downlineSize = countDownline(member);
    final milestone = buildNextMilestoneText(member);
    final levelLabel = level == 0 ? 'Not qualified yet' : 'Level $level';

    return Container(
      decoration: BoxDecoration(
        gradient: buildHeaderGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(255, 152, 0, 0.28),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    levelLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Track how your direct downline unlocks levels in the plan.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryStatRow(
                  icon: Icons.people_alt_rounded,
                  label: 'Direct referrals',
                  value: '${member.referrals.length} / 3',
                ),
                const SizedBox(height: 12),
                _SummaryStatRow(
                  icon: Icons.groups_3_rounded,
                  label: 'Total team size',
                  value: '$downlineSize',
                ),
                const SizedBox(height: 16),
                Text(
                  milestone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E6100),
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

class _SummaryStatRow extends StatelessWidget {
  const _SummaryStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            gradient: buildHeaderGradient(),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E6100),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3C3C3C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MlmMemberBranch extends StatelessWidget {
  const _MlmMemberBranch({required this.member, required this.depth});

  final MlmMember member;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRoot = depth == 0;
    final level = calculateMemberLevel(member);
    final textColor = isRoot ? Colors.white : const Color(0xFF3C3C3C);
    final iconColor = isRoot ? Colors.white : const Color(0xFFFF8F00);

    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactDevice = screenWidth < 360;
    final horizontalPadding = isCompactDevice
        ? (isRoot ? 16.0 : 12.0)
        : (isRoot ? 20.0 : 16.0);
    final verticalPadding = isCompactDevice
        ? (isRoot ? 14.0 : 10.0)
        : (isRoot ? 16.0 : 12.0);
    final childHorizontalPadding = isCompactDevice ? 8.0 : 12.0;
    final childBottomPadding = isCompactDevice ? 12.0 : 16.0;

    return Container(
      margin: EdgeInsets.only(
        left: isRoot ? 0 : (isCompactDevice ? 12 : 16),
        bottom: isCompactDevice ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: isRoot ? buildHeaderGradient() : null,
        color: isRoot ? null : Colors.white,
        borderRadius: BorderRadius.circular(isRoot ? 24 : 18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(255, 152, 0, 0.18),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('${member.name}-$depth'),
          initiallyExpanded: depth <= 1,
          tilePadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            childHorizontalPadding,
            0,
            childHorizontalPadding,
            childBottomPadding,
          ),
          iconColor: iconColor,
          collapsedIconColor: iconColor,
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          title: _MemberHeader(
            member: member,
            textColor: textColor,
            level: level,
            isRoot: isRoot,
          ),
          children: _buildChildren(context),
        ),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    final theme = Theme.of(context);

    if (member.referrals.isEmpty) {
      return [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No referrals yet.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ];
    }

    final widgets = <Widget>[_ReferralBadges(referrals: member.referrals)];

    if (depth <= 1) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_MilestoneBanner(message: buildNextMilestoneText(member)));
    }

    for (final referral in member.referrals) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_MlmMemberBranch(member: referral, depth: depth + 1));
    }

    return widgets;
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.member,
    required this.textColor,
    required this.level,
    required this.isRoot,
  });

  final MlmMember member;
  final Color textColor;
  final int level;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = member.name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final levelLabel = level == 0 ? 'Not qualified' : 'Level $level';

    final levelBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRoot
            ? Colors.white.withValues(alpha: 0.22)
            : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        levelLabel,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: isRoot ? Colors.white : const Color(0xFF8E6100),
        ),
      ),
    );

    final nameAndStats = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${member.referrals.length} direct '
          '${member.referrals.length == 1 ? 'referral' : 'referrals'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: textColor.withValues(alpha: isRoot ? 0.9 : 0.75),
          ),
        ),
      ],
    );

    final avatar = CircleAvatar(
      radius: 22,
      backgroundColor: isRoot
          ? Colors.white.withValues(alpha: 0.25)
          : const Color(0xFFFFECB3),
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: isRoot ? Colors.white : const Color(0xFFFF8F00),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 280;
        final rowChildren = <Widget>[
          avatar,
          const SizedBox(width: 12),
          Expanded(child: nameAndStats),
        ];

        if (!isCompact) {
          return Row(
            children: [...rowChildren, const SizedBox(width: 12), levelBadge],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: rowChildren),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: levelBadge,
            ),
          ],
        );
      },
    );
  }
}

class _ReferralBadges extends StatelessWidget {
  const _ReferralBadges({required this.referrals});

  final List<MlmMember> referrals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Direct team',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8E6100),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final referral in referrals) _ReferralChip(member: referral),
          ],
        ),
      ],
    );
  }
}

class _ReferralChip extends StatelessWidget {
  const _ReferralChip({required this.member});

  final MlmMember member;

  @override
  Widget build(BuildContext context) {
    final level = calculateMemberLevel(member);
    final trimmed = member.name.trim();
    final initials = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Chip(
      backgroundColor: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      avatar: CircleAvatar(
        backgroundColor: const Color(0xFFFFECB3),
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF8F00),
          ),
        ),
      ),
      label: Text('${member.name} Â· L$level'),
      labelStyle: const TextStyle(
        color: Color(0xFF8E6100),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MilestoneBanner extends StatelessWidget {
  const _MilestoneBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: Color(0xFFFF8F00)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8E6100),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

int countDownline(MlmMember member) {
  var total = member.referrals.length;
  for (final referral in member.referrals) {
    total += countDownline(referral);
  }
  return total;
}

int calculateMemberLevel(MlmMember member) {
  if (member.referrals.length < 3) {
    return 0;
  }

  final childLevels = [
    for (final referral in member.referrals) calculateMemberLevel(referral),
  ];

  var level = 1;
  // Each level requires every direct referral to already hold the previous level.
  while (childLevels.every((childLevel) => childLevel >= level)) {
    level += 1;
  }
  return level;
}

String buildNextMilestoneText(MlmMember member) {
  final currentLevel = calculateMemberLevel(member);
  final directReferrals = member.referrals.length;

  if (currentLevel == 0) {
    final missing = (3 - directReferrals).clamp(0, 3);
    if (missing > 0) {
      final suffix = missing == 1 ? '' : 's';
      return 'Needs $missing more direct referral$suffix to unlock Level 1.';
    }
    return 'Direct team is ready. Support them to add their own three referrals to unlock Level 1.';
  }

  final targetLevel = currentLevel;
  final lacking = member.referrals
      .where((referral) => calculateMemberLevel(referral) < targetLevel)
      .toList();

  if (lacking.isEmpty) {
    return 'All direct referrals are at Level $targetLevel. Duplicate this depth to move towards Level ${currentLevel + 1}.';
  }

  if (lacking.length == 1) {
    final referral = lacking.first;
    return '${referral.name} needs to reach Level $targetLevel to unlock Level ${currentLevel + 1} for ${member.name}.';
  }

  final names = lacking.map((referral) => referral.name).join(', ');
  return '${member.name} needs $names to reach Level $targetLevel to unlock Level ${currentLevel + 1}.';
}

import "package:flutter/material.dart";

class TotalUsersPage extends StatelessWidget {
  const TotalUsersPage({super.key});

  static final List<_UserMetric> _metrics = [
    _UserMetric(label: "Total users", value: "940", icon: Icons.people_outline),
    _UserMetric(label: "New this week", value: "84", icon: Icons.trending_up),
    _UserMetric(label: "Power users", value: "186", icon: Icons.flash_on_outlined),
    _UserMetric(label: "Churn risk", value: "21", icon: Icons.warning_amber_rounded),
  ];

  static final List<_RecentUser> _recentUsers = [
    _RecentUser(name: "Yash Patel", joinedOn: "Joined 02 Oct", source: "Campaign • UTM"),
    _RecentUser(name: "Sneha Rao", joinedOn: "Joined 02 Oct", source: "Referral • #ALPHA"),
    _RecentUser(name: "Manish Tiwari", joinedOn: "Joined 01 Oct", source: "Organic"),
    _RecentUser(name: "Lakshmi Iyer", joinedOn: "Joined 30 Sep", source: "Campaign • UTM"),
    _RecentUser(name: "Harsh Bajaj", joinedOn: "Joined 29 Sep", source: "Referral • #BETA"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final crossAxisCount = size.width >= 720 ? 2 : 1;
    final childAspectRatio = crossAxisCount == 1 ? 3.0 : 2.2;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Total Users"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final metric = _metrics[index];
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            metric.icon,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                metric.value,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                metric.label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              "Recent signups",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentUsers.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _recentUsers[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                      child: Text(
                        "${index + 1}",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.joinedOn,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.source,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserMetric {
  const _UserMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _RecentUser {
  const _RecentUser({
    required this.name,
    required this.joinedOn,
    required this.source,
  });

  final String name;
  final String joinedOn;
  final String source;
}

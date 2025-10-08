import "package:flutter/material.dart";

class ActiveUsersPage extends StatelessWidget {
  const ActiveUsersPage({super.key});

  static final List<_ActiveUser> _activeUsers = [
    _ActiveUser(name: "Ananya Singh", username: "@ananya_s", lastSeen: "Online now", plan: "Pro"),
    _ActiveUser(name: "Rohit Mehra", username: "@rohit.m", lastSeen: "Active 2m ago", plan: "Starter"),
    _ActiveUser(name: "Meera Varma", username: "@meerav", lastSeen: "Active 5m ago", plan: "Pro"),
    _ActiveUser(name: "Sahil Kapoor", username: "@sahil_k", lastSeen: "Active 8m ago", plan: "Starter"),
    _ActiveUser(name: "Priya Desai", username: "@priyad", lastSeen: "Active 12m ago", plan: "Enterprise"),
    _ActiveUser(name: "Farhan Ali", username: "@farhan98", lastSeen: "Active 15m ago", plan: "Pro"),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Users"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _activeUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = _activeUsers[index];
          return Card(
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
                child: Text(
                  user.initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.secondary,
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
                    user.username,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.lastSeen,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
              trailing: FilledButton.tonal(
                onPressed: () {},
                child: Text(user.plan),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveUser {
  const _ActiveUser({
    required this.name,
    required this.username,
    required this.lastSeen,
    required this.plan,
  });

  final String name;
  final String username;
  final String lastSeen;
  final String plan;

  String get initials {
    final parts = name.trim().split(RegExp(r"\\s+"));
    if (parts.length == 1) {
      final word = parts.first;
      final length = word.length >= 2 ? 2 : word.length;
      return word.substring(0, length).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

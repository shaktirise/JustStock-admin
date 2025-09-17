import "package:flutter/material.dart";

import "package:juststockadmin/features/profile/profile_page.dart";
import "../../theme.dart";

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.adminName,
    required this.adminMobile,
  });

  final String adminName;
  final String adminMobile;

  static const _actions = <_DashboardAction>[
    _DashboardAction(label: 'Nifty', icon: Icons.trending_up),
    _DashboardAction(label: 'BankNifty', icon: Icons.account_balance),
    _DashboardAction(label: 'Stocks', icon: Icons.insights),
    _DashboardAction(label: 'Sensex', icon: Icons.show_chart),
    _DashboardAction(label: 'Commodity', icon: Icons.auto_graph),
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      HomePage._actions.length,
      (_) => TextEditingController(),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfilePage(
          adminName: widget.adminName,
          adminMobile: widget.adminMobile,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleSubmit() {
    final filledMessages = <String>[];
    for (var index = 0; index < HomePage._actions.length; index++) {
      final message = _controllers[index].text.trim();
      if (message.isNotEmpty) {
        filledMessages.add('${HomePage._actions[index].label}: $message');
      }
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (filledMessages.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please add a message before submitting.'),
        ),
      );
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          'Submitted ${filledMessages.length} segment'
          '${filledMessages.length == 1 ? '' : 's'} successfully.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedName = widget.adminName.trim();
    final displayName = trimmedName.isEmpty ? 'Admin' : trimmedName;
    final initial = displayName[0].toUpperCase();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 88,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'JustStock',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Semantics(
              label: 'Open profile',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openProfile,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
              'Welcome, $displayName!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor live market segments and manage investor communications.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(
              HomePage._actions.length,
              (index) => Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 16),
                child: _ActionMessageRow(
                  action: HomePage._actions[index],
                  controller: _controllers[index],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionMessageRow extends StatelessWidget {
  const _ActionMessageRow({required this.action, required this.controller});

  final _DashboardAction action;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActionBadge(action: action),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: '${action.label} message',
              hintText: 'Enter update for ${action.label}',
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: buildHeaderGradient(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(255, 152, 0, 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(action.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            action.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

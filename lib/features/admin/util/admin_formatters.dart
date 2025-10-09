import "package:flutter/material.dart";

import "../data/admin_models.dart";

String formatCurrency(num? value, {String symbol = "Rs"}) {
  if (value == null) return "$symbol 0";
  final doubleValue = value.toDouble();
  final isNegative = doubleValue < 0;
  final absValue = doubleValue.abs();

  String formatted;
  if (absValue >= 10000000) {
    formatted = "${(absValue / 10000000).toStringAsFixed(absValue >= 100000000 ? 1 : 2)} Cr";
  } else if (absValue >= 100000) {
    formatted = "${(absValue / 100000).toStringAsFixed(absValue >= 1000000 ? 1 : 2)} L";
  } else if (absValue >= 1000) {
    formatted = "${(absValue / 1000).toStringAsFixed(absValue >= 10000 ? 1 : 2)} K";
  } else {
    formatted = absValue.toStringAsFixed(absValue % 1 == 0 ? 0 : 2);
  }

  return "${isNegative ? "-" : ""}$symbol $formatted";
}

String formatFullCurrency(num? value, {String symbol = "Rs"}) {
  if (value == null) return "$symbol 0.00";
  final doubleValue = value.toDouble();
  final isNegative = doubleValue < 0;
  final absValue = doubleValue.abs();
  final formatted = absValue.toStringAsFixed(2);
  return "${isNegative ? "-" : ""}$symbol $formatted";
}

String formatDateTime(DateTime? value) {
  if (value == null) return "--";
  final date = value;
  final formattedDate =
      "${_twoDigits(date.day)}-${_twoDigits(date.month)}-${date.year}";
  final formattedTime =
      "${_twoDigits(date.hour)}:${_twoDigits(date.minute)}";
  return "$formattedDate · $formattedTime";
}

String formatRelative(DateTime? value) {
  if (value == null) return "--";
  final now = DateTime.now();
  final difference = now.difference(value);
  if (difference.inSeconds.abs() < 60) {
    return "just now";
  }
  if (difference.inMinutes.abs() < 60) {
    final minutes = difference.inMinutes.abs();
    return difference.isNegative ? "in $minutes min" : "$minutes min ago";
  }
  if (difference.inHours.abs() < 24) {
    final hours = difference.inHours.abs();
    return difference.isNegative ? "in $hours hr" : "$hours hr ago";
  }
  final days = difference.inDays.abs();
  return difference.isNegative ? "in $days d" : "$days d ago";
}

String formatUserDisplay(AdminUserReference? user) {
  if (user == null) return "Unknown user";
  final parts = <String>[];
  if (user.name != null && user.name!.trim().isNotEmpty) {
    parts.add(user.name!.trim());
  }
  if (user.email != null && user.email!.trim().isNotEmpty) {
    parts.add(user.email!.trim());
  } else if (user.phone != null && user.phone!.trim().isNotEmpty) {
    parts.add(user.phone!.trim());
  } else if (user.username != null && user.username!.trim().isNotEmpty) {
    parts.add(user.username!.trim());
  }
  if (parts.isEmpty) {
    return user.id;
  }
  return parts.join(" · ");
}

Color ledgerTypeColor(BuildContext context, AdminWalletEntry entry) {
  if (entry.isCredit) {
    return Colors.green.shade600;
  }
  if ((entry.type ?? "").toLowerCase().contains("withdraw")) {
    return Colors.red.shade600;
  }
  return Theme.of(context).colorScheme.primary;
}

String _twoDigits(int value) => value.toString().padLeft(2, "0");

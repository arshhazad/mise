import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          ),
          _buildNotificationItem("Chef's Special", "New menu items added for next week! 🍱", "2h ago", isNew: true),
          _buildNotificationItem("Order Confirmed", "Your lunch for tomorrow is scheduled.", "5h ago", isNew: false),
          _buildNotificationItem("Delivery Arrived", "Your meal was delivered to 'Office'.", "1d ago", isNew: false),
          _buildNotificationItem("Subscription Renewed", "Thank you for staying with Mise!", "3d ago", isNew: false),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, String time, {required bool isNew}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isNew ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNew) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, right: 12), decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 8),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menu_provider.dart';
import '../theme/app_theme.dart';
import '../models/menu_model.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN CONSOLE'),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menu Library (${menuProvider.allItems.length} Items)', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildItemLibrary(menuProvider),
            const SizedBox(height: 32),
            Text('Quick Start', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'Create New Menu Item',
              Icons.add_circle_outline,
              () => _showAddItemDialog(context),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'Schedule Daily Menu',
              Icons.calendar_month_outlined,
              () => _showScheduleDialog(context, menuProvider),
            ),
            const SizedBox(height: 32),
            Text('Next 30 Days Schedule', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _buildScheduleList(menuProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemLibrary(MenuProvider provider) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: provider.allItems.length,
        itemBuilder: (context, index) {
          final item = provider.allItems[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(item.imageUrl ?? '', fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList(MenuProvider provider) {
    // Show only the next 30 days
    final upcoming = provider.weeklyMenus.where((m) => m.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))).take(30).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: upcoming.length,
      itemBuilder: (context, index) {
        final menu = upcoming[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[100]!)),
          child: ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(menu.vegMeal?.imageUrl ?? '')),
            title: Text(DateFormat('EEEE, MMM d').format(menu.date), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Lunch: ${menu.vegMeal?.name ?? 'Not set'}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showScheduleDialog(context, provider, existingMenu: menu),
            ),
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Menu Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Item Name')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                await context.read<MenuProvider>().addMenuItem(
                  _nameController.text,
                  _descController.text,
                );
                _nameController.clear();
                _descController.clear();
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save Item'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, MenuProvider provider, {DailyMenu? existingMenu}) {
    String? selectedVegId = existingMenu?.vegMeal?.id;
    String? selectedNonVegId = existingMenu?.nonVegMeal?.id;
    String? selectedAltId = existingMenu?.altMeal?.id;
    String selectedMealType = existingMenu?.mealType ?? 'Lunch';
    DateTime dialogDate = existingMenu?.date ?? _selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingMenu == null ? 'Schedule Meal' : 'Edit Scheduled Meal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text("Date: ${DateFormat('yyyy-MM-dd').format(dialogDate)}"),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dialogDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setDialogState(() => dialogDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                const Text("Default Veg Meal", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedVegId,
                  items: provider.allItems.map((item) {
                    return DropdownMenuItem(value: item.id, child: Text(item.name));
                  }).toList() + [const DropdownMenuItem(value: null, child: Text("Select Veg"))],
                  onChanged: (val) => setDialogState(() => selectedVegId = val),
                ),
                const SizedBox(height: 16),
                const Text("Default Non-Veg Meal", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedNonVegId,
                  items: provider.allItems.map((item) {
                    return DropdownMenuItem(value: item.id, child: Text(item.name));
                  }).toList() + [const DropdownMenuItem(value: null, child: Text("Select Non-Veg"))],
                  onChanged: (val) => setDialogState(() => selectedNonVegId = val),
                ),
                const SizedBox(height: 16),
                const Text("Alternative Dish (Swap/Add-on)", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedAltId,
                  items: provider.allItems.map((item) {
                    return DropdownMenuItem(value: item.id, child: Text(item.name));
                  }).toList() + [const DropdownMenuItem(value: null, child: Text("Select Alt"))],
                  onChanged: (val) => setDialogState(() => selectedAltId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedVegId != null && selectedNonVegId != null) {
                  try {
                    await provider.updateSchedule(
                      dialogDate, 
                      selectedVegId!, 
                      selectedNonVegId!,
                      selectedAltId,
                      mealType: selectedMealType,
                      id: existingMenu?.id,
                    );
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error saving: $e"), backgroundColor: Colors.red)
                      );
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select Veg and Non-Veg meals"))
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

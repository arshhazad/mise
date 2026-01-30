import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/menu_provider.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard.dart';
import 'package:intl/intl.dart';
import '../models/menu_model.dart';
import '../models/user_model.dart';
import 'meal_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Local state removed, using Provider instead

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<MenuProvider>().fetchMenus(auth.currentUser?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentMenu = menuProvider.currentMenu;
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(authProvider, user?.fullName ?? 'Arshh'),
              _buildDateNav(menuProvider),
              _buildDeliveryInfo(menuProvider, authProvider),
              if (currentMenu == null)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text("No lunch scheduled for this date."),
                ))
              else
                _buildMainMealCard(context, menuProvider, currentMenu, user?.id, user?.defaultPreference ?? 'Veg'),
              _buildHorizontalLibrarySection("Want more?\nWhat else is cooking today...", menuProvider.allItems),
              const SizedBox(height: 24),
              _buildHorizontalScheduleSection("Planning ahead?\nUpcoming Lunches...", menuProvider.weeklyMenus, user?.defaultPreference ?? 'Veg'),
              const SizedBox(height: 32),
              _buildConsumedMealsBar(authProvider.activeSubscription?.mealsRemaining ?? 0),
              const SizedBox(height: 120), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: authProvider.isAdmin ? FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.admin_panel_settings, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildHeader(AuthProvider auth, String name) {
    bool isSubscribed = auth.activeSubscription != null;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mise_user'), 
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hey $name", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (!isSubscribed)
                const Text("Not Subscribed", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                auth.currentUser?.defaultPreference == 'Veg' ? "Veg" : "Non-Veg", 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold,
                  color: auth.currentUser?.defaultPreference == 'Veg' ? Colors.green : Colors.red,
                )
              ),
              const SizedBox(width: 4),
              Switch.adaptive(
                value: auth.currentUser?.defaultPreference == 'Veg',
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.3),
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red.withOpacity(0.3),
                onChanged: (val) {
                  auth.updateLocalPreference(val ? 'Veg' : 'Non-Veg');
                },
              ),
            ],
          ),
          IconButton(onPressed: () => auth.logout(), icon: const Icon(Icons.logout, size: 20, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildDateNav(MenuProvider provider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM d').format(provider.selectedDate), 
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  debugPrint("DEBUG: Previous Date clicked");
                  provider.selectDate(provider.selectedDate.subtract(const Duration(days: 1)));
                },
                child: _buildArrowButton(Icons.chevron_left, true)
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  debugPrint("DEBUG: Next Date clicked");
                  provider.selectDate(provider.selectedDate.add(const Duration(days: 1)));
                },
                child: _buildArrowButton(Icons.chevron_right, false)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton(IconData icon, bool isDim) {
    return Container(
      decoration: BoxDecoration(
        color: isDim ? Colors.grey[100] : AppTheme.neonGreen,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Icon(icon, size: 18, color: Colors.black54),
    );
  }

  Widget _buildDeliveryInfo(MenuProvider menuProvider, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final addresses = user?.addresses ?? [];
    final selectedTag = user?.selectedAddressTag ?? (addresses.isNotEmpty ? addresses[0].tag : 'Home');
    final activeAddress = addresses.firstWhere((a) => a.tag == selectedTag, orElse: () => UserAddress(tag: 'Home', address: 'Address not set')).address;
    
    final subscription = authProvider.activeSubscription;
    final isPaused = subscription?.status == SubscriptionStatus.paused;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAddressDialog(context, menuProvider, authProvider),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(selectedTag, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
              const Spacer(),
              if (addresses.length > 1) _buildAddressSwitcher(authProvider),
            ],
          ),
          const SizedBox(height: 4),
          Text(activeAddress, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("Delivery Time: ", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                child: const Text("8:00-8:20 am", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              _buildGhostButton(isPaused ? "Subscription Paused" : "Pause Meal", () {
                if (subscription != null) _showPauseSheet(context, menuProvider, subscription);
              }),
            ],
          ),
          if (isPaused && subscription?.endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text("Resumes on ${DateFormat('MMM d').format(subscription!.endDate!)}", style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSwitcher(AuthProvider auth) {
    final addresses = auth.currentUser?.addresses ?? [];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: addresses.map((a) => _buildSwitchItem(auth, a.tag)).toList(),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(AuthProvider auth, String tag) {
    final isSelected = auth.currentUser?.selectedAddressTag == tag;
    return GestureDetector(
      onTap: () => auth.updateAddressTag(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  void _showAddressDialog(BuildContext context, MenuProvider menuProvider, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final selectedTag = user?.selectedAddressTag ?? 'Home';
    final addresses = user?.addresses ?? [];
    final currentAddress = addresses.firstWhere((a) => a.tag == selectedTag, orElse: () => UserAddress(tag: 'Home', address: '')).address;
    
    final controller = TextEditingController(text: currentAddress);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update $selectedTag Address"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter address"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (user != null) {
                final updatedAddress = UserAddress(tag: selectedTag, address: controller.text);
                await authProvider.addOrUpdateAddress(updatedAddress);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showPauseSheet(BuildContext context, MenuProvider menuProvider, Subscription subscription) {
    int pauseDays = 5;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppTheme.neonGreen, shape: BoxShape.circle),
                child: const Icon(Icons.pause, size: 32),
              ),
              const SizedBox(height: 16),
              const Text("Pause Lunch Subscription?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              const Text("You won't be charged for the paused days. Your subscription will be extended.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Text("How many days would you like to pause?"),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setSheetState(() => pauseDays = pauseDays > 1 ? pauseDays - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                    child: Text("$pauseDays", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(onPressed: () => setSheetState(() => pauseDays++), icon: const Icon(Icons.add_circle_outline)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await menuProvider.pauseSubscription(subscription.id, pauseDays);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Pause Subscription"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGhostButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            const Icon(Icons.pause, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMealCard(BuildContext context, MenuProvider provider, DailyMenu menu, String? userId, String preference) {
    final order = provider.getOrderForMenu(menu.id);
    final isSwapped = order?.type == 'swap';
    final addOns = provider.getAddOnsForMenu(menu.id);
    
    // Logic: Default based on preference. If swapped, use Alt meal.
    final defaultMeal = preference == 'Non-Veg' ? (menu.nonVegMeal ?? menu.vegMeal) : menu.vegMeal;
    final meal = isSwapped ? (menu.altMeal ?? defaultMeal) : defaultMeal;
    
    if (meal == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
              if (isSwapped)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.neonGreen, borderRadius: BorderRadius.circular(8)),
                  child: const Text("SWAPPED (₹60 Fee)", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (addOns.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                children: addOns.map((a) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Text("+ ${a.name}", style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ),
          const SizedBox(height: 4),
          Text("${meal.calories ?? 0} Kcal • 250g", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text(meal.description ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          _buildMacros(meal),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
              child: Hero(
                tag: 'meal-${meal.id}',
                child: Image.network(
                  meal.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildActionButton("Add Extra + (₹120)", true, () {
                if (userId != null) _showAddOnSheet(context, provider, menu.id, userId, menu.altMeal);
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildActionButton(isSwapped ? "Original Item ⇄" : "Swap meal ⇄ (₹60)", false, () {
                if (userId != null) _showSwapSheet(context, provider, menu, userId);
              })),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddOnSheet(BuildContext context, MenuProvider provider, String menuId, String userId, MenuItem? altMeal) {
    if (altMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No additional dish available today.")));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Alternative Dish?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            if (altMeal.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(altMeal.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text("Get ${altMeal.name} in addition to your default meal.", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text("• Add-on Price: ₹120", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await provider.addExtra(userId, menuId, altMeal.name, 120.0);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Add to Daily Pack (₹120)"),
            ),
          ],
        ),
      ),
    );
  }

  void _showSwapSheet(BuildContext context, MenuProvider provider, DailyMenu menu, String userId) {
    if (menu.altMeal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No alternative dish available for today.")));
      return;
    }
    
    final altMeal = menu.altMeal!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Swap to Alternative?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            if (altMeal.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(altMeal.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text("Switch your default meal to ${altMeal.name}.", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text("• Swap Fee: ₹60", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Keep Original"))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await provider.requestSwap(userId, menu.id, menu.date);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    child: const Text("Confirm Swap (₹60)"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLibrarySection(String title, List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: item))),
                child: _buildSmallMealCard(item.name, "${item.calories} Kcal", item.imageUrl),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalScheduleSection(String title, List<DailyMenu> menus, String preference) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final upcoming = menus.where((m) => m.date.isAfter(tomorrow.subtract(const Duration(minutes: 1)))).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final menu = upcoming[index];
              final meal = (preference == 'Non-Veg' ? (menu.nonVegMeal ?? menu.vegMeal) : menu.vegMeal);
              return GestureDetector(
                onTap: () {
                  if (meal != null) Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal)));
                },
                child: _buildSmallMealCard(
                  meal?.name ?? 'Lunch', 
                  DateFormat('EEEE').format(menu.date), 
                  meal?.imageUrl
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2),
      ),
    );
  }

  Widget _buildSmallMealCard(String name, String sub, String? url) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format',
              height: 100,
              width: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMacros(MenuItem meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMacroInfo('Carbs', '${meal.carbs ?? 0}g'),
        _buildMacroInfo('Protein', '${meal.protein ?? 0}g'),
        _buildMacroInfo('Fats', '${meal.fats ?? 0}g'),
      ],
    );
  }

  Widget _buildMacroInfo(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButton(String label, bool isPrimary, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.neonGreen : Colors.white,
        foregroundColor: isPrimary ? Colors.black : Colors.black87,
        elevation: 0,
        side: isPrimary ? null : BorderSide(color: Colors.black87),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildConsumedMealsBar(int remaining) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subscription Status", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("$remaining meals left", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: remaining / 24, // Assuming a total of 24 meals for the progress bar
                backgroundColor: Colors.grey[200],
                color: AppTheme.neonGreen,
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.restaurant_menu, true, () => debugPrint("DEBUG: Nav Menu")),
          _buildNavItem(Icons.calendar_month_outlined, false, () => debugPrint("DEBUG: Nav Calendar")),
          _buildNavItem(Icons.notifications_none, false, () => debugPrint("DEBUG: Nav Notifications")),
          _buildNavItem(Icons.person_outline, false, () => debugPrint("DEBUG: Nav Profile")),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, color: isActive ? AppTheme.primaryColor : Colors.grey[400], size: 26),
    );
  }
}

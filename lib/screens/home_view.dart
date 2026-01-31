import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_provider.dart';
import '../services/menu_provider.dart';
import '../theme/app_theme.dart';
import '../models/menu_model.dart';
import '../models/user_model.dart';
import 'meal_detail_screen.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentMenu = menuProvider.currentMenu;
    final user = authProvider.currentUser;
    final isSubscribed = authProvider.activeSubscription != null;
    final isPaused = authProvider.activeSubscription?.status == SubscriptionStatus.paused;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(authProvider, user?.fullName ?? 'User'),
          
          // Big Subscription Card for Unsubscribed users
          if (!isSubscribed) _buildSubscribePromoCard(context),
          
          // Pause Indicator
          if (isSubscribed && isPaused) _buildPausedBanner(context, menuProvider, authProvider.activeSubscription!.id),

          _buildDateNav(menuProvider),
          _buildDeliveryInfo(menuProvider, authProvider),
          
          if (currentMenu == null)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("No meals scheduled for this date."),
            ))
          else
            _buildMainMealCard(context, menuProvider, currentMenu, user?.id, user?.defaultPreference ?? 'Veg'),
          
          _buildHorizontalLibrarySection("Want more?\nWhat else is cooking today...", menuProvider.allItems),
          const SizedBox(height: 24),
          _buildHorizontalScheduleSection("Planning ahead?\nUpcoming Lunches...", menuProvider.weeklyMenus, user?.defaultPreference ?? 'Veg'),
          const SizedBox(height: 32),
          _buildConsumedMealsBar(authProvider.activeSubscription?.mealsRemaining ?? 0),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, String name) {
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
              if (auth.activeSubscription == null)
                const Text("Not Subscribed", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              // Pause logic
              if (auth.activeSubscription != null) {
                // In a real app, show a dialog first
              }
            }, 
            icon: Icon(
              auth.activeSubscription?.status == SubscriptionStatus.paused ? Icons.play_arrow : Icons.pause, 
              size: 20, 
              color: Colors.black
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribePromoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor, Colors.black]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("START YOUR JOURNEY", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text("Get Chef-Crafted\nMeals Daily", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to payment/plans
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Subscribe Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedBanner(BuildContext context, MenuProvider menu, String subId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_filled, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Subscription Paused", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text("Your deliveries are on hold.", style: TextStyle(fontSize: 12, color: Colors.orange)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => menu.resumeSubscription(subId),
            child: const Text("RESUME", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ... (Rest of the helper methods from DashboardScreen converted to HomeView)
  // I will copy them below to ensure the file is functional.
  
  Widget _buildDateNav(MenuProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
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
                  onTap: () => provider.selectDate(provider.selectedDate.subtract(const Duration(days: 1))),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                    child: const Icon(Icons.chevron_left, size: 20),
                  )
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => provider.selectDate(provider.selectedDate.add(const Duration(days: 1))),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[100]),
                    child: const Icon(Icons.chevron_right, size: 20),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(MenuProvider menu, AuthProvider auth) {
    final user = auth.currentUser;
    final addresses = user?.addresses ?? [];
    final selectedTag = user?.selectedAddressTag ?? (addresses.isNotEmpty ? addresses[0].tag : 'Home');
    final activeAddress = addresses.firstWhere((a) => a.tag == selectedTag, orElse: () => UserAddress(tag: 'Home', address: 'Address not set')).address;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DELIVERING TO", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(activeAddress, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _buildAddressSwitcher(auth),
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

  Widget _buildSwitchItem(AuthProvider auth, String label) {
    final isActive = auth.currentUser?.selectedAddressTag == label;
    return GestureDetector(
      onTap: () => auth.updateAddressTag(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _buildMainMealCard(BuildContext context, MenuProvider provider, DailyMenu menu, String? userId, String preference) {
    final order = provider.getOrderForMenu(menu.id);
    final isSwapped = order?.type == 'swap';
    final addOns = provider.getAddOnsForMenu(menu.id);
    
    final defaultMeal = preference == 'Non-Veg' ? (menu.nonVegMeal ?? menu.vegMeal) : menu.vegMeal;
    final mainMeal = isSwapped ? (menu.altMeal ?? defaultMeal) : defaultMeal;
    
    if (mainMeal == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildSingleMealCard(context, provider, mainMeal, menu, userId, isSwapped: isSwapped, isAddOn: false),
        ...addOns.map((addOn) {
          final addOnMeal = menu.altMeal;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildSingleMealCard(context, provider, addOnMeal ?? MenuItem(id: 'add-on', name: addOn.name, calories: 150), menu, userId, isSwapped: false, isAddOn: true),
          );
        }),
      ],
    );
  }

  Widget _buildSingleMealCard(BuildContext context, MenuProvider provider, MenuItem meal, DailyMenu menu, String? userId, {required bool isSwapped, required bool isAddOn}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isAddOn ? Colors.blue[100]! : Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(isAddOn ? "ADD-ON: ${meal.name}" : meal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black))),
              if (isSwapped) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.neonGreen, borderRadius: BorderRadius.circular(8)), child: const Text("SWAPPED", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
              if (isAddOn) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: Text("EXTRA (₹120)", style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 4),
          Text("${meal.calories ?? 0} Kcal • 250g", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          _buildMacros(meal),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
              child: Hero(
                tag: 'meal-${meal.id}-${isAddOn ? 'addon' : 'main'}',
                child: Image.network(meal.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format', height: 160, fit: BoxFit.contain),
              ),
            ),
          ),
          if (!isAddOn) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildActionButton("Add Extra +", true, () {
                  if (userId != null) _showAddOnSheet(context, provider, menu.id, userId, menu.altMeal);
                })),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(isSwapped ? "Original Item ⇄" : "Swap meal ⇄", false, () {
                  if (userId != null) _showSwapSheet(context, provider, menu, userId);
                })),
              ],
            ),
          ],
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
    return Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))]);
  }

  Widget _buildActionButton(String label, bool isPrimary, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.neonGreen : Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        side: isPrimary ? null : const BorderSide(color: Colors.black87),
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
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Subscription Status", style: TextStyle(fontWeight: FontWeight.bold)), Text("$remaining meals left", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: remaining / 24, backgroundColor: Colors.grey[200], color: AppTheme.neonGreen, minHeight: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalLibrarySection(String title, List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2))),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildSmallMealCard(item.name, "${item.calories} Kcal", item.imageUrl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalScheduleSection(String title, List<DailyMenu> menus, String preference) {
    final upcoming = menus.where((m) => m.date.isAfter(DateTime.now())).take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2))),
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
              return _buildSmallMealCard(meal?.name ?? 'Lunch', DateFormat('EEEE').format(menu.date), meal?.imageUrl);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMealCard(String name, String sub, String? url) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format', height: 100, width: 140, fit: BoxFit.cover)),
          const SizedBox(height: 8),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddOnSheet(BuildContext context, MenuProvider provider, String menuId, String userId, MenuItem? altMeal) {
    if (altMeal == null) return;
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
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(altMeal.imageUrl ?? '', height: 180, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            Text("Get ${altMeal.name} in addition to your default meal.", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () async { await provider.addExtra(userId, menuId, altMeal.name, 120.0); Navigator.pop(context); }, child: const Text("Add to Daily Pack (₹120)")),
          ],
        ),
      ),
    );
  }

  void _showSwapSheet(BuildContext context, MenuProvider provider, DailyMenu menu, String userId) {
    if (menu.altMeal == null) return;
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
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(menu.altMeal!.imageUrl ?? '', height: 180, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 24),
            Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Keep Original"))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: () async { await provider.requestSwap(userId, menu.id, menu.date); Navigator.pop(context); }, child: const Text("Confirm Swap (₹60)")))


]),
          ],
        ),
      ),
    );
  }
}

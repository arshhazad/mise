import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_model.dart';

class MenuProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<DailyMenu> _weeklyMenus = [];
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Lunch';

  List<MenuItem> _allItems = [];
  List<UserOrder> _userOrders = [];
  List<MealAddOn> _userAddOns = [];

  List<DailyMenu> get weeklyMenus => _weeklyMenus;
  List<MenuItem> get allItems => _allItems;
  DateTime get selectedDate => _selectedDate;
  String get selectedCategory => _selectedCategory;
  List<UserOrder> get userOrders => _userOrders;
  List<MealAddOn> get userAddOns => _userAddOns;

  UserOrder? getOrderForMenu(String menuId) {
    try {
      return _userOrders.firstWhere((o) => o.dailyMenuId == menuId);
    } catch (e) {
      return null;
    }
  }

  List<MealAddOn> getAddOnsForMenu(String menuId) {
    return _userAddOns.where((a) => a.dailyMenuId == menuId).toList();
  }

  DailyMenu? get currentMenu {
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    try {
      return _weeklyMenus.firstWhere(
        (m) => m.date.toIso8601String().startsWith(dateStr) && m.mealType == _selectedCategory,
      );
    } catch (e) {
      return null;
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchMenus([String? userId]) async {
    try {
      final response = await _supabase
          .from('daily_menus')
          .select('''
            id,
            date,
            meal_type,
            veg_menu_item:menu_items!veg_menu_item_id(*),
            non_veg_menu_item:menu_items!non_veg_menu_item_id(*),
            alt_menu_item:menu_items!alt_menu_item_id(*)
          ''')
          .order('date', ascending: true);

      _weeklyMenus = (response as List).map((json) {
        try {
          return DailyMenu.fromJson(json);
        } catch (e) {
          debugPrint("Error parsing menu JSON: $e");
          rethrow;
        }
      }).toList();

      if (userId != null) {
        await _fetchUserSpecifics(userId);
      }

      if (_weeklyMenus.isNotEmpty && _selectedDate.year == DateTime.now().year && _selectedDate.day == DateTime.now().day) {
        final now = DateTime.now();
        if (now.hour >= 15) {
          _selectedDate = now.add(const Duration(days: 1));
        }
      }

      notifyListeners();
      await fetchAllItems();
    } catch (e) {
      debugPrint("Error fetching menus: $e");
    }
  }

  Future<void> fetchAllItems() async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .order('name', ascending: true);
      
      _allItems = (response as List).map((j) => MenuItem.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching all items: $e");
    }
  }

  Future<void> _fetchUserSpecifics(String userId) async {
    final orderResponse = await _supabase
        .from('orders')
        .select()
        .eq('user_id', userId);
    _userOrders = (orderResponse as List).map((j) => UserOrder.fromJson(j)).toList();

    final addOnResponse = await _supabase
        .from('add_ons')
        .select()
        .eq('user_id', userId);
    _userAddOns = (addOnResponse as List).map((j) => MealAddOn.fromJson(j)).toList();
  }

  bool canModify(DateTime mealDate) {
    final now = DateTime.now();
    final cutoff = mealDate.subtract(const Duration(hours: 24));
    return now.isBefore(cutoff);
  }

  Future<void> requestSwap(String userId, String dailyMenuId, DateTime mealDate) async {
    if (!canModify(mealDate)) {
      throw Exception("Modifications must be made 24 hours in advance.");
    }

    await _supabase.from('orders').upsert({
      'user_id': userId,
      'daily_menu_id': dailyMenuId,
      'type': 'swap',
      'status': 'pending',
    });

    await _supabase.from('payments').insert({
      'user_id': userId,
      'amount': 60.00,
      'status': 'pending',
      'transaction_id': 'SWAP_${DateTime.now().millisecondsSinceEpoch}',
    });

    await fetchMenus(userId);
  }

  Future<void> addExtra(String userId, String dailyMenuId, String name, double price) async {
    await _supabase.from('add_ons').insert({
      'user_id': userId,
      'daily_menu_id': dailyMenuId,
      'name': name,
      'price': 120.00,
    });

    await fetchMenus(userId);
  }

  Future<void> updateOfficeAddress(String userId, String address) async {
    await _supabase.from('users').update({'office_address': address}).eq('id', userId);
    notifyListeners();
  }

  Future<void> pauseSubscription(String subscriptionId, int days) async {
    final response = await _supabase.from('subscriptions').select('end_date').eq('id', subscriptionId).single();
    DateTime currentEnd = DateTime.parse(response['end_date']);
    DateTime newEnd = currentEnd.add(Duration(days: days));
    
    await _supabase.from('subscriptions').update({
      'status': 'paused',
      'end_date': newEnd.toIso8601String().split('T')[0],
    }).eq('id', subscriptionId);
    
    notifyListeners();
  }

  Future<void> addMenuItem(String name, String description) async {
    await _supabase.from('menu_items').insert({
      'name': name,
      'description': description,
    });
    await fetchMenus(); // Refresh UI
  }

  List<DailyMenu> getMenusForCategory(String category) {
    return _weeklyMenus.where((m) => m.mealType == category).toList();
  }

  Future<void> updateSchedule(DateTime date, String vegId, String nonVegId, String? altId, {String mealType = 'Lunch', String? id}) async {
    try {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      debugPrint("DEBUG: updateSchedule - Date: $dateStr, Veg: $vegId, NonVeg: $nonVegId, Alt: $altId, ID: $id");
      
      final data = {
        'date': dateStr,
        'meal_type': mealType,
        'veg_menu_item_id': vegId,
        'non_veg_menu_item_id': nonVegId,
        'alt_menu_item_id': altId,
      };
      if (id != null) data['id'] = id;
      
      final res = await _supabase.from('daily_menus').upsert(data, onConflict: 'date,meal_type').select();
      debugPrint("DEBUG: updateSchedule Success: $res");
      
      await fetchMenus(); // Refresh UI
    } catch (e) {
      debugPrint("DEBUG: updateSchedule Error: $e");
      rethrow;
    }
  }
}

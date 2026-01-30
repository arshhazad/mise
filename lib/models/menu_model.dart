class MenuItem {
  final String id;
  final String name;
  final String? description;
  final List<String>? ingredients;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fats;
  final String? imageUrl;
  final bool isPremium;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    this.ingredients,
    this.calories,
    this.protein,
    this.carbs,
    this.fats,
    this.imageUrl,
    this.isPremium = false,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ingredients: (json['ingredients'] as List?)?.map((e) => e.toString()).toList(),
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fats: json['fats'],
      imageUrl: json['image_url'],
      isPremium: json['is_premium'] ?? false,
    );
  }
}

class DailyMenu {
  final String id;
  final DateTime date;
  final String mealType; 
  final MenuItem? vegMeal;
  final MenuItem? nonVegMeal;
  final MenuItem? altMeal;

  DailyMenu({
    required this.id,
    required this.date,
    required this.mealType,
    this.vegMeal,
    this.nonVegMeal,
    this.altMeal,
  });

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mealType: json['meal_type'] ?? 'Lunch',
      vegMeal: json['veg_menu_item'] != null ? MenuItem.fromJson(json['veg_menu_item']) : null,
      nonVegMeal: json['non_veg_menu_item'] != null ? MenuItem.fromJson(json['non_veg_menu_item']) : null,
      altMeal: json['alt_menu_item'] != null ? MenuItem.fromJson(json['alt_menu_item']) : null,
    );
  }
}

class UserOrder {
  final String id;
  final String dailyMenuId;
  final String type; // base, swap, add_on
  final String status; // pending, delivered, cancelled

  UserOrder({
    required this.id,
    required this.dailyMenuId,
    required this.type,
    required this.status,
  });

  factory UserOrder.fromJson(Map<String, dynamic> json) {
    return UserOrder(
      id: json['id'],
      dailyMenuId: json['daily_menu_id'],
      type: json['type'],
      status: json['status'],
    );
  }
}

class MealAddOn {
  final String id;
  final String dailyMenuId;
  final String name;
  final double price;

  MealAddOn({
    required this.id,
    required this.dailyMenuId,
    required this.name,
    required this.price,
  });

  factory MealAddOn.fromJson(Map<String, dynamic> json) {
    return MealAddOn(
      id: json['id'],
      dailyMenuId: json['daily_menu_id'],
      name: json['name'] ?? 'Extra Item',
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

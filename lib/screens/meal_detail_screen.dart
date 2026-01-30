import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../theme/app_theme.dart';

class MealDetailScreen extends StatelessWidget {
  final MenuItem meal;

  const MealDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                meal.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          meal.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                      if (meal.isPremium)
                        const Chip(
                          label: Text("PREMIUM", style: TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: Colors.amber,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    meal.description ?? "A balanced and nutritious meal prepared with fresh ingredients to keep you energized throughout the day.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Text("Nutritional Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildNutritionRow(),
                  const SizedBox(height: 32),
                  const Text("Ingredients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (meal.ingredients != null && meal.ingredients!.isNotEmpty)
                    Column(
                      children: meal.ingredients!.map((ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            Expanded(child: Text(ing, style: TextStyle(color: Colors.grey[700], fontSize: 16))),
                          ],
                        ),
                      )).toList(),
                    )
                  else
                    const Text("• Fresh vegetables, herbs, and spices.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildNutritionItem("Calories", "${meal.calories ?? 450}", "kcal"),
        _buildNutritionItem("Protein", "${meal.protein ?? 22}", "g"),
        _buildNutritionItem("Carbs", "${meal.carbs ?? 45}", "g"),
        _buildNutritionItem("Fats", "${meal.fats ?? 12}", "g"),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(unit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }
}

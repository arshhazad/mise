import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menu_provider.dart';
import '../theme/app_theme.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final addOns = menuProvider.userAddOns;
    final total = addOns.fold<double>(0, (sum, item) => sum + item.price);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text("Cart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        ),
        if (addOns.isEmpty)
          const Expanded(child: Center(child: Text("Your cart is empty.")))
        else
          Expanded(
            child: ListView.builder(
              itemCount: addOns.length,
              itemBuilder: (context, index) {
                final item = addOns[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Premium Extra Dish"),
                  trailing: Text("₹${item.price.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        if (addOns.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text("₹${total.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Checkout"),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
      ],
    );
  }
}

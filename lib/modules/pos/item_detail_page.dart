import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_page.dart';

class ItemDetailPage extends StatefulWidget {
  final dynamic item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int quantity = 1;
  dynamic selectedVariant;
  final selectedAddons = <dynamic>[];

  late final CartController cartController;

  @override
  void initState() {
    super.initState();

    cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
  }

  List<dynamic> get variants =>
      widget.item['variants'] is List ? widget.item['variants'] : [];

  List<dynamic> get addons =>
      widget.item['addons'] is List ? widget.item['addons'] : [];

  List<dynamic> get recipeItems =>
      widget.item['recipeItems'] is List ? widget.item['recipeItems'] : [];

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  double get itemPrice {
    if (selectedVariant != null) {
      return _toDouble(selectedVariant['price']);
    }
    return _toDouble(widget.item['price']);
  }

  double get addonsTotal {
    return selectedAddons.fold<double>(
      0,
      (sum, addon) => sum + _toDouble(addon['price']),
    );
  }

  double get total => (itemPrice + addonsTotal) * quantity;

  Future<void> _addToCart() async {
    await cartController.addToCart(
      item: widget.item,
      variant: selectedVariant,
      addons: List<dynamic>.from(selectedAddons),
      quantity: quantity,
    );

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.item['title'] ?? '';
    final category = widget.item['category_title'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: SafeArea(
        child: Column(
          children: [
            _Header(onCartTap: () => Get.to(() => const CartPage())),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 110),
                children: [
                  Center(
                    child: Container(
                      height: 210,
                      width: 210,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_pizza,
                        size: 110,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'LKR ${itemPrice.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 26),

                  if (variants.isNotEmpty) ...[
                    const _SectionTitle(title: 'Choose Variant'),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 105,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: variants.length,
                        itemBuilder: (context, index) {
                          final variant = variants[index];
                          final selected =
                              selectedVariant?['id'] == variant['id'];

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVariant = variant;
                              });
                            },
                            child: Container(
                              width: 130,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primaryLight
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    variant['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'LKR ${variant['price']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (addons.isNotEmpty) ...[
                    const _SectionTitle(title: 'Addons'),
                    const SizedBox(height: 12),
                    ...addons.map((addon) {
                      final selected = selectedAddons.any(
                        (a) => a['id'] == addon['id'],
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: CheckboxListTile(
                          value: selected,
                          activeColor: AppColors.primary,
                          title: Text(
                            addon['title'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('LKR ${addon['price']}'),
                          onChanged: (_) {
                            setState(() {
                              if (selected) {
                                selectedAddons.removeWhere(
                                  (a) => a['id'] == addon['id'],
                                );
                              } else {
                                selectedAddons.add(addon);
                              }
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  if (recipeItems.isNotEmpty) ...[
                    const _SectionTitle(title: 'Recipe Availability'),
                    const SizedBox(height: 12),
                    ...recipeItems.map((recipe) {
                      final available = recipe['is_available'] == true;

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            available ? Icons.check_circle : Icons.warning,
                            color: available
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          title: Text(recipe['ingredient_title'] ?? ''),
                          subtitle: Text(
                            'Need ${recipe['required_base_qty']} ${recipe['base_unit_short']} • Available ${recipe['available_base_qty']} ${recipe['base_unit_short']}',
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _BottomAddBar(
        quantity: quantity,
        total: total,
        onMinus: () {
          if (quantity > 1) {
            setState(() => quantity--);
          }
        },
        onPlus: () {
          setState(() => quantity++);
        },
        onAdd: _addToCart,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onCartTap;

  const _Header({required this.onCartTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          _CircleIcon(icon: Icons.arrow_back, onTap: Get.back),
          const Spacer(),
          _CircleIcon(icon: Icons.shopping_cart_outlined, onTap: onCartTap),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
      ),
    );
  }
}

class _BottomAddBar extends StatelessWidget {
  final int quantity;
  final double total;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onAdd;

  const _BottomAddBar({
    required this.quantity,
    required this.total,
    required this.onMinus,
    required this.onPlus,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryLight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                IconButton(onPressed: onMinus, icon: const Icon(Icons.remove)),
                Text(
                  '$quantity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: onPlus, icon: const Icon(Icons.add)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onAdd,
              child: Text('Add to Cart • LKR ${total.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_page.dart';
import '../printer/printer_setup_page.dart';
import 'pos_init_controller.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PosInitController());

    if (!Get.isRegistered<CartController>()) {
      Get.put<CartController>(CartController(), permanent: true);
      debugPrint(
        '⚠️ CartController was not registered. Registered in PosPage.',
      );
    } else {
      debugPrint('✅ CartController already registered in PosPage.');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final store = controller.storeSettings.value ?? {};
          final storeName = store['store_name'] ?? 'Synera RMS';

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
              children: [
                _TopHeader(
                  storeName: storeName,
                  onPrinterTap: () => Get.to(() => PrinterSetupPage()),
                ),
                const SizedBox(height: 18),
                _SearchBox(controller: controller),
                const SizedBox(height: 18),
                _CategoryList(controller: controller),
                const SizedBox(height: 20),
                const _OfferBanner(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: controller.selectedCategoryId.value == 0
                      ? 'Best Sellers'
                      : 'Menu Items',
                  actionText: '${controller.filteredItems.length} items',
                ),
                const SizedBox(height: 12),
                _MenuGrid(controller: controller),
              ],
            ),
          );
        }),
      ),
      floatingActionButton: Obx(() {
        final cart = Get.find<CartController>();

        return FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () {
            debugPrint(
              '🛒 Floating cart clicked. Count: ${cart.cartItems.length}',
            );
            Get.to(() => const CartPage());
          },
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Text(
            'Cart (${cart.cartItems.length})',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String storeName;
  final VoidCallback onPrinterTap;

  const _TopHeader({required this.storeName, required this.onPrinterTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Icon(Icons.restaurant, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello 👋',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              Text(
                storeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(icon: Icons.print, onTap: onPrinterTap),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
          ],
        ),
        child: Icon(icon, color: AppColors.textDark),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final PosInitController controller;

  const _SearchBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.searchController,
      onChanged: controller.onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search food items',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.searchText.value.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.searchController.clear();
                  controller.onSearchChanged('');
                },
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final PosInitController controller;

  const _CategoryList({required this.controller});

  IconData _iconForCategory(String title) {
    final value = title.toLowerCase();

    if (value.contains('rice')) return Icons.rice_bowl;
    if (value.contains('kottu')) return Icons.local_dining;
    if (value.contains('noodle')) return Icons.ramen_dining;
    if (value.contains('beer') || value.contains('bar')) {
      return Icons.sports_bar;
    }
    if (value.contains('drink') || value.contains('beverage')) {
      return Icons.local_drink;
    }
    if (value.contains('dessert')) return Icons.icecream;
    if (value.contains('pasta')) return Icons.dinner_dining;
    if (value.contains('fish')) return Icons.set_meal;

    return Icons.fastfood;
  }

  @override
  Widget build(BuildContext context) {
    final categories = controller.displayCategories;

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryCard(
            title: 'All',
            icon: Icons.grid_view_rounded,
            selected: controller.selectedCategoryId.value == 0,
            onTap: () => controller.selectCategory(0),
          ),
          ...categories.map((cat) {
            final id = int.tryParse(cat['id'].toString()) ?? 0;
            final title = cat['title'] ?? '';

            return _CategoryCard(
              title: title,
              icon: _iconForCategory(title),
              selected: controller.selectedCategoryId.value == id,
              onTap: () => controller.selectCategory(id),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 82,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today Special',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 6),
                Text(
                  'Fast Orders\nFresh Food',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_pizza, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          actionText,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final PosInitController controller;

  const _MenuGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final items = controller.filteredItems;

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(child: Text('No menu items found')),
      );
    }

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
        childAspectRatio: 0.67,
      ),
      itemBuilder: (context, index) {
        return _FoodCard(item: items[index]);
      },
    );
  }
}

class _FoodCard extends StatelessWidget {
  final dynamic item;

  const _FoodCard({required this.item});

  double _price(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? '';
    final category = item['category_title'] ?? '';
    final price = _price(item['price']).toStringAsFixed(2);

    final addons = item['addons'] is List ? item['addons'] as List : [];
    final variants = item['variants'] is List ? item['variants'] as List : [];
    final recipeItems = item['recipeItems'] is List
        ? item['recipeItems'] as List
        : [];

    return InkWell(
      onTap: () {
        debugPrint('🍔 Item clicked: $title');
        _showItemDetails(context, item);
      },
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 86,
                      width: 86,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fastfood,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 15,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${recipeItems.length} recipes',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'LKR $price',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (addons.isNotEmpty || variants.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${variants.length}V ${addons.length}A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showItemDetails(BuildContext context, dynamic item) {
  final variants = item['variants'] is List ? item['variants'] as List : [];
  final addons = item['addons'] is List ? item['addons'] as List : [];
  final recipeItems = item['recipeItems'] is List
      ? item['recipeItems'] as List
      : [];

  int quantity = 1;
  dynamic selectedVariant;
  final selectedAddons = <dynamic>{};

  double toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  double itemPrice() {
    if (selectedVariant != null) {
      return toDouble(selectedVariant['price']);
    }
    return toDouble(item['price']);
  }

  double addonTotal() {
    double total = 0;

    for (final addon in addons) {
      if (selectedAddons.contains(addon['id'])) {
        total += toDouble(addon['price']);
      }
    }

    return total;
  }

  debugPrint('📄 Opening bottom sheet for: ${item['title']}');

  Get.bottomSheet(
    StatefulBuilder(
      builder: (context, setSheetState) {
        final total = (itemPrice() + addonTotal()) * quantity;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        height: 150,
                        width: 150,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_pizza,
                          color: AppColors.primary,
                          size: 82,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item['title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['category_title'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textLight),
                    ),
                    const SizedBox(height: 22),

                    if (variants.isNotEmpty) ...[
                      const _DetailTitle('Choose Variant'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: variants.map((variant) {
                            final selected =
                                selectedVariant?['id'] == variant['id'];

                            return InkWell(
                              onTap: () {
                                setSheetState(() {
                                  selectedVariant = variant;
                                });

                                debugPrint(
                                  '✅ Variant selected: ${variant['title']}',
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryLight
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
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
                                          : Colors.grey,
                                    ),
                                    const SizedBox(height: 5),
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
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (addons.isNotEmpty) ...[
                      const _DetailTitle('Add Ingredients'),
                      const SizedBox(height: 10),
                      ...addons.map((addon) {
                        final selected = selectedAddons.contains(addon['id']);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: CheckboxListTile(
                            value: selected,
                            activeColor: AppColors.primary,
                            title: Text(
                              addon['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('LKR ${addon['price']}'),
                            onChanged: (_) {
                              setSheetState(() {
                                if (selected) {
                                  selectedAddons.remove(addon['id']);
                                } else {
                                  selectedAddons.add(addon['id']);
                                }
                              });

                              debugPrint(
                                '✅ Selected addons IDs: ${selectedAddons.toList()}',
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    if (recipeItems.isNotEmpty) ...[
                      const _DetailTitle('Recipe Availability'),
                      const SizedBox(height: 10),
                      ...recipeItems.map((recipe) {
                        final available = recipe['is_available'] == true;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
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
                        );
                      }),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryLight),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity > 1) {
                                setSheetState(() => quantity--);
                                debugPrint('➖ Quantity: $quantity');
                              }
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setSheetState(() => quantity++);
                              debugPrint('➕ Quantity: $quantity');
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final cartController = Get.find<CartController>();

                          final selectedAddonList = addons.where((addon) {
                            return selectedAddons.contains(addon['id']);
                          }).toList();

                          await cartController.addToCart(
                            item: item,
                            variant: selectedVariant,
                            addons: selectedAddonList,
                            quantity: quantity,
                          );

                          Get.back();
                        },
                        child: Text(
                          'Add to Cart • LKR ${total.toStringAsFixed(2)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
    isScrollControlled: true,
  );
}

class _DetailTitle extends StatelessWidget {
  final String title;

  const _DetailTitle(this.title);

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

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return Obx(() {
      return Container(
        height: 78,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const _NavItem(icon: Icons.home, title: 'Home', active: true),
            const _NavItem(icon: Icons.favorite_border, title: 'Fav'),
            GestureDetector(
              onTap: () => Get.to(() => const CartPage()),
              child: _NavItem(
                icon: Icons.shopping_cart_outlined,
                title: 'Cart ${cart.cartItems.length}',
              ),
            ),
            const _NavItem(icon: Icons.receipt_long, title: 'Orders'),
            const _NavItem(icon: Icons.person_outline, title: 'Me'),
          ],
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.title,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: active
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: active ? Colors.white : AppColors.textLight,
            size: 22,
          ),
          if (active) ...[
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

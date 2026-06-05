import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'cart_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _showPaymentPopup(BuildContext context, CartController controller) {
    if (controller.cartItems.isEmpty) {
      Get.snackbar('Cart Empty', 'Please add items first');
      return;
    }

    if (controller.paymentTypes.isEmpty) {
      Get.snackbar('Payment Error', 'Payment types not loaded');
      return;
    }

    controller.selectedPaymentType.value ??= controller.paymentTypes.first;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Obx(() {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Payment Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 18),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: controller.paymentTypes.map((type) {
                    final selected =
                        controller.selectedPaymentType.value?['id'] ==
                        type['id'];

                    return InkWell(
                      onTap: () => controller.selectPaymentType(type),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : const Color(0xFFF4F8F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.grey.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          type['title']?.toString() ?? '',
                          style: TextStyle(
                            color: selected ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                _SummaryRow(
                  title: 'Total',
                  value: 'LKR ${controller.total.toStringAsFixed(2)}',
                  bold: true,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isCheckoutLoading.value
                        ? null
                        : controller.payAndComplete,
                    child: controller.isCheckoutLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Complete Payment'),
                  ),
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: controller.isCheckoutLoading.value
                      ? null
                      : Get.back,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartController controller = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F5),
      body: SafeArea(
        child: Column(
          children: [
            _CartHeader(onClear: controller.clearCart),
            Expanded(
              child: Obx(() {
                if (controller.cartItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'Cart is empty',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  itemCount: controller.cartItems.length,
                  itemBuilder: (context, index) {
                    final cart = controller.cartItems[index];

                    return _CartItemCard(
                      cart: cart,
                      onMinus: () => controller.decreaseQty(index),
                      onPlus: () => controller.increaseQty(index),
                      onRemove: () => controller.removeItem(index),
                    );
                  },
                );
              }),
            ),
            Obx(
              () => _CartSummary(
                subtotal: controller.subtotal,
                serviceCharge: controller.serviceCharge,
                total: controller.total,
                isLoading: controller.isCheckoutLoading.value,
                onCheckout: () => _showPaymentPopup(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  final VoidCallback onClear;

  const _CartHeader({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          _CircleButton(icon: Icons.arrow_back, onTap: Get.back),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Cart',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          _CircleButton(icon: Icons.delete_outline, onTap: onClear),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: AppColors.textDark),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final Map<String, dynamic> cart;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.cart,
    required this.onMinus,
    required this.onPlus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = cart['item'];
    final variant = cart['variant'];
    final addons = cart['addons'] is List ? cart['addons'] as List : [];

    final title = item['title'] ?? '';
    final category = item['category_title'] ?? '';
    final qty = cart['quantity'] ?? 1;
    final total = double.tryParse(cart['total']?.toString() ?? '0') ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fastfood,
              color: AppColors.primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  variant != null
                      ? '$category • ${variant['title']}'
                      : category,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
                if (addons.isNotEmpty)
                  Text(
                    addons.map((a) => a['title']).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'LKR ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
              Row(
                children: [
                  _QtyButton(icon: Icons.remove, onTap: onMinus),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$qty',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _QtyButton(icon: Icons.add, onTap: onPlus),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 28,
        width: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double subtotal;
  final double serviceCharge;
  final double total;
  final bool isLoading;
  final VoidCallback onCheckout;

  const _CartSummary({
    required this.subtotal,
    required this.serviceCharge,
    required this.total,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            title: 'Subtotal',
            value: 'LKR ${subtotal.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            title: 'Service Charge',
            value: 'LKR ${serviceCharge.toStringAsFixed(2)}',
          ),
          const Divider(height: 26),
          _SummaryRow(
            title: 'Total',
            value: 'LKR ${total.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: subtotal <= 0 || isLoading ? null : onCheckout,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Pay & Complete • LKR ${total.toStringAsFixed(2)}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: bold ? AppColors.textDark : AppColors.textLight,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
            fontSize: bold ? 17 : 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: bold ? AppColors.primary : AppColors.textDark,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }
}

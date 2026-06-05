import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../core/api/api_client.dart';
import '../printer/printer_service.dart';

class CartController extends GetxController {
  final cartItems = <Map<String, dynamic>>[].obs;
  final isCheckoutLoading = false.obs;
  final isPaymentLoading = false.obs;

  final paymentTypes = <Map<String, dynamic>>[].obs;
  final selectedPaymentType = Rxn<Map<String, dynamic>>();

  final storeSettings = <String, dynamic>{}.obs;
  final printSettings = <String, dynamic>{}.obs;

  final GetStorage _box = GetStorage();

  static const String _cartKey = 'pos_cart_items';
  static const String _paymentTypesKey = 'pos_payment_types';
  static const String _storeSettingsKey = 'pos_store_settings';
  static const String _printSettingsKey = 'pos_print_settings';

  double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    loadCart();
    loadPosSettingsFromStorage();

    if (paymentTypes.isEmpty ||
        storeSettings.isEmpty ||
        printSettings.isEmpty) {
      fetchPosInit();
    }
  }

  Future<void> fetchPosInit() async {
    isPaymentLoading.value = true;

    try {
      final response = await ApiClient.dio.get('/pos/init');

      print('========== POS INIT RESPONSE ==========');
      print(const JsonEncoder.withIndent('  ').convert(response.data));

      final data = Map<String, dynamic>.from(response.data ?? {});

      final types = data['paymentTypes'];
      if (types is List) {
        setPaymentTypes(types);
      }

      storeSettings.assignAll(
        Map<String, dynamic>.from(data['storeSettings'] ?? {}),
      );

      printSettings.assignAll(
        Map<String, dynamic>.from(data['printSettings'] ?? {}),
      );

      await _box.write(_storeSettingsKey, storeSettings);
      await _box.write(_printSettingsKey, printSettings);
    } catch (e) {
      print('========== POS INIT ERROR ==========');
      print(e);
      Get.snackbar('Payment Error', 'Unable to load POS settings');
    } finally {
      isPaymentLoading.value = false;
    }
  }

  void setPaymentTypes(List<dynamic> types) {
    paymentTypes.assignAll(
      types
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['is_active'] == 1)
          .toList(),
    );

    if (paymentTypes.isNotEmpty) {
      selectedPaymentType.value ??= paymentTypes.first;
    }

    _box.write(_paymentTypesKey, paymentTypes.toList());

    print('========== PAYMENT TYPES LOADED ==========');
    print(const JsonEncoder.withIndent('  ').convert(paymentTypes));
  }

  void loadPosSettingsFromStorage() {
    final storedPaymentTypes = _box.read(_paymentTypesKey);
    final storedStoreSettings = _box.read(_storeSettingsKey);
    final storedPrintSettings = _box.read(_printSettingsKey);

    if (storedPaymentTypes is List && storedPaymentTypes.isNotEmpty) {
      paymentTypes.assignAll(
        storedPaymentTypes
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['is_active'] == 1)
            .toList(),
      );

      if (paymentTypes.isNotEmpty) {
        selectedPaymentType.value = paymentTypes.first;
      }
    }

    if (storedStoreSettings is Map) {
      storeSettings.assignAll(Map<String, dynamic>.from(storedStoreSettings));
    }

    if (storedPrintSettings is Map) {
      printSettings.assignAll(Map<String, dynamic>.from(storedPrintSettings));
    }
  }

  void selectPaymentType(Map<String, dynamic> type) {
    selectedPaymentType.value = type;

    print('========== SELECTED PAYMENT TYPE ==========');
    print(const JsonEncoder.withIndent('  ').convert(type));
  }

  void loadCart() {
    final storedCart = _box.read(_cartKey);

    if (storedCart is List) {
      cartItems.assignAll(
        storedCart.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }
  }

  Future<void> _saveCart() async {
    await _box.write(_cartKey, cartItems.toList());
  }

  Future<void> addToCart({
    required dynamic item,
    dynamic variant,
    required List<dynamic> addons,
    required int quantity,
  }) async {
    final basePrice = variant != null
        ? _toDouble(variant['price'])
        : _toDouble(item['price']);

    final addonsTotal = addons.fold<double>(
      0,
      (sum, addon) => sum + _toDouble(addon['price']),
    );

    final unitPrice = basePrice + addonsTotal;

    final existingIndex = cartItems.indexWhere((cart) {
      final sameItem = cart['item']['id'] == item['id'];
      final sameVariant = cart['variant']?['id'] == variant?['id'];

      final oldAddons = cart['addons'] is List ? cart['addons'] as List : [];
      final oldAddonIds = oldAddons.map((a) => a['id']).toList()..sort();

      final newAddonIds = addons.map((a) => a['id']).toList()..sort();

      return sameItem &&
          sameVariant &&
          oldAddonIds.toString() == newAddonIds.toString();
    });

    if (existingIndex >= 0) {
      cartItems[existingIndex]['quantity'] =
          _toInt(cartItems[existingIndex]['quantity']) + quantity;
      _recalculate(existingIndex);
    } else {
      cartItems.add({
        'item': Map<String, dynamic>.from(item),
        'variant': variant == null ? null : Map<String, dynamic>.from(variant),
        'addons': addons.map((a) => Map<String, dynamic>.from(a)).toList(),
        'quantity': quantity,
        'unitPrice': unitPrice,
        'total': unitPrice * quantity,
      });
    }

    cartItems.refresh();
    await _saveCart();

    Get.snackbar('Added', '${item['title']} added to cart');
  }

  Future<void> increaseQty(int index) async {
    cartItems[index]['quantity'] = _toInt(cartItems[index]['quantity']) + 1;
    _recalculate(index);
    cartItems.refresh();
    await _saveCart();
  }

  Future<void> decreaseQty(int index) async {
    if (_toInt(cartItems[index]['quantity']) > 1) {
      cartItems[index]['quantity'] = _toInt(cartItems[index]['quantity']) - 1;
      _recalculate(index);
      cartItems.refresh();
      await _saveCart();
    }
  }

  Future<void> removeItem(int index) async {
    cartItems.removeAt(index);
    cartItems.refresh();
    await _saveCart();
  }

  Future<void> clearCart() async {
    cartItems.clear();
    await _box.remove(_cartKey);
  }

  void _recalculate(int index) {
    final qty = _toInt(cartItems[index]['quantity']);
    final unitPrice = _toDouble(cartItems[index]['unitPrice']);
    cartItems[index]['total'] = unitPrice * qty;
  }

  List<Map<String, dynamic>> get checkoutCart {
    return cartItems.map((cart) {
      final item = Map<String, dynamic>.from(cart['item'] ?? {});
      final variant = cart['variant'];
      final addons = cart['addons'] is List ? cart['addons'] as List : [];
      final qty = _toInt(cart['quantity']);

      item['quantity'] = qty;
      item['variant'] = variant;
      item['variant_id'] = variant == null ? null : variant['id'].toString();
      item['addons'] = addons;
      item['addons_ids'] = addons.map((a) => a['id']).toList();
      item['unitPrice'] = cart['unitPrice'];
      item['total'] = cart['total'];

      return item;
    }).toList();
  }

  Future<void> payAndComplete() async {
    if (cartItems.isEmpty) {
      Get.snackbar('Cart Empty', 'Please add items first');
      return;
    }

    final payment = selectedPaymentType.value;

    if (payment == null) {
      Get.snackbar('Payment Required', 'Please select payment type');
      return;
    }

    isCheckoutLoading.value = true;

    try {
      final body = {
        "cart": checkoutCart,
        "customerId": {
          "phone": "+94703252747",
          "name": "Nadun Malinda Jayaweera",
        },
        "customerType": "CUSTOMER",
        "deliveryChargeRangeId": null,
        "deliveryChargeTotal": 0,
        "deliveryRangeText": null,
        "deliveryType": "",
        "discountTotal": 0,
        "isDefaultTaxServiceCharge": 1,
        "loyaltyPointsTotal": 0,
        "redeemLoyaltyPoints": 0,
        "netTotal": subtotal,
        "selectedPaymentType": {payment['id'].toString(): total},
        "selectedQrOrderItem": null,
        "serviceChargeTotal": serviceCharge,
        "tableId": "",
        "taxTotal": 0,
        "total": total,
      };

      print('========== PAY AND COMPLETE REQUEST ==========');
      print(const JsonEncoder.withIndent('  ').convert(body));

      final response = await ApiClient.dio.post(
        '/pos/create-order-and-invoice',
        data: body,
      );

      print('========== PAY AND COMPLETE STATUS ==========');
      print(response.statusCode);

      print('========== PAY AND COMPLETE RESPONSE ==========');
      print(const JsonEncoder.withIndent('  ').convert(response.data));

      final data = Map<String, dynamic>.from(response.data ?? {});

      if (data['success'] == true) {
        final printed = await PrinterService.printCheckoutReceipt(
          responseData: data,
          requestBody: body,
          paymentType: payment,
          storeSettings: storeSettings,
          printSettings: printSettings,
        );

        await clearCart();

        Get.back();
        Get.back();

        Get.snackbar(
          printed ? 'Success' : 'Order Success',
          printed
              ? 'Payment completed and bill printed'
              : 'Payment completed but bill not printed',
        );
      } else {
        Get.snackbar(
          'Checkout Failed',
          data['message']?.toString() ?? 'Something went wrong',
        );
      }
    } on DioException catch (e) {
      print('========== PAY AND COMPLETE DIO ERROR ==========');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('MESSAGE: ${e.message}');

      Get.snackbar(
        'Checkout Error',
        e.response?.data?['message']?.toString() ??
            'Status Code: ${e.response?.statusCode}',
      );
    } catch (e) {
      print('========== PAY AND COMPLETE UNKNOWN ERROR ==========');
      print(e);

      Get.snackbar('Checkout Error', e.toString());
    } finally {
      isCheckoutLoading.value = false;
    }
  }

  double get subtotal {
    return cartItems.fold<double>(
      0,
      (sum, item) => sum + _toDouble(item['total']),
    );
  }

  double get serviceCharge => subtotal * 0.10;

  double get total => subtotal + serviceCharge;

  int get totalQty {
    return cartItems.fold<int>(
      0,
      (sum, item) => sum + _toInt(item['quantity']),
    );
  }
}

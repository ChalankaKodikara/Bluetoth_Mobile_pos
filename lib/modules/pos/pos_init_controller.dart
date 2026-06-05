import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/api/api_client.dart';

class PosInitController extends GetxController {
  final isLoading = false.obs;
  final searchController = TextEditingController();

  final categories = <dynamic>[].obs;
  final paymentTypes = <dynamic>[].obs;
  final storeTables = <dynamic>[].obs;
  final menuItems = <dynamic>[].obs;

  final storeSettings = Rxn<Map<String, dynamic>>();
  final printSettings = Rxn<Map<String, dynamic>>();

  final selectedCategoryId = 0.obs;
  final searchText = ''.obs;

  List<dynamic> get parentCategories {
    return categories.where((cat) {
      return cat['is_enabled'] == 1 && cat['parent_item_group_id'] == null;
    }).toList();
  }

  List<dynamic> get childCategories {
    return categories.where((cat) {
      return cat['is_enabled'] == 1 && cat['parent_item_group_id'] != null;
    }).toList();
  }

  List<dynamic> get displayCategories {
    final list = childCategories;
    return list.isEmpty ? categories : list;
  }

  List<dynamic> get filteredItems {
    List<dynamic> items = menuItems.where((item) {
      return item['is_enabled'] == 1;
    }).toList();

    if (selectedCategoryId.value != 0) {
      items = items.where((item) {
        return item['category_id'] == selectedCategoryId.value ||
            item['parent_item_group'] == selectedCategoryId.value;
      }).toList();
    }

    if (searchText.value.trim().isNotEmpty) {
      final q = searchText.value.trim().toLowerCase();

      items = items.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final category = (item['category_title'] ?? '')
            .toString()
            .toLowerCase();
        return title.contains(q) || category.contains(q);
      }).toList();
    }

    return items;
  }

  List<dynamic> get bestSellers {
    final items = menuItems.where((item) => item['is_enabled'] == 1).toList();
    return items.take(6).toList();
  }

  Future<void> fetchPosInit() async {
    try {
      isLoading.value = true;

      final response = await ApiClient.dio.get('/pos/init');
      final data = response.data;

      categories.assignAll(data['categories'] ?? []);
      paymentTypes.assignAll(data['paymentTypes'] ?? []);
      storeTables.assignAll(data['storeTables'] ?? []);
      menuItems.assignAll(data['menuItems'] ?? []);

      storeSettings.value = Map<String, dynamic>.from(
        data['storeSettings'] ?? {},
      );
      printSettings.value = Map<String, dynamic>.from(
        data['printSettings'] ?? {},
      );
    } catch (e) {
      Get.snackbar('POS Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(int id) {
    selectedCategoryId.value = id;
  }

  void onSearchChanged(String value) {
    searchText.value = value;
  }

  Future<void> refreshData() async {
    await fetchPosInit();
  }

  @override
  void onInit() {
    super.onInit();
    fetchPosInit();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

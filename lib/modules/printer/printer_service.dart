import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterService {
  PrinterService._();

  static final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  static final GetStorage _box = GetStorage();

  static const String _printerAddressKey = 'selected_printer_address';

  static Future<void> savePrinterAddress(String address) async {
    await _box.write(_printerAddressKey, address);
    print('PRINTER SAVED ADDRESS: $address');
  }

  static String? get savedPrinterAddress => _box.read(_printerAddressKey);

  static Future<void> requestPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  static Future<bool> connectSavedPrinter() async {
    try {
      await requestPermissions();

      final address = savedPrinterAddress;
      print('PRINTER SAVED ADDRESS READ: $address');

      if (address == null || address.isEmpty) {
        print('NO SAVED PRINTER ADDRESS');
        return false;
      }

      final alreadyConnected = await bluetooth.isConnected;

      if (alreadyConnected == true) {
        print('PRINTER ALREADY CONNECTED');
        return true;
      }

      final devices = await bluetooth.getBondedDevices();

      final printer = devices.firstWhere(
        (d) => d.address == address,
        orElse: () => throw Exception('Saved printer not found'),
      );

      print('CONNECTING TO: ${printer.name} - ${printer.address}');

      await bluetooth.connect(printer);
      await Future.delayed(const Duration(seconds: 2));

      final status = await bluetooth.isConnected;
      print('PRINTER CONNECT RESULT: $status');

      return status == true;
    } catch (e) {
      print('PRINTER CONNECT ERROR: $e');
      return false;
    }
  }

  static String _clean(dynamic value) {
    return value
            ?.toString()
            .replaceAll('"', '')
            .replaceAll('\n', ' ')
            .replaceAll('\r', ' ')
            .trim() ??
        '';
  }

  static String _short(dynamic value, int max) {
    final text = _clean(value);
    if (text.length <= max) return text;
    return text.substring(0, max);
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '1') ?? 1;
  }

  static String _money(String currency, dynamic value) {
    return '$currency ${_toDouble(value).toStringAsFixed(2)}';
  }

  static String _line() => '------------------------------';

  static Future<bool> _sendCpcl(String cpcl) async {
    try {
      final command = cpcl.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');

      await bluetooth.writeBytes(Uint8List.fromList(command.codeUnits));
      await Future.delayed(const Duration(seconds: 1));

      print('CPCL COMMAND SENT');
      return true;
    } catch (e) {
      print('CPCL SEND ERROR: $e');
      return false;
    }
  }

  static Future<bool> testPrint() async {
    final connected = await connectSavedPrinter();
    if (!connected) return false;

    final cpcl =
        '''
! 0 200 200 420 1
CENTER
TEXT 4 0 0 40 TEST PRINT
TEXT 4 0 0 100 SYNERA RMS
TEXT 4 0 0 160 PRINT OK
LEFT
TEXT 0 0 20 230 ${DateTime.now().toString().substring(0, 19)}
FORM
PRINT
''';

    return _sendCpcl(cpcl);
  }

  static Future<bool> printCheckoutReceipt({
    required Map<String, dynamic> responseData,
    required Map<String, dynamic> requestBody,
    required Map<String, dynamic> paymentType,
    required Map<String, dynamic> storeSettings,
    required Map<String, dynamic> printSettings,
  }) async {
    try {
      final connected = await connectSavedPrinter();
      if (!connected) return false;

      final cart = requestBody['cart'] is List
          ? requestBody['cart'] as List
          : [];
      final customer = requestBody['customerId'] is Map
          ? Map<String, dynamic>.from(requestBody['customerId'])
          : <String, dynamic>{};

      final currency = _clean(storeSettings['currency']).isEmpty
          ? 'LKR'
          : _clean(storeSettings['currency']);

      final storeName = _clean(storeSettings['store_name']);
      final address = _clean(storeSettings['address']);
      final phone = _clean(storeSettings['phone']);
      final email = _clean(storeSettings['email']);

      final header = _clean(printSettings['header']);
      final footer = _clean(printSettings['footer']);

      final showStoreDetails = printSettings['show_store_details'] == 1;
      final showCustomerDetails = printSettings['show_customer_details'] == 1;
      final showNotes = printSettings['show_notes'] == 1;
      final printToken = printSettings['print_token'] == 1;

      final tokenNo = responseData['tokenNo'];
      final orderId = responseData['orderId'];
      final invoiceId = responseData['invoiceId'];

      final loyalty = responseData['loyalty'] is Map
          ? Map<String, dynamic>.from(responseData['loyalty'])
          : <String, dynamic>{};

      final subtotal = _toDouble(requestBody['netTotal']);
      final serviceCharge = _toDouble(requestBody['serviceChargeTotal']);
      final taxTotal = _toDouble(requestBody['taxTotal']);
      final discountTotal = _toDouble(requestBody['discountTotal']);
      final deliveryChargeTotal = _toDouble(requestBody['deliveryChargeTotal']);
      final total = _toDouble(requestBody['total']);

      int y = 20;
      final int paperHeight = 900 + (cart.length * 130);

      final buffer = StringBuffer();

      buffer.writeln('! 0 200 200 $paperHeight 1');

      if (showStoreDetails) {
        buffer.writeln('CENTER');

        if (storeName.isNotEmpty) {
          buffer.writeln('TEXT 4 0 0 $y ${_short(storeName, 28)}');
          y += 50;
        }

        if (address.isNotEmpty) {
          buffer.writeln('TEXT 0 0 0 $y ${_short(address, 38)}');
          y += 30;
        }

        if (phone.isNotEmpty) {
          buffer.writeln('TEXT 0 0 0 $y Tel: ${_short(phone, 28)}');
          y += 30;
        }

        if (email.isNotEmpty) {
          buffer.writeln('TEXT 0 0 0 $y ${_short(email, 34)}');
          y += 30;
        }
      }

      if (header.isNotEmpty) {
        buffer.writeln('LEFT');
        buffer.writeln('TEXT 0 0 20 $y ${_line()}');
        y += 30;

        buffer.writeln('CENTER');
        buffer.writeln('TEXT 0 0 0 $y ${_short(header, 34)}');
        y += 35;
      }

      buffer.writeln('LEFT');
      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 35;

      buffer.writeln('TEXT 0 0 20 $y Receipt No: $tokenNo');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Order ID: $orderId');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Invoice ID: $invoiceId');
      y += 30;

      buffer.writeln(
        'TEXT 0 0 20 $y Date: ${DateTime.now().toString().substring(0, 19)}',
      );
      y += 35;

      if (printToken && tokenNo != null) {
        buffer.writeln('CENTER');
        buffer.writeln('TEXT 4 0 0 $y TOKEN NO: $tokenNo');
        y += 55;
        buffer.writeln('LEFT');
      }

      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 35;

      if (showCustomerDetails) {
        final customerName = _clean(customer['name']);
        final customerPhone = _clean(customer['phone']);

        buffer.writeln(
          'TEXT 0 0 20 $y Customer: ${_short(customerName.isEmpty ? 'Walk-in' : customerName, 24)}',
        );
        y += 30;

        if (customerPhone.isNotEmpty) {
          buffer.writeln('TEXT 0 0 20 $y Phone: ${_short(customerPhone, 24)}');
          y += 30;
        }

        buffer.writeln(
          'TEXT 0 0 20 $y Order Type: ${_short(requestBody['deliveryType'], 20)}',
        );
        y += 35;

        buffer.writeln('TEXT 0 0 20 $y ${_line()}');
        y += 35;
      }

      for (final raw in cart) {
        final item = Map<String, dynamic>.from(raw);

        final title = _clean(
          item['title'] ??
              item['item_title'] ??
              item['item_name'] ??
              item['name'] ??
              item['menu_item_title'],
        );

        final qty = _toInt(
          item['quantity'] ?? item['qty'] ?? item['item_quantity'],
        );
        final unitPrice = _toDouble(
          item['unitPrice'] ??
              item['unit_price'] ??
              item['price'] ??
              item['item_price'],
        );

        final lineTotalRaw = _toDouble(
          item['total'] ??
              item['line_total'] ??
              item['item_total'] ??
              item['sub_total'],
        );

        final lineTotal = lineTotalRaw > 0 ? lineTotalRaw : qty * unitPrice;

        String itemName = title;

        final variant = item['variant'];
        if (variant is Map) {
          final variantTitle = _clean(variant['title'] ?? variant['name']);
          if (variantTitle.isNotEmpty) {
            itemName = '$itemName - $variantTitle';
          }
        }

        buffer.writeln('TEXT 0 0 20 $y ${_short(itemName, 32)}');
        y += 30;

        final addons = item['addons'];
        if (addons is List && addons.isNotEmpty) {
          final addonText = addons
              .map((a) {
                if (a is Map) return _clean(a['title'] ?? a['name']);
                return '';
              })
              .where((e) => e.isNotEmpty)
              .join(', ');

          if (addonText.isNotEmpty) {
            buffer.writeln('TEXT 0 0 20 $y Addons: ${_short(addonText, 24)}');
            y += 30;
          }
        }

        if (showNotes && _clean(item['notes']).isNotEmpty) {
          buffer.writeln('TEXT 0 0 20 $y Notes: ${_short(item['notes'], 26)}');
          y += 30;
        }

        buffer.writeln('TEXT 0 0 20 $y $qty x ${_money(currency, unitPrice)}');

        buffer.writeln('TEXT 0 0 300 $y ${_money(currency, lineTotal)}');

        y += 40;
      }

      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 35;

      buffer.writeln('TEXT 0 0 20 $y Subtotal:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, subtotal)}');
      y += 30;

      if (discountTotal > 0) {
        buffer.writeln('TEXT 0 0 20 $y Discount:');
        buffer.writeln('TEXT 0 0 300 $y ${_money(currency, discountTotal)}');
        y += 30;
      }

      buffer.writeln('TEXT 0 0 20 $y Tax:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, taxTotal)}');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Service Charge:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, serviceCharge)}');
      y += 30;

      if (deliveryChargeTotal > 0) {
        buffer.writeln('TEXT 0 0 20 $y Delivery Charge:');
        buffer.writeln(
          'TEXT 0 0 300 $y ${_money(currency, deliveryChargeTotal)}',
        );
        y += 30;
      }

      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 40;

      buffer.writeln('TEXT 4 0 20 $y TOTAL:');
      buffer.writeln('TEXT 4 0 230 $y ${_money(currency, total)}');
      y += 60;

      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 35;

      buffer.writeln('TEXT 4 0 20 $y Payment Details');
      y += 40;

      final paymentTitle = _clean(paymentType['title']).isEmpty
          ? 'Payment'
          : _clean(paymentType['title']);

      buffer.writeln('TEXT 0 0 20 $y ${_short(paymentTitle, 18)}:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, total)}');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Total Paid:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, total)}');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Balance:');
      buffer.writeln('TEXT 0 0 300 $y ${_money(currency, 0)}');
      y += 40;

      if (loyalty.isNotEmpty) {
        buffer.writeln('TEXT 0 0 20 $y ${_line()}');
        y += 35;

        buffer.writeln('TEXT 4 0 20 $y Loyalty');
        y += 40;

        if (loyalty['earnedPoints'] != null) {
          buffer.writeln('TEXT 0 0 20 $y Earned: ${loyalty['earnedPoints']}');
          y += 30;
        }

        if (loyalty['redeemedPoints'] != null) {
          buffer.writeln(
            'TEXT 0 0 20 $y Redeemed: ${loyalty['redeemedPoints']}',
          );
          y += 30;
        }

        if (loyalty['remainingLoyaltyPoints'] != null) {
          buffer.writeln(
            'TEXT 0 0 20 $y Remaining: ${loyalty['remainingLoyaltyPoints']}',
          );
          y += 35;
        }
      }

      buffer.writeln('TEXT 0 0 20 $y ${_line()}');
      y += 35;

      if (footer.isNotEmpty) {
        buffer.writeln('CENTER');
        buffer.writeln('TEXT 0 0 0 $y ${_short(footer, 36)}');
        y += 40;
      }

      buffer.writeln('CENTER');
      buffer.writeln('TEXT 0 0 0 $y Software by Talentfort');
      y += 40;

      buffer.writeln('FORM');
      buffer.writeln('PRINT');

      return _sendCpcl(buffer.toString());
    } catch (e) {
      print('PRINT CHECKOUT RECEIPT ERROR: $e');
      return false;
    }
  }

  static Future<bool> printReceiptFromResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : response;

    return printCheckoutReceipt(
      responseData: data,
      requestBody: data,
      paymentType: {'title': 'Payment'},
      storeSettings: const {'currency': 'LKR', 'store_name': 'SYNERA RMS'},
      printSettings: const {
        'show_store_details': 1,
        'show_customer_details': 1,
        'show_notes': 0,
        'print_token': 0,
        'header': 'Receipt',
        'footer': 'Thank You',
      },
    );
  }
}

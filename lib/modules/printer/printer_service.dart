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

  static String _clean(String value) {
    return value
        .replaceAll('"', '')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();
  }

  static String _short(String value, int max) {
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

    final cpcl = '''
! 0 200 200 400 1
CENTER
TEXT 4 0 0 40 CPCL TEST
TEXT 4 0 0 100 SYNERA RMS
TEXT 4 0 0 160 PRINT OK
FORM
PRINT
''';

    return _sendCpcl(cpcl);
  }

  static Future<bool> printReceiptFromResponse(
    Map<String, dynamic> response,
  ) async {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'])
        : response;

    final order = data['order'] is Map
        ? Map<String, dynamic>.from(data['order'])
        : data;

    final invoice = data['invoice'] is Map
        ? Map<String, dynamic>.from(data['invoice'])
        : data;

    final rawItems =
        data['items'] ??
        order['items'] ??
        data['cart'] ??
        order['cart'] ??
        invoice['items'] ??
        [];

    final items = rawItems is List
        ? rawItems.map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return printReceipt(
      cartItems: items,
      customerName:
          order['customer_name']?.toString() ??
          order['customerName']?.toString() ??
          order['customer']?['name']?.toString() ??
          data['customerName']?.toString() ??
          '-',
      customerPhone:
          order['customer_phone']?.toString() ??
          order['customerPhone']?.toString() ??
          order['customer']?['phone']?.toString() ??
          data['customerPhone']?.toString() ??
          '-',
      subtotal: _toDouble(invoice['subtotal']) != 0
          ? _toDouble(invoice['subtotal'])
          : _toDouble(order['netTotal'] ?? data['netTotal']),
      tax: _toDouble(invoice['tax'] ?? order['taxTotal'] ?? data['taxTotal']),
      serviceCharge: _toDouble(
        invoice['service_charge'] ??
            invoice['serviceCharge'] ??
            order['serviceChargeTotal'] ??
            data['serviceChargeTotal'],
      ),
      total: _toDouble(invoice['total'] ?? order['total'] ?? data['total']),
    );
  }

  static String _itemTitle(Map<String, dynamic> item) {
    return _clean(
      item['title']?.toString() ??
          item['item_title']?.toString() ??
          item['item_name']?.toString() ??
          item['name']?.toString() ??
          item['menu_item_title']?.toString() ??
          '',
    );
  }

  static Future<bool> printReceipt({
    required List<Map<String, dynamic>> cartItems,
    required String customerName,
    required String customerPhone,
    required double subtotal,
    required double tax,
    required double serviceCharge,
    required double total,
  }) async {
    try {
      final connected = await connectSavedPrinter();
      if (!connected) return false;

      int y = 30;
      final int paperHeight = 700 + (cartItems.length * 100);

      final buffer = StringBuffer();

      buffer.writeln('! 0 200 200 $paperHeight 1');
      buffer.writeln('CENTER');
      buffer.writeln('TEXT 4 0 0 $y SYNERA RMS');
      y += 50;

      buffer.writeln('TEXT 4 0 0 $y RECEIPT');
      y += 55;

      buffer.writeln('LEFT');
      buffer.writeln('TEXT 0 0 20 $y ------------------------------');
      y += 35;

      buffer.writeln(
        'TEXT 0 0 20 $y Customer: ${_short(customerName.isEmpty ? 'Walk-in' : customerName, 22)}',
      );
      y += 30;

      buffer.writeln(
        'TEXT 0 0 20 $y Phone: ${_short(customerPhone.isEmpty ? '-' : customerPhone, 24)}',
      );
      y += 30;

      buffer.writeln(
        'TEXT 0 0 20 $y Date: ${DateTime.now().toString().substring(0, 19)}',
      );
      y += 35;

      buffer.writeln('TEXT 0 0 20 $y ------------------------------');
      y += 35;

      for (final item in cartItems) {
        final title = _itemTitle(item);

        final qty = _toInt(
          item['quantity'] ?? item['qty'] ?? item['item_quantity'],
        );

        final unitPrice = _toDouble(
          item['unitPrice'] ??
              item['unit_price'] ??
              item['price'] ??
              item['item_price'],
        );

        final lineTotal = _toDouble(
          item['total'] ??
              item['line_total'] ??
              item['item_total'] ??
              item['sub_total'],
        );

        final variant = item['variant'];
        final addons = item['addons'];

        String itemName = title;

        if (variant is Map) {
          final variantTitle = _clean(
            variant['title']?.toString() ?? variant['name']?.toString() ?? '',
          );
          if (variantTitle.isNotEmpty) {
            itemName = '$title - $variantTitle';
          }
        }

        buffer.writeln('TEXT 0 0 20 $y ${_short(itemName, 30)}');
        y += 30;

        final displayTotal = lineTotal > 0 ? lineTotal : unitPrice * qty;

        buffer.writeln(
          'TEXT 0 0 20 $y $qty x ${unitPrice.toStringAsFixed(2)} = ${displayTotal.toStringAsFixed(2)}',
        );
        y += 35;

        if (addons is List && addons.isNotEmpty) {
          final addonText = addons
              .map(
                (a) => a is Map
                    ? _clean(
                        a['title']?.toString() ?? a['name']?.toString() ?? '',
                      )
                    : '',
              )
              .where((e) => e.isNotEmpty)
              .join(', ');

          if (addonText.isNotEmpty) {
            buffer.writeln('TEXT 0 0 20 $y Addons: ${_short(addonText, 24)}');
            y += 35;
          }
        }
      }

      buffer.writeln('TEXT 0 0 20 $y ------------------------------');
      y += 35;

      buffer.writeln('TEXT 0 0 20 $y Subtotal: ${subtotal.toStringAsFixed(2)}');
      y += 30;

      buffer.writeln('TEXT 0 0 20 $y Tax: ${tax.toStringAsFixed(2)}');
      y += 30;

      buffer.writeln(
        'TEXT 0 0 20 $y Service: ${serviceCharge.toStringAsFixed(2)}',
      );
      y += 40;

      buffer.writeln('TEXT 4 0 20 $y TOTAL: ${total.toStringAsFixed(2)}');
      y += 60;

      buffer.writeln('CENTER');
      buffer.writeln('TEXT 4 0 0 $y THANK YOU');
      y += 50;

      buffer.writeln('FORM');
      buffer.writeln('PRINT');

      return _sendCpcl(buffer.toString());
    } catch (e) {
      print('CPCL RECEIPT ERROR: $e');
      return false;
    }
  }
}

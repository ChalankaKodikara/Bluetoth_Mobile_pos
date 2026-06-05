import 'dart:io';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'printer_service.dart';

class PrinterController extends GetxController {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  final isLoading = false.obs;
  final isConnected = false.obs;
  final connectedAddress = ''.obs;
  final printers = <BluetoothDevice>[].obs;

  BluetoothDevice? selectedPrinter;

  @override
  void onInit() {
    super.onInit();
    loadPrinterData();
  }

  Future<void> loadPrinterData() async {
    await requestBluetoothPermissions();
    await getPairedPrinters();
    await checkConnection();
  }

  Future<void> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return;

    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.location.request();
  }

  Future<void> checkConnection() async {
    try {
      final status = await bluetooth.isConnected;
      isConnected.value = status == true;

      if (!isConnected.value) {
        connectedAddress.value = '';
      } else {
        connectedAddress.value = PrinterService.savedPrinterAddress ?? '';
      }
    } catch (e) {
      isConnected.value = false;
      connectedAddress.value = '';
      print('CHECK CONNECTION ERROR: $e');
    }
  }

  Future<void> getPairedPrinters() async {
    isLoading.value = true;

    try {
      await requestBluetoothPermissions();

      final devices = await bluetooth.getBondedDevices();

      printers.assignAll(
        devices.where((device) {
          final name = (device.name ?? '').toLowerCase();
          return name.contains('printer') ||
              name.contains('xprinter') ||
              name.contains('xp') ||
              name.contains('pos') ||
              name.contains('thermal') ||
              name.contains('receipt') ||
              name.contains('rpp') ||
              name.contains('bt');
        }).toList(),
      );

      for (final d in printers) {
        print('PRINTER FOUND: ${d.name} | ${d.address}');
      }

      if (printers.isEmpty) {
        Get.snackbar(
          'No Printers',
          'Pair printer from phone Bluetooth settings first',
        );
      }
    } catch (e) {
      print('GET PRINTERS ERROR: $e');
      Get.snackbar('Printer Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> connectPrinter(BluetoothDevice printer) async {
    isLoading.value = true;

    try {
      await requestBluetoothPermissions();

      final oldConnected = await bluetooth.isConnected;
      if (oldConnected == true) {
        await bluetooth.disconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      selectedPrinter = printer;

      print('CONNECTING PRINTER: ${printer.name} | ${printer.address}');

      await bluetooth.connect(printer);
      await Future.delayed(const Duration(seconds: 2));

      final connected = await bluetooth.isConnected;
      isConnected.value = connected == true;

      if (isConnected.value) {
        connectedAddress.value = printer.address ?? '';
        await PrinterService.savePrinterAddress(printer.address ?? '');

        Get.snackbar('Success', 'Printer connected successfully');
      } else {
        selectedPrinter = null;
        connectedAddress.value = '';
        Get.snackbar('Failed', 'Printer connection failed');
      }
    } catch (e) {
      print('CONNECT PRINTER ERROR: $e');

      isConnected.value = false;
      connectedAddress.value = '';
      selectedPrinter = null;

      Get.snackbar('Connection Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disconnectPrinter() async {
    isLoading.value = true;

    try {
      final connected = await bluetooth.isConnected;

      if (connected == true) {
        await bluetooth.disconnect();
        await Future.delayed(const Duration(milliseconds: 800));
      }

      isConnected.value = false;
      connectedAddress.value = '';
      selectedPrinter = null;

      Get.snackbar('Printer', 'Printer disconnected');
    } catch (e) {
      print('DISCONNECT PRINTER ERROR: $e');
      Get.snackbar('Disconnect Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reconnectSavedPrinter() async {
    isLoading.value = true;

    try {
      final connected = await PrinterService.connectSavedPrinter();

      isConnected.value = connected;

      if (connected) {
        connectedAddress.value = PrinterService.savedPrinterAddress ?? '';
        Get.snackbar('Success', 'Saved printer reconnected');
      } else {
        connectedAddress.value = '';
        Get.snackbar('Failed', 'Could not reconnect saved printer');
      }
    } catch (e) {
      print('RECONNECT ERROR: $e');
      Get.snackbar('Reconnect Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> testPrint() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      final result = await PrinterService.testPrint();

      await checkConnection();

      Get.snackbar(
        result ? 'Success' : 'Failed',
        result ? 'Test print sent successfully' : 'Test print failed',
      );
    } catch (e) {
      print('TEST PRINT CONTROLLER ERROR: $e');
      Get.snackbar('Print Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'printer_controller.dart';

class PrinterSetupPage extends StatelessWidget {
  const PrinterSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PrinterController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Printer'),
        actions: [
          Obx(() {
            if (!controller.isConnected.value) {
              return const SizedBox.shrink();
            }

            return IconButton(
              onPressed: controller.disconnectPrinter,
              icon: const Icon(Icons.link_off),
            );
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Obx(() {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: controller.isConnected.value
                      ? AppColors.primaryLight
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: controller.isConnected.value
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  controller.isConnected.value
                      ? 'Printer Connected'
                      : 'No Printer Connected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: controller.isConnected.value
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.getPairedPrinters,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Paired Printers'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.printers.isEmpty) {
                  return const Center(
                    child: Text(
                      'No paired printers found.\nPair printer from phone Bluetooth settings first.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: controller.printers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final printer = controller.printers[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.print, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    printer.name ?? 'Unknown Printer',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    printer.address ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final address = printer.address ?? '';

                              final isThisPrinterConnected =
                                  controller.isConnected.value &&
                                  controller.connectedAddress.value == address;

                              return SizedBox(
                                width: 108,
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isThisPrinterConnected) {
                                      controller.disconnectPrinter();
                                    } else {
                                      controller.connectPrinter(printer);
                                    }
                                  },
                                  child: Text(
                                    isThisPrinterConnected
                                        ? 'Disconnect'
                                        : 'Connect',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.testPrint,
                  icon: const Icon(Icons.receipt),
                  label: const Text('Test Print'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

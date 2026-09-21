import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  final MockService service;

  const ReportsScreen({super.key, required this.service});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReportType = "Daily Activity";
  bool _isGenerating = false;
  final List<String> _reportHistory = [
    "daily_activity_2026_07_18.pdf (1.2 MB)",
    "monthly_valuation_2026_06.pdf (4.5 MB)",
    "sales_summary_q2.xlsx (850 KB)",
  ];

  final List<String> _reportTypes = [
    "Daily Activity",
    "Monthly Stock Valuation",
    "Sales & Invoicing Summary",
    "Inventory Shrinkage & Audits",
  ];

  void _generateMockReport() {
    setState(() => _isGenerating = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isGenerating = false;
        final name =
            "${_selectedReportType.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.pdf";
        _reportHistory.insert(0, "$name (1.4 MB)");
        widget.service.addNotification(
          "Report Generated",
          "Generated PDF document for $_selectedReportType successfully.",
          "SYSTEM",
        );
      });
    });
  }

  void _shareReport(String name) {
    widget.service.addNotification(
      "Report Dispatched",
      "Sharing document '$name' via system files api.",
      "SYSTEM",
    );
  }

  void _openPrinterSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothPrinterScreen(service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Reports"),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_disabled_rounded),
            tooltip: "Receipt Printers",
            onPressed: _openPrinterSetup,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Report Builder Engine",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            EnterpriseCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedReportType,
                    decoration: const InputDecoration(
                      labelText: "Select Report Template type",
                    ),
                    items: _reportTypes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedReportType = val!),
                  ),
                  const SizedBox(height: 16),
                  if (_isGenerating)
                    const Column(
                      children: [
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          "Compiling SQLite records and drawing canvas structures...",
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: EnterpriseButton(
                            label: "Generate PDF Report",
                            icon: Icons.picture_as_pdf_rounded,
                            onPressed: _generateMockReport,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              "Local Hardware Printing Services",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            EnterpriseCard(
              child: ListTile(
                leading: const Icon(
                  Icons.bluetooth_audio_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                title: const Text(
                  "Thermal Bluetooth Printer Configuration",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  "Select local POS devices and configure slip layout dimensions.",
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: _openPrinterSetup,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Prior Document Export Logs",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            EnterpriseCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reportHistory.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final file = _reportHistory[idx];
                  final isExcel = file.endsWith("xlsx)");
                  return ListTile(
                    leading: Icon(
                      isExcel
                          ? Icons.table_view_rounded
                          : Icons.picture_as_pdf_outlined,
                      color: isExcel ? AppColors.secondary : AppColors.error,
                    ),
                    title: Text(
                      file,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share, size: 18),
                          onPressed: () => _shareReport(file),
                        ),
                        IconButton(
                          icon: const Icon(Icons.print, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Sending $file to print server...",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class BluetoothPrinterScreen extends StatefulWidget {
  final MockService service;

  const BluetoothPrinterScreen({super.key, required this.service});

  @override
  State<BluetoothPrinterScreen> createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  bool _isScanning = false;

  void _scanDevices() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isScanning = false);
      widget.service.addNotification(
        "Printer Scan Complete",
        "Discovered 3 Bluetooth receipt printer nodes nearby.",
        "SYSTEM",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final printers = widget.service.printers;

    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Print Setup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Hardware Output Device",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text("Scan Devices"),
                        onPressed: _scanDevices,
                      ),
              ],
            ),
            const SizedBox(height: 8),

            EnterpriseCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: printers.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final printer = printers[idx];
                  return ListTile(
                    leading: const Icon(Icons.print_rounded),
                    title: Text(
                      printer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      printer.address,
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: Switch(
                      value: printer.isConnected,
                      onChanged: (val) {
                        setState(() {
                          widget.service.togglePrinterConnection(idx);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Slip Print Preview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    "APEX ENTERPRISE LOGISTICS",
                    style: TextStyle(
                      fontFamily: "Courier",
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    "WH Site: Central Zone WH-01",
                    style: TextStyle(fontFamily: "Courier", fontSize: 10),
                  ),
                  const Text(
                    "Tel: +1 (555) 987-6543",
                    style: TextStyle(fontFamily: "Courier", fontSize: 10),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Item SKU",
                        style: TextStyle(
                          fontFamily: "Courier",
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Qty",
                        style: TextStyle(
                          fontFamily: "Courier",
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Total",
                        style: TextStyle(
                          fontFamily: "Courier",
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  _buildPreviewItem("RFID Pallet Tags", "12", "\$59.88"),
                  _buildPreviewItem("Forklift Battery XL", "1", "\$2,450.00"),
                  const Divider(height: 16),
                  _buildPreviewItem("Subtotal", "", "\$2,509.88"),
                  _buildPreviewItem("Tax VAT (15%)", "", "\$376.48"),
                  _buildPreviewItem(
                    "Grand Total",
                    "",
                    "\$2,886.36",
                    isBold: true,
                  ),
                  const Divider(height: 16),
                  const Text(
                    "THANK YOU FOR YOUR BUSINESS!",
                    style: TextStyle(
                      fontFamily: "Courier",
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const Text(
                    "Receipt generated offline using Hive caches.",
                    style: TextStyle(fontFamily: "Courier", fontSize: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EnterpriseButton(
                    label: "Verify connection & Print test",
                    icon: Icons.print_rounded,
                    onPressed: () {
                      final hasConnected = printers.any((p) => p.isConnected);
                      if (hasConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Printing receipt... Success"),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text("No active printer"),
                            content: const Text(
                              "Please connect to one of the Bluetooth printers above before attempting a test print job.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(
    String item,
    String qty,
    String price, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              item,
              style: TextStyle(
                fontFamily: "Courier",
                fontSize: 10,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (qty.isNotEmpty)
            SizedBox(
              width: 30,
              child: Text(
                qty,
                style: const TextStyle(fontFamily: "Courier", fontSize: 10),
              ),
            ),
          Text(
            price,
            style: TextStyle(
              fontFamily: "Courier",
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

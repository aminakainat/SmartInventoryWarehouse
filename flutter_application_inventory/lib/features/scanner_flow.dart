import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';
import 'package:flutter_application_inventory/features/inventory_flow.dart';

class ScannerScreen extends StatefulWidget {
  final MockService service;

  const ScannerScreen({super.key, required this.service});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isQrMode = false;
  bool _isFlashOn = false;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
    widget.service.addNotification(
      _isFlashOn ? "Flashlight Activated" : "Flashlight Deactivated",
      "Simulated device hardware flash toggled.",
      "SYSTEM",
    );
  }

  void _simulateSuccessfulScan() {
    final barcodes = [
      "880947623910",
      "079357318944",
      "690123456789",
      "400638133393",
    ];
    final chosenBarcode = _isQrMode
        ? "https://apex-erp.central.net/warehouse/verify?sku=PLT-RFID-001"
        : barcodes[DateTime.now().second % barcodes.length];

    HapticFeedback.lightImpact();
    widget.service.recordScan(chosenBarcode);

    if (_isQrMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              QrResultScreen(qrContent: chosenBarcode, service: widget.service),
        ),
      );
    } else {
      final matchedProduct = widget.service.products.firstWhere(
        (p) => p.barcode == chosenBarcode,
        orElse: () => Product(
          id: "",
          name: "Unknown SKU Item",
          sku: "UNKNOWN-SKU",
          barcode: chosenBarcode,
          category: "Uncategorized",
          quantity: 0,
          price: 0.0,
          location: "Unknown",
          images: [],
        ),
      );

      _showScanConfirmation(matchedProduct);
    }
  }

  void _showScanConfirmation(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Barcode Scan Success",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "SKU: ${p.sku} | Barcode: ${p.barcode}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (p.id.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Stock Quantity in Cache: ${p.quantity} units",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    StatusChip(label: p.location, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: EnterpriseSecondaryButton(
                        label: "Audit Adjust",
                        onPressed: () {
                          Navigator.pop(context);
                          _showAdjustQuantityDialog(p);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnterpriseButton(
                        label: "Product Specs",
                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: p,
                                service: widget.service,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  "This barcode is not matched inside local SQLite databases.",
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: EnterpriseButton(
                    label: "Add to ERP Database",
                    onPressed: () {
                      Navigator.pop(context);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductFormScreen(
                            service: widget.service,
                            product: Product(
                              id: "",
                              name: "",
                              sku: "SKU-${p.barcode.substring(0, 4)}",
                              barcode: p.barcode,
                              category: "Hardware Devices",
                              quantity: 0,
                              price: 0.0,
                              location: "Aisle A",
                              images: [],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAdjustQuantityDialog(Product p) {
    int qtyDelta = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Adjust ${p.name}"),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Quantity adjustments (e.g. +5, -10)",
          ),
          onChanged: (val) => qtyDelta = int.tryParse(val) ?? 0,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (qtyDelta != 0) {
                widget.service.adjustStock(p.id, qtyDelta, "Scan Audit");
              }
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }

  void _showManualBarcodeSheet() {
    final barcodeController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Manual EAN Barcode Entry",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              EnterpriseTextField(
                labelText: "Barcode Digits",
                keyboardType: TextInputType.number,
                controller: barcodeController,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: EnterpriseButton(
                  label: "Submit Barcode",
                  onPressed: () {
                    final text = barcodeController.text.trim();
                    if (text.isNotEmpty) {
                      Navigator.pop(context);

                      widget.service.recordScan(text);
                      final matchedProduct = widget.service.products.firstWhere(
                        (p) => p.barcode == text,
                        orElse: () => Product(
                          id: "",
                          name: "Unknown SKU Item",
                          sku: "UNKNOWN-SKU",
                          barcode: text,
                          category: "Uncategorized",
                          quantity: 0,
                          price: 0.0,
                          location: "Unknown",
                          images: [],
                        ),
                      );
                      _showScanConfirmation(matchedProduct);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_left,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isQrMode = false),
                        child: Text(
                          "BARCODE",
                          style: TextStyle(
                            color: !_isQrMode
                                ? AppColors.primary
                                : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _isQrMode = true),
                        child: Text(
                          "QR CODE",
                          style: TextStyle(
                            color: _isQrMode
                                ? AppColors.primary
                                : Colors.white60,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  final y =
                                      constraints.maxHeight *
                                      _laserAnimation.value;
                                  return Positioned(
                                    top: y,
                                    left: 10,
                                    right: 10,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.error.withValues(
                                              alpha: 0.8,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          Center(
                            child: Container(
                              width: _isQrMode ? 180 : 260,
                              height: _isQrMode ? 180 : 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                              ),
                            ),
                          ),

                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Text(
                                _isQrMode
                                    ? "Align QR code inside box"
                                    : "Position barcode inside window",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.center_focus_weak, color: Colors.white),
                label: const Text(
                  "Simulate Camera Capture",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _simulateSuccessfulScan,
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: EnterpriseSecondaryButton(
                          label: "Type Code Manually",
                          icon: Icons.edit_note,
                          onPressed: _showManualBarcodeSheet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Session Scan History",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.service.scanHistory.length} scan(s)",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.service.scanHistory.isEmpty)
                    Container(
                      height: 50,
                      alignment: Alignment.center,
                      child: const Text(
                        "No barcodes captured in this session",
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    )
                  else
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.service.scanHistory.length,
                        itemBuilder: (context, index) {
                          final item = widget.service.scanHistory[index];
                          return Card(
                            color: const Color(0xFF1E293B),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.qr_code,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.length > 15
                                        ? "${item.substring(0, 12)}..."
                                        : item,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrResultScreen extends StatelessWidget {
  final String qrContent;
  final MockService service;

  const QrResultScreen({
    super.key,
    required this.qrContent,
    required this.service,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: qrContent));
    service.addNotification(
      "Copied to Clipboard",
      "QR result payload copied successfully.",
      "SYSTEM",
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR Content copied to Clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Result details")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.qr_code_2, size: 36, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  "QR Scan Payload",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            EnterpriseCard(
              child: Text(
                qrContent,
                style: const TextStyle(
                  fontFamily: "Courier",
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: EnterpriseButton(
                    label: "Copy Payload",
                    icon: Icons.copy_rounded,
                    onPressed: () => _copyToClipboard(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EnterpriseSecondaryButton(
                    label: "Share API",
                    icon: Icons.share_rounded,
                    onPressed: () {
                      service.addNotification(
                        "System Share Dialog",
                        "Sharing QR data payload.",
                        "SYSTEM",
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnterpriseSecondaryButton(
                    label: "Save local",
                    icon: Icons.save_rounded,
                    onPressed: () {
                      service.addNotification(
                        "Record Saved",
                        "QR record saved locally to cached scanner database.",
                        "SYSTEM",
                      );
                      Navigator.pop(context);
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
}

import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';

class BillingScreen extends StatefulWidget {
  final MockService service;

  const BillingScreen({super.key, required this.service});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<InvoiceItem> _cart = [];
  final _customerNameController = TextEditingController(text: "Global Logistics Corp");
  final _customerPhoneController = TextEditingController(text: "+1 555 987 6543");
  double _discountPercentage = 0.0;
  final double _taxRate = 15.0; // 15% standard VAT/Tax
  String _paymentMethod = "Credit Account";

  final List<String> _paymentMethods = ["Credit Account", "Corporate POS Card", "Cash Payment"];

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);
  double get _discountAmount => _subtotal * (_discountPercentage / 100);
  double get _taxAmount => (_subtotal - _discountAmount) * (_taxRate / 100);
  double get _grandTotal => _subtotal - _discountAmount + _taxAmount;

  void _addItemToCart(Product p) {
    setState(() {
      int idx = _cart.indexWhere((item) => item.product.id == p.id);
      if (idx != -1) {
        if (_cart[idx].quantity < p.quantity) {
          _cart[idx].quantity++;
        }
      } else {
        if (p.quantity > 0) {
          _cart.add(InvoiceItem(product: p, quantity: 1));
        }
      }
    });
  }

  void _adjustCartQuantity(int idx, int delta) {
    setState(() {
      final item = _cart[idx];
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cart.removeAt(idx);
      } else if (newQty <= item.product.quantity) {
        item.quantity = newQty;
      }
    });
  }

  void _showAddProductSearchSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final availableProducts = widget.service.products.where((p) => p.quantity > 0).toList();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Inventory Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Expanded(
                child: availableProducts.isEmpty
                    ? const Center(child: Text("No physical stock available to sell."))
                    : ListView.builder(
                        itemCount: availableProducts.length,
                        itemBuilder: (context, i) {
                          final p = availableProducts[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text("SKU: ${p.sku} | Price: \$${p.price.toStringAsFixed(2)}"),
                            trailing: Text("Qty: ${p.quantity}"),
                            onTap: () {
                              _addItemToCart(p);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processCheckout() {
    if (_cart.isEmpty) return;

    final invoice = Invoice(
      id: "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      customerName: _customerNameController.text.trim().isEmpty ? "Anonymous Client" : _customerNameController.text.trim(),
      customerPhone: _customerPhoneController.text.trim(),
      items: List.from(_cart),
      discount: _discountPercentage,
      taxRate: _taxRate,
      paymentMethod: _paymentMethod,
      date: DateTime.now(),
      isSynced: widget.service.isOnline, // Sync immediately if online
    );

    widget.service.createInvoice(invoice);

    // Clear state
    setState(() {
      _cart.clear();
      _discountPercentage = 0.0;
    });

    _showReceiptPreview(invoice);
  }

  void _showReceiptPreview(Invoice inv) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: inv.isSynced ? AppColors.success : AppColors.warning),
              const SizedBox(width: 8),
              Text("Invoice: #${inv.id}"),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer: ${inv.customerName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text("Phone: ${inv.customerPhone}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text("Date: ${inv.date.toLocal()}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const Divider(height: 24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: inv.items.length,
                    itemBuilder: (context, idx) {
                      final item = inv.items[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item.product.name} (x${item.quantity})", style: const TextStyle(fontSize: 12)),
                            Text("\$${item.total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  _buildReceiptSummaryRow("Subtotal", "\$${inv.subtotal.toStringAsFixed(2)}"),
                  _buildReceiptSummaryRow("Discount (${inv.discount}%)", "-\$${inv.discountAmount.toStringAsFixed(2)}"),
                  _buildReceiptSummaryRow("VAT Tax (${inv.taxRate}%)", "+\$${inv.taxAmount.toStringAsFixed(2)}"),
                  const Divider(height: 12),
                  _buildReceiptSummaryRow("Total Amount", "\$${inv.grandTotal.toStringAsFixed(2)}", isBold: true),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: inv.isSynced ? AppColors.success.withValues(alpha: 0.12) : AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inv.isSynced
                          ? "Successfully registered to enterprise servers."
                          : "Saved to Offline cache. Synced queue pending connection.",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inv.isSynced ? AppColors.success : AppColors.warning,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bluetooth print job sent to queue...")),
                );
              },
              child: const Text("Print Receipt", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptSummaryRow(String title, String val, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: isBold ? 13 : 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(fontSize: isBold ? 14 : 11, fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Offline Billing Terminal")),
      body: Column(
        children: [
          ConnectivityBanner(
            isOnline: widget.service.isOnline,
            onToggle: () => setState(() => widget.service.isOnline = !widget.service.isOnline),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Details Card
                  Text(
                    "Customer Details",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  EnterpriseCard(
                    child: Column(
                      children: [
                        EnterpriseTextField(
                          labelText: "Client Company Name",
                          controller: _customerNameController,
                        ),
                        const SizedBox(height: 12),
                        EnterpriseTextField(
                          labelText: "Phone / VAT registration",
                          controller: _customerPhoneController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shopping Cart Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Shopping Cart Items",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text("Add SKU"),
                        onPressed: _showAddProductSearchSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  EnterpriseCard(
                    padding: EdgeInsets.zero,
                    child: _cart.isEmpty
                        ? Container(
                            height: 100,
                            alignment: Alignment.center,
                            child: const Text("Cart is empty. Click 'Add SKU' above.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _cart.length,
                            separatorBuilder: (context, idx) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final item = _cart[idx];
                              return ListTile(
                                title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text(
                                  "\$${item.product.price.toStringAsFixed(2)} / unit | Max: ${item.product.quantity}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => _adjustCartQuantity(idx, -1),
                                    ),
                                    Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => _adjustCartQuantity(idx, 1),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Totals and taxes Panel
                  Text(
                    "Checkout Ledger",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  EnterpriseCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Subtotal Amount", style: TextStyle(fontSize: 12)),
                            Text("\$${_subtotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(child: Text("Discount Percentage", style: TextStyle(fontSize: 12))),
                            SizedBox(
                              width: 80,
                              height: 35,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8), hintText: "0.0%"),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (val) {
                                  setState(() {
                                    _discountPercentage = double.tryParse(val) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("VAT Standard Tax ($_taxRate%)", style: const TextStyle(fontSize: 12)),
                            Text("+\$${_taxAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.error)),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Grand Total Value", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              "\$${_grandTotal.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _paymentMethod,
                          decoration: const InputDecoration(labelText: "Corporate Payment Terms"),
                          items: _paymentMethods.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) => setState(() => _paymentMethod = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: EnterpriseButton(
                      label: "Post Invoice Checkouts",
                      icon: Icons.check_circle_outline,
                      isLoading: false,
                      onPressed: _cart.isEmpty ? () {} : _processCheckout,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

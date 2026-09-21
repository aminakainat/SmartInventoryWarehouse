import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';

class StockManagementScreen extends StatefulWidget {
  final MockService service;

  const StockManagementScreen({super.key, required this.service});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  String _selectedLogFilter = "ALL";

  List<StockMoveLog> _getFilteredLogs() {
    final logs = widget.service.stockLogs;
    if (_selectedLogFilter == "ALL") return logs;
    return logs.where((l) => l.type == _selectedLogFilter).toList();
  }

  void _showNewTransferSheet() {
    if (widget.service.products.isEmpty) return;

    Product selectedProduct = widget.service.products.first;
    String destWH = "East Division (WH-02)";
    final qtyController = TextEditingController(text: "5");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Initiate Internal Transfer",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Product>(
                initialValue: selectedProduct,
                decoration: const InputDecoration(
                  labelText: "Select Stock Item",
                ),
                items: widget.service.products.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text("${p.name} (Max: ${p.quantity})"),
                  );
                }).toList(),
                onChanged: (p) => selectedProduct = p!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: destWH,
                decoration: const InputDecoration(
                  labelText: "Destination Warehouse Site",
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Central Zone (WH-01)",
                    child: Text("Central Zone (WH-01)"),
                  ),
                  DropdownMenuItem(
                    value: "East Division (WH-02)",
                    child: Text("East Division (WH-02)"),
                  ),
                  DropdownMenuItem(
                    value: "North Logistics Hub (WH-03)",
                    child: Text("North Logistics Hub (WH-03)"),
                  ),
                ],
                onChanged: (val) => destWH = val!,
              ),
              const SizedBox(height: 12),
              EnterpriseTextField(
                labelText: "Quantity Units to Dispatch",
                keyboardType: TextInputType.number,
                controller: qtyController,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: EnterpriseButton(
                  label: "Dispatch Stock Transfer",
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text) ?? 0;
                    if (qty > 0 && qty <= selectedProduct.quantity) {
                      setState(() {
                        widget.service.transferStock(
                          selectedProduct.id,
                          qty,
                          destWH,
                        );
                      });
                      Navigator.pop(context);
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

  void _showNewIncomingSheet() {
    if (widget.service.products.isEmpty) return;

    Product selectedProduct = widget.service.products.first;
    final qtyController = TextEditingController(text: "50");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Log Incoming Inventory",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Product>(
                initialValue: selectedProduct,
                decoration: const InputDecoration(
                  labelText: "Select Target SKU",
                ),
                items: widget.service.products.map((p) {
                  return DropdownMenuItem(value: p, child: Text(p.name));
                }).toList(),
                onChanged: (p) => selectedProduct = p!,
              ),
              const SizedBox(height: 12),
              EnterpriseTextField(
                labelText: "Quantity Incoming Received",
                keyboardType: TextInputType.number,
                controller: qtyController,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: EnterpriseButton(
                  label: "Commit Incoming Stock",
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text) ?? 0;
                    if (qty > 0) {
                      setState(() {
                        widget.service.adjustStock(
                          selectedProduct.id,
                          qty,
                          "Supplier Shipment Received",
                        );
                      });
                      Navigator.pop(context);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      appBar: AppBar(title: const Text("Stock & Movement Control")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: EnterpriseSecondaryButton(
                    label: "Inbound Log",
                    icon: Icons.south_west_rounded,
                    onPressed: _showNewIncomingSheet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnterpriseSecondaryButton(
                    label: "Internal Move",
                    icon: Icons.swap_horiz_rounded,
                    onPressed: _showNewTransferSheet,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip("ALL"),
                  _buildFilterChip("INCOMING"),
                  _buildFilterChip("OUTGOING"),
                  _buildFilterChip("TRANSFER"),
                  _buildFilterChip("ADJUSTMENT"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredLogs.isEmpty
                ? const Center(
                    child: Text("No movement histories found for this filter."),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final isLast = index == filteredLogs.length - 1;
                      return _buildTimelineItem(log, isLast, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedLogFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(
          filter,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedLogFilter = filter;
          });
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildTimelineItem(StockMoveLog log, bool isLast, bool isDark) {
    Color nodeColor;
    IconData nodeIcon;

    switch (log.type) {
      case 'INCOMING':
        nodeColor = AppColors.success;
        nodeIcon = Icons.arrow_downward_rounded;
        break;
      case 'OUTGOING':
        nodeColor = AppColors.error;
        nodeIcon = Icons.arrow_upward_rounded;
        break;
      case 'TRANSFER':
        nodeColor = AppColors.primary;
        nodeIcon = Icons.swap_horiz_rounded;
        break;
      default:
        nodeColor = AppColors.warning;
        nodeIcon = Icons.edit_note_rounded;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nodeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(nodeIcon, color: nodeColor, size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${log.timestamp.month}/${log.timestamp.day} ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Delta Quantity: ${log.quantityDelta > 0 ? "+" : ""}${log.quantityDelta} units",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: nodeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "From: ${log.sourceLocation} ➔ To: ${log.destLocation}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Logged by: ${log.user} (SQLite Database Cached)",
                    style: const TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

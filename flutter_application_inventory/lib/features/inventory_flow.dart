import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  final MockService service;

  const InventoryScreen({super.key, required this.service});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = "";
  String _selectedCategory = "All";
  String _sortBy = "Name"; // "Name", "Quantity", "Price"
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ["All", "RF Tags & Sensors", "Machinery Parts", "Packaging Supplies", "Hardware Devices"];

  List<Product> _getFilteredProducts() {
    List<Product> list = widget.service.products.toList();

    // Search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery)).toList();
    }

    // Category filter
    if (_selectedCategory != "All") {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }

    // Sort
    if (_sortBy == "Name") {
      list.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == "Quantity") {
      list.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else if (_sortBy == "Price") {
      list.sort((a, b) => b.price.compareTo(a.price));
    }

    return list;
  }

  void _importCsvFile() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ImportFilePickerSheet(
        onImportComplete: (importedCount) {
          setState(() {
            // Seed a mock product to show import results
            widget.service.addProduct(
              Product(
                id: "IMP_${DateTime.now().millisecondsSinceEpoch}",
                name: "Imported Industrial Relay X5",
                sku: "REL-IND-X5",
                barcode: "750102030405",
                category: "Hardware Devices",
                quantity: 45,
                price: 12.80,
                location: "Aisle C, Bin 12",
                images: [],
              ),
            );
            widget.service.addNotification(
              "Import Successful",
              "Imported $importedCount items from Excel/CSV inventory template.",
              "SYSTEM",
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Inventory"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open_outlined),
            tooltip: "Import CSV/Excel",
            onPressed: _importCsvFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  decoration: InputDecoration(
                    hintText: "Search name, SKU, or scan barcode...",
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = "";
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Horizontal category chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Sorting dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Showing ${filtered.length} products",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.sort_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          items: const [
                            DropdownMenuItem(value: "Name", child: Text("Sort: Name")),
                            DropdownMenuItem(value: "Quantity", child: Text("Sort: Stock Qty")),
                            DropdownMenuItem(value: "Price", child: Text("Sort: Price")),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _sortBy = val!;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text("No products found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text("Try broadening search parameters or add a product.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isLow = p.quantity <= 5;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: EnterpriseCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(product: p, service: widget.service),
                              ),
                            ).then((value) => setState(() {}));
                          },
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product Icon/Image
                              Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "SKU: ${p.sku} | Barcode: ${p.barcode}",
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        StatusChip(label: p.category, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          "\$${p.price.toStringAsFixed(2)}",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Stock Indicators
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${p.quantity} units",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: isLow ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isLow ? "LOW STOCK" : "IN STOCK",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isLow ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ],
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
      floatingActionButton: FloatingActionButton(
        heroTag: "add_product_fab",
        child: const Icon(Icons.add_rounded),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductFormScreen(service: widget.service),
            ),
          ).then((value) => setState(() {}));
        },
      ),
    );
  }
}

// --- PRODUCT DETAILS SCREEN ---

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final MockService service;

  const ProductDetailScreen({super.key, required this.product, required this.service});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Product?"),
        content: Text("Are you sure you want to delete ${widget.product.name}? This will remove it from the local cache and flag deletion for synchronization."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              widget.service.deleteProduct(widget.product.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to inventory
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _adjustStock() {
    int qtyDelta = 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Adjust Stock Qty"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Manually adjust physical count. Enter negative to subtract."),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity Delta", hintText: "e.g. +10 or -5"),
              onChanged: (val) {
                qtyDelta = int.tryParse(val) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (qtyDelta != 0) {
                widget.service.adjustStock(widget.product.id, qtyDelta, "Manual Audit");
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.product;
    final isLow = p.quantity <= 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(service: widget.service, product: p),
                ),
              ).then((value) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
            onPressed: _deleteProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Placeholder / QR Barcode Visual
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.barcode_reader, size: 70, color: AppColors.primary),
                    const SizedBox(height: 12),
                    Text(
                      p.barcode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Product Name & Category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(label: p.category, color: AppColors.primary),
                    ],
                  ),
                ),
                Text(
                  "\$${p.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Stock Details
            Row(
              children: [
                Expanded(
                  child: EnterpriseCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Physical Stock", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          "${p.quantity} units",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isLow ? AppColors.error : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnterpriseCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Storage Site", style: TextStyle(color: Colors.grey, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          p.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Technical Specs Table
            const Text(
              "ERP Specifications Data",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _buildSpecRow("SKU Number", p.sku, isDark),
                  const Divider(height: 1),
                  _buildSpecRow("UPC Barcode", p.barcode, isDark),
                  const Divider(height: 1),
                  _buildSpecRow("Hive Status", p.isSynced ? "SYNCED" : "UNSYNCED (CACHE)", isDark, isBoldVal: true),
                  const Divider(height: 1),
                  _buildSpecRow("Authorized Role Required", "Standard Operations", isDark),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Stock Actions
            Row(
              children: [
                Expanded(
                  child: EnterpriseButton(
                    label: "Adjust Inventory",
                    icon: Icons.edit_attributes_rounded,
                    onPressed: _adjustStock,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnterpriseSecondaryButton(
                    label: "Internal Transfer",
                    icon: Icons.move_up_rounded,
                    onPressed: () {
                      // Trigger mock internal transfer popup
                      _showTransferDialog(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTransferDialog(BuildContext context) {
    String destinationLoc = "North Logistics Hub (WH-03)";
    int transferQty = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Internal Warehouse Transfer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Log destination location and quantity transfer units:"),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: destinationLoc,
              items: const [
                DropdownMenuItem(value: "Central Zone (WH-01)", child: Text("Central Zone (WH-01)")),
                DropdownMenuItem(value: "East Division (WH-02)", child: Text("East Division (WH-02)")),
                DropdownMenuItem(value: "North Logistics Hub (WH-03)", child: Text("North Logistics Hub (WH-03)")),
              ],
              onChanged: (val) => destinationLoc = val!,
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity Units to Transfer"),
              onChanged: (val) {
                transferQty = int.tryParse(val) ?? 0;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (transferQty > 0 && transferQty <= widget.product.quantity) {
                widget.service.transferStock(widget.product.id, transferQty, destinationLoc);
                setState(() {});
              }
              Navigator.pop(context);
            },
            child: const Text("Confirm Transfer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String title, String val, bool isDark, {bool isBoldVal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBoldVal ? FontWeight.w900 : FontWeight.bold,
              color: isBoldVal 
                  ? (val.startsWith("S") ? AppColors.success : AppColors.warning)
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PRODUCT ADD / EDIT FORM SCREEN (Includes Camera & Gallery Simulators) ---

class ProductFormScreen extends StatefulWidget {
  final MockService service;
  final Product? product; // If edit mode

  const ProductFormScreen({super.key, required this.service, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = "RF Tags & Sensors";
  List<String> _capturedImages = [];

  final List<String> _categories = ["RF Tags & Sensors", "Machinery Parts", "Packaging Supplies", "Hardware Devices"];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _skuController.text = p.sku;
      _barcodeController.text = p.barcode;
      _qtyController.text = p.quantity.toString();
      _priceController.text = p.price.toString();
      _locationController.text = p.location;
      _category = p.category;
      _capturedImages = List.from(p.images);
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final finalProduct = Product(
        id: widget.product?.id ?? "P_${DateTime.now().millisecondsSinceEpoch}",
        name: _nameController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        category: _category,
        quantity: int.parse(_qtyController.text),
        price: double.parse(_priceController.text),
        location: _locationController.text,
        images: _capturedImages,
        isSynced: false, // Save offline first
      );

      if (widget.product != null) {
        widget.service.updateProduct(finalProduct);
      } else {
        widget.service.addProduct(finalProduct);
      }

      Navigator.pop(context);
    }
  }

  void _openCameraSimulator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraIntegrationScreen(
          onPhotoCaptured: (photoPath) {
            setState(() {
              _capturedImages.add(photoPath);
            });
          },
        ),
      ),
    );
  }

  void _openGallerySimulator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryIntegrationScreen(
          onPhotosSelected: (photos) {
            setState(() {
              _capturedImages.addAll(photos);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Modify Stock Product" : "Catalog New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Bar
              const Text("Product Image Attachments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildUploadButton(Icons.camera_alt_rounded, "Camera", _openCameraSimulator),
                  const SizedBox(width: 12),
                  _buildUploadButton(Icons.photo_library_rounded, "Gallery", _openGallerySimulator),
                ],
              ),
              const SizedBox(height: 12),
              // Image thumbnails list
              if (_capturedImages.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(_capturedImages[idx]), // Simulating file display
                                  fit: BoxFit.cover,
                                  onError: (e, s) => {},
                                ),
                              ),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () => setState(() => _capturedImages.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const Divider(height: 32),

              EnterpriseTextField(
                labelText: "Product Nomenclature / Name",
                controller: _nameController,
                validator: (val) => val!.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: EnterpriseTextField(
                      labelText: "SKU Identifier",
                      controller: _skuController,
                      validator: (val) => val!.isEmpty ? "SKU required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EnterpriseTextField(
                      labelText: "EAN / Barcode",
                      controller: _barcodeController,
                      validator: (val) => val!.isEmpty ? "Barcode required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: "Inventory Category"),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: EnterpriseTextField(
                      labelText: "Initial Units Qty",
                      keyboardType: TextInputType.number,
                      controller: _qtyController,
                      validator: (val) => int.tryParse(val ?? "") == null ? "Must be integer" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EnterpriseTextField(
                      labelText: "Unit Price (\$)",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      controller: _priceController,
                      validator: (val) => double.tryParse(val ?? "") == null ? "Must be decimal" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EnterpriseTextField(
                labelText: "Warehouse Storage Location Bin / Shelf",
                controller: _locationController,
                validator: (val) => val!.isEmpty ? "Location needed" : null,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: EnterpriseButton(
                  label: isEdit ? "Save ERP Records" : "Commit to Cache",
                  onPressed: _saveProduct,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CAMERA INTEGRATION SIMULATOR ---

class CameraIntegrationScreen extends StatefulWidget {
  final Function(String) onPhotoCaptured;

  const CameraIntegrationScreen({super.key, required this.onPhotoCaptured});

  @override
  State<CameraIntegrationScreen> createState() => _CameraIntegrationScreenState();
}

class _CameraIntegrationScreenState extends State<CameraIntegrationScreen> {
  bool _shutterActive = false;

  void _triggerShutter() {
    setState(() => _shutterActive = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _shutterActive = false);
      // Pass back a simulated photo reference path
      final timeStr = DateTime.now().millisecondsSinceEpoch;
      widget.onPhotoCaptured("assets/mock_photo_$timeStr.png");
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Camera bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text("Device Camera Sensor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Icon(Icons.flash_off, color: Colors.white),
                ],
              ),
            ),
            // Simulated live camera viewfinder grid
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white.withValues(alpha: 0.3), size: 80),
                          const SizedBox(height: 12),
                          Text(
                            "Aim camera lens at product...",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Grid overlays
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: CustomPaint(painter: CameraGridPainter()),
                      ),
                    ),
                  ),
                  // Flash visual shutter effect
                  if (_shutterActive)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            // Camera controls bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Icon(Icons.photo_size_select_large, color: Colors.white),
                  GestureDetector(
                    onTap: _triggerShutter,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 4),
                        ),
                      ),
                    ),
                  ),
                  const Icon(Icons.switch_camera, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    // Draw 3x3 grid lines
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);

    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- GALLERY INTEGRATION SCREEN ---

class GalleryIntegrationScreen extends StatelessWidget {
  final Function(List<String>) onPhotosSelected;

  const GalleryIntegrationScreen({super.key, required this.onPhotosSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Product Photos")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withValues(alpha: 0.06),
            child: const Row(
              children: [
                Icon(Icons.crop_rotate_rounded, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Selected photos will be cropped automatically to a square 1:1 aspect ratio prior to SQLite storage compression.",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                // Mock selection
                return InkWell(
                  onTap: () {
                    // Send back selected photo path
                    onPhotosSelected(["assets/mock_gallery_${index + 1}.png"]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Center(
                      child: Icon(Icons.image_outlined, color: Colors.grey.shade600),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- IMPORT FILE PICKER SHEET ---

class ImportFilePickerSheet extends StatefulWidget {
  final Function(int) onImportComplete;

  const ImportFilePickerSheet({super.key, required this.onImportComplete});

  @override
  State<ImportFilePickerSheet> createState() => _ImportFilePickerSheetState();
}

class _ImportFilePickerSheetState extends State<ImportFilePickerSheet> {
  bool _loading = false;

  void _pickMockFile(String ext) {
    setState(() {
      _loading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      widget.onImportComplete(15); // Emulates importing 15 inventory items
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Import Product Database", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Choose a local CSV or Excel (XLSX) template file containing SKU barcode details.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 24),
          if (_loading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text("Reading Excel file structures..."),
                ],
              ),
            )
          else ...[
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.file_present_rounded, color: Colors.green),
              ),
              title: const Text("Select Excel Template (XLSX)"),
              onTap: () => _pickMockFile("xlsx"),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
                child: const Icon(Icons.insert_drive_file_outlined, color: Colors.blue),
              ),
              title: const Text("Select Flat CSV Inventory File"),
              onTap: () => _pickMockFile("csv"),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

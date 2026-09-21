import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final MockService service;
  final VoidCallback onThemeChanged;

  const ProfileScreen({
    super.key,
    required this.service,
    required this.onThemeChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedSyncFreq = "5 minutes";
  final List<String> _syncFrequencies = [
    "Manual Trigger",
    "5 minutes",
    "15 minutes",
    "1 hour",
    "Daily Sync",
  ];

  void _triggerDatabaseReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Offline Cache?"),
        content: const Text(
          "This clears all local SQLite & Hive cached data tables and reloads warehouse seed files. Any unsynced data will be wiped.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              widget.service.clearLocalCache();
              Navigator.pop(context);
            },
            child: const Text(
              "Reset Cache",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSimulatedConflict() {
    widget.service.simulateManualConflict();
  }

  void _openGeoMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeolocationMapScreen(service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("System Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.currentUser,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Role ID: ${widget.service.userRole}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "Warehouse: ${widget.service.assignedWarehouse}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              "Native Integrations & Navigation",
              style: TextStyle(
                fontSize: 14,
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
                  Icons.map_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
                title: const Text(
                  "Live GPS & Warehouse Routing Map",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: const Text(
                  "Displays vehicle routes and coordinates sync status.",
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: _openGeoMap,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Offline Synchronization Engine",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (widget.service.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            EnterpriseCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sync Freq Interval",
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(
                        width: 150,
                        height: 35,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSyncFreq,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          items: _syncFrequencies
                              .map(
                                (f) =>
                                    DropdownMenuItem(value: f, child: Text(f)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedSyncFreq = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Last Connected sync Time",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        "${widget.service.lastSyncTime.hour}:${widget.service.lastSyncTime.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (widget.service.isSyncing) ...[
                    LinearProgressIndicator(value: widget.service.syncProgress),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: EnterpriseButton(
                          label: "Trigger Sync Now",
                          icon: Icons.sync_rounded,
                          isLoading: widget.service.isSyncing,
                          onPressed: () => widget.service.syncOfflineData(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: EnterpriseSecondaryButton(
                          label: "Simulate Conflict",
                          icon: Icons.error_outline_rounded,
                          onPressed: _triggerSimulatedConflict,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (widget.service.conflicts.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sync Conflicts Alert",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.service.conflicts.length,
                itemBuilder: (context, idx) {
                  final conflict = widget.service.conflicts[idx];
                  return Card(
                    color: AppColors.error.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Conflict: ${conflict.localProduct.name}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conflict.reason,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Local: ${conflict.localProduct.quantity} units",
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                "Server: ${conflict.serverProduct.quantity} units",
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      widget.service.resolveConflict(idx, true),
                                  child: const Text("Keep Local"),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => widget.service
                                      .resolveConflict(idx, false),
                                  child: const Text("Keep Server"),
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
              const SizedBox(height: 20),
            ],

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Security & System Administration",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            EnterpriseCard(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      "Application Dark Mode",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: isDark,
                    onChanged: (val) {
                      widget.onThemeChanged();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      "Biometric Pin / Lock Enabled",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: widget.service.isBiometricEnabled,
                    onChanged: (val) {
                      setState(() {
                        widget.service.isBiometricEnabled = val;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text(
                      "Wipe Cache / Reset Database",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: const Text(
                      "Resets SQLite tables back to seed templates.",
                      style: TextStyle(fontSize: 10),
                    ),
                    trailing: const Icon(
                      Icons.delete_forever,
                      color: AppColors.error,
                    ),
                    onTap: _triggerDatabaseReset,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class GeolocationMapScreen extends StatefulWidget {
  final MockService service;

  const GeolocationMapScreen({super.key, required this.service});

  @override
  State<GeolocationMapScreen> createState() => _GeolocationMapScreenState();
}

class _GeolocationMapScreenState extends State<GeolocationMapScreen> {
  @override
  void initState() {
    super.initState();
    widget.service.simulateRouteTravel();
  }

  @override
  void dispose() {
    widget.service.isTrackingLocation = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lat = widget.service.latitude;
    final lng = widget.service.longitude;

    return Scaffold(
      appBar: AppBar(title: const Text("Live Delivery Router")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.gps_fixed_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "GPS coordinates: Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    fontFamily: "Courier",
                  ),
                ),
                const Spacer(),
                const StatusChip(
                  label: "TRACKING ACTIVE",
                  color: AppColors.success,
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: MapRoutesPainter(
                        lat: lat,
                        lng: lng,
                        isDark: isDark,
                      ),
                    ),

                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendRow(AppColors.primary, "Central WH-01"),
                            _buildLegendRow(
                              AppColors.secondary,
                              "Distribution Hub WH-02",
                            ),
                            _buildLegendRow(
                              AppColors.accent,
                              "Active Delivery Route",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mock GPS Tracking Feed",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Switch(
                      value: widget.service.isTrackingLocation,
                      onChanged: (val) {
                        setState(() {
                          widget.service.isTrackingLocation = val;
                          if (val) {
                            widget.service.simulateRouteTravel();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Simulates background SQLite spatial updates syncing location paths with logistics dispatch servers.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class MapRoutesPainter extends CustomPainter {
  final double lat;
  final double lng;
  final bool isDark;

  MapRoutesPainter({
    required this.lat,
    required this.lng,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
    final roadPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(50, 50), Offset(size.width - 50, 50), roadPaint);
    canvas.drawLine(Offset(50, 50), Offset(50, size.height - 100), roadPaint);
    canvas.drawLine(
      Offset(size.width - 50, 50),
      Offset(size.width - 50, size.height - 100),
      roadPaint,
    );
    canvas.drawLine(
      Offset(50, size.height - 100),
      Offset(size.width - 50, size.height - 100),
      roadPaint,
    );

    canvas.drawLine(
      Offset(50, 50),
      Offset(size.width - 50, size.height - 100),
      roadPaint,
    );
    final whPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final wh2Paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(50, 50), 12, whPaint);

    canvas.drawCircle(Offset(size.width - 50, size.height - 100), 12, wh2Paint);
    final double mapX = 50 + ((lat * 1000) % (size.width - 100));
    final double mapY = 50 + ((lng * 1000).abs() % (size.height - 150));

    final routePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePath = Path();
    routePath.moveTo(50, 50);
    routePath.quadraticBezierTo(size.width / 2, size.height / 3, mapX, mapY);
    canvas.drawPath(routePath, routePaint);
    final vehiclePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(mapX, mapY), 8, vehiclePaint);

    final vehicleBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(mapX, mapY), 8, vehicleBorder);
  }

  @override
  bool shouldRepaint(covariant MapRoutesPainter oldDelegate) => true;
}

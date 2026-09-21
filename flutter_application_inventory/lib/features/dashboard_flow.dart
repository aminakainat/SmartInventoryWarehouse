import 'package:flutter/material.dart';
import 'package:flutter_application_inventory/core/theme.dart';
import 'package:flutter_application_inventory/core/mock_service.dart';
import 'package:flutter_application_inventory/core/widgets/common_widgets.dart';
import 'package:flutter_application_inventory/core/widgets/custom_charts.dart';
import 'package:flutter_application_inventory/features/billing_flow.dart';
import 'package:flutter_application_inventory/features/stock_flow.dart';

class DashboardScreen extends StatelessWidget {
  final MockService service;
  final VoidCallback onNavigateToInventory;
  final VoidCallback onNavigateToScanner;
  final VoidCallback onNavigateToReports;
  final VoidCallback onNavigateToProfile;

  const DashboardScreen({
    super.key,
    required this.service,
    required this.onNavigateToInventory,
    required this.onNavigateToScanner,
    required this.onNavigateToReports,
    required this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculations based on Mock Data
    final totalProducts = service.products.length;
    final totalStockQty = service.products.fold(0, (sum, p) => sum + p.quantity);
    final totalStockValue = service.products.fold(0.0, (sum, p) => sum + (p.quantity * p.price));
    final lowStockCount = service.products.where((p) => p.quantity <= 5).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Apex Dashboard"),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 26),
                if (service.notifications.any((n) => !n.isRead))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationCenterScreen(service: service)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsDetailScreen(service: service)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectivityBanner(
            isOnline: service.isOnline,
            onToggle: () => service.isOnline = !service.isOnline,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Warehouse ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, ${service.currentUser}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            "Role: ${service.userRole} | ${service.assignedWarehouse}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      StatusChip(
                        label: service.isOnline ? "SYNCED" : "OFFLINE CACHE",
                        color: service.isOnline ? AppColors.secondary : AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mini Alerts banner if there are unsynced data or conflicts
                  if (service.conflicts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: EnterpriseCard(
                        color: AppColors.error.withValues(alpha: 0.12),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_problem_rounded, color: AppColors.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${service.conflicts.length} Sync Conflict(s) pending resolution. Tap to review.",
                                style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward, color: AppColors.error),
                              onPressed: onNavigateToProfile,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // KPI Cards Grid (Total Products, Stock Value, Low Stock Alerts, Today's Sales)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildKPICard(
                        context,
                        title: "Total SKUs",
                        value: "$totalProducts Products",
                        subtitle: "$totalStockQty Total items",
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.primary,
                      ),
                      _buildKPICard(
                        context,
                        title: "Stock Valuation",
                        value: "\$${totalStockValue.toStringAsFixed(0)}",
                        subtitle: "SQLite DB cached",
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.secondary,
                      ),
                      _buildKPICard(
                        context,
                        title: "Low Stock Alerts",
                        value: "$lowStockCount Items",
                        subtitle: "Threshold <= 5 units",
                        icon: Icons.crisis_alert_rounded,
                        color: lowStockCount > 0 ? AppColors.error : AppColors.success,
                      ),
                      _buildKPICard(
                        context,
                        title: "Today's Sales",
                        value: "\$485.50",
                        subtitle: "6 offline checkouts",
                        icon: Icons.trending_up_rounded,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Business Insights / Recommendations
                  Text(
                    "Business Insights & AI Forecasts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  EnterpriseCard(
                    child: Column(
                      children: [
                        _buildInsightRow(
                          icon: Icons.analytics_outlined,
                          title: "Predicted Low Stock Outage",
                          subtitle: "Industrial Forklift Battery XL will run out of stock in 48h based on current trends.",
                          color: AppColors.error,
                        ),
                        const Divider(height: 20),
                        _buildInsightRow(
                          icon: Icons.speed_rounded,
                          title: "Database Clean Up Recommended",
                          subtitle: "SQLite transaction files exceed 15MB. Run database maintenance in profile settings.",
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions Grid
                  Text(
                    "Quick Operations Manager",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),

                  // Charts Mini View
                  SizedBox(
                    height: 230,
                    child: EnterpriseCard(
                      child: CustomLineChart(
                        data: const [1200, 1850, 1500, 2400, 3100, 2900],
                        labels: const ["Jan", "Feb", "Mar", "Apr", "May", "Jun"],
                        title: "Revenue Forecast & Sales Trend (\$)",
                        lineColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Recent Activity Feed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Stock Activity Log",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: onNavigateToInventory,
                        child: const Text("View All Logs"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentLogs(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return EnterpriseCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.8) : AppColors.lightTextSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildActionItem(
          context,
          icon: Icons.qr_code_scanner_rounded,
          label: "Scanner",
          color: AppColors.primary,
          onTap: onNavigateToScanner,
        ),
        _buildActionItem(
          context,
          icon: Icons.shopping_cart_checkout_rounded,
          label: "Offline Bill",
          color: AppColors.secondary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BillingScreen(service: service)),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.import_export_rounded,
          label: "Transfers",
          color: AppColors.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StockManagementScreen(service: service)),
            );
          },
        ),
        _buildActionItem(
          context,
          icon: Icons.cloud_sync_rounded,
          label: "Force Sync",
          color: AppColors.success,
          onTap: () {
            service.syncOfflineData();
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogs(BuildContext context) {
    final logs = service.stockLogs.take(3).toList();
    if (logs.isEmpty) {
      return const EnterpriseCard(
        child: Center(
          child: Text("No stock movements registered."),
        ),
      );
    }
    return EnterpriseCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (context, idx) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final log = logs[idx];
          Color iconColor = AppColors.primary;
          IconData icon = Icons.swap_horiz_rounded;

          if (log.type == 'INCOMING') {
            iconColor = AppColors.success;
            icon = Icons.add_circle_outline_rounded;
          } else if (log.type == 'OUTGOING') {
            iconColor = AppColors.error;
            icon = Icons.remove_circle_outline_rounded;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.1),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              log.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              "Qty Delta: ${log.quantityDelta > 0 ? "+" : ""}${log.quantityDelta} | Location: ${log.destLocation}",
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              "${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          );
        },
      ),
    );
  }
}

// --- NOTIFICATION CENTER SCREEN ---

class NotificationCenterScreen extends StatefulWidget {
  final MockService service;

  const NotificationCenterScreen({super.key, required this.service});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = widget.service.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.service.markAllNotificationsRead();
              });
            },
            child: const Text("Read All"),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                widget.service.clearNotifications();
              });
            },
          ),
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.lightTextSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text("All caught up!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("No pending alerts from Hive or SQLite Sync Engine.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                Color badgeColor;
                IconData icon;

                switch (note.type.toUpperCase()) {
                  case 'STOCK':
                    badgeColor = AppColors.error;
                    icon = Icons.warning_amber_rounded;
                    break;
                  case 'SYNC':
                    badgeColor = AppColors.secondary;
                    icon = Icons.sync_rounded;
                    break;
                  case 'BILLING':
                    badgeColor = AppColors.primary;
                    icon = Icons.receipt_long_rounded;
                    break;
                  default:
                    badgeColor = AppColors.accent;
                    icon = Icons.system_update_alt_rounded;
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: note.isRead
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : badgeColor.withValues(alpha: 0.5),
                      width: note.isRead ? 1 : 1.5,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: badgeColor.withValues(alpha: 0.1),
                      child: Icon(icon, color: badgeColor, size: 20),
                    ),
                    title: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: note.isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(note.message, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(
                          "${note.timestamp.hour}:${note.timestamp.minute.toString().padLeft(2, '0')} - Local DB log",
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                    trailing: !note.isRead
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

// --- ANALYTICS DETAIL SCREEN ---

class AnalyticsDetailScreen extends StatelessWidget {
  final MockService service;

  const AnalyticsDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Warehouse Insights")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Performance Dashboard",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Operational efficiency and storage analysis drawn directly from SQLite database caches.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Revenue Trends Line Chart
            SizedBox(
              height: 220,
              child: EnterpriseCard(
                child: CustomLineChart(
                  data: const [1500, 2900, 1800, 3100, 4800, 4200],
                  labels: const ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
                  title: "Weekly Revenue Growth (\$)",
                  lineColor: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Warehouse Capacities Bar Chart
            SizedBox(
              height: 220,
              child: EnterpriseCard(
                child: CustomBarChart(
                  values: const [850, 420, 610, 150],
                  labels: const ["WH-1", "WH-2", "WH-3", "Store 4"],
                  title: "Stock Capacity by Storage Site (units)",
                  barColor: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Donut Category breakdown
            SizedBox(
              height: 240,
              child: EnterpriseCard(
                child: CustomDonutChart(
                  values: const [300, 150, 400, 120],
                  labels: const ["RFID Tags", "Machinery", "Boxes", "Hardware"],
                  colors: const [
                    AppColors.primary,
                    AppColors.secondary,
                    AppColors.accent,
                    AppColors.warning,
                  ],
                  title: "Category Storage Share",
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Operational insights text block
            EnterpriseCard(
              color: AppColors.primary.withValues(alpha: 0.06),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text("Critical Actionable Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Outbound shipping demand is 28% higher than current inbound stocking schedules. Warehouse transfers should be adjusted to balance inventory in East Division WH-02.",
                    style: TextStyle(fontSize: 12),
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

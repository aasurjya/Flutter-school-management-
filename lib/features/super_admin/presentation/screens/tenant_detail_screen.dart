import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';

class TenantDetailScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  ConsumerState<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends ConsumerState<TenantDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock tenant data
  final Map<String, dynamic> _tenant = {
    'id': '1',
    'name': 'Delhi Public School',
    'subdomain': 'dps',
    'email': 'admin@dps.edu',
    'phone': '+91 9876543210',
    'address': '123 Education Lane, New Delhi',
    'logo': null,
    'students': 2500,
    'teachers': 120,
    'parents': 4200,
    'admins': 15,
    'status': 'active',
    'plan': 'enterprise',
    'subscriptionStart': DateTime(2023, 6, 15),
    'subscriptionEnd': DateTime(2025, 12, 31),
    'createdAt': DateTime(2023, 6, 15),
    'lastActive': DateTime.now().subtract(const Duration(minutes: 5)),
    'monthlyRevenue': 50000.0,
    'storageUsed': 45.5, // GB
    'storageLimit': 100.0, // GB
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Text(
                                _tenant['name'].toString().substring(0, 1),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_tenant['name'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                  Text('${_tenant['subdomain']}.schoolsaas.com', style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(_tenant['status']),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _tenant['status'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'impersonate', child: Row(children: [Icon(Icons.login, size: 18), SizedBox(width: 8), Text('Login as Admin')])),
                  const PopupMenuDivider(),
                  if (_tenant['status'] == 'active')
                    const PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block, size: 18, color: AppColors.warning), SizedBox(width: 8), Text('Suspend')]))
                  else
                    const PopupMenuItem(value: 'activate', child: Row(children: [Icon(Icons.check_circle, size: 18, color: AppColors.success), SizedBox(width: 8), Text('Activate')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Users'),
                Tab(text: 'Billing'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildUsersTab(),
            _buildBillingTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(child: _StatCard(title: 'Students', value: '${_tenant['students']}', icon: Icons.school, color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(title: 'Teachers', value: '${_tenant['teachers']}', icon: Icons.person, color: AppColors.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(title: 'Parents', value: '${_tenant['parents']}', icon: Icons.family_restroom, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 16),

          // Activity Chart
          const Text('User Activity (Last 7 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Text(days[value.toInt() % 7], style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(7, (i) => BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(toY: 40 + (i * 8).toDouble(), color: AppColors.primary, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
                  )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Storage Usage
          const Text('Storage Usage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_tenant['storageUsed']} GB used', style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('${_tenant['storageLimit']} GB limit', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _tenant['storageUsed'] / _tenant['storageLimit'],
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.info),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact Info
          const Text('Contact Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(icon: Icons.email, label: 'Email', value: _tenant['email']),
                _InfoRow(icon: Icons.phone, label: 'Phone', value: _tenant['phone']),
                _InfoRow(icon: Icons.location_on, label: 'Address', value: _tenant['address']),
                _InfoRow(icon: Icons.calendar_today, label: 'Created', value: DateFormat('MMM d, yyyy').format(_tenant['createdAt'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _UserTypeCard(title: 'Administrators', count: _tenant['admins'], icon: Icons.admin_panel_settings, color: AppColors.error),
        _UserTypeCard(title: 'Teachers', count: _tenant['teachers'], icon: Icons.school, color: AppColors.secondary),
        _UserTypeCard(title: 'Students', count: _tenant['students'], icon: Icons.people, color: AppColors.primary),
        _UserTypeCard(title: 'Parents', count: _tenant['parents'], icon: Icons.family_restroom, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text('Recent Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(5, (i) => ListTile(
          leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), child: Text('U${i + 1}')),
          title: Text('User ${i + 1}'),
          subtitle: Text(i % 2 == 0 ? 'Teacher' : 'Admin'),
          trailing: Text('Active ${i + 1}h ago', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        )),
      ],
    );
  }

  Widget _buildBillingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Current Plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text(_tenant['plan'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(icon: Icons.calendar_today, label: 'Started', value: DateFormat('MMM d, yyyy').format(_tenant['subscriptionStart'])),
                _InfoRow(icon: Icons.event, label: 'Expires', value: DateFormat('MMM d, yyyy').format(_tenant['subscriptionEnd'])),
                _InfoRow(icon: Icons.payments, label: 'Monthly', value: '₹${_tenant['monthlyRevenue'].toStringAsFixed(0)}'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(onPressed: () {}, child: const Text('Change Plan')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Extend'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ...List.generate(5, (i) => GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Subscription', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(DateFormat('MMM d, yyyy').format(DateTime.now().subtract(Duration(days: 30 * i))), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Text('₹${_tenant['monthlyRevenue'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tenant Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Allow Student Registration'),
          subtitle: const Text('Students can self-register'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Enable Parent Portal'),
          subtitle: const Text('Parents can access the portal'),
          value: true,
          onChanged: (v) {},
        ),
        SwitchListTile(
          title: const Text('Email Notifications'),
          subtitle: const Text('Send email notifications'),
          value: true,
          onChanged: (v) {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Backup Data'),
          subtitle: const Text('Last backup: Today, 3:00 AM'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Export Data'),
          subtitle: const Text('Download all tenant data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: const Text('Delete Tenant', style: TextStyle(color: AppColors.error)),
          subtitle: const Text('Permanently delete all data'),
          onTap: () => _handleAction('delete'),
        ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'suspend':
        _showConfirmDialog('Suspend Tenant', 'Are you sure you want to suspend this tenant?', AppColors.warning, () {
          setState(() => _tenant['status'] = 'suspended');
        });
        break;
      case 'activate':
        setState(() => _tenant['status'] = 'active');
        context.showSuccessSnackBar('Tenant activated');
        break;
      case 'delete':
        _showConfirmDialog('Delete Tenant', 'This will permanently delete all data. This action cannot be undone.', AppColors.error, () {
          Navigator.pop(context);
        });
        break;
      case 'impersonate':
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logging in as tenant admin...')));
        break;
    }
  }

  void _showConfirmDialog(String title, String message, Color color, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: color),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return AppColors.success;
      case 'trial': return AppColors.warning;
      case 'suspended': return AppColors.error;
      default: return Colors.grey;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _UserTypeCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _UserTypeCard({required this.title, required this.count, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

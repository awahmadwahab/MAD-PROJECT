import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/offline_vault_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentOfflineVaultScreen extends StatefulWidget {
  const StudentOfflineVaultScreen({super.key});

  @override
  State<StudentOfflineVaultScreen> createState() =>
      _StudentOfflineVaultScreenState();
}

class _StudentOfflineVaultScreenState extends State<StudentOfflineVaultScreen> {
  bool _syncing = false;

  Future<void> _syncNow() async {
    if (_syncing) {
      return;
    }

    setState(() => _syncing = true);
    try {
      final synced = await context.read<AppState>().syncOfflineVaultNow();
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced > 0
                ? '$synced pending record(s) synced successfully.'
                : 'No pending records to sync right now.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _clearSynced() async {
    await OfflineVaultService.removeSyncedRecords();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synced vault records cleared.')),
    );
  }

  Future<void> _clearAll() async {
    await OfflineVaultService.clearVault();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline Vault cleared.')),
    );
  }

  String _formatDate(String? rawIso) {
    if (rawIso == null || rawIso.isEmpty) {
      return 'Unknown time';
    }

    try {
      final dt = DateTime.parse(rawIso).toLocal();
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}-$mm-$dd $hh:$min';
    } catch (_) {
      return rawIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/student/home'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Vault',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Stored attendance waiting for sync',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: OfflineVaultService.getAllRecords(),
                    builder: (context, snapshot) {
                      final records = snapshot.data ?? <Map<String, dynamic>>[];
                      final pending = records
                          .where((r) => r['synced'] != true)
                          .toList();
                      final synced = records.length - pending.length;

                      final sorted = [...records]..sort((a, b) {
                          final first = a['scannedAt']?.toString() ?? '';
                          final second = b['scannedAt']?.toString() ?? '';
                          return second.compareTo(first);
                        });

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Pending',
                                  value: '${pending.length}',
                                  color: AppColors.warning,
                                  icon: Icons.cloud_off_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Synced',
                                  value: '$synced',
                                  color: AppColors.success,
                                  icon: Icons.cloud_done_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryCard(
                                  label: 'Total',
                                  value: '${records.length}',
                                  color: AppColors.accent,
                                  icon: Icons.storage_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GradientButton(
                                  label: _syncing ? 'Syncing...' : 'Sync Now',
                                  icon: Icons.sync_rounded,
                                  loading: _syncing,
                                  onPressed: _syncNow,
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed:
                                    records.isEmpty ? null : _clearSynced,
                                child: const Text('Clear Synced'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed:
                                    records.isEmpty ? null : _clearAll,
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: sorted.isEmpty
                                ? GlassCard(
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inbox_rounded,
                                            size: 44,
                                            color: AppColors.textMuted
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'Offline Vault is empty',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: sorted.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final record = sorted[index];
                                      final isSynced = record['synced'] == true;
                                      final color = isSynced
                                          ? AppColors.success
                                          : AppColors.warning;
                                      final icon = isSynced
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_upload_rounded;
                                      return GlassCard(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                icon,
                                                color: color,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${record['courseCode'] ?? ''} - ${record['studentId'] ?? ''}',
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Scanned: ${_formatDate(record['scannedAt']?.toString())}',
                                                    style: const TextStyle(
                                                      color: AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (!isSynced)
                                                    Text(
                                                      'Queued: ${_formatDate(record['queuedAt']?.toString())}',
                                                      style: const TextStyle(
                                                        color: AppColors.textMuted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              isSynced ? 'Synced' : 'Pending',
                                              style: TextStyle(
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

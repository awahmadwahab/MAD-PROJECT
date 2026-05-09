import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campuscan/core/app_state.dart';
import 'package:campuscan/core/offline_vault_service.dart';
import 'package:campuscan/core/theme.dart';
import 'package:campuscan/shared/widgets.dart';

class StudentVaultScreen extends StatefulWidget {
  const StudentVaultScreen({super.key});

  @override
  State<StudentVaultScreen> createState() => _StudentVaultScreenState();
}

class _StudentVaultScreenState extends State<StudentVaultScreen> {
  bool _isSyncing = false;

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    final count = await context.read<AppState>().syncOfflineVaultNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(count > 0 ? 'Successfully synced $count records!' : 'No records to sync or still offline.')),
      );
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticlesBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline Vault',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Pending sync records',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _isSyncing ? null : _handleManualSync,
                      icon: _isSyncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, color: AppColors.accent),
                      style: IconButton.styleFrom(backgroundColor: AppColors.surfaceLight),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: OfflineVaultService.getAllRecords(),
                    builder: (context, snapshot) {
                      final records = snapshot.data ?? [];

                      if (records.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_done_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              const Text('Vault is empty', style: TextStyle(color: AppColors.textMuted)),
                              const Text('All records are synced!', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final r = records[index];
                          final bool isSynced = r['synced'] == true;

                          return GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isSynced ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                    color: isSynced ? AppColors.success : AppColors.warning,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r['courseCode'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        r['scannedAt'].toString().split('T').first,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  isSynced ? 'SYNCED' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSynced ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Sync All Now',
                    icon: Icons.cloud_upload_rounded,
                    onPressed: _handleManualSync,
                    loading: _isSyncing,
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

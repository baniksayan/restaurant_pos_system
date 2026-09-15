import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos_system/core/constants/app_colors.dart';
import 'package:restaurant_pos_system/core/utils/haptic_helper.dart';
import 'package:restaurant_pos_system/features/chef/models/chef_order_model.dart';
import 'package:restaurant_pos_system/features/orders/providers/ready_to_collect_provider.dart';
import 'package:restaurant_pos_system/shared/widgets/layout/skeleton_loader.dart';

/// Waiter-facing screen that lists all kitchen orders marked "Ready to Serve"
/// (KOT status 3) — i.e. food that has been prepared and is sitting on the
/// kitchen pass waiting to be collected and delivered to the guest's table.
class ReadyToCollectOrdersView extends StatefulWidget {
  const ReadyToCollectOrdersView({super.key});

  @override
  State<ReadyToCollectOrdersView> createState() =>
      _ReadyToCollectOrdersViewState();
}

class _ReadyToCollectOrdersViewState extends State<ReadyToCollectOrdersView> {
  // Confirmation guard: prevent double-tap on the Collected button
  final Set<String> _confirming = {};

  @override
  void initState() {
    super.initState();
    // Refresh on open so the list is always fresh when the waiter opens it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReadyToCollectProvider>().fetchReadyOrders();
    });
  }

  Future<void> _refresh() =>
      context.read<ReadyToCollectProvider>().fetchReadyOrders();

  Future<void> _onMarkCollected(
      BuildContext ctx, ReadyToCollectProvider provider, ChefOrder order) async {
    if (_confirming.contains(order.id)) return;
    setState(() => _confirming.add(order.id));

    await HapticHelper.triggerFeedback();

    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierColor: Colors.black26,
      builder: (dialogCtx) => _CollectConfirmDialog(kotNo: order.kotNo),
    );

    if (!mounted) return;
    setState(() => _confirming.remove(order.id));

    if (confirmed == true) {
      provider.markAsCollected(order.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ready to Collect'),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<ReadyToCollectProvider>(
            builder: (_, provider, __) => IconButton(
              onPressed: provider.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ReadyToCollectProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                if (!provider.isLoading &&
                    provider.error == null &&
                    provider.readyOrders.isNotEmpty)
                  _SummaryBar(
                    orderCount: provider.readyCount,
                    itemCount: provider.totalItemCount,
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.success,
                    child: _buildBody(context, provider),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, ReadyToCollectProvider provider) {
    if (provider.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonLoader.rectangular(
            width: double.infinity,
            height: 130,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      );
    }

    if (provider.error != null) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load',
        detail: provider.error!,
        tone: AppColors.error,
      );
    }

    if (provider.readyOrders.isEmpty) {
      return const _EmptyState(
        icon: Icons.soup_kitchen_rounded,
        title: 'Kitchen queue is clear',
        detail:
            'No prepared orders are waiting to be collected.\nPull down to refresh.',
        tone: AppColors.success,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: provider.readyOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final order = provider.readyOrders[i];
        return _OrderCard(
          order: order,
          isConfirming: _confirming.contains(order.id),
          onMarkCollected: () => _onMarkCollected(ctx, provider, order),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Summary bar
// ──────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final int orderCount;
  final int itemCount;

  const _SummaryBar({required this.orderCount, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.success.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.room_service_rounded,
              size: 17, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            '$orderCount order${orderCount == 1 ? '' : 's'} ready to collect',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$itemCount item${itemCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Order card
// ──────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final ChefOrder order;
  final bool isConfirming;
  final VoidCallback onMarkCollected;

  const _OrderCard({
    required this.order,
    required this.isConfirming,
    required this.onMarkCollected,
  });

  @override
  Widget build(BuildContext context) {
    // Elapsed time since the kitchen marked this ready
    final elapsed = DateTime.now().difference(order.completedTime ?? order.orderTime);
    final elapsedLabel = elapsed.inMinutes < 1
        ? 'Just now'
        : elapsed.inMinutes < 60
            ? '${elapsed.inMinutes} min ago'
            : '${elapsed.inHours} hr ago';

    // Urgency colour: green < 10 min, amber 10-20, red > 20
    final urgencyColor = elapsed.inMinutes < 10
        ? AppColors.success
        : elapsed.inMinutes < 20
            ? AppColors.warning
            : AppColors.error;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  // KOT number
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            order.kotNo.startsWith('#') ||
                                    order.kotNo.startsWith('KOT')
                                ? order.kotNo
                                : '#${order.kotNo}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Table badge
                        Flexible(
                          flex: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.tableNumber.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Elapsed time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_rounded,
                            size: 11, color: urgencyColor),
                        const SizedBox(width: 3),
                        Text(
                          elapsedLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Items ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: order.items.map((item) {
                  final hasNote = (item.specialInstructions ?? '').trim().isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Qty pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${item.quantity}×',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              if (hasNote) ...[
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                        color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_note_rounded,
                                          size: 11,
                                          color: Color(0xFFD97706)),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          item.specialInstructions!,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Action button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isConfirming ? null : onMarkCollected,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text(
                    'COLLECTED & SERVED',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Confirmation dialog
// ──────────────────────────────────────────────────────────────────────────────

class _CollectConfirmDialog extends StatelessWidget {
  final String kotNo;

  const _CollectConfirmDialog({required this.kotNo});

  @override
  Widget build(BuildContext context) {
    final display = kotNo.startsWith('#') || kotNo.startsWith('KOT')
        ? kotNo
        : '#$kotNo';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.room_service_rounded,
                color: AppColors.success, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            'Collected $display?',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Confirm you have collected this order\nfrom the kitchen and delivered it to the table.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Yes, Collected',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Empty / error state
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final Color tone;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.detail,
    this.tone = AppColors.textHint,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 80),
      children: [
        Icon(icon, size: 52, color: tone.withValues(alpha: 0.7)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

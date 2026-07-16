import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickfix_provider/core/theme/app_colors.dart';
import 'package:quickfix_provider/core/theme/app_text_styles.dart';
import 'package:quickfix_provider/core/utils/currency_formatter.dart';
import 'package:quickfix_provider/core/utils/date_formatter.dart';
import 'package:quickfix_provider/features/auth/presentation/controllers/auth_provider.dart';
import 'package:quickfix_provider/features/shop/presentation/controllers/payments_provider.dart';
import 'package:quickfix_provider/core/widgets/error_widgets.dart';
import 'package:quickfix_provider/core/network/connectivity_provider.dart';
import 'package:quickfix_provider/features/payments/presentation/widgets/withdrawal_dialog.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 1) {
          ref.read(paymentsProvider.notifier).fetchSettlementHistory();
        } else if (_tabController.index == 2) {
          ref.read(paymentsProvider.notifier).fetchLedger();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showWithdrawalDialog(
    BuildContext context,
    WidgetRef ref,
    double maxAmount,
  ) {
    showDialog(
      context: context,
      builder: (context) => WithdrawalDialog(maxAmount: maxAmount, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);
    final shop = ref.watch(authProvider.select((state) => state.shop));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<bool>>(connectivityProvider, (previous, next) {
      if (next.value == true &&
          previous?.value == false &&
          paymentsState.errorMessage != null) {
        ref.read(paymentsProvider.notifier).fetchEarnings();
      }
    });

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Earnings & Payments'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(paymentsProvider.notifier).fetchEarnings(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance_wallet_outlined, size: 18),
              text: 'Overview',
            ),
            Tab(icon: Icon(Icons.swap_horiz, size: 18), text: 'Settlements'),
            Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 18),
              text: 'Ledger',
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async =>
            ref.read(paymentsProvider.notifier).fetchEarnings(),
        child:
            paymentsState.errorMessage != null &&
                !paymentsState.hasDashboardData
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - 200,
                  alignment: Alignment.center,
                  child: CommonErrorWidget(
                    message: paymentsState.errorMessage!,
                    onRetry: () =>
                        ref.read(paymentsProvider.notifier).fetchEarnings(),
                  ),
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context, paymentsState, shop, isDark),
                  _buildSettlementsTab(context, paymentsState, isDark),
                  _buildLedgerTab(context, paymentsState, isDark),
                ],
              ),
      ),
    );
  }

  // ─── Overview Tab ─────────────────────────────────────────────────────────

  Widget _buildOverviewTab(
    BuildContext context,
    PaymentsState state,
    dynamic shop,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Commission Due Warning Banner
          if (state.commissionDue > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commission Outstanding',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${state.commissionDue.toStringAsFixed(2)} platform commission is due from cash jobs. Please settle with admin.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Wallet Balance Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.plusGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'AVAILABLE WALLET BALANCE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.formatDouble(state.walletBalance),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: state.walletBalance < 0
                        ? Colors.redAccent
                        : Colors.white,
                    fontFamily: 'Outfit',
                  ),
                ),
                if (state.walletBalance < 0) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Negative balance = Commission owed to platform',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: state.walletBalance <= 0
                      ? null
                      : () => _showWithdrawalDialog(
                          context,
                          ref,
                          state.walletBalance,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.account_balance_outlined, size: 16),
                  label: const Text(
                    'Request Settlement',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Today's Earnings Grid
          if (state.hasDashboardData) ...[
            _sectionLabel('TODAY\'S SUMMARY', isDark),
            const SizedBox(height: 10),
            _earningsGrid(state, isDark),
            const SizedBox(height: 16),

            _sectionLabel('OVERALL STATS', isDark),
            const SizedBox(height: 10),
            _overallStats(state, isDark),
            const SizedBox(height: 16),
          ],

          // Commission Info Box
          _commissionInfoBox(state, isDark),
          const SizedBox(height: 16),

          // Bank Account
          if (shop != null) ...[
            _sectionLabel('SETTLEMENT BANK ACCOUNT', isDark),
            const SizedBox(height: 10),
            _bankAccountCard(shop, isDark),
            const SizedBox(height: 20),
          ],

          // Transaction History
          _sectionLabel('TRANSACTION HISTORY', isDark),
          const SizedBox(height: 10),
          if (state.transactions.isEmpty)
            _emptyCard('No transactions yet', Icons.history, isDark)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tx = state.transactions[index] as Map<String, dynamic>;
                final isCredit = tx['type'] == 'credit';
                final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                return _txCard(tx, isCredit, amount, isDark);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _earningsGrid(PaymentsState s, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _miniStatCard(
          'Today\'s Earnings',
          s.todayEarnings,
          AppColors.success,
          Icons.trending_up,
          isDark,
        ),
        _miniStatCard(
          'Cash Collected',
          s.todayCash,
          Colors.orange,
          Icons.money,
          isDark,
        ),
        _miniStatCard(
          'Online Earnings',
          s.todayOnline,
          AppColors.primary,
          Icons.credit_card,
          isDark,
        ),
        _miniStatCard(
          'Commission Deducted',
          s.todayCommission,
          Colors.redAccent,
          Icons.percent,
          isDark,
        ),
      ],
    );
  }

  Widget _overallStats(PaymentsState s, bool isDark) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          _statRow(
            'Total Earnings',
            '₹${s.totalEarnings.toStringAsFixed(2)}',
            AppColors.success,
          ),
          _statRow(
            'Total Commission Paid',
            '₹${s.totalCommission.toStringAsFixed(2)}',
            Colors.orange,
          ),
          if (s.commissionDue > 0)
            _statRow(
              'Commission Outstanding',
              '₹${s.commissionDue.toStringAsFixed(2)}',
              Colors.red,
            ),
          _statRow('Cash Jobs', '${s.cashJobsCount} bookings', Colors.orange),
          _statRow(
            'Online Jobs',
            '${s.onlineJobsCount} bookings',
            AppColors.primary,
          ),
          _statRow(
            'Total Settled',
            '₹${s.totalSettled.toStringAsFixed(2)}',
            AppColors.success,
          ),
          _statRow(
            'Completed Settlements',
            '${s.completedSettlementCount}',
            AppColors.success,
          ),
          if (s.pendingSettlementCount > 0)
            _statRow(
              'Pending Settlement',
              '₹${s.pendingSettlementAmount.toStringAsFixed(2)} (${s.pendingSettlementCount})',
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(
    String label,
    double value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commissionInfoBox(
    PaymentsState state,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commission Rate: ${state.commissionRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For online payments: ${state.commissionRate.toStringAsFixed(0)}% is auto-deducted and earnings credited to your wallet.\nFor cash payments: You collect full amount from customer and owe ${state.commissionRate.toStringAsFixed(0)}% commission to the platform.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankAccountCard(dynamic shop, bool isDark) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_rounded,
            color: Colors.teal,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.bankAccountNumber.isNotEmpty
                      ? 'A/C: *******${shop.bankAccountNumber.substring(shop.bankAccountNumber.length.clamp(4, shop.bankAccountNumber.length) - 4)}'
                      : 'No bank account added',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shop.ifscCode.isNotEmpty
                      ? 'IFSC: ${shop.ifscCode}${shop.upiId.isNotEmpty ? "  •  UPI: ${shop.upiId}" : ""}'
                      : 'Update details in your profile',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _txCard(
    Map<String, dynamic> tx,
    bool isCredit,
    double amount,
    bool isDark,
  ) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : Colors.redAccent)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? AppColors.success : Colors.redAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title']?.toString() ?? 'Transaction',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tx['date'] != null
                      ? DateFormatter.formatIsoString(tx['date'].toString())
                      : 'Just now',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? "+" : "-"}${CurrencyFormatter.formatDouble(amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isCredit ? AppColors.success : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Settlements Tab ───────────────────────────────────────────────────────

  Widget _buildSettlementsTab(
    BuildContext context,
    PaymentsState state,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _settleSummaryItem(
                  'Total Settled',
                  '₹${state.totalSettled.toStringAsFixed(0)}',
                  AppColors.success,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _settleSummaryItem(
                  'Pending',
                  '₹${state.pendingSettlementAmount.toStringAsFixed(0)}',
                  Colors.orange,
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                _settleSummaryItem(
                  'Balance',
                  '₹${state.walletBalance.toStringAsFixed(0)}',
                  state.walletBalance >= 0 ? AppColors.success : Colors.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Request New Settlement Button
          ElevatedButton.icon(
            onPressed: state.walletBalance <= 0
                ? null
                : () =>
                      _showWithdrawalDialog(context, ref, state.walletBalance),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.send_to_mobile),
            label: const Text(
              'Request New Settlement',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),

          _sectionLabel('SETTLEMENT HISTORY', isDark),
          const SizedBox(height: 10),

          if (state.settlementHistory.isEmpty)
            FutureBuilder(
              future: ref
                  .read(paymentsProvider.notifier)
                  .fetchSettlementHistory(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ref.read(paymentsProvider).settlementHistory.isEmpty) {
                  return _emptyCard(
                    'No settlement history yet.\nRequest your first settlement above!',
                    Icons.swap_horiz,
                    isDark,
                  );
                }
                return _settlementList(
                  ref.read(paymentsProvider).settlementHistory,
                  isDark,
                );
              },
            )
          else
            _settlementList(state.settlementHistory, isDark),
        ],
      ),
    );
  }

  Widget _settleSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
      ],
    );
  }

  Widget _settlementList(List<dynamic> settlements, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: settlements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final s = settlements[index] as Map<String, dynamic>;
        final status = s['status']?.toString() ?? 'pending';
        final amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
        final statusColor = _settlementStatusColor(status);
        final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${s['id'] ?? '—'}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              if (s['requestedAt'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Requested: ${DateFormatter.formatIsoString(s['requestedAt'].toString())}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
              if (s['completedAt'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Completed: ${DateFormatter.formatIsoString(s['completedAt'].toString())}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                ),
              ],
              if (s['transactionId'] != null &&
                  s['transactionId'].toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Txn ID: ${s['transactionId']}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (s['adminNote'] != null &&
                  s['adminNote'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Note: ${s['adminNote']}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _settlementStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'approved':
        return AppColors.primary;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ─── Ledger Tab ────────────────────────────────────────────────────────────

  Widget _buildLedgerTab(
    BuildContext context,
    PaymentsState state,
    bool isDark,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Each completed booking generates an accounting entry showing gross amount, platform commission, and your net earnings.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _sectionLabel('BOOKING LEDGER', isDark),
          const SizedBox(height: 10),

          if (state.ledgerEntries.isEmpty)
            FutureBuilder(
              future: ref.read(paymentsProvider.notifier).fetchLedger(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final entries = ref.read(paymentsProvider).ledgerEntries;
                if (entries.isEmpty) {
                  return _emptyCard(
                    'No ledger entries yet.\nComplete a booking to see accounting records.',
                    Icons.receipt_long_outlined,
                    isDark,
                  );
                }
                return _ledgerList(entries, isDark);
              },
            )
          else
            _ledgerList(state.ledgerEntries, isDark),
        ],
      ),
    );
  }

  Widget _ledgerList(List<dynamic> entries, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final e = entries[index] as Map<String, dynamic>;
        final gross = (e['grossAmount'] as num?)?.toDouble() ?? 0.0;
        final commission = (e['commissionAmount'] as num?)?.toDouble() ?? 0.0;
        final earnings = (e['providerEarnings'] as num?)?.toDouble() ?? 0.0;
        final commRate = (e['commissionRate'] as num?)?.toDouble() ?? 20.0;
        final method = e['paymentMethod']?.toString() ?? 'cash';
        final payStatus = e['paymentStatus']?.toString() ?? 'pending';
        final commStatus = e['commissionStatus']?.toString() ?? 'pending';
        final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        final border = isDark ? AppColors.borderDark : AppColors.borderLight;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      e['serviceTitle']?.toString() ?? 'Booking',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _methodChip(method),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Booking: ${e['bookingId']?.toString() ?? '—'}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              if (e['createdAt'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormatter.formatIsoString(e['createdAt'].toString()),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
              const SizedBox(height: 12),

              // Accounting breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _ledgerRow(
                      'Gross Billing Amount',
                      '₹${gross.toStringAsFixed(2)}',
                      Colors.white,
                    ),
                    _ledgerRow(
                      'Platform Commission (${commRate.toStringAsFixed(0)}%)',
                      '- ₹${commission.toStringAsFixed(2)}',
                      Colors.orange,
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    _ledgerRow(
                      'Your Net Earnings',
                      '₹${earnings.toStringAsFixed(2)}',
                      AppColors.success,
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Status row
              Row(
                children: [
                  _statusChip(
                    _payStatusLabel(payStatus),
                    _payStatusColor(payStatus),
                  ),
                  const SizedBox(width: 8),
                  _statusChip(
                    'Comm: ${commStatus.toUpperCase()}',
                    commStatus == 'paid' ? AppColors.success : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ledgerRow(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 14 : 12,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String method) {
    final map = {
      'cash': [Colors.orange, '💵 CASH'],
      'online': [AppColors.success, '💳 ONLINE'],
      'wallet': [AppColors.primary, '👛 WALLET'],
      'upi': [Colors.purple, '📱 UPI'],
    };
    final config = map[method] ?? [Colors.grey, method.toUpperCase()];
    final color = config[0] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        config[1] as String,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _payStatusLabel(String status) {
    const map = {
      'cash_pending': '💵 CASH PENDING',
      'cash_collected': '✅ CASH COLLECTED',
      'paid': '💳 PAID',
      'settlement_pending': '⏳ SETTLEMENT PENDING',
      'settled': '✅ SETTLED',
      'pending': '⏳ PENDING',
    };
    return map[status] ?? status.toUpperCase();
  }

  Color _payStatusColor(String status) {
    switch (status) {
      case 'settled':
      case 'paid':
      case 'cash_collected':
        return AppColors.success;
      case 'settlement_pending':
      case 'cash_pending':
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ─── Shared Helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: AppTextStyles.headingSmall(isDark).copyWith(
        color: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _emptyCard(String message, IconData icon, bool isDark) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



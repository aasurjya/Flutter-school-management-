import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/copy/warm_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/academic.dart';
import '../../../../data/models/invoice.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../fees/providers/fees_provider.dart';
import '../../../fees/utils/fee_statement_pdf_builder.dart';
import '../../../fees/utils/fees_pdf_builder.dart';
import '../../../fees/utils/payment_receipt_pdf_builder.dart';
import '../../../id_card/providers/id_card_provider.dart';

/// Admin Fees screen — overview, fee structure, pending.
///
/// Rewritten 2026-05-25 to replace 5 "coming soon" stubs and the
/// hardcoded mock recent-transactions list with real backend calls and
/// PDF print/share flows (receipt, statement, defaulter list).
class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() =>
      _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(feesNotifierProvider.notifier).loadInvoices();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
            tooltip: 'Export collection report',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fee Structure'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildFeeStructure(),
          _buildPendingPayments(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Overview
  // ---------------------------------------------------------------------------

  Widget _buildOverview() {
    final statsAsync = ref.watch(feeCollectionStatsProvider(null));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(feeCollectionStatsProvider);
        ref.invalidate(recentPaymentsProvider);
      },
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
          onRetry: () => ref.invalidate(feeCollectionStatsProvider),
        ),
        data: (stats) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Collected',
                    value: '₹${_formatAmount(stats['total_paid'] ?? 0)}',
                    icon: Icons.account_balance_wallet,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Pending',
                    value: '₹${_formatAmount(stats['total_pending'] ?? 0)}',
                    icon: Icons.pending_actions,
                    color: AppColors.warning,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Total Fee',
                    value: '₹${_formatAmount(stats['total_fee'] ?? 0)}',
                    icon: Icons.account_balance,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Collection Rate',
                    value:
                        '${(stats['collection_percentage'] ?? 0).toStringAsFixed(1)}%',
                    icon: Icons.trending_up,
                    color: AppColors.info,
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              const Text('Quick Actions',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionButton(
                    icon: Icons.receipt_long,
                    label: 'Generate Invoices',
                    onTap: _generateInvoices,
                  ),
                  _ActionButton(
                    icon: Icons.notifications,
                    label: 'Send Reminders',
                    onTap: _sendReminders,
                  ),
                  _ActionButton(
                    icon: Icons.add_card,
                    label: 'Record Payment',
                    onTap: () => _recordPaymentForInvoice(null),
                  ),
                  _ActionButton(
                    icon: Icons.discount,
                    label: 'Apply Discount',
                    onTap: _applyDiscount,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Recent Transactions',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _RecentTransactions(onTapPrint: _printReceiptForPayment),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fee Structure
  // ---------------------------------------------------------------------------

  Widget _buildFeeStructure() {
    final feeHeadsAsync = ref.watch(feeHeadsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(feeHeadsProvider),
      child: feeHeadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _ErrorRetry(onRetry: () => ref.invalidate(feeHeadsProvider)),
        data: (feeHeads) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Fee Heads',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
              ElevatedButton.icon(
                onPressed: _addFeeHead,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Head'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
              ),
            ]),
            const SizedBox(height: 16),
            if (feeHeads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No fee heads yet. Add one to get started.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...feeHeads.map((fh) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(fh.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ),
                          if (fh.code != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(fh.code!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primary)),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            tooltip: 'Edit fee head',
                            onPressed: () => _editFeeHead(fh),
                          ),
                        ]),
                        if (fh.description != null)
                          Text(fh.description!,
                              style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        if (fh.isRecurring)
                          _buildFeeChip('Recurring', color: AppColors.info),
                      ],
                    ),
                  )),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Fee Structure'),
                onPressed: _addFeeStructure,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeChip(String label, {Color color = AppColors.primary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  // ---------------------------------------------------------------------------
  // Pending
  // ---------------------------------------------------------------------------

  Widget _buildPendingPayments() {
    final invoicesAsync = ref.watch(overdueInvoicesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(overdueInvoicesProvider),
      child: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorRetry(
            onRetry: () => ref.invalidate(overdueInvoicesProvider)),
        data: (invoices) {
          if (invoices.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 96),
              children: const [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Center(
                    child: Text('No overdue payments.',
                        style: TextStyle(fontSize: 16))),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length + 1, // +1 for export footer
            itemBuilder: (context, index) {
              if (index == invoices.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Defaulter Report (PDF)'),
                    onPressed: () => _exportDefaulters(invoices),
                  ),
                );
              }
              final invoice = invoices[index];
              final dueDate = invoice.dueDate;
              final isOverdue = dueDate.isBefore(DateTime.now());
              final pendingAmount = invoice.totalAmount -
                  invoice.discountAmount -
                  invoice.paidAmount;

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.studentName ?? 'Unknown Student',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            Text('Invoice: ${invoice.invoiceNumber}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${pendingAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? AppColors.error
                                      .withValues(alpha: 0.1)
                                  : AppColors.warning
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOverdue
                                  ? 'Overdue'
                                  : 'Due ${DateFormat('MMM d').format(dueDate)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _remindOne(invoice),
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Remind'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _printStatementForStudent(invoice.studentId),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('Statement'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _recordPaymentForInvoice(invoice),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white),
                          child: const Text('Pay'),
                        ),
                      ),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action handlers — all REAL backend calls.
  // ---------------------------------------------------------------------------

  /// Generate invoices for a class via the `generate_class_invoices` RPC.
  /// Bottom sheet asks for class, academic year and due date.
  Future<void> _generateInvoices() async {
    final result = await showModalBottomSheet<_GenerateInvoiceParams>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GenerateInvoiceSheet(),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating invoices...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final count = await ref
          .read(feesNotifierProvider.notifier)
          .generateClassInvoices(
            classId: result.classId,
            academicYearId: result.academicYearId,
            termId: result.termId,
            dueDate: result.dueDate,
          );
      ref
        ..invalidate(feeCollectionStatsProvider)
        ..invalidate(overdueInvoicesProvider);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showSuccessSnackBar('$count invoices generated.');
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not generate invoices. ${_short(e)}');
    }
  }

  /// Send reminder to every overdue invoice. Idempotent — the RPC tags
  /// the log so re-sends within a short window are surfaced separately.
  Future<void> _sendReminders() async {
    final invoices = ref.read(overdueInvoicesProvider).value ?? const [];
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No overdue invoices to remind.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Send reminders?'),
        content: Text(
          'Send a payment reminder for ${invoices.length} overdue invoice(s)?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Sending reminders…'), duration: Duration(seconds: 2)));

    final repo = ref.read(feeRepositoryProvider);
    int sent = 0;
    int failed = 0;
    for (final inv in invoices) {
      try {
        final pending =
            inv.totalAmount - inv.discountAmount - inv.paidAmount;
        await repo.logReminderSent(
          invoiceId: inv.id,
          studentId: inv.studentId,
          messageText:
              'Reminder: Invoice ${inv.invoiceNumber} of ₹${pending.toStringAsFixed(0)} is overdue. Please pay at your earliest.',
          riskScore: _overdueRisk(inv),
        );
        sent++;
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    context.showSuccessSnackBar(
      'Reminders: $sent sent${failed > 0 ? ' · $failed failed' : ''}.',
    );
  }

  /// Record a payment. If [invoice] is null, the sheet lets admin pick
  /// from the overdue list. After a successful save the admin is offered
  /// a receipt PDF.
  Future<void> _recordPaymentForInvoice(Invoice? invoice) async {
    final result = await showModalBottomSheet<_RecordPaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordPaymentSheet(prefillInvoice: invoice),
    );
    if (result == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Recording payment…'),
        duration: Duration(seconds: 2)));
    try {
      final payment = await ref
          .read(feesNotifierProvider.notifier)
          .recordPayment(
            invoiceId: result.invoiceId,
            amount: result.amount,
            paymentMethod: result.method,
            transactionId: result.transactionId,
            remarks: result.remarks,
          );
      ref
        ..invalidate(feeCollectionStatsProvider)
        ..invalidate(overdueInvoicesProvider)
        ..invalidate(recentPaymentsProvider);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      _offerReceiptPdf(payment.id, result.invoiceId);
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not record payment. ${_short(e)}');
    }
  }

  /// Post-payment success sheet: lets admin print or share the receipt.
  void _offerReceiptPdf(String paymentId, String invoiceId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Payment recorded',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ]),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Print receipt'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _printReceipt(paymentId, invoiceId, share: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share receipt PDF'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _printReceipt(paymentId, invoiceId, share: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Done'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Fetches the saved invoice + payment from the repo and offers
  /// print or share. Used both right after a save and from the
  /// recent-transactions tap.
  Future<void> _printReceipt(
    String paymentId,
    String invoiceId, {
    required bool share,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Preparing receipt…'),
        duration: Duration(seconds: 2)));
    try {
      final repo = ref.read(feeRepositoryProvider);
      final invoice = await repo.getInvoiceById(invoiceId);
      if (invoice == null) throw 'Invoice not found.';
      final payments = await repo.getPayments(invoiceId: invoiceId);
      Payment? payment;
      for (final p in payments) {
        if (p.id == paymentId) {
          payment = p;
          break;
        }
      }
      payment ??= payments.isNotEmpty ? payments.first : null;
      if (payment == null) throw 'Payment not found.';
      final tenant = await ref.read(currentTenantProvider.future);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      if (share) {
        await PaymentReceiptPdfBuilder.buildAndShare(
            payment: payment, invoice: invoice, tenant: tenant);
      } else {
        await PaymentReceiptPdfBuilder.buildAndPrint(
            payment: payment, invoice: invoice, tenant: tenant);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not build receipt. ${_short(e)}');
    }
  }

  /// Print receipt for a tapped row in Recent Transactions.
  void _printReceiptForPayment(Payment p) {
    _printReceipt(p.id, p.invoiceId, share: false);
  }

  /// Per-student statement: aggregates the student's invoices and payments
  /// for the year and renders [FeeStatementPdfBuilder].
  Future<void> _printStatementForStudent(String studentId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Preparing statement…'),
        duration: Duration(seconds: 2)));
    try {
      final repo = ref.read(feeRepositoryProvider);
      final summary = await repo.getStudentFeeSummary(studentId: studentId);
      if (summary == null) throw 'No fee data for this student.';
      final invoices = await repo.getInvoices(
        studentId: studentId,
        academicYearId: summary.academicYearId,
      );
      final payments = await repo.getPayments(studentId: studentId);
      final tenant = await ref.read(currentTenantProvider.future);
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await FeeStatementPdfBuilder.buildAndShare(
        summary: summary,
        invoices: invoices,
        payments: payments,
        tenant: tenant,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not build statement. ${_short(e)}');
    }
  }

  /// Apply a one-off discount/concession to a single invoice.
  Future<void> _applyDiscount() async {
    final invoices = ref.read(overdueInvoicesProvider).value ?? const [];
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invoices to discount.')),
      );
      return;
    }
    final result = await showModalBottomSheet<_DiscountResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiscountSheet(invoices: invoices),
    );
    if (result == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(feeRepositoryProvider).applyInvoiceDiscount(
            invoiceId: result.invoiceId,
            discountAmount: result.discountAmount,
            reason: result.reason,
          );
      ref
        ..invalidate(overdueInvoicesProvider)
        ..invalidate(feeCollectionStatsProvider);
      if (!mounted) return;
      context.showSuccessSnackBar('Discount applied.');
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not apply discount. ${_short(e)}');
    }
  }

  /// Log a reminder for one invoice (used from the Pending tab row).
  Future<void> _remindOne(Invoice inv) async {
    try {
      final pending = inv.totalAmount - inv.discountAmount - inv.paidAmount;
      await ref.read(feeRepositoryProvider).logReminderSent(
            invoiceId: inv.id,
            studentId: inv.studentId,
            messageText:
                'Reminder: Invoice ${inv.invoiceNumber} of ₹${pending.toStringAsFixed(0)} is overdue.',
            riskScore: _overdueRisk(inv),
          );
      if (!mounted) return;
      context.showSuccessSnackBar('Reminder logged.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not send reminder. ${_short(e)}');
    }
  }

  Future<void> _addFeeHead() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeeHeadSheet(),
    );
    if (data == null || !mounted) return;
    try {
      await ref.read(feeHeadsNotifierProvider.notifier).createFeeHead(data);
      ref.invalidate(feeHeadsProvider);
      if (!mounted) return;
      context.showSuccessSnackBar('Fee head added.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not add fee head. ${_short(e)}');
    }
  }

  Future<void> _editFeeHead(FeeHead fh) async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeeHeadSheet(existing: fh),
    );
    if (data == null || !mounted) return;
    try {
      await ref.read(feeRepositoryProvider).updateFeeHead(fh.id, data);
      ref.invalidate(feeHeadsProvider);
      if (!mounted) return;
      context.showSuccessSnackBar('Fee head updated.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not update fee head. ${_short(e)}');
    }
  }

  Future<void> _addFeeStructure() async {
    final data = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FeeStructureSheet(),
    );
    if (data == null || !mounted) return;
    try {
      await ref.read(feeRepositoryProvider).createFeeStructure(data);
      if (!mounted) return;
      context.showSuccessSnackBar('Fee structure added.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Could not add structure. ${_short(e)}');
    }
  }

  /// Full collection report — every invoice in the current view.
  Future<void> _exportReport() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Preparing report…'),
        duration: Duration(seconds: 2)));
    try {
      final invoices = await ref.read(feeRepositoryProvider).getInvoices();
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await FeesPdfBuilder.buildAndShare(invoices);
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not export. ${_short(e)}');
    }
  }

  /// Defaulter report — overdue invoices only.
  Future<void> _exportDefaulters(List<Invoice> overdue) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
        content: Text('Preparing defaulter list…'),
        duration: Duration(seconds: 2)));
    try {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      await FeesPdfBuilder.buildAndShareDefaulters(overdue);
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      context.showErrorSnackBar('Could not build report. ${_short(e)}');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _short(Object e) {
    final s = e.toString();
    return s.length > 80 ? '${s.substring(0, 80)}…' : s;
  }

  /// Crude 0–100 risk score derived from days overdue and unpaid ratio.
  /// Used only as a tag on the reminder log so analytics can group by
  /// severity later. Not a substitute for the ML risk model.
  int _overdueRisk(Invoice inv) {
    final days = DateTime.now().difference(inv.dueDate).inDays.clamp(0, 365);
    final total = inv.totalAmount - inv.discountAmount;
    final unpaidRatio =
        total <= 0 ? 0 : ((total - inv.paidAmount) / total).clamp(0, 1);
    final score = (0.6 * (days / 90) + 0.4 * unpaidRatio) * 100;
    return score.clamp(0, 100).round();
  }
}

// =============================================================================
// Recent Transactions — real query, no mocks.
// =============================================================================

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions({required this.onTapPrint});
  final void Function(Payment) onTapPrint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(recentPaymentsProvider);
    return paymentsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(WarmCopy.genericError,
            style: TextStyle(color: Colors.grey[600])),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No recent payments.',
                style: TextStyle(color: Colors.grey[600])),
          );
        }
        return Column(
          children: payments
              .map((p) => GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    onTap: () => onTapPrint(p),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.check_circle,
                            color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.studentName ?? p.paymentNumber,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(
                                '${p.paymentMethod.toUpperCase()} · ${_relTime(p.paidAt ?? p.createdAt)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Text('+₹${p.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success)),
                      const SizedBox(width: 6),
                      const Icon(Icons.print_outlined,
                          size: 18, color: Colors.grey),
                    ]),
                  ))
              .toList(),
        );
      },
    );
  }

  String _relTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}

// =============================================================================
// Summary card and action button (unchanged style)
// =============================================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 20), const Spacer()]),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(WarmCopy.genericError),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// =============================================================================
// Generate Invoice sheet — class + academic year + term + due date.
// =============================================================================

class _GenerateInvoiceParams {
  const _GenerateInvoiceParams({
    required this.classId,
    required this.academicYearId,
    this.termId,
    this.dueDate,
  });
  final String classId;
  final String academicYearId;
  final String? termId;
  final DateTime? dueDate;
}

class _GenerateInvoiceSheet extends ConsumerStatefulWidget {
  const _GenerateInvoiceSheet();
  @override
  ConsumerState<_GenerateInvoiceSheet> createState() =>
      _GenerateInvoiceSheetState();
}

class _GenerateInvoiceSheetState
    extends ConsumerState<_GenerateInvoiceSheet> {
  String? _classId;
  String? _yearId;
  String? _termId;
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final termsAsync = _yearId == null
        ? const AsyncValue<List<Term>>.data([])
        : ref.watch(termsProvider(_yearId!));

    return _SheetShell(
      title: 'Generate Invoices',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _dropdown<SchoolClass>(
            label: 'Class',
            value: _classId,
            items: classesAsync,
            toValue: (c) => c.id,
            toLabel: (c) => c.name,
            onChanged: (v) => setState(() => _classId = v),
          ),
          const SizedBox(height: 12),
          _dropdown<AcademicYear>(
            label: 'Academic Year',
            value: _yearId,
            items: yearsAsync,
            toValue: (y) => y.id,
            toLabel: (y) => y.name,
            onChanged: (v) => setState(() {
              _yearId = v;
              _termId = null;
            }),
          ),
          const SizedBox(height: 12),
          _dropdown<Term>(
            label: 'Term (optional)',
            value: _termId,
            items: termsAsync,
            toValue: (t) => t.id,
            toLabel: (t) => t.name,
            onChanged: (v) => setState(() => _termId = v),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_dueDate == null
                ? 'Due date (optional)'
                : 'Due ${DateFormat('d MMM yyyy').format(_dueDate!)}'),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _classId == null || _yearId == null
                ? null
                : () => Navigator.pop(
                      context,
                      _GenerateInvoiceParams(
                        classId: _classId!,
                        academicYearId: _yearId!,
                        termId: _termId,
                        dueDate: _dueDate,
                      ),
                    ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Record Payment sheet
// =============================================================================

class _RecordPaymentResult {
  const _RecordPaymentResult({
    required this.invoiceId,
    required this.amount,
    required this.method,
    this.transactionId,
    this.remarks,
  });
  final String invoiceId;
  final double amount;
  final String method;
  final String? transactionId;
  final String? remarks;
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet({this.prefillInvoice});
  final Invoice? prefillInvoice;

  @override
  ConsumerState<_RecordPaymentSheet> createState() =>
      _RecordPaymentSheetState();
}

class _RecordPaymentSheetState
    extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  final _txnCtl = TextEditingController();
  final _remarksCtl = TextEditingController();
  String _method = 'cash';
  Invoice? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.prefillInvoice;
    if (_picked != null) {
      _amountCtl.text =
          (_picked!.totalAmount - _picked!.discountAmount - _picked!.paidAmount)
              .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _txnCtl.dispose();
    _remarksCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overdue = ref.watch(overdueInvoicesProvider);
    return _SheetShell(
      title: 'Record Payment',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.prefillInvoice != null) ...[
              _ReadOnlyTile(
                label: 'Student',
                value: widget.prefillInvoice!.studentName ?? '—',
              ),
              const SizedBox(height: 8),
              _ReadOnlyTile(
                label: 'Invoice',
                value: widget.prefillInvoice!.invoiceNumber,
              ),
              const SizedBox(height: 12),
            ] else
              overdue.when(
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) =>
                    Text(WarmCopy.genericError),
                data: (invs) {
                  return DropdownButtonFormField<Invoice>(
                    initialValue: _picked,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Invoice',
                      border: OutlineInputBorder(),
                    ),
                    items: invs
                        .map((inv) => DropdownMenuItem(
                              value: inv,
                              child: Text(
                                '${inv.invoiceNumber} · ${inv.studentName ?? "—"} · ₹${(inv.totalAmount - inv.discountAmount - inv.paidAmount).toStringAsFixed(0)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    validator: (v) => v == null ? 'Pick an invoice' : null,
                    onChanged: (v) {
                      setState(() {
                        _picked = v;
                        if (v != null) {
                          _amountCtl.text =
                              (v.totalAmount - v.discountAmount - v.paidAmount)
                                  .toStringAsFixed(0);
                        }
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtl,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                if (_picked != null) {
                  final due = _picked!.totalAmount -
                      _picked!.discountAmount -
                      _picked!.paidAmount;
                  if (n > due + 0.01) {
                    return 'Cannot exceed pending ₹${due.toStringAsFixed(0)}';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                  labelText: 'Method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'online', child: Text('Online')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _txnCtl,
              decoration: const InputDecoration(
                labelText: 'Transaction / Reference # (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Remarks (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                if (_picked == null) return;
                Navigator.pop(
                  context,
                  _RecordPaymentResult(
                    invoiceId: _picked!.id,
                    amount: double.parse(_amountCtl.text),
                    method: _method,
                    transactionId:
                        _txnCtl.text.trim().isEmpty ? null : _txnCtl.text.trim(),
                    remarks: _remarksCtl.text.trim().isEmpty
                        ? null
                        : _remarksCtl.text.trim(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Discount sheet — apply a one-off discount to an invoice.
// =============================================================================

class _DiscountResult {
  const _DiscountResult({
    required this.invoiceId,
    required this.discountAmount,
    this.reason,
  });
  final String invoiceId;
  final double discountAmount;
  final String? reason;
}

class _DiscountSheet extends StatefulWidget {
  const _DiscountSheet({required this.invoices});
  final List<Invoice> invoices;
  @override
  State<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<_DiscountSheet> {
  Invoice? _picked;
  final _amountCtl = TextEditingController();
  final _reasonCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountCtl.dispose();
    _reasonCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: 'Apply Discount',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<Invoice>(
              initialValue: _picked,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Invoice', border: OutlineInputBorder()),
              items: widget.invoices
                  .map((inv) => DropdownMenuItem(
                        value: inv,
                        child: Text(
                          '${inv.invoiceNumber} · ${inv.studentName ?? "—"}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              validator: (v) => v == null ? 'Pick an invoice' : null,
              onChanged: (v) => setState(() => _picked = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtl,
              decoration: const InputDecoration(
                labelText: 'Discount amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                if (_picked != null && n > _picked!.totalAmount) {
                  return 'Discount cannot exceed invoice total';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonCtl,
              decoration: const InputDecoration(
                labelText: 'Reason (saved to invoice notes)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _DiscountResult(
                    invoiceId: _picked!.id,
                    discountAmount: double.parse(_amountCtl.text),
                    reason: _reasonCtl.text.trim().isEmpty
                        ? null
                        : _reasonCtl.text.trim(),
                  ),
                );
              },
              child: const Text('Apply Discount'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Fee Head create/edit sheet
// =============================================================================

class _FeeHeadSheet extends StatefulWidget {
  const _FeeHeadSheet({this.existing});
  final FeeHead? existing;
  @override
  State<_FeeHeadSheet> createState() => _FeeHeadSheetState();
}

class _FeeHeadSheetState extends State<_FeeHeadSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  final _descCtl = TextEditingController();
  bool _recurring = true;

  @override
  void initState() {
    super.initState();
    final fh = widget.existing;
    if (fh != null) {
      _nameCtl.text = fh.name;
      _codeCtl.text = fh.code ?? '';
      _descCtl.text = fh.description ?? '';
      _recurring = fh.isRecurring;
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _codeCtl.dispose();
    _descCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      title: widget.existing == null ? 'Add Fee Head' : 'Edit Fee Head',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                  labelText: 'Name (e.g. Tuition Fee)',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeCtl,
              decoration: const InputDecoration(
                  labelText: 'Code (optional, e.g. TUI)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder()),
            ),
            SwitchListTile.adaptive(
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
              title: const Text('Recurring'),
              subtitle: const Text('Applied every term'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'name': _nameCtl.text.trim(),
                  if (_codeCtl.text.trim().isNotEmpty)
                    'code': _codeCtl.text.trim(),
                  if (_descCtl.text.trim().isNotEmpty)
                    'description': _descCtl.text.trim(),
                  'is_recurring': _recurring,
                });
              },
              child: Text(widget.existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Fee Structure sheet — class × year × head → amount
// =============================================================================

class _FeeStructureSheet extends ConsumerStatefulWidget {
  const _FeeStructureSheet();
  @override
  ConsumerState<_FeeStructureSheet> createState() =>
      _FeeStructureSheetState();
}

class _FeeStructureSheetState
    extends ConsumerState<_FeeStructureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtl = TextEditingController();
  String? _classId;
  String? _yearId;
  String? _termId;
  String? _headId;
  bool _mandatory = true;

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);
    final yearsAsync = ref.watch(academicYearsProvider);
    final headsAsync = ref.watch(feeHeadsProvider);
    final termsAsync = _yearId == null
        ? const AsyncValue<List<Term>>.data([])
        : ref.watch(termsProvider(_yearId!));

    return _SheetShell(
      title: 'Add Fee Structure',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dropdown<SchoolClass>(
              label: 'Class',
              value: _classId,
              items: classesAsync,
              toValue: (c) => c.id,
              toLabel: (c) => c.name,
              onChanged: (v) => setState(() => _classId = v),
            ),
            const SizedBox(height: 12),
            _dropdown<AcademicYear>(
              label: 'Academic Year',
              value: _yearId,
              items: yearsAsync,
              toValue: (y) => y.id,
              toLabel: (y) => y.name,
              onChanged: (v) => setState(() {
                _yearId = v;
                _termId = null;
              }),
            ),
            const SizedBox(height: 12),
            _dropdown<Term>(
              label: 'Term (optional)',
              value: _termId,
              items: termsAsync,
              toValue: (t) => t.id,
              toLabel: (t) => t.name,
              onChanged: (v) => setState(() => _termId = v),
            ),
            const SizedBox(height: 12),
            _dropdown<FeeHead>(
              label: 'Fee Head',
              value: _headId,
              items: headsAsync,
              toValue: (h) => h.id,
              toLabel: (h) => h.name,
              onChanged: (v) => setState(() => _headId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtl,
              decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            SwitchListTile.adaptive(
              value: _mandatory,
              onChanged: (v) => setState(() => _mandatory = v),
              title: const Text('Mandatory'),
              subtitle: const Text('Auto-included in every invoice'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _classId == null ||
                      _yearId == null ||
                      _headId == null ||
                      !_formKey.currentState!.validate()
                  ? null
                  : () {
                      Navigator.pop(context, {
                        'class_id': _classId,
                        'academic_year_id': _yearId,
                        if (_termId != null) 'term_id': _termId,
                        'fee_head_id': _headId,
                        'amount': double.parse(_amountCtl.text),
                        'is_mandatory': _mandatory,
                      });
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Shared sheet/dropdown helpers
// =============================================================================

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

Widget _dropdown<T>({
  required String label,
  required String? value,
  required AsyncValue<List<T>> items,
  required String Function(T) toValue,
  required String Function(T) toLabel,
  required ValueChanged<String?> onChanged,
}) {
  return items.when(
    loading: () => InputDecorator(
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      child: const SizedBox(
        height: 24,
        child: Center(
            child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
    ),
    error: (_, __) => InputDecorator(
      decoration: InputDecoration(
          labelText: label, border: const OutlineInputBorder()),
      child: Text(WarmCopy.genericError,
          style: TextStyle(color: Colors.grey[600])),
    ),
    data: (list) => DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: list
          .map((it) => DropdownMenuItem(
                value: toValue(it),
                child: Text(toLabel(it)),
              ))
          .toList(),
      onChanged: onChanged,
    ),
  );
}

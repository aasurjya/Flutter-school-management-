import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
class FeeHead with _$FeeHead {
  const factory FeeHead({
    required String id,
    required String tenantId,
    required String name,
    String? code,
    String? description,
    @Default(true) bool isRecurring,
    DateTime? createdAt,
  }) = _FeeHead;

  factory FeeHead.fromJson(Map<String, dynamic> json) => _$FeeHeadFromJson(json);
}

@freezed
class FeeStructure with _$FeeStructure {
  const factory FeeStructure({
    required String id,
    required String tenantId,
    required String academicYearId,
    required String classId,
    required String feeHeadId,
    required double amount,
    DateTime? dueDate,
    String? termId,
    @Default(true) bool isMandatory,
    DateTime? createdAt,
    // Joined data
    String? feeHeadName,
    String? className,
    String? academicYearName,
    String? termName,
  }) = _FeeStructure;

  factory FeeStructure.fromJson(Map<String, dynamic> json) =>
      _$FeeStructureFromJson(json);
}

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String tenantId,
    required String invoiceNumber,
    required String studentId,
    required String academicYearId,
    String? termId,
    required double totalAmount,
    @Default(0) double discountAmount,
    @Default(0) double paidAmount,
    required DateTime dueDate,
    @Default('pending') String status,
    String? notes,
    String? generatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Joined data
    String? studentName,
    String? admissionNumber,
    String? sectionName,
    String? className,
    String? academicYearName,
    String? termName,
    List<InvoiceItem>? items,
    List<Payment>? payments,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
}

@freezed
class InvoiceItem with _$InvoiceItem {
  const factory InvoiceItem({
    required String id,
    required String invoiceId,
    required String feeHeadId,
    String? description,
    required double amount,
    @Default(0) double discount,
    // Joined data
    String? feeHeadName,
  }) = _InvoiceItem;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) =>
      _$InvoiceItemFromJson(json);
}

@freezed
class Payment with _$Payment {
  const factory Payment({
    required String id,
    required String tenantId,
    required String invoiceId,
    required String paymentNumber,
    required double amount,
    required String paymentMethod,
    @Default('pending') String status,
    String? transactionId,
    Map<String, dynamic>? gatewayResponse,
    DateTime? paidAt,
    String? receivedBy,
    String? remarks,
    DateTime? createdAt,
    // Joined data
    String? receivedByName,
    String? invoiceNumber,
    String? studentName,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

@freezed
class FeeSummary with _$FeeSummary {
  const factory FeeSummary({
    required String tenantId,
    required String studentId,
    required String studentName,
    required String admissionNumber,
    required String sectionId,
    required String sectionName,
    required String className,
    required String academicYearId,
    required String academicYearName,
    required double totalFee,
    required double totalDiscount,
    required double totalPaid,
    required double totalPending,
    required int totalInvoices,
    required int paidInvoices,
    required int pendingInvoices,
    required int overdueInvoices,
  }) = _FeeSummary;

  factory FeeSummary.fromJson(Map<String, dynamic> json) =>
      _$FeeSummaryFromJson(json);
}

extension InvoiceHelpers on Invoice {
  double get pendingAmount => totalAmount - discountAmount - paidAmount;
  double get netAmount => totalAmount - discountAmount;
  
  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isPartial => status == 'partial';
  bool get isOverdue => status == 'overdue';
  bool get isCancelled => status == 'cancelled';
  bool get isDraft => status == 'draft';
  
  bool get isOverdueNow => 
      !isPaid && !isCancelled && DateTime.now().isAfter(dueDate);
  
  String get statusDisplay {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partially Paid';
      case 'paid':
        return 'Paid';
      case 'overdue':
        return 'Overdue';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
  
  double get paidPercentage => 
      netAmount > 0 ? (paidAmount / netAmount) * 100 : 0;
}

extension PaymentHelpers on Payment {
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';
  
  String get paymentMethodDisplay {
    switch (paymentMethod) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'netbanking':
        return 'Net Banking';
      case 'cheque':
        return 'Cheque';
      case 'wallet':
        return 'Wallet';
      default:
        return paymentMethod;
    }
  }
  
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }
}

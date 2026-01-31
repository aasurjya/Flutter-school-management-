// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeeHeadImpl _$$FeeHeadImplFromJson(Map<String, dynamic> json) =>
    _$FeeHeadImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$FeeHeadImplToJson(_$FeeHeadImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'name': instance.name,
      'code': instance.code,
      'description': instance.description,
      'isRecurring': instance.isRecurring,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$FeeStructureImpl _$$FeeStructureImplFromJson(Map<String, dynamic> json) =>
    _$FeeStructureImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      academicYearId: json['academicYearId'] as String,
      classId: json['classId'] as String,
      feeHeadId: json['feeHeadId'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
      termId: json['termId'] as String?,
      isMandatory: json['isMandatory'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      feeHeadName: json['feeHeadName'] as String?,
      className: json['className'] as String?,
      academicYearName: json['academicYearName'] as String?,
      termName: json['termName'] as String?,
    );

Map<String, dynamic> _$$FeeStructureImplToJson(_$FeeStructureImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'academicYearId': instance.academicYearId,
      'classId': instance.classId,
      'feeHeadId': instance.feeHeadId,
      'amount': instance.amount,
      'dueDate': instance.dueDate?.toIso8601String(),
      'termId': instance.termId,
      'isMandatory': instance.isMandatory,
      'createdAt': instance.createdAt?.toIso8601String(),
      'feeHeadName': instance.feeHeadName,
      'className': instance.className,
      'academicYearName': instance.academicYearName,
      'termName': instance.termName,
    };

_$InvoiceImpl _$$InvoiceImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      studentId: json['studentId'] as String,
      academicYearId: json['academicYearId'] as String,
      termId: json['termId'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      generatedBy: json['generatedBy'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      studentName: json['studentName'] as String?,
      admissionNumber: json['admissionNumber'] as String?,
      sectionName: json['sectionName'] as String?,
      className: json['className'] as String?,
      academicYearName: json['academicYearName'] as String?,
      termName: json['termName'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$InvoiceImplToJson(_$InvoiceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'invoiceNumber': instance.invoiceNumber,
      'studentId': instance.studentId,
      'academicYearId': instance.academicYearId,
      'termId': instance.termId,
      'totalAmount': instance.totalAmount,
      'discountAmount': instance.discountAmount,
      'paidAmount': instance.paidAmount,
      'dueDate': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'notes': instance.notes,
      'generatedBy': instance.generatedBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'sectionName': instance.sectionName,
      'className': instance.className,
      'academicYearName': instance.academicYearName,
      'termName': instance.termName,
      'items': instance.items,
      'payments': instance.payments,
    };

_$InvoiceItemImpl _$$InvoiceItemImplFromJson(Map<String, dynamic> json) =>
    _$InvoiceItemImpl(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      feeHeadId: json['feeHeadId'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      feeHeadName: json['feeHeadName'] as String?,
    );

Map<String, dynamic> _$$InvoiceItemImplToJson(_$InvoiceItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoiceId': instance.invoiceId,
      'feeHeadId': instance.feeHeadId,
      'description': instance.description,
      'amount': instance.amount,
      'discount': instance.discount,
      'feeHeadName': instance.feeHeadName,
    };

_$PaymentImpl _$$PaymentImplFromJson(Map<String, dynamic> json) =>
    _$PaymentImpl(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      invoiceId: json['invoiceId'] as String,
      paymentNumber: json['paymentNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: json['status'] as String? ?? 'pending',
      transactionId: json['transactionId'] as String?,
      gatewayResponse: json['gatewayResponse'] as Map<String, dynamic>?,
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      receivedBy: json['receivedBy'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      receivedByName: json['receivedByName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      studentName: json['studentName'] as String?,
    );

Map<String, dynamic> _$$PaymentImplToJson(_$PaymentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'invoiceId': instance.invoiceId,
      'paymentNumber': instance.paymentNumber,
      'amount': instance.amount,
      'paymentMethod': instance.paymentMethod,
      'status': instance.status,
      'transactionId': instance.transactionId,
      'gatewayResponse': instance.gatewayResponse,
      'paidAt': instance.paidAt?.toIso8601String(),
      'receivedBy': instance.receivedBy,
      'remarks': instance.remarks,
      'createdAt': instance.createdAt?.toIso8601String(),
      'receivedByName': instance.receivedByName,
      'invoiceNumber': instance.invoiceNumber,
      'studentName': instance.studentName,
    };

_$FeeSummaryImpl _$$FeeSummaryImplFromJson(Map<String, dynamic> json) =>
    _$FeeSummaryImpl(
      tenantId: json['tenantId'] as String,
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      admissionNumber: json['admissionNumber'] as String,
      sectionId: json['sectionId'] as String,
      sectionName: json['sectionName'] as String,
      className: json['className'] as String,
      academicYearId: json['academicYearId'] as String,
      academicYearName: json['academicYearName'] as String,
      totalFee: (json['totalFee'] as num).toDouble(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      totalPending: (json['totalPending'] as num).toDouble(),
      totalInvoices: (json['totalInvoices'] as num).toInt(),
      paidInvoices: (json['paidInvoices'] as num).toInt(),
      pendingInvoices: (json['pendingInvoices'] as num).toInt(),
      overdueInvoices: (json['overdueInvoices'] as num).toInt(),
    );

Map<String, dynamic> _$$FeeSummaryImplToJson(_$FeeSummaryImpl instance) =>
    <String, dynamic>{
      'tenantId': instance.tenantId,
      'studentId': instance.studentId,
      'studentName': instance.studentName,
      'admissionNumber': instance.admissionNumber,
      'sectionId': instance.sectionId,
      'sectionName': instance.sectionName,
      'className': instance.className,
      'academicYearId': instance.academicYearId,
      'academicYearName': instance.academicYearName,
      'totalFee': instance.totalFee,
      'totalDiscount': instance.totalDiscount,
      'totalPaid': instance.totalPaid,
      'totalPending': instance.totalPending,
      'totalInvoices': instance.totalInvoices,
      'paidInvoices': instance.paidInvoices,
      'pendingInvoices': instance.pendingInvoices,
      'overdueInvoices': instance.overdueInvoices,
    };

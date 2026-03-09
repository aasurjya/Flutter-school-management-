// HR & Payroll Models

// ============================================================================
// Enums
// ============================================================================

enum ContractType { permanent, temporary, contract, probation }

enum ContractStatus { active, expired, terminated }

enum PayrollRunStatus { draft, processing, completed, approved }

enum PayrollPaymentStatus { pending, paid, failed }

enum StaffAttendanceStatus { present, absent, halfDay, onLeave, holiday }

enum TaxDeclarationStatus { draft, submitted, verified }

enum StaffDocumentType {
  resume,
  idProof,
  addressProof,
  qualification,
  experienceLetter,
  offerLetter,
  contract,
}

// ============================================================================
// Department
// ============================================================================

class Department {
  final String id;
  final String tenantId;
  final String name;
  final String? headOfDepartmentId;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? hodName;
  final int? staffCount;

  const Department({
    required this.id,
    required this.tenantId,
    required this.name,
    this.headOfDepartmentId,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.hodName,
    this.staffCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      name: json['name'] ?? '',
      headOfDepartmentId: json['head_of_department_id'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      hodName: json['hod']?['full_name'] ?? json['hod_name'],
      staffCount: json['staff_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'head_of_department_id': headOfDepartmentId,
      'description': description,
      'is_active': isActive,
    };
  }

  String get initials {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

// ============================================================================
// Designation
// ============================================================================

class Designation {
  final String id;
  final String tenantId;
  final String name;
  final String? departmentId;
  final int level;
  final String? payGrade;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? departmentName;

  const Designation({
    required this.id,
    required this.tenantId,
    required this.name,
    this.departmentId,
    this.level = 1,
    this.payGrade,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.departmentName,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      name: json['name'] ?? '',
      departmentId: json['department_id'],
      level: json['level'] ?? 1,
      payGrade: json['pay_grade'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      departmentName: json['departments']?['name'] ?? json['department_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'department_id': departmentId,
      'level': level,
      'pay_grade': payGrade,
      'is_active': isActive,
    };
  }
}

// ============================================================================
// StaffContract
// ============================================================================

class StaffContract {
  final String id;
  final String tenantId;
  final String staffId;
  final ContractType contractType;
  final DateTime startDate;
  final DateTime? endDate;
  final double basicSalary;
  final double hra;
  final double da;
  final double ta;
  final Map<String, dynamic> otherAllowances;
  final Map<String, dynamic> deductions;
  final double grossSalary;
  final double netSalary;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? staffName;
  final String? staffEmployeeId;

  const StaffContract({
    required this.id,
    required this.tenantId,
    required this.staffId,
    this.contractType = ContractType.permanent,
    required this.startDate,
    this.endDate,
    this.basicSalary = 0,
    this.hra = 0,
    this.da = 0,
    this.ta = 0,
    this.otherAllowances = const {},
    this.deductions = const {},
    this.grossSalary = 0,
    this.netSalary = 0,
    this.status = ContractStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.staffName,
    this.staffEmployeeId,
  });

  factory StaffContract.fromJson(Map<String, dynamic> json) {
    return StaffContract(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      contractType: _parseContractType(json['contract_type']),
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      basicSalary: _toDouble(json['basic_salary']),
      hra: _toDouble(json['hra']),
      da: _toDouble(json['da']),
      ta: _toDouble(json['ta']),
      otherAllowances:
          json['other_allowances'] is Map
              ? Map<String, dynamic>.from(json['other_allowances'])
              : {},
      deductions:
          json['deductions'] is Map
              ? Map<String, dynamic>.from(json['deductions'])
              : {},
      grossSalary: _toDouble(json['gross_salary']),
      netSalary: _toDouble(json['net_salary']),
      status: _parseContractStatus(json['status']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      staffName: _extractStaffName(json['staff']),
      staffEmployeeId: json['staff']?['employee_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'staff_id': staffId,
      'contract_type': contractType.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'basic_salary': basicSalary,
      'hra': hra,
      'da': da,
      'ta': ta,
      'other_allowances': otherAllowances,
      'deductions': deductions,
      'gross_salary': grossSalary,
      'net_salary': netSalary,
      'status': status.name,
    };
  }

  String get contractTypeDisplay {
    switch (contractType) {
      case ContractType.permanent:
        return 'Permanent';
      case ContractType.temporary:
        return 'Temporary';
      case ContractType.contract:
        return 'Contract';
      case ContractType.probation:
        return 'Probation';
    }
  }

  String get statusDisplay {
    switch (status) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.expired:
        return 'Expired';
      case ContractStatus.terminated:
        return 'Terminated';
    }
  }

  bool get isExpiringSoon {
    if (endDate == null) return false;
    return endDate!.difference(DateTime.now()).inDays <= 30;
  }

  int? get daysUntilExpiry {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  double get totalAllowances =>
      hra +
      da +
      ta +
      otherAllowances.values.fold<double>(
        0,
        (sum, v) => sum + _toDouble(v),
      );

  double get totalDeductions =>
      deductions.values.fold<double>(0, (sum, v) => sum + _toDouble(v));

  static ContractType _parseContractType(String? value) {
    switch (value) {
      case 'temporary':
        return ContractType.temporary;
      case 'contract':
        return ContractType.contract;
      case 'probation':
        return ContractType.probation;
      default:
        return ContractType.permanent;
    }
  }

  static ContractStatus _parseContractStatus(String? value) {
    switch (value) {
      case 'expired':
        return ContractStatus.expired;
      case 'terminated':
        return ContractStatus.terminated;
      default:
        return ContractStatus.active;
    }
  }

  static String? _extractStaffName(Map<String, dynamic>? staff) {
    if (staff == null) return null;
    final first = staff['first_name'] ?? staff['designation'] ?? '';
    final last = staff['last_name'] ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : null;
  }
}

// ============================================================================
// SalaryStructure
// ============================================================================

class SalaryComponent {
  final String name;
  final String type; // earning or deduction
  final String calculation; // fixed or percentage
  final double value;
  final bool isTaxable;

  const SalaryComponent({
    required this.name,
    required this.type,
    required this.calculation,
    required this.value,
    this.isTaxable = false,
  });

  factory SalaryComponent.fromJson(Map<String, dynamic> json) {
    return SalaryComponent(
      name: json['name'] ?? '',
      type: json['type'] ?? 'earning',
      calculation: json['calculation'] ?? 'fixed',
      value: _toDouble(json['value']),
      isTaxable: json['is_taxable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'calculation': calculation,
      'value': value,
      'is_taxable': isTaxable,
    };
  }

  bool get isEarning => type == 'earning';
  bool get isDeduction => type == 'deduction';
  bool get isFixed => calculation == 'fixed';
  bool get isPercentage => calculation == 'percentage';
}

class SalaryStructure {
  final String id;
  final String tenantId;
  final String name;
  final List<SalaryComponent> components;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SalaryStructure({
    required this.id,
    required this.tenantId,
    required this.name,
    this.components = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    List<SalaryComponent> components = [];
    if (json['components'] is List) {
      components = (json['components'] as List)
          .map((c) => SalaryComponent.fromJson(c is Map<String, dynamic> ? c : {}))
          .toList();
    }

    return SalaryStructure(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      name: json['name'] ?? '',
      components: components,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'name': name,
      'components': components.map((c) => c.toJson()).toList(),
      'is_active': isActive,
    };
  }

  List<SalaryComponent> get earnings =>
      components.where((c) => c.isEarning).toList();
  List<SalaryComponent> get deductionsList =>
      components.where((c) => c.isDeduction).toList();
}

// ============================================================================
// PayrollRun
// ============================================================================

class PayrollRun {
  final String id;
  final String tenantId;
  final int month;
  final int year;
  final DateTime runDate;
  final PayrollRunStatus status;
  final double totalGross;
  final double totalDeductions;
  final double totalNet;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? approverName;
  final int? staffCount;
  final List<PayrollItem>? items;

  const PayrollRun({
    required this.id,
    required this.tenantId,
    required this.month,
    required this.year,
    required this.runDate,
    this.status = PayrollRunStatus.draft,
    this.totalGross = 0,
    this.totalDeductions = 0,
    this.totalNet = 0,
    this.approvedBy,
    this.approvedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.approverName,
    this.staffCount,
    this.items,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    List<PayrollItem>? items;
    if (json['payroll_items'] is List) {
      items = (json['payroll_items'] as List)
          .map((i) => PayrollItem.fromJson(i))
          .toList();
    }

    return PayrollRun(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      runDate: json['run_date'] != null
          ? DateTime.parse(json['run_date'])
          : DateTime.now(),
      status: _parsePayrollRunStatus(json['status']),
      totalGross: _toDouble(json['total_gross']),
      totalDeductions: _toDouble(json['total_deductions']),
      totalNet: _toDouble(json['total_net']),
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      approverName: json['approver']?['full_name'],
      staffCount: items?.length ?? json['staff_count'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'month': month,
      'year': year,
      'run_date': runDate.toIso8601String().split('T')[0],
      'status': status.name,
      'notes': notes,
    };
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  String get periodDisplay => '$monthName $year';

  String get statusDisplay {
    switch (status) {
      case PayrollRunStatus.draft:
        return 'Draft';
      case PayrollRunStatus.processing:
        return 'Processing';
      case PayrollRunStatus.completed:
        return 'Completed';
      case PayrollRunStatus.approved:
        return 'Approved';
    }
  }

  bool get isDraft => status == PayrollRunStatus.draft;
  bool get isCompleted => status == PayrollRunStatus.completed;
  bool get isApproved => status == PayrollRunStatus.approved;

  static PayrollRunStatus _parsePayrollRunStatus(String? value) {
    switch (value) {
      case 'processing':
        return PayrollRunStatus.processing;
      case 'completed':
        return PayrollRunStatus.completed;
      case 'approved':
        return PayrollRunStatus.approved;
      default:
        return PayrollRunStatus.draft;
    }
  }
}

// ============================================================================
// PayrollItem
// ============================================================================

class PayrollItem {
  final String id;
  final String payrollRunId;
  final String staffId;
  final double basicSalary;
  final Map<String, dynamic> earnings;
  final Map<String, dynamic> deductions;
  final double grossSalary;
  final double taxAmount;
  final double netSalary;
  final PayrollPaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? paymentRef;
  final int daysWorked;
  final int daysAbsent;
  final double overtimeHours;
  final double overtimeAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? staffName;
  final String? staffEmployeeId;
  final String? designation;

  const PayrollItem({
    required this.id,
    required this.payrollRunId,
    required this.staffId,
    this.basicSalary = 0,
    this.earnings = const {},
    this.deductions = const {},
    this.grossSalary = 0,
    this.taxAmount = 0,
    this.netSalary = 0,
    this.paymentStatus = PayrollPaymentStatus.pending,
    this.paymentMethod,
    this.paymentRef,
    this.daysWorked = 0,
    this.daysAbsent = 0,
    this.overtimeHours = 0,
    this.overtimeAmount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.staffName,
    this.staffEmployeeId,
    this.designation,
  });

  factory PayrollItem.fromJson(Map<String, dynamic> json) {
    return PayrollItem(
      id: json['id'] ?? '',
      payrollRunId: json['payroll_run_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      basicSalary: _toDouble(json['basic_salary']),
      earnings: json['earnings'] is Map
          ? Map<String, dynamic>.from(json['earnings'])
          : {},
      deductions: json['deductions'] is Map
          ? Map<String, dynamic>.from(json['deductions'])
          : {},
      grossSalary: _toDouble(json['gross_salary']),
      taxAmount: _toDouble(json['tax_amount']),
      netSalary: _toDouble(json['net_salary']),
      paymentStatus: _parsePaymentStatus(json['payment_status']),
      paymentMethod: json['payment_method'],
      paymentRef: json['payment_ref'],
      daysWorked: json['days_worked'] ?? 0,
      daysAbsent: json['days_absent'] ?? 0,
      overtimeHours: _toDouble(json['overtime_hours']),
      overtimeAmount: _toDouble(json['overtime_amount']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      staffName: _extractStaffName(json['staff']),
      staffEmployeeId: json['staff']?['employee_id'],
      designation: json['staff']?['designation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payroll_run_id': payrollRunId,
      'staff_id': staffId,
      'basic_salary': basicSalary,
      'earnings': earnings,
      'deductions': deductions,
      'gross_salary': grossSalary,
      'tax_amount': taxAmount,
      'net_salary': netSalary,
      'payment_status': paymentStatus.name,
      'payment_method': paymentMethod,
      'payment_ref': paymentRef,
      'days_worked': daysWorked,
      'days_absent': daysAbsent,
      'overtime_hours': overtimeHours,
      'overtime_amount': overtimeAmount,
    };
  }

  String get paymentStatusDisplay {
    switch (paymentStatus) {
      case PayrollPaymentStatus.pending:
        return 'Pending';
      case PayrollPaymentStatus.paid:
        return 'Paid';
      case PayrollPaymentStatus.failed:
        return 'Failed';
    }
  }

  double get totalEarnings =>
      earnings.values.fold<double>(0, (sum, v) => sum + _toDouble(v));

  double get totalDeductions =>
      deductions.values.fold<double>(0, (sum, v) => sum + _toDouble(v)) +
      taxAmount;

  static PayrollPaymentStatus _parsePaymentStatus(String? value) {
    switch (value) {
      case 'paid':
        return PayrollPaymentStatus.paid;
      case 'failed':
        return PayrollPaymentStatus.failed;
      default:
        return PayrollPaymentStatus.pending;
    }
  }

  static String? _extractStaffName(Map<String, dynamic>? staff) {
    if (staff == null) return null;
    final first = staff['first_name'] ?? staff['designation'] ?? '';
    final last = staff['last_name'] ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : null;
  }
}

// ============================================================================
// SalarySlip
// ============================================================================

class SalarySlip {
  final String id;
  final String payrollItemId;
  final String slipNumber;
  final DateTime generatedAt;
  final String? pdfUrl;
  final bool sentToStaff;
  final DateTime createdAt;

  // Joined data
  final PayrollItem? payrollItem;

  const SalarySlip({
    required this.id,
    required this.payrollItemId,
    required this.slipNumber,
    required this.generatedAt,
    this.pdfUrl,
    this.sentToStaff = false,
    required this.createdAt,
    this.payrollItem,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'] ?? '',
      payrollItemId: json['payroll_item_id'] ?? '',
      slipNumber: json['slip_number'] ?? '',
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'])
          : DateTime.now(),
      pdfUrl: json['pdf_url'],
      sentToStaff: json['sent_to_staff'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      payrollItem: json['payroll_items'] != null
          ? PayrollItem.fromJson(json['payroll_items'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payroll_item_id': payrollItemId,
      'slip_number': slipNumber,
      'pdf_url': pdfUrl,
      'sent_to_staff': sentToStaff,
    };
  }
}

// ============================================================================
// StaffAttendanceDaily
// ============================================================================

class StaffAttendanceDaily {
  final String id;
  final String tenantId;
  final String staffId;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final StaffAttendanceStatus status;
  final double overtimeHours;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? staffName;
  final String? staffEmployeeId;

  const StaffAttendanceDaily({
    required this.id,
    required this.tenantId,
    required this.staffId,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.status = StaffAttendanceStatus.present,
    this.overtimeHours = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.staffName,
    this.staffEmployeeId,
  });

  factory StaffAttendanceDaily.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceDaily(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      status: _parseAttendanceStatus(json['status']),
      overtimeHours: _toDouble(json['overtime_hours']),
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      staffName: _extractStaffName(json['staff']),
      staffEmployeeId: json['staff']?['employee_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'staff_id': staffId,
      'date': date.toIso8601String().split('T')[0],
      'check_in': checkIn,
      'check_out': checkOut,
      'status': status.name,
      'overtime_hours': overtimeHours,
      'notes': notes,
    };
  }

  String get statusDisplay {
    switch (status) {
      case StaffAttendanceStatus.present:
        return 'Present';
      case StaffAttendanceStatus.absent:
        return 'Absent';
      case StaffAttendanceStatus.halfDay:
        return 'Half Day';
      case StaffAttendanceStatus.onLeave:
        return 'On Leave';
      case StaffAttendanceStatus.holiday:
        return 'Holiday';
    }
  }

  static StaffAttendanceStatus _parseAttendanceStatus(String? value) {
    switch (value) {
      case 'absent':
        return StaffAttendanceStatus.absent;
      case 'half_day':
        return StaffAttendanceStatus.halfDay;
      case 'on_leave':
        return StaffAttendanceStatus.onLeave;
      case 'holiday':
        return StaffAttendanceStatus.holiday;
      default:
        return StaffAttendanceStatus.present;
    }
  }

  static String? _extractStaffName(Map<String, dynamic>? staff) {
    if (staff == null) return null;
    final first = staff['first_name'] ?? staff['designation'] ?? '';
    final last = staff['last_name'] ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : null;
  }
}

// ============================================================================
// TaxDeclaration
// ============================================================================

class TaxDeclaration {
  final String id;
  final String tenantId;
  final String staffId;
  final String financialYear;
  final Map<String, dynamic> section80c;
  final Map<String, dynamic> section80d;
  final double hraExemption;
  final Map<String, dynamic> otherDeclarations;
  final TaxDeclarationStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? staffName;
  final String? verifierName;

  const TaxDeclaration({
    required this.id,
    required this.tenantId,
    required this.staffId,
    required this.financialYear,
    this.section80c = const {},
    this.section80d = const {},
    this.hraExemption = 0,
    this.otherDeclarations = const {},
    this.status = TaxDeclarationStatus.draft,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    this.staffName,
    this.verifierName,
  });

  factory TaxDeclaration.fromJson(Map<String, dynamic> json) {
    return TaxDeclaration(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      financialYear: json['financial_year'] ?? '',
      section80c: json['section_80c'] is Map
          ? Map<String, dynamic>.from(json['section_80c'])
          : {},
      section80d: json['section_80d'] is Map
          ? Map<String, dynamic>.from(json['section_80d'])
          : {},
      hraExemption: _toDouble(json['hra_exemption']),
      otherDeclarations: json['other_declarations'] is Map
          ? Map<String, dynamic>.from(json['other_declarations'])
          : {},
      status: _parseDeclarationStatus(json['status']),
      verifiedBy: json['verified_by'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      staffName: _extractStaffName(json['staff']),
      verifierName: json['verifier']?['full_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'staff_id': staffId,
      'financial_year': financialYear,
      'section_80c': section80c,
      'section_80d': section80d,
      'hra_exemption': hraExemption,
      'other_declarations': otherDeclarations,
      'status': status.name,
    };
  }

  String get statusDisplay {
    switch (status) {
      case TaxDeclarationStatus.draft:
        return 'Draft';
      case TaxDeclarationStatus.submitted:
        return 'Submitted';
      case TaxDeclarationStatus.verified:
        return 'Verified';
    }
  }

  double get total80c =>
      section80c.values.fold<double>(0, (sum, v) => sum + _toDouble(v));
  double get total80d =>
      section80d.values.fold<double>(0, (sum, v) => sum + _toDouble(v));
  double get totalDeclarations => total80c + total80d + hraExemption;

  static TaxDeclarationStatus _parseDeclarationStatus(String? value) {
    switch (value) {
      case 'submitted':
        return TaxDeclarationStatus.submitted;
      case 'verified':
        return TaxDeclarationStatus.verified;
      default:
        return TaxDeclarationStatus.draft;
    }
  }

  static String? _extractStaffName(Map<String, dynamic>? staff) {
    if (staff == null) return null;
    final first = staff['first_name'] ?? staff['designation'] ?? '';
    final last = staff['last_name'] ?? '';
    final name = '$first $last'.trim();
    return name.isNotEmpty ? name : null;
  }
}

// ============================================================================
// StaffDocument
// ============================================================================

class StaffDocument {
  final String id;
  final String tenantId;
  final String staffId;
  final StaffDocumentType documentType;
  final String fileUrl;
  final String? fileName;
  final DateTime uploadedAt;
  final bool verified;
  final String? verifiedBy;
  final String? notes;
  final DateTime createdAt;

  const StaffDocument({
    required this.id,
    required this.tenantId,
    required this.staffId,
    required this.documentType,
    required this.fileUrl,
    this.fileName,
    required this.uploadedAt,
    this.verified = false,
    this.verifiedBy,
    this.notes,
    required this.createdAt,
  });

  factory StaffDocument.fromJson(Map<String, dynamic> json) {
    return StaffDocument(
      id: json['id'] ?? '',
      tenantId: json['tenant_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      documentType: _parseDocumentType(json['document_type']),
      fileUrl: json['file_url'] ?? '',
      fileName: json['file_name'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : DateTime.now(),
      verified: json['verified'] ?? false,
      verifiedBy: json['verified_by'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_id': tenantId,
      'staff_id': staffId,
      'document_type': documentType.name,
      'file_url': fileUrl,
      'file_name': fileName,
      'notes': notes,
    };
  }

  String get documentTypeDisplay {
    switch (documentType) {
      case StaffDocumentType.resume:
        return 'Resume';
      case StaffDocumentType.idProof:
        return 'ID Proof';
      case StaffDocumentType.addressProof:
        return 'Address Proof';
      case StaffDocumentType.qualification:
        return 'Qualification';
      case StaffDocumentType.experienceLetter:
        return 'Experience Letter';
      case StaffDocumentType.offerLetter:
        return 'Offer Letter';
      case StaffDocumentType.contract:
        return 'Contract';
    }
  }

  static StaffDocumentType _parseDocumentType(String? value) {
    switch (value) {
      case 'id_proof':
        return StaffDocumentType.idProof;
      case 'address_proof':
        return StaffDocumentType.addressProof;
      case 'qualification':
        return StaffDocumentType.qualification;
      case 'experience_letter':
        return StaffDocumentType.experienceLetter;
      case 'offer_letter':
        return StaffDocumentType.offerLetter;
      case 'contract':
        return StaffDocumentType.contract;
      default:
        return StaffDocumentType.resume;
    }
  }
}

// ============================================================================
// HR Dashboard Stats (from view)
// ============================================================================

class HRDashboardStats {
  final int totalStaff;
  final int activeStaff;
  final int totalDepartments;
  final int activeContracts;
  final int expiringContracts;
  final double monthlyPayrollEstimate;

  // Computed on client
  final int presentToday;
  final int absentToday;
  final int onLeaveToday;

  const HRDashboardStats({
    this.totalStaff = 0,
    this.activeStaff = 0,
    this.totalDepartments = 0,
    this.activeContracts = 0,
    this.expiringContracts = 0,
    this.monthlyPayrollEstimate = 0,
    this.presentToday = 0,
    this.absentToday = 0,
    this.onLeaveToday = 0,
  });

  factory HRDashboardStats.fromJson(Map<String, dynamic> json) {
    return HRDashboardStats(
      totalStaff: json['total_staff'] ?? 0,
      activeStaff: json['active_staff'] ?? 0,
      totalDepartments: json['total_departments'] ?? 0,
      activeContracts: json['active_contracts'] ?? 0,
      expiringContracts: json['expiring_contracts'] ?? 0,
      monthlyPayrollEstimate: _toDouble(json['monthly_payroll_estimate']),
    );
  }

  HRDashboardStats copyWith({
    int? presentToday,
    int? absentToday,
    int? onLeaveToday,
  }) {
    return HRDashboardStats(
      totalStaff: totalStaff,
      activeStaff: activeStaff,
      totalDepartments: totalDepartments,
      activeContracts: activeContracts,
      expiringContracts: expiringContracts,
      monthlyPayrollEstimate: monthlyPayrollEstimate,
      presentToday: presentToday ?? this.presentToday,
      absentToday: absentToday ?? this.absentToday,
      onLeaveToday: onLeaveToday ?? this.onLeaveToday,
    );
  }
}

// ============================================================================
// Helper
// ============================================================================

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  if (value is num) return value.toDouble();
  return 0;
}

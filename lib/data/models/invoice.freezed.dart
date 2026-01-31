// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeeHead _$FeeHeadFromJson(Map<String, dynamic> json) {
  return _FeeHead.fromJson(json);
}

/// @nodoc
mixin _$FeeHead {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get code => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  bool get isRecurring => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeeHeadCopyWith<FeeHead> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeeHeadCopyWith<$Res> {
  factory $FeeHeadCopyWith(FeeHead value, $Res Function(FeeHead) then) =
      _$FeeHeadCopyWithImpl<$Res, FeeHead>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      String? code,
      String? description,
      bool isRecurring,
      DateTime? createdAt});
}

/// @nodoc
class _$FeeHeadCopyWithImpl<$Res, $Val extends FeeHead>
    implements $FeeHeadCopyWith<$Res> {
  _$FeeHeadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? name = null,
    Object? code = freezed,
    Object? description = freezed,
    Object? isRecurring = null,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeeHeadImplCopyWith<$Res> implements $FeeHeadCopyWith<$Res> {
  factory _$$FeeHeadImplCopyWith(
          _$FeeHeadImpl value, $Res Function(_$FeeHeadImpl) then) =
      __$$FeeHeadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String name,
      String? code,
      String? description,
      bool isRecurring,
      DateTime? createdAt});
}

/// @nodoc
class __$$FeeHeadImplCopyWithImpl<$Res>
    extends _$FeeHeadCopyWithImpl<$Res, _$FeeHeadImpl>
    implements _$$FeeHeadImplCopyWith<$Res> {
  __$$FeeHeadImplCopyWithImpl(
      _$FeeHeadImpl _value, $Res Function(_$FeeHeadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? name = null,
    Object? code = freezed,
    Object? description = freezed,
    Object? isRecurring = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$FeeHeadImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      isRecurring: null == isRecurring
          ? _value.isRecurring
          : isRecurring // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeeHeadImpl implements _FeeHead {
  const _$FeeHeadImpl(
      {required this.id,
      required this.tenantId,
      required this.name,
      this.code,
      this.description,
      this.isRecurring = true,
      this.createdAt});

  factory _$FeeHeadImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeeHeadImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String name;
  @override
  final String? code;
  @override
  final String? description;
  @override
  @JsonKey()
  final bool isRecurring;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'FeeHead(id: $id, tenantId: $tenantId, name: $name, code: $code, description: $description, isRecurring: $isRecurring, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeeHeadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.isRecurring, isRecurring) ||
                other.isRecurring == isRecurring) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, tenantId, name, code,
      description, isRecurring, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeeHeadImplCopyWith<_$FeeHeadImpl> get copyWith =>
      __$$FeeHeadImplCopyWithImpl<_$FeeHeadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeeHeadImplToJson(
      this,
    );
  }
}

abstract class _FeeHead implements FeeHead {
  const factory _FeeHead(
      {required final String id,
      required final String tenantId,
      required final String name,
      final String? code,
      final String? description,
      final bool isRecurring,
      final DateTime? createdAt}) = _$FeeHeadImpl;

  factory _FeeHead.fromJson(Map<String, dynamic> json) = _$FeeHeadImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get name;
  @override
  String? get code;
  @override
  String? get description;
  @override
  bool get isRecurring;
  @override
  DateTime? get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$FeeHeadImplCopyWith<_$FeeHeadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeeStructure _$FeeStructureFromJson(Map<String, dynamic> json) {
  return _FeeStructure.fromJson(json);
}

/// @nodoc
mixin _$FeeStructure {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  String get classId => throw _privateConstructorUsedError;
  String get feeHeadId => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  String? get termId => throw _privateConstructorUsedError;
  bool get isMandatory => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get feeHeadName => throw _privateConstructorUsedError;
  String? get className => throw _privateConstructorUsedError;
  String? get academicYearName => throw _privateConstructorUsedError;
  String? get termName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeeStructureCopyWith<FeeStructure> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeeStructureCopyWith<$Res> {
  factory $FeeStructureCopyWith(
          FeeStructure value, $Res Function(FeeStructure) then) =
      _$FeeStructureCopyWithImpl<$Res, FeeStructure>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String academicYearId,
      String classId,
      String feeHeadId,
      double amount,
      DateTime? dueDate,
      String? termId,
      bool isMandatory,
      DateTime? createdAt,
      String? feeHeadName,
      String? className,
      String? academicYearName,
      String? termName});
}

/// @nodoc
class _$FeeStructureCopyWithImpl<$Res, $Val extends FeeStructure>
    implements $FeeStructureCopyWith<$Res> {
  _$FeeStructureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? academicYearId = null,
    Object? classId = null,
    Object? feeHeadId = null,
    Object? amount = null,
    Object? dueDate = freezed,
    Object? termId = freezed,
    Object? isMandatory = null,
    Object? createdAt = freezed,
    Object? feeHeadName = freezed,
    Object? className = freezed,
    Object? academicYearName = freezed,
    Object? termName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      feeHeadId: null == feeHeadId
          ? _value.feeHeadId
          : feeHeadId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      isMandatory: null == isMandatory
          ? _value.isMandatory
          : isMandatory // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      feeHeadName: freezed == feeHeadName
          ? _value.feeHeadName
          : feeHeadName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeeStructureImplCopyWith<$Res>
    implements $FeeStructureCopyWith<$Res> {
  factory _$$FeeStructureImplCopyWith(
          _$FeeStructureImpl value, $Res Function(_$FeeStructureImpl) then) =
      __$$FeeStructureImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String academicYearId,
      String classId,
      String feeHeadId,
      double amount,
      DateTime? dueDate,
      String? termId,
      bool isMandatory,
      DateTime? createdAt,
      String? feeHeadName,
      String? className,
      String? academicYearName,
      String? termName});
}

/// @nodoc
class __$$FeeStructureImplCopyWithImpl<$Res>
    extends _$FeeStructureCopyWithImpl<$Res, _$FeeStructureImpl>
    implements _$$FeeStructureImplCopyWith<$Res> {
  __$$FeeStructureImplCopyWithImpl(
      _$FeeStructureImpl _value, $Res Function(_$FeeStructureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? academicYearId = null,
    Object? classId = null,
    Object? feeHeadId = null,
    Object? amount = null,
    Object? dueDate = freezed,
    Object? termId = freezed,
    Object? isMandatory = null,
    Object? createdAt = freezed,
    Object? feeHeadName = freezed,
    Object? className = freezed,
    Object? academicYearName = freezed,
    Object? termName = freezed,
  }) {
    return _then(_$FeeStructureImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      classId: null == classId
          ? _value.classId
          : classId // ignore: cast_nullable_to_non_nullable
              as String,
      feeHeadId: null == feeHeadId
          ? _value.feeHeadId
          : feeHeadId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: freezed == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      isMandatory: null == isMandatory
          ? _value.isMandatory
          : isMandatory // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      feeHeadName: freezed == feeHeadName
          ? _value.feeHeadName
          : feeHeadName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeeStructureImpl implements _FeeStructure {
  const _$FeeStructureImpl(
      {required this.id,
      required this.tenantId,
      required this.academicYearId,
      required this.classId,
      required this.feeHeadId,
      required this.amount,
      this.dueDate,
      this.termId,
      this.isMandatory = true,
      this.createdAt,
      this.feeHeadName,
      this.className,
      this.academicYearName,
      this.termName});

  factory _$FeeStructureImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeeStructureImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String academicYearId;
  @override
  final String classId;
  @override
  final String feeHeadId;
  @override
  final double amount;
  @override
  final DateTime? dueDate;
  @override
  final String? termId;
  @override
  @JsonKey()
  final bool isMandatory;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? feeHeadName;
  @override
  final String? className;
  @override
  final String? academicYearName;
  @override
  final String? termName;

  @override
  String toString() {
    return 'FeeStructure(id: $id, tenantId: $tenantId, academicYearId: $academicYearId, classId: $classId, feeHeadId: $feeHeadId, amount: $amount, dueDate: $dueDate, termId: $termId, isMandatory: $isMandatory, createdAt: $createdAt, feeHeadName: $feeHeadName, className: $className, academicYearName: $academicYearName, termName: $termName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeeStructureImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.classId, classId) || other.classId == classId) &&
            (identical(other.feeHeadId, feeHeadId) ||
                other.feeHeadId == feeHeadId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.termId, termId) || other.termId == termId) &&
            (identical(other.isMandatory, isMandatory) ||
                other.isMandatory == isMandatory) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.feeHeadName, feeHeadName) ||
                other.feeHeadName == feeHeadName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.academicYearName, academicYearName) ||
                other.academicYearName == academicYearName) &&
            (identical(other.termName, termName) ||
                other.termName == termName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      academicYearId,
      classId,
      feeHeadId,
      amount,
      dueDate,
      termId,
      isMandatory,
      createdAt,
      feeHeadName,
      className,
      academicYearName,
      termName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeeStructureImplCopyWith<_$FeeStructureImpl> get copyWith =>
      __$$FeeStructureImplCopyWithImpl<_$FeeStructureImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeeStructureImplToJson(
      this,
    );
  }
}

abstract class _FeeStructure implements FeeStructure {
  const factory _FeeStructure(
      {required final String id,
      required final String tenantId,
      required final String academicYearId,
      required final String classId,
      required final String feeHeadId,
      required final double amount,
      final DateTime? dueDate,
      final String? termId,
      final bool isMandatory,
      final DateTime? createdAt,
      final String? feeHeadName,
      final String? className,
      final String? academicYearName,
      final String? termName}) = _$FeeStructureImpl;

  factory _FeeStructure.fromJson(Map<String, dynamic> json) =
      _$FeeStructureImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get academicYearId;
  @override
  String get classId;
  @override
  String get feeHeadId;
  @override
  double get amount;
  @override
  DateTime? get dueDate;
  @override
  String? get termId;
  @override
  bool get isMandatory;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get feeHeadName;
  @override
  String? get className;
  @override
  String? get academicYearName;
  @override
  String? get termName;
  @override
  @JsonKey(ignore: true)
  _$$FeeStructureImplCopyWith<_$FeeStructureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Invoice _$InvoiceFromJson(Map<String, dynamic> json) {
  return _Invoice.fromJson(json);
}

/// @nodoc
mixin _$Invoice {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get invoiceNumber => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  String? get termId => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  double get paidAmount => throw _privateConstructorUsedError;
  DateTime get dueDate => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get generatedBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError; // Joined data
  String? get studentName => throw _privateConstructorUsedError;
  String? get admissionNumber => throw _privateConstructorUsedError;
  String? get sectionName => throw _privateConstructorUsedError;
  String? get className => throw _privateConstructorUsedError;
  String? get academicYearName => throw _privateConstructorUsedError;
  String? get termName => throw _privateConstructorUsedError;
  List<InvoiceItem>? get items => throw _privateConstructorUsedError;
  List<Payment>? get payments => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String invoiceNumber,
      String studentId,
      String academicYearId,
      String? termId,
      double totalAmount,
      double discountAmount,
      double paidAmount,
      DateTime dueDate,
      String status,
      String? notes,
      String? generatedBy,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? sectionName,
      String? className,
      String? academicYearName,
      String? termName,
      List<InvoiceItem>? items,
      List<Payment>? payments});
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? invoiceNumber = null,
    Object? studentId = null,
    Object? academicYearId = null,
    Object? termId = freezed,
    Object? totalAmount = null,
    Object? discountAmount = null,
    Object? paidAmount = null,
    Object? dueDate = null,
    Object? status = null,
    Object? notes = freezed,
    Object? generatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
    Object? academicYearName = freezed,
    Object? termName = freezed,
    Object? items = freezed,
    Object? payments = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceNumber: null == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _value.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedBy: freezed == generatedBy
          ? _value.generatedBy
          : generatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
      admissionNumber: freezed == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InvoiceItem>?,
      payments: freezed == payments
          ? _value.payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
          _$InvoiceImpl value, $Res Function(_$InvoiceImpl) then) =
      __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String invoiceNumber,
      String studentId,
      String academicYearId,
      String? termId,
      double totalAmount,
      double discountAmount,
      double paidAmount,
      DateTime dueDate,
      String status,
      String? notes,
      String? generatedBy,
      DateTime? createdAt,
      DateTime? updatedAt,
      String? studentName,
      String? admissionNumber,
      String? sectionName,
      String? className,
      String? academicYearName,
      String? termName,
      List<InvoiceItem>? items,
      List<Payment>? payments});
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
      _$InvoiceImpl _value, $Res Function(_$InvoiceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? invoiceNumber = null,
    Object? studentId = null,
    Object? academicYearId = null,
    Object? termId = freezed,
    Object? totalAmount = null,
    Object? discountAmount = null,
    Object? paidAmount = null,
    Object? dueDate = null,
    Object? status = null,
    Object? notes = freezed,
    Object? generatedBy = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? studentName = freezed,
    Object? admissionNumber = freezed,
    Object? sectionName = freezed,
    Object? className = freezed,
    Object? academicYearName = freezed,
    Object? termName = freezed,
    Object? items = freezed,
    Object? payments = freezed,
  }) {
    return _then(_$InvoiceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceNumber: null == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      termId: freezed == termId
          ? _value.termId
          : termId // ignore: cast_nullable_to_non_nullable
              as String?,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      paidAmount: null == paidAmount
          ? _value.paidAmount
          : paidAmount // ignore: cast_nullable_to_non_nullable
              as double,
      dueDate: null == dueDate
          ? _value.dueDate
          : dueDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedBy: freezed == generatedBy
          ? _value.generatedBy
          : generatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
      admissionNumber: freezed == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      sectionName: freezed == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String?,
      className: freezed == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String?,
      academicYearName: freezed == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String?,
      termName: freezed == termName
          ? _value.termName
          : termName // ignore: cast_nullable_to_non_nullable
              as String?,
      items: freezed == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<InvoiceItem>?,
      payments: freezed == payments
          ? _value._payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl(
      {required this.id,
      required this.tenantId,
      required this.invoiceNumber,
      required this.studentId,
      required this.academicYearId,
      this.termId,
      required this.totalAmount,
      this.discountAmount = 0,
      this.paidAmount = 0,
      required this.dueDate,
      this.status = 'pending',
      this.notes,
      this.generatedBy,
      this.createdAt,
      this.updatedAt,
      this.studentName,
      this.admissionNumber,
      this.sectionName,
      this.className,
      this.academicYearName,
      this.termName,
      final List<InvoiceItem>? items,
      final List<Payment>? payments})
      : _items = items,
        _payments = payments;

  factory _$InvoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String invoiceNumber;
  @override
  final String studentId;
  @override
  final String academicYearId;
  @override
  final String? termId;
  @override
  final double totalAmount;
  @override
  @JsonKey()
  final double discountAmount;
  @override
  @JsonKey()
  final double paidAmount;
  @override
  final DateTime dueDate;
  @override
  @JsonKey()
  final String status;
  @override
  final String? notes;
  @override
  final String? generatedBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
// Joined data
  @override
  final String? studentName;
  @override
  final String? admissionNumber;
  @override
  final String? sectionName;
  @override
  final String? className;
  @override
  final String? academicYearName;
  @override
  final String? termName;
  final List<InvoiceItem>? _items;
  @override
  List<InvoiceItem>? get items {
    final value = _items;
    if (value == null) return null;
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<Payment>? _payments;
  @override
  List<Payment>? get payments {
    final value = _payments;
    if (value == null) return null;
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Invoice(id: $id, tenantId: $tenantId, invoiceNumber: $invoiceNumber, studentId: $studentId, academicYearId: $academicYearId, termId: $termId, totalAmount: $totalAmount, discountAmount: $discountAmount, paidAmount: $paidAmount, dueDate: $dueDate, status: $status, notes: $notes, generatedBy: $generatedBy, createdAt: $createdAt, updatedAt: $updatedAt, studentName: $studentName, admissionNumber: $admissionNumber, sectionName: $sectionName, className: $className, academicYearName: $academicYearName, termName: $termName, items: $items, payments: $payments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.termId, termId) || other.termId == termId) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.paidAmount, paidAmount) ||
                other.paidAmount == paidAmount) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.generatedBy, generatedBy) ||
                other.generatedBy == generatedBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.academicYearName, academicYearName) ||
                other.academicYearName == academicYearName) &&
            (identical(other.termName, termName) ||
                other.termName == termName) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            const DeepCollectionEquality().equals(other._payments, _payments));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        tenantId,
        invoiceNumber,
        studentId,
        academicYearId,
        termId,
        totalAmount,
        discountAmount,
        paidAmount,
        dueDate,
        status,
        notes,
        generatedBy,
        createdAt,
        updatedAt,
        studentName,
        admissionNumber,
        sectionName,
        className,
        academicYearName,
        termName,
        const DeepCollectionEquality().hash(_items),
        const DeepCollectionEquality().hash(_payments)
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceImplToJson(
      this,
    );
  }
}

abstract class _Invoice implements Invoice {
  const factory _Invoice(
      {required final String id,
      required final String tenantId,
      required final String invoiceNumber,
      required final String studentId,
      required final String academicYearId,
      final String? termId,
      required final double totalAmount,
      final double discountAmount,
      final double paidAmount,
      required final DateTime dueDate,
      final String status,
      final String? notes,
      final String? generatedBy,
      final DateTime? createdAt,
      final DateTime? updatedAt,
      final String? studentName,
      final String? admissionNumber,
      final String? sectionName,
      final String? className,
      final String? academicYearName,
      final String? termName,
      final List<InvoiceItem>? items,
      final List<Payment>? payments}) = _$InvoiceImpl;

  factory _Invoice.fromJson(Map<String, dynamic> json) = _$InvoiceImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get invoiceNumber;
  @override
  String get studentId;
  @override
  String get academicYearId;
  @override
  String? get termId;
  @override
  double get totalAmount;
  @override
  double get discountAmount;
  @override
  double get paidAmount;
  @override
  DateTime get dueDate;
  @override
  String get status;
  @override
  String? get notes;
  @override
  String? get generatedBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override // Joined data
  String? get studentName;
  @override
  String? get admissionNumber;
  @override
  String? get sectionName;
  @override
  String? get className;
  @override
  String? get academicYearName;
  @override
  String? get termName;
  @override
  List<InvoiceItem>? get items;
  @override
  List<Payment>? get payments;
  @override
  @JsonKey(ignore: true)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InvoiceItem _$InvoiceItemFromJson(Map<String, dynamic> json) {
  return _InvoiceItem.fromJson(json);
}

/// @nodoc
mixin _$InvoiceItem {
  String get id => throw _privateConstructorUsedError;
  String get invoiceId => throw _privateConstructorUsedError;
  String get feeHeadId => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  double get discount => throw _privateConstructorUsedError; // Joined data
  String? get feeHeadName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InvoiceItemCopyWith<InvoiceItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceItemCopyWith<$Res> {
  factory $InvoiceItemCopyWith(
          InvoiceItem value, $Res Function(InvoiceItem) then) =
      _$InvoiceItemCopyWithImpl<$Res, InvoiceItem>;
  @useResult
  $Res call(
      {String id,
      String invoiceId,
      String feeHeadId,
      String? description,
      double amount,
      double discount,
      String? feeHeadName});
}

/// @nodoc
class _$InvoiceItemCopyWithImpl<$Res, $Val extends InvoiceItem>
    implements $InvoiceItemCopyWith<$Res> {
  _$InvoiceItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceId = null,
    Object? feeHeadId = null,
    Object? description = freezed,
    Object? amount = null,
    Object? discount = null,
    Object? feeHeadName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      feeHeadId: null == feeHeadId
          ? _value.feeHeadId
          : feeHeadId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      feeHeadName: freezed == feeHeadName
          ? _value.feeHeadName
          : feeHeadName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InvoiceItemImplCopyWith<$Res>
    implements $InvoiceItemCopyWith<$Res> {
  factory _$$InvoiceItemImplCopyWith(
          _$InvoiceItemImpl value, $Res Function(_$InvoiceItemImpl) then) =
      __$$InvoiceItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String invoiceId,
      String feeHeadId,
      String? description,
      double amount,
      double discount,
      String? feeHeadName});
}

/// @nodoc
class __$$InvoiceItemImplCopyWithImpl<$Res>
    extends _$InvoiceItemCopyWithImpl<$Res, _$InvoiceItemImpl>
    implements _$$InvoiceItemImplCopyWith<$Res> {
  __$$InvoiceItemImplCopyWithImpl(
      _$InvoiceItemImpl _value, $Res Function(_$InvoiceItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceId = null,
    Object? feeHeadId = null,
    Object? description = freezed,
    Object? amount = null,
    Object? discount = null,
    Object? feeHeadName = freezed,
  }) {
    return _then(_$InvoiceItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      feeHeadId: null == feeHeadId
          ? _value.feeHeadId
          : feeHeadId // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      discount: null == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as double,
      feeHeadName: freezed == feeHeadName
          ? _value.feeHeadName
          : feeHeadName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InvoiceItemImpl implements _InvoiceItem {
  const _$InvoiceItemImpl(
      {required this.id,
      required this.invoiceId,
      required this.feeHeadId,
      this.description,
      required this.amount,
      this.discount = 0,
      this.feeHeadName});

  factory _$InvoiceItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$InvoiceItemImplFromJson(json);

  @override
  final String id;
  @override
  final String invoiceId;
  @override
  final String feeHeadId;
  @override
  final String? description;
  @override
  final double amount;
  @override
  @JsonKey()
  final double discount;
// Joined data
  @override
  final String? feeHeadName;

  @override
  String toString() {
    return 'InvoiceItem(id: $id, invoiceId: $invoiceId, feeHeadId: $feeHeadId, description: $description, amount: $amount, discount: $discount, feeHeadName: $feeHeadName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.invoiceId, invoiceId) ||
                other.invoiceId == invoiceId) &&
            (identical(other.feeHeadId, feeHeadId) ||
                other.feeHeadId == feeHeadId) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.feeHeadName, feeHeadName) ||
                other.feeHeadName == feeHeadName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, invoiceId, feeHeadId,
      description, amount, discount, feeHeadName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      __$$InvoiceItemImplCopyWithImpl<_$InvoiceItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InvoiceItemImplToJson(
      this,
    );
  }
}

abstract class _InvoiceItem implements InvoiceItem {
  const factory _InvoiceItem(
      {required final String id,
      required final String invoiceId,
      required final String feeHeadId,
      final String? description,
      required final double amount,
      final double discount,
      final String? feeHeadName}) = _$InvoiceItemImpl;

  factory _InvoiceItem.fromJson(Map<String, dynamic> json) =
      _$InvoiceItemImpl.fromJson;

  @override
  String get id;
  @override
  String get invoiceId;
  @override
  String get feeHeadId;
  @override
  String? get description;
  @override
  double get amount;
  @override
  double get discount;
  @override // Joined data
  String? get feeHeadName;
  @override
  @JsonKey(ignore: true)
  _$$InvoiceItemImplCopyWith<_$InvoiceItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Payment _$PaymentFromJson(Map<String, dynamic> json) {
  return _Payment.fromJson(json);
}

/// @nodoc
mixin _$Payment {
  String get id => throw _privateConstructorUsedError;
  String get tenantId => throw _privateConstructorUsedError;
  String get invoiceId => throw _privateConstructorUsedError;
  String get paymentNumber => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get paymentMethod => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get transactionId => throw _privateConstructorUsedError;
  Map<String, dynamic>? get gatewayResponse =>
      throw _privateConstructorUsedError;
  DateTime? get paidAt => throw _privateConstructorUsedError;
  String? get receivedBy => throw _privateConstructorUsedError;
  String? get remarks => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError; // Joined data
  String? get receivedByName => throw _privateConstructorUsedError;
  String? get invoiceNumber => throw _privateConstructorUsedError;
  String? get studentName => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaymentCopyWith<Payment> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) then) =
      _$PaymentCopyWithImpl<$Res, Payment>;
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String invoiceId,
      String paymentNumber,
      double amount,
      String paymentMethod,
      String status,
      String? transactionId,
      Map<String, dynamic>? gatewayResponse,
      DateTime? paidAt,
      String? receivedBy,
      String? remarks,
      DateTime? createdAt,
      String? receivedByName,
      String? invoiceNumber,
      String? studentName});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res, $Val extends Payment>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? invoiceId = null,
    Object? paymentNumber = null,
    Object? amount = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? transactionId = freezed,
    Object? gatewayResponse = freezed,
    Object? paidAt = freezed,
    Object? receivedBy = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? receivedByName = freezed,
    Object? invoiceNumber = freezed,
    Object? studentName = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      paymentNumber: null == paymentNumber
          ? _value.paymentNumber
          : paymentNumber // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatewayResponse: freezed == gatewayResponse
          ? _value.gatewayResponse
          : gatewayResponse // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      receivedBy: freezed == receivedBy
          ? _value.receivedBy
          : receivedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      receivedByName: freezed == receivedByName
          ? _value.receivedByName
          : receivedByName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentImplCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$$PaymentImplCopyWith(
          _$PaymentImpl value, $Res Function(_$PaymentImpl) then) =
      __$$PaymentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String tenantId,
      String invoiceId,
      String paymentNumber,
      double amount,
      String paymentMethod,
      String status,
      String? transactionId,
      Map<String, dynamic>? gatewayResponse,
      DateTime? paidAt,
      String? receivedBy,
      String? remarks,
      DateTime? createdAt,
      String? receivedByName,
      String? invoiceNumber,
      String? studentName});
}

/// @nodoc
class __$$PaymentImplCopyWithImpl<$Res>
    extends _$PaymentCopyWithImpl<$Res, _$PaymentImpl>
    implements _$$PaymentImplCopyWith<$Res> {
  __$$PaymentImplCopyWithImpl(
      _$PaymentImpl _value, $Res Function(_$PaymentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tenantId = null,
    Object? invoiceId = null,
    Object? paymentNumber = null,
    Object? amount = null,
    Object? paymentMethod = null,
    Object? status = null,
    Object? transactionId = freezed,
    Object? gatewayResponse = freezed,
    Object? paidAt = freezed,
    Object? receivedBy = freezed,
    Object? remarks = freezed,
    Object? createdAt = freezed,
    Object? receivedByName = freezed,
    Object? invoiceNumber = freezed,
    Object? studentName = freezed,
  }) {
    return _then(_$PaymentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      paymentNumber: null == paymentNumber
          ? _value.paymentNumber
          : paymentNumber // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      paymentMethod: null == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
      gatewayResponse: freezed == gatewayResponse
          ? _value._gatewayResponse
          : gatewayResponse // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      paidAt: freezed == paidAt
          ? _value.paidAt
          : paidAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      receivedBy: freezed == receivedBy
          ? _value.receivedBy
          : receivedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      remarks: freezed == remarks
          ? _value.remarks
          : remarks // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      receivedByName: freezed == receivedByName
          ? _value.receivedByName
          : receivedByName // ignore: cast_nullable_to_non_nullable
              as String?,
      invoiceNumber: freezed == invoiceNumber
          ? _value.invoiceNumber
          : invoiceNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      studentName: freezed == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentImpl implements _Payment {
  const _$PaymentImpl(
      {required this.id,
      required this.tenantId,
      required this.invoiceId,
      required this.paymentNumber,
      required this.amount,
      required this.paymentMethod,
      this.status = 'pending',
      this.transactionId,
      final Map<String, dynamic>? gatewayResponse,
      this.paidAt,
      this.receivedBy,
      this.remarks,
      this.createdAt,
      this.receivedByName,
      this.invoiceNumber,
      this.studentName})
      : _gatewayResponse = gatewayResponse;

  factory _$PaymentImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentImplFromJson(json);

  @override
  final String id;
  @override
  final String tenantId;
  @override
  final String invoiceId;
  @override
  final String paymentNumber;
  @override
  final double amount;
  @override
  final String paymentMethod;
  @override
  @JsonKey()
  final String status;
  @override
  final String? transactionId;
  final Map<String, dynamic>? _gatewayResponse;
  @override
  Map<String, dynamic>? get gatewayResponse {
    final value = _gatewayResponse;
    if (value == null) return null;
    if (_gatewayResponse is EqualUnmodifiableMapView) return _gatewayResponse;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final DateTime? paidAt;
  @override
  final String? receivedBy;
  @override
  final String? remarks;
  @override
  final DateTime? createdAt;
// Joined data
  @override
  final String? receivedByName;
  @override
  final String? invoiceNumber;
  @override
  final String? studentName;

  @override
  String toString() {
    return 'Payment(id: $id, tenantId: $tenantId, invoiceId: $invoiceId, paymentNumber: $paymentNumber, amount: $amount, paymentMethod: $paymentMethod, status: $status, transactionId: $transactionId, gatewayResponse: $gatewayResponse, paidAt: $paidAt, receivedBy: $receivedBy, remarks: $remarks, createdAt: $createdAt, receivedByName: $receivedByName, invoiceNumber: $invoiceNumber, studentName: $studentName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.invoiceId, invoiceId) ||
                other.invoiceId == invoiceId) &&
            (identical(other.paymentNumber, paymentNumber) ||
                other.paymentNumber == paymentNumber) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            const DeepCollectionEquality()
                .equals(other._gatewayResponse, _gatewayResponse) &&
            (identical(other.paidAt, paidAt) || other.paidAt == paidAt) &&
            (identical(other.receivedBy, receivedBy) ||
                other.receivedBy == receivedBy) &&
            (identical(other.remarks, remarks) || other.remarks == remarks) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.receivedByName, receivedByName) ||
                other.receivedByName == receivedByName) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      tenantId,
      invoiceId,
      paymentNumber,
      amount,
      paymentMethod,
      status,
      transactionId,
      const DeepCollectionEquality().hash(_gatewayResponse),
      paidAt,
      receivedBy,
      remarks,
      createdAt,
      receivedByName,
      invoiceNumber,
      studentName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      __$$PaymentImplCopyWithImpl<_$PaymentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentImplToJson(
      this,
    );
  }
}

abstract class _Payment implements Payment {
  const factory _Payment(
      {required final String id,
      required final String tenantId,
      required final String invoiceId,
      required final String paymentNumber,
      required final double amount,
      required final String paymentMethod,
      final String status,
      final String? transactionId,
      final Map<String, dynamic>? gatewayResponse,
      final DateTime? paidAt,
      final String? receivedBy,
      final String? remarks,
      final DateTime? createdAt,
      final String? receivedByName,
      final String? invoiceNumber,
      final String? studentName}) = _$PaymentImpl;

  factory _Payment.fromJson(Map<String, dynamic> json) = _$PaymentImpl.fromJson;

  @override
  String get id;
  @override
  String get tenantId;
  @override
  String get invoiceId;
  @override
  String get paymentNumber;
  @override
  double get amount;
  @override
  String get paymentMethod;
  @override
  String get status;
  @override
  String? get transactionId;
  @override
  Map<String, dynamic>? get gatewayResponse;
  @override
  DateTime? get paidAt;
  @override
  String? get receivedBy;
  @override
  String? get remarks;
  @override
  DateTime? get createdAt;
  @override // Joined data
  String? get receivedByName;
  @override
  String? get invoiceNumber;
  @override
  String? get studentName;
  @override
  @JsonKey(ignore: true)
  _$$PaymentImplCopyWith<_$PaymentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FeeSummary _$FeeSummaryFromJson(Map<String, dynamic> json) {
  return _FeeSummary.fromJson(json);
}

/// @nodoc
mixin _$FeeSummary {
  String get tenantId => throw _privateConstructorUsedError;
  String get studentId => throw _privateConstructorUsedError;
  String get studentName => throw _privateConstructorUsedError;
  String get admissionNumber => throw _privateConstructorUsedError;
  String get sectionId => throw _privateConstructorUsedError;
  String get sectionName => throw _privateConstructorUsedError;
  String get className => throw _privateConstructorUsedError;
  String get academicYearId => throw _privateConstructorUsedError;
  String get academicYearName => throw _privateConstructorUsedError;
  double get totalFee => throw _privateConstructorUsedError;
  double get totalDiscount => throw _privateConstructorUsedError;
  double get totalPaid => throw _privateConstructorUsedError;
  double get totalPending => throw _privateConstructorUsedError;
  int get totalInvoices => throw _privateConstructorUsedError;
  int get paidInvoices => throw _privateConstructorUsedError;
  int get pendingInvoices => throw _privateConstructorUsedError;
  int get overdueInvoices => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FeeSummaryCopyWith<FeeSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeeSummaryCopyWith<$Res> {
  factory $FeeSummaryCopyWith(
          FeeSummary value, $Res Function(FeeSummary) then) =
      _$FeeSummaryCopyWithImpl<$Res, FeeSummary>;
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String className,
      String academicYearId,
      String academicYearName,
      double totalFee,
      double totalDiscount,
      double totalPaid,
      double totalPending,
      int totalInvoices,
      int paidInvoices,
      int pendingInvoices,
      int overdueInvoices});
}

/// @nodoc
class _$FeeSummaryCopyWithImpl<$Res, $Val extends FeeSummary>
    implements $FeeSummaryCopyWith<$Res> {
  _$FeeSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? academicYearId = null,
    Object? academicYearName = null,
    Object? totalFee = null,
    Object? totalDiscount = null,
    Object? totalPaid = null,
    Object? totalPending = null,
    Object? totalInvoices = null,
    Object? paidInvoices = null,
    Object? pendingInvoices = null,
    Object? overdueInvoices = null,
  }) {
    return _then(_value.copyWith(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearName: null == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String,
      totalFee: null == totalFee
          ? _value.totalFee
          : totalFee // ignore: cast_nullable_to_non_nullable
              as double,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalPaid: null == totalPaid
          ? _value.totalPaid
          : totalPaid // ignore: cast_nullable_to_non_nullable
              as double,
      totalPending: null == totalPending
          ? _value.totalPending
          : totalPending // ignore: cast_nullable_to_non_nullable
              as double,
      totalInvoices: null == totalInvoices
          ? _value.totalInvoices
          : totalInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      paidInvoices: null == paidInvoices
          ? _value.paidInvoices
          : paidInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      pendingInvoices: null == pendingInvoices
          ? _value.pendingInvoices
          : pendingInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      overdueInvoices: null == overdueInvoices
          ? _value.overdueInvoices
          : overdueInvoices // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeeSummaryImplCopyWith<$Res>
    implements $FeeSummaryCopyWith<$Res> {
  factory _$$FeeSummaryImplCopyWith(
          _$FeeSummaryImpl value, $Res Function(_$FeeSummaryImpl) then) =
      __$$FeeSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tenantId,
      String studentId,
      String studentName,
      String admissionNumber,
      String sectionId,
      String sectionName,
      String className,
      String academicYearId,
      String academicYearName,
      double totalFee,
      double totalDiscount,
      double totalPaid,
      double totalPending,
      int totalInvoices,
      int paidInvoices,
      int pendingInvoices,
      int overdueInvoices});
}

/// @nodoc
class __$$FeeSummaryImplCopyWithImpl<$Res>
    extends _$FeeSummaryCopyWithImpl<$Res, _$FeeSummaryImpl>
    implements _$$FeeSummaryImplCopyWith<$Res> {
  __$$FeeSummaryImplCopyWithImpl(
      _$FeeSummaryImpl _value, $Res Function(_$FeeSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tenantId = null,
    Object? studentId = null,
    Object? studentName = null,
    Object? admissionNumber = null,
    Object? sectionId = null,
    Object? sectionName = null,
    Object? className = null,
    Object? academicYearId = null,
    Object? academicYearName = null,
    Object? totalFee = null,
    Object? totalDiscount = null,
    Object? totalPaid = null,
    Object? totalPending = null,
    Object? totalInvoices = null,
    Object? paidInvoices = null,
    Object? pendingInvoices = null,
    Object? overdueInvoices = null,
  }) {
    return _then(_$FeeSummaryImpl(
      tenantId: null == tenantId
          ? _value.tenantId
          : tenantId // ignore: cast_nullable_to_non_nullable
              as String,
      studentId: null == studentId
          ? _value.studentId
          : studentId // ignore: cast_nullable_to_non_nullable
              as String,
      studentName: null == studentName
          ? _value.studentName
          : studentName // ignore: cast_nullable_to_non_nullable
              as String,
      admissionNumber: null == admissionNumber
          ? _value.admissionNumber
          : admissionNumber // ignore: cast_nullable_to_non_nullable
              as String,
      sectionId: null == sectionId
          ? _value.sectionId
          : sectionId // ignore: cast_nullable_to_non_nullable
              as String,
      sectionName: null == sectionName
          ? _value.sectionName
          : sectionName // ignore: cast_nullable_to_non_nullable
              as String,
      className: null == className
          ? _value.className
          : className // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearId: null == academicYearId
          ? _value.academicYearId
          : academicYearId // ignore: cast_nullable_to_non_nullable
              as String,
      academicYearName: null == academicYearName
          ? _value.academicYearName
          : academicYearName // ignore: cast_nullable_to_non_nullable
              as String,
      totalFee: null == totalFee
          ? _value.totalFee
          : totalFee // ignore: cast_nullable_to_non_nullable
              as double,
      totalDiscount: null == totalDiscount
          ? _value.totalDiscount
          : totalDiscount // ignore: cast_nullable_to_non_nullable
              as double,
      totalPaid: null == totalPaid
          ? _value.totalPaid
          : totalPaid // ignore: cast_nullable_to_non_nullable
              as double,
      totalPending: null == totalPending
          ? _value.totalPending
          : totalPending // ignore: cast_nullable_to_non_nullable
              as double,
      totalInvoices: null == totalInvoices
          ? _value.totalInvoices
          : totalInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      paidInvoices: null == paidInvoices
          ? _value.paidInvoices
          : paidInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      pendingInvoices: null == pendingInvoices
          ? _value.pendingInvoices
          : pendingInvoices // ignore: cast_nullable_to_non_nullable
              as int,
      overdueInvoices: null == overdueInvoices
          ? _value.overdueInvoices
          : overdueInvoices // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeeSummaryImpl implements _FeeSummary {
  const _$FeeSummaryImpl(
      {required this.tenantId,
      required this.studentId,
      required this.studentName,
      required this.admissionNumber,
      required this.sectionId,
      required this.sectionName,
      required this.className,
      required this.academicYearId,
      required this.academicYearName,
      required this.totalFee,
      required this.totalDiscount,
      required this.totalPaid,
      required this.totalPending,
      required this.totalInvoices,
      required this.paidInvoices,
      required this.pendingInvoices,
      required this.overdueInvoices});

  factory _$FeeSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeeSummaryImplFromJson(json);

  @override
  final String tenantId;
  @override
  final String studentId;
  @override
  final String studentName;
  @override
  final String admissionNumber;
  @override
  final String sectionId;
  @override
  final String sectionName;
  @override
  final String className;
  @override
  final String academicYearId;
  @override
  final String academicYearName;
  @override
  final double totalFee;
  @override
  final double totalDiscount;
  @override
  final double totalPaid;
  @override
  final double totalPending;
  @override
  final int totalInvoices;
  @override
  final int paidInvoices;
  @override
  final int pendingInvoices;
  @override
  final int overdueInvoices;

  @override
  String toString() {
    return 'FeeSummary(tenantId: $tenantId, studentId: $studentId, studentName: $studentName, admissionNumber: $admissionNumber, sectionId: $sectionId, sectionName: $sectionName, className: $className, academicYearId: $academicYearId, academicYearName: $academicYearName, totalFee: $totalFee, totalDiscount: $totalDiscount, totalPaid: $totalPaid, totalPending: $totalPending, totalInvoices: $totalInvoices, paidInvoices: $paidInvoices, pendingInvoices: $pendingInvoices, overdueInvoices: $overdueInvoices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeeSummaryImpl &&
            (identical(other.tenantId, tenantId) ||
                other.tenantId == tenantId) &&
            (identical(other.studentId, studentId) ||
                other.studentId == studentId) &&
            (identical(other.studentName, studentName) ||
                other.studentName == studentName) &&
            (identical(other.admissionNumber, admissionNumber) ||
                other.admissionNumber == admissionNumber) &&
            (identical(other.sectionId, sectionId) ||
                other.sectionId == sectionId) &&
            (identical(other.sectionName, sectionName) ||
                other.sectionName == sectionName) &&
            (identical(other.className, className) ||
                other.className == className) &&
            (identical(other.academicYearId, academicYearId) ||
                other.academicYearId == academicYearId) &&
            (identical(other.academicYearName, academicYearName) ||
                other.academicYearName == academicYearName) &&
            (identical(other.totalFee, totalFee) ||
                other.totalFee == totalFee) &&
            (identical(other.totalDiscount, totalDiscount) ||
                other.totalDiscount == totalDiscount) &&
            (identical(other.totalPaid, totalPaid) ||
                other.totalPaid == totalPaid) &&
            (identical(other.totalPending, totalPending) ||
                other.totalPending == totalPending) &&
            (identical(other.totalInvoices, totalInvoices) ||
                other.totalInvoices == totalInvoices) &&
            (identical(other.paidInvoices, paidInvoices) ||
                other.paidInvoices == paidInvoices) &&
            (identical(other.pendingInvoices, pendingInvoices) ||
                other.pendingInvoices == pendingInvoices) &&
            (identical(other.overdueInvoices, overdueInvoices) ||
                other.overdueInvoices == overdueInvoices));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      tenantId,
      studentId,
      studentName,
      admissionNumber,
      sectionId,
      sectionName,
      className,
      academicYearId,
      academicYearName,
      totalFee,
      totalDiscount,
      totalPaid,
      totalPending,
      totalInvoices,
      paidInvoices,
      pendingInvoices,
      overdueInvoices);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FeeSummaryImplCopyWith<_$FeeSummaryImpl> get copyWith =>
      __$$FeeSummaryImplCopyWithImpl<_$FeeSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeeSummaryImplToJson(
      this,
    );
  }
}

abstract class _FeeSummary implements FeeSummary {
  const factory _FeeSummary(
      {required final String tenantId,
      required final String studentId,
      required final String studentName,
      required final String admissionNumber,
      required final String sectionId,
      required final String sectionName,
      required final String className,
      required final String academicYearId,
      required final String academicYearName,
      required final double totalFee,
      required final double totalDiscount,
      required final double totalPaid,
      required final double totalPending,
      required final int totalInvoices,
      required final int paidInvoices,
      required final int pendingInvoices,
      required final int overdueInvoices}) = _$FeeSummaryImpl;

  factory _FeeSummary.fromJson(Map<String, dynamic> json) =
      _$FeeSummaryImpl.fromJson;

  @override
  String get tenantId;
  @override
  String get studentId;
  @override
  String get studentName;
  @override
  String get admissionNumber;
  @override
  String get sectionId;
  @override
  String get sectionName;
  @override
  String get className;
  @override
  String get academicYearId;
  @override
  String get academicYearName;
  @override
  double get totalFee;
  @override
  double get totalDiscount;
  @override
  double get totalPaid;
  @override
  double get totalPending;
  @override
  int get totalInvoices;
  @override
  int get paidInvoices;
  @override
  int get pendingInvoices;
  @override
  int get overdueInvoices;
  @override
  @JsonKey(ignore: true)
  _$$FeeSummaryImplCopyWith<_$FeeSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

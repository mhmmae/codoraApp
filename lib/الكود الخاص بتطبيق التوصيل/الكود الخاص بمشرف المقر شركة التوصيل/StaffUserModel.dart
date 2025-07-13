// staff_user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum StaffUserRole {
  platform_admin,   // مشرف المنصة الرئيسي (صاحب التطبيق)
  company_admin,    // مشرف شركة توصيل
  hub_supervisor,   // مشرف مقر تابع لشركة توصيل
  // يمكنك إضافة أدوار أخرى مستقبلًا (مثل: خدمة العملاء)
}

String staffUserRoleToString(StaffUserRole role) => role.toString().split('.').last;

StaffUserRole stringToStaffUserRole(String? roleStr) {
  if (roleStr == null || roleStr.isEmpty) {
    return StaffUserRole.hub_supervisor; // أو أي دور افتراضي مناسب
  }
  return StaffUserRole.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == roleStr.toLowerCase(),
      orElse: () {
        debugPrint("WARNING: Unknown StaffUserRole string '$roleStr', defaulting.");
        return StaffUserRole.hub_supervisor; //  كن حذرًا في القيمة الافتراضية هنا
      });
}

class StaffUserModel {
  final String uid; // نفس UID من Firebase Authentication
  String name;
  String email; // البريد المستخدم لتسجيل الدخول
  String? phoneNumber; // (اختياري، يمكن التحقق منه)
  String? profileImageUrl;
  StaffUserRole role;

  // حقول خاصة بالأدوار
  String? assignedCompanyId; // إذا كان company_admin أو hub_supervisor
  // لـ company_admin، هذا هو companyId للشركة التي يديرها (غالبًا نفس الـ UID)
  // لـ hub_supervisor، هذا هو companyId للشركة التي يتبع لها المقر

  String? assignedHubId;     // فقط لـ hub_supervisor، معرّف المقر الذي يشرف عليه

  List<String>? permissions;   // (متقدم) قائمة بصلاحيات محددة (مثل: 'manage_drivers', 'view_reports')
  // مبدئيًا، الدور (role) سيحدد الصلاحيات العامة.

  bool isActive; // هل هذا الحساب فعال (يمكن لمشرف المنصة أو مشرف الشركة تعطيله)
  Timestamp createdAt;
  Timestamp? lastLoginAt;
  Timestamp? updatedAt;

  StaffUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    required this.role,
    this.assignedCompanyId,
    this.assignedHubId,
    this.permissions,
    this.isActive = true, // افتراضيًا فعال عند الإنشاء
    required this.createdAt,
    this.lastLoginAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // يمكن عدم تخزينه إذا كان اسم المستند
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'role': staffUserRoleToString(role), // تحويل الـ enum إلى String
      'assignedCompanyId': assignedCompanyId,
      'assignedHubId': assignedHubId,
      'permissions': permissions,
      'isActive': isActive,
      'createdAt': createdAt, // FieldValue.serverTimestamp() عند الإنشاء الفعلي
      'lastLoginAt': lastLoginAt, // FieldValue.serverTimestamp() عند تسجيل الدخول
      'updatedAt': FieldValue.serverTimestamp(), // دائمًا
    };
  }

  factory StaffUserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StaffUserModel(
      uid: documentId, // استخدام معرف المستند كـ uid
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      role: stringToStaffUserRole(map['role'] as String?), // تحويل String إلى enum
      assignedCompanyId: map['assignedCompanyId'] as String?,
      assignedHubId: map['assignedHubId'] as String?,
      permissions: (map['permissions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      lastLoginAt: map['lastLoginAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }
}

// اسم المجموعة المقترح في Firestore: "staff_users" أو "admin_users"
// FirebaseX.staffUsersCollection = "staff_users";
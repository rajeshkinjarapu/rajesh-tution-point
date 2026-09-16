import 'package:flutter/material.dart';

enum AppFlavor {
  universal,
  student,
  teacher,
  admin,
}

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String appId;
  final Color primaryColor;
  final Color secondaryColor;
  final LinearGradient brandGradient;
  final List<String> allowedRoles;
  final String defaultRole;
  final String welcomeTitle;
  final String welcomeSubtitle;
  final String idFieldLabel;
  final String idFieldHint;
  final IconData roleIcon;

  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.appId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.brandGradient,
    required this.allowedRoles,
    required this.defaultRole,
    required this.welcomeTitle,
    required this.welcomeSubtitle,
    required this.idFieldLabel,
    required this.idFieldHint,
    required this.roleIcon,
  });

  static AppConfig current = _universalConfig;

  static void initialize(AppFlavor flavor) {
    switch (flavor) {
      case AppFlavor.student:
        current = _studentConfig;
        break;
      case AppFlavor.teacher:
        current = _teacherConfig;
        break;
      case AppFlavor.admin:
        current = _adminConfig;
        break;
      case AppFlavor.universal:
      default:
        current = _universalConfig;
        break;
    }
  }

  static bool get isStudent => current.flavor == AppFlavor.student;
  static bool get isTeacher => current.flavor == AppFlavor.teacher;
  static bool get isAdmin => current.flavor == AppFlavor.admin;
  static bool get isUniversal => current.flavor == AppFlavor.universal;

  // 🎓 Student & Parent App Configuration
  static const AppConfig _studentConfig = AppConfig(
    flavor: AppFlavor.student,
    appName: 'JY - Student',
    appId: 'com.jyschool.erp.student',
    primaryColor: Color(0xFF4F46E5), // Indigo
    secondaryColor: Color(0xFF06B6D4), // Cyan
    brandGradient: LinearGradient(
      colors: [Color(0xFF3730A3), Color(0xFF4F46E5), Color(0xFF06B6D4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    allowedRoles: ['STUDENT', 'PARENT'],
    defaultRole: 'STUDENT',
    welcomeTitle: 'Student & Parent Portal',
    welcomeSubtitle: 'Access attendance, exam hall tickets, results, fee receipts & homework.',
    idFieldLabel: 'Roll No / Student ID / Phone',
    idFieldHint: 'Enter your Roll No or registered phone',
    roleIcon: Icons.school_rounded,
  );

  // 👨‍🏫 Teacher & Staff App Configuration
  static const AppConfig _teacherConfig = AppConfig(
    flavor: AppFlavor.teacher,
    appName: 'JY - Teacher',
    appId: 'com.jyschool.erp.teacher',
    primaryColor: Color(0xFF059669), // Emerald
    secondaryColor: Color(0xFF0D9488), // Teal
    brandGradient: LinearGradient(
      colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    allowedRoles: ['TEACHER'],
    defaultRole: 'TEACHER',
    welcomeTitle: 'Teacher & Staff Workspace',
    welcomeSubtitle: 'Mark daily attendance, assign homework, enter marks & manage class schedule.',
    idFieldLabel: 'Employee ID / Phone / Email',
    idFieldHint: 'Enter your Employee ID or Phone number',
    roleIcon: Icons.badge_rounded,
  );

  // 🏛️ Admin & Management App Configuration
  static const AppConfig _adminConfig = AppConfig(
    flavor: AppFlavor.admin,
    appName: 'JY - Admin',
    appId: 'com.jyschool.erp.admin',
    primaryColor: Color(0xFF1E1B4B), // Deep Slate Navy
    secondaryColor: Color(0xFF7C3AED), // Royal Purple
    brandGradient: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    allowedRoles: ['ADMIN', 'SUPER_ADMIN', 'ACCOUNTANT'],
    defaultRole: 'ADMIN',
    welcomeTitle: 'Admin & Principal Suite',
    welcomeSubtitle: 'Real-time tution metrics, fee collection, staff tracking & approvals.',
    idFieldLabel: 'Admin Email / Phone',
    idFieldHint: 'Enter administrator credentials',
    roleIcon: Icons.admin_panel_settings_rounded,
  );

  // 🌐 Universal / Multi-Role Default
  static const AppConfig _universalConfig = AppConfig(
    flavor: AppFlavor.universal,
    appName: 'Rajesh Tution Point',
    appId: 'com.jyschool.erp',
    primaryColor: Color(0xFF6366F1),
    secondaryColor: Color(0xFFD946EF),
    brandGradient: LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    allowedRoles: ['STUDENT', 'PARENT', 'TEACHER', 'ADMIN', 'SUPER_ADMIN', 'ACCOUNTANT'],
    defaultRole: 'STUDENT',
    welcomeTitle: 'Rajesh Tution Point',
    welcomeSubtitle: 'Next-Generation Tution Management & Communication Platform.',
    idFieldLabel: 'Email / Phone / Roll No',
    idFieldHint: 'Enter your credentials',
    roleIcon: Icons.school_rounded,
  );
}

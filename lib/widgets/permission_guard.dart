import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/permission.dart';
import '../providers/auth_provider.dart';

/// Виджет-обертка для проверки прав доступа
class PermissionGuard extends StatelessWidget {
  final Permission permission;
  final Widget child;
  final Widget? fallback;
  final bool showSnackBar;

  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
    this.showSnackBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.hasPermission(permission)) {
      return child;
    }
    
    if (showSnackBar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Нет прав: ${permission.label}')),
          );
        }
      });
    }
    
    return fallback ?? const SizedBox.shrink();
  }
}

/// Расширение для проверки прав в виджетах
extension PermissionExtension on BuildContext {
  bool hasPermission(Permission permission) {
    final auth = Provider.of<AuthProvider>(this, listen: false);
    return auth.hasPermission(permission);
  }
  
  bool hasAnyPermission(List<Permission> permissions) {
    final auth = Provider.of<AuthProvider>(this, listen: false);
    return auth.hasAnyPermission(permissions);
  }
  
  bool hasAllPermissions(List<Permission> permissions) {
    final auth = Provider.of<AuthProvider>(this, listen: false);
    return auth.hasAllPermissions(permissions);
  }
}

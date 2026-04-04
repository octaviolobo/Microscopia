import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'purchase_service.dart';

/// Busca o CustomerInfo atual
final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return Purchases.getCustomerInfo();
});

/// true se o usuário tem entitlement Pro ativo
final isProProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoProvider);
  return info.whenOrNull(
        data: (ci) => ci.entitlements.active.containsKey(kEntitlementPro),
      ) ??
      false;
});

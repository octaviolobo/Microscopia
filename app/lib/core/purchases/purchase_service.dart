import 'package:purchases_flutter/purchases_flutter.dart';

const _revenueCatApiKey = 'test_EaPfcOeMzFMLpONDjAsBIypkInv';
const kEntitlementPro = 'MicroLaudo Pro';
const kFreeTierLimit = 3;

class PurchaseService {
  static Future<void> init(String? userId) async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(_revenueCatApiKey);
    if (userId != null) config.appUserID = userId;
    await Purchases.configure(config);
  }

  /// Retorna true se o usuário tem acesso Pro
  static Future<bool> isPro() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(kEntitlementPro);
    } catch (_) {
      return false;
    }
  }

  /// Restaura compras anteriores
  static Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(kEntitlementPro);
    } catch (_) {
      return false;
    }
  }

  /// Sincroniza o userId do Supabase com o RevenueCat
  static Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }

  /// Desloga (ao fazer logout do Supabase)
  static Future<void> logout() async {
    await Purchases.logOut();
  }
}

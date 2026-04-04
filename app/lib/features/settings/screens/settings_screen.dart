import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:microlaudo/core/theme/app_theme.dart';
import 'package:microlaudo/core/supabase/auth_provider.dart';
import 'package:microlaudo/core/purchases/purchase_provider.dart';
import 'package:microlaudo/core/purchases/purchase_service.dart';
import 'package:microlaudo/features/paywall/paywall_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['name'] ?? '';
    final crm = user?.userMetadata?['crm'] ?? '';
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? 'Dr(a). $name' : 'Médico(a)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (crm.isNotEmpty)
                          Text('CRM $crm', style: const TextStyle(color: AppColors.textSecondary)),
                        Text(user?.email ?? '',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isPro)
                    Chip(
                      label: const Text('PRO',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      backgroundColor: AppColors.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Assinatura
          Card(
            child: Column(
              children: [
                if (!isPro)
                  ListTile(
                    leading: const Icon(Icons.star_outline, color: AppColors.accent),
                    title: const Text('Assinar MicroLaudo Pro'),
                    subtitle: const Text('Laudos ilimitados'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => PaywallScreen.show(context),
                  ),
                if (isPro)
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined, color: AppColors.primary),
                    title: const Text('Gerenciar Assinatura'),
                    subtitle: const Text('Cancelar, reembolso, histórico'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => RevenueCatUI.presentCustomerCenter(),
                  ),
                ListTile(
                  leading: const Icon(Icons.restore, color: AppColors.textSecondary),
                  title: const Text('Restaurar Compras'),
                  onTap: () async {
                    final restored = await PurchaseService.restore();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(restored ? 'Assinatura restaurada!' : 'Nenhuma compra encontrada.'),
                        backgroundColor: restored ? AppColors.success : AppColors.textSecondary,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sair
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sair', style: TextStyle(color: AppColors.error)),
              onTap: () async {
                await PurchaseService.logout();
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'MicroLaudo v1.0.0',
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:microlaudo/core/theme/app_theme.dart';
import 'package:microlaudo/core/supabase/auth_provider.dart';
import 'package:microlaudo/core/purchases/purchase_provider.dart';
import 'package:microlaudo/core/purchases/purchase_service.dart';
import 'package:microlaudo/features/laudo/models/laudo_model.dart';
import 'package:microlaudo/features/laudo/repositories/laudo_repository.dart';
import 'package:microlaudo/features/laudo/screens/detalhe_laudo_screen.dart';
import 'package:microlaudo/features/paywall/paywall_screen.dart';

final laudoListProvider = FutureProvider.autoDispose<List<LaudoSummary>>((ref) {
  return LaudoRepository().listar();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = user?.userMetadata?['name'] ?? 'Médico(a)';
    final laudosAsync = ref.watch(laudoListProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MicroLaudo'),
        actions: [
          if (isPro)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                label: Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.biotech, color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, Dr(a). $name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Relatórios de Microscopia Vaginal',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Botão Novo Laudo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Verifica tier gratuito
                    if (!isPro) {
                      final laudos = await LaudoRepository().listar();
                      if (laudos.length >= kFreeTierLimit) {
                        if (!context.mounted) return;
                        final subscribed = await PaywallScreen.show(context);
                        if (!subscribed) return;
                      }
                    }
                    if (!context.mounted) return;
                    await context.push('/laudo/novo');
                    ref.invalidate(laudoListProvider);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Novo Laudo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Histórico
              Text(
                'Laudos Recentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: laudosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erro: $e')),
                  data: (laudos) {
                    if (laudos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_outlined,
                                size: 64,
                                color: AppColors.textSecondary.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text('Nenhum laudo ainda',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(laudoListProvider),
                      child: ListView.separated(
                        itemCount: laudos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _LaudoCard(
                          laudo: laudos[i],
                          onDeleted: () => ref.invalidate(laudoListProvider),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaudoCard extends StatelessWidget {
  final LaudoSummary laudo;
  final VoidCallback onDeleted;
  const _LaudoCard({required this.laudo, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final isVaginose = laudo.nugentTotal >= 7;
    final isTransicao = laudo.nugentTotal >= 4 && laudo.nugentTotal < 7;
    final scoreColor = isVaginose
        ? Colors.red.shade400
        : isTransicao
            ? Colors.orange.shade400
            : AppColors.success;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final deleted = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => DetalheLaudoScreen(laudo: laudo),
            ),
          );
          if (deleted == true) onDeleted();
        },
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Score badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${laudo.nugentTotal}',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laudo.paciente,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    laudo.dataColeta,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    laudo.floraTipo,
                    style: TextStyle(
                      fontSize: 11,
                      color: scoreColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
      ),
    );
  }
}

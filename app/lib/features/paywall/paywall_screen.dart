import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:microlaudo/core/theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  static Future<bool> show(BuildContext context) async {
    final subscribed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
    return subscribed ?? false;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  Package? _selected;
  bool _loading = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        setState(() {
          _offerings = offerings;
          _selected = current.annual ?? current.monthly ?? current.lifetime;
          _loading = false;
        });
      } else {
        setState(() { _loading = false; _error = 'Nenhum plano disponível.'; });
      }
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _purchase() async {
    if (_selected == null) return;
    setState(() => _purchasing = true);
    try {
      final info = await Purchases.purchasePackage(_selected!);
      if (info.entitlements.active.isNotEmpty) {
        if (mounted) Navigator.pop(context, true);
      }
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active.isNotEmpty && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma compra encontrada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
              : _buildContent(),
    );
  }

  static const _prices = {
    PackageType.annual:   'R\$479,00/ano',
    PackageType.monthly:  'R\$59,00/mês',
    PackageType.lifetime: 'R\$899,00 único',
  };

  static const _labels = {
    PackageType.annual:   'Anual',
    PackageType.monthly:  'Mensal',
    PackageType.lifetime: 'Vitalício',
  };

  Widget _buildContent() {
    final current = _offerings!.current!;
    final packages = [
      if (current.annual != null) current.annual!,
      if (current.monthly != null) current.monthly!,
      if (current.lifetime != null) current.lifetime!,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.biotech, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            const Text('MicroLaudo Pro',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Laudos ilimitados para sua prática médica',
                style: TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            // Features
            ...[
              'Laudos ilimitados',
              'Geração de PDF profissional',
              'Histórico completo',
              'Upload de fotos de microscopia',
            ].map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(f, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ]),
                )),
            const SizedBox(height: 32),
            // Planos
            ...packages.map((pkg) {
              final isSelected = _selected == pkg;
              final isAnnual = pkg == current.annual;
              return GestureDetector(
                onTap: () => setState(() => _selected = pkg),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.white12,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_labels[pkg.packageType] ?? pkg.packageType.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppColors.primaryDark : Colors.white,
                                )),
                            Text(_prices[pkg.packageType] ?? pkg.storeProduct.priceString,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.white70,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                      ),
                      if (isAnnual)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('34% OFF',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _purchasing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _purchasing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Assinar agora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: _purchasing ? null : _restore,
              child: const Text('Restaurar compra', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';

class HistoryScreen extends StatefulWidget {
  final Account account;
  const HistoryScreen({super.key, required this.account});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Payment> payments = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.userId != widget.account.userId) _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await ApiService.getPaymentHistory(widget.account.userId);
    if (mounted) setState(() { payments = data; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: AppBar(
            backgroundColor: AppColors.gradientCenter,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              S.of('paymentHistory'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 14),
                child: Center(
                  child: LanguageToggleButton(
                    foreground: Colors.white,
                    background: Color(0x33FFFFFF),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.gradientCenter,
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gradientCenter))
                : payments.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              S.of('noPayments'),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(18),
                        itemCount: payments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final p = payments[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowColor,
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (p.verified ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    p.verified ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                    color: p.verified ? AppColors.success : AppColors.warning,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.plan,
                                        style: const TextStyle(color: AppColors.textDark, fontSize: 14.5, fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        p.date,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${p.amount}',
                                      style: const TextStyle(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      p.verified ? S.of('verified') : S.of('pending'),
                                      style: TextStyle(
                                        color: p.verified ? AppColors.success : AppColors.warning,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        );
      },
    );
  }
}

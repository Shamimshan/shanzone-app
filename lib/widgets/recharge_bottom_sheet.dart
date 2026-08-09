import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../models/plan.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

const String kUpiId = '9984389923@ybl';
const String kUpiPayeeName = 'Shan Zone Broadband';

Future<void> showRechargeSheet({
  required BuildContext context,
  required Account account,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _RechargeSheetContent(account: account),
  );
}

class _RechargeSheetContent extends StatefulWidget {
  final Account account;
  const _RechargeSheetContent({required this.account});

  @override
  State<_RechargeSheetContent> createState() => _RechargeSheetContentState();
}

class _RechargeSheetContentState extends State<_RechargeSheetContent> {
  Plan? selectedPlan;
  bool claimSubmitted = false;
  bool submitting = false;

  String get _upiLink {
    final plan = selectedPlan!;
    final note = Uri.encodeComponent('${widget.account.userId} ${plan.key} Recharge');
    return 'upi://pay?pa=$kUpiId&pn=${Uri.encodeComponent(kUpiPayeeName)}'
        '&am=${plan.amount}&cu=INR&tn=$note';
  }

  Future<void> _openUpiApp() async {
    final uri = Uri.parse(_upiLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _submitClaim() async {
    setState(() => submitting = true);
    final ok = await ApiService.submitPaymentClaim(
      userId: widget.account.userId,
      name: widget.account.name,
      plan: selectedPlan!.key,
      amount: selectedPlan!.amount,
    );
    if (!mounted) return;
    setState(() {
      submitting = false;
      claimSubmitted = ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: selectedPlan == null ? _buildPlanList() : _buildPaymentView(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Text(
          S.of('selectPlan'),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 16),
        ...Plan.all.map((plan) {
          final isCurrent = plan.key == widget.account.plan;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.gradientCenter.withOpacity(0.08)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? AppColors.gradientCenter : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(S.of(plan.nameKey),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark)),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gradientCenter,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(S.of('currentPlanTag'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ]
                        ],
                      ),
                      Text(plan.speed,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text('₹${plan.amount}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    selectedPlan = plan;
                    claimSubmitted = false;
                  }),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(S.of('payNow'), style: const TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentView() {
    final plan = selectedPlan!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => selectedPlan = null),
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            ),
            Text('${S.of(plan.nameKey)} · ₹${plan.amount}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16)
            ],
          ),
          child: QrImageView(data: _upiLink, size: 190),
        ),
        const SizedBox(height: 12),
        Text(S.of('scanQr'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _openUpiApp,
          icon: const Icon(Icons.smartphone),
          label: Text(S.of('openUpiApp')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gradientCenter,
            side: const BorderSide(color: AppColors.gradientCenter),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        Text(S.of('enterUpiId'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(kUpiId,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
        const SizedBox(height: 22),
        if (!claimSubmitted) ...[
          ElevatedButton.icon(
            onPressed: submitting ? null : _submitClaim,
            icon: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(S.of('ivePaid')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          Text(S.of('ivePaidHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ] else
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(S.of('claimSubmitted'),
                      style: const TextStyle(color: AppColors.success, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

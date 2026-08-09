import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../models/plan.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/account_switcher_sheet.dart';
import '../widgets/expiry_progress_bar.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/recharge_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final List<Account> accounts;
  final Account selectedAccount;
  final ValueChanged<Account> onAccountChanged;
  final ValueChanged<List<Account>> onAccountsRefreshed;

  const HomeScreen({
    super.key,
    required this.accounts,
    required this.selectedAccount,
    required this.onAccountChanged,
    required this.onAccountsRefreshed,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool refreshing = false;

  Future<void> _refresh() async {
    setState(() => refreshing = true);
    final fresh = await ApiService.refreshAccount(widget.selectedAccount.userId);
    if (fresh != null && mounted) {
      final updated = widget.accounts
          .map((a) => a.userId == fresh.userId ? fresh : a)
          .toList();
      widget.onAccountsRefreshed(updated);
    }
    if (mounted) setState(() => refreshing = false);
  }

  @override
  void initState() {
    super.initState();
    _refresh(); // Har baar Home khulte hi latest plan/expiry Sheet se le aao
  }

  @override
  Widget build(BuildContext context) {
    final acc = widget.selectedAccount;
    final plan = Plan.byKey(acc.plan);
    final isHindi = AppLocale.current.value == AppLang.hi;
    final displayName = isHindi && acc.nameHi.isNotEmpty ? acc.nameHi : acc.name;

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.gradientCenter,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- Purple header: account switcher + language + welcome ----
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: widget.accounts.length < 2
                                    ? null
                                    : () async {
                                        final chosen = await showAccountSwitcherSheet(
                                          context: context,
                                          accounts: widget.accounts,
                                          selectedUserId: acc.userId,
                                        );
                                        if (chosen != null) widget.onAccountChanged(chosen);
                                      },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          acc.userId,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      if (widget.accounts.length > 1) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const LanguageToggleButton(),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '${S.of('welcome')}, $displayName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Plan card (overlapping the header, like the website's cards) ----
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              S.of('activePlan'),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (refreshing)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gradientCenter),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${S.of(plan.nameKey)} · ${plan.speed}',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              S.of('expiresOn'),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              acc.expiry.isEmpty ? '—' : acc.expiry,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ExpiryProgressBar(daysLeft: acc.daysLeft),
                        const SizedBox(height: 6),
                        Text(
                          acc.daysLeft < 0
                              ? S.of('expired')
                              : '${acc.daysLeft} ${S.of('daysLeft')}',
                          style: TextStyle(
                            color: acc.daysLeft < 0
                                ? AppColors.danger
                                : acc.daysLeft <= 5
                                    ? AppColors.warning
                                    : AppColors.success,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => showRechargeSheet(context: context, account: acc),
                            icon: const Icon(Icons.bolt_rounded),
                            label: Text(S.of('recharge'), style: const TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gradientCenter,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/account.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'speedtest_screen.dart';
import 'profile_screen.dart';

/// Shell that owns the bottom navigation + the shared "which account is
/// currently selected" state, so switching accounts on Home instantly
/// reflects on Profile too.
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int tabIndex = 0;
  List<Account> accounts = [];
  Account? selectedAccount;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await SessionService.getAccounts();
    final selectedId = await SessionService.getSelectedUserId();
    if (!mounted) return;
    setState(() {
      accounts = loaded;
      selectedAccount = loaded.firstWhere(
        (a) => a.userId == selectedId,
        orElse: () => loaded.isNotEmpty ? loaded.first : Account(
          userId: '', name: '', nameHi: '', mobile: '', plan: 'lite',
          expiry: '', address: '', addressHi: '',
        ),
      );
      loading = false;
    });
  }

  void onAccountChanged(Account acc) {
    setState(() => selectedAccount = acc);
    SessionService.setSelectedUserId(acc.userId);
  }

  void onAccountsRefreshed(List<Account> updated) {
    setState(() {
      accounts = updated;
      if (selectedAccount != null) {
        selectedAccount = updated.firstWhere(
          (a) => a.userId == selectedAccount!.userId,
          orElse: () => updated.first,
        );
      }
    });
    SessionService.updateAccounts(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (loading || selectedAccount == null || selectedAccount!.userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gradientCenter)),
      );
    }

    final screens = [
      HomeScreen(
        accounts: accounts,
        selectedAccount: selectedAccount!,
        onAccountChanged: onAccountChanged,
        onAccountsRefreshed: onAccountsRefreshed,
      ),
      const SpeedTestScreen(),
      ProfileScreen(account: selectedAccount!),
    ];

    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          body: IndexedStack(index: tabIndex, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabIndex,
            onTap: (i) => setState(() => tabIndex = i),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: S.of('navHome'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.speed_rounded),
                label: S.of('navSpeed'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded),
                label: S.of('navProfile'),
              ),
            ],
          ),
        );
      },
    );
  }
}

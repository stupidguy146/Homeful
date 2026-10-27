import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/customer_profile.dart';
import '../services/customer_service.dart';
import '../theme/app_tokens.dart';
import '../i18n/locale_scope.dart';
import '../widgets/app_widgets.dart';
import '../widgets/auth_scope.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'home_screen.dart';
import 'items_screen.dart';
import 'budget_screen.dart';
import 'to_buy_screen.dart';
import 'settings_screen.dart';

/// Main app shell with the homeful 5-tab bottom navigation.
/// (To-buy is a placeholder until its phase lands.)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _goItems() => setState(() => _index = 1);

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.neutral0 : AppColors.brand600;
    final unselectedColor =
        isDark ? AppColors.neutral400 : AppColors.neutral500;
    final pages = [
      HomeScreen(onSeeAllItems: _goItems),
      const ItemsScreen(),
      const ToBuyScreen(),
      const BudgetScreen(),
      const _MenuScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Theme.of(context).cardTheme.color,
          indicatorColor: isDark ? AppColors.brand700 : AppColors.brand100,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? selectedColor
                  : unselectedColor,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppType.caption.copyWith(
              color: states.contains(WidgetState.selected)
                  ? selectedColor
                  : unselectedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: s.navHome,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded),
              label: s.navItems,
            ),
            NavigationDestination(
              icon: const Icon(Icons.shopping_cart_outlined),
              selectedIcon: const Icon(Icons.shopping_cart_rounded),
              label: s.navToBuy,
            ),
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
              label: s.navBudget,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_rounded),
              selectedIcon: const Icon(Icons.menu_open_rounded),
              label: s.navMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuScreen extends StatefulWidget {
  const _MenuScreen();

  @override
  State<_MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<_MenuScreen> {
  CustomerService? _customer;
  Future<CustomerProfile>? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_customer == null) {
      _customer = CustomerService(auth: AuthScope.of(context));
      _profile = _customer!.getMyProfile();
    }
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) {
      setState(() => _profile = _customer!.getMyProfile());
    }
  }

  Future<void> _confirmLogout() async {
    final s = context.strings;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Theme.of(dialogContext).cardTheme.color,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.rXl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.coralTint,
                    borderRadius: AppRadius.rLg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.logoutConfirmTitle,
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  s.logoutConfirmMessage,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(s.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: Text(s.logout),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (shouldLogout == true && mounted) {
      await AuthScope.read(context).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(subtitle: s.appTitle, title: s.navMenu),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                FutureBuilder<CustomerProfile>(
                  future: _profile,
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final bytes = _decodeAvatar(profile?.avatarBase64);
                    final name = profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : profile?.username ?? s.myProfile;
                    return AppCard(
                      onTap: _editProfile,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.brand100,
                            backgroundImage:
                                bytes == null ? null : MemoryImage(bytes),
                            child: bytes == null
                                ? const Icon(Icons.person_rounded,
                                    color: AppColors.brand500, size: 32)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  profile?.username.isNotEmpty == true
                                      ? '@${profile!.username} · ${s.editProfile}'
                                      : s.editProfile,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.lock_reset_rounded,
                  label: s.changePassword,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.settings_outlined,
                  label: s.settings,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _MenuOption(
                  icon: Icons.logout_rounded,
                  label: s.logout,
                  color: AppColors.danger,
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeAvatar(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    try {
      return base64Decode(avatar.contains(',') ? avatar.split(',').last : avatar);
    } catch (_) {
      return null;
    }
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.brand500,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/home_navigation_controller.dart';
import '../../account/presentation/account_page.dart';
import '../../discovery/presentation/discovery_page.dart';
import '../../interests/presentation/interests_page.dart';
import '../../messages/presentation/messages_page.dart';
import '../../search/presentation/search_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {

  final _pages = const [
    AccountPage(),
    SearchPage(),
    DiscoveryPage(),
    InterestsPage(),
    MessagesPage(),
  ];

  static const _navItems = [
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
    _NavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Discover',
    ),
    _NavItem(
      icon: Icons.auto_awesome_rounded,
      activeIcon: Icons.auto_awesome_rounded,
      label: 'People',
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      label: 'Liked You',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
  ];

  void _onTap(int index) {
    final notifier = ref.read(homeTabIndexProvider.notifier);
    if (notifier.state == index) return;
    notifier.state = index;
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(index),
          child: _pages[index],
        ),
      ),
      bottomNavigationBar: _BumbleBottomNav(
        index: index,
        items: _navItems,
        onTap: _onTap,
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
}

class _BumbleBottomNav extends StatelessWidget {
  const _BumbleBottomNav({
    required this.index,
    required this.items,
    required this.onTap,
  });

  final int index;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFEAE7E1)),
          ),
        ),
        child: SizedBox(
          height: 84,
          child: Row(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final itemIndex = entry.key;
              final isSelected = index == itemIndex;

              if (item.isCenter) {
                return Expanded(
                  child: CenterNavButton(
                    label: item.label,
                    icon: isSelected ? item.activeIcon : item.icon,
                    isSelected: isSelected,
                    onTap: () => onTap(itemIndex),
                  ),
                );
              }

              return Expanded(
                child: _NavButton(
                  label: item.label,
                  icon: isSelected ? item.activeIcon : item.icon,
                  isSelected: isSelected,
                  onTap: () => onTap(itemIndex),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.black;
    final inactiveColor = const Color(0xFF8F8F8F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 84,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CenterNavButton extends StatelessWidget {
  const CenterNavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactiveFill = const Color(0xFFF3F2ED);
    final activeFill = Colors.black;
    final activeLabel = Colors.black;
    final inactiveLabel = const Color(0xFF8F8F8F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 84,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipPath(
              clipper: _HexagonClipper(),
              child: Container(
                width: 46,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? activeFill : inactiveFill,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : const Color(0xFF444444),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeLabel : inactiveLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/theme_switcher.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/my_profile_repository.dart';
import '../../media/presentation/photo_verification_page.dart';
import '../../media/presentation/profile_picture_upload_page.dart';
import 'my_profile_page.dart';
import 'profile_preferences_page.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationsProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.account),
        actions: [
          IconButton(
            tooltip: loc.signOut,
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          profileAsync.when(
            loading: () => const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator.adaptive()),
            ),
            error: (_, __) => _ProfileInlineOption(
              title: loc.userProfile,
              subtitle: loc.authenticatedSession,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyProfilePage(),
                ),
              ),
            ),
            data: (profileView) => _ProfileInlineOption(
              title: profileView.displayName.isEmpty
                  ? loc.userProfile
                  : profileView.displayName,
              subtitle: profileView.profile.profileStatus,
              imageUrl: profileView.primaryPhotoUrl,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MyProfilePage(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Profile settings',
            subtitle: 'Manage your visibility, photos and trust signals.',
          ),
          const SizedBox(height: 10),
          _ModernTile(
            icon: Icons.verified_user_outlined,
            title: loc.verification,
            subtitle: loc.verificationSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PhotoVerificationPage(),
              ),
            ),
          ),
          _ModernTile(
            icon: Icons.photo_library_outlined,
            title: 'Profile photos',
            subtitle: 'Upload, reorder and manage your profile pictures',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePictureUploadPage(),
              ),
            ),
          ),
          _ModernTile(
            icon: Icons.tune_outlined,
            title: 'Match preferences',
            subtitle: 'Set who you want to see and be seen by',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePreferencesPage(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SectionHeader(
            title: 'Preferences',
            subtitle: 'Personalize the app to your taste.',
          ),
          const SizedBox(height: 10),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Consumer(
              builder: (context, ref, child) {
                final loc = ref.watch(localizationsProvider);
                return ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: Text(loc.appTheme),
                  subtitle: Text(loc.appThemeSubtitle),
                  trailing: const ThemeSwitcher(),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Consumer(
              builder: (context, ref, child) {
                final loc = ref.watch(localizationsProvider);
                return ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(loc.language),
                  subtitle: Text(loc.languageSubtitle),
                  trailing: const LanguageSwitcher(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _SectionHeader(
            title: 'Privacy & plans',
            subtitle: 'Fine tune your membership and visibility options.',
          ),
          const SizedBox(height: 10),
          _ModernTile(
            icon: Icons.lock_outline,
            title: loc.privacyControls,
            subtitle: loc.privacyControlsSubtitle,
          ),
          _ModernTile(
            icon: Icons.workspace_premium_outlined,
            title: loc.subscription,
            subtitle: loc.subscriptionSubtitle,
          ),
          _ModernTile(
            icon: Icons.auto_awesome_outlined,
            title: loc.matchIntelligence,
            subtitle: loc.matchIntelligenceSubtitle,
          ),
        ],
      ),
    );
  }
}

class _ProfileInlineOption extends StatelessWidget {
  const _ProfileInlineOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipOval(
          child: SizedBox(
            width: 52,
            height: 52,
            child: imageUrl == null
                ? Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF334155)),
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF334155)),
                    ),
                  ),
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _ModernTile extends StatelessWidget {
  const _ModernTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF334155)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../data/my_profile_repository.dart';
import '../../media/presentation/profile_picture_upload_page.dart';

const _pageBackground = Color(0xFFF7F8FB);
const _cardBorder = Color(0xFFE7EAF0);
const _accent = Color(0xFFD94D67);

class MyProfilePage extends ConsumerWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final lookupsAsync = ref.watch(staticDataProvider);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) => _ProfileErrorView(error: error.toString()),
        data: (profileView) => lookupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (error, _) => _ProfileErrorView(error: error.toString()),
          data: (lookups) => _MyProfileContent(
            profileView: profileView,
            lookups: lookups,
          ),
        ),
      ),
    );
  }
}

class _MyProfileContent extends StatelessWidget {
  const _MyProfileContent({
    required this.profileView,
    required this.lookups,
  });

  final MyProfileView profileView;
  final dynamic lookups;

  @override
  Widget build(BuildContext context) {
    final profile = profileView.profile;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          pinned: false,
          floating: false,
          snap: false,
          elevation: 0,
          expandedHeight: 360,
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: _ProfileHeroHeader(
            profileView: profileView,
            title: profile.fullname,
            subtitle: 'ID - ${profile.profileId.isEmpty ? profileView.accountId : profile.profileId}',
            imageUrl: profileView.primaryPhotoUrl,
            onBackPressed: () => Navigator.of(context).maybePop(),
            onPhotosPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePictureUploadPage(),
              ),
            ),
            onPreviewPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile preview coming soon')),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompletionPromptCard(
                  completion: profileView.profileCompletion,
                  onCompletePressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile completion flow coming soon')),
                  ),
                ),
                const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Basic details',
                  subtitle: 'Brief outline of personal information',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile details coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.height_rounded,
                      label: 'Height',
                      value: _lookup(lookups.heights, profile.heightId),
                    ),
                    _DetailRowView(
                      icon: Icons.temple_hindu_outlined,
                      label: 'Religion',
                      value: _lookup(lookups.religions, profile.religionId),
                    ),
                    _DetailRowView(
                      icon: Icons.language_rounded,
                      label: 'Mother tongue',
                      value: _lookup(lookups.motherTongues, profile.motherTongueId),
                    ),
                    _DetailRowView(
                      icon: Icons.place_outlined,
                      label: 'Location',
                      value: [
                        _lookup(lookups.countries, profile.countryId),
                        _lookup(lookups.states, profile.stateId),
                        _lookup(lookups.cities, profile.cityId),
                      ].where((item) => item != 'Not added').join(', '),
                    ),
                    _DetailRowView(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Income',
                      value: _lookup(lookups.incomes, profile.expectedSalaryId),
                    ),
                    _DetailRowView(
                      icon: Icons.favorite_border_rounded,
                      label: 'Marital status',
                      value: profile.maritalStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if ((profile.aboutMe ?? '').isNotEmpty)
                  _ProfileSectionCard(
                    title: 'About me',
                    subtitle: 'Describe yourself in a few words',
                    onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit about me coming soon')),
                    ),
                    children: [
                      Text(
                        profile.aboutMe!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.55,
                              color: const Color(0xFF1F2937),
                            ),
                      ),
                    ],
                  ),
                if ((profile.aboutMe ?? '').isNotEmpty) const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Education',
                  subtitle: 'Showcase your educational qualification',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit education coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.school_outlined,
                      label: 'Education',
                      value: _lookup(lookups.education, profile.educationDegreeId),
                      secondaryValue: _lookup(lookups.employedIn, profile.employedInId),
                    ),
                    _DetailRowView(
                      icon: Icons.work_outline_rounded,
                      label: 'Occupation',
                      value: _lookup(lookups.occupation, profile.occupationRoleId),
                      secondaryValue: _lookup(lookups.incomes, profile.expectedSalaryId),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Career',
                  subtitle: 'Give a glimpse of your professional life',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit career coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.apartment_outlined,
                      label: 'Employed in',
                      value: _lookup(lookups.employedIn, profile.employedInId),
                    ),
                    _DetailRowView(
                      icon: Icons.business_center_outlined,
                      label: 'Experience',
                      value: profile.profileCreatedFor,
                      secondaryValue: profile.profileStatus,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Family',
                  subtitle: 'Introduce your family members, values and background',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit family coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.groups_outlined,
                      label: 'Caste',
                      value: _lookup(lookups.castes, profile.casteId),
                      secondaryValue: _lookup(lookups.subcastes, profile.subcasteId),
                    ),
                    _DetailRowView(
                      icon: Icons.account_tree_outlined,
                      label: 'Kulam',
                      value: _lookup(lookups.kulams, profile.kulamId),
                      secondaryValue: profile.profileCreatedFor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Contact',
                  subtitle: 'Details that would help profiles get in touch with you',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit contact details coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profileView.primaryEmail ?? 'Not added',
                    ),
                    _DetailRowView(
                      icon: Icons.phone_outlined,
                      label: 'Mobile',
                      value: profileView.primaryPhone ?? 'Not added',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSectionCard(
                  title: 'Physical details',
                  subtitle: 'A quick glance at your build',
                  onEditPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit physical details coming soon')),
                  ),
                  children: [
                    _DetailRowView(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      value: profile.weight == null ? 'Not added' : '${profile.weight} kg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _lookup(List<LookupItem> items, int? id) {
    if (id == null) return 'Not added';
    final match = items.where((item) => item.id == id);
    return match.isEmpty ? 'Not added' : match.first.name;
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({
    required this.profileView,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onBackPressed,
    required this.onPhotosPressed,
    required this.onPreviewPressed,
  });

  final MyProfileView profileView;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onBackPressed;
  final VoidCallback onPhotosPressed;
  final VoidCallback onPreviewPressed;

  String _initialOf(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final nameParts = title
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    final initials = nameParts.isEmpty
        ? '?'
        : nameParts.length == 1
            ? _initialOf(nameParts.first)
            : '${_initialOf(nameParts.first)}${_initialOf(nameParts.last)}';

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: imageUrl == null
              ? _HeroFallback(initials: initials)
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _HeroFallback(initials: initials),
                ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.06),
                  Colors.black.withValues(alpha: 0.70),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HeroIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: onBackPressed,
                    ),
                    const Spacer(),
                    _HeroStatButton(
                      icon: Icons.photo_library_outlined,
                      label: '${profileView.photosCount}',
                      onPressed: onPhotosPressed,
                    ),
                    const SizedBox(width: 10),
                    _HeroIconButton(
                      icon: Icons.visibility_outlined,
                      onPressed: onPreviewPressed,
                    ),
                  ],
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  height: 1.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF4FA3FF),
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Color(0xFF6B7280), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _HeroStatButton extends StatelessWidget {
  const _HeroStatButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionPromptCard extends StatelessWidget {
  const _CompletionPromptCard({
    required this.completion,
    required this.onCompletePressed,
  });

  final int completion;
  final VoidCallback onCompletePressed;

  @override
  Widget build(BuildContext context) {
    final accent = completion >= 80
        ? const Color(0xFF16A34A)
        : completion >= 50
            ? const Color(0xFFF59E0B)
            : _accent;

    return InkWell(
      onTap: onCompletePressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0D8DB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D111827),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: completion / 100,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xFFF2E9EA),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                  Center(
                    child: Text(
                      '$completion%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add a few more details to make your profile rich!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF374151),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: _accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.onEditPressed,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A111827),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEditPressed,
                icon: const Icon(Icons.edit_outlined),
                color: const Color(0xFF667085),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._separate(children),
        ],
      ),
    );
  }

  List<Widget> _separate(List<Widget> items) {
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(items[i]);
      if (i != items.length - 1) {
        widgets.add(const Divider(height: 22, thickness: 1, color: Color(0xFFE9EDF3)));
      }
    }
    return widgets;
  }
}

class _DetailRowView extends StatelessWidget {
  const _DetailRowView({
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  secondaryValue!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.3,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

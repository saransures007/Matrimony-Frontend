import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../../lookups/domain/static_data.dart';
import '../data/matches_repository.dart';
import '../domain/match_profile.dart';
import 'discover_controller.dart';

class DiscoveryPage extends ConsumerWidget {
  const DiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final lookupsAsync = ref.watch(staticDataProvider);
    final visibleProfiles = ref.watch(filteredDiscoverProfilesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFFF3F1EA) : const Color(0xFFF6F2EB),
      body: SafeArea(
        bottom: false,
        child: matchesAsync.when(
          loading: () => const _DiscoveryLoadingView(),
          error: (error, _) => _DiscoveryErrorView(
            error: error.toString(),
            onRetry: () {
              ref.invalidate(matchesProvider);
              ref.invalidate(staticDataProvider);
            },
          ),
          data: (_) => lookupsAsync.when(
            loading: () => const _DiscoveryLoadingView(),
            error: (error, _) => _DiscoveryErrorView(
              error: error.toString(),
              onRetry: () => ref.invalidate(staticDataProvider),
            ),
            data: (lookups) {
              if (visibleProfiles.isEmpty) {
                return _DiscoveryEmptyState(
                  onRefresh: () => ref.invalidate(matchesProvider),
                  onOpenFilters: () => _openFiltersSheet(context, ref, lookups),
                );
              }

              return _DiscoverDeck(
                profiles: visibleProfiles,
                lookups: lookups,
                onOpenFilters: () => _openFiltersSheet(context, ref, lookups),
                onOpenProfile: (profile) => _openExpandedProfile(
                  context,
                  profile,
                  lookups,
                  ref.read(matchesRepositoryProvider),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiscoverDeck extends ConsumerStatefulWidget {
  const _DiscoverDeck({
    required this.profiles,
    required this.lookups,
    required this.onOpenFilters,
    required this.onOpenProfile,
  });

  final List<MatchProfile> profiles;
  final StaticData lookups;
  final VoidCallback onOpenFilters;
  final ValueChanged<MatchProfile> onOpenProfile;

  @override
  ConsumerState<_DiscoverDeck> createState() => _DiscoverDeckState();
}

class _DiscoverDeckState extends ConsumerState<_DiscoverDeck> {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimating = false;

  MatchProfile? get _activeProfile {
    if (_currentIndex >= widget.profiles.length) return null;
    return widget.profiles[_currentIndex];
  }

  @override
  void didUpdateWidget(covariant _DiscoverDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profiles != widget.profiles &&
        _currentIndex >= widget.profiles.length) {
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _isDragging = false;
      _isAnimating = false;
    }
  }

  Future<void> _swipe({
    required bool liked,
    required bool superInterest,
  }) async {
    final profile = _activeProfile;
    if (profile == null || _isAnimating) return;

    final width = MediaQuery.of(context).size.width;
    final targetX = liked ? width * 1.25 : -width * 1.25;

    setState(() {
      _isAnimating = true;
      _dragOffset = Offset(targetX, 0);
      _isDragging = false;
    });

    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final result = await ref.read(matchesRepositoryProvider).swipe(
          targetProfileId: profile.profileId,
          liked: liked,
        );

    if (!mounted) return;

    setState(() {
      _currentIndex = min(_currentIndex + 1, widget.profiles.length);
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });

    if (result.matched) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.82),
        builder: (_) => _MatchPopup(
          profile: profile,
          result: result,
          onMessage: () {
            Navigator.of(context).pop();
            widget.onOpenProfile(profile);
          },
          onContinue: () => Navigator.of(context).pop(),
        ),
      );
      return;
    }

    if (superInterest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super interest sent'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta;
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_isAnimating) return;

    final profile = _activeProfile;
    if (profile == null) return;

    final velocity = details.velocity.pixelsPerSecond;
    final width = MediaQuery.of(context).size.width;
    final horizontalThreshold = width * 0.22;
    final upwardGesture = _dragOffset.dy < -horizontalThreshold || velocity.dy < -800;

    if (_dragOffset.dx > horizontalThreshold || velocity.dx > 900) {
      await _swipe(liked: true, superInterest: false);
      return;
    }

    if (_dragOffset.dx < -horizontalThreshold || velocity.dx < -900) {
      await _swipe(liked: false, superInterest: false);
      return;
    }

    if (upwardGesture) {
      widget.onOpenProfile(profile);
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _activeProfile;
    final bottomDock = MediaQuery.of(context).padding.bottom + 16;

    if (profile == null) {
      return _DiscoveryEmptyState(
        onRefresh: () => ref.invalidate(matchesProvider),
        onOpenFilters: widget.onOpenFilters,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _DiscoverHeader(onOpenFilters: widget.onOpenFilters),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (_currentIndex + 1 < widget.profiles.length)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            child: Transform.scale(
                              scale: 0.96,
                              child: _SwipeCard(
                                profile: widget.profiles[_currentIndex + 1],
                                lookups: widget.lookups,
                                isBackground: true,
                                dragOffset: Offset.zero,
                                isDragging: false,
                                onTap: () => widget.onOpenProfile(widget.profiles[_currentIndex + 1]),
                                onReject: () => _swipe(liked: false, superInterest: false),
                                onSuperInterest: () => _swipe(liked: true, superInterest: true),
                                onLike: () => _swipe(liked: true, superInterest: false),
                                onMessage: () => widget.onOpenProfile(widget.profiles[_currentIndex + 1]),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => widget.onOpenProfile(profile),
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: _SwipeCard(
                            profile: profile,
                            lookups: widget.lookups,
                            isBackground: false,
                            dragOffset: _dragOffset,
                            isDragging: _isDragging,
                            onTap: () => widget.onOpenProfile(profile),
                            onReject: () => _swipe(liked: false, superInterest: false),
                            onSuperInterest: () => _swipe(liked: true, superInterest: true),
                            onLike: () => _swipe(liked: true, superInterest: false),
                            onMessage: () => widget.onOpenProfile(profile),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomDock,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundActionButton(
                        size: 56,
                        backgroundColor: const Color(0xFFF7D46C),
                        foregroundColor: const Color(0xFF1E1E1E),
                        icon: Icons.favorite_rounded,
                        onTap: () => _swipe(liked: false, superInterest: false),
                      ),
                      _RoundActionButton(
                        size: 76,
                        backgroundColor: const Color(0xFFF7D46C),
                        foregroundColor: const Color(0xFF1E1E1E),
                        icon: Icons.star_rounded,
                        onTap: () => _swipe(liked: true, superInterest: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SwipeCard extends StatelessWidget {
  const _SwipeCard({
    required this.profile,
    required this.lookups,
    required this.isBackground,
    required this.dragOffset,
    required this.isDragging,
    required this.onTap,
    required this.onReject,
    required this.onSuperInterest,
    required this.onLike,
    required this.onMessage,
  });

  final MatchProfile profile;
  final StaticData lookups;
  final bool isBackground;
  final Offset dragOffset;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onReject;
  final VoidCallback onSuperInterest;
  final VoidCallback onLike;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final images = _profileImages(profile);
    final rotation = isBackground ? 0.0 : (dragOffset.dx / 450).clamp(-0.18, 0.18);
    final likeOpacity = (dragOffset.dx / 150).clamp(0.0, 1.0);
    final nopeOpacity = (-dragOffset.dx / 150).clamp(0.0, 1.0);
    final superOpacity = (-dragOffset.dy / 170).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: isDragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.translationValues(dragOffset.dx, dragOffset.dy * 0.18, 0)
          ..rotateZ(rotation),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.black.withValues(alpha: 0.06) : const Color(0xFFE4DED5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isBackground ? 0.08 : 0.14),
                  blurRadius: isBackground ? 22 : 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: _heroTag(profile.profileId),
                  child: images.isNotEmpty
                      ? Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _CardImagePlaceholder(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const _CardImagePlaceholder();
                          },
                        )
                      : const _CardImagePlaceholder(),
                ),
                const _CardShade(),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _SmallCircleButton(
                    icon: Icons.share_outlined,
                    onTap: () {},
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _StatusPill(
                    label: profile.pictures.isNotEmpty ? 'Photo verified' : 'Trusted profile',
                    icon: profile.pictures.isNotEmpty ? Icons.verified_rounded : Icons.lock_outline_rounded,
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    top: 16,
                    left: 72,
                    right: 72,
                    child: _StoryPreviewRow(count: images.length),
                  ),
                if (!isBackground) ...[
                  Positioned(
                    top: 120,
                    left: 18,
                    child: _SwipeStamp(
                      text: 'NOPE',
                      opacity: nopeOpacity,
                      color: _DiscoverColors.reject,
                    ),
                  ),
                  Positioned(
                    top: 120,
                    right: 18,
                    child: _SwipeStamp(
                      text: 'LIKE',
                      opacity: likeOpacity,
                      color: _DiscoverColors.like,
                    ),
                  ),
                  Positioned(
                    top: 170,
                    left: 18,
                    child: _SwipeStamp(
                      text: 'SUPER',
                      opacity: superOpacity,
                      color: _DiscoverColors.superInterest,
                    ),
                  ),
                ],
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: _CardBottomSheet(
                    profile: profile,
                    lookups: lookups,
                    onTap: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBottomSheet extends StatelessWidget {
  const _CardBottomSheet({
    required this.profile,
    required this.lookups,
    required this.onTap,
  });

  final MatchProfile profile;
  final StaticData lookups;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${profile.fullname}, ${profile.age}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _StatusPill(
                  label: profile.pictures.isNotEmpty ? 'Verified' : 'Review',
                  icon: profile.pictures.isNotEmpty
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'We have things in common',
              style: TextStyle(
                color: const Color(0xFF1F1F1F).withValues(alpha: 0.8),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftChip(label: _lookup(lookups.occupation, profile.occupationRoleId)),
                _SoftChip(label: _lookup(lookups.education, profile.educationDegreeId)),
                _SoftChip(label: _lookup(lookups.religions, profile.religionId)),
                _SoftChip(label: _lookup(lookups.castes, profile.casteId)),
                _SoftChip(label: _locationLabel(lookups, profile)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.size,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: foregroundColor, size: 24),
      ),
    );
  }
}

class _SmallCircleButton extends StatelessWidget {
  const _SmallCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({required this.onOpenFilters});

  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Discover',
            style: TextStyle(
              color: Color(0xFF161616),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.tune_rounded,
          onTap: onOpenFilters,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E1D7)),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF171717)),
      ),
    );
  }
}

class _DiscoveryLoadingView extends StatelessWidget {
  const _DiscoveryLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 36, 18, 110),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE6DED3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 18),
            Text(
              'Finding premium profiles...',
              style: TextStyle(
                color: Color(0xFF161616),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryEmptyState extends StatelessWidget {
  const _DiscoveryEmptyState({
    required this.onRefresh,
    required this.onOpenFilters,
  });

  final VoidCallback onRefresh;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE7E1D7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: Color(0xFFF7D46C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 54,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No more profiles nearby',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF161616),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Adjust your filters or refresh suggestions to continue discovering compatible matches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6D6D6D),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onRefresh,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF7D46C),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Refresh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onOpenFilters,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF161616),
                        side: const BorderSide(color: Color(0xFFE7E1D7)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryErrorView extends StatelessWidget {
  const _DiscoveryErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE7E1D7)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 44, color: Color(0xFF161616)),
              const SizedBox(height: 14),
              const Text(
                'Discover is unavailable',
                style: TextStyle(
                  color: Color(0xFF161616),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6D6D6D),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF7D46C),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailPage extends StatefulWidget {
  const _ProfileDetailPage({
    required this.profile,
    required this.lookups,
    required this.heroTag,
    required this.repository,
  });

  final MatchProfile profile;
  final StaticData lookups;
  final String heroTag;
  final MatchesRepository repository;

  @override
  State<_ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<_ProfileDetailPage> {
  late final PageController _pageController;
  late final ValueNotifier<int> _pageIndex;
  bool _likedBurst = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageIndex = ValueNotifier<int>(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageIndex.dispose();
    super.dispose();
  }

  Future<void> _likeProfile() async {
    if (_likedBurst) return;
    setState(() => _likedBurst = true);
    HapticFeedback.mediumImpact();

    final result = await widget.repository.swipe(
      targetProfileId: widget.profile.profileId,
      liked: true,
    );

    if (!mounted) return;

    if (result.matched) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.82),
        builder: (_) => _MatchPopup(
          profile: widget.profile,
          result: result,
          onMessage: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          onContinue: () => Navigator.of(context).pop(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interest sent')),
      );
    }

    if (mounted) {
      setState(() => _likedBurst = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _profileImages(widget.profile);
    final headerHeight = MediaQuery.of(context).size.height * 0.62;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: headerHeight,
            backgroundColor: const Color(0xFFF6F2EB),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF161616)),
            ),
            actions: [
              IconButton(
                onPressed: _likeProfile,
                icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF161616)),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, color: Color(0xFF161616)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => _pageIndex.value = index,
                    itemCount: images.isEmpty ? 1 : images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images.isEmpty ? null : images[index];
                      return Hero(
                        tag: index == 0 ? widget.heroTag : '${widget.heroTag}-$index',
                        child: GestureDetector(
                          onDoubleTap: _likeProfile,
                          child: imageUrl == null
                              ? const _CardImagePlaceholder()
                              : InteractiveViewer(
                                  minScale: 1,
                                  maxScale: 2.6,
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const _CardImagePlaceholder(),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const _CardImagePlaceholder();
                                    },
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const _CardShade(),
                  if (_likedBurst) const Positioned.fill(child: _LikeBurstOverlay()),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _ProfileHeroSummary(
                      profile: widget.profile,
                      lookups: widget.lookups,
                      pageIndex: _pageIndex,
                      imageCount: images.isEmpty ? 1 : images.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F2EB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionCard(
                      title: 'Compatibility',
                      subtitle: 'Balanced for meaningful matrimony conversations.',
                      child: _CompatibilitySection(profile: widget.profile),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'About',
                      subtitle: 'A richer story for families and matches.',
                      child: Text(
                        widget.profile.aboutMe?.trim().isNotEmpty == true
                            ? widget.profile.aboutMe!.trim()
                            : 'This profile is awaiting a richer bio.',
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Lifestyle & family',
                      subtitle: 'Presented in a calm, trusted format.',
                      child: _DetailGrid(
                        lookups: widget.lookups,
                        profile: widget.profile,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Tags',
                      subtitle: 'Quick signals that help a family understand the profile.',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SoftChip(label: _lookup(widget.lookups.religions, widget.profile.religionId)),
                          _SoftChip(label: _lookup(widget.lookups.castes, widget.profile.casteId)),
                          _SoftChip(label: _lookup(widget.lookups.education, widget.profile.educationDegreeId)),
                          _SoftChip(label: _lookup(widget.lookups.occupation, widget.profile.occupationRoleId)),
                          _SoftChip(label: _lookup(widget.lookups.heights, widget.profile.heightId)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _StickyActions(
                      onLike: _likeProfile,
                      onMessage: () => Navigator.of(context).pop(),
                      onSave: () {},
                      onSuperInterest: _likeProfile,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroSummary extends StatelessWidget {
  const _ProfileHeroSummary({
    required this.profile,
    required this.lookups,
    required this.pageIndex,
    required this.imageCount,
  });

  final MatchProfile profile;
  final StaticData lookups;
  final ValueNotifier<int> pageIndex;
  final int imageCount;

  @override
  Widget build(BuildContext context) {
    final detail = [
      _lookup(lookups.occupation, profile.occupationRoleId),
      _locationLabel(lookups, profile),
      _lookup(lookups.education, profile.educationDegreeId),
    ].where((item) => item != 'Not added').join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: pageIndex,
          builder: (context, index, _) {
            return Row(
              children: List.generate(
                imageCount,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == imageCount - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i == index ? Colors.white : Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${profile.fullname}, ${profile.age}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StatusPill(
              label: profile.pictures.isNotEmpty ? 'Verified' : 'Review',
              icon: profile.pictures.isNotEmpty
                  ? Icons.verified_rounded
                  : Icons.lock_outline_rounded,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          detail.isEmpty ? 'Trusted matrimonial profile' : detail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CompatibilitySection extends StatelessWidget {
  const _CompatibilitySection({required this.profile});

  final MatchProfile profile;

  @override
  Widget build(BuildContext context) {
    final score = _compatibilityScore(profile);
    return Row(
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 9,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(_DiscoverColors.gold),
              ),
              Center(
                child: Text(
                  '$score%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Color(0xFF0F172A),
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
                'AI compatibility score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Shared interests, lifestyle, and partner preferences are aligned for a warm starting point.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({
    required this.lookups,
    required this.profile,
  });

  final StaticData lookups;
  final MatchProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = <_DetailRow>[
      _DetailRow(icon: Icons.cake_outlined, label: 'Age', value: '${profile.age} years'),
      _DetailRow(icon: Icons.person_outline_rounded, label: 'Gender', value: profile.gender),
      _DetailRow(icon: Icons.favorite_border_rounded, label: 'Marital status', value: profile.maritalStatus),
      _DetailRow(icon: Icons.school_outlined, label: 'Education', value: _lookup(lookups.education, profile.educationDegreeId)),
      _DetailRow(icon: Icons.work_outline_rounded, label: 'Profession', value: _lookup(lookups.occupation, profile.occupationRoleId)),
      _DetailRow(icon: Icons.place_outlined, label: 'Location', value: _locationLabel(lookups, profile)),
      _DetailRow(icon: Icons.language_rounded, label: 'Mother tongue', value: _lookup(lookups.motherTongues, profile.motherTongueId)),
      _DetailRow(icon: Icons.height_rounded, label: 'Height', value: _lookup(lookups.heights, profile.heightId)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.9,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, size: 16, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DetailRow {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StickyActions extends StatelessWidget {
  const _StickyActions({
    required this.onLike,
    required this.onMessage,
    required this.onSave,
    required this.onSuperInterest,
  });

  final VoidCallback onLike;
  final VoidCallback onMessage;
  final VoidCallback onSave;
  final VoidCallback onSuperInterest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onLike,
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Like'),
            style: FilledButton.styleFrom(
              backgroundColor: _DiscoverColors.like,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onMessage,
            icon: const Icon(Icons.message_rounded),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.bookmark_border_rounded),
            label: const Text('Save'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: onSuperInterest,
            icon: const Icon(Icons.star_rounded),
            label: const Text('Star'),
            style: FilledButton.styleFrom(
              backgroundColor: _DiscoverColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchPopup extends StatelessWidget {
  const _MatchPopup({
    required this.profile,
    required this.result,
    required this.onMessage,
    required this.onContinue,
  });

  final MatchProfile profile;
  final SwipeResult result;
  final VoidCallback onMessage;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final images = _profileImages(profile);
    final firstImage = images.isNotEmpty ? images.first : null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.78),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      10,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index.isEven ? Icons.favorite_rounded : Icons.auto_awesome_rounded,
                          color: index.isEven ? _DiscoverColors.like : _DiscoverColors.gold,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "It's a Match",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You and ${profile.fullname} liked each other. ${result.matchId != null ? 'Match #${result.matchId}' : ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _MatchAvatar(
                          imageUrl: firstImage,
                          fallbackName: profile.fullname,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.favorite_rounded, color: _DiscoverColors.like, size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MatchAvatar(
                          imageUrl: firstImage,
                          fallbackName: profile.fullname,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: onMessage,
                          style: FilledButton.styleFrom(
                            backgroundColor: _DiscoverColors.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Message'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onContinue,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Keep browsing'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({
    required this.imageUrl,
    required this.fallbackName,
  });

  final String? imageUrl;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.82,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: imageUrl == null || imageUrl!.isEmpty
            ? _FallbackAvatar(name: fallbackName)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _FallbackAvatar(name: fallbackName),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const _CardImagePlaceholder();
                },
              ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF1D4ED8),
            Color(0xFF7C3AED),
            Color(0xFFEC4899),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 36,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardShade extends StatelessWidget {
  const _CardShade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.02),
            Colors.black.withValues(alpha: 0.10),
            Colors.black.withValues(alpha: 0.26),
            Colors.black.withValues(alpha: 0.74),
          ],
          stops: const [0.0, 0.48, 0.76, 1.0],
        ),
      ),
    );
  }
}

class _CardImagePlaceholder extends StatelessWidget {
  const _CardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF2E5),
            Color(0xFFF9CFC0),
            Color(0xFFFFFBF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person_rounded,
          size: 78,
          color: Color(0xFF7C3AED),
        ),
      ),
    );
  }
}

class _StoryPreviewRow extends StatelessWidget {
  const _StoryPreviewRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        count.clamp(1, 4),
        (index) => Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == count.clamp(1, 4) - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({
    required this.text,
    required this.opacity,
    required this.color,
  });

  final String text;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: text == 'SUPER' ? -0.18 : 0.12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 3),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _LikeBurstOverlay extends StatelessWidget {
  const _LikeBurstOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.favorite_rounded,
        color: _DiscoverColors.like.withValues(alpha: 0.75),
        size: 120,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DiscoverColors {
  static const gold = Color(0xFFF7D46C);
  static const like = Color(0xFFEA5C80);
  static const reject = Color(0xFFF45B69);
  static const superInterest = Color(0xFF8B5CF6);
}

Future<void> _openExpandedProfile(
  BuildContext context,
  MatchProfile profile,
  StaticData lookups,
  MatchesRepository repository,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: _ProfileDetailPage(
            profile: profile,
            lookups: lookups,
            heroTag: _heroTag(profile.profileId),
            repository: repository,
          ),
        );
      },
    ),
  );
}

Future<void> _openFiltersSheet(
  BuildContext context,
  WidgetRef ref,
  StaticData lookups,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.84,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Container(
              color: const Color(0xFFF6F2EB),
              child: Consumer(
                builder: (context, ref, _) {
                  final filters = ref.watch(discoverFiltersProvider);
                  final controller = ref.read(discoverFiltersProvider.notifier);

                  return CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 56,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: controller.reset,
                                    child: const Text('Reset'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tune your matches for age, community, education and premium preferences.',
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _FilterSection(
                                title: 'Age range',
                                child: RangeSlider(
                                  values: filters.ageRange,
                                  min: 18,
                                  max: 50,
                                  divisions: 32,
                                  labels: RangeLabels(
                                    filters.ageRange.start.round().toString(),
                                    filters.ageRange.end.round().toString(),
                                  ),
                                  onChanged: controller.setAgeRange,
                                ),
                              ),
                              _FilterSection(
                                title: 'Quick toggles',
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Verified photos'),
                                      selected: filters.onlyVerified,
                                      onSelected: controller.setOnlyVerified,
                                    ),
                                    ChoiceChip(
                                      label: const Text('Premium only'),
                                      selected: filters.premiumOnly,
                                      onSelected: controller.setPremiumOnly,
                                    ),
                                  ],
                                ),
                              ),
                              _FilterSection(
                                title: 'Religion',
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _lookupChips(
                                    lookups.religions,
                                    filters.religionId,
                                    controller.setReligion,
                                  ),
                                ),
                              ),
                              _FilterSection(
                                title: 'Education',
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _lookupChips(
                                    lookups.education,
                                    filters.educationDegreeId,
                                    controller.setEducation,
                                  ),
                                ),
                              ),
                              _FilterSection(
                                title: 'Profession',
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _lookupChips(
                                    lookups.occupation,
                                    filters.occupationRoleId,
                                    controller.setOccupation,
                                  ),
                                ),
                              ),
                              _FilterSection(
                                title: 'Height',
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _lookupChips(
                                    lookups.heights,
                                    filters.heightId,
                                    controller.setHeight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

List<Widget> _lookupChips(
  List<LookupItem> items,
  int? selectedId,
  ValueChanged<int?> onSelected,
) {
  return [
    ChoiceChip(
      label: const Text('Any'),
      selected: selectedId == null,
      onSelected: (selected) => onSelected(selected ? null : selectedId),
    ),
    ...items.take(8).map(
          (item) => ChoiceChip(
            label: Text(item.name),
            selected: selectedId == item.id,
            onSelected: (selected) => onSelected(selected ? item.id : null),
          ),
        ),
  ];
}

String _heroTag(String profileId) => 'discover-profile-$profileId';

String _lookup(List<LookupItem> items, int? id) {
  if (id == null) return 'Not added';
  for (final item in items) {
    if (item.id == id) return item.name;
  }
  return 'Not added';
}

String _locationLabel(StaticData lookups, MatchProfile profile) {
  final parts = <String>[
    _lookup(lookups.countries, profile.countryId),
    _lookup(lookups.states, profile.stateId),
    _lookup(lookups.cities, profile.cityId),
  ].where((item) => item != 'Not added').toList(growable: false);

  if (parts.isEmpty) return 'Location not added';
  return parts.join(', ');
}

int _compatibilityScore(MatchProfile profile) {
  final seed = profile.profileId.codeUnits.fold<int>(0, (sum, value) => sum + value);
  return 78 + (seed % 15);
}

List<String> _profileImages(MatchProfile profile) {
  final images = <String>[
    ...profile.pictures.where((item) => item.isNotEmpty),
    if (profile.imageUrl != null && profile.imageUrl!.isNotEmpty) profile.imageUrl!,
  ];
  return images.toSet().toList(growable: false);
}

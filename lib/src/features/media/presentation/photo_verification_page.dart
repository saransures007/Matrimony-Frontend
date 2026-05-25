import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_picture_repository.dart';

class PhotoVerificationPage extends ConsumerStatefulWidget {
  const PhotoVerificationPage({super.key});

  @override
  ConsumerState<PhotoVerificationPage> createState() =>
      _PhotoVerificationPageState();
}

class _PhotoVerificationPageState
    extends ConsumerState<PhotoVerificationPage> {
  int? _selectedPrimaryPictureId;
  bool _consent = false;
  bool _submitting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final picturesAsync = ref.watch(profilePicturesProvider);
    final verificationAsync = ref.watch(photoVerificationStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium photo verification'),
      ),
      body: SafeArea(
        child: picturesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text('Failed to load: $e')),
          data: (pictures) {
            return verificationAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (e, _) =>
                  Center(child: Text('Failed to load status: $e')),
              data: (status) {
                if (status.verified) {
                  final approvedIds = status.approvedPictureIds.toSet();
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(
                        title: 'Verified',
                        subtitle: 'Your profile photos are trusted for viewing.',
                        icon: Icons.verified_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _SectionTitle(title: 'Approved photos'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: pictures
                            .where((p) => approvedIds.contains(p.id))
                            .map(
                              (p) => _PhotoChip(
                                url: p.url,
                                label: p.isProfilePic ? 'Primary' : 'Photo',
                                isApproved: true,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Continue'),
                      ),
                    ],
                  );
                }

                _selectedPrimaryPictureId ??= pictures.isEmpty
                    ? null
                    : pictures.firstWhere(
                        (p) => p.uploadStatus == 'uploaded',
                        orElse: () => pictures.first,
                      ).id;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(
                      title: 'Pro verification',
                      subtitle:
                          'Choose a primary photo, confirm consent, then submit.',
                      icon: Icons.photo_camera_back_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProgressStepsBar(currentStep: 3),
                    const SizedBox(height: 14),
                    _StepCard(
                      stepIndex: 1,
                      title: 'Select primary photo',
                      subtitle:
                          'This photo will be used for your verification.',
                      child: pictures.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Upload photos first.'),
                            )
                          : _PrimaryPhotoPicker(
                              pictures: pictures,
                              selectedId: _selectedPrimaryPictureId,
                              onSelected: (id) {
                                setState(() {
                                  _selectedPrimaryPictureId = id;
                                  _error = null;
                                });
                              },
                            ),
                    ),
                    _StepCard(
                      stepIndex: 2,
                      title: 'Consent',
                      subtitle:
                          'I agree to automated photo verification for trust & safety.',
                      child: CheckboxListTile(
                        value: _consent,
                        onChanged: (value) {
                          setState(() {
                            _consent = value ?? false;
                            _error = null;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('I consent to photo verification'),
                        subtitle: const Text(
                          'Your identity is processed to reduce fake profiles.',
                          maxLines: 2,
                        ),
                      ),
                    ),
                    _StepCard(
                      stepIndex: 3,
                      title: 'Submit',
                      subtitle: status.status == 'pending'
                          ? 'Verification is pending—submit again to proceed.'
                          : 'Submit to verify your photos.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          FilledButton.icon(
                            onPressed: (_submitting ||
                                    _selectedPrimaryPictureId == null ||
                                    !_consent)
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    setState(() {
                                      _submitting = true;
                                      _error = null;
                                    });
                                    try {
                                      await ref
                                          .read(profilePictureRepositoryProvider)
                                          .submitVerification(
                                            primaryPictureId:
                                                _selectedPrimaryPictureId,
                                          );

                                      ref.invalidate(profilePicturesProvider);
                                      ref.invalidate(
                                        photoVerificationStatusProvider,
                                      );

                                      if (!mounted) return;
                                      setState(() => _submitting = false);

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Verification submitted. Updates will appear shortly.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      setState(() {
                                        _submitting = false;
                                        _error = e.toString();
                                      });
                                    }
                                  },
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.shield_outlined),
                            label: Text(
                              _submitting ? 'Submitting...' : 'Verify photos',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Premium trust badge unlocks faster matching. This demo uses a server-side stub until liveness provider is integrated.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProgressStepsBar extends StatelessWidget {
  const _ProgressStepsBar({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final items = const [1, 2, 3];
    return Row(
      children: items.map((i) {
        final done = i < currentStep;
        final active = i == currentStep;
        final color = done
            ? const Color(0xFF22C55E)
            : active
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0);
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step $i',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active
                          ? const Color(0xFF2563EB)
                          : Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: gradient,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int stepIndex;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                child: Text(
                  '$stepIndex',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PrimaryPhotoPicker extends StatelessWidget {
  const _PrimaryPhotoPicker({
    required this.pictures,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ProfilePicture> pictures;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: pictures.map((p) {
        final approved = p.isApproved;
        final selected = p.id == selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (selected) return;
            onSelected(p.id);
          },
          child: Container(
            width: 92,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : approved
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFE2E8F0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              Container(color: const Color(0xFFF1F5F9)),
                        ),
                        if (approved)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        if (selected)
                          Positioned.fill(
                            child: Container(
                              color: const Color(0x332563EB),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.isProfilePic ? 'Primary' : 'Photo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhotoChip extends StatelessWidget {
  const _PhotoChip({
    required this.url,
    required this.label,
    required this.isApproved,
  });

  final String url;
  final String label;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isApproved ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: isApproved ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) =>
                    Container(color: const Color(0xFFF1F5F9)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/profile_picture_repository.dart';

class ProfilePictureUploadPage extends ConsumerStatefulWidget {
  const ProfilePictureUploadPage({super.key});

  @override
  ConsumerState<ProfilePictureUploadPage> createState() =>
      _ProfilePictureUploadPageState();
}

class _ProfilePictureUploadPageState
    extends ConsumerState<ProfilePictureUploadPage> {
  final _picker = ImagePicker();
  List<XFile> _files = const [];
  bool _uploading = false;
  String? _error;

  static const _maxPhotos = 8;

  @override
  Widget build(BuildContext context) {
    final picturesAsync = ref.watch(profilePicturesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profile photos'),
        actions: [
          TextButton.icon(
            onPressed: _uploading ? null : _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Add'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: picturesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (pictures) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _HeroCard(
              title: 'Make your profile stand out',
              subtitle:
                  'Upload clear photos, choose a primary image, and submit in a polished step-by-step flow.',
              stats: [
                ('Selected', '${_files.length}/$_maxPhotos'),
                ('Approved', '${pictures.where((p) => p.isApproved).length}'),
                ('Primary', '${pictures.where((p) => p.isProfilePic).length}'),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressRail(
              step: _uploading ? 3 : (_files.isEmpty ? 1 : 2),
            ),
            const SizedBox(height: 16),
            _ModernSectionCard(
              title: 'Your current photos',
              subtitle: 'Manage visible photos and keep your primary image fresh.',
              child: pictures.isEmpty
                  ? const _RequiredPhotoNotice()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pictures.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final picture = pictures[index];
                        return _PhotoCard(
                          picture: picture,
                          uploading: _uploading,
                          onDelete: pictures.length <= 1
                              ? null
                              : () async {
                                  await ref
                                      .read(profilePictureRepositoryProvider)
                                      .deleteProfilePicture(picture.id);
                                  ref.invalidate(profilePicturesProvider);
                                },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _ModernSectionCard(
              title: 'Upload queue',
              subtitle:
                  'Pick up to $_maxPhotos photos. We’ll upload them securely to Cloudflare R2.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionBar(
                    onPick: _uploading || _files.length >= _maxPhotos
                        ? null
                        : _pickImages,
                    onClear: _uploading || _files.isEmpty ? null : _clearQueue,
                    count: _files.length,
                    maxCount: _maxPhotos,
                  ),
                  const SizedBox(height: 12),
                  if (_files.isEmpty)
                    const _EmptyQueue()
                  else
                    ..._files.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;
                      return _QueuedFileTile(
                        file: file,
                        position: index + 1,
                        uploading: _uploading,
                        onRemove: () => setState(
                          () => _files = _files
                              .where((item) => item.path != file.path)
                              .toList(growable: false),
                        ),
                      );
                    }),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _files.isEmpty || _uploading ? null : _upload,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _uploading ? 'Uploading...' : 'Upload to Cloudflare',
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

  Future<void> _pickImages() async {
    final remaining = _maxPhotos - _files.length;
    final files = await _picker.pickMultiImage(limit: remaining);
      setState(() {
        _files = [..._files, ...files].take(_maxPhotos).toList(growable: false);
        _error = null;
      });
  }

  void _clearQueue() {
    setState(() {
      _files = const [];
      _error = null;
    });
  }

  Future<void> _upload() async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref
          .read(profilePictureRepositoryProvider)
          .uploadProfilePictures(_files);
      ref.invalidate(profilePicturesProvider);
      if (mounted) {
        setState(() {
          _files = const [];
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.stats,
  });

  final String title;
  final String subtitle;
  final List<(String label, String value)> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: stats
                .map(
                  (stat) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.$1,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat.$2,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProgressRail extends StatelessWidget {
  const _ProgressRail({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Select', 'Choose photos'),
      ('Review', 'Inspect queue'),
      ('Upload', 'Send to Cloudflare'),
    ];
    return Row(
      children: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        final active = index <= step;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: active ? const Color(0xFF1D4ED8) : Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  const _ModernSectionCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPick,
    required this.onClear,
    required this.count,
    required this.maxCount,
  });

  final VoidCallback? onPick;
  final VoidCallback? onClear;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(count == 0 ? 'Choose photos' : 'Add more'),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count/$maxCount',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black54,
              ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: onClear,
          child: const Text('Clear'),
        ),
      ],
    );
  }
}

class _QueuedFileTile extends StatelessWidget {
  const _QueuedFileTile({
    required this.file,
    required this.position,
    required this.uploading,
    required this.onRemove,
  });

  final XFile file;
  final int position;
  final bool uploading;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0E7FF),
          child: Text(
            '$position',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(file.name),
        subtitle: Text(uploading ? 'Uploading...' : 'Queued for upload'),
        trailing: IconButton(
          tooltip: 'Remove file',
          onPressed: uploading ? null : onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.picture,
    required this.uploading,
    required this.onDelete,
  });

  final ProfilePicture picture;
  final bool uploading;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: picture.isProfilePic
              ? const Color(0xFF2563EB)
              : picture.isApproved
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFE2E8F0),
          width: picture.isProfilePic ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    picture.url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  if (picture.isProfilePic)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _Badge(
                        label: 'Primary',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  if (picture.isApproved)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _Badge(
                        label: 'Approved',
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      picture.isProfilePic ? 'Primary photo' : 'Photo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: uploading ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete photo',
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.cloud_upload_outlined, size: 28),
          SizedBox(height: 10),
          Text(
            'No files selected yet.',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 6),
          Text(
            'Choose photos to build a clean upload queue before sending them to Cloudflare.',
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _RequiredPhotoNotice extends StatelessWidget {
  const _RequiredPhotoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'At least one profile photo is required.',
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

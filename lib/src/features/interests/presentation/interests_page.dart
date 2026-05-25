import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/interests_repository.dart';
import '../domain/interest_item.dart';
import '../../discovery/presentation/profile_details_page.dart';

class InterestsPage extends ConsumerWidget {
  const InterestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Interests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _InterestList(type: _InterestListType.received),
            _InterestList(type: _InterestListType.sent),
            _InterestList(type: _InterestListType.matches),
          ],
        ),
      ),
    );
  }
}

enum _InterestListType { received, sent, matches }

class _InterestList extends ConsumerWidget {
  const _InterestList({required this.type});

  final _InterestListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = switch (type) {
      _InterestListType.received => receivedInterestsProvider,
      _InterestListType.sent => sentInterestsProvider,
      _InterestListType.matches => interestMatchesProvider,
    };

    return ref
        .watch(provider)
        .when(
          data: (items) => items.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _InterestTile(item: items[index], type: type);
                  },
                ),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }
}

class _InterestTile extends ConsumerWidget {
  const _InterestTile({required this.item, required this.type});

  final InterestItem item;
  final _InterestListType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ProfileDetailsPage(profileId: item.profile.profileId),
          ),
        ),
        leading: CircleAvatar(
          backgroundImage: item.profile.imageUrl == null
              ? null
              : NetworkImage(item.profile.imageUrl!),
          child: item.profile.imageUrl == null
              ? const Icon(Icons.person_outline)
              : null,
        ),
        title: Text(item.profile.fullname),
        subtitle: Text(
          type == _InterestListType.sent
              ? item.status
              : item.profile.aboutMe ?? item.status,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: type == _InterestListType.received && item.likeId != null
            ? Wrap(
                spacing: 6,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Reject',
                    onPressed: () async {
                      await ref
                          .read(interestsRepositoryProvider)
                          .reject(item.likeId!);
                      ref.invalidate(receivedInterestsProvider);
                    },
                    icon: const Icon(Icons.close),
                  ),
                  IconButton.filled(
                    tooltip: 'Accept',
                    onPressed: () async {
                      await ref
                          .read(interestsRepositoryProvider)
                          .accept(item.likeId!);
                      ref.invalidate(receivedInterestsProvider);
                      ref.invalidate(interestMatchesProvider);
                    },
                    icon: const Icon(Icons.favorite),
                  ),
                ],
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Nothing here yet. New interests will appear here.'),
    );
  }
}

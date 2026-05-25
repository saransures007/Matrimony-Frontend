import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lookups/data/static_data_repository.dart';
import '../../lookups/domain/lookup_item.dart';
import '../data/matches_repository.dart';
import '../domain/match_profile.dart';

class ProfileDetailsPage extends ConsumerWidget {
  const ProfileDetailsPage({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDetailsProvider(profileId));
    final lookupsAsync = ref.watch(staticDataProvider);

    return Scaffold(
      body: profileAsync.when(
        data: (profile) => lookupsAsync.when(
          data: (lookups) =>
              _ProfileDetails(profile: profile, lookups: lookups),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.profile, required this.lookups});

  final MatchProfile profile;
  final dynamic lookups;

  @override
  Widget build(BuildContext context) {
    final pictures = profile.pictures.isNotEmpty
        ? profile.pictures
        : [if (profile.imageUrl != null) profile.imageUrl!];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 340,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(profile.fullname),
            background: pictures.isEmpty
                ? Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person_outline, size: 96),
                  )
                : PageView(
                    children: pictures
                        .map(
                          (url) => Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.age} years • ${profile.gender} • ${profile.maritalStatus}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (profile.aboutMe?.isNotEmpty == true) ...[
                  const SizedBox(height: 18),
                  _Section(title: 'About', child: Text(profile.aboutMe!)),
                ],
                _Section(
                  title: 'Basic details',
                  child: _DetailGrid(
                    rows: [
                      _DetailRow('Profile for', profile.profileCreatedFor),
                      _DetailRow(
                        'Mother tongue',
                        _name(lookups.motherTongues, profile.motherTongueId),
                      ),
                      _DetailRow(
                        'Religion',
                        _name(lookups.religions, profile.religionId),
                      ),
                      _DetailRow(
                        'Caste',
                        _name(lookups.castes, profile.casteId),
                      ),
                      _DetailRow(
                        'Subcaste',
                        _name(lookups.subcastes, profile.subcasteId),
                      ),
                      _DetailRow(
                        'Kulam',
                        _name(lookups.kulams, profile.kulamId),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Location',
                  child: _DetailGrid(
                    rows: [
                      _DetailRow(
                        'Country',
                        _name(lookups.countries, profile.countryId),
                      ),
                      _DetailRow(
                        'State',
                        _name(lookups.states, profile.stateId),
                      ),
                      _DetailRow('City', _name(lookups.cities, profile.cityId)),
                    ],
                  ),
                ),
                _Section(
                  title: 'Education & career',
                  child: _DetailGrid(
                    rows: [
                      _DetailRow(
                        'Education',
                        _name(lookups.education, profile.educationDegreeId),
                      ),
                      _DetailRow(
                        'Occupation',
                        _name(lookups.occupation, profile.occupationRoleId),
                      ),
                      _DetailRow(
                        'Employed in',
                        _name(lookups.employedIn, profile.employedInId),
                      ),
                      _DetailRow(
                        'Income',
                        _name(lookups.incomes, profile.expectedSalaryId),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Physical details',
                  child: _DetailGrid(
                    rows: [
                      _DetailRow(
                        'Height',
                        _name(lookups.heights, profile.heightId),
                      ),
                      _DetailRow(
                        'Weight',
                        profile.weight == null
                            ? 'Not added'
                            : '${profile.weight} kg',
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

  String _name(List<LookupItem> items, int? id) {
    if (id == null) return 'Not added';
    return items.where((item) => item.id == id).firstOrNull?.name ??
        'Not added';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 126,
                    child: Text(
                      row.label,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailRow {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;
}

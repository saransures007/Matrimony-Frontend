import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

final profilePictureRepositoryProvider = Provider<ProfilePictureRepository>(
  (ref) {
    return ProfilePictureRepository(
      ref.watch(apiClientProvider),
      ref.watch(dioProvider),
    );
  },
);

final profilePicturesProvider = FutureProvider<List<ProfilePicture>>((ref) {
  return ref.watch(profilePictureRepositoryProvider).fetchProfilePictures();
});

final photoVerificationStatusProvider =
    FutureProvider<PhotoVerificationStatus>((ref) async {
  return ref.watch(profilePictureRepositoryProvider).fetchVerificationStatus();
});

class ProfilePicture {
  const ProfilePicture({
    required this.id,
    required this.url,
    required this.isProfilePic,
    required this.isApproved,
    required this.uploadStatus,
  });

  final int id;
  final String url;
  final bool isProfilePic;
  final bool isApproved;
  final String uploadStatus;

  factory ProfilePicture.fromJson(Map<String, dynamic> json) {
    return ProfilePicture(
      id: json['id'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      isProfilePic: json['isProfilePic'] as bool? ?? false,
      isApproved: json['isApproved'] as bool? ?? false,
      uploadStatus: json['uploadStatus'] as String? ?? 'uploaded',
    );
  }
}

class PhotoVerificationStatus {
  const PhotoVerificationStatus({
    required this.status,
    required this.verified,
    required this.approvedPictureIds,
  });

  /// pending | verified | not_started
  final String status;
  final bool verified;
  final List<int> approvedPictureIds;

  factory PhotoVerificationStatus.fromJson(Map<String, dynamic> json) {
    final ids = json['approvedPictureIds'];
    return PhotoVerificationStatus(
      status: json['status'] as String? ?? 'not_started',
      verified: json['verified'] as bool? ?? false,
      approvedPictureIds: ids is List
          ? ids.map((e) => (e as num).toInt()).toList(growable: false)
          : const [],
    );
  }
}

class ProfilePictureRepository {
  const ProfilePictureRepository(this._apiClient, this._dio);

  final ApiClient _apiClient;
  final Dio _dio;

  Future<List<ProfilePicture>> fetchProfilePictures() async {
    final response = await _apiClient.getJson('/media/profile-pictures');
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => ProfilePicture.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<PhotoVerificationStatus> fetchVerificationStatus() async {
    final response = await _apiClient.getJson(
      '/media/profile-pictures/verification/status',
    );
    final data = response['data'] as Object?;
    if (data is Map<String, dynamic>) {
      return PhotoVerificationStatus.fromJson(Map<String, dynamic>.from(data));
    }
    if (data is Map) {
      return PhotoVerificationStatus.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Unexpected API response format');
  }

  Future<void> submitVerification({int? primaryPictureId}) async {
    await _apiClient.postJson(
      '/media/profile-pictures/verification/submit',
      {
        'primaryPictureId': primaryPictureId,
        'consent': true,
      },
    );
  }

  Future<void> deleteProfilePicture(int pictureId) async {
    await _apiClient.deleteJson('/media/profile-pictures/$pictureId');
  }

  Future<void> uploadProfilePictures(List<XFile> files) async {
    final uploadSpecs = <Map<String, dynamic>>[];
    final bytesByName = <String, List<int>>{};

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final bytes = await file.readAsBytes();
      final contentType = file.mimeType ?? _normalizeMimeType(file.name);
      if (!_allowedTypes.contains(contentType)) {
        throw Exception('Only JPEG, PNG, and WEBP images are allowed.');
      }
      if (bytes.length > 8 * 1024 * 1024) {
        throw Exception('${file.name} is larger than 8MB.');
      }
      bytesByName[file.name] = bytes;
      uploadSpecs.add({
        'fileName': file.name,
        'contentType': contentType,
        'sizeBytes': bytes.length,
        'sortOrder': index,
        'isProfilePic': index == 0,
      });
    }

    final presignResponse = await _apiClient.postJson(
      '/media/profile-pictures/presign',
      {'files': uploadSpecs},
    );

    if (presignResponse['data'] == null) {
      throw Exception('❌ Presign API failed: No data returned');
    }

    final presigned = (presignResponse['data'] as List).cast<Map>();

    final completed = <Map<String, dynamic>>[];
    final uploadedKeys = <String>[];

    try {
      for (var index = 0; index < presigned.length; index++) {
        final upload = Map<String, dynamic>.from(presigned[index]);
        final spec = uploadSpecs[index];
        final bytes = bytesByName[spec['fileName']]!;
        await _putWithRetry(
          upload['uploadUrl'] as String,
          bytes,
          spec['contentType'] as String,
        );
        uploadedKeys.add(upload['storageKey'] as String);
        completed.add({
          'uploadId': upload['uploadId'],
          'storageKey': upload['storageKey'],
          'fileName': spec['fileName'],
          'contentType': spec['contentType'],
          'sizeBytes': spec['sizeBytes'],
          'publicUrl': upload['publicUrl'],
          'sortOrder': spec['sortOrder'],
          'isProfilePic': spec['isProfilePic'],
        });
      }

      await _apiClient.postJson('/media/profile-pictures/complete', {
        'uploads': completed,
      });
    } catch (_) {
      if (uploadedKeys.isNotEmpty) {
        await _apiClient.postJson('/media/profile-pictures/rollback', {
          'storageKeys': uploadedKeys,
        });
      }
      rethrow;
    }
  }



Future<void> _putWithRetry(
  String url,
  List<int> bytes,
  String contentType,
) async {
  Object? lastError;

  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      print('=== UPLOAD ATTEMPT ${attempt + 1} ===');

      final uri = Uri.parse(url);
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': contentType,
        },
        body: bytes,
      );

      print('Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');

    } catch (error) {
      print('Error on attempt ${attempt + 1}: $error');
      lastError = error;
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
  }

  throw lastError ?? Exception('Upload failed');
}
// ✅ Fix — return normalized single value
String _normalizeMimeType(String contentType) {
  switch (contentType) {
    case 'image/jpg':
    case 'image/jpeg':
      return 'image/jpeg';
    case 'image/png':
      return 'image/png';
    case 'image/webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}
}

const _allowedTypes = {'image/jpeg', 'image/jpg', 'image/png', 'image/webp'};

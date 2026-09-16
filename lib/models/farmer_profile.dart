import 'package:flutter/foundation.dart';

/// Immutable domain model representing a registered farmer profile.
@immutable
class FarmerProfile {
  /// Unique Firebase Authentication User ID.
  final String uid;

  /// Farmer's contact phone number with country code (e.g. `"+919876543210"`).
  final String phoneNumber;

  /// Full name of the farmer.
  final String name;

  /// Village or locality name.
  final String village;

  /// District name.
  final String district;

  /// State name.
  final String state;

  /// List of primary crop IDs cultivated by the farmer (e.g. `['tomato', 'wheat']`).
  final List<String> primaryCrops;

  /// Privacy preference: whether to back up raw leaf scan photos to cloud storage.
  /// Strictly defaults to false per PRD Section 8 guidelines.
  final bool photoBackupOptIn;

  /// Optional local file path or cloud URL to farmer's profile photo.
  final String? profilePhotoPath;

  /// Timestamp when the profile was initially created.
  final DateTime createdAt;

  /// Optional timestamp when the profile was last updated.
  final DateTime? updatedAt;

  const FarmerProfile({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    required this.village,
    required this.district,
    required this.state,
    this.primaryCrops = const [],
    this.photoBackupOptIn = false,
    this.profilePhotoPath,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to deserialize [FarmerProfile] from a Map (Firestore / SharedPreferences).
  ///
  /// Supports both snake_case and camelCase keys, and gracefully handles Firestore
  /// `Timestamp`, ISO-8601 strings, and integer millisecond timestamps.
  factory FarmerProfile.fromMap(Map<String, dynamic> map) {
    return FarmerProfile(
      uid: (map['uid'] ?? '') as String,
      phoneNumber:
          ((map['phone_number'] ?? map['phoneNumber']) ?? '') as String,
      name: (map['name'] ?? '') as String,
      village: (map['village'] ?? '') as String,
      district: (map['district'] ?? '') as String,
      state: (map['state'] ?? '') as String,
      primaryCrops: List<String>.from(
        ((map['primary_crops'] ?? map['primaryCrops']) ?? const []) as Iterable,
      ),
      photoBackupOptIn:
          ((map['photo_backup_opt_in'] ?? map['photoBackupOptIn']) as bool?) ??
              false,
      profilePhotoPath:
          (map['profile_photo_path'] ?? map['profilePhotoPath']) as String?,
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: (map['updated_at'] != null || map['updatedAt'] != null)
          ? _parseDateTime(map['updated_at'] ?? map['updatedAt'])
          : null,
    );
  }

  /// Alias factory constructor for JSON deserialization.
  factory FarmerProfile.fromJson(Map<String, dynamic> json) =>
      FarmerProfile.fromMap(json);

  /// Serializes [FarmerProfile] to a Map suitable for Firestore or SharedPreferences caching.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone_number': phoneNumber,
      'name': name,
      'village': village,
      'district': district,
      'state': state,
      'primary_crops': primaryCrops,
      'photo_backup_opt_in': photoBackupOptIn,
      if (profilePhotoPath != null) 'profile_photo_path': profilePhotoPath,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Alias method for JSON serialization.
  Map<String, dynamic> toJson() => toMap();

  /// Human-readable location string (e.g. `"Rampur, Varanasi, Uttar Pradesh"`).
  String get locationDisplay {
    final parts = [village, district, state].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  /// True if the farmer has filled in basic mandatory profile fields.
  bool get isProfileComplete =>
      name.trim().isNotEmpty &&
      village.trim().isNotEmpty &&
      district.trim().isNotEmpty;

  /// Creates a copy of this [FarmerProfile] with specified fields replaced.
  FarmerProfile copyWith({
    String? uid,
    String? phoneNumber,
    String? name,
    String? village,
    String? district,
    String? state,
    List<String>? primaryCrops,
    bool? photoBackupOptIn,
    String? profilePhotoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerProfile(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      primaryCrops: primaryCrops ?? this.primaryCrops,
      photoBackupOptIn: photoBackupOptIn ?? this.photoBackupOptIn,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FarmerProfile &&
        other.uid == uid &&
        other.phoneNumber == phoneNumber &&
        other.name == name &&
        other.village == village &&
        other.district == district &&
        other.state == state &&
        listEquals(other.primaryCrops, primaryCrops) &&
        other.photoBackupOptIn == photoBackupOptIn &&
        other.profilePhotoPath == profilePhotoPath &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        phoneNumber,
        name,
        village,
        district,
        state,
        Object.hashAll(primaryCrops),
        photoBackupOptIn,
        profilePhotoPath,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'FarmerProfile(uid: $uid, name: $name, phone: $phoneNumber, location: $locationDisplay, crops: $primaryCrops, photoBackup: $photoBackupOptIn, photo: $profilePhotoPath)';

  static DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is String) {
      return DateTime.tryParse(val) ?? DateTime.now();
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    // Duck-typing support for Cloud Firestore Timestamp without direct coupling
    try {
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// 사용자 정보 모델
///
/// 서버에서 받아온 사용자 정보를 표현합니다.
class User {
  final int userId;
  final String name;
  final String? email;
  final String? accountId;
  final String? phoneNumber;
  final String? birthDate;
  final String? profileImageUrl;

  User({
    required this.userId,
    required this.name,
    this.email,
    this.accountId,
    this.phoneNumber,
    this.birthDate,
    this.profileImageUrl,
  });

  /// JSON에서 User 객체 생성
  factory User.fromJson(Map<String, dynamic> json) {
    final dynamic userIdValue = json['user_id'] ?? json['userId'];
    final int parsedUserId = userIdValue is int
        ? userIdValue
        : int.tryParse(userIdValue?.toString() ?? '') ?? 0;

    return User(
      userId: parsedUserId,
      name: json['name'] as String,
      email: json['email'] as String?,
      accountId: json['account_id'] as String? ?? json['accountId'] as String?,
      phoneNumber:
          json['phone_number'] as String? ?? json['phoneNumber'] as String?,
      birthDate: json['birth_date'] as String? ?? json['birthDate'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  /// User 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'account_id': accountId,
      'phone_number': phoneNumber,
      'birth_date': birthDate,
      'profile_image_url': profileImageUrl,
    };
  }

  @override
  String toString() {
    return 'User(userId: $userId, name: $name, email: $email, accountId: $accountId, phoneNumber: $phoneNumber, birthDate: $birthDate, profileImageUrl: $profileImageUrl)';
  }
}

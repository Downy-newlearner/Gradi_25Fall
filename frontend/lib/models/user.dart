/// 사용자 정보 모델
///
/// 서버에서 받아온 사용자 정보를 표현합니다.
class User {
  final int userId;
  final String name;
  final String? profileImageUrl;
  // 추후 확장 가능: 이메일, 전화번호 등

  User({required this.userId, required this.name, this.profileImageUrl});

  /// JSON에서 User 객체 생성
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  /// User 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'profile_image_url': profileImageUrl,
    };
  }

  @override
  String toString() {
    return 'User(userId: $userId, name: $name, profileImageUrl: $profileImageUrl)';
  }
}

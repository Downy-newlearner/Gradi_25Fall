import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// FCM 초기화
  Future<void> initialize() async {
    // 알림 권한 요청
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('사용자가 알림 권한을 허용했습니다');
    } else {
      developer.log('사용자가 알림 권한을 거부했습니다');
      return;
    }

    // iOS에서 APNS 토큰 요청 (FCM 토큰을 받기 전에 필요)
    if (Platform.isIOS) {
      try {
        developer.log('🍎 iOS: APNS 토큰 요청 중...');
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          developer.log('✅ APNS 토큰 수신 성공');
          debugPrint('✅ APNS Token: $apnsToken');
        } else {
          developer.log('⚠️ APNS 토큰이 아직 설정되지 않았습니다 (시뮬레이터일 수 있음)');
          debugPrint('⚠️ APNS 토큰이 없습니다. 실제 기기에서 테스트하거나 나중에 다시 시도하세요.');
          // 시뮬레이터에서는 APNS 토큰을 얻을 수 없지만 계속 진행
        }
      } catch (e) {
        developer.log('⚠️ APNS 토큰 요청 중 오류 (시뮬레이터일 수 있음): $e');
        debugPrint('⚠️ APNS 토큰 오류 (시뮬레이터에서는 정상): $e');
        // 시뮬레이터에서는 APNS 토큰을 얻을 수 없지만 계속 진행
      }
    }

    // FCM 토큰 가져오기
    developer.log('🔔 FCM 토큰 요청 시작...');
    try {
      _fcmToken = await _firebaseMessaging.getToken();

      if (_fcmToken != null) {
        developer.log('✅ FCM 토큰 생성 성공!');
        developer.log('📱 FCM Token: $_fcmToken');
        developer.log('📏 토큰 길이: ${_fcmToken!.length}자');
        debugPrint('═══════════════════════════════════════');
        debugPrint('🔔 FCM 토큰 생성 완료');
        debugPrint('📱 Token: $_fcmToken');
        debugPrint('📏 길이: ${_fcmToken!.length}자');
        debugPrint('═══════════════════════════════════════');
      } else {
        developer.log('❌ FCM 토큰 생성 실패: 토큰이 null입니다');
        debugPrint('❌ FCM 토큰 생성 실패!');
      }
    } catch (e) {
      developer.log('⚠️ FCM 토큰 요청 실패: $e');
      debugPrint('⚠️ FCM 토큰 요청 실패: $e');
      if (Platform.isIOS) {
        developer.log('💡 iOS 시뮬레이터에서는 APNS 토큰이 없어 FCM 토큰을 받을 수 없습니다.');
        developer.log('💡 실제 기기에서 테스트하거나, APNS 인증서가 설정되어 있는지 확인하세요.');
        debugPrint('💡 iOS 시뮬레이터에서는 FCM 토큰을 받을 수 없습니다.');
        debugPrint('💡 실제 기기에서 테스트하세요.');
      }
      // 에러가 발생해도 앱은 계속 실행
    }

    // 토큰 갱신 리스너
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      developer.log('🔄 FCM Token 갱신됨');
      developer.log('📱 새 FCM Token: $newToken');
      developer.log('📏 새 토큰 길이: ${newToken.length}자');
      debugPrint('═══════════════════════════════════════');
      debugPrint('🔄 FCM 토큰 갱신 완료');
      debugPrint('📱 New Token: $newToken');
      debugPrint('📏 길이: ${newToken.length}자');
      debugPrint('═══════════════════════════════════════');
      // 서버에 새 토큰 전송
      _sendTokenToServer(newToken);
    });

    // 로컬 알림 초기화
    await _initializeLocalNotifications();

    // 백그라운드 메시지 핸들러 설정
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드에서 알림 탭 핸들러
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 앱이 종료된 상태에서 알림으로 앱 실행된 경우
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 서버에 토큰 전송
    if (_fcmToken != null) {
      await _sendTokenToServer(_fcmToken!);
    }
  }

  /// 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// 포그라운드 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('포그라운드 메시지 수신: ${message.messageId}');

    // 알림 표시
    _showLocalNotification(message);

    // TODO: 알림 목록 업데이트 (상태 관리 필요)
  }

  /// 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    developer.log('알림 탭됨: ${message.messageId}');

    // TODO: 알림 타입에 따라 페이지 이동
    final data = message.data;
    if (data.containsKey('type')) {
      // 예: Navigator.pushNamed(context, '/notification-detail');
    }
  }

  /// 로컬 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    developer.log('로컬 알림 탭됨: ${response.payload}');
    // TODO: 알림 상세 페이지로 이동
  }

  /// 서버에 FCM 토큰 전송
  Future<void> _sendTokenToServer(String token) async {
    try {
      // TODO: 실제 서버 API 엔드포인트로 변경
      const String serverUrl = 'https://your-backend-url.com/api/fcm/token';

      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fcm_token': token,
          'device_type': 'mobile', // Android 또는 iOS
          'user_id': 'current_user_id', // TODO: 현재 로그인한 사용자 ID
        }),
      );

      if (response.statusCode == 200) {
        developer.log('FCM 토큰이 서버에 성공적으로 전송되었습니다');
      } else {
        developer.log('FCM 토큰 전송 실패: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('FCM 토큰 전송 중 오류 발생: $e');
    }
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      // TODO: 실제 서버 API 엔드포인트로 변경
      final String serverUrl =
          'https://your-backend-url.com/api/notifications/$notificationId/read';

      final response = await http.put(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log('알림 읽음 처리 완료');
      }
    } catch (e) {
      developer.log('알림 읽음 처리 중 오류 발생: $e');
    }
  }
}

/// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('백그라운드 메시지 수신: ${message.messageId}');
  // TODO: 백그라운드에서 알림 데이터 저장 등 처리
}

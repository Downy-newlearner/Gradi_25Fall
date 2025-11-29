import 'dart:async';
import 'dart:developer' as developer;

import 'package:launchdarkly_event_source_client/launchdarkly_event_source_client.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// 이미지 업로드용 SSE 스트림 서비스
///
/// - 연결: GET /storage/storage/upload-stream
/// - 이벤트:
///   - event: "upload-url" → data: presigned URL 1개
///   - event: "ping" → keep-alive
class UploadSseService {
  SSEClient? _sseClient;
  StreamSubscription<Event>? _subscription;
  final StreamController<String> _uploadUrlController =
      StreamController<String>.broadcast();

  Stream<String> get uploadUrlStream => _uploadUrlController.stream;

  bool get isConnected => _sseClient != null;

  /// SSE 구독 시작
  Future<void> connect() async {
    if (_sseClient != null) {
      return;
    }

    try {
      final token = await AuthService().ensureValidAccessToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. SSE 연결을 시작할 수 없습니다.');
      }

      final uri = ApiConfig.getUploadStreamUri();
      developer.log('[UploadSseService] Connecting to $uri');

      // launchdarkly_event_source_client는 eventTypes를 Set으로 받습니다
      _sseClient = SSEClient(
        uri,
        {'upload-url', 'ping'}, // 수신할 이벤트 타입들
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('[UploadSseService] SSE connected');

      _subscription = _sseClient!.stream.listen(
        (Event event) {
          if (event is MessageEvent) {
            final eventType = event.type;
            final data = event.data;

            developer.log('[UploadSseService] event=$eventType, data=$data');

            if (eventType == 'upload-url' && data.isNotEmpty) {
              _uploadUrlController.add(data);
            } else if (eventType == 'ping') {
              // keep-alive
              developer.log('[UploadSseService] ping');
            }
          } else if (event is OpenEvent) {
            developer.log('[UploadSseService] Connection opened');
          }
        },
        onError: (error) {
          developer.log('[UploadSseService] Stream error: $error');
        },
        onDone: () {
          developer.log('[UploadSseService] Stream closed');
        },
      );
    } catch (e) {
      developer.log('[UploadSseService] SSE connect error: $e');
      rethrow;
    }
  }

  /// 구독 종료
  void disconnect() {
    try {
      _subscription?.cancel();
      _subscription = null;
      _sseClient?.close();
      _sseClient = null;
      developer.log('[UploadSseService] SSE disconnected');
    } catch (e) {
      developer.log('[UploadSseService] SSE disconnect error: $e');
    }
  }

  void dispose() {
    disconnect();
    _uploadUrlController.close();
  }
}

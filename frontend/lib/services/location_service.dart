import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

/// 위치 권한 및 현재 위치 조회를 담당하는 서비스
///
/// DI Container에서 singleton으로 관리되며,
/// 이 파일에서는 별도의 싱글톤 패턴을 구현하지 않습니다.
class LocationService {
  LocationService();

  /// 위치 권한 요청 및 현재 위치 가져오기
  Future<Position?> getCurrentLocation() async {
    try {
      // 위치 서비스 활성화 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services are disabled');
        return null;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log(
            'Location permissions are permanently denied, we cannot request permissions.');
        return null;
      }

      // 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      developer.log(
          'Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      developer.log('Error getting current location: $e');
      return null;
    }
  }

  /// 위치 권한 상태 확인
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}


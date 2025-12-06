import 'package:flutter/material.dart';
import '../../widgets/back_button.dart';

/// 알림 설정 페이지
/// 푸시 알림, 숙제 마감 알림, 학습 리마인더 등을 설정하는 페이지
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // TODO: 설정 값들을 SharedPreferences에 저장
  bool _pushNotification = true;
  bool _homeworkDeadline = true;
  bool _learningReminder = false;
  bool _academyNotice = true;
  bool _marketingNotification = false;

  String _reminderTime = '20:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 전체 알림
                    _buildSectionTitle('전체 알림'),
                    const SizedBox(height: 12),
                    _buildSwitchSetting(
                      title: '푸시 알림',
                      subtitle: '모든 알림 수신 여부',
                      value: _pushNotification,
                      onChanged: (value) {
                        setState(() {
                          _pushNotification = value;
                          if (!value) {
                            // 푸시 알림 끄면 모든 알림 끄기
                            _homeworkDeadline = false;
                            _learningReminder = false;
                            _academyNotice = false;
                            _marketingNotification = false;
                          }
                        });
                        // TODO: 알림 설정 저장
                      },
                    ),

                    const SizedBox(height: 24),

                    // 학습 관련 알림
                    _buildSectionTitle('학습 관련'),
                    const SizedBox(height: 12),
                    _buildSwitchSetting(
                      title: '숙제 마감 알림',
                      subtitle: '숙제 마감 1일 전, 당일에 알림',
                      value: _homeworkDeadline,
                      onChanged: _pushNotification
                          ? (value) {
                              setState(() {
                                _homeworkDeadline = value;
                              });
                              // TODO: 알림 설정 저장
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchSetting(
                      title: '학습 리마인더',
                      subtitle: '매일 정해진 시간에 학습 알림',
                      value: _learningReminder,
                      onChanged: _pushNotification
                          ? (value) {
                              setState(() {
                                _learningReminder = value;
                              });
                              // TODO: 알림 설정 저장
                            }
                          : null,
                    ),
                    if (_learningReminder) ...[
                      const SizedBox(height: 12),
                      _buildTimeSelector(),
                    ],

                    const SizedBox(height: 24),

                    // 학원 관련 알림
                    _buildSectionTitle('학원 관련'),
                    const SizedBox(height: 12),
                    _buildSwitchSetting(
                      title: '학원 공지사항',
                      subtitle: '등록된 학원의 공지사항 알림',
                      value: _academyNotice,
                      onChanged: _pushNotification
                          ? (value) {
                              setState(() {
                                _academyNotice = value;
                              });
                              // TODO: 알림 설정 저장
                            }
                          : null,
                    ),

                    const SizedBox(height: 24),

                    // 기타 알림
                    _buildSectionTitle('기타'),
                    const SizedBox(height: 12),
                    _buildSwitchSetting(
                      title: '마케팅 알림',
                      subtitle: '이벤트, 혜택 등의 마케팅 정보',
                      value: _marketingNotification,
                      onChanged: _pushNotification
                          ? (value) {
                              setState(() {
                                _marketingNotification = value;
                              });
                              // TODO: 알림 설정 저장
                            }
                          : null,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: const [
          CustomBackButton(),
          SizedBox(width: 20),
          Text(
            '알림 설정',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: onChanged == null
                        ? const Color(0xFF999999)
                        : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFAC5BF8),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text(
            '알림 시간',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.parse(_reminderTime.split(':')[0]),
                  minute: int.parse(_reminderTime.split(':')[1]),
                ),
              );
              if (picked != null) {
                setState(() {
                  _reminderTime =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
                // TODO: 알림 시간 저장
              }
            },
            child: Row(
              children: [
                Text(
                  _reminderTime,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFFAC5BF8),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Color(0xFFAC5BF8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


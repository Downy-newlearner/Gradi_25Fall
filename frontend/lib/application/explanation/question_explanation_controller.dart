import 'package:flutter/foundation.dart';

import '../../domain/explanation/explanation_entity.dart';
import '../../domain/explanation/explanation_source.dart';
import 'explanation_service.dart';

/// 해설 화면 상태
class QuestionExplanationState {
  final bool isLoading;
  final String? errorMessage;
  final ExplanationEntity? explanation;

  /// 마지막 load 호출에서 실제로 해설 생성 요청(POST)이 수행되었는지 여부
  final bool lastRequestPerformed;

  const QuestionExplanationState({
    required this.isLoading,
    this.errorMessage,
    this.explanation,
    required this.lastRequestPerformed,
  });

  const QuestionExplanationState.initial()
      : isLoading = false,
        errorMessage = null,
        explanation = null,
        lastRequestPerformed = false;

  QuestionExplanationState copyWith({
    bool? isLoading,
    String? errorMessage,
    ExplanationEntity? explanation,
    bool? lastRequestPerformed,
  }) {
    return QuestionExplanationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      explanation: explanation ?? this.explanation,
      lastRequestPerformed: lastRequestPerformed ?? this.lastRequestPerformed,
    );
  }
}

/// 해설 조회/생성을 담당하는 Controller (ViewModel)
class QuestionExplanationController extends ChangeNotifier {
  final ExplanationService _service;

  QuestionExplanationState _state =
      const QuestionExplanationState.initial();
  QuestionExplanationState get state => _state;

  QuestionExplanationController({required ExplanationService service})
      : _service = service;

  /// 이미 생성된 해설만 조회하는 진입 시 로딩용 메서드
  ///
  /// 해설이 없으면 POST를 수행하지 않고, [lastRequestPerformed]도 false로 유지됩니다.
  Future<void> loadExisting(ExplanationSource source) async {
    _setState(
      _state.copyWith(
        isLoading: true,
        errorMessage: null,
        lastRequestPerformed: false,
      ),
    );
    try {
      final existing = await _service.loadExistingExplanation(source);
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: null,
          explanation: existing,
          lastRequestPerformed: false,
        ),
      );
    } catch (_) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: '해설을 불러오지 못했습니다.',
          lastRequestPerformed: false,
        ),
      );
    }
  }

  /// 해설 요청 버튼 클릭 시 사용하는 메서드
  ///
  /// 필요 시 해설 생성 POST까지 수행하며, 이때 [lastRequestPerformed]가 true가 됩니다.
  Future<void> load(ExplanationSource source) async {
    _setState(
      _state.copyWith(
        isLoading: true,
        errorMessage: null,
        lastRequestPerformed: false,
      ),
    );
    try {
      final result = await _service.loadOrRequestExplanation(source);
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: null,
          explanation: result.explanation,
          lastRequestPerformed: result.requestPerformed,
        ),
      );
    } catch (_) {
      _setState(
        _state.copyWith(
          isLoading: false,
          errorMessage: '해설을 불러오지 못했습니다.',
          lastRequestPerformed: false,
        ),
      );
    }
  }

  Future<void> requestAgain(ExplanationSource source) async {
    await load(source);
  }

  void _setState(QuestionExplanationState newState) {
    _state = newState;
    notifyListeners();
  }
}


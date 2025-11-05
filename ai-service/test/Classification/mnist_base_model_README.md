`mnist_base_model.ipynb` 코드에 대한 설명입니다.

해당 코드는 answer_1, answer_2의 crop image에 나타난 숫자를 예측(인식)하기 전 기초 단계입니다.

현재 프로젝트에서 모델이 1~5 사이 숫자를 예측해야 하는 상황입니다.
우선 모델에게 mnist를 학습시켜 숫자 손글씨 인식 능력을 부여합니다.

*base model 후보*
1. EfficientNet-B0
2. ResNet18
3. MobileNetV3

위 3가지 모델에 대한 mnist 학습은 이미 완료되었으며
**따라서, `mnist_base_model.ipynb` 코드는 실행할 필요가 없습니다.**
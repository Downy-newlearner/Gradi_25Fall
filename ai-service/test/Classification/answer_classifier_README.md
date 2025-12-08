`answer_classifier.ipynb` 코드에 대한 설명입니다.

해당 코드는 mnist를 학습시킨 3가지 base model에 추가적으로 answer_1, answer_2를 finetuned한 코드입니다.
mnist_base_model.ipynb에서 학습 완료된 모델 마지막 레이어를 5-class로 변환하여 answer_1, answer_2를 맞출 수 있도록 변경합니다.

데이터셋이 상대적으로 적기 때문에 증강을 적용했으며 5-fold validation을 적용해 성능을 확인하였습니다. 

*결과 모델 (총 6가지)*
1. answer_1의 EfficientNet-B0
2. answer_2의 EfficientNet-B0
3. answer_1의 ResNet18
4. answer_2의 ResNet18
5. answer_1의 MobileNetV3
6. answer_2의 MobileNetV3


*Best CV 성능 결과*
############################################################
############################################################
answer_1의 ResNet18: Best CV Validation Acc: 94.20%
answer_2의 ResNet18: Best CV Validation Acc: 100.00%

answer_1의 EfficientNet-B0: Best CV Validation Acc: 85.92%
answer_2의 EfficientNet-B0: Best CV Validation Acc: 100.00%

answer_1의 MobileNetV3: Best CV Validation Acc: 80.58%
answer_2의 MobileNetV3: Best CV Validation Acc: 100.00%

############################################################
############################################################


*평균 성능 결과*
############################################################
############################################################
📊 answer_1 평균 Validation Accuracy (Cross Validation):
  EFFICIENTNET: 83.82%
  RESNET: 91.28%
  MOBILENET: 77.04%

📊 answer_2 평균 Validation Accuracy (Cross Validation):
  EFFICIENTNET: 99.89%
  RESNET: 99.78%
  MOBILENET: 99.35%
############################################################
############################################################

위 6가지 모델에 대한 미세조정 학습은 이미 완료되었으며
**따라서, `answer_classifier.ipynb` 코드는 실행할 필요가 없습니다.**


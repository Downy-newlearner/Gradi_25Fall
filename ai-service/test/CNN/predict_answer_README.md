`predict_anser.ipynb` 코드에 대한 설명입니다.

'answer_classifie.ipynb'에서 학습이 완료된 모델 6가지를 Kaggle에서 불러와 테스트를 진행합니다.

*test dataset 다운로드 링크*
answer_1: [text](https://drive.google.com/drive/folders/1A7LzAO8lTPCwhgckuZhMyPpbs_lUfdK3?usp=sharing)
answer_2: [text](https://drive.google.com/drive/folders/15EoIKLGbeLyOjLL_T7rua48TyyhdOZR3?usp=sharing)

*최종 성능 요약*
############################################################
############################################################
📊 answer_1 성능:
  RESNET      :  98.74% (1019/1032)
  EFFICIENTNET:  96.51% (996/1032)
  MOBILENET   :  90.50% (934/1032)

📊 answer_2 성능:
  RESNET      : 100.00% (927/927)
  EFFICIENTNET: 100.00% (927/927)
  MOBILENET   : 100.00% (927/927)
############################################################
############################################################ 

answer_1과 answer_2의 평균 차이가 나는 이유는 상대적으로 answer_1의 난이도가 높기 때문입니다. 
(answer_1의 경우 체크 표시에 숫자가 가려져 예측에 어려움을 겪는 경우가 발생합니다.)

`predict_anser.ipynb`를 실행하여 모델 테스트를 진행하세요!
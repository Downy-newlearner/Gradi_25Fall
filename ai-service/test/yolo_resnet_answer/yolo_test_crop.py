import logging
import time
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import cv2
import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms
from models.Detection.legacy.Model_routing_1104.run_routed_inference import RoutedInference as RoutedInference_1104
from models.Detection.legacy.Model_routing_1004.run_routed_inference import RoutedInference as RoutedInference_1004
from models.Recognition.ocr import OCRModel

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ResNetClassifier:
    """ResNet 기반 답안 분류 모델 (1-5 분류)"""
    
    def __init__(self, model_path: str, device: str = 'cuda'):
        """
        Args:
            model_path: ResNet 모델 가중치 파일 경로 (.pth)
            device: 'cuda' 또는 'cpu'
        """
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model = self._load_model(model_path)
        self.transform = self._get_transform()
        
        logger.info(f"✅ ResNet 모델 로드 완료: {model_path}")
        logger.info(f"   디바이스: {self.device}")
    
    def _load_model(self, model_path: str):
        """ResNet 모델 로드 - 커스텀 구조"""
        import torch.nn as nn
        
        # 커스텀 ResNet18 구조 (shortcut 사용, grayscale 입력)
        class BasicBlock(nn.Module):
            expansion = 1
            
            def __init__(self, in_channels, out_channels, stride=1):
                super(BasicBlock, self).__init__()
                self.conv1 = nn.Conv2d(in_channels, out_channels, kernel_size=3, stride=stride, padding=1, bias=False)
                self.bn1 = nn.BatchNorm2d(out_channels)
                self.conv2 = nn.Conv2d(out_channels, out_channels, kernel_size=3, stride=1, padding=1, bias=False)
                self.bn2 = nn.BatchNorm2d(out_channels)
                
                self.shortcut = nn.Sequential()
                if stride != 1 or in_channels != out_channels:
                    self.shortcut = nn.Sequential(
                        nn.Conv2d(in_channels, out_channels, kernel_size=1, stride=stride, bias=False),
                        nn.BatchNorm2d(out_channels)
                    )
            
            def forward(self, x):
                out = torch.relu(self.bn1(self.conv1(x)))
                out = self.bn2(self.conv2(out))
                out += self.shortcut(x)
                out = torch.relu(out)
                return out
        
        class CustomResNet18(nn.Module):
            def __init__(self, num_classes=5):
                super(CustomResNet18, self).__init__()
                # Grayscale 입력 (1 채널)
                self.conv1 = nn.Conv2d(1, 64, kernel_size=3, stride=1, padding=1, bias=False)
                self.bn1 = nn.BatchNorm2d(64)
                
                # ResNet18 구조
                self.layer1 = self._make_layer(64, 64, 2, stride=1)
                self.layer2 = self._make_layer(64, 128, 2, stride=2)
                self.layer3 = self._make_layer(128, 256, 2, stride=2)
                self.layer4 = self._make_layer(256, 512, 2, stride=2)
                
                self.avgpool = nn.AdaptiveAvgPool2d((1, 1))
                self.fc = nn.Linear(512, num_classes)
            
            def _make_layer(self, in_channels, out_channels, num_blocks, stride):
                layers = []
                layers.append(BasicBlock(in_channels, out_channels, stride))
                for _ in range(1, num_blocks):
                    layers.append(BasicBlock(out_channels, out_channels, 1))
                return nn.Sequential(*layers)
            
            def forward(self, x):
                out = torch.relu(self.bn1(self.conv1(x)))
                out = self.layer1(out)
                out = self.layer2(out)
                out = self.layer3(out)
                out = self.layer4(out)
                out = self.avgpool(out)
                out = out.view(out.size(0), -1)
                out = self.fc(out)
                return out
        
        # 모델 생성
        model = CustomResNet18(num_classes=5)
        
        # 가중치 로드 (PyTorch 2.6+ 호환)
        try:
            checkpoint = torch.load(model_path, map_location=self.device, weights_only=False)
        except TypeError:
            checkpoint = torch.load(model_path, map_location=self.device)
        
        # state_dict 추출
        if isinstance(checkpoint, dict):
            if 'model_state_dict' in checkpoint:
                state_dict = checkpoint['model_state_dict']
            elif 'state_dict' in checkpoint:
                state_dict = checkpoint['state_dict']
            else:
                state_dict = checkpoint
        else:
            state_dict = checkpoint
        
        model.load_state_dict(state_dict)
        model.to(self.device)
        model.eval()
        
        return model
    
    def _get_transform(self):
        """이미지 전처리 변환 - MNIST 스타일"""
        return transforms.Compose([
            transforms.ToPILImage(),
            transforms.Grayscale(num_output_channels=1),  # Grayscale 변환
            transforms.Resize((28, 28)),  # MNIST 크기
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.1307], std=[0.3081])  # MNIST 정규화
        ])
    
    def predict(self, image_path: str) -> Tuple[Optional[str], float]:
        """
        이미지에서 답안 번호 예측
        
        Args:
            image_path: 이미지 파일 경로
            
        Returns:
            Tuple[Optional[str], float]: (예측된 답안 번호 '1'-'5', 신뢰도)
        """
        try:
            # 이미지 로드 (BGR)
            image = cv2.imread(image_path)
            if image is None:
                logger.error(f"이미지 로드 실패: {image_path}")
                return None, 0.0
            
            # RGB로 변환 (PIL은 RGB를 기대)
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # 전처리 (Grayscale 변환 포함)
            input_tensor = self.transform(image_rgb).unsqueeze(0).to(self.device)
            
            # 추론
            with torch.no_grad():
                outputs = self.model(input_tensor)
                probabilities = torch.softmax(outputs, dim=1)
                confidence, predicted = torch.max(probabilities, 1)
            
            # 결과 변환 (0-4 → 1-5)
            answer = str(predicted.item() + 1)
            conf = confidence.item()
            
            logger.info(f"ResNet 예측: 답안={answer}, 신뢰도={conf:.4f}")
            
            return answer, conf
            
        except Exception as e:
            logger.error(f"ResNet 예측 실패: {e}", exc_info=True)
            return None, 0.0


class HierarchicalCropPipeline:
    """계층적 크롭 파이프라인: 페이지 → Section → 문제번호 및 정답 (answer_1 crop 후 ResNet 분류)"""
    
    def __init__(self, model_dir_1104: str, model_dir_1004: str, 
                 section_padding: int = 50,
                 answer_key_path: Optional[str] = None,
                 resnet_model_path: Optional[str] = None):
        """
        Args:
            model_dir_1104: 1104 모델 경로
            model_dir_1004: 1004 모델 경로
            section_padding: Section crop 시 추가할 여백 (픽셀). 기본값 50
            answer_key_path: 답지 파일 경로 (txt 파일)
            resnet_model_path: ResNet 모델 경로 (.pth 파일)
        """
        self.router_1104 = RoutedInference_1104(model_dir_1104)  # 답안 추론용
        self.router_1004 = RoutedInference_1004(model_dir_1004)  # 크롭용 (페이지번호, 문제번호, section)
        self.ocr = OCRModel()
        self.section_padding = section_padding
        
        # ✨ ResNet 모델 초기화
        self.resnet_classifier = None
        if resnet_model_path and os.path.exists(resnet_model_path):
            try:
                self.resnet_classifier = ResNetClassifier(resnet_model_path)
                logger.info("✅ ResNet 분류 모델 로드 성공")
            except Exception as e:
                logger.error(f"❌ ResNet 모델 로드 실패: {e}")
                logger.warning("ResNet 분류를 사용할 수 없습니다.")
        else:
            if resnet_model_path:
                logger.warning(f"ResNet 모델 파일을 찾을 수 없습니다: {resnet_model_path}")
            logger.info("ResNet 분류 없이 실행됩니다.")
        
        # 답지 로드
        self.answer_key = self._load_answer_key(answer_key_path) if answer_key_path else None
        
        logger.info("HierarchicalCropPipeline 초기화 (두 개의 모델 + OCR 모델 로드 완료)")
        logger.info("  - 1104 모델: 답안 추론용 (answer_1 검출)")
        logger.info("  - 1004 모델: 페이지번호, 문제번호, section 크롭용")
        logger.info(f"  - Section padding: {section_padding}px")
        logger.info(f"  - ResNet 분류: {'사용 가능' if self.resnet_classifier else '사용 불가'}")
        if self.answer_key:
            logger.info(f"  - 답지 로드 완료: {len(self.answer_key)}개 페이지")
    
    def _load_answer_key(self, answer_key_path: str) -> Dict[str, List[Dict]]:
        """답지 파일 로드
        
        파일 형식: 페이지번호, 문제번호, 정답
        예: 1, 1, 3
        
        Returns:
            Dict[str, List[Dict]]: {페이지번호: [{'problem': 문제번호, 'answer': 정답}, ...]}
        """
        answer_key = {}
        try:
            with open(answer_key_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    
                    parts = [p.strip() for p in line.split(',')]
                    if len(parts) >= 3:
                        page_num = parts[0]
                        problem_num = parts[1]
                        answer = parts[2]
                        
                        if page_num not in answer_key:
                            answer_key[page_num] = []
                        
                        answer_key[page_num].append({
                            'problem': problem_num,
                            'answer': answer
                        })
            
            logger.info(f"답지 로드 완료: {answer_key_path}")
            for page, problems in answer_key.items():
                logger.info(f"  페이지 {page}: {len(problems)}개 문제")
        
        except Exception as e:
            logger.error(f"답지 로드 실패: {e}")
            return {}
        
        return answer_key
    
    def is_valid_page(self, page_number: Optional[str]) -> bool:
        """페이지 번호가 답지에 있는지 확인
        
        Args:
            page_number: OCR로 인식된 페이지 번호
            
        Returns:
            bool: 답지에 있으면 True, 답지가 없거나 페이지가 없으면 True (기본 처리)
        """
        if self.answer_key is None:
            # 답지가 없으면 모든 페이지 처리
            return True
        
        if page_number is None:
            logger.warning("페이지 번호를 인식하지 못했습니다. 건너뜁니다.")
            return False
        
        # 페이지 번호 정규화 (공백 제거, 문자열 변환)
        page_number_normalized = str(page_number).strip()
        
        is_valid = page_number_normalized in self.answer_key
        
        if not is_valid:
            logger.warning(f"페이지 {page_number}는 답지에 없습니다. 건너뜁니다.")
        else:
            logger.info(f"페이지 {page_number}는 답지에 있습니다. 처리를 계속합니다.")
        
        return is_valid
    
    def calculate_iou(self, bbox1: List[float], bbox2: List[float]) -> float:
        """두 바운딩 박스의 IoU(Intersection over Union) 계산
        
        Args:
            bbox1: [x1, y1, x2, y2]
            bbox2: [x1, y1, x2, y2]
            
        Returns:
            float: IoU 값 (0.0 ~ 1.0)
        """
        x1_1, y1_1, x2_1, y2_1 = bbox1
        x1_2, y1_2, x2_2, y2_2 = bbox2
        
        # 겹치는 영역 계산
        x1_i = max(x1_1, x1_2)
        y1_i = max(y1_1, y1_2)
        x2_i = min(x2_1, x2_2)
        y2_i = min(y2_1, y2_2)
        
        if x2_i <= x1_i or y2_i <= y1_i:
            return 0.0
        
        # Intersection 면적
        intersection = (x2_i - x1_i) * (y2_i - y1_i)
        
        # 각 박스의 면적
        area1 = (x2_1 - x1_1) * (y2_1 - y1_1)
        area2 = (x2_2 - x1_2) * (y2_2 - y1_2)
        
        # Union 면적
        union = area1 + area2 - intersection
        
        if union == 0:
            return 0.0
        
        return intersection / union
    
    def expand_bbox_with_padding(self, bbox: List[float], padding: int, img_width: int, img_height: int) -> List[int]:
        """바운딩 박스에 padding을 추가하되, 이미지 경계를 넘지 않도록 처리
        
        Args:
            bbox: [x1, y1, x2, y2]
            padding: 추가할 여백 (픽셀)
            img_width: 이미지 너비
            img_height: 이미지 높이
            
        Returns:
            List[int]: 확장된 바운딩 박스 [x1, y1, x2, y2]
        """
        x1, y1, x2, y2 = bbox
        
        # Padding 추가
        x1_expanded = max(0, int(x1 - padding))
        y1_expanded = max(0, int(y1 - padding))
        x2_expanded = min(img_width, int(x2 + padding))
        y2_expanded = min(img_height, int(y2 + padding))
        
        return [x1_expanded, y1_expanded, x2_expanded, y2_expanded]
    
    def is_bbox_near_section_boundary(self, bbox: List[float], section_bbox: List[float], threshold: int = 30) -> bool:
        """문제번호 박스가 section 경계 근처에 있는지 확인
        
        Args:
            bbox: 문제번호 바운딩 박스 [x1, y1, x2, y2]
            section_bbox: Section 바운딩 박스 [x1, y1, x2, y2]
            threshold: 경계로 간주할 거리 (픽셀)
            
        Returns:
            bool: 경계 근처에 있으면 True
        """
        bx1, by1, bx2, by2 = bbox
        sx1, sy1, sx2, sy2 = section_bbox
        
        # 상하좌우 경계와의 거리 계산
        dist_top = abs(by1 - sy1)
        dist_bottom = abs(by2 - sy2)
        dist_left = abs(bx1 - sx1)
        dist_right = abs(bx2 - sx2)
        
        # 하나라도 threshold 이내이면 경계 근처로 판단
        return min(dist_top, dist_bottom, dist_left, dist_right) < threshold
    
    def visualize_section_detection(self, image_path: str, section_bbox: List[float], 
                                   section_idx: int, output_dir: Path, page_name: str,
                                   detections_1104: List[Dict], section_padding: int = 50):
        """Section 검출 결과를 시각화하여 저장 (디버깅용)
        ✨ section, answer_1, 1-5 모든 검출 결과를 시각화
        
        Args:
            image_path: 원본 이미지 경로
            section_bbox: Section 바운딩 박스 [x1, y1, x2, y2]
            section_idx: Section 인덱스
            output_dir: 출력 디렉토리
            page_name: 페이지 이름
            detections_1104: 1104 모델의 검출 결과 (answer_1, 1-5)
            section_padding: Section padding 값
        """
        image = cv2.imread(image_path)
        if image is None:
            return
        
        h, w = image.shape[:2]
        sx1, sy1, sx2, sy2 = section_bbox
        
        # Section 확장 영역 계산
        sx1_exp = max(0, int(sx1 - section_padding))
        sy1_exp = max(0, int(sy1 - section_padding))
        sx2_exp = min(w, int(sx2 + section_padding))
        sy2_exp = min(h, int(sy2 + section_padding))
        
        # Section bbox 그리기 (원본 - 초록색)
        x1, y1, x2, y2 = map(int, section_bbox)
        cv2.rectangle(image, (x1, y1), (x2, y2), (0, 255, 0), 3)
        label = f"Section {section_idx}"
        cv2.putText(image, label, (x1, y1 - 10), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        
        # Section 확장 영역 그리기 (점선 - 연두색)
        cv2.rectangle(image, (sx1_exp, sy1_exp), (sx2_exp, sy2_exp), (100, 255, 100), 2)
        cv2.putText(image, f"Expanded (+{section_padding}px)", 
                   (sx1_exp, sy1_exp - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (100, 255, 100), 2)
        
        # 색상 정의
        colors = {
            'answer_1': (255, 0, 0),      # 빨강
            '1': (0, 0, 255),              # 파랑
            '2': (255, 165, 0),            # 주황
            '3': (255, 255, 0),            # 노랑
            '4': (255, 0, 255),            # 자홍
            '5': (0, 255, 255)             # 청록
        }
        
        # Section 내의 answer_1과 숫자 검출 결과 그리기
        for det in detections_1104:
            class_name = det['class_name']
            if class_name not in colors:
                continue
            
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            
            # 확장된 Section 영역 내에 있는지 확인
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                # 바운딩 박스 그리기
                color = colors[class_name]
                x1, y1, x2, y2 = map(int, det['bbox'])
                cv2.rectangle(image, (x1, y1), (x2, y2), color, 2)
                
                # 라벨 (클래스명 + 신뢰도)
                conf = det['confidence']
                label = f"{class_name}: {conf:.2f}"
                
                # 텍스트 배경
                (text_w, text_h), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.6, 2)
                cv2.rectangle(image, (x1, y1 - text_h - 5), (x1 + text_w, y1), color, -1)
                
                # 텍스트
                cv2.putText(image, label, (x1, y1 - 5), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # 범례 추가
        legend_y = 30
        legend_x = w - 200
        cv2.rectangle(image, (legend_x - 10, 10), (w - 10, 200), (255, 255, 255), -1)
        cv2.rectangle(image, (legend_x - 10, 10), (w - 10, 200), (0, 0, 0), 2)
        
        cv2.putText(image, "Legend:", (legend_x, legend_y), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 0), 2)
        legend_y += 25
        
        for class_name, color in colors.items():
            cv2.rectangle(image, (legend_x, legend_y - 10), (legend_x + 15, legend_y + 5), color, -1)
            cv2.putText(image, class_name, (legend_x + 20, legend_y), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1)
            legend_y += 20
        
        # 저장
        debug_dir = output_dir / page_name / "debug"
        debug_dir.mkdir(parents=True, exist_ok=True)
        
        save_path = debug_dir / f"section_{section_idx:02d}_detection_visual.jpg"
        cv2.imwrite(str(save_path), image)
        logger.info(f"✨ Section 검출 시각화 저장 (answer_1 + 1-5 포함): {save_path}")
    
    def crop_page_number(self, image_path: str, detections_1004: List[Dict], output_dir: Path) -> Tuple[Optional[str], Optional[str]]:
        """페이지 번호를 크롭하고 OCR로 인식 (1004 모델 사용)
        
        Returns:
            Tuple[Optional[str], Optional[str]]: (크롭 이미지 경로, 인식된 페이지 번호)
        """
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return None, None
        
        page_num_detections = [d for d in detections_1004 if d['class_name'] == 'page_number']
        
        if not page_num_detections:
            logger.warning(f"페이지 번호 미검출: {image_path}")
            return None, None
        
        # 신뢰도 가장 높은 것 선택
        best_det = max(page_num_detections, key=lambda x: x['confidence'])
        x1, y1, x2, y2 = map(int, best_det['bbox'])
        
        h, w = image.shape[:2]
        x1, y1 = max(0, x1), max(0, y1)
        x2, y2 = min(w, x2), min(h, y2)
        
        if x2 <= x1 or y2 <= y1:
            logger.warning(f"잘못된 페이지 번호 박스: {best_det['bbox']}")
            return None, None
        
        # 크롭 및 저장
        cropped = image[y1:y2, x1:x2]
        page_num_dir = output_dir / "page_numbers"
        page_num_dir.mkdir(parents=True, exist_ok=True)
        
        image_name = Path(image_path).stem
        save_path = page_num_dir / f"{image_name}_page_number.jpg"
        cv2.imwrite(str(save_path), cropped)
        
        # OCR로 페이지 번호 인식
        recognized_number = self.ocr.extract_number(str(save_path))
        
        logger.info(f"페이지 번호 crop 완료 (1004 모델): {save_path}")
        logger.info(f"페이지 번호 OCR 결과: '{recognized_number}'")
        
        return str(save_path), recognized_number
    
    def classify_answer_with_resnet(self, answer_1_crop_path: str, section_idx: int) -> Tuple[Optional[str], float, bool]:
        """
        ✨ answer_1 crop 이미지를 ResNet으로 분류
        
        Args:
            answer_1_crop_path: answer_1 crop 이미지 경로
            section_idx: Section 인덱스
            
        Returns:
            Tuple[Optional[str], float, bool]: (예측 답안, 신뢰도, 실패 여부)
        """
        if self.resnet_classifier is None:
            logger.warning(f"Section {section_idx}: ResNet 모델이 없어 분류를 사용할 수 없습니다.")
            return None, 0.0, True
        
        if not os.path.exists(answer_1_crop_path):
            logger.error(f"Section {section_idx}: answer_1 이미지가 없어 ResNet을 사용할 수 없습니다: {answer_1_crop_path}")
            return None, 0.0, True
        
        logger.info(f"Section {section_idx}: ✨ ResNet 분류 시도 중...")
        
        try:
            answer, confidence = self.resnet_classifier.predict(answer_1_crop_path)
            
            if answer is None:
                logger.warning(f"Section {section_idx}: ResNet 예측 실패")
                return None, 0.0, True
            
            logger.info(f"Section {section_idx}: ✅ ResNet 예측 성공 - 답안={answer}, 신뢰도={confidence:.4f}")
            return answer, confidence, False
            
        except Exception as e:
            logger.error(f"Section {section_idx}: ResNet 예측 중 예외 발생: {e}")
            return None, 0.0, True
    
    def process_single_section(self, original_image_path: str, section_idx: int, 
                            page_name: str, output_dir: Path, 
                            section_bbox: List[float], detections_1004: List[Dict],
                            detections_1104: List[Dict]) -> Dict:
        """섹션 내의 문제번호와 정답을 추론
        ✨ 새로운 방식: answer_1 crop 후 ResNet 분류
        
        Returns:
            Dict: {'section_idx', 'problem_number_ocr', 'answer_number', 'section_crop_path', 'problem_crop_path', 
                   'answer_1_crop_path', 'crop_success', 'crop_failure_reason', 'used_resnet', 'resnet_confidence', 'resnet_failed'}
        """
        sx1, sy1, sx2, sy2 = section_bbox
        image = cv2.imread(original_image_path)
        h, w = image.shape[:2]
        
        # Section bbox 유효성 검사
        if sx2 <= sx1 or sy2 <= sy1:
            logger.error(f"❌ Section {section_idx} CROP 실패: 잘못된 bbox [{sx1:.1f}, {sy1:.1f}, {sx2:.1f}, {sy2:.1f}]")
            logger.error(f"   bbox 너비: {sx2 - sx1:.1f}, 높이: {sy2 - sy1:.1f}")
            return {
                'section_idx': section_idx,
                'problem_number_ocr': None,
                'answer_number': None,
                'section_crop_path': None,
                'problem_crop_path': None,
                'answer_1_crop_path': None,
                'crop_success': False,
                'crop_failure_reason': 'invalid_bbox',
                'used_resnet': False,
                'resnet_confidence': 0.0,
                'resnet_failed': False,
                'debug_info': {
                    'original_bbox': section_bbox,
                    'bbox_width': sx2 - sx1,
                    'bbox_height': sy2 - sy1,
                    'image_size': (w, h)
                }
            }
        
        # Section 이미지 크롭 시 padding 추가
        expanded_section_bbox = self.expand_bbox_with_padding(
            [sx1, sy1, sx2, sy2], 
            self.section_padding, 
            w, h
        )
        sx1_exp, sy1_exp, sx2_exp, sy2_exp = expanded_section_bbox
        
        # 확장된 bbox 유효성 검사
        if sx2_exp <= sx1_exp or sy2_exp <= sy1_exp:
            logger.error(f"❌ Section {section_idx} CROP 실패: 잘못된 확장 bbox [{sx1_exp}, {sy1_exp}, {sx2_exp}, {sy2_exp}]")
            return {
                'section_idx': section_idx,
                'problem_number_ocr': None,
                'answer_number': None,
                'section_crop_path': None,
                'problem_crop_path': None,
                'answer_1_crop_path': None,
                'crop_success': False,
                'crop_failure_reason': 'invalid_expanded_bbox',
                'used_resnet': False,
                'resnet_confidence': 0.0,
                'resnet_failed': False,
                'debug_info': {
                    'original_bbox': section_bbox,
                    'expanded_bbox': expanded_section_bbox,
                    'padding': self.section_padding,
                    'image_size': (w, h)
                }
            }
        
        # Crop 실행
        try:
            section_cropped = image[sy1_exp:sy2_exp, sx1_exp:sx2_exp]
            
            # Crop된 이미지 크기 확인
            crop_h, crop_w = section_cropped.shape[:2]
            if crop_h == 0 or crop_w == 0:
                logger.error(f"❌ Section {section_idx} CROP 실패: 크롭된 이미지 크기가 0")
                return {
                    'section_idx': section_idx,
                    'problem_number_ocr': None,
                    'answer_number': None,
                    'section_crop_path': None,
                    'problem_crop_path': None,
                    'answer_1_crop_path': None,
                    'crop_success': False,
                    'crop_failure_reason': 'zero_size_crop',
                    'used_resnet': False,
                    'resnet_confidence': 0.0,
                    'resnet_failed': False,
                    'debug_info': {
                        'original_bbox': section_bbox,
                        'expanded_bbox': expanded_section_bbox,
                        'crop_size': (crop_w, crop_h),
                        'image_size': (w, h)
                    }
                }
            
            section_dir = output_dir / page_name / "sections"
            section_dir.mkdir(parents=True, exist_ok=True)
            
            section_crop_path = section_dir / f"section_{section_idx:02d}.jpg"
            
            # 파일 저장
            write_success = cv2.imwrite(str(section_crop_path), section_cropped)
            
            if not write_success or not section_crop_path.exists():
                logger.error(f"❌ Section {section_idx} 파일 저장 실패: {section_crop_path}")
                return {
                    'section_idx': section_idx,
                    'problem_number_ocr': None,
                    'answer_number': None,
                    'section_crop_path': None,
                    'problem_crop_path': None,
                    'answer_1_crop_path': None,
                    'crop_success': False,
                    'crop_failure_reason': 'file_write_failed',
                    'used_resnet': False,
                    'resnet_confidence': 0.0,
                    'resnet_failed': False
                }
            
            logger.info(f"✅ Section {section_idx} 이미지 저장 성공 (padding {self.section_padding}px 추가): {section_crop_path}")
            
        except Exception as e:
            logger.error(f"❌ Section {section_idx} CROP 실패: {e}")
            return {
                'section_idx': section_idx,
                'problem_number_ocr': None,
                'answer_number': None,
                'section_crop_path': None,
                'problem_crop_path': None,
                'answer_1_crop_path': None,
                'crop_success': False,
                'crop_failure_reason': f'exception: {str(e)}',
                'used_resnet': False,
                'resnet_confidence': 0.0,
                'resnet_failed': False
            }
        
        # 1004 모델에서 문제번호 검출 (확장된 영역 기준)
        section_dets_1004 = []
        for det in detections_1004:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            # 확장된 영역 내에서 검출 (padding 고려)
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                if det['class_name'] == 'problem_number':
                    section_dets_1004.append(det)
                    # 경계 근처 여부 체크
                    if self.is_bbox_near_section_boundary(det['bbox'], [sx1, sy1, sx2, sy2]):
                        logger.warning(f"Section {section_idx}: 문제번호가 경계 근처에 위치 (padding으로 보정)")
        
        # 디버깅: 문제번호 검출 결과
        logger.info(f"Section {section_idx}: 1004 모델 문제번호 검출 개수 = {len(section_dets_1004)}")
        if section_dets_1004:
            for i, det in enumerate(section_dets_1004):
                logger.info(f"  문제번호 {i+1}: confidence={det['confidence']:.3f}, bbox={det['bbox']}")
        
        # 1104 모델에서 answer_1과 숫자(1-5) 검출 (확장된 영역 기준)
        section_dets_1104 = []
        for det in detections_1104:
            dx1, dy1, dx2, dy2 = det['bbox']
            cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
            if sx1_exp <= cx <= sx2_exp and sy1_exp <= cy <= sy2_exp:
                if det['class_name'] in ['answer_1', '1', '2', '3', '4', '5']:
                    section_dets_1104.append(det)

        # 디버깅: answer_1 검출 결과
        answer_1_dets = [d for d in section_dets_1104 if d['class_name'] == 'answer_1']
        
        logger.info(f"Section {section_idx}: 1104 모델 answer_1 검출 개수 = {len(answer_1_dets)}")
        if answer_1_dets:
            for i, det in enumerate(answer_1_dets):
                logger.info(f"  answer_1 {i+1}: confidence={det['confidence']:.3f}, bbox={det['bbox']}")

        # 문제번호 OCR 및 이미지 저장 (1004 모델 결과 사용)
        problem_ocr = None
        problem_crop_path = None
        if section_dets_1004:
            best_det = max(section_dets_1004, key=lambda x: x['confidence'])
            x1, y1, x2, y2 = map(int, best_det['bbox'])
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 > x1 and y2 > y1:
                cropped = image[y1:y2, x1:x2]
                
                # Problem number 이미지 저장
                problem_dir = output_dir / page_name / "problem_numbers"
                problem_dir.mkdir(parents=True, exist_ok=True)
                problem_crop_path = problem_dir / f"section_{section_idx:02d}_problem_number.jpg"
                cv2.imwrite(str(problem_crop_path), cropped)
                logger.info(f"Section {section_idx} 문제번호 이미지 저장: {problem_crop_path}")
                
                # OCR 수행
                problem_ocr = self.ocr.extract_number(str(problem_crop_path))
                logger.info(f"Section {section_idx} 문제번호 OCR 결과: '{problem_ocr}'")
        else:
            logger.warning(f"Section {section_idx}: 문제번호 미검출")

        # ✨ 새로운 방식: answer_1 crop 후 ResNet 분류 + YOLO IoU 검증
        best_answer = None
        used_resnet = False
        resnet_confidence = 0.0
        resnet_failed = False
        answer_1_crop_path = None
        yolo_iou_verification = None  # YOLO IoU 검증 결과

        if answer_1_dets:
            # answer_1을 crop
            best_det = max(answer_1_dets, key=lambda x: x['confidence'])
            answer_1_bbox = best_det['bbox']
            x1, y1, x2, y2 = map(int, answer_1_bbox)
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(w, x2), min(h, y2)
            
            if x2 > x1 and y2 > y1:
                cropped_answer_1 = image[y1:y2, x1:x2]
                
                # answer_1 이미지 저장
                answer_dir = output_dir / page_name / "answers"
                answer_dir.mkdir(parents=True, exist_ok=True)
                answer_1_crop_path = answer_dir / f"section_{section_idx:02d}_answer_1.jpg"
                cv2.imwrite(str(answer_1_crop_path), cropped_answer_1)
                logger.info(f"Section {section_idx} answer_1 이미지 저장: {answer_1_crop_path}")
                
                # ResNet으로 분류
                answer, conf, failed = self.classify_answer_with_resnet(str(answer_1_crop_path), section_idx)
                
                if not failed and answer is not None:
                    # ✨ YOLO IoU로 검증
                    number_dets = [d for d in section_dets_1104 if d['class_name'] in ['1', '2', '3', '4', '5']]
                    
                    if number_dets:
                        # 각 숫자와의 IoU 계산
                        iou_results = []
                        for det in number_dets:
                            iou = self.calculate_iou(answer_1_bbox, det['bbox'])
                            iou_results.append({
                                'number': det['class_name'],
                                'iou': iou,
                                'confidence': det['confidence']
                            })
                        
                        # IoU가 가장 높은 숫자
                        best_iou_result = max(iou_results, key=lambda x: x['iou'])
                        yolo_best_number = best_iou_result['number']
                        yolo_best_iou = best_iou_result['iou']
                        
                        logger.info(f"Section {section_idx}: YOLO IoU 검증")
                        logger.info(f"  ResNet 예측: {answer} (신뢰도: {conf:.4f})")
                        logger.info(f"  YOLO 최고 IoU: {yolo_best_number} (IoU: {yolo_best_iou:.4f})")
                        
                        # IoU 결과 저장
                        for result in sorted(iou_results, key=lambda x: x['iou'], reverse=True):
                            logger.info(f"    - {result['number']}: IoU={result['iou']:.4f}, Conf={result['confidence']:.3f}")
                        
                        yolo_iou_verification = {
                            'yolo_best': yolo_best_number,
                            'yolo_iou': yolo_best_iou,
                            'resnet_pred': answer,
                            'resnet_conf': conf,
                            'all_ious': iou_results
                        }
                        
                        # ✨ 불일치 시 경고 + ResNet 신뢰도가 낮으면 YOLO 사용
                        if answer != yolo_best_number:
                            logger.warning(f"⚠️ Section {section_idx}: ResNet({answer}) ≠ YOLO IoU({yolo_best_number})")
                            
                            # ResNet 신뢰도가 낮고(70% 이하) IoU가 높으면(0.3 이상) YOLO 결과 사용
                            if conf < 0.70 and yolo_best_iou > 0.3:
                                logger.warning(f"   → ResNet 신뢰도 낮음({conf:.2f}), YOLO 결과({yolo_best_number}) 사용")
                                best_answer = yolo_best_number
                            else:
                                logger.info(f"   → ResNet 신뢰도 높음({conf:.2f}), ResNet 결과({answer}) 유지")
                                best_answer = answer
                        else:
                            logger.info(f"✅ Section {section_idx}: ResNet과 YOLO IoU 일치 ({answer})")
                            best_answer = answer
                    else:
                        # 숫자 검출 안 됨 - ResNet만 사용
                        logger.warning(f"Section {section_idx}: YOLO 숫자 미검출, ResNet만 사용")
                        best_answer = answer
                    
                    resnet_confidence = conf
                    used_resnet = True
                    resnet_failed = False
                    logger.info(f"Section {section_idx}: ✅ 최종 답안={best_answer}")
                else:
                    resnet_failed = True
                    used_resnet = True
                    logger.warning(f"Section {section_idx}: ❌ ResNet 분류 실패")
            else:
                logger.warning(f"Section {section_idx}: answer_1 bbox가 유효하지 않음")
                resnet_failed = True
        else:
            logger.warning(f"Section {section_idx}: answer_1이 검출되지 않았습니다.")
            resnet_failed = True

        # Section 검출 시각화 저장 (✨ 모든 검출 정보 포함)
        self.visualize_section_detection(original_image_path, section_bbox, section_idx, 
                                        output_dir, page_name, section_dets_1104, self.section_padding)

        return {
            'section_idx': section_idx,
            'problem_number_ocr': problem_ocr,
            'answer_number': best_answer,
            'section_crop_path': str(section_crop_path),
            'problem_crop_path': str(problem_crop_path) if problem_crop_path else None,
            'answer_1_crop_path': str(answer_1_crop_path) if answer_1_crop_path else None,
            'crop_success': True,
            'is_boundary_issue': len(section_dets_1004) > 0 and any(
                self.is_bbox_near_section_boundary(d['bbox'], [sx1, sy1, sx2, sy2]) 
                for d in section_dets_1004
            ),
            'used_resnet': used_resnet,
            'resnet_confidence': resnet_confidence,
            'resnet_failed': resnet_failed,
            'yolo_iou_verification': yolo_iou_verification,  # ✨ YOLO 검증 정보
            'debug_info': {
                'original_bbox': section_bbox,
                'expanded_bbox': expanded_section_bbox,
                'crop_size': (crop_w, crop_h),
                'image_size': (w, h),
                'answer_1_count': len(answer_1_dets)
            }
        }

    def filter_duplicate_sections(self, image_path: str, section_detections: List[Dict], 
                                 detections_1004: List[Dict]) -> List[Dict]:
        """
        중복된 section을 필터링 (같은 problem_number를 가진 section 중 더 큰 것 선택)
        
        Args:
            image_path: 원본 이미지 경로
            section_detections: section 검출 결과 리스트
            detections_1004: 1004 모델의 전체 검출 결과
            
        Returns:
            필터링된 section 리스트
        """
        if len(section_detections) <= 1:
            return section_detections
        
        image = cv2.imread(image_path)
        if image is None:
            logger.error(f"이미지 로드 실패: {image_path}")
            return section_detections
        
        h, w = image.shape[:2]
        
        # 각 section에 대해 problem_number 찾기
        section_with_problem = []
        
        for idx, section in enumerate(section_detections):
            sx1, sy1, sx2, sy2 = section['bbox']
            section_area = (sx2 - sx1) * (sy2 - sy1)
            
            # 해당 section 내의 problem_number 찾기
            problem_numbers = []
            for det in detections_1004:
                if det['class_name'] != 'problem_number':
                    continue
                
                dx1, dy1, dx2, dy2 = det['bbox']
                cx, cy = (dx1 + dx2) / 2, (dy1 + dy2) / 2
                
                # Section 영역 내에 있는지 확인
                if sx1 <= cx <= sx2 and sy1 <= cy <= sy2:
                    problem_numbers.append(det)
            
            # 가장 신뢰도 높은 problem_number 사용
            if problem_numbers:
                best_problem = max(problem_numbers, key=lambda x: x['confidence'])
                
                # OCR로 문제번호 인식 (임시)
                x1, y1, x2, y2 = map(int, best_problem['bbox'])
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)
                
                if x2 > x1 and y2 > y1:
                    cropped = image[y1:y2, x1:x2]
                    # OCR 모델이 numpy array를 받을 수 있는지 확인
                    try:
                        problem_ocr = self.ocr.extract_number(cropped)
                    except:
                        # 임시 파일로 저장 후 OCR
                        import tempfile
                        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as tmp:
                            cv2.imwrite(tmp.name, cropped)
                            problem_ocr = self.ocr.extract_number(tmp.name)
                            os.unlink(tmp.name)
                else:
                    problem_ocr = None
            else:
                problem_ocr = None
            
            section_with_problem.append({
                'section': section,
                'original_index': idx,
                'problem_number_ocr': problem_ocr,
                'section_area': section_area,
                'bbox': section['bbox']
            })
        
        # problem_number별로 그룹화
        problem_groups = {}
        no_problem_sections = []
        
        for item in section_with_problem:
            problem_num = item['problem_number_ocr']
            
            if problem_num is None or problem_num == '':
                # 문제번호가 없는 section은 별도 처리
                no_problem_sections.append(item)
            else:
                if problem_num not in problem_groups:
                    problem_groups[problem_num] = []
                problem_groups[problem_num].append(item)
        
        # 중복 제거: 각 그룹에서 가장 큰 section 선택
        filtered_sections = []
        removed_count = 0
        
        for problem_num, items in problem_groups.items():
            if len(items) > 1:
                # 면적이 가장 큰 section 선택
                largest = max(items, key=lambda x: x['section_area'])
                filtered_sections.append(largest['section'])
                
                removed_count += len(items) - 1
                
                logger.warning(f"⚠️ 문제번호 '{problem_num}': {len(items)}개 section 검출됨")
                logger.warning(f"   가장 큰 section 선택 (면적: {largest['section_area']:.1f})")
                
                # 제거된 section들 로그
                for item in items:
                    if item != largest:
                        logger.warning(f"   - 제거: Section index {item['original_index']}, "
                                     f"면적={item['section_area']:.1f}, bbox={item['bbox']}")
            else:
                filtered_sections.append(items[0]['section'])
        
        # 문제번호가 없는 section들 추가
        for item in no_problem_sections:
            filtered_sections.append(item['section'])
            logger.warning(f"⚠️ Section index {item['original_index']}: 문제번호 미검출 (포함)")
        
        if removed_count > 0:
            logger.info(f"✂️ 중복 필터링: {removed_count}개 section 제거됨")
            logger.info(f"   필터링 전: {len(section_detections)}개 → 필터링 후: {len(filtered_sections)}개")
        
        # y 좌표 기준으로 재정렬
        filtered_sections = sorted(filtered_sections, key=lambda x: x['bbox'][1])
        
        return filtered_sections
    
    def process_page(self, image_path: str, output_dir: Path) -> Optional[Dict]:
        """페이지 처리: 1104 모델로 answer_1 검출, ResNet으로 분류
        
        Returns:
            Optional[Dict]: 페이지가 답지에 있으면 결과 반환, 없으면 None
        """
        start_time = time.time()
        
        # 1004 모델: 페이지번호, 문제번호, section 검출
        logger.info("1004 모델 실행 중 (페이지번호, 문제번호, section 검출)...")
        result_1004 = self.router_1004.route_infer_single_image(image_path)
        detections_1004 = result_1004['detections']
        
        # Section 검출 통계
        section_detections = [d for d in detections_1004 if d['class_name'] == 'section']
        logger.info(f"1004 모델 Section 검출 개수: {len(section_detections)}")
        
        if not section_detections:
            logger.error(f"❌ Section이 하나도 검출되지 않았습니다!")
            logger.error(f"   1004 모델 전체 검출 개수: {len(detections_1004)}")
            logger.error(f"   검출된 클래스: {set(d['class_name'] for d in detections_1004)}")
            
            # 검출된 클래스별 개수 출력
            class_counts = {}
            for det in detections_1004:
                class_name = det['class_name']
                class_counts[class_name] = class_counts.get(class_name, 0) + 1
            
            logger.error(f"   클래스별 검출 개수:")
            for class_name, count in sorted(class_counts.items()):
                logger.error(f"     - {class_name}: {count}개")
        else:
            for i, det in enumerate(section_detections):
                bbox = det['bbox']
                conf = det['confidence']
                logger.info(f"  Section {i}: confidence={conf:.3f}, bbox=[{bbox[0]:.1f}, {bbox[1]:.1f}, {bbox[2]:.1f}, {bbox[3]:.1f}]")
        
        page_name = Path(image_path).stem
        page_output_dir = output_dir / page_name
        page_output_dir.mkdir(parents=True, exist_ok=True)

        # 페이지 번호 OCR (1004 모델 사용)
        page_num_path, page_num_ocr = self.crop_page_number(image_path, detections_1004, page_output_dir)

        # 답지 필터링: 페이지 번호가 답지에 없으면 건너뛰기
        if not self.is_valid_page(page_num_ocr):
            logger.info(f"페이지 '{page_name}' (페이지 번호: {page_num_ocr})는 처리하지 않습니다.")
            return None
        
        # 1104 모델: answer_1 검출용
        logger.info("1104 모델 실행 중 (answer_1 검출)...")
        result_1104 = self.router_1104.route_infer_single_image(image_path)
        detections_1104 = result_1104['detections']

        # Section 영역 검출 (1004 모델 사용)
        logger.info(f"페이지 '{page_name}': {len(section_detections)}개 Section 검출 (필터링 전)")
        
        # 중복 section 필터링
        section_detections = self.filter_duplicate_sections(image_path, section_detections, detections_1004)
        
        # 정렬 (y 좌표 기준)
        section_detections = sorted(section_detections, key=lambda x: x['bbox'][1])
        
        logger.info(f"페이지 '{page_name}': {len(section_detections)}개 Section 처리 (필터링 후)")

        page_result = []
        crop_failure_count = 0
        
        for idx, det in enumerate(section_detections):
            section_bbox = det['bbox']
            section_result = self.process_single_section(
                image_path, idx, page_name, output_dir, section_bbox,
                detections_1004, detections_1104
            )
            page_result.append(section_result)
            
            if not section_result.get('crop_success', True):
                crop_failure_count += 1

        end_time = time.time()
        
        # Crop 실패 통계
        if crop_failure_count > 0:
            logger.warning(f"⚠️ 페이지 '{page_name}': {crop_failure_count}개 Section crop 실패")
        
        return {
            "image_path": image_path,
            "page_name": page_name,
            "page_number_ocr": page_num_ocr,
            "sections": page_result,
            "processing_time": end_time - start_time,
            "total_sections": len(section_detections),
            "crop_failure_count": crop_failure_count
        }
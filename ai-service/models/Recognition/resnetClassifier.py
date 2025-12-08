from typing import  Tuple, Optional
import cv2
import torch
import torch.nn as nn
from torchvision import transforms

class ResNetClassifier:
    """ResNet 기반 답안 분류 모델 (1-5 분류)"""
    
    def __init__(self, model_path: str, model_type: str = 'answer', device: str = 'cuda'):
        """
        Args:
            model_path: ResNet 모델 가중치 파일 경로 (.pth)
            model_type: 모델 타입 ('answer_1' 또는 'answer_2')
            device: 'cuda' 또는 'cpu'
        """
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model_type = model_type
        self.model = self._load_model(model_path)
        self.transform = self._get_transform()

    
    def _load_model(self, model_path: str):
        """ResNet 모델 로드 - 커스텀 구조"""
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
            

            return answer, conf
            
        except Exception as e:
            return None, 0.0
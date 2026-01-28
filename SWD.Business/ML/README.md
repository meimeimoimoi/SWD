# 🧪 ML Module - ResNet18 Rice Disease Detection

## 📁 Cấu trúc

```
SWD.Business/ML/
├── Models/                          # Thư mục chứa model files
│   └── resnet18_rice_disease.zip   # ResNet18 trained model
├── ResNet18Predictor.cs            # Class chính để load và predict
├── ImagePreprocessor.cs            # Xử lý ảnh trước khi predict
└── README.md                        # File này
```

## 🚀 Cách sử dụng

### 1. Đặt model vào thư mục
```bash
# Đặt model file vào:
SWD.Business/ML/Models/resnet18_rice_disease.zip
```

### 2. Gọi API để predict

#### Upload file ảnh:
```bash
POST /api/diseasedetection/predict/upload
Content-Type: multipart/form-data

file: [your-image.jpg]
```

#### Hoặc gửi Base64:
```bash
POST /api/diseasedetection/predict/base64
Content-Type: application/json

{
  "imageData": "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
}
```

### 3. Response format
```json
{
  "success": true,
  "prediction": {
    "predictedDisease": "Bacterial Leaf Blight",
    "confidence": 95.8,
    "allPredictions": [
      { "label": "Bacterial Leaf Blight", "confidence": 95.8 },
      { "label": "Brown Spot", "confidence": 2.1 },
      { "label": "Healthy", "confidence": 1.5 },
      { "label": "Blast", "confidence": 0.4 },
      { "label": "Leaf Smut", "confidence": 0.2 }
    ],
    "processingTimeMs": 234,
    "predictedAt": "2026-01-28T10:30:45Z"
  }
}
```

## 🔧 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/diseasedetection/status` | Kiểm tra model đã load chưa |
| POST | `/api/diseasedetection/predict/upload` | Upload ảnh để predict |
| POST | `/api/diseasedetection/predict/base64` | Gửi base64 image |
| GET | `/api/diseasedetection/diseases` | Danh sách các bệnh |

## 📊 Các bệnh được nhận diện

1. **Healthy** - Cây lúa khỏe mạnh
2. **Bacterial Leaf Blight** - Bạc lá do vi khuẩn
3. **Brown Spot** - Đốm nâu
4. **Leaf Smut** - Đen lép hạt
5. **Blast** - Đạo ôn

## ⚙️ Cấu hình

File `appsettings.json`:
```json
{
  "MLModel": {
    "ModelPath": "ML/Models/resnet18_rice_disease.zip",
    "ModelType": "MLNET",
    "InputImageSize": 224
  }
}
```

## 📝 Technical Details

- **Model**: ResNet18
- **Input size**: 224x224 RGB
- **Output**: 5 classes with confidence scores
- **Framework**: ML.NET
- **Image formats**: JPG, PNG, BMP
- **Max file size**: 10MB

## 🛠️ Dependencies

Cần cài đặt:
```bash
dotnet add package Microsoft.ML
dotnet add package Microsoft.ML.ImageAnalytics
dotnet add package System.Drawing.Common
```

## 💡 Example Usage in Code

```csharp
// Inject service
private readonly IDiseaseDetectionService _diseaseService;

// Predict from file
var imageBytes = File.ReadAllBytes("rice-leaf.jpg");
var result = await _diseaseService.PredictDiseaseAsync(imageBytes);

Console.WriteLine($"Disease: {result.PredictedDisease}");
Console.WriteLine($"Confidence: {result.Confidence}%");
```

## 🔗 Model Training

Nếu bạn cần train model mới:
1. Chuẩn bị dataset (images + labels)
2. Sử dụng ML.NET Model Builder hoặc Python (PyTorch/TensorFlow)
3. Export sang ONNX hoặc ML.NET format
4. Đặt vào thư mục `Models/`

## 📦 Model File Location

**Production**: Đặt model ở external storage (Azure Blob, S3) và download khi startup  
**Development**: Đặt local tại `ML/Models/`

## ⚠️ Lưu ý

- Model file (~45MB) không nên commit vào Git
- Sử dụng Git LFS cho large files
- Kiểm tra model status trước khi predict: `/api/diseasedetection/status`

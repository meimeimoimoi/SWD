# ResNet18 Model Directory

## 📁 Thư mục này chứa model ResNet18 đã được train

### Cấu trúc file:
```
Models/
  └── resnet18_rice_disease.zip (hoặc .onnx)
```

### Hướng dẫn sử dụng model:

#### 1. **Đặt model vào đây**
   - Download model ResNet18 đã train từ Azure/S3/Local
   - Đặt file model vào thư mục này
   - Đặt tên file: `resnet18_rice_disease.zip` hoặc `resnet18_rice_disease.onnx`

#### 2. **Format model**
   Hỗ trợ các format:
   - **ML.NET format** (.zip): Model đã được train bằng ML.NET
   - **ONNX format** (.onnx): Model từ PyTorch/TensorFlow export sang ONNX

#### 3. **Cấu hình model path**
   Cập nhật đường dẫn model trong `appsettings.json`:
   ```json
   {
     "MLModel": {
       "ModelPath": "ML/Models/resnet18_rice_disease.zip",
       "UseOnnx": false
     }
   }
   ```

#### 4. **Các class được nhận diện**
   Model được train để nhận diện các bệnh sau:
   1. Healthy (Lúa khỏe mạnh)
   2. Bacterial Leaf Blight (Bạc lá do vi khuẩn)
   3. Brown Spot (Đốm nâu)
   4. Leaf Smut (Đen lép hạt)
   5. Blast (Đạo ôn)

### 📝 Lưu ý:
- Model size: ~45MB (ResNet18)
- Input size: 224x224 RGB
- Output: 5 classes với confidence scores
- Không commit model lớn vào Git (sử dụng Git LFS hoặc external storage)

### 🔗 Link tải model:
Thêm link download model của bạn ở đây:
- Azure Blob Storage: `https://...`
- Google Drive: `https://...`
- AWS S3: `https://...`

# ?? Hý?ng d?n s? d?ng - C?C K? NG?N G?N

## ?? Setup (1 phút)

### **Hi?n t?i: Dùng Mock Data**

```json
// appsettings.json
{
  "AIModel": {
    "Url": "",
    "UseMock": "true"  ? Dùng mock data t?m
  }
}
```

### **Khi có Model th?t:**

```json
// appsettings.json
{
  "AIModel": {
    "Url": "https://your-team-model-url.com/predict",
    "UseMock": "false"  ? Ð?i thành false
  }
}
```

**Ch? c?n thay 2 d?ng này là xong!**

---

## ?? Cách dùng (Frontend)

### **Workflow c?c ðõn gi?n (gi?ng h?t dù mock hay th?t):**

```javascript
// Bý?c 1: Upload ?nh (ngý?i khác ð? làm)
const formData = new FormData();
formData.append('file', imageFile);

const uploadResponse = await fetch('/api/uploads', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: formData
});
const { uploadId } = await uploadResponse.json();

// Bý?c 2: G?i API ð? predict
const predictResponse = await fetch('/api/predictions/run', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({ uploadId: uploadId })
});
const result = await predictResponse.json();

// XONG! Có k?t qu? r?i
console.log(result);
// {
//   "predictionId": 501,
//   "tree": { "treeId": 1, "treeName": "Lúa" },
//   "illness": { "illnessId": 3, "illnessName": "Ð?o ôn" },
//   "confidenceScore": 0.85,
//   "processingTimeMs": 450
// }
```

---

## ? Mock Mode vs Real Model

### **Mock Mode (hi?n t?i):**
```
Upload ?nh
    ?
API t? generate k?t qu? gi?
    ?
Lýu vào database
    ?
Return k?t qu?

? Test ðý?c toàn b? flow
? Không c?n model th?t
? Response gi?ng y chang real model
```

### **Real Model (khi có link):**
```
Upload ?nh
    ?
API g?i model th?t qua HTTP
    ?
Lýu vào database
    ?
Return k?t qu?

? Ch? c?n ð?i 2 d?ng config
? Code không thay ð?i g?
```

---

## ?? Mock Data Example

**Mock s? random tr? v?:**
```json
{
  "treeId": 1,
  "illnessId": 1,
  "predictedClass": "Rice_Blast",
  "confidenceScore": 0.8523,
  "topPredictions": [
    { "className": "Rice_Blast", "confidence": 0.8523 },
    { "className": "Healthy", "confidence": 0.1477 }
  ],
  "processingTimeMs": 542
}
```

**Các b?nh mock:**
- Rice_Blast (Ð?o ôn lúa)
- Brown_Spot (Ð?m nâu lúa)
- Corn_Rust (G? s?t ngô)

---

## ?? Format Response t? Model th?t

**Khi có model, nhóm b?n c?n return:**

```json
{
  "treeId": 1,
  "illnessId": 3,
  "predictedClass": "Rice_Blast",
  "confidenceScore": 0.85,
  "topPredictions": [
    { "className": "Rice_Blast", "confidence": 0.85 },
    { "className": "Brown_Spot", "confidence": 0.10 },
    { "className": "Healthy", "confidence": 0.05 }
  ],
  "processingTimeMs": 450
}
```

**Request g?i t?i model:**
```http
POST https://your-model-url.com/predict
Content-Type: application/json

{
  "imagePath": "/uploads/img_123.jpg",
  "modelVersion": "v2.1.0"
}
```

---

## ? Test ngay bây gi?!

### **1. Ch?y API:**
```bash
dotnet run
```

### **2. Test qua Swagger:**
```
https://localhost:5001/swagger
```

### **3. Test Prediction:**
```bash
# 1. Login ð? l?y token
POST /api/auth/login

# 2. Upload ?nh
POST /api/uploads

# 3. Run prediction (dùng mock)
POST /api/predictions/run
{
  "uploadId": 1
}

# ? Nh?n k?t qu? mock ngay!
```

---

## ?? Chuy?n sang Real Model

### **Khi nhóm có model r?i:**

```json
// appsettings.json - CH? C?N Ð?I 2 D?NG
{
  "AIModel": {
    "Url": "https://your-team-model-url.com/predict",  ? Ði?n URL
    "UseMock": "false"  ? Ð?i thành false
  }
}
```

**Restart API ? Xong!**

---

## ?? Auto Fallback

**N?u model th?t l?i:**
```
API g?i model th?t
    ?
N?u l?i (timeout, 500, etc.)
    ?
T? ð?ng dùng mock data
    ?
Log warning
    ?
V?n return k?t qu? cho user
```

? **H? th?ng luôn ho?t ð?ng!**

---

## ?? Logs

**Console s? hi?n th?:**

```
[INFO] Using model: ResNet50_RiceDisease v2.1.0
[WARN] Using MOCK data - Model URL not configured
[INFO] Generated mock prediction: Rice_Blast (0.8523)
```

**Khi có model th?t:**
```
[INFO] Using model: ResNet50_RiceDisease v2.1.0
[INFO] Calling AI model at https://your-model-url.com/predict
[INFO] Prediction received: Rice_Blast (0.8523)
```

---

## ? Summary

### **Hi?n t?i:**
- ? Mock mode active
- ? Test ðý?c toàn b? flow
- ? Frontend ho?t ð?ng b?nh thý?ng
- ? Database lýu data mock

### **Khi có model:**
- ? Ð?i 2 d?ng config
- ? Restart API
- ? Không thay ð?i code
- ? T? ð?ng dùng model th?t

**C?c k? ðõn gi?n!** ??

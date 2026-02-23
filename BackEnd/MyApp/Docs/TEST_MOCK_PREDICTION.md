# ?? Test Mock Prediction - 3 phút

## ?? Test nhanh qua Swagger

### **1. M? Swagger:**
```
https://localhost:5001/swagger
```

### **2. Login (l?y token):**
```
POST /api/auth/login
{
  "email": "admin@Swd.com",
  "password": "StrongPassword@123"
}
```

**Copy token t? response!**

### **3. Authorize:**
- Click nút **Authorize** (góc trên ph?i)
- Paste token: `Bearer {your_token}`
- Click **Authorize**

### **4. Test Mock Prediction:**
```
POST /api/predictions/run
{
  "uploadId": 1
}
```

**?? N?u uploadId=1 chýa có, t?o trý?c:**
```sql
-- T?o upload test trong database
INSERT INTO image_uploads (user_id, file_path, upload_status, uploaded_at)
VALUES (1, '/uploads/test.jpg', 'uploaded', GETDATE());

-- Xem uploadId v?a t?o
SELECT TOP 1 * FROM image_uploads ORDER BY upload_id DESC;
```

---

## ? Expected Response (Mock):

```json
{
  "success": true,
  "message": "Prediction completed successfully",
  "data": {
    "predictionId": 1,
    "tree": {
      "treeId": 1,
      "treeName": "Lúa"
    },
    "illness": {
      "illnessId": 1,
      "illnessName": "Ð?o ôn"
    },
    "confidenceScore": 0.8523,
    "processingTimeMs": 542,
    "createdAt": "2024-12-20T10:30:00Z"
  }
}
```

---

## ?? Check Logs

**Console s? hi?n th?:**
```
[INFO] Using model: ResNet50_RiceDisease v2.1.0
[WARN] Using MOCK data - Model URL not configured
[INFO] Generated mock prediction: Rice_Blast (0.8523)
```

---

## ?? Test v?i Postman/cURL

### **cURL:**
```bash
# Login
curl -X POST "https://localhost:5001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@Swd.com","password":"StrongPassword@123"}'

# Predict (thay TOKEN)
curl -X POST "https://localhost:5001/api/predictions/run" \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"uploadId":1}'
```

---

## ?? Test Complete Flow

```javascript
// Frontend test code
async function testPrediction() {
  // 1. Login
  const loginRes = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'admin@Swd.com',
      password: 'StrongPassword@123'
    })
  });
  const { token } = await loginRes.json();

  // 2. Run prediction
  const predictRes = await fetch('/api/predictions/run', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ uploadId: 1 })
  });
  const result = await predictRes.json();

  console.log('Prediction:', result);
  // Mock data s? random tr? v? Rice_Blast, Brown_Spot, ho?c Corn_Rust
}

testPrediction();
```

---

## ? Verification

### **Check Database:**
```sql
-- Xem prediction v?a t?o
SELECT TOP 1 * 
FROM predictions 
ORDER BY prediction_id DESC;

-- Xem v?i details
SELECT 
  p.prediction_id,
  p.predicted_class,
  p.confidence_score,
  p.processing_time_ms,
  t.tree_name,
  i.illness_name,
  m.model_name,
  m.version
FROM predictions p
LEFT JOIN trees t ON p.tree_id = t.tree_id
LEFT JOIN tree_illnesses i ON p.illness_id = i.illness_id
LEFT JOIN model_versions m ON p.model_version_id = m.model_version_id
ORDER BY p.created_at DESC;
```

---

## ?? Mock Data Variations

**M?i l?n g?i s? random:**
- **Disease:** Rice_Blast, Brown_Spot, ho?c Corn_Rust
- **Confidence:** 0.70 - 0.95
- **Processing Time:** 300ms - 800ms

**Test nhi?u l?n ð? th?y variations!**

---

## ?? Ready for Real Model

**Khi model th?t s?n sàng:**

```json
// appsettings.json
{
  "AIModel": {
    "Url": "https://your-model.com/predict",
    "UseMock": "false"
  }
}
```

**Restart ? Test l?i ? Done!**

---

**Test thành công = Ready to integrate!** ?

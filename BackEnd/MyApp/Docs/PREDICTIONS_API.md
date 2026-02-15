# ?? Predictions API Documentation

## ?? Overview

API ð? ch?y prediction (d? ðoán b?nh cây lúa), xem chi ti?t prediction và l?ch s? predictions.

**Base URL:** `/api/predictions`  
**Authorization:** JWT Bearer Token required

---

## ?? API Endpoints

### 1. POST /api/predictions/run
**M?c ðích:** Ch?y prediction trên ?nh ð? upload

**Authorization:** Required (All authenticated users)

**Request Body:**
```json
{
  "uploadId": 123,
  "modelVersionId": 1,
  "usePreprocessedImage": true
}
```

**Request Parameters:**
- `uploadId` (int, **required**): ID c?a ?nh ð? upload
- `modelVersionId` (int, optional): Model version ð? s? d?ng (null = dùng default model)
- `usePreprocessedImage` (bool, default: true): Dùng ?nh ð? preprocess hay không

**Response Success (200):**
```json
{
  "success": true,
  "message": "Prediction completed successfully",
  "data": {
    "predictionId": 501,
    "tree": {
      "treeId": 1,
      "treeName": "Lúa"
    },
    "illness": {
      "illnessId": 3,
      "illnessName": "Ð?o ôn"
    },
    "confidenceScore": 0.92,
    "processingTimeMs": 450,
    "createdAt": "2025-01-01T10:02:00"
  }
}
```

**Response Error (400):**
```json
{
  "success": false,
  "message": "Image upload 123 not found"
}
```

**X? l?:**
1. Validate uploadId t?n t?i
2. Ch?y inference qua AIService
3. Lýu prediction vào database
4. Return k?t qu? v?i thông tin tree và illness

---

### 2. GET /api/predictions/{id}
**M?c ðích:** L?y chi ti?t m?t prediction theo ID

**Authorization:** Required

**Path Parameters:**
- `id` (int): Prediction ID

**Response Success (200):**
```json
{
  "success": true,
  "message": "Prediction retrieved successfully",
  "data": {
    "predictionId": 501,
    "predictedClass": "Rice_Blast",
    "confidenceScore": 0.92,
    "topNPredictions": [
      {
        "class": "Rice_Blast",
        "score": 0.92
      },
      {
        "class": "Brown_Spot",
        "score": 0.05
      },
      {
        "class": "Leaf_Blight",
        "score": 0.02
      }
    ],
    "processingTimeMs": 450,
    "createdAt": "2025-01-01T10:02:00",
    "tree": {
      "treeId": 1,
      "treeName": "Lúa"
    },
    "illness": {
      "illnessId": 3,
      "illnessName": "Ð?o ôn"
    },
    "model": {
      "modelVersionId": 1,
      "modelName": "ResNet18_RiceDisease",
      "version": "v1.0.0"
    }
  }
}
```

**Response Not Found (404):**
```json
{
  "success": false,
  "message": "Prediction with ID 999 not found"
}
```

**X? l?:**
1. T?m prediction theo ID
2. Include related entities (Tree, Illness, ModelVersion)
3. Parse TopNPredictions JSON
4. Return chi ti?t ð?y ð?

---

### 3. GET /api/predictions/history
**M?c ðích:** L?y l?ch s? predictions

**Authorization:** Required

**Query Parameters:**
- `userId` (int, optional): Filter theo user (m?c ð?nh: current user t? JWT)
- `fromDate` (DateTime, optional): Filter t? ngày
- `toDate` (DateTime, optional): Filter ð?n ngày

**Example:**
```
GET /api/predictions/history
GET /api/predictions/history?fromDate=2025-01-01
GET /api/predictions/history?userId=5&fromDate=2025-01-01&toDate=2025-01-31
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Prediction history retrieved successfully",
  "count": 3,
  "data": [
    {
      "predictionId": 501,
      "treeName": "Lúa",
      "illnessName": "Ð?o ôn",
      "confidenceScore": 0.92,
      "createdAt": "2025-01-01T10:02:00",
      "imagePath": "uploads/images/img_123.jpg",
      "modelName": "ResNet18_RiceDisease v1.0.0"
    },
    {
      "predictionId": 502,
      "treeName": "Lúa",
      "illnessName": "Brown Spot",
      "confidenceScore": 0.85,
      "createdAt": "2025-01-02T14:30:00",
      "imagePath": "uploads/images/img_124.jpg",
      "modelName": "ResNet18_RiceDisease v1.0.0"
    }
  ]
}
```

**X? l?:**
1. L?y userId t? JWT token n?u không ðý?c provide
2. Query predictions v?i filters
3. Include related entities
4. Order by CreatedAt descending
5. Return list sorted

---

## ?? Use Cases

### Use Case 1: User upload ?nh và nh?n d? ðoán
```
# Step 1: Upload image (existing API)
POST /api/uploads
? Returns uploadId = 123

# Step 2: Run prediction
POST /api/predictions/run
{
  "uploadId": 123
}
? Returns prediction result

# Step 3: View detail
GET /api/predictions/501
? Returns full prediction details
```

### Use Case 2: Xem l?ch s? predictions c?a user
```
GET /api/predictions/history
? Returns all predictions c?a current user

GET /api/predictions/history?fromDate=2025-01-01&toDate=2025-01-31
? Returns predictions trong tháng 1
```

### Use Case 3: So sánh predictions
```
GET /api/predictions/501
GET /api/predictions/502
? So sánh confidence scores và top predictions
```

---

## ?? Authorization

T?t c? endpoints yêu c?u:
- JWT Bearer Token trong header
- User ph?i authenticated

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Roles:**
- All authenticated users có th?:
  - Run predictions
  - View own predictions
  - View own history

---

## ?? Data Flow

```
POST /api/predictions/run
         ?
PredictionsController.RunPrediction()
         ?
PredictionService.RunPredictionAsync()
         ?
AIService.RunInferenceAsync()
         ?
- Preprocess image (n?u c?n)
- Run ML model inference
- Save to predictions table
         ?
Return prediction result
```

---

## ?? Error Handling

### Common Errors:

**400 Bad Request:**
```json
{
  "success": false,
  "message": "UploadId is required"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Image upload 123 not found"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "An error occurred while running prediction",
  "error": "Detailed error message"
}
```

---

## ?? Notes

### TopNPredictions Format
Lýu d?ng JSON trong database:
```json
[
  {"className": "Rice_Blast", "confidence": 0.92, "treeId": 1, "illnessId": 3},
  {"className": "Brown_Spot", "confidence": 0.05, "treeId": 1, "illnessId": 2}
]
```

### Default Behavior
- N?u không specify `modelVersionId` ? dùng default model
- N?u không specify `userId` trong history ? dùng current user t? JWT
- `usePreprocessedImage` m?c ð?nh = true ð? tãng accuracy

---

## ?? Testing v?i Swagger

1. Navigate to: `https://localhost:5001`
2. Click "Authorize" và nh?p JWT token
3. Test endpoints:
   - POST `/api/predictions/run`
   - GET `/api/predictions/{id}`
   - GET `/api/predictions/history`

---

## ? Summary

| Endpoint | Method | Authorization | Description |
|----------|--------|---------------|-------------|
| `/api/predictions/run` | POST | Required | Run prediction |
| `/api/predictions/{id}` | GET | Required | Get prediction detail |
| `/api/predictions/history` | GET | Required | Get prediction history |

**Total:** 3 endpoints chu?n theo yêu c?u ?

---

**Created:** 2024  
**Version:** 1.0.0  
**Status:** ? Complete

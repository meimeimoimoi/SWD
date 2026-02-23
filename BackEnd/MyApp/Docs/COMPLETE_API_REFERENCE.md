# ?? Complete API Reference - All Endpoints

## ?? T?ng quan: 24 API Endpoints (Optimized)

**? Ki?n trúc m?i:** API này CH? qu?n l? metadata. AI model ch?y ? server riêng.

---

## ?? 1. AUTHENTICATION (3 endpoints)
**Controller:** AuthController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| POST | `/api/auth/login` | Public | User login |
| POST | `/api/auth/register` | Public | User register |
| POST | `/api/auth/logout` | Authenticated | User logout |

---

## ?? 2. USER MANAGEMENT (6 endpoints)
**Controller:** AdminController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| GET | `/api/admin/users` | Admin | Get all users |
| GET | `/api/admin/users/{id}` | Admin | Get user by ID |
| PUT | `/api/admin/users/{id}` | Admin | Update user |
| PATCH | `/api/admin/users/{id}/status` | Admin | Update user status |
| POST | `/api/admin/users/staff` | Admin | Create staff/technician |
| DELETE | `/api/admin/users/{id}` | Admin | Delete user |

---

## ?? 3. MODEL MANAGEMENT (6 endpoints)
**Controller:** ModelsController
**M?c ðích:** Qu?n l? metadata c?a ML models (model th?c t? ? AI server riêng)

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| GET | `/api/models` | Technical, Admin | Get all models metadata |
| GET | `/api/models/{id}` | Technical, Admin | Get model metadata by ID |
| GET | `/api/models/default` | Technical, Admin | Get default model |
| PUT | `/api/models/{id}/activate` | Technical, Admin | Activate model |
| PUT | `/api/models/{id}/deactivate` | Technical, Admin | Deactivate model |
| PUT | `/api/models/{id}/set-default` | Technical, Admin | Set as default |

---

## ?? 4. PREDICTIONS (3 endpoints)
**Controller:** PredictionsController
**M?c ðích:** Lýu k?t qu? prediction t? AI server

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| POST | `/api/predictions/run` | Authenticated | Lýu prediction t? AI server |
| GET | `/api/predictions/{id}` | Authenticated | Get prediction detail |
| GET | `/api/predictions/history` | Authenticated | Get prediction history |

**?? NOTE:** Frontend workflow:
```javascript
// 1. Upload ?nh
POST /api/uploads ? uploadId

// 2. G?i ?nh t?i AI Server (Python)
POST http://ai-server:5000/predict ? prediction result

// 3. Lýu k?t qu? vào API
POST /api/predictions/run
{
  "uploadId": 123,
  "predictionId": 501,  // T? AI server
  ...
}
```

---

## ?? 5. TREES (4 endpoints)
**Controller:** TreesController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| GET | `/api/trees` | Public | Get all trees |
| GET | `/api/trees/{id}` | Public | Get tree by ID |
| POST | `/api/trees` | Admin | Create tree |
| PUT | `/api/trees/{id}` | Admin | Update tree |
| DELETE | `/api/trees/{id}` | Admin | Delete tree |

---

## ?? 6. ILLNESSES (4 endpoints)
**Controller:** IllnessesController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| GET | `/api/illnesses` | Public | Get all illnesses |
| GET | `/api/illnesses/{id}` | Public | Get illness by ID |
| POST | `/api/illnesses` | Admin | Create illness |
| PUT | `/api/illnesses/{id}` | Admin | Update illness |
| DELETE | `/api/illnesses/{id}` | Admin | Delete illness |

---

## ?? 7. TREE-ILLNESS MAPPING (2 endpoints)
**Controller:** TreeIllnessController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| POST | `/api/tree-illness/map` | Admin | Map tree to illness |
| DELETE | `/api/tree-illness/unmap?treeId={id}&illnessId={id}` | Admin | Unmap tree from illness |

---

## ?? 8. SOLUTIONS (5 endpoints)
**Controller:** SolutionsController

| Method | Endpoint | Authorization | Description |
|--------|----------|---------------|-------------|
| GET | `/api/solutions` | Public | Get all solutions |
| GET | `/api/solutions/{id}` | Public | Get solution by ID |
| GET | `/api/solutions/by-prediction/{id}` | Authenticated | Get solutions by prediction |
| GET | `/api/solutions/by-illness/{id}` | Public | Get solutions by illness |
| POST | `/api/solutions` | Admin | Create solution |
| PUT | `/api/solutions/{id}` | Admin | Update solution |
| DELETE | `/api/solutions/{id}` | Admin | Delete solution |

---

## ?? Summary by Authorization

| Authorization | Endpoint Count | Controllers |
|---------------|----------------|-------------|
| **Public** | 8 | Trees (read), Illnesses (read), Solutions (read) |
| **Authenticated** | 3 | Predictions |
| **Admin** | 16 | All write operations |
| **Technical/Admin** | 6 | Models |

---

## ??? Architecture Overview

```
???????????????????????????????????????????????????
?              Frontend/Mobile App                 ?
???????????????????????????????????????????????????
      ?                                   ?
      ? Upload, Save, Query              ? Predict
      ?                                   ?
???????????????????              ??????????????????
?  .NET API       ?              ?  AI Server     ?
?  (This Code)    ?              ?  (Separate)    ?
?                 ?              ?                ?
?  Endpoints:     ?              ?  - ML Model    ?
?  - Auth         ?              ?  - Preprocess  ?
?  - Models*      ?              ?  - Inference   ?
?  - Predictions* ?              ?                ?
?  - Trees        ?              ?  Python/Flask  ?
?  - Illnesses    ?              ?  or FastAPI    ?
?  - Solutions    ?              ?                ?
???????????????????              ??????????????????
         ?
         ? *Models = metadata only
         ? *Predictions = save results only
         ?
???????????????????
?   SQL Server    ?
?   Database      ?
???????????????????
```

---

## ?? Complete User Journey

```
1. User Login
   POST /api/auth/login
   
2. Upload Image
   POST /api/uploads
   ? Returns: uploadId, filePath
   
3. Call AI Server (Frontend direct)
   POST http://ai-server:5000/predict
   {
     "imagePath": "/uploads/img_123.jpg"
   }
   ? Returns: {
       predictionId, treeId, illnessId,
       confidenceScore, topNPredictions
     }
   
4. Save Prediction Result
   POST /api/predictions/run
   {
     "uploadId": 123,
     "predictionId": 501,
     ...
   }
   
5. Get Solutions
   GET /api/solutions/by-prediction/501
   
6. Display Results to User
```

---

## ?? API Request/Response Examples

### Example 1: Upload & Predict Flow

```javascript
// Step 1: Upload image
const uploadFormData = new FormData();
uploadFormData.append('file', imageFile);

const uploadResponse = await fetch('/api/uploads', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: uploadFormData
});
const { uploadId, filePath } = await uploadResponse.json();
// Response: { uploadId: 123, filePath: "/uploads/img_123.jpg" }

// Step 2: Call AI Server
const aiResponse = await fetch('http://ai-server:5000/predict', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ imagePath: filePath })
});
const aiResult = await aiResponse.json();
// Response: {
//   predictionId: 501,
//   predictedClass: "Rice_Blast",
//   treeId: 1,
//   illnessId: 3,
//   confidenceScore: 0.85,
//   topNPredictions: [...],
//   processingTimeMs: 450
// }

// Step 3: Save to API
const savePredictionResponse = await fetch('/api/predictions/run', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    uploadId: uploadId,
    predictionId: aiResult.predictionId
  })
});
// Response: {
//   success: true,
//   data: {
//     predictionId: 501,
//     tree: { treeId: 1, treeName: "Lúa" },
//     illness: { illnessId: 3, illnessName: "Ð?o ôn" },
//     confidenceScore: 0.85
//   }
// }

// Step 4: Get Solutions
const solutionsResponse = await fetch(
  `/api/solutions/by-prediction/501`,
  { headers: { 'Authorization': `Bearer ${token}` } }
);
const solutions = await solutionsResponse.json();
// Response: {
//   success: true,
//   count: 3,
//   solutions: [
//     {
//       solutionId: 10,
//       solutionName: "Phun thu?c sinh h?c",
//       solutionType: "BIOLOGICAL",
//       priority: 1
//     },
//     ...
//   ]
// }
```

---

## ?? Important Notes

### 1. AI Server Setup (Separate)
```python
# Example AI Server (Python Flask)
from flask import Flask, request, jsonify
import tensorflow as tf

app = Flask(__name__)
model = tf.keras.models.load_model('rice_disease_model.h5')

@app.route('/predict', methods=['POST'])
def predict():
    image_path = request.json['imagePath']
    
    # Load & preprocess image
    image = load_and_preprocess(image_path)  # resize, normalize
    
    # Run prediction
    predictions = model.predict(image)
    
    # Map to tree/illness IDs
    result = {
        'predictionId': generate_prediction_id(),
        'predictedClass': class_names[predictions.argmax()],
        'treeId': map_to_tree_id(predictions.argmax()),
        'illnessId': map_to_illness_id(predictions.argmax()),
        'confidenceScore': float(predictions.max()),
        'topNPredictions': get_top_n(predictions, 5),
        'processingTimeMs': elapsed_time
    }
    
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### 2. Image Storage (Simplified)
```
uploads/
??? images/
    ??? user_123_img_001.jpg  (?nh g?c, không x? l?)
    ??? user_123_img_002.jpg
    ??? ...

Notes:
- ?nh lýu tr?c ti?p, không preprocessing
- AI Server t? x? l? ?nh khi predict
- API ch? lýu path trong database
```

### 3. Model Metadata Only
```json
// GET /api/models response
{
  "success": true,
  "data": [
    {
      "modelVersionId": 1,
      "modelName": "ResNet50_RiceDisease",
      "version": "v1.0.0",
      "modelType": "resnet50",
      "isActive": true,
      "isDefault": true,
      "description": "Model trained on 10,000 rice disease images"
    }
  ]
}

// NOTE: Actual model files (.h5, .onnx, .pb) are on AI Server
```

---

## ?? Response Format (Consistent)

### Success Response:
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response:
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

### List Response:
```json
{
  "success": true,
  "message": "Items retrieved successfully",
  "count": 5,
  "data": [...]
}
```

---

## ?? Benefits of This Architecture

### ? **Simplified .NET API**
- No image processing complexity
- No ML dependencies
- Faster response times
- Easier to maintain

### ? **Scalable AI Server**
- Can use GPU efficiently
- Independent scaling
- Easy to update models
- Support multiple model versions

### ? **Clear Separation**
- Business logic in .NET
- ML logic in Python
- Best tool for each job

### ? **Flexible Deployment**
- .NET API on any cloud
- AI Server on GPU instance
- Can use Docker containers

---

## ?? Comparison

| Aspect | Before (Monolithic) | After (Separated) |
|--------|---------------------|-------------------|
| Endpoints | 25 | 24 |
| Image Processing | In API | In AI Server |
| ML Model | In API | In AI Server |
| GPU Requirement | API needs GPU | Only AI Server |
| Code Complexity | High | **Simple** |
| Scalability | Limited | **Excellent** |
| Maintainability | Medium | **High** |

---

**Total Endpoints:** 24  
**Controllers:** 5  
**Build Status:** ? SUCCESS  
**Framework:** .NET 9.0  
**Architecture:** Microservices (API + AI Server)  
**Status:** ? Optimized & Production Ready

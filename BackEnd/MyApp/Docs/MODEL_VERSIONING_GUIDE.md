# ?? Model Versioning Guide - Always Use Latest

## ?? Overview

H? th?ng ð? ðý?c c?p nh?t ð? **t? ð?ng s? d?ng model version m?i nh?t**. Không c?n c? ð?nh version, API s? t? ð?ng l?y version m?i nh?t khi c?n.

---

## ?? New API Endpoints

### **Get Latest Active Model**
```
GET /api/models/latest
```

**M?c ðích:** L?y model version m?i nh?t ðang active

**Authorization:** Technical, Admin

**Response:**
```json
{
  "success": true,
  "message": "Latest active model retrieved successfully",
  "data": {
    "modelVersionId": 5,
    "modelName": "ResNet50_RiceDisease",
    "version": "v2.1.0",
    "modelType": "resnet50",
    "description": "Latest model with improved accuracy",
    "isActive": true,
    "isDefault": false,
    "minConfidence": 0.75,
    "createdAt": "2024-12-20T10:00:00Z"
  }
}
```

---

### **Get Latest Model By Name**
```
GET /api/models/latest/{modelName}
```

**M?c ðích:** L?y version m?i nh?t c?a m?t model c? th?

**Authorization:** Technical, Admin

**Example:**
```
GET /api/models/latest/ResNet50_RiceDisease
```

**Response:**
```json
{
  "success": true,
  "message": "Latest version of 'ResNet50_RiceDisease' retrieved successfully",
  "data": {
    "modelVersionId": 5,
    "modelName": "ResNet50_RiceDisease",
    "version": "v2.1.0",
    "modelType": "resnet50",
    "isActive": true,
    "createdAt": "2024-12-20T10:00:00Z"
  }
}
```

---

## ?? Model Version Strategy

### **3 cách l?y model:**

| Endpoint | Use Case | Logic |
|----------|----------|-------|
| `GET /api/models/default` | Dùng model m?c ð?nh | L?y model có `isDefault = true` |
| `GET /api/models/latest` | **Dùng model m?i nh?t** | L?y model có `createdAt` m?i nh?t |
| `GET /api/models/latest/{name}` | Dùng version m?i nh?t c?a model c? th? | Filter by name + newest |

---

## ?? Frontend Integration

### **Option 1: Always use latest (Recommended)**

```javascript
// Luôn dùng model m?i nh?t
async function getModelForPrediction() {
  const response = await fetch('/api/models/latest', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const result = await response.json();
  return result.data;
}

// S? d?ng
const latestModel = await getModelForPrediction();
console.log(`Using model: ${latestModel.modelName} v${latestModel.version}`);

// G?i t?i AI Server
const aiResponse = await fetch('http://ai-server:5000/predict', {
  method: 'POST',
  body: JSON.stringify({
    imagePath: filePath,
    modelVersionId: latestModel.modelVersionId,
    modelName: latestModel.modelName,
    version: latestModel.version
  })
});
```

---

### **Option 2: Use latest by model name**

```javascript
// Dùng version m?i nh?t c?a model c? th?
async function getLatestModelByName(modelName) {
  const response = await fetch(`/api/models/latest/${modelName}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const result = await response.json();
  return result.data;
}

// S? d?ng
const model = await getLatestModelByName('ResNet50_RiceDisease');
console.log(`Using: ${model.modelName} v${model.version}`);
```

---

### **Option 3: Use default model**

```javascript
// Dùng model ðý?c ðánh d?u default
async function getDefaultModel() {
  const response = await fetch('/api/models/default', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const result = await response.json();
  return result.data;
}
```

---

## ?? Complete Prediction Workflow (With Latest Model)

```javascript
// Complete flow: Upload ? Get Latest Model ? Predict ? Save
async function predictWithLatestModel(imageFile) {
  try {
    // 1. Upload image
    const uploadFormData = new FormData();
    uploadFormData.append('file', imageFile);
    
    const uploadResponse = await fetch('/api/uploads', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` },
      body: uploadFormData
    });
    const { uploadId, filePath } = await uploadResponse.json();
    
    // 2. Get latest model
    const modelResponse = await fetch('/api/models/latest', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const modelData = await modelResponse.json();
    const latestModel = modelData.data;
    
    console.log(`Using latest model: ${latestModel.modelName} v${latestModel.version}`);
    
    // 3. Call AI Server with latest model info
    const aiResponse = await fetch('http://ai-server:5000/predict', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        imagePath: filePath,
        modelVersionId: latestModel.modelVersionId,
        modelName: latestModel.modelName,
        modelVersion: latestModel.version
      })
    });
    const prediction = await aiResponse.json();
    
    // 4. Save prediction result
    const saveResponse = await fetch('/api/predictions/run', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        uploadId: uploadId,
        predictionId: prediction.predictionId
      })
    });
    const savedPrediction = await saveResponse.json();
    
    // 5. Get solutions
    const solutionsResponse = await fetch(
      `/api/solutions/by-prediction/${prediction.predictionId}`,
      { headers: { 'Authorization': `Bearer ${token}` } }
    );
    const solutions = await solutionsResponse.json();
    
    return {
      model: latestModel,
      prediction: savedPrediction,
      solutions: solutions
    };
    
  } catch (error) {
    console.error('Error in prediction workflow:', error);
    throw error;
  }
}

// Usage
const result = await predictWithLatestModel(selectedImageFile);
console.log('Prediction result:', result);
```

---

## ??? AI Server Implementation

### **Python AI Server c?n support model version:**

```python
from flask import Flask, request, jsonify
import tensorflow as tf
import os

app = Flask(__name__)

# Load models dynamically
models = {}

def load_model(model_name, version):
    """Load specific model version"""
    model_key = f"{model_name}_{version}"
    
    if model_key not in models:
        model_path = f"./models/{model_name}/{version}/model.h5"
        if os.path.exists(model_path):
            models[model_key] = tf.keras.models.load_model(model_path)
            print(f"Loaded model: {model_key}")
        else:
            raise FileNotFoundError(f"Model not found: {model_path}")
    
    return models[model_key]

def load_latest_model(model_name):
    """Load latest version of model"""
    model_dir = f"./models/{model_name}"
    versions = sorted(os.listdir(model_dir), reverse=True)
    
    if not versions:
        raise FileNotFoundError(f"No versions found for model: {model_name}")
    
    latest_version = versions[0]
    return load_model(model_name, latest_version), latest_version

@app.route('/predict', methods=['POST'])
def predict():
    data = request.json
    image_path = data['imagePath']
    
    # Get model info from request or use latest
    if 'modelName' in data and 'modelVersion' in data:
        model_name = data['modelName']
        model_version = data['modelVersion']
        model = load_model(model_name, model_version)
        print(f"Using specified model: {model_name} v{model_version}")
    else:
        # Auto-load latest model
        model_name = "ResNet50_RiceDisease"  # Default model name
        model, model_version = load_latest_model(model_name)
        print(f"Using latest model: {model_name} v{model_version}")
    
    # Preprocess image
    image = load_and_preprocess(image_path)
    
    # Run prediction
    predictions = model.predict(image)
    
    # Return result
    result = {
        'predictionId': generate_prediction_id(),
        'predictedClass': class_names[predictions.argmax()],
        'treeId': map_to_tree_id(predictions.argmax()),
        'illnessId': map_to_illness_id(predictions.argmax()),
        'confidenceScore': float(predictions.max()),
        'topNPredictions': get_top_n(predictions, 5),
        'processingTimeMs': elapsed_time,
        'modelUsed': {
            'modelName': model_name,
            'version': model_version
        }
    }
    
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

---

## ?? Model Storage Structure

```
ai-server/
??? models/
    ??? ResNet50_RiceDisease/
    ?   ??? v1.0.0/
    ?   ?   ??? model.h5
    ?   ??? v1.5.0/
    ?   ?   ??? model.h5
    ?   ??? v2.1.0/          ? Latest version
    ?       ??? model.h5
    ?
    ??? EfficientNet_RiceDisease/
        ??? v1.0.0/
        ?   ??? model.h5
        ??? v2.0.0/          ? Latest version
            ??? model.h5
```

---

## ?? Model Update Workflow

### **Khi có model m?i:**

```sql
-- 1. Admin insert model m?i vào database
INSERT INTO model_versions (model_name, version, model_type, is_active, is_default, created_at)
VALUES ('ResNet50_RiceDisease', 'v2.1.0', 'resnet50', 1, 0, GETDATE());

-- 2. Copy model file vào AI server
scp model_v2.1.0.h5 ai-server:/models/ResNet50_RiceDisease/v2.1.0/model.h5

-- 3. Test model
GET /api/models/latest
? Returns v2.1.0

-- 4. N?u ok, set làm default (optional)
PUT /api/models/{id}/set-default
```

### **Frontend t? ð?ng dùng model m?i:**
```javascript
// Frontend không c?n thay ð?i g?
// API t? ð?ng tr? v? version m?i nh?t
const latestModel = await fetch('/api/models/latest').then(r => r.json());
// Luôn nh?n ðý?c version m?i nh?t: v2.1.0
```

---

## ? Benefits

### **1. No Hard-coded Versions**
```javascript
// ? Old way (hard-coded)
const modelVersionId = 3;  // C? ð?nh

// ? New way (dynamic)
const model = await fetch('/api/models/latest').then(r => r.json());
const modelVersionId = model.data.modelVersionId;  // Luôn m?i nh?t
```

### **2. Easy Model Updates**
- Deploy model m?i ? API t? ð?ng dùng
- Không c?n update frontend code
- Rollback d? dàng (deactivate model m?i)

### **3. A/B Testing**
```javascript
// Test model m?i
const newModel = await fetch('/api/models/latest').then(r => r.json());

// So sánh v?i model c?
const oldModel = await fetch('/api/models/3').then(r => r.json());

// Ch?y c? 2 ð? so sánh
```

---

## ?? API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/models` | GET | Get all models |
| `/api/models/{id}` | GET | Get specific version |
| `/api/models/default` | GET | Get default model |
| **`/api/models/latest`** | **GET** | **Get newest version** ? |
| **`/api/models/latest/{name}`** | **GET** | **Get newest by name** ? |
| `/api/models/{id}/activate` | PUT | Activate model |
| `/api/models/{id}/deactivate` | PUT | Deactivate model |
| `/api/models/{id}/set-default` | PUT | Set as default |

---

## ?? Recommendation

### **Best Practice:**
```javascript
// ? RECOMMENDED: Always use latest
const model = await fetch('/api/models/latest');

// ? ALTERNATIVE: Use latest of specific model
const model = await fetch('/api/models/latest/ResNet50_RiceDisease');

// ?? FALLBACK: Use default if latest fails
const model = await fetch('/api/models/default');
```

---

**Status:** ? Complete  
**New Endpoints:** 2  
**Total Model Endpoints:** 8  
**Build:** ? SUCCESS

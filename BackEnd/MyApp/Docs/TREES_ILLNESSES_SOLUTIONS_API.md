# ?? Trees, Illnesses & Solutions API Documentation

## ?? Overview

API system ð? qu?n l? Trees (cây tr?ng), Illnesses (b?nh), Relationships (quan h? cây-b?nh), và Solutions (gi?i pháp ði?u tr?).

---

## ?? API Endpoints Summary

### **Trees API** - 4 endpoints
```
GET    /api/trees                    # Xem t?t c? cây
GET    /api/trees/{id}               # Xem cây theo ID
POST   /api/trees                    # T?o cây m?i (Admin)
PUT    /api/trees/{id}               # C?p nh?t cây (Admin)
DELETE /api/trees/{id}               # Xóa cây (Admin)
```

### **Illnesses API** - 4 endpoints
```
GET    /api/illnesses                # Xem t?t c? b?nh
GET    /api/illnesses/{id}           # Xem b?nh theo ID
POST   /api/illnesses                # T?o b?nh m?i (Admin)
PUT    /api/illnesses/{id}           # C?p nh?t b?nh (Admin)
DELETE /api/illnesses/{id}           # Xóa b?nh (Admin)
```

### **Tree-Illness Relationships** - 2 endpoints
```
POST   /api/tree-illness/map         # Map cây v?i b?nh (Admin)
DELETE /api/tree-illness/unmap       # Unmap cây kh?i b?nh (Admin)
```

### **Solutions API** - 5 endpoints
```
GET    /api/solutions                        # Xem t?t c? solutions
GET    /api/solutions/{id}                   # Xem solution theo ID
GET    /api/solutions/by-prediction/{id}     # L?y solutions theo prediction
GET    /api/solutions/by-illness/{id}        # L?y solutions theo illness
POST   /api/solutions                        # T?o solution m?i (Admin)
PUT    /api/solutions/{id}                   # C?p nh?t solution (Admin)
DELETE /api/solutions/{id}                   # Xóa solution (Admin)
```

**T?ng c?ng: 15 API endpoints**

---

## ?? 1. TREES API

### 1.1 GET /api/trees
**Authorization:** Public (no auth required)

**Response:**
```json
{
  "success": true,
  "message": "Trees retrieved successfully",
  "count": 2,
  "data": [
    {
      "treeId": 1,
      "treeName": "Lúa",
      "scientificName": "Oryza sativa",
      "description": "Cây lúa là lo?i cây tr?ng quan tr?ng...",
      "imagePath": "/images/trees/rice.jpg",
      "createdAt": "2024-01-01T00:00:00Z",
      "illnesses": [
        {
          "illnessId": 1,
          "illnessName": "Ð?o ôn",
          "severity": "High"
        }
      ]
    }
  ]
}
```

### 1.2 GET /api/trees/{id}
**Authorization:** Public

**Response:**
```json
{
  "success": true,
  "message": "Tree retrieved successfully",
  "data": {
    "treeId": 1,
    "treeName": "Lúa",
    "scientificName": "Oryza sativa",
    "description": "Cây lúa...",
    "imagePath": "/images/trees/rice.jpg",
    "createdAt": "2024-01-01T00:00:00Z",
    "illnesses": [...]
  }
}
```

### 1.3 POST /api/trees
**Authorization:** Admin only

**Request:**
```json
{
  "treeName": "Lúa",
  "scientificName": "Oryza sativa",
  "description": "Cây lúa là lo?i cây tr?ng...",
  "imagePath": "/images/trees/rice.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tree created successfully",
  "data": {
    "treeId": 1,
    "treeName": "Lúa",
    ...
  }
}
```

### 1.4 PUT /api/trees/{id}
**Authorization:** Admin only

**Request:**
```json
{
  "treeName": "Lúa Nh?t",
  "scientificName": "Oryza sativa japonica",
  "description": "Updated description",
  "imagePath": "/images/trees/rice-updated.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tree 1 updated successfully"
}
```

### 1.5 DELETE /api/trees/{id}
**Authorization:** Admin only

**Response:**
```json
{
  "success": true,
  "message": "Tree 1 deleted successfully"
}
```

---

## ?? 2. ILLNESSES API

### 2.1 GET /api/illnesses
**Authorization:** Public

**Response:**
```json
{
  "success": true,
  "message": "Illnesses retrieved successfully",
  "count": 2,
  "data": [
    {
      "illnessId": 1,
      "illnessName": "Ð?o ôn",
      "scientificName": "Pyricularia oryzae",
      "description": "B?nh ð?o ôn là b?nh ph? bi?n...",
      "symptoms": "Lá có ð?m nâu, h?nh thoi",
      "causes": "N?m Pyricularia oryzae gây ra",
      "severity": "High",
      "createdAt": "2024-01-01T00:00:00Z",
      "affectedTrees": [
        {
          "treeId": 1,
          "treeName": "Lúa"
        }
      ]
    }
  ]
}
```

### 2.2 GET /api/illnesses/{id}
**Authorization:** Public

**Response:** Same structure as GET all, but single illness

### 2.3 POST /api/illnesses
**Authorization:** Admin only

**Request:**
```json
{
  "illnessName": "Ð?o ôn",
  "scientificName": "Pyricularia oryzae",
  "description": "B?nh ph? bi?n trên lúa",
  "symptoms": "Lá có ð?m nâu",
  "causes": "N?m gây b?nh",
  "severity": "High"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Illness created successfully",
  "data": { ... }
}
```

### 2.4 PUT /api/illnesses/{id}
**Authorization:** Admin only

**Request:** Same as POST

**Response:**
```json
{
  "success": true,
  "message": "Illness 1 updated successfully"
}
```

### 2.5 DELETE /api/illnesses/{id}
**Authorization:** Admin only

**Response:**
```json
{
  "success": true,
  "message": "Illness 1 deleted successfully"
}
```

---

## ?? 3. TREE-ILLNESS RELATIONSHIPS API

### 3.1 POST /api/tree-illness/map
**Authorization:** Admin only

**Request:**
```json
{
  "treeId": 1,
  "illnessId": 1
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tree 1 mapped to illness 1 successfully"
}
```

**Business Rules:**
- Tree và Illness ph?i t?n t?i
- Không cho phép duplicate mapping
- Unique constraint: (TreeId, IllnessId)

### 3.2 DELETE /api/tree-illness/unmap
**Authorization:** Admin only

**Query Parameters:**
- `treeId` (int, required)
- `illnessId` (int, required)

**Example:**
```
DELETE /api/tree-illness/unmap?treeId=1&illnessId=1
```

**Response:**
```json
{
  "success": true,
  "message": "Tree 1 unmapped from illness 1 successfully"
}
```

---

## ?? 4. SOLUTIONS API

### 4.1 GET /api/solutions
**Authorization:** Public

**Response:**
```json
{
  "success": true,
  "message": "Solutions retrieved successfully",
  "count": 3,
  "data": [
    {
      "solutionId": 1,
      "solutionName": "Phun thu?c sinh h?c",
      "solutionType": "BIOLOGICAL",
      "description": "S? d?ng thu?c sinh h?c...",
      "priority": 1,
      "minConfidence": 0.75,
      "illness": {
        "illnessId": 1,
        "illnessName": "Ð?o ôn"
      },
      "treeStage": {
        "stageId": 1,
        "stageName": "Giai ðo?n ð? nhánh"
      }
    }
  ]
}
```

### 4.2 GET /api/solutions/{id}
**Authorization:** Public

**Response:** Single solution with same structure

### 4.3 GET /api/solutions/by-prediction/{predictionId}
**Authorization:** Authenticated users

**Response:**
```json
{
  "success": true,
  "message": "Solutions retrieved successfully",
  "predictionId": 501,
  "count": 2,
  "solutions": [
    {
      "solutionId": 1,
      "solutionName": "Phun thu?c sinh h?c",
      "solutionType": "BIOLOGICAL",
      "priority": 1,
      ...
    }
  ]
}
```

**Logic:**
- L?y illness t? prediction
- Filter solutions theo:
  - `IllnessId` = prediction's illness
  - `MinConfidence` <= prediction's confidence score
- S?p x?p theo `Priority` ASC

### 4.4 GET /api/solutions/by-illness/{illnessId}
**Authorization:** Public

**Response:**
```json
{
  "success": true,
  "message": "Solutions retrieved successfully",
  "illnessId": 1,
  "count": 3,
  "solutions": [...]
}
```

### 4.5 POST /api/solutions
**Authorization:** Admin only

**Request:**
```json
{
  "solutionName": "Phun thu?c sinh h?c",
  "solutionType": "BIOLOGICAL",
  "description": "S? d?ng thu?c sinh h?c Trichoderma...",
  "illnessId": 1,
  "treeStageId": 1,
  "priority": 1,
  "minConfidence": 0.75
}
```

**Validation:**
- `solutionType` must be: BIOLOGICAL, CHEMICAL, or CULTURAL
- `minConfidence` range: 0.0 - 1.0
- `priority` >= 0

**Response:**
```json
{
  "success": true,
  "message": "Solution created successfully",
  "data": { ... }
}
```

### 4.6 PUT /api/solutions/{id}
**Authorization:** Admin only

**Request:** Same as POST

**Response:**
```json
{
  "success": true,
  "message": "Solution 1 updated successfully"
}
```

### 4.7 DELETE /api/solutions/{id}
**Authorization:** Admin only

**Response:**
```json
{
  "success": true,
  "message": "Solution 1 deleted successfully"
}
```

---

## ?? Authorization Summary

| Endpoint Group | GET (Read) | POST/PUT/DELETE (Write) |
|----------------|------------|-------------------------|
| Trees | Public | Admin only |
| Illnesses | Public | Admin only |
| Tree-Illness | N/A | Admin only |
| Solutions (all) | Public | Admin only |
| Solutions (by-prediction) | Authenticated | N/A |

---

## ?? Use Cases

### Use Case 1: Admin thêm cây m?i và b?nh
```bash
# Step 1: T?o cây
POST /api/trees
{
  "treeName": "Lúa",
  "scientificName": "Oryza sativa"
}
? Returns treeId = 1

# Step 2: T?o b?nh
POST /api/illnesses
{
  "illnessName": "Ð?o ôn",
  "severity": "High"
}
? Returns illnessId = 1

# Step 3: Map cây v?i b?nh
POST /api/tree-illness/map
{
  "treeId": 1,
  "illnessId": 1
}
```

### Use Case 2: User xem b?nh và solutions
```bash
# Step 1: Xem b?nh
GET /api/illnesses/1

# Step 2: Xem solutions cho b?nh ðó
GET /api/solutions/by-illness/1
```

### Use Case 3: Sau khi ch?y prediction, l?y solutions
```bash
# Step 1: Run prediction
POST /api/predictions/run
{
  "uploadId": 123
}
? Returns predictionId = 501, illnessId = 1

# Step 2: L?y solutions phù h?p
GET /api/solutions/by-prediction/501
? Returns solutions filtered by confidence
```

---

## ?? Database Relationships

```
trees (1) ?? (N) tree_illness_relationships (N) ?? (1) tree_illnesses
                                                              ?
                                                         (1 to N)
                                                              ?
                                                    treatment_solutions
                                                              ?
                                                         (N to 1)
                                                              ?
                                                        tree_stages
```

---

## ?? Common Errors

### 400 Bad Request
```json
{
  "success": false,
  "message": "Invalid input",
  "errors": ["TreeName is required"]
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Tree with ID 99 not found"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Unauthorized access"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Insufficient permissions. Admin role required"
}
```

---

## ?? Notes

### Solution Types
- **BIOLOGICAL**: Sinh h?c (thu?c sinh h?c, vi sinh)
- **CHEMICAL**: Hóa h?c (thu?c hóa h?c)
- **CULTURAL**: Canh tác (bi?n pháp tr?ng tr?t)

### Priority System
- Lower number = Higher priority
- Priority 1 = Most recommended
- Solutions ordered by priority ASC

### MinConfidence Logic
- Solution ch? hi?n th? n?u prediction confidence >= solution's minConfidence
- Ví d?: Prediction confidence = 0.8, Solution minConfidence = 0.75 ? Show
- Ví d?: Prediction confidence = 0.7, Solution minConfidence = 0.75 ? Hide

---

## ? Testing Checklist

- [ ] GET /api/trees - Public access
- [ ] POST /api/trees - Admin only
- [ ] GET /api/illnesses - Public access
- [ ] POST /api/tree-illness/map - Admin only
- [ ] GET /api/solutions/by-prediction/{id} - Auth required
- [ ] GET /api/solutions/by-illness/{id} - Public access

---

**Status:** ? Complete  
**Total Endpoints:** 15  
**Build Status:** ? Success  
**Framework:** .NET 9.0

# SWD - Rice Disease Detection - 3-Layer Architecture .NET Application ( Đọc cho hết làm ơn )

## 📋 Mô tả dự án
Đây là một ứng dụng Web API xây dựng theo kiến trúc 3 lớp (3-Layer Architecture), được thiết kế để nhận diện bệnh trên cây lúa sử dụng mô hình ResNet18. Dự án sử dụng .NET 9.0 và Entity Framework Core.

---

## 🏗️ Cấu trúc dự án

### 📦 SWD.Data - Data Access Layer (Lớp truy cập dữ liệu)
**Chức năng:** Quản lý tất cả các hoạt động liên quan đến cơ sở dữ liệu

**Các thành phần:**
- `DbContext/ApplicationDbContext.cs` - DbContext chính để kết nối và quản lý database
- `Entities/BaseEntity.cs` - Lớp cơ sở cho tất cả entities (chứa Id, CreatedDate, UpdatedDate, IsDeleted)
- `Repositories/IRepository.cs` - Interface định nghĩa các phương thức CRUD
- `Repositories/Repository.cs` - Triển khai chung cho Repository pattern
- `Migrations/` - Thư mục chứa database migrations

**Ví dụ sử dụng:**
```csharp
var entity = await repository.GetByIdAsync(id);
await repository.AddAsync(entity);
await repository.UpdateAsync(entity);
await repository.DeleteAsync(entity);
```

---

### 💼 SWD.Business - Business Logic Layer (Lớp logic kinh doanh)
**Chức năng:** Xử lý logic kinh doanh, validation, và xử lý dữ liệu

**Các thành phần:**
- `DTOs/BaseDTO.cs` - Lớp cơ sở cho Data Transfer Objects (chuyển dữ liệu giữa các lớp)
- `Interface/IService.cs` - Interface định nghĩa các phương thức service
- `Services/BaseService.cs` - Lớp cơ sở triển khai logic kinh doanh

**Ví dụ sử dụng:**
```csharp
public class DiseaseService : BaseService<DiseaseDTO>
{
    public override async Task<DiseaseDTO> GetByIdAsync(Guid id)
    {
        // Implement disease detection logic
    }
}
```

---

### 🌐 SWD.Presentation - Presentation Layer (Lớp giao diện)
**Chức năng:** API endpoint, controllers, và giao diện với client

**Các thành phần:**
- `Controllers/BaseController.cs` - Lớp cơ sở cho tất cả controllers
- `Controllers/HealthController.cs` - Health check endpoint
- `Models/` - View models
- `Program.cs` - Cấu hình ứng dụng và dependency injection
- `appsettings.json` - Cấu hình ứng dụng (connection string, logging, etc.) về tự kết nối db của mình
- **Swagger UI** - API documentation (truy cập tại `/`)

**API Endpoints:**
```
GET /api/health - Health check ( test )
```

---

### 🔧 SWD.Shared - Shared/Common Layer (Lớp dùng chung)
**Chức năng:** Chứa các class, enum, helper được sử dụng bởi tất cả các lớp

**Các thành phần:**
- `Constants/AppConstants.cs` - Hằng số ứng dụng
- `Enums/Status.cs` - Enum trạng thái (Active, Inactive, Deleted)
- `Helpers/DateTimeHelper.cs` - Các hàm tiện ích xử lý ngày tháng

---

## 🚀 Hướng dẫn sử dụng

### 📋 Yêu cầu hệ thống
- .NET SDK 9.0 trở lên
- Visual Studio 2022, VS Code, hoặc JetBrains Rider
- SQL Server (hoặc cơ sở dữ liệu khác được Entity Framework hỗ trợ)

### 🔧 Cài đặt và chạy

#### 1. Clone repository
```bash
git clone https://github.com/meimeimoimoi/SWD.git
cd SWD
```

#### 2. Restore packages
```bash
dotnet restore
```

#### 3. Build dự án
```bash
dotnet build
```

#### 4. Cấu hình Database
Chỉnh sửa connection string trong `SWD.Presentation/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your_server;Database=SWD;Trusted_Connection=true;"
  }
}
```

#### 5. Tạo Database (Migrations)
```bash
dotnet ef migrations add InitialCreate --project SWD.Data --startup-project SWD.Presentation
dotnet ef database update --project SWD.Data --startup-project SWD.Presentation
```

#### 6. Chạy ứng dụng
```bash
dotnet run --project SWD.Presentation
```

**Kết quả:** API sẽ chạy trên `http://localhost:5191`

#### 7. Truy cập Swagger UI
Mở trình duyệt và truy cập: **http://localhost:5191**

Swagger UI sẽ hiển thị tất cả các API endpoints và cho phép bạn test chúng trực tiếp.

---

## 🏛️ Kiến trúc 3-Lớp (3-Layer Architecture)

```
┌─────────────────────────────────────────┐
│   SWD.Presentation (Web API / UI)       │  ← Controllers, Swagger UI
├─────────────────────────────────────────┤
│   SWD.Business (Business Logic)         │  ← Services, DTOs, Validation
├─────────────────────────────────────────┤
│   SWD.Data (Data Access)                │  ← Repositories, Entities, DbContext
├─────────────────────────────────────────┤
│   SWD.Shared (Common / Utilities)       │  ← Constants, Enums, Helpers
└─────────────────────────────────────────┘
```

**Luồng dữ liệu:**
1. Client gửi request → **Presentation Layer** (Controller)
2. Controller gọi **Business Logic Layer** (Service)
3. Service xử lý logic → gọi **Data Access Layer** (Repository)
4. Repository truy cập **Database**
5. Kết quả trả về client qua Presentation Layer

---

## 📚 Các lệnh hữu ích

### Build
```bash
dotnet build
```

### Run
```bash
dotnet run --project SWD.Presentation
```

### Add Migration
```bash
dotnet ef migrations add MigrationName --project SWD.Data --startup-project SWD.Presentation
```

### Update Database
```bash
dotnet ef database update --project SWD.Data --startup-project SWD.Presentation
```

### Remove Migration
```bash
dotnet ef migrations remove --project SWD.Data --startup-project SWD.Presentation
```

### Test API
```bash
# Truy cập Swagger UI
http://localhost:5191

# Hoặc dùng curl
curl http://localhost:5191/api/health
```

---

## 📦 Dependencies
| Package | Version | Mục đích |
|---------|---------|---------|
| .NET | 9.0 | Framework |
| Entity Framework Core | 9.0.4 | ORM |
| EF Core SQL Server | 9.0.4 | SQL Server Provider |
| EF Core Tools | 9.0.4 | Migration Tools |
| Swashbuckle.AspNetCore | 7.2.0 | Swagger UI |

---

## 🔄 Quy trình phát triển

### Thêm Entity mới:
1. Tạo class trong `SWD.Data/Entities/` kế thừa từ `BaseEntity`
2. Thêm `DbSet<Entity>` vào `ApplicationDbContext`
3. Tạo migration: `dotnet ef migrations add AddEntity`
4. Update database: `dotnet ef database update`

### Thêm Service mới:
1. Tạo DTO trong `SWD.Business/DTOs/`
2. Tạo Service interface trong `SWD.Business/Interface/`
3. Tạo Service class trong `SWD.Business/Services/` kế thừa từ `BaseService`
4. Đăng ký service trong `Program.cs` (Dependency Injection)

### Thêm Controller mới:
1. Tạo Controller trong `SWD.Presentation/Controllers/` kế thừa từ `BaseController`
2. Inject Service vào constructor
3. Tạo các action methods (GET, POST, PUT, DELETE)
4. Swagger sẽ tự động generate documentation

---

## 🤝 Đóng góp
Khi làm việc với dự án:
1. Tạo branch mới từ `main`
2. Commit changes với message rõ ràng
3. Push và tạo Pull Request
4. Không Push main
   
Quan trọng: commit điên t đấm vỡ mồm
---

## 📞 Liên hệ
- Repository: https://github.com/meimeimoimoi/SWD

---

## 📝 Ghi chú
- Đảm bảo luôn có migration trước khi commit
- Sử dụng DTOs để truyền dữ liệu giữa các lớp
- Implement validation trong Business Logic Layer
- Sử dụng async/await cho các hoạt động I/O
- Kiểm tra thật kĩ những thứ trên

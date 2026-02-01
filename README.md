# SWD - Rice Disease Detection (3-Layer .NET)

## Mô tả
Web API kiến trúc 3 lớp, nhận diện bệnh trên cây lúa bằng ResNet18. .NET 9.0, Entity Framework Core.

## Cấu trúc dự án

| Layer | Chức năng chính |
|-------|-----------------|
| **SWD.Presentation** | Controllers, Swagger UI, API endpoints |
| **SWD.Business** | Services, DTOs, validation |
| **SWD.Data** | Repositories, Entities, DbContext |
| **SWD.Shared** | Constants, Enums, Helpers |

- **SWD.Data:** `ApplicationDbContext`, `BaseEntity`, `IRepository`/`Repository`, Migrations.
- **SWD.Business:** `BaseDTO`, `IService`/`BaseService`, DTOs, ML (ResNet18).
- **SWD.Presentation:** `BaseController`, `Program.cs`, `appsettings.json`, Swagger tại `/`.
- **SWD.Shared:** `AppConstants`, `Status`, `DateTimeHelper`.

## Yêu cầu và chạy

- .NET SDK 9.0+, SQL Server (hoặc DB hỗ trợ EF).
- Clone, vào thư mục, rồi:

```bash
dotnet restore
dotnet build
```

- Sửa connection string trong `BackEnd/SWD.Presentation/appsettings.json`.
- Tạo DB:

```bash
dotnet ef migrations add InitialCreate --project BackEnd/SWD.Data --startup-project BackEnd/SWD.Presentation
dotnet ef database update --project BackEnd/SWD.Data --startup-project BackEnd/SWD.Presentation
```

- Chạy API:

```bash
dotnet run --project BackEnd/SWD.Presentation
```

- API: `http://localhost:5191`, Swagger tại `/`.

## Lệnh thường dùng

| Lệnh | Mô tả |
|------|--------|
| `dotnet build` | Build |
| `dotnet run --project BackEnd/SWD.Presentation` | Chạy API |
| `dotnet ef migrations add <Name> --project BackEnd/SWD.Data --startup-project BackEnd/SWD.Presentation` | Thêm migration |
| `dotnet ef database update --project BackEnd/SWD.Data --startup-project BackEnd/SWD.Presentation` | Cập nhật DB |
| `dotnet ef migrations remove --project BackEnd/SWD.Data --startup-project BackEnd/SWD.Presentation` | Xóa migration cuối |

## Luồng dữ liệu

Client -> Controller (Presentation) -> Service (Business) -> Repository (Data) -> DB; kết quả trả ngược lên client.

## Dependencies chính

- .NET 9.0, Entity Framework Core 9.x, EF SQL Server, Swashbuckle (Swagger).

## Phát triển nhanh

- **Entity mới:** Class trong `SWD.Data/Entities` kế thừa `BaseEntity`, thêm `DbSet` trong DbContext, tạo migration rồi update DB.
- **Service mới:** DTO trong `SWD.Business/DTOs`, interface + class trong `Interface/` và `Services/`, đăng ký trong `Program.cs`.
- **Controller mới:** Kế thừa `BaseController`, inject service, thêm actions; Swagger tự cập nhật.

## Đóng góp

- Branch từ `main`, commit rõ ràng, tạo Pull Request. Không push trực tiếp lên `main`.

## Lưu ý sau khi clone

- Đã ignore `bin/`, `obj/`. Không commit chúng hay `*.user`, `*.suo`. Chỉ commit source (`.cs`, `.csproj`, `.json`).
- Nếu lỗi build: `dotnet clean`, `git pull origin main`, `dotnet restore`, `dotnet build`.
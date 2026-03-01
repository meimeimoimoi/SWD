# SWD - Rice Disease Detection System

## Mô tả
Dự án nhận diện bệnh trên cây lúa gồm:
- **BackEnd:** Web API kiến trúc nhiều lớp, nhận diện bệnh bằng MobileNetv3, phát triển với .NET 9.0, Entity Framework Core.
- **FrontEnd:** Ứng dụng Flutter.

## Cấu trúc dự án

```
SWD/
├── BackEnd/           # .NET Web API
│   ├── MyApp/         # Source code chính
│   │   ├── Api/       # Controllers
│   │   ├── Application/   # Business logic, Features, Interfaces
│   │   ├── Configuration/ # Cấu hình JWT, Swagger
│   │   ├── Domain/    # Entities (Models)
│   │   ├── Infrastructure/ # Services, Helpers
│   │   ├── Persistence/    # DbContext, Repositories
│   │   ├── uploads/    # Thư mục lưu ảnh
│   │   ├── appsettings.json # Cấu hình
│   │   └── Program.cs  # Entry point
│   └── SWDSystem.slnx  # Solution file
├── FrontEnd/           # Flutter app
│   ├── app/            # Source code Flutter
│   │   ├── lib/        # Code chính (main.dart, feature, providers...)
│   │   ├── android/    # Android
│   │   ├── ios/        # iOS
│   │   ├── web/        # Web
│   │   ├── windows/    # Windows
│   │   ├── macos/      # macOS
│   │   └── test/       # Unit test
```

## Hướng dẫn chạy dự án

### BackEnd (.NET API)
- Yêu cầu: .NET SDK 9.0+, SQL Server.
- Cài đặt:
  1. Vào thư mục `BackEnd/MyApp`.
  2. Sửa connection string trong `appsettings.json`.
  3. Restore và build:
	  ```bash
	  dotnet restore
	  dotnet build
	  ```
  4. Tạo database:
	  ```bash
	  dotnet ef migrations add InitialCreate
	  dotnet ef database update
	  ```
  5. Chạy API:
	  ```bash
	  dotnet run
	  ```
- API: `https://localhost:7244;http://localhost:5299`, Swagger tại `/swagger`.

### FrontEnd (Flutter App)
- Yêu cầu: Flutter SDK 3.x+
- Cài đặt:
  1. Vào thư mục `FrontEnd/app`.
  2. Cài dependencies:
	  ```bash
	  flutter pub get
	  ```
  3. Chạy app:
	  ```bash
	  flutter run
	  ```

## Lệnh BackEnd thường dùng

| Lệnh | Mô tả |
|------|--------|
| `dotnet build` | Build API |
| `dotnet run` | Chạy API |
| `dotnet ef migrations add <Name>` | Thêm migration |
| `dotnet ef database update` | Cập nhật DB |
| `dotnet ef migrations remove` | Xóa migration cuối |

## Luồng dữ liệu BackEnd

Client (Flutter/Web) → Controller (Api) → Service (Application) → Repository (Persistence) → DB
Kết quả trả ngược lên client.

## Dependencies chính

- **BackEnd:** .NET 9.0, Entity Framework Core 9.x, EF SQL Server, Swashbuckle (Swagger).
- **FrontEnd:** Flutter 3.x, provider, http, cupertino_icons, ...

## Phát triển nhanh

- **BackEnd:**
	- **Entity mới:** Class trong `Domain/Entities`, thêm `DbSet` vào `AppDbContext`, migration và update DB.
	- **Service mới:** Interface + class trong `Infrastructure/Services`, đăng ký DI.
	- **Controller mới:** Tạo controller trong `Api/Controllers`, inject service, thêm actions.
- **FrontEnd:**
	- Thêm màn hình mới: tạo file trong `lib/feature/`.
	- Thêm provider: tạo file trong `lib/providers/`.

## Đóng góp

- Branch từ `main`, commit rõ ràng, tạo Pull Request. Không push trực tiếp lên `main`.

## Lưu ý sau khi clone

- Đã ignore `bin/`, `obj/`, build outputs. Chỉ commit source (`.cs`, `.csproj`, `.json`, `.dart`).
- Nếu lỗi build .NET: `dotnet clean`, `git pull origin main`, `dotnet restore`, `dotnet build`.
- Nếu lỗi Flutter: `flutter clean`, `flutter pub get`, kiểm tra SDK.

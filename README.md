# SWD - 3-Layer Architecture .NET Application

## Cấu trúc dự án

### SWD.Data - Data Access Layer
- **DbContext**: ApplicationDbContext để quản lý database
- **Entities**: Các entity models (BaseEntity)
- **Repositories**: Repository pattern (IRepository, Repository)
- **Migrations**: Database migrations folder

### SWD.Business - Business Logic Layer
- **DTOs**: Data Transfer Objects (BaseDTO)
- **Interface**: Service interfaces (IService)
- **Services**: Business logic implementation (BaseService)

### SWD.Presentation - Presentation Layer (Web API)
- **Controllers**: API Controllers (BaseController)
- **Models**: View models
- **Program.cs**: Application entry point
- **appsettings.json**: Configuration files

### SWD.Shared - Shared/Common Layer
- **Constants**: Application constants
- **Enums**: Common enumerations (Status)
- **Helpers**: Utility classes (DateTimeHelper)

## Cách sử dụng

### Build dự án
```bash
dotnet build
```

### Run API
```bash
dotnet run --project SWD.Presentation
```

### Database Migration
```bash
dotnet ef migrations add InitialCreate --project SWD.Data --startup-project SWD.Presentation
dotnet ef database update --project SWD.Data --startup-project SWD.Presentation
```

## Dependencies
- Entity Framework Core 10.0.2
- Entity Framework Core SQL Server
- Entity Framework Core Tools
- ASP.NET Core Web API
Nhận diện bênh trên cây lúa sử dụng model ResNet18

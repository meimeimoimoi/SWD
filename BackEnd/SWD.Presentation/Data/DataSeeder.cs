using Microsoft.EntityFrameworkCore;
using SWD.Data.Data;
using SWD.Data.Entities;

namespace SWD.Presentation.Data
{
    // Dùng static class vì chúng ta không cần tạo instance của nó
    public static class DataSeeder
    {
        // Phương thức chính để thực hiện việc seed dữ liệu
        public static async Task SeedAsync(WebApplication app)
        {
            // Sử dụng IServiceScopeFactory để lấy các dependency injection services (như DbContext)
            // Đây là cách làm chuẩn khi cần truy cập service trong Program.cs
            using var scope = app.Services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<Swd392Context>();
            var configuration = scope.ServiceProvider.GetRequiredService<IConfiguration>();

            // (Tùy chọn nhưng khuyến khích) Tự động áp dụng các migration đang chờ
            await context.Database.MigrateAsync();

            // --- BƯỚC 1: TẠO CÁC VAI TRÒ (ROLES) ---
            // Chỉ tạo nếu bảng Roles chưa có dữ liệu
            if (!await context.Roles.AnyAsync())
            {
                var roles = new List<Role>
            {
                new() { Name = "Admin", NormalizedName = "ADMIN" },
                new() { Name = "Technician", NormalizedName = "TECHNICIAN" },
                new() { Name = "User", NormalizedName = "USER" }
            };
                await context.Roles.AddRangeAsync(roles);
                await context.SaveChangesAsync();
            }

            // --- BƯỚC 2: TẠO TÀI KHOẢN SUPER ADMIN ---
            // Lấy thông tin từ file secrets.json
            var adminEmail = configuration["SuperAdminSettings:Email"];
            var adminPassword = configuration["SuperAdminSettings:Password"];

            // Chỉ tạo nếu email và password được cấu hình và user chưa tồn tại
            if (!string.IsNullOrEmpty(adminEmail) &&
                !string.IsNullOrEmpty(adminPassword) &&
                !await context.Users.AnyAsync(u => u.Email == adminEmail))
            {
                // Tìm Role "Admin" vừa tạo ở trên
                var adminRole = await context.Roles.SingleAsync(r => r.Name == "Admin");

                // Tạo đối tượng User mới
                var adminUser = new User
                {
                    Id = Guid.NewGuid(),
                    Email = adminEmail,
                    NormalizedEmail = adminEmail.ToUpper(),
                    UserName = adminEmail,
                    NormalizedUserName = adminEmail.ToUpper(),
                    FirstName = "Super",
                    LastName = "Admin",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword),
                    EmailConfirmed = true,
                    IsActive = true
                };

                // Thêm user vào DB
                context.Users.Add(adminUser);

                // Gán vai trò "Admin" cho user đó
                context.UserRoles.Add(new UserRole { UserId = adminUser.Id, RoleId = adminRole.Id });

                // Lưu tất cả thay đổi vào DB
                await context.SaveChangesAsync();
            }
        }

    }
}

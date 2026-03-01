using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Data
{
    public class DataSeeder
    {
        private readonly AppDbContext _context;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IConfiguration _configuration;
        private readonly ILogger<DataSeeder> _logger;

        public DataSeeder(
            AppDbContext context, 
            IPasswordHasher passwordHasher,
            IConfiguration configuration,
            ILogger<DataSeeder> logger)
        {
            _context = context;
            _passwordHasher = passwordHasher;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SeedAsync()
        {
            try
            {
                // Ensure database is created
                await _context.Database.EnsureCreatedAsync();

                // Seed Admin User
                await SeedAdminUserAsync();
                // Seed Default Model
                await SeedDefaultModelAsync();

                _logger.LogInformation("Data seeding completed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while seeding the database");
                throw;
            }
        }

        private async Task SeedAdminUserAsync()
        {
            // Check if any admin user exists
            var adminExists = await _context.Users.AnyAsync(u => u.Role == "Admin");

            if (adminExists)
            {
                _logger.LogInformation("Admin user already exists. Skipping admin seeding.");
                return;
            }

            // Get admin credentials from configuration
            var adminEmail = _configuration["SuperAdminSettings:Email"] ?? "admin@swd.com";
            var adminPassword = _configuration["SuperAdminSettings:Password"] ?? "Admin123!";

            // Create admin user
            var adminUser = new User
            {
                Username = "admin",
                Email = adminEmail,
                PasswordHash = _passwordHasher.Hash(adminPassword),
                FirstName = "System",
                LastName = "Administrator",
                Role = "Admin",
                AccountStatus = "Active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(adminUser);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin user created: {Username} ({Email})", adminUser.Username, adminUser.Email);
        }

        private async Task SeedDefaultModelAsync()
        {
            const string modelName = "Rice Disease MobileNetV3";
            const string version   = "v1.0";
            const string fileName  = "rice_disease_v3.onnx";
            const string filePath  = "Models/rice_disease_v3.onnx";

            // Skip if already registered
            var alreadyExists = await _context.ModelVersions
                .AnyAsync(m => m.ModelName == modelName && m.Version == version);

            if (alreadyExists)
            {
                _logger.LogInformation(
                    "Default model '{Name}' v{Version} already registered. Skipping.",
                    modelName, version);
                return;
            }

            // Verify physical file exists in the Models/ folder
            var physicalPath = Path.Combine(AppContext.BaseDirectory, "Models", fileName);
            if (!File.Exists(physicalPath))
            {
                _logger.LogWarning(
                    "Model file not found at {Path}. Skipping model seed. " +
                    "Place '{File}' inside the Models/ folder and restart.",
                    physicalPath, fileName);
                return;
            }

            // Deactivate any previously active/default model
            var currentActives = await _context.ModelVersions
                .Where(m => m.IsActive == true || m.IsDefault == true)
                .ToListAsync();

            foreach (var m in currentActives)
            {
                m.IsActive  = false;
                m.IsDefault = false;
            }

            // Register and activate the default model
            var model = new ModelVersion
            {
                ModelName   = modelName,
                Version     = version,
                ModelType   = "mobilenetv3",
                Description = "Base model — detects 3 rice diseases and healthy leaf.",
                IsActive    = true,
                IsDefault   = true,
                CreatedAt   = DateTime.UtcNow
            };

            _context.ModelVersions.Add(model);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "Default model seeded — Id={Id}, Name='{Name}', v{Version}, FilePath={Path}",
                model.ModelVersionId, model.ModelName, model.Version, filePath);
        }
    }
}

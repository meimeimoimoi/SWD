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

        /// <summary>
        /// Applies pending EF Core migrations. Call before <see cref="SeedAsync"/>; must succeed for a consistent schema.
        /// </summary>
        public async Task MigrateDatabaseAsync(CancellationToken cancellationToken = default)
        {
            if (!await _context.Database.CanConnectAsync(cancellationToken))
            {
                throw new InvalidOperationException(
                    "Cannot connect to the database. Check ConnectionStrings:DefaultConnection and that SQL Server is reachable.");
            }

            var pending = await _context.Database.GetPendingMigrationsAsync(cancellationToken);
            var list = pending.ToList();
            if (list.Count > 0)
            {
                _logger.LogInformation("Applying {Count} pending migration(s): {Migrations}", list.Count, string.Join(", ", list));
            }

            await _context.Database.MigrateAsync(cancellationToken);

            if (list.Count > 0)
            {
                _logger.LogInformation("Database migrations applied successfully");
            }
        }

        /// <summary>
        /// Idempotent data seed (admin user, default model). Requires schema to be current — run <see cref="MigrateDatabaseAsync"/> first.
        /// </summary>
        public async Task SeedAsync(CancellationToken cancellationToken = default)
        {
            await SeedAdminUserAsync(cancellationToken);
            await SeedDefaultModelAsync(cancellationToken);
            _logger.LogInformation("Data seeding completed successfully");
        }

        private async Task SeedAdminUserAsync(CancellationToken cancellationToken = default)
        {
            // Check if any admin user exists
            var adminExists = await _context.Users.AnyAsync(u => u.Role == "Admin", cancellationToken);

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
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Admin user created: {Username} ({Email})", adminUser.Username, adminUser.Email);
        }

        private async Task SeedDefaultModelAsync(CancellationToken cancellationToken = default)
        {
            const string modelName = "Rice Disease MobileNetV3";
            const string version   = "v1.0";
            const string fileName  = "rice_disease_v3.onnx";
            var          filePath  = Path.Combine("Models", fileName);

            // Skip if already registered
            var alreadyExists = await _context.ModelVersions
                .AnyAsync(m => m.ModelName == modelName && m.Version == version, cancellationToken);

            if (alreadyExists)
            {
                _logger.LogInformation(
                    "Default model '{Name}' v{Version} already registered. Skipping.",
                    modelName, version);
                return;
            }

            // Verify physical file exists
            var physicalPath = Path.Combine(AppContext.BaseDirectory, "Models", fileName);
            if (!File.Exists(physicalPath))
            {
                _logger.LogWarning(
                    "Model file not found at '{Path}'. Place '{File}' inside the Models/ folder and restart.",
                    physicalPath, fileName);
                return;
            }

            // Deactivate any previously active/default model
            var currentActives = await _context.ModelVersions
                .Where(m => m.IsActive == true || m.IsDefault == true)
                .ToListAsync(cancellationToken);
            foreach (var m in currentActives)
            {
                m.IsActive  = false;
                m.IsDefault = false;
            }

            // Register with FilePath stored in DB
            var model = new ModelVersion
            {
                ModelName   = modelName,
                Version     = version,
                ModelType   = "mobilenetv3",
                Description = "Base model — detects 3 rice diseases and healthy leaf.",
                FilePath    = filePath,
                IsActive    = true,
                IsDefault   = true,
                CreatedAt   = DateTime.UtcNow
            };

            _context.ModelVersions.Add(model);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Default model seeded — Id={Id}, Name='{Name}', v{Version}, FilePath='{Path}'",
                model.ModelVersionId, model.ModelName, model.Version, filePath);
        }
    }
}

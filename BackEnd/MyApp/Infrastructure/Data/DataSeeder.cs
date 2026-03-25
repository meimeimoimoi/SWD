using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.ML.OnnxRuntime;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Domain.Enums;
using MyApp.Infrastructure.Ml;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Data
{
    public class DataSeeder
    {
        private readonly AppDbContext _context;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IConfiguration _configuration;
        private readonly EfMigrationHistoryChecksumService _migrationChecksums;
        private readonly ILogger<DataSeeder> _logger;

        public DataSeeder(
            AppDbContext context,
            IPasswordHasher passwordHasher,
            IConfiguration configuration,
            EfMigrationHistoryChecksumService migrationChecksums,
            ILogger<DataSeeder> logger)
        {
            _context = context;
            _passwordHasher = passwordHasher;
            _configuration = configuration;
            _migrationChecksums = migrationChecksums;
            _logger = logger;
        }

        public async Task MigrateDatabaseAsync(CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(_configuration.GetConnectionString("DefaultConnection")))
            {
                throw new InvalidOperationException(
                    "ConnectionStrings:DefaultConnection is missing or empty. Set it in appsettings.json, user secrets, or environment variables.");
            }

            var pending = await _context.Database.GetPendingMigrationsAsync(cancellationToken);
            var list = pending.ToList();
            if (list.Count > 0)
            {
                _logger.LogInformation("Applying {Count} pending migration(s): {Migrations}", list.Count, string.Join(", ", list));
            }

            var migrationsApplied = false;
            try
            {
                await _context.Database.MigrateAsync(cancellationToken);
                migrationsApplied = true;
            }
            catch (InvalidOperationException ex) when (ex.Message?.Contains("PendingModelChangesWarning") == true || ex.Message?.Contains("pending changes", StringComparison.OrdinalIgnoreCase) == true)
            {
                // This can happen when the EF model has changed but no migration was created.
                // We intentionally skip applying migrations in this case to avoid altering the database schema
                // because the workspace requested no DB schema changes. Log and continue.
                _logger.LogWarning(ex, "Skipping database migration because the EF model has pending changes. Create a migration to apply schema changes if desired.");
            }

            if (migrationsApplied)
            {
                await _migrationChecksums.ValidateSealAndVerifyAsync(cancellationToken);

                if (list.Count > 0)
                {
                    _logger.LogInformation("Database migrations applied successfully");
                }
            }
            else
            {
                _logger.LogInformation("Database migration skipped. Continuing without applying schema changes.");
            }
        }

        public async Task SeedAsync(CancellationToken cancellationToken = default)
        {
            await SeedAdminUserAsync(cancellationToken);
            await SeedDefaultModelAsync(cancellationToken);
            await SeedTreeIllnessNamesFromOnnxAsync(cancellationToken);
            _logger.LogInformation("Data seeding completed successfully");
        }

        private async Task SeedAdminUserAsync(CancellationToken cancellationToken = default)
        {
            var adminExists = await _context.Users.AnyAsync(u => u.Role == UserRole.Admin, cancellationToken);

            if (adminExists)
            {
                _logger.LogInformation("Admin user already exists. Skipping admin seeding.");
                return;
            }

            var adminEmail = _configuration["SuperAdminSettings:Email"] ?? "admin@swd.com";
            var adminPassword = _configuration["SuperAdminSettings:Password"] ?? "Admin123!";

            var adminUser = new User
            {
                Username = "admin",
                Email = adminEmail,
                PasswordHash = _passwordHasher.Hash(adminPassword),
                FirstName = "System",
                LastName = "Administrator",
                Role = UserRole.Admin,
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

            var alreadyExists = await _context.ModelVersions
                .AnyAsync(m => m.ModelName == modelName && m.Version == version, cancellationToken);

            if (alreadyExists)
            {
                _logger.LogInformation(
                    "Default model '{Name}' v{Version} already registered. Skipping.",
                    modelName, version);
                return;
            }

            var physicalPath = Path.Combine(AppContext.BaseDirectory, "Models", fileName);
            if (!File.Exists(physicalPath))
            {
                _logger.LogWarning(
                    "Model file not found at '{Path}'. Place '{File}' inside the Models/ folder and restart.",
                    physicalPath, fileName);
                return;
            }

            var currentActives = await _context.ModelVersions
                .Where(m => m.IsActive == true || m.IsDefault == true)
                .ToListAsync(cancellationToken);
            foreach (var m in currentActives)
            {
                m.IsActive  = false;
                m.IsDefault = false;
            }

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

        private async Task SeedTreeIllnessNamesFromOnnxAsync(CancellationToken cancellationToken)
        {
            var mv = await _context.ModelVersions
                .FirstOrDefaultAsync(m => m.IsDefault == true && m.IsActive == true, cancellationToken);
            if (mv?.FilePath is not { } rel)
                return;

            var full = Path.Combine(AppContext.BaseDirectory, rel.Replace('/', Path.DirectorySeparatorChar));
            if (!File.Exists(full))
                return;

            try
            {
                using var session = new InferenceSession(full);
                var now = DateTime.UtcNow;
                foreach (var name in OnnxModelLabels.Read(session, full))
                {
                    if (await _context.TreeIllnesses.AnyAsync(t => t.IllnessName == name, cancellationToken))
                        continue;
                    _context.TreeIllnesses.Add(new TreeIllness
                    {
                        IllnessName = name,
                        CreatedAt = now,
                        UpdatedAt = now
                    });
                }

                await _context.SaveChangesAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not seed tree_illnesses from ONNX (needs metadata class_labels).");
            }
        }
    }
}

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
                Phone = null,
                ProfileImagePath = null,
                Role = "Admin",
                AccountStatus = "Active",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _context.Users.Add(adminUser);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Admin user created successfully");
            _logger.LogInformation("Admin Username: {Username}", adminUser.Username);
            _logger.LogInformation("Admin Email: {Email}", adminUser.Email);
            _logger.LogWarning("⚠️ IMPORTANT: Default admin password is from configuration. Please change it after first login!");
        }
    }
}

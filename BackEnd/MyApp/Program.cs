using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.FileProviders;
using Microsoft.OpenApi.Models;
using MyApp.Api;
using MyApp.Application.Interfaces;
using MyApp.Configuration;
using MyApp.Infrastructure;
using MyApp.Infrastructure.Data;
using MyApp.Persistence;
using MyApp.Persistence.Context;

namespace MyApp
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            builder.Services.AddControllers();
            builder.Services.AddSwaggerDocumentation();
            builder.Services.AddApplicationSerivce();
            builder.Services.AddInfrastructureService();
            builder.Services.AddPersitenceService();
            
// Cấu hình JSON để không escape ký tự Unicode (để hiển thị tiếng Việt đúng)
            builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Encoder = 
        System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping;
    });

            // Add DbContext
            builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            builder.Services.AddHealthChecks()
                .AddCheck("self", () => HealthCheckResult.Healthy(), tags: new[] { "live" })
                .AddDbContextCheck<AppDbContext>(
                    name: "database",
                    failureStatus: HealthStatus.Unhealthy,
                    tags: new[] { "ready", "db" });

            // Add JWT Authentication
            builder.Services.AddJwtAuthentication(builder.Configuration);


            var app = builder.Build();

            // Migrations + seed: fail fast so the host never serves traffic against a missing or stale schema.
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                var logger = services.GetRequiredService<ILogger<Program>>();
                var seeder = services.GetRequiredService<DataSeeder>();
                try
                {
                    await seeder.MigrateDatabaseAsync();
                    await seeder.SeedAsync();
                }
                catch (Exception ex)
                {
                    logger.LogCritical(ex, "Database migration or seeding failed; the application will not start.");
                    throw;
                }
            }

            app.UseSwaggerDocumentation();

            var uploadsImagesPath = Path.Combine(app.Environment.ContentRootPath, "uploads", "images");
            Directory.CreateDirectory(uploadsImagesPath);
            app.UseStaticFiles(new StaticFileOptions
            {
                FileProvider = new PhysicalFileProvider(uploadsImagesPath),
                RequestPath = "/uploads/images"
            });

            // Important: Authentication must come before Authorization
            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.MapHealthChecks("/health");
            app.MapHealthChecks("/health/live", new HealthCheckOptions
            {
                Predicate = r => r.Tags.Contains("live")
            });
            app.MapHealthChecks("/health/ready", new HealthCheckOptions
            {
                Predicate = r => r.Tags.Contains("ready")
            });

            app.Run();
        }
    }
}

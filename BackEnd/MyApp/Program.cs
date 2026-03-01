using Microsoft.EntityFrameworkCore;
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

            // Add DbContext
            builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

            // Add JWT Authentication
            builder.Services.AddJwtAuthentication(builder.Configuration);


            var app = builder.Build();

            // Seed database
            using (var scope = app.Services.CreateScope())
            {
                var services = scope.ServiceProvider;
                try
                {
                    var seeder = services.GetRequiredService<DataSeeder>();
                    await seeder.SeedAsync();
                }
                catch (Exception ex)
                {
                    var logger = services.GetRequiredService<ILogger<Program>>();
                    logger.LogError(ex, "An error occurred while seeding the database");
                }
            }

            app.UseSwaggerDocumentation();

            // Important: Authentication must come before Authorization
            app.UseAuthentication();
            app.UseAuthorization();

            app.MapControllers();

            app.Run();
        }
    }
}

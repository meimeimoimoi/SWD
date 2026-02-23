using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Data;
using MyApp.Infrastructure.Helpers;
using MyApp.Infrastructure.Services;
using MyApp.Persistence.Repositories;

namespace MyApp.Api
{
    public static class DependecyInjection
    {
        public static IServiceCollection AddApplicationSerivce(this IServiceCollection service)
        {
            // Services
            service.AddScoped<IAuthService, AuthService>();
            service.AddScoped<IAdminService, AdminService>();
            service.AddScoped<IMessageService, MessageService>();
            service.AddScoped<IImageUploadService, ImageUploadService>();
            
            // Repositories
            service.AddScoped<UserRepository>();
            service.AddScoped<ImageUploadRepository>();
            
            // Utilities
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            
            // Data Seeder
            service.AddScoped<DataSeeder>();

            service.AddTransient<ApiResponse>();
            return service;
        }
    }
}

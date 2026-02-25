using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Data;
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
            service.AddScoped<IPredictionService, PredictionService>();
            service.AddScoped<ITreatmentSolutionService, TreatmentSolutionService>();

            // Repositories
            service.AddScoped<UserRepository>();
            service.AddScoped<ImageUploadRepository>();
            service.AddScoped<PredictionRepository>();
            service.AddScoped<TreatmentSolutionRepository>();
            // Utilities
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            
            // Data Seeder
            service.AddScoped<DataSeeder>();

            return service;
        }
    }
}

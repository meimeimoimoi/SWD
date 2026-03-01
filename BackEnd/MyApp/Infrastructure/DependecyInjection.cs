using Microsoft.AspNetCore.Identity;
using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Data;
using MyApp.Infrastructure.Helpers;
using MyApp.Infrastructure.Services;

namespace MyApp.Infrastructure
{
    public static class DependecyInjection
    {
        public static IServiceCollection AddInfrastructureService(this IServiceCollection services)
        {
            services.AddScoped<IAdminService, AdminService>();
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            services.AddScoped<IImageUploadService, ImageUploadService>();
            services.AddScoped<JwtTokenGeneratior>();
            services.AddScoped<IMessageService, MessageService>();
            services.AddScoped<IPredictionService, PredictionService>();
            services.AddScoped<ApiResponse>();

            // New services
            services.AddScoped<ITreatmentService, TreatmentService>();
            services.AddScoped<IModelService, ModelService>();
            services.AddScoped<IPredictionHistoryService, PredictionHistoryService>();
            services.AddScoped<DataSeeder>();
            return services;
        }
    }
}

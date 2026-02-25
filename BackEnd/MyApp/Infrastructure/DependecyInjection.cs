using Microsoft.AspNetCore.Identity;
using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Services;

namespace MyApp.Infrastructure
{
    public class DependecyInjection
    {
        public static void RegisterServices(IServiceCollection services)
        {
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            services.AddScoped<IMessageService, MessageService>();
            services.AddScoped<IAdminService, AdminService>();
            services.AddScoped<IImageUploadService, ImageUploadService>();
            services.AddScoped<IPredictionService, PredictionService>();
            services.AddScoped<ITreatmentSolutionService, TreatmentSolutionService>();
            // Register infrastructure services here
        }
    }
}

using Microsoft.AspNetCore.Identity;
using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Helpers;
using MyApp.Infrastructure.Services;

namespace MyApp.Infrastructure
{
    public static class DependecyInjection
    {
        public static void RegisterServices(IServiceCollection services)
        {
            services.AddTransient<ApiResponse>();
            services.AddScoped<IAuthService, AuthService>();
            services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            services.AddScoped<IMessageService, MessageService>();
            services.AddScoped<IAdminService, AdminService>();
            services.AddScoped<IImageUploadService, ImageUploadService>();
            services.AddScoped<IUserService, UserService>();
            services.AddScoped<JwtTokenGeneratior>();
            services.AddScoped<IPredictionService, PredictionService>();

        }
    }
}

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

            service.AddScoped<IAuthService, AuthService>();
            service.AddScoped<IAdminService, AdminService>();
            service.AddScoped<IMessageService, MessageService>();
            service.AddScoped<IImageUploadService, ImageUploadService>();
            service.AddScoped<IUserService, UserService>();
            service.AddScoped<IRatingService, RatingService>();

            service.AddScoped<UserRepository>();
            service.AddScoped<ImageUploadRepository>();
            service.AddScoped<RatingRepository>();
            
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            
            service.AddScoped<DataSeeder>();

            service.AddTransient<ApiResponse>();
            service.AddScoped<IPredictionService, PredictionService>();
            return service;
        }
    }
}

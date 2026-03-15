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
            service.AddScoped<IPredictionService, PredictionService>();
            service.AddScoped<ITreatmentSolutionService, TreatmentSolutionService>();
            service.AddScoped<ITreeIllnessService, TreeIllnessService>();
            service.AddScoped<ITreeStageService, TreeStageService>();
            service.AddScoped<IRatingService, RatingService>();

            service.AddScoped<IUserService, UserService>();
            
            // Repositories
            service.AddScoped<UserRepository>();
            service.AddScoped<ImageUploadRepository>();
            service.AddScoped<PredictionRepository>();
            service.AddScoped<TreatmentSolutionRepository>();
            service.AddScoped<TreeIllnessRepository>();
            service.AddScoped<TreeStageRepository>();
            service.AddScoped<RatingRepository>();

            // Utilities
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
            
            // Data Seeder
            service.AddScoped<DataSeeder>();

            service.AddTransient<ApiResponse>();
            service.AddScoped<IPredictionService, PredictionService>();
            return service;
        }
    }
}

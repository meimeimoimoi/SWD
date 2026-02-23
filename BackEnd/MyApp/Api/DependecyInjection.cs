using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Services;
using MyApp.Persistence.Repositories;

namespace MyApp.Api
{
    public static class DependecyInjection
    {
        public static IServiceCollection AddApplicationSerivce(this IServiceCollection service)
        {
            // HttpClient for AI Model
            service.AddHttpClient<AIModelService>();
            
            // Authentication & Authorization
            service.AddScoped<IAuthService, AuthService>();
            service.AddScoped<IAdminService, AdminService>();
            service.AddScoped<IMessageService, MessageService>();
            
            // Model Management & AI
            service.AddScoped<IModelService, ModelService>();
            service.AddScoped<AIModelService>();
            service.AddScoped<IPredictionService, PredictionService>();
            
            // Tree & Illness Services
            service.AddScoped<ITreeService, TreeService>();
            service.AddScoped<IIllnessService, IllnessService>();
            service.AddScoped<ITreeIllnessService, TreeIllnessService>();
            service.AddScoped<ISolutionService, SolutionService>();
            
            // Repositories
            service.AddScoped<UserRepository>();
            service.AddScoped<ModelRepository>();
            service.AddScoped<ImageRepository>();
            service.AddScoped<TreeDataRepository>();
            service.AddScoped<SolutionRepository>();
            
            // Utilities
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();

            return service;
        }
    }
}

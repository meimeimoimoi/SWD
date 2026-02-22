using MyApp.Application.Interfaces;
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
            service.AddScoped<IModelService, ModelService>();
            service.AddScoped<IAIService, AIService>();
            service.AddScoped<IPredictionService, PredictionService>();
            
            service.AddScoped<UserRepository>();
            service.AddScoped<ModelRepository>();
            service.AddScoped<ImageRepository>();
            
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();

            // NEW: Tree & Illness management services
            service.AddScoped<ITreeService, TreeService>();
            service.AddScoped<IIllnessService, IllnessService>();
            service.AddScoped<ITreeIllnessService, TreeIllnessService>();
            service.AddScoped<ISolutionService, SolutionService>();
            
            // NEW: Tree data repositories
            service.AddScoped<TreeDataRepository>();
            service.AddScoped<SolutionRepository>();

            return service;
        }
    }
}

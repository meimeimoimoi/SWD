using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Data;
using MyApp.Infrastructure.Helpers;
using MyApp.Infrastructure.Services;
using MyApp.Persistence.Repositories;

namespace MyApp.Persistence
{
    public static class DependecyInjection
    {
        public static IServiceCollection AddPersitenceService(this IServiceCollection service)
        {
            service.AddScoped<UserRepository>();
            service.AddScoped<ImageUploadRepository>();
            service.AddScoped<IllnessRepository>();
            service.AddScoped<PredictionRepository>();
            service.AddScoped<ModelRepository>();

            return service;
        }
    }
}

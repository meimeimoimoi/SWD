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
            service.AddScoped<UserRepository>();
            service.AddScoped<JwtTokenGeneratior>();
            service.AddScoped<IPasswordHasher, BCryptPasswordHasher>();

            return service;
        }
    }
}

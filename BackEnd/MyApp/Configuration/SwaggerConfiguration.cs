using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi.Models;

namespace MyApp.Configuration
{
    public static class SwaggerConfiguration
    {
        public static IServiceCollection AddSwaggerDocumentation(this IServiceCollection services)
        {
            services.AddEndpointsApiExplorer(); services.AddSwaggerGen(c => {
                c.SwaggerDoc("v1", new OpenApiInfo { Title = "MyApp API", Version = "v1" });
                // Cấu hình JWT
                c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme 
                { 
                    Description = "JWT Authorization header using the Bearer scheme. Example: \"Bearer {token}\"",
                    Name = "Authorization", 
                    In = ParameterLocation.Header,
                    Type = SecuritySchemeType.ApiKey, Scheme = "Bearer" 
                }); 
                c.AddSecurityRequirement(new OpenApiSecurityRequirement 
                { 
                    { 
                        new OpenApiSecurityScheme 
                        { 
                            Reference = new OpenApiReference 
                            { 
                                Type = ReferenceType.SecurityScheme, 
                                Id = "Bearer" 
                            } 
                        },
                        Array.Empty<string>() 
                    } 
                }); 
            });
            return services; 
        } 
        public static IApplicationBuilder UseSwaggerDocumentation(this IApplicationBuilder app) 
        { 
            app.UseSwagger(); 
            app.UseSwaggerUI(c => { c.SwaggerEndpoint("/swagger/v1/swagger.json", "MyApp API v1"); 
                c.RoutePrefix = string.Empty;
                // Swagger ở root URL
            }); 
            return app; 
        }
    }
}

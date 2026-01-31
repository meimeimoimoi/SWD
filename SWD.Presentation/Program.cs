using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SWD.Business.Interface;
using SWD.Business.Services;
using SWD.Data.Data;
using SWD.Data.Repositories;
using SWD.Presentation.Data;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Get model path from configuration
var modelPath = builder.Configuration["MLModel:ModelPath"] ?? "ML/Models/resnet18_rice_disease.zip";
var fullModelPath = Path.Combine(AppContext.BaseDirectory, modelPath);

// Register Disease Detection Service
builder.Services.AddSingleton<IDiseaseDetectionService>(sp => 
    new DiseaseDetectionService(fullModelPath));

// --- 4. Đăng ký DbContext ---
builder.Services.AddDbContext<Swd392Context>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// --- 5. Đăng ký các lớp nghiệp vụ (Dependency Injection) ---
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IMessageService, MessageService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddHttpClient();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// --- 3. Cấu hình Swagger để hỗ trợ JWT Bearer Token ---
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo()
    {
        Title = "SWD API - Rice Disease Detection",
        Version = "v1",
        Description = "Rice Disease Detection API using ResNet18 model for identifying diseases in rice plants",
        Contact = new OpenApiContact
        {
            Name = "SWD Team"
        }
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header,
            },
            new List<string>()
        }
    });
});

// --- 6. Cấu hình xác thực JWT ---
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!))
        };

        // ✅ Check IsActive when token is validated
        options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var userIdClaim = context.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)
                    ?? context.Principal?.FindFirst("sub");

                if (userIdClaim != null && Guid.TryParse(userIdClaim.Value, out var userId))
                {
                    using var scope = context.HttpContext.RequestServices.CreateScope();
                    var userRepository = scope.ServiceProvider.GetRequiredService<IUserRepository>();
                    var user = await userRepository.FindByIdAsync(userId);

                    if (user == null || !user.IsActive)
                    {
                        context.Fail("Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.");
                    }
                }
            }
        };
    });

builder.Services.AddAuthorization();

var app = builder.Build();
// Gọi Data Seeder để khởi tạo dữ liệu ban đầu
await DataSeeder.SeedAsync(app);

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "SWD API V1");
        c.RoutePrefix = string.Empty; // Set Swagger UI at root
    });
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();

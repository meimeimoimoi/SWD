using SWD.Business.Interface;
using SWD.Business.Services;

var builder = WebApplication.CreateBuilder(args);

// Get model path from configuration
var modelPath = builder.Configuration["MLModel:ModelPath"] ?? "ML/Models/resnet18_rice_disease.zip";
var fullModelPath = Path.Combine(AppContext.BaseDirectory, modelPath);

// Register Disease Detection Service
builder.Services.AddSingleton<IDiseaseDetectionService>(sp => 
    new DiseaseDetectionService(fullModelPath));

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new()
    {
        Title = "SWD API - Rice Disease Detection",
        Version = "v1",
        Description = "Rice Disease Detection API using ResNet18 model for identifying diseases in rice plants"
    });
});

var app = builder.Build();

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
app.UseAuthorization();
app.MapControllers();

app.Run();

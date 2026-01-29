using SWD.Business.Interface;
using SWD.Business.Services;
using Microsoft.OpenApi.Models;
using System.Reflection;
using Swashbuckle.AspNetCore.SwaggerGen;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

// Get model path from configuration
var modelPath = builder.Configuration["MLModel:ModelPath"] ?? "ML/Models/resnet18_rice_disease.zip";
var fullModelPath = Path.Combine(AppContext.BaseDirectory, modelPath);

// Register Disease Detection Service with error handling
builder.Services.AddSingleton<IDiseaseDetectionService>(sp => 
{
    try
    {
        return new DiseaseDetectionService(fullModelPath);
    }
    catch (Exception ex)
    {
        // Log error but don't crash the application
        Console.WriteLine($"⚠️ Warning: Failed to initialize Disease Detection Service: {ex.Message}");
        Console.WriteLine($"   Model path: {fullModelPath}");
        Console.WriteLine($"   API will start but predictions will not be available until model is loaded.");
        return new DiseaseDetectionService(fullModelPath);
    }
});

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SWD API - Rice Disease Detection",
        Version = "v1",
        Description = "Rice Disease Detection API using ResNet18 model for identifying diseases in rice plants",
        Contact = new OpenApiContact
        {
            Name = "SWD Team"
        }
    });

    // Add operation filter to handle file uploads
    c.OperationFilter<FileUploadOperationFilter>();

    // Enable XML comments if available
    try
    {
        var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
        {
            c.IncludeXmlComments(xmlPath, includeControllerXmlComments: true);
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"⚠️ Warning: Could not load XML documentation: {ex.Message}");
    }
});

var app = builder.Build();

// Configure the HTTP request pipeline.
// Enable Swagger in all environments for testing
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SWD API V1");
    c.RoutePrefix = string.Empty; // Set Swagger UI at root
    c.DocumentTitle = "SWD API - Rice Disease Detection";
});

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

Console.WriteLine("✅ Application started successfully");
Console.WriteLine($"📍 Swagger UI: https://localhost:<port>/");
Console.WriteLine($"📍 Health Check: https://localhost:<port>/api/health");

app.Run();

// Operation filter to handle file uploads in Swagger
public class FileUploadOperationFilter : IOperationFilter
{
    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var fileParams = context.MethodInfo.GetParameters()
            .Where(p => p.ParameterType == typeof(IFormFile))
            .ToList();

        if (!fileParams.Any())
            return;

        operation.RequestBody = new OpenApiRequestBody
        {
            Content = new Dictionary<string, OpenApiMediaType>
            {
                ["multipart/form-data"] = new OpenApiMediaType
                {
                    Schema = new OpenApiSchema
                    {
                        Type = "object",
                        Properties = fileParams.ToDictionary(
                            p => p.Name ?? "file",
                            p => new OpenApiSchema
                            {
                                Type = "string",
                                Format = "binary"
                            }
                        ),
                        Required = new HashSet<string>(fileParams.Select(p => p.Name ?? "file"))
                    }
                }
            }
        };
    }
}

public class UploadFileRequest
{
    // Use [FromForm] to specify that the file should be bound from form data
    public IFormFile File { get; set; } = null!;
}

using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class ModelService : IModelService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<ModelService> _logger;
        private readonly IWebHostEnvironment _env;

        public ModelService(AppDbContext context, ILogger<ModelService> logger, IWebHostEnvironment env)
        {
            _context = context;
            _logger = logger;
            _env = env;
        }

        public async Task<List<ModelVersionDto>> GetAllModelsAsync()
        {
            var models = await _context.ModelVersions
                .OrderByDescending(m => m.CreatedAt)
                .ToListAsync();

            return models.Select(MapToDto).ToList();
        }

        public async Task<ModelVersionDto> UploadModelAsync(UploadModelDto dto)
        {
            // Check duplicate name+version
            var exists = await _context.ModelVersions
                .AnyAsync(m => m.ModelName == dto.ModelName && m.Version == dto.Version);

            if (exists)
                throw new InvalidOperationException($"Model '{dto.ModelName}' version '{dto.Version}' already exists.");

            string? savedFilePath = null;

            // If a file is provided, save it to the Models directory
            if (dto.ModelFile != null && dto.ModelFile.Length > 0)
            {
                var modelsDir = Path.Combine(_env.ContentRootPath, "Models");
                Directory.CreateDirectory(modelsDir);

                var fileName = $"{dto.ModelName}_{dto.Version}.onnx";
                savedFilePath = Path.Combine(modelsDir, fileName);

                await using var fs = new FileStream(savedFilePath, FileMode.Create);
                await dto.ModelFile.CopyToAsync(fs);

                _logger.LogInformation("Model file saved to {Path}", savedFilePath);
            }

            var entity = new ModelVersion
            {
                ModelName = dto.ModelName,
                Version = dto.Version,
                ModelType = dto.ModelType ?? "resnet18",
                Description = dto.Description,
                IsActive = dto.IsActive,
                IsDefault = dto.IsDefault,
                CreatedAt = DateTime.UtcNow
            };

            _context.ModelVersions.Add(entity);
            await _context.SaveChangesAsync();

            _logger.LogInformation("New model registered: {Name} v{Version}", entity.ModelName, entity.Version);

            return MapToDto(entity);
        }

        public async Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId)
        {
            var model = await _context.ModelVersions.FindAsync(modelVersionId);
            if (model == null) return null;

            // Deactivate all other models that are currently default
            if (!model.IsDefault.GetValueOrDefault())
            {
                var currentDefaults = await _context.ModelVersions
                    .Where(m => m.IsDefault == true && m.ModelVersionId != modelVersionId)
                    .ToListAsync();

                foreach (var m in currentDefaults)
                    m.IsDefault = false;
            }

            model.IsActive = true;
            model.IsDefault = true;

            await _context.SaveChangesAsync();

            _logger.LogInformation("Model {Id} ({Name} v{Version}) activated as default", 
                model.ModelVersionId, model.ModelName, model.Version);

            return MapToDto(model);
        }

        private static ModelVersionDto MapToDto(ModelVersion m) => new()
        {
            ModelVersionId = m.ModelVersionId,
            ModelName = m.ModelName,
            Version = m.Version,
            ModelType = m.ModelType,
            Description = m.Description,
            IsActive = m.IsActive,
            IsDefault = m.IsDefault,
            CreatedAt = m.CreatedAt
        };
    }
}

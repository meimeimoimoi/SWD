using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class ModelService : IModelService
    {
        private readonly ModelRepository _modelRepository;
        private readonly ILogger<ModelService> _logger;
        private readonly IWebHostEnvironment _env;

        public ModelService(
            ModelRepository modelRepository,
            ILogger<ModelService> logger,
            IWebHostEnvironment env)
        {
            _modelRepository = modelRepository;
            _logger = logger;
            _env = env;
        }

        public async Task<List<ModelVersionDto>> GetAllModelsAsync()
        {
            _logger.LogInformation("Fetching all model versions.");
            var models = await _modelRepository.GetAllAsync();
            _logger.LogInformation("Retrieved {Count} model versions.", models.Count);
            return models.Select(m => MapToDto(m)).ToList();
        }

        public async Task<(bool success, string message, ModelVersionDto? data)> UploadModelAsync(UploadModelDto dto)
        {
            _logger.LogInformation("Uploading new model: {Name} v{Version}", dto.ModelName, dto.Version);

            // 1. Validate file extension — only .onnx allowed
            var ext = Path.GetExtension(dto.ModelFile.FileName).ToLowerInvariant();
            if (ext != ".onnx")
            {
                _logger.LogWarning("Rejected upload — invalid file extension: {Ext}", ext);
                return (false, "Only .onnx files are accepted.", null);
            }

            // 2. Check duplicate name + version in DB
            var exists = await _modelRepository.ExistsByNameAndVersionAsync(dto.ModelName, dto.Version);
            if (exists)
            {
                _logger.LogWarning("Model '{Name}' v{Version} already exists in DB.", dto.ModelName, dto.Version);
                return (false, $"Model '{dto.ModelName}' version '{dto.Version}' already exists.", null);
            }

            // 3. Build file path and check if the physical file already exists
            var modelsDir = Path.Combine(_env.ContentRootPath, "Models");
            Directory.CreateDirectory(modelsDir);

            var fileName = $"{dto.ModelName}_{dto.Version}.onnx";
            var savedFilePath = Path.Combine(modelsDir, fileName);

            if (File.Exists(savedFilePath))
            {
                _logger.LogWarning("Physical file already exists at {Path}", savedFilePath);
                return (false, $"A file named '{fileName}' already exists on the server.", null);
            }

            // 4. Save file to disk
            await using (var fs = new FileStream(savedFilePath, FileMode.Create))
            {
                await dto.ModelFile.CopyToAsync(fs);
            }
            _logger.LogInformation("Model file saved to {Path}", savedFilePath);

            // 5. Convert to relative path for DB storage
            var relativeFilePath = Path.Combine("Models", fileName);

            // 6. New model is inactive and not default by default — admin must explicitly activate
            var entity = new ModelVersion
            {
                ModelName = dto.ModelName,
                Version = dto.Version,
                ModelType = string.IsNullOrWhiteSpace(dto.ModelType) ? "mobilenetv3" : dto.ModelType,
                Description = dto.Description,
                IsActive = false,
                IsDefault = false,
                CreatedAt = DateTime.UtcNow
            };

            await _modelRepository.AddAsync(entity);
            _logger.LogInformation(
                "Model registered in DB — Id={Id}, Name={Name}, v{Version}, IsActive=false, IsDefault=false",
                entity.ModelVersionId, entity.ModelName, entity.Version);

            return (true, "Model uploaded and registered successfully.", MapToDto(entity, relativeFilePath));
        }

        public async Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId)
        {
            _logger.LogInformation("Activating model Id={Id}", modelVersionId);

            var model = await _modelRepository.GetByIdAsync(modelVersionId);
            if (model == null)
            {
                _logger.LogWarning("Model Id={Id} not found.", modelVersionId);
                return null;
            }

            // Deactivate (IsActive=false, IsDefault=false) all other models first
            var otherDefaults = await _modelRepository.GetAllDefaultsExceptAsync(modelVersionId);
            if (otherDefaults.Count > 0)
            {
                foreach (var m in otherDefaults)
                {
                    m.IsDefault = false;
                    m.IsActive = false;
                }
                await _modelRepository.UpdateRangeAsync(otherDefaults);
                _logger.LogInformation(
                    "Deactivated {Count} previously active model(s).", otherDefaults.Count);
            }

            // Activate the selected model
            model.IsActive = true;
            model.IsDefault = true;
            await _modelRepository.UpdateAsync(model);

            _logger.LogInformation(
                "Model Id={Id} ({Name} v{Version}) is now active and default.",
                model.ModelVersionId, model.ModelName, model.Version);

            return MapToDto(model);
        }

        // ?? Helpers ??????????????????????????????????????????????????????????????

        private static ModelVersionDto MapToDto(ModelVersion m, string? filePath = null) => new()
        {
            ModelVersionId = m.ModelVersionId,
            ModelName = m.ModelName,
            Version = m.Version,
            ModelType = m.ModelType,
            Description = m.Description,
            IsActive = m.IsActive,
            IsDefault = m.IsDefault,
            CreatedAt = m.CreatedAt,
            FilePath = filePath
        };
    }
}

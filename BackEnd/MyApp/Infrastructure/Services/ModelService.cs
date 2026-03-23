using Microsoft.ML.OnnxRuntime;
using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Infrastructure.Ml;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class ModelService : IModelService
    {
        private readonly ModelRepository _modelRepository;
        private readonly IMonitoringService _monitoring;
        private readonly IPredictionService _prediction;
        private readonly ILogger<ModelService> _logger;
        private readonly IWebHostEnvironment _env;

        public ModelService(
            ModelRepository modelRepository,
            IMonitoringService monitoring,
            IPredictionService prediction,
            ILogger<ModelService> logger,
            IWebHostEnvironment env)
        {
            _modelRepository = modelRepository;
            _monitoring      = monitoring;
            _prediction      = prediction;
            _logger          = logger;
            _env             = env;
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

            var ext = Path.GetExtension(dto.ModelFile.FileName).ToLowerInvariant();
            if (ext != ".onnx")
            {
                _logger.LogWarning("Rejected upload - invalid file extension: {Ext}", ext);
                return (false, "Only .onnx files are accepted.", null);
            }

            var exists = await _modelRepository.ExistsByNameAndVersionAsync(dto.ModelName, dto.Version);
            if (exists)
            {
                _logger.LogWarning("Model '{Name}' v{Version} already exists in DB.", dto.ModelName, dto.Version);
                return (false, $"Model '{dto.ModelName}' version '{dto.Version}' already exists.", null);
            }

            var modelsDir = Path.Combine(_env.ContentRootPath, "Models");
            Directory.CreateDirectory(modelsDir);

            var fileName     = $"{dto.ModelName}_{dto.Version}.onnx";
            var savedFilePath = Path.Combine(modelsDir, fileName);

            if (File.Exists(savedFilePath))
            {
                _logger.LogWarning("Physical file already exists at {Path}", savedFilePath);
                return (false, $"A file named '{fileName}' already exists on the server.", null);
            }

            await using (var fs = new FileStream(savedFilePath, FileMode.Create))
            {
                await dto.ModelFile.CopyToAsync(fs);
            }
            _logger.LogInformation("Model file saved to {Path}", savedFilePath);

            var relativeFilePath = Path.Combine("Models", fileName);

            var entity = new ModelVersion
            {
                ModelName   = dto.ModelName,
                Version     = dto.Version,
                ModelType   = string.IsNullOrWhiteSpace(dto.ModelType) ? "mobilenetv3" : dto.ModelType,
                Description = dto.Description,
                FilePath    = relativeFilePath,
                IsActive    = false,
                IsDefault   = false,
                CreatedAt   = DateTime.UtcNow
            };

            await _modelRepository.AddAsync(entity);
            _logger.LogInformation(
                "Model registered in DB - Id={Id}, Name={Name}, v{Version}, IsActive=false, IsDefault=false",
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

            var otherDefaults = await _modelRepository.GetAllDefaultsExceptAsync(modelVersionId);
            if (otherDefaults.Count > 0)
            {
                foreach (var m in otherDefaults)
                {
                    m.IsDefault = false;
                    m.IsActive  = false;
                }
                await _modelRepository.UpdateRangeAsync(otherDefaults);
                _logger.LogInformation("Deactivated {Count} previously active model(s).", otherDefaults.Count);
            }

            model.IsActive  = true;
            model.IsDefault = true;
            await _modelRepository.UpdateAsync(model);

            _logger.LogInformation(
                "Model Id={Id} ({Name} v{Version}) is now active and default.",
                model.ModelVersionId, model.ModelName, model.Version);

            return MapToDto(model);
        }

        public async Task<ModelVersionDetailDto?> GetModelVersionDetailAsync(int modelVersionId)
        {
            var m = await _modelRepository.GetByIdAsync(modelVersionId);
            if (m == null)
            {
                return null;
            }

            var usage = await _monitoring.GetModelUsageMetricsAsync(modelVersionId)
                        ?? new ModelVersionUsageMetricsDto();

            var dto = new ModelVersionDetailDto
            {
                ModelVersionId = m.ModelVersionId,
                ModelName = m.ModelName,
                Version = m.Version,
                ModelType = m.ModelType,
                Description = m.Description,
                IsActive = m.IsActive,
                IsDefault = m.IsDefault,
                CreatedAt = m.CreatedAt,
                RelativeFilePath = m.FilePath,
                TotalPredictions = usage.TotalPredictions,
                PredictionsToday = usage.PredictionsToday,
                PredictionsLast7Days = usage.PredictionsLast7Days,
                AverageConfidence = usage.AverageConfidence,
                TotalRatings = usage.TotalRatings,
                PositiveRatings = usage.PositiveRatings,
                PositiveRatingRate = usage.PositiveRatingRate,
                TopPredictedClasses = usage.TopPredictedClasses,
                CurrentlyLoadedModelVersionId = _prediction.GetLoadedModelVersionId(),
                IsCurrentInferenceModel =
                    _prediction.GetLoadedModelVersionId() == modelVersionId
            };

            if (string.IsNullOrWhiteSpace(m.FilePath))
            {
                return dto;
            }

            var full = Path.GetFullPath(Path.Combine(_env.ContentRootPath, m.FilePath));
            dto.AbsolutePath = full;

            if (!File.Exists(full))
            {
                return dto;
            }

            dto.FileExists = true;
            try
            {
                var fi = new FileInfo(full);
                dto.FileSizeBytes = fi.Length;
                dto.FileLastModifiedUtc = fi.LastWriteTimeUtc;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Could not stat model file {Path}", full);
            }

            PopulateOnnxMetadata(dto, full);
            return dto;
        }

        private void PopulateOnnxMetadata(ModelVersionDetailDto dto, string fullPath)
        {
            try
            {
                using var session = new InferenceSession(fullPath);
                var mm = session.ModelMetadata;
                dto.OnnxProducerName = mm.ProducerName;
                dto.OnnxGraphName = mm.GraphName;
                dto.OnnxDomain = mm.Domain;
                dto.OnnxModelVersion = mm.Version;

                dto.OnnxInputNames = session.InputMetadata.Keys.ToList();
                dto.OnnxOutputNames = session.OutputMetadata.Keys.ToList();

                foreach (var kv in session.InputMetadata)
                {
                    dto.OnnxInputShapeDescriptions[kv.Key] = DescribeDimensions(kv.Value);
                }

                foreach (var kv in session.OutputMetadata)
                {
                    dto.OnnxOutputShapeDescriptions[kv.Key] = DescribeDimensions(kv.Value);
                }

                try
                {
                    var labels = OnnxModelLabels.Read(session, fullPath);
                    dto.OnnxClassLabelCount = labels.Length;
                    dto.OnnxClassLabelsSample = labels.Take(32).ToList();
                }
                catch (Exception ex)
                {
                    dto.OnnxClassLabelsError = ex.Message;
                }
            }
            catch (Exception ex)
            {
                dto.OnnxMetadataError = ex.Message;
                _logger.LogWarning(ex, "ONNX inspect failed for {Path}", fullPath);
            }
        }

        private static string DescribeDimensions(NodeMetadata meta)
        {
            var dims = meta.Dimensions;
            if (dims == null || dims.Length == 0)
            {
                return "?";
            }

            return string.Join(
                " × ",
                dims.Select(d => d <= 0 ? "dynamic" : d.ToString()));
        }

        private static ModelVersionDto MapToDto(ModelVersion m, string? filePath = null) => new()
        {
            ModelVersionId = m.ModelVersionId,
            ModelName      = m.ModelName,
            Version        = m.Version,
            ModelType      = m.ModelType,
            Description    = m.Description,
            IsActive       = m.IsActive,
            IsDefault      = m.IsDefault,
            CreatedAt      = m.CreatedAt,
            FilePath       = filePath ?? m.FilePath
        };
    }
}

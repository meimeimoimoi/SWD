using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Models.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class ModelService : IModelService
{
    private readonly ModelRepository _modelRepository;
    private readonly ILogger<ModelService> _logger;

    public ModelService(ModelRepository modelRepository, ILogger<ModelService> logger)
    {
        _modelRepository = modelRepository;
        _logger = logger;
    }

    public async Task<List<ModelVersionDto>> GetAllModelsAsync()
    {
        try
        {
            var models = await _modelRepository.GetAllModelsAsync();
            var result = new List<ModelVersionDto>();

            foreach (var model in models)
            {
                var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);
                
                result.Add(new ModelVersionDto
                {
                    ModelVersionId = model.ModelVersionId,
                    ModelName = model.ModelName,
                    Version = model.Version,
                    ModelType = model.ModelType,
                    Description = model.Description,
                    IsActive = model.IsActive,
                    IsDefault = model.IsDefault,
                    MinConfidence = threshold?.MinConfidence,
                    CreatedAt = model.CreatedAt
                });
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting all models");
            throw;
        }
    }

    public async Task<ModelVersionDto?> GetModelByIdAsync(int modelVersionId)
    {
        try
        {
            var model = await _modelRepository.GetModelByIdAsync(modelVersionId);
            if (model == null)
                return null;

            var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);

            return new ModelVersionDto
            {
                ModelVersionId = model.ModelVersionId,
                ModelName = model.ModelName,
                Version = model.Version,
                ModelType = model.ModelType,
                Description = model.Description,
                IsActive = model.IsActive,
                IsDefault = model.IsDefault,
                MinConfidence = threshold?.MinConfidence,
                CreatedAt = model.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting model by ID: {ModelVersionId}", modelVersionId);
            throw;
        }
    }

    public async Task<bool> ActivateModelAsync(int modelVersionId)
    {
        try
        {
            var result = await _modelRepository.ActivateModelAsync(modelVersionId);
            
            if (result)
                _logger.LogInformation("Model {ModelVersionId} activated successfully", modelVersionId);
            else
                _logger.LogWarning("Failed to activate model {ModelVersionId}", modelVersionId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error activating model: {ModelVersionId}", modelVersionId);
            throw;
        }
    }

    public async Task<bool> DeactivateModelAsync(int modelVersionId)
    {
        try
        {
            var result = await _modelRepository.DeactivateModelAsync(modelVersionId);
            
            if (result)
                _logger.LogInformation("Model {ModelVersionId} deactivated successfully", modelVersionId);
            else
                _logger.LogWarning("Failed to deactivate model {ModelVersionId}", modelVersionId);

            return result;
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Cannot deactivate model {ModelVersionId}: {Message}", 
                modelVersionId, ex.Message);
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deactivating model: {ModelVersionId}", modelVersionId);
            throw;
        }
    }

    public async Task<ModelVersionDto?> GetDefaultModelAsync()
    {
        try
        {
            var model = await _modelRepository.GetDefaultModelAsync();
            if (model == null)
                return null;

            var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);

            return new ModelVersionDto
            {
                ModelVersionId = model.ModelVersionId,
                ModelName = model.ModelName,
                Version = model.Version,
                ModelType = model.ModelType,
                Description = model.Description,
                IsActive = model.IsActive,
                IsDefault = model.IsDefault,
                MinConfidence = threshold?.MinConfidence,
                CreatedAt = model.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting default model");
            throw;
        }
    }

    public async Task<ModelVersionDto?> GetLatestActiveModelAsync()
    {
        try
        {
            var model = await _modelRepository.GetLatestActiveModelAsync();
            if (model == null)
                return null;

            var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);

            _logger.LogInformation("Latest active model retrieved: {ModelName} v{Version}", 
                model.ModelName, model.Version);

            return new ModelVersionDto
            {
                ModelVersionId = model.ModelVersionId,
                ModelName = model.ModelName,
                Version = model.Version,
                ModelType = model.ModelType,
                Description = model.Description,
                IsActive = model.IsActive,
                IsDefault = model.IsDefault,
                MinConfidence = threshold?.MinConfidence,
                CreatedAt = model.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting latest active model");
            throw;
        }
    }

    public async Task<ModelVersionDto?> GetLatestModelByNameAsync(string modelName)
    {
        try
        {
            var model = await _modelRepository.GetLatestModelByNameAsync(modelName);
            if (model == null)
                return null;

            var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);

            _logger.LogInformation("Latest model for {ModelName} retrieved: v{Version}", 
                modelName, model.Version);

            return new ModelVersionDto
            {
                ModelVersionId = model.ModelVersionId,
                ModelName = model.ModelName,
                Version = model.Version,
                ModelType = model.ModelType,
                Description = model.Description,
                IsActive = model.IsActive,
                IsDefault = model.IsDefault,
                MinConfidence = threshold?.MinConfidence,
                CreatedAt = model.CreatedAt
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting latest model by name: {ModelName}", modelName);
            throw;
        }
    }

    public async Task<bool> SetDefaultModelAsync(int modelVersionId)
    {
        try
        {
            var result = await _modelRepository.SetDefaultModelAsync(modelVersionId);
            
            if (result)
                _logger.LogInformation("Model {ModelVersionId} set as default successfully", modelVersionId);
            else
                _logger.LogWarning("Failed to set model {ModelVersionId} as default", modelVersionId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting default model: {ModelVersionId}", modelVersionId);
            throw;
        }
    }
}

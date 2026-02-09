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
            var modelDtos = new List<ModelVersionDto>();

            foreach (var model in models)
            {
                var threshold = await _modelRepository.GetThresholdByModelIdAsync(model.ModelVersionId);
                
                modelDtos.Add(new ModelVersionDto
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

            _logger.LogInformation("Retrieved {Count} models", modelDtos.Count);
            return modelDtos;
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

            var threshold = await _modelRepository.GetThresholdByModelIdAsync(modelVersionId);

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
                _logger.LogWarning("Failed to activate model {ModelVersionId} - not found", modelVersionId);

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

    public async Task<bool> SetDefaultModelAsync(int modelVersionId)
    {
        try
        {
            var result = await _modelRepository.SetDefaultModelAsync(modelVersionId);
            
            if (result)
                _logger.LogInformation("Model {ModelVersionId} set as default", modelVersionId);
            else
                _logger.LogWarning("Failed to set model {ModelVersionId} as default - not found", modelVersionId);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting default model: {ModelVersionId}", modelVersionId);
            throw;
        }
    }
}

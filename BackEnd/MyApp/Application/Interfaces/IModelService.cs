using MyApp.Application.Features.Models.DTOs;

namespace MyApp.Application.Interfaces;

public interface IModelService
{
    Task<List<ModelVersionDto>> GetAllModelsAsync();
    Task<ModelVersionDto?> GetModelByIdAsync(int modelVersionId);
    Task<bool> ActivateModelAsync(int modelVersionId);
    Task<bool> DeactivateModelAsync(int modelVersionId);
    Task<bool> UpdateModelThresholdAsync(int modelVersionId, decimal minConfidence);
    Task<ModelVersionDto?> GetDefaultModelAsync();
    Task<bool> SetDefaultModelAsync(int modelVersionId);
}

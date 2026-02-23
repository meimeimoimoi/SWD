using MyApp.Application.Features.Models.DTOs;

namespace MyApp.Application.Interfaces;

public interface IModelVersionService
{
    Task<List<ModelVersionDto>> GetAllModelsAsync();
    Task<bool> ActivateModelAsync(int modelId, bool isActive);
    Task<bool> SetDefaultModelAsync(int modelId);
}

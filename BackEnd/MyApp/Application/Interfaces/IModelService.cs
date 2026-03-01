using MyApp.Application.Features.ModelManagement.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IModelService
    {
        Task<List<ModelVersionDto>> GetAllModelsAsync();
        Task<(bool success, string message, ModelVersionDto? data)> UploadModelAsync(UploadModelDto dto);
        Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId);
    }
}

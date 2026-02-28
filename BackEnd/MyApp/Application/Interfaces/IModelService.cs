using MyApp.Application.Features.ModelManagement.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IModelService
    {
        Task<List<ModelVersionDto>> GetAllModelsAsync();
        Task<ModelVersionDto> UploadModelAsync(UploadModelDto dto);
        Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId);
    }
}

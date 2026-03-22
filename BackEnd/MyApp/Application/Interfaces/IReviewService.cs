using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.ModelManagement.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IReviewService
    {
        Task<List<TreatmentReviewDto>> GetAllTreatmentsAsync();
        Task<TreatmentReviewDto?> GetTreatmentByIdAsync(int solutionId);
        Task<TreatmentReviewDto?> UpdateTreatmentAsync(int solutionId, UpdateTreatmentDto dto);
        Task<bool> DeleteTreatmentAsync(int solutionId);

        Task<List<ModelVersionDto>> GetAllModelsAsync();
        Task<ModelVersionDto?> ActivateModelAsync(int modelVersionId);
        Task<bool> DeactivateModelAsync(int modelVersionId);
    }
}

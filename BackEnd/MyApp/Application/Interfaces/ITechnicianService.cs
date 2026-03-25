using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Technician.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface ITechnicianService
    {
        Task<List<IllnessDto>> GetAllIllnessesAsync();
        Task<IllnessDto?> GetIllnessByIdAsync(int id);
        Task<IllnessDto> CreateIllnessAsync(CreateIllnessDto dto);
        Task<IllnessDto?> UpdateIllnessAsync(int id, UpdateIllnessDto dto);
        Task<bool> DeleteIllnessAsync(int id);
        Task<(bool success, string message)> AssignIllnessToTreeAsync(int illnessId, int treeId);

        Task<List<TreeStageDto>> GetAllStagesAsync();
        Task<TreeStageDto?> GetStageByIdAsync(int id);
        Task<TreeStageDto> CreateStageAsync(CreateTreeStageDto dto);
        Task<TreeStageDto?> UpdateStageAsync(int id, UpdateTreeStageDto dto);

        Task<List<TreatmentReviewDto>> GetAllTreatmentsAsync();
        Task<TreatmentReviewDto> CreateTreatmentAsync(CreateTreatmentDto dto);
        Task<TreatmentReviewDto?> UpdateTreatmentAsync(int solutionId, UpdateTreatmentDto dto);
        Task<(bool success, string message, TreatmentReviewDto? data)> AssignTreatmentToIllnessAsync(int solutionId, int illnessId);

        // Image management for TreatmentSolution
        Task<List<SolutionImageDto>> GetImagesBySolutionIdAsync(int solutionId);
        Task<SolutionImageDto> UploadSolutionImageAsync(int solutionId, Microsoft.AspNetCore.Http.IFormFile file);
        Task<bool> DeleteSolutionImageAsync(int imageId);
        Task<bool> ReorderSolutionImagesAsync(int solutionId, List<int> orderedImageIds);
    }
}

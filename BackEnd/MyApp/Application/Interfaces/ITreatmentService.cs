using MyApp.Application.Features.Treatment.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface ITreatmentService
    {
        Task<DiseaseDetailDto?> GetDiseaseDetailAsync(int illnessId);
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessAsync(int illnessId);
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessStageAsync(int illnessId, int illnessStageId);
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByTreeStageAsync(int treeStageId);
        Task<TreatmentSolutionDto?> GetSolutionDetailAsync(int solutionId);
    }
}

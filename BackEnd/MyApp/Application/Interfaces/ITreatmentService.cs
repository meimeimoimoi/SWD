using MyApp.Application.Features.Treatment.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface ITreatmentService
    {
        /// <summary>GET /api/diseases/{id}/detail — Chi ti?t b?nh + danh sách thu?c</summary>
        Task<DiseaseDetailDto?> GetDiseaseDetailAsync(int illnessId);

        /// <summary>Ð? xu?t ði?u tr? theo b?nh</summary>
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessAsync(int illnessId);

        /// <summary>Ð? xu?t ði?u tr? theo b?nh + giai ðo?n b?nh</summary>
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByIllnessStageAsync(int illnessId, int illnessStageId);

        /// <summary>Ð? xu?t ði?u tr? theo giai ðo?n sinh trý?ng c?a lúa (tree stage)</summary>
        Task<List<TreatmentRecommendationDto>> GetRecommendationsByTreeStageAsync(int treeStageId);

        /// <summary>Xem mô t? chi ti?t m?t thu?c/gi?i pháp</summary>
        Task<TreatmentSolutionDto?> GetSolutionDetailAsync(int solutionId);
    }
}

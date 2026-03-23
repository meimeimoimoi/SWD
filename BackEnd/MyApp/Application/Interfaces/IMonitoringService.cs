using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.ModelManagement.DTOs;
using MyApp.Domain.Entities;

namespace MyApp.Application.Interfaces
{
    public interface IMonitoringService
    {
        Task<DashboardStatsDto> GetDashboardStatsAsync();
        Task<PredictionStatsDto> GetPredictionStatsAsync(int days = 7);
        Task<List<ModelAccuracyDto>> GetModelAccuracyAsync();
        Task<List<RatingDto>> GetRatingsAsync(int page = 1, int pageSize = 20);
        Task<List<ActivityLog>> GetActivityLogsAsync(int count = 50);
        Task<List<CommonThreatItemDto>> GetCommonThreatsAsync(int take = 5);

        Task<ModelVersionUsageMetricsDto?> GetModelUsageMetricsAsync(int modelVersionId);
    }
}

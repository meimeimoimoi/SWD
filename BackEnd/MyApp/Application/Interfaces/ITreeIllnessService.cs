using MyApp.Application.Features.TreeIllnesses.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface ITreeIllnessService
    {
        Task<(List<TreeIllnessResponseDto> illnesses, PaginationMetadata pagination)> GetAllIllnessesAsync(
            TreeIllnessListRequestDto request);
        Task<TreeIllnessResponseDto?> GetIllnessByIdAsync(int illnessId);
        Task<Dictionary<string, int>> GetSeverityStatisticsAsync();
        Task<TreeIllnessResponseDto> CreateIllnessAsync(CreateTreeIllnessDto dto);
        Task<TreeIllnessResponseDto> UpdateIllnessAsync(int illnessId, UpdateTreeIllnessDto dto);
    }
}

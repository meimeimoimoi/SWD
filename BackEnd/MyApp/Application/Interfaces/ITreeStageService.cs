using MyApp.Application.Features.TreeStages.DTOs;

namespace MyApp.Application.Interfaces
{

    public interface ITreeStageService
    {
        Task<List<TreeStageResponseDto>> GetAllStagesAsync();
        Task<TreeStageResponseDto?> GetStageByIdAsync(int stageId);
        Task<TreeStageResponseDto> CreateStageAsync(CreateTreeStageDto dto);
        Task<TreeStageResponseDto> UpdateStageAsync(int stageId, UpdateTreeStageDto dto);
        Task DeleteStageAsync(int stageId);
    }
}

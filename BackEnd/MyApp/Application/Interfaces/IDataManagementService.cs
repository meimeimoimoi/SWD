using MyApp.Application.Features.Admin.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IDataManagementService
    {
        Task<List<TreeStageDto>> GetAllStagesAsync();
        Task<TreeStageDto?> GetStageByIdAsync(int id);
        Task<TreeStageDto> CreateStageAsync(CreateTreeStageDto dto);
        Task<TreeStageDto?> UpdateStageAsync(int id, UpdateTreeStageDto dto);
        Task<bool> DeleteStageAsync(int id);

        Task<List<TreeIllnessRelationshipDto>> GetAllRelationshipsAsync();
        Task<List<TreeIllnessRelationshipDto>> GetRelationshipsByTreeAsync(int treeId);
        Task<List<TreeIllnessRelationshipDto>> GetRelationshipsByIllnessAsync(int illnessId);
        Task<TreeIllnessRelationshipDto> CreateRelationshipAsync(CreateRelationshipDto dto);
        Task<bool> DeleteRelationshipAsync(int relationshipId);
    }
}

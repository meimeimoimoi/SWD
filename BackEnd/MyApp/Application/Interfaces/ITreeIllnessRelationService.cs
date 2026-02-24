using MyApp.Application.Features.TreeIllnessRelations.DTOs;

namespace MyApp.Application.Interfaces;

public interface ITreeIllnessRelationService
{
    Task<bool> MapTreeIllnessAsync(MapTreeIllnessDto dto);
    Task<bool> UnmapTreeIllnessAsync(MapTreeIllnessDto dto);
}

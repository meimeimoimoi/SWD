using MyApp.Application.Features.Trees.DTOs;

namespace MyApp.Application.Interfaces;

public interface ITreeIllnessService
{
    Task<bool> MapTreeIllnessAsync(int treeId, int illnessId);
    Task<bool> UnmapTreeIllnessAsync(int treeId, int illnessId);
}

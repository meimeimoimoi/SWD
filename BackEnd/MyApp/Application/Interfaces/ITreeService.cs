using MyApp.Application.Features.Trees.DTOs;

namespace MyApp.Application.Interfaces;

public interface ITreeService
{
    Task<List<TreeDto>> GetAllTreesAsync();
    Task<TreeDto?> GetTreeByIdAsync(int treeId);
    Task<TreeDto> CreateTreeAsync(CreateTreeDto createDto);
    Task<bool> UpdateTreeAsync(int treeId, UpdateTreeDto updateDto);
    Task<bool> DeleteTreeAsync(int treeId);
}

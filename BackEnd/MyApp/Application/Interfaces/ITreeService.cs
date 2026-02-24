using MyApp.Application.Features.Trees.DTOs;

namespace MyApp.Application.Interfaces;

public interface ITreeService
{
    Task<List<TreeDto>> GetAllTreesAsync();
    Task<int> CreateTreeAsync(CreateTreeDto dto);
    Task<bool> UpdateTreeAsync(int id, UpdateTreeDto dto);
    Task<bool> DeleteTreeAsync(int id);
}

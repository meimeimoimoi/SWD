using MyApp.Application.Features.Illnesses.DTOs;

namespace MyApp.Application.Interfaces;

public interface IIllnessService
{
    Task<List<IllnessDto>> GetAllIllnessesAsync();
    Task<int> CreateIllnessAsync(CreateIllnessDto dto);
    Task<bool> UpdateIllnessAsync(int id, UpdateIllnessDto dto);
    Task<bool> DeleteIllnessAsync(int id);
}

using MyApp.Application.Features.Illnesses.DTOs;

namespace MyApp.Application.Interfaces;

public interface IIllnessService
{
    Task<List<IllnessDto>> GetAllIllnessesAsync();
    Task<IllnessDto?> GetIllnessByIdAsync(int illnessId);
    Task<IllnessDto> CreateIllnessAsync(CreateIllnessDto createDto);
    Task<bool> UpdateIllnessAsync(int illnessId, UpdateIllnessDto updateDto);
    Task<bool> DeleteIllnessAsync(int illnessId);
}

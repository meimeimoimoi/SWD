using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces;

public interface IUserTreeService
{
    Task<List<UserTreeListItemDto>> GetTreesForUserAsync(int userId);
    Task<UserTreeListItemDto> CreateTreeAsync(CreateUserTreeDto dto);
    Task<(bool Success, string Message)> AssignPredictionToTreeAsync(int userId, int predictionId, int treeId);
}

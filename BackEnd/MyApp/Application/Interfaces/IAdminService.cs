using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IAdminService
    {
        Task<List<UserDto>> GetAllUsersAsync(string? search = null, string? role = null, string? sortBy = "email", string? sortOrder = "asc");
        Task<UserDto?> GetUserByIdAsync(int userId);
        Task<bool> UpdateUserAsync(int userId, UpdateUserDto updateDto);
        Task<bool> UpdateUserStatusAsync(int userId, string status);
        Task<UserDto> CreateStaffUserAsync(CreateTechnicianStaffDto createDto);
        Task<bool> DeleteUserAsync(int userId);
    }
}

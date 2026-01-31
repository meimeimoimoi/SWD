using SWD.Business.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Interface
{
    public interface IAdminService
    {
        Task<ApiResponse<PagedResult<UserDto>>> GetAllUsersAsync(int page, int pageSize, string? search = null, string? role = null, string? sortBy = "email", string? sortOrder = "asc");
        Task<ApiResponse<UserDto>> GetUserByIdAsync(Guid userId);
        Task<ApiResponse<object>> UpdateUserAsync(Guid userId, UpdateUserDto updateDto);
        Task<ApiResponse<object>> UpdateUserStatusAsync(Guid userId, UpdateUserStatusDto statusDto);
        Task<ApiResponse<object>> CreateStaffUserAsync(CreateStaffUserDto createDto);
    }
}

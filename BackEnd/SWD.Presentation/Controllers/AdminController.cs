using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SWD.Business.DTOs;
using SWD.Business.Interface;

namespace SWD.Presentation.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;
        public AdminController(IAdminService adminService)
        {
            _adminService = adminService;
        }

        [HttpPost("users")]
        public async Task<IActionResult> CreateStaffUser([FromBody] CreateStaffUserDto createDto)
        {
            var response = await _adminService.CreateStaffUserAsync(createDto);
            if (!response.Succeeded)
            {
                return Conflict(response);
            }
            return Ok(response);
        }

        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null,
            [FromQuery] string? role = null,
            [FromQuery] string? sortBy = "email",
            [FromQuery] string? sortOrder = "asc")
        {
            var response = await _adminService.GetAllUsersAsync(page, pageSize, search, role, sortBy, sortOrder);
            return Ok(response);
        }

        [HttpGet("users/{userId}")]
        public async Task<IActionResult> GetUserById(Guid userId)
        {
            var response = await _adminService.GetUserByIdAsync(userId);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return NotFound(response);
        }

        [HttpPut("users/{userId}")]
        public async Task<IActionResult> UpdateUser(Guid userId, [FromBody] UpdateUserDto updateDto)
        {
            var response = await _adminService.UpdateUserAsync(userId, updateDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return BadRequest(response);
        }

        [HttpPatch("users/{userId}/status")]
        public async Task<IActionResult> UpdateUserStatus(Guid userId, [FromBody] UpdateUserStatusDto statusDto)
        {
            var response = await _adminService.UpdateUserStatusAsync(userId, statusDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return BadRequest(response);
        }
    }
}

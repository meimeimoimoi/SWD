using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;
        private readonly ILogger<AdminController> _logger;

        public AdminController(IAdminService adminService, ILogger<AdminController> logger)
        {
            _adminService = adminService;
            _logger = logger;
        }

       
        [HttpGet("users")]
       
        public async Task<IActionResult> GetAllUsers(
            [FromQuery] string? search = null,
            [FromQuery] string? role = null,
            [FromQuery] string? sortBy = "email",
            [FromQuery] string? sortOrder = "asc")
        {
            try
            {
                var users = await _adminService.GetAllUsersAsync(search, role, sortBy, sortOrder);
                return Ok(new
                {
                    success = true,
                    message = "Users retrieved successfully",
                    data = users
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving users");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving users",
                    error = ex.Message
                });
            }
        }

        
        [HttpGet("users/{userId}")]
        
        public async Task<IActionResult> GetUserById(int userId)
        {
            try
            {
                var user = await _adminService.GetUserByIdAsync(userId);
                
                if (user == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"User with ID {userId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "User retrieved successfully",
                    data = user
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving user {UserId}", userId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving user",
                    error = ex.Message
                });
            }
        }

      
        [HttpPut("users/{userId}")]
       
        public async Task<IActionResult> UpdateUser(int userId, [FromBody] UpdateUserDto updateDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)
                    });
                }

                var result = await _adminService.UpdateUserAsync(userId, updateDto);
                
                if (!result)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"User with ID {userId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "User updated successfully"
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user {UserId}", userId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while updating user",
                    error = ex.Message
                });
            }
        }

       
        [HttpPatch("users/{userId}/status")]
        
        public async Task<IActionResult> UpdateUserStatus(int userId, [FromBody] UpdateStatusRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Status))
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Status is required"
                    });
                }

                var result = await _adminService.UpdateUserStatusAsync(userId, request.Status);
                
                if (!result)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"User with ID {userId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = $"User status updated to '{request.Status}' successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user status {UserId}", userId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while updating user status",
                    error = ex.Message
                });
            }
        }

       
        [HttpPost("users/staff")]
       
        public async Task<IActionResult> CreateStaffUser([FromBody] CreateTechnicianStaffDto createDto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input data",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)
                    });
                }

                var user = await _adminService.CreateStaffUserAsync(createDto);

                return CreatedAtAction(
                    nameof(GetUserById),
                    new { userId = user.UserId },
                    new
                    {
                        success = true,
                        message = $"Staff/Technician user created successfully. Confirmation email sent to {user.Email}",
                        data = user
                    });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating staff user");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while creating staff user",
                    error = ex.Message
                });
            }
        }

        [HttpDelete("users/{userId}")]
      
        public async Task<IActionResult> DeleteUser(int userId)
        {
            try
            {
                var result = await _adminService.DeleteUserAsync(userId);
                
                if (!result)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = $"User with ID {userId} not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "User deleted successfully (soft delete - status set to 'Deleted')"
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new
                {
                    success = false,
                    message = ex.Message
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user {UserId}", userId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while deleting user",
                    error = ex.Message
                });
            }
        }
    }

    public class UpdateStatusRequest
    {
        public string Status { get; set; } = null!;
    }
}

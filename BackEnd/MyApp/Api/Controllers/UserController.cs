using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace MyApp.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IUserTreeService _userTreeService;
        private readonly ILogger<UserController> _logger;

        public UserController(
            IUserService userService,
            IUserTreeService userTreeService,
            ILogger<UserController> logger)
        {
            _userService = userService;
            _userTreeService = userTreeService;
            _logger = logger;
        }

        [HttpGet("profile")]
        public async Task<IActionResult> GetProfileUser()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    return Unauthorized(new
                    {
                        success = false,
                        message = "Invalid user authentication"
                    });
                }

                var profile = await _userService.GetProfileUserAsync(userId.Value);
                if (profile == null)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "User not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Profile retrieved successfully",
                    data = profile
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving current user profile");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while retrieving profile",
                    error = ex.Message
                });
            }
        }

        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileDto updateDto)
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

                var userId = GetCurrentUserId();
                if (userId == null)
                {
                    return Unauthorized(new
                    {
                        success = false,
                        message = "Invalid user authentication"
                    });
                }

                var updated = await _userService.UpdateProfileAsync(userId.Value, updateDto);
                if (!updated)
                {
                    return NotFound(new
                    {
                        success = false,
                        message = "User not found"
                    });
                }

                return Ok(new
                {
                    success = true,
                    message = "Profile updated successfully"
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
                _logger.LogError(ex, "Error updating current user profile");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while updating profile",
                    error = ex.Message
                });
            }
        }

        [HttpGet("notifications")]
        public async Task<IActionResult> GetNotifications()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null) return Unauthorized();

                var notifications = await _userService.GetUserNotificationsAsync(userId.Value);
                return Ok(new { success = true, total = notifications.Count, data = notifications });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching notifications for user.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("activities")]
        public async Task<IActionResult> GetActivities()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null) return Unauthorized();

                var activities = await _userService.GetUserActivitiesAsync(userId.Value);
                return Ok(new { success = true, total = activities.Count, data = activities });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching activities for user.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpGet("trees")]
        public async Task<IActionResult> GetMyTrees()
        {
            try
            {
                var userId = GetCurrentUserId();
                if (userId == null)
                    return Unauthorized(new { success = false, message = "Invalid user authentication" });

                var trees = await _userTreeService.GetTreesForUserAsync(userId.Value);
                return Ok(new { success = true, data = trees });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error listing user trees.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        [HttpPost("trees")]
        public async Task<IActionResult> CreateTree([FromBody] CreateUserTreeDto dto)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Invalid input",
                        errors = ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage)
                    });
                }

                if (GetCurrentUserId() == null)
                    return Unauthorized(new { success = false, message = "Invalid user authentication" });

                var created = await _userTreeService.CreateTreeAsync(dto);
                return Ok(new
                {
                    success = true,
                    message = "Tree created successfully.",
                    data = created
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user tree.");
                return StatusCode(500, new { success = false, message = "Internal server error." });
            }
        }

        private int? GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

            return int.TryParse(userIdClaim, out var userId) ? userId : null;
        }
    }
}

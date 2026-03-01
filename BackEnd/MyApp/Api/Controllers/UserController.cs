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
		private readonly ILogger<UserController> _logger;

		public UserController(IUserService userService, ILogger<UserController> logger)
		{
			_userService = userService;
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

		private int? GetCurrentUserId()
		{
			var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
				?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;

			return int.TryParse(userIdClaim, out var userId) ? userId : null;
		}
	}
}

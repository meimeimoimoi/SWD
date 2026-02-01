using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SWD.Business.DTOs;
using SWD.Business.Interface;
using System.Security.Claims;

namespace SWD.Presentation.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> RegisterUser([FromBody] RegisterRequestDto registerDto)
        {
            var response = await _authService.RegisterUserAsync(registerDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return BadRequest(response);
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDto loginDto)
        {
            var response = await _authService.LoginAsync(loginDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return Unauthorized(response);
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordDto changePasswordDto)
        {
            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
            if (!Guid.TryParse(userIdString, out var userId))
            {
                return Unauthorized(ApiResponse<object>.Error("Invalid token."));
            }

            var response = await _authService.ChangePasswordAsync(userId, changePasswordDto);

            if (!response.Succeeded)
            {
                return BadRequest(response);
            }

            return Ok(response);
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto requestDto)
        {
            var response = await _authService.ForgotPasswordAsync(requestDto);
            return Ok(response);
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto requestDto)
        {
            var response = await _authService.ResetPasswordAsync(requestDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return BadRequest(response);
        }

        [HttpPost("google-login")]
        public async Task<IActionResult> LoginWithGoogle([FromBody] GoogleLoginRequestDto requestDto)
        {
            var response = await _authService.LoginWithGoogleAsync(requestDto);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return Unauthorized(response);
        }

        [HttpGet("confirm-email")]
        public async Task<IActionResult> ConfirmEmail([FromQuery] string userId, [FromQuery] string token)
        {
            var response = await _authService.ConfirmEmailAsync(userId, token);
            if (response.Succeeded)
            {
                return Ok(response);
            }
            return BadRequest(response);
        }
    }
}

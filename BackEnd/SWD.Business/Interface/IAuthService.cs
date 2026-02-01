using SWD.Business.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Interface
{
    public interface IAuthService
    {
        Task<ApiResponse<RegisterResponseDto>> RegisterUserAsync(RegisterRequestDto registerDto);
        Task<ApiResponse<LoginResponseDto>> LoginAsync(LoginRequestDto loginDto);
        Task<ApiResponse<object>> ForgotPasswordAsync(ForgotPasswordRequestDto requestDto);
        Task<ApiResponse<object>> ResetPasswordAsync(ResetPasswordRequestDto requestDto);
        Task<ApiResponse<LoginResponseDto>> LoginWithGoogleAsync(GoogleLoginRequestDto requestDto);
        Task<ApiResponse<object>> ConfirmEmailAsync(string userId, string token);
        Task<ApiResponse<object>> ChangePasswordAsync(Guid userId, ChangePasswordDto changePasswordDto);
    }
}

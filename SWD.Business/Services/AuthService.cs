using Google.Apis.Auth;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using SWD.Business.DTOs;
using SWD.Business.Interface;
using SWD.Data.Data;
using SWD.Data.Entities;
using SWD.Data.Repositories;
using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Services
{
    public class AuthService: IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly IConfiguration _configuration;
        private readonly IMessageService _messageService;
        private readonly Swd392Context _context;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            IUserRepository userRepository,
            IConfiguration configuration,
            IMessageService messageService,
            Swd392Context context,
            ILogger<AuthService> logger)
        {
            _userRepository = userRepository;
            _configuration = configuration;
            _messageService = messageService;
            _context = context;
            _logger = logger;
        }

        public async Task<ApiResponse<object>> ChangePasswordAsync(Guid userId, ChangePasswordDto changePasswordDto)
        {
            var user = await _userRepository.FindByIdAsync(userId);
            if(user == null)
            {
                return ApiResponse<object>.Error("User not found.");
            }

            if (!user.MustChangePassword)
            {
                if (string.IsNullOrWhiteSpace(changePasswordDto.OldPassword))
                {
                    return ApiResponse<object>.Error("Old password is required.");
                }

                if(!BCrypt.Net.BCrypt.Verify(changePasswordDto.OldPassword, user.PasswordHash))
                {
                    return ApiResponse<object>.Error("Old password is incorrect.");
                }
            }

            //2. Cập nhật mật khẩu mới
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(changePasswordDto.NewPassword);

            //3. Tắt cờ bắt buộc đổi mật khẩu
            user.MustChangePassword = false;

            user.UpdatedAt = DateTime.UtcNow;

            await _userRepository.UpdateUserAsync(user);
            return ApiResponse<object>.Success(null, "Password changed successfully.");
        }

        public async Task<ApiResponse<object>> ConfirmEmailAsync(string userId, string token)
        {
            if(!Guid.TryParse(userId, out var userGuid))
            {
                return ApiResponse<object>.Error("Invalid user.");
            }
            var user = await _userRepository.FindByIdAsync(userGuid);
            if (user == null || user.EmailConfirmationToken != token
                || user.ConfirmationTokenExpires < DateTime.UtcNow)
            {
                return ApiResponse<object>.Error("Invalid or expired confirmation link.");
            }

            user.EmailConfirmed = true;
            user.EmailConfirmationToken = null;
            user.ConfirmationTokenExpires = null;

            await _userRepository.UpdateUserAsync(user);
            return ApiResponse<object>.Success(null, "Email confirmed successfully. You can now login");
        }

        public async Task<ApiResponse<object>> ForgotPasswordAsync(ForgotPasswordRequestDto requestDto)
        {
            var user = await _userRepository.FindByEmailAsync(requestDto.Email);
            if(user != null)
            {
                var otp = System.Security.Cryptography.RandomNumberGenerator.GetInt32(100000, 999999).ToString("D6");   
                user.PasswordResetToken= BCrypt.Net.BCrypt.HashPassword(otp);
                user.ResetTokenExpires = DateTime.UtcNow.AddMinutes(15);
                await _userRepository.UpdateUserAsync(user);

                await _messageService.SendPasswordResetEmailAsync(user.Email, otp);
                _logger.LogInformation("Password reset email sent to {Email}", user.Email);
            }
            return ApiResponse<object>.Success(null!, "If an account exists, a reset token has been sent.");
        }

        public async Task<ApiResponse<LoginResponseDto>> LoginAsync(LoginRequestDto loginDto)
        {
            var user = await _userRepository.FindByEmailAsync(loginDto.Email);

            if(user == null || !BCrypt.Net.BCrypt.Verify(loginDto.Password, user.PasswordHash))
            {
                _logger.LogWarning("Invalid login attempt for email: {Email}", loginDto.Email);
                return ApiResponse<LoginResponseDto>.Error("Invalid email or password.");
            }

            if (!user.IsActive)
            {
                _logger.LogWarning("Login attempt for inactive account: {Email}", user.Email);
                return ApiResponse<LoginResponseDto>.Error("Account is inactive. Please contact support.");
            }

            if (!user.EmailConfirmed)
            {
                _logger.LogWarning("Login attempt for uncofirmed email: {Email}", user.Email);
                return ApiResponse<LoginResponseDto>.Error("Email is not confirmed. Please check your inbox.");
            }

            _logger.LogInformation("User logged in successfully. UserId: {UserId}, Email: {Email}", user.Id, user.Email);

            var token = await GenerateJwtTokenAsync(user);
            return ApiResponse<LoginResponseDto>.Success(new LoginResponseDto { Token = token});
        }

        public async Task<ApiResponse<LoginResponseDto>> LoginWithGoogleAsync(GoogleLoginRequestDto requestDto)
        {
            string email;
            string name = string.Empty;
            bool emailVerified = true;

            if (!string.IsNullOrEmpty(requestDto.Credential))
            {
                var validationSettings = new GoogleJsonWebSignature.ValidationSettings
                {
                    Audience = new[] { _configuration["GoogleAuthSettings:ClientId"] }
                };
                try
                {
                    var payload = await GoogleJsonWebSignature.ValidateAsync(requestDto.Credential, validationSettings);
                    email = payload.Email;
                    name = payload.Name;
                    emailVerified = payload.EmailVerified;
                }
                catch (InvalidJwtException)
                {
                    return ApiResponse<LoginResponseDto>.Error("Invalid Google token.");
                }
            }
            else if (!string.IsNullOrEmpty(requestDto.AccessToken) && !string.IsNullOrEmpty(requestDto.Email))
            {
                // Use the email and name provided from frontend
                email = requestDto.Email;
                name = requestDto.Name ?? string.Empty;
            }
            else
            {
                return ApiResponse<LoginResponseDto>.Error("Missing Google authentication information.");
            }
            // Find or create user
            var user = await _userRepository.FindByEmailAsync(email);

            if (user == null)
            {
                user = new User
                {
                    Id = Guid.NewGuid(),
                    Email = email,
                    UserName = email,
                    NormalizedEmail = email.ToUpper(),
                    NormalizedUserName = email.ToUpper(),
                    EmailConfirmed = emailVerified,
                    FirstName = name,
                    PasswordHash = "",
                    IsActive = true
                };
                await _userRepository.CreateUserWithRoleAsync(user, "Patient");
                user = await _userRepository.FindByEmailAsync(email);
            }
            if (user == null) return ApiResponse<LoginResponseDto>.Error("Failed to create or retrieve user.");

            // ✅ Check if user account is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Google login attempt for inactive account: {Email}", user.Email);
                return ApiResponse<LoginResponseDto>.Error("Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ quản trị viên.");
            }

            var token = await GenerateJwtTokenAsync(user);
            return ApiResponse<LoginResponseDto>.Success(new LoginResponseDto { Token = token });
        }

        public async Task<ApiResponse<RegisterResponseDto>> RegisterUserAsync(RegisterRequestDto registerDto)
        {
            if(await _userRepository.UserExistsByEmailAsync(registerDto.Email))
            {
                return ApiResponse<RegisterResponseDto>.Error("Email already exists.");
            }

            var passwordHash = BCrypt.Net.BCrypt.HashPassword(registerDto.Password);
            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = registerDto.Email,
                UserName = registerDto.Email,
                NormalizedEmail = registerDto.Email.ToUpper(),
                NormalizedUserName = registerDto.Email.ToUpper(),
                PasswordHash = passwordHash,
                EmailConfirmationToken = Guid.NewGuid().ToString(),
                ConfirmationTokenExpires = DateTime.UtcNow.AddHours(24)
            };

            await _userRepository.CreateUserWithRoleAsync(user, "User");
            await _messageService.SendConfirmationEmailAsync(user.Email, user.Id.ToString() ,user.EmailConfirmationToken!);

            _logger.LogInformation("User registered successfully. UserId: {UserId}, Email: {Email}", user.Id, user.Email);

            var data = new RegisterResponseDto { UserId = user.Id,
                Email = user.Email
            };
            return ApiResponse<RegisterResponseDto>.Success(data, "User registered successfully. Please check your email to confirm your account.");
        }

        public async Task<ApiResponse<object>> ResetPasswordAsync(ResetPasswordRequestDto requestDto)
        {
            var user = await _userRepository.FindByEmailAsync(requestDto.Email);
            if(user == null
                || user.PasswordResetToken == null
                || user.ResetTokenExpires < DateTime.UtcNow)
            {
                return ApiResponse<object>.Error("Invalid or expired token.");
            }

            if(!BCrypt.Net.BCrypt.Verify(requestDto.Token, user.PasswordResetToken))
            {
                return ApiResponse<object>.Error("Invalid or expired token.");
            }

            //Update password with Bcrypt hash
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(requestDto.NewPassword);
            user.PasswordResetToken = null;
            user.ResetTokenExpires = null;
            user.MustChangePassword= false;

            await _userRepository.UpdateUserAsync(user);
            return ApiResponse<object>.Success(null!, "Password has been reset successfully.");
        }

        private async Task<string> GenerateJwtTokenAsync(User user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(JwtRegisteredClaimNames.Name, user.FirstName ?? string.Empty)
            };

            foreach(var userRole in user.UserRoles)
            {
                claims.Add(new Claim(ClaimTypes.Role, userRole.Role.Name));
            }

            if (user.MustChangePassword)
            {
                claims.Add(new Claim("must_change_password", "true"));
            }

            var userRoleIds = user.UserRoles.Select(ur => ur.RoleId).ToList();

            var permissions = await _context.RolePermissions
                .Where(rp => userRoleIds.Contains(rp.RoleId))
                .Include(rp => rp.Permission)
                .Select(rp => rp.Permission.Name)
                .Distinct()
                .ToListAsync();

            foreach (var permissionName in permissions)
            {
                claims.Add(new Claim("permission", permissionName));
            }

            var token = new JwtSecurityToken(
                issuer: _configuration["Jwt:Issuer"],
                audience: _configuration["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddHours(3),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}

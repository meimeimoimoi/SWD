using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Infrastructure.Helpers;
using MyApp.Persistence.Context;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
    public class AuthService : IAuthService
    {
        private readonly UserRepository _userRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly JwtTokenGeneratior _jwtTokenGeneratior;
        private readonly AppDbContext _context;
        private readonly ILogger<AuthService> _logger;
        private readonly TimeSpan _tokenExpiration = TimeSpan.FromMinutes(30);
        private readonly TimeSpan _refreshTokenExpiration = TimeSpan.FromDays(7);
        private readonly ApiResponse _apiResponse;

        public AuthService(
            UserRepository userRepository,
            IPasswordHasher passwordHasher,
            JwtTokenGeneratior jwtTokenGeneratior,
            AppDbContext context,
            ILogger<AuthService> logger,
            ApiResponse apiResponse)
        {
            _userRepository = userRepository;
            _passwordHasher = passwordHasher;
            _jwtTokenGeneratior = jwtTokenGeneratior;
            _context = context;
            _logger = logger;
            _apiResponse = apiResponse;
        }

        public async Task<LoginResponseDTO> LoginAsync(LoginRequestDTO request)
        {
            try
            {
                var user = await _userRepository.FindByUsernameOrEmailAsync(request.UsernameOrEmail);
                await CheckUserError(user, request);

                string accessToken = _jwtTokenGeneratior.GenerateToken(user, _tokenExpiration, out string jti);
                var refreshToken = _jwtTokenGeneratior.GenerateRefreshToken(jti);

                _context.RefreshTokens.Add(refreshToken);
                await _context.SaveChangesAsync();

                return new LoginResponseDTO 
                {
                    AccessToken = accessToken,
                    RefreshToken = jti,
                    ExpiresIn = _tokenExpiration,
                    Username = user.Username,
                    Role = user.Role
                };
                
            }
            catch (UnauthorizedAccessException ex)
            {
                _logger.LogWarning(ex.Message);
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login Error");
                throw;
            }

        }

        public Task LogoutAsync(string token)
        {
            return Task.CompletedTask;
        }

        public async Task<ApiResponse> RegisterAsync(ResgisterRequestDTO request)
        {
            try
            {
                _logger.LogInformation("Registering new user: {Username}", request.Username);

                bool isUsernameTaken = await _context.Users.AnyAsync(u => u.Username == request.Username);
                if (isUsernameTaken)
                {
                    return new ApiResponse { Success = false, Message = "Tên đăng nhập đã tồn tại!" };
                }

                string emailToRegister = $"{request.Username}@temp.local";

                bool isEmailTaken = await _context.Users.AnyAsync(u => u.Email == emailToRegister);
                if (isEmailTaken)
                {
                    return new ApiResponse { Success = false, Message = "Email đã được sử dụng bởi một tài khoản khác!" };
                }

                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email ?? $"{request.Username}@myapp.com", 
                    PasswordHash = _passwordHasher.Hash(request.Password),
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    AccountStatus = "Active",
                    Role = "User"
                };

                await _userRepository.AddUserAsync(user);
                //await _context.SaveChangesAsync();

                _logger.LogInformation("User registered successfully: {Username}", user.Username);

                return new ApiResponse { Success = true, Message = "User registered successfully" };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for: {Username}", request.Username);
                return new ApiResponse { Success = false, Message = "An internal error occurred." };
            }
        }

        private async Task<Boolean> CheckUserError(User user, LoginRequestDTO request)
        {
            user = await _userRepository.FindByUsernameOrEmailAsync(request.UsernameOrEmail);

            if (user == null)
            {
                _logger.LogWarning("Login failed - User not found: {UsernameOrEmail}", request.UsernameOrEmail);
                throw new UnauthorizedAccessException("Invalid username/email or password.");
            }

            if (!_passwordHasher.verify(request.Password, user.PasswordHash))
            {
                _logger.LogWarning("Login failed - Invalid password for user: {Username}", user.Username);
                throw new UnauthorizedAccessException("Invalid username/email or password.");
            }

            if (user.AccountStatus != "Active")
            {
                _logger.LogWarning("Login failed - Account not active: {Username}, Status: {Status}",
                    user.Username, user.AccountStatus);
                throw new UnauthorizedAccessException($"Account is {user.AccountStatus}. Please contact administrator.");
            }

            return true;
        }
    }
}

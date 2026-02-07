using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
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

        public AuthService(
            UserRepository userRepository, 
            IPasswordHasher passwordHasher, 
            JwtTokenGeneratior jwtTokenGeneratior,
            AppDbContext context,
            ILogger<AuthService> logger)
        {
            _userRepository = userRepository;
            _passwordHasher = passwordHasher;
            _jwtTokenGeneratior = jwtTokenGeneratior;
            _context = context;
            _logger = logger;
        }

        public async Task<string> LoginAsync(LoginRequestDTO request)
        {
            try
            {
                _logger.LogInformation("Login attempt for: {UsernameOrEmail}", request.UsernameOrEmail);

                // Find user by username or email
                var user = await _userRepository.FindByUsernameOrEmailAsync(request.UsernameOrEmail);

                if (user == null)
                {
                    _logger.LogWarning("Login failed - User not found: {UsernameOrEmail}", request.UsernameOrEmail);
                    throw new UnauthorizedAccessException("Invalid username/email or password.");
                }

                // Verify password
                if (!_passwordHasher.verify(request.Password, user.PasswordHash))
                {
                    _logger.LogWarning("Login failed - Invalid password for user: {Username}", user.Username);
                    throw new UnauthorizedAccessException("Invalid username/email or password.");
                }

                // Check account status
                if (user.AccountStatus != "Active")
                {
                    _logger.LogWarning("Login failed - Account not active: {Username}, Status: {Status}", 
                        user.Username, user.AccountStatus);
                    throw new UnauthorizedAccessException($"Account is {user.AccountStatus}. Please contact administrator.");
                }

                // Update last login time
                user.LastLoginAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                _logger.LogInformation("Login successful for user: {Username}", user.Username);

                // Generate JWT token
                return _jwtTokenGeneratior.GenerateToken(user);
            }
            catch (UnauthorizedAccessException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login for: {UsernameOrEmail}", request.UsernameOrEmail);
                throw new Exception("An error occurred during login", ex);
            }
        }

        public Task LogoutAsync(string token)
        {
            // TODO: Implement token revocation if needed
            return Task.CompletedTask;
        }

        public async Task RegisterAsync(ResgisterRequestDTO request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                {
                    throw new ArgumentException("Username and password are required");
                }

                // Check if username already exists
                bool exists = await _context.Users.AnyAsync(u => u.Username == request.Username);
                if (exists)
                {
                    throw new InvalidOperationException("Username already exists.");
                }

                // Create new user
                var user = new User
                {
                    Username = request.Username,
                    Email = $"{request.Username}@temp.local", // Set temporary email
                    PasswordHash = _passwordHasher.Hash(request.Password),
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    AccountStatus = "Active",
                    Role = "User"
                };

                await _userRepository.AddUserAsync(user);
                
                _logger.LogInformation("User registered successfully: {Username}", user.Username);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration for: {Username}", request.Username);
                throw;
            }
        }
    }
}

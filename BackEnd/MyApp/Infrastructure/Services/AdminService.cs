using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using System.Security.Cryptography;

namespace MyApp.Infrastructure.Services
{
    public class AdminService : IAdminService
    {
        private readonly UserRepository _userRepository;
        private readonly IPasswordHasher _passwordHasher;
        private readonly IMessageService _messageService;
        private readonly ILogger<AdminService> _logger;

        public AdminService(
            UserRepository userRepository, 
            IPasswordHasher passwordHasher,
            IMessageService messageService,
            ILogger<AdminService> logger)
        {
            _userRepository = userRepository;
            _passwordHasher = passwordHasher;
            _messageService = messageService;
            _logger = logger;
        }

        public async Task<List<UserDto>> GetAllUsersAsync(string? search = null, string? role = null, string? sortBy = "email", string? sortOrder = "asc")
        {
            try
            {
                var query = _userRepository.GetAllUsersQuery();

                // Apply search filter
                if (!string.IsNullOrWhiteSpace(search))
                {
                    query = query.Where(u => 
                        u.Username.Contains(search) || 
                        u.Email.Contains(search) ||
                        (u.FirstName != null && u.FirstName.Contains(search)) ||
                        (u.LastName != null && u.LastName.Contains(search)));
                }

                // Apply role filter
                if (!string.IsNullOrWhiteSpace(role))
                {
                    query = query.Where(u => u.Role == role);
                }

                // Apply sorting
                query = sortBy?.ToLower() switch
                {
                    "username" => sortOrder?.ToLower() == "desc" 
                        ? query.OrderByDescending(u => u.Username) 
                        : query.OrderBy(u => u.Username),
                    "email" => sortOrder?.ToLower() == "desc" 
                        ? query.OrderByDescending(u => u.Email) 
                        : query.OrderBy(u => u.Email),
                    "role" => sortOrder?.ToLower() == "desc" 
                        ? query.OrderByDescending(u => u.Role) 
                        : query.OrderBy(u => u.Role),
                    "createdat" => sortOrder?.ToLower() == "desc" 
                        ? query.OrderByDescending(u => u.CreatedAt) 
                        : query.OrderBy(u => u.CreatedAt),
                    _ => query.OrderBy(u => u.Email)
                };

                var users = await query.ToListAsync();

                // Map to DTOs and return full list
                var userDtos = users.Select(u => new UserDto
                {
                    UserId = u.UserId,
                    Username = u.Username,
                    Email = u.Email,
                    FirstName = u.FirstName,
                    LastName = u.LastName,
                    Phone = u.Phone,
                    ProfileImagePath = u.ProfileImagePath,
                    Role = u.Role
                }).ToList();

                _logger.LogInformation("Retrieved {Count} users", userDtos.Count);
                
                return userDtos;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all users");
                throw;
            }
        }

        public async Task<UserDto?> GetUserByIdAsync(int userId)
        {
            try
            {
                var user = await _userRepository.FindByIdAsync(userId);
                
                if (user == null)
                    return null;

                return new UserDto
                {
                    UserId = user.UserId,
                    Username = user.Username,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Phone = user.Phone,
                    ProfileImagePath = user.ProfileImagePath,
                    Role = user.Role
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user by ID: {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> UpdateUserAsync(int userId, UpdateUserDto updateDto)
        {
            try
            {
                var user = await _userRepository.FindByIdAsync(userId);
                
                if (user == null)
                    return false;

                // Update fields if provided
                if (!string.IsNullOrWhiteSpace(updateDto.Email))
                {
                    // Check if email already exists for another user
                    var existingUser = await _userRepository.FindByEmail(updateDto.Email);
                    if (existingUser != null && existingUser.UserId != userId)
                    {
                        throw new InvalidOperationException("Email already exists");
                    }
                    user.Email = updateDto.Email;
                }

                if (updateDto.FirstName != null)
                    user.FirstName = updateDto.FirstName;

                if (updateDto.LastName != null)
                    user.LastName = updateDto.LastName;

                if (updateDto.Phone != null)
                    user.Phone = updateDto.Phone;

                if (updateDto.ProfileImagePath != null)
                    user.ProfileImagePath = updateDto.ProfileImagePath;

                if (!string.IsNullOrWhiteSpace(updateDto.Role))
                    user.Role = updateDto.Role;

                user.UpdatedAt = DateTime.UtcNow;

                await _userRepository.UpdateUserAsync(user);
                
                _logger.LogInformation("User {UserId} updated successfully", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user: {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> UpdateUserStatusAsync(int userId, string status)
        {
            try
            {
                var user = await _userRepository.FindByIdAsync(userId);
                
                if (user == null)
                    return false;

                user.AccountStatus = status;
                user.UpdatedAt = DateTime.UtcNow;

                await _userRepository.UpdateUserAsync(user);
                
                _logger.LogInformation("User {UserId} status updated to {Status}", userId, status);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user status: {UserId}", userId);
                throw;
            }
        }

        public async Task<UserDto> CreateStaffUserAsync(CreateTechnicianStaffDto createDto)
        {
            try
            {
                // Validate username doesn't exist
                if (await _userRepository.ExistByUsernameAsync(createDto.Username))
                {
                    throw new InvalidOperationException($"Username '{createDto.Username}' already exists");
                }

                // Validate email doesn't exist
                var existingEmail = await _userRepository.FindByEmail(createDto.Email);
                if (existingEmail != null)
                {
                    throw new InvalidOperationException($"Email '{createDto.Email}' already exists");
                }

                // Auto-generate secure password using BCryptPasswordHasher
                string temporaryPassword = _passwordHasher.GenerateRandomPassword(12);
                
                _logger.LogInformation("Creating staff user: {Username}, Auto-generated password", createDto.Username);
                
                // Create new user
                var user = new User
                {
                    Username = createDto.Username,
                    Email = createDto.Email,
                    PasswordHash = _passwordHasher.Hash(temporaryPassword),
                    FirstName = createDto.FirstName,
                    LastName = createDto.LastName,
                    Phone = createDto.Phone,
                    Role = createDto.Role,
                    AccountStatus = "Active",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _userRepository.CreateTechnicianStaff(user, createDto.Role);

                // Generate confirmation token
                string confirmationToken = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));

                // Send welcome email with auto-generated credentials
                await _messageService.SendAccountCreatedByStaffEmailAsync(
                    user.Email,
                    user.FirstName ?? user.Username,
                    temporaryPassword,
                    user.UserId,
                    confirmationToken
                );

                _logger.LogInformation("Staff/Technician user created: {Username}, Role: {Role}, Email sent with auto-generated password", 
                    user.Username, user.Role);

                return new UserDto
                {
                    UserId = user.UserId,
                    Username = user.Username,
                    Email = user.Email,
                    FirstName = user.FirstName,
                    LastName = user.LastName,
                    Phone = user.Phone,
                    ProfileImagePath = user.ProfileImagePath,
                    Role = user.Role
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating staff user");
                throw;
            }
        }

        public async Task<bool> DeleteUserAsync(int userId)
        {
            try
            {
                var user = await _userRepository.FindByIdAsync(userId);
                
                if (user == null)
                {
                    _logger.LogWarning("Delete failed - User not found: {UserId}", userId);
                    return false;
                }

                if (user.Role == "Admin")
                {
                    _logger.LogWarning("Delete failed - Cannot delete Admin user: {UserId}, Username: {Username}", 
                        userId, user.Username);
                    throw new InvalidOperationException("Cannot delete Admin user. Admin accounts are protected.");
                }

                user.AccountStatus = "Deleted";
                user.UpdatedAt = DateTime.UtcNow;
                await _userRepository.UpdateUserAsync(user);

                _logger.LogInformation("User soft-deleted successfully: {UserId}, Username: {Username}", 
                    userId, user.Username);
                
                return true;
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user: {UserId}", userId);
                throw;
            }
        }
    }
}

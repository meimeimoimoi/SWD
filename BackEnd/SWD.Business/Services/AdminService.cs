using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SWD.Business.DTOs;
using SWD.Business.Interface;
using SWD.Data.Data;
using SWD.Data.Entities;
using SWD.Data.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SWD.Business.Services
{
    public class AdminService : IAdminService
    {
        private readonly IUserRepository _userRepository;
        private readonly Swd392Context _context;
        private readonly IMessageService _messageService;
        private readonly ILogger<AdminService> _logger;

        public AdminService(IUserRepository userRepository, Swd392Context context, IMessageService messageService, ILogger<AdminService> logger)
        {
            _userRepository = userRepository;
            _context = context;
            _messageService = messageService;
            _logger = logger;
        }

        public async Task<ApiResponse<object>> CreateStaffUserAsync(CreateStaffUserDto createDto)
        {
            if (await _userRepository.UserExistsByEmailAsync(createDto.Email))
            {
                return ApiResponse<object>.Error("Email already exists.");
            }

            var role = await _context.Roles.FirstOrDefaultAsync(r => r.Name == createDto.RoleName);
            if(role == null)
            {
                return ApiResponse<object>.Error($"Role '{createDto.RoleName}' does not exist.");
            }

            var temporaryPassword = GenerateRandomPassword();
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(temporaryPassword);

            var user = new User
            {
                Id = Guid.NewGuid(),
                Email = createDto.Email,
                UserName = createDto.Email,
                NormalizedEmail = createDto.Email.ToUpper(),
                NormalizedUserName = createDto.Email.ToUpper(),

                FirstName = createDto.FirstName,
                LastName = createDto.LastName,

                PasswordHash = passwordHash,
                EmailConfirmed = true,
                IsActive = true,
                MustChangePassword = true
            };

            await _userRepository.CreateUserWithRoleAsync(user, role.Name);
            await _messageService.SendWelcomeEmailWithPasswordAsync(user.Email, temporaryPassword);
            return ApiResponse<object>.Success(null, "Staff user created successfully.");

        }

        public async Task<ApiResponse<PagedResult<UserDto>>> GetAllUsersAsync(
            int page, 
            int pageSize, 
            string? search = null, 
            string? role = null, 
            string? sortBy = "email", 
            string? sortOrder = "asc")
        {
            // Validate pagination parameters
            if (page < 1)
                return ApiResponse<PagedResult<UserDto>>.Error("Page number must be greater than 0.");
            if (pageSize < 1 || pageSize > 100)
                return ApiResponse<PagedResult<UserDto>>.Error("Page size must be between 1 and 100.");

            var (users, totalCount) = await _userRepository.GetAllPaginatedAsync(page, pageSize, search, role, sortBy, sortOrder);

            var userDtos = users.Select(u => new UserDto
            {
                Id = u.Id,
                Email = u.Email,
                FirstName = u.FirstName,
                LastName = u.LastName,
                FullName = $"{u.FirstName ?? ""} {u.LastName ?? ""}".Trim(),
                IsActive = u.IsActive,
                EmailConfirmed = u.EmailConfirmed,
                CreatedAt = u.CreatedAt,
                Roles = u.UserRoles.Select(ur => ur.Role.Name).ToList()
            }).ToList();

            var pagedResult = new PagedResult<UserDto>
            {
                Items = userDtos,
                TotalCount = totalCount,
                PageNumber = page,
                PageSize = pageSize
            };

            return ApiResponse<PagedResult<UserDto>>.Success(pagedResult);
        }

        public async Task<ApiResponse<UserDto>> GetUserByIdAsync(Guid userId)
        {
            var user = await _userRepository.FindByIdAsync(userId);
            if (user == null)
            {
                return ApiResponse<UserDto>.Error("User not found.");
            }
            var userDto = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                FullName = $"{user.FirstName ?? ""} {user.LastName ?? ""}".Trim(),
                IsActive = user.IsActive,
                EmailConfirmed = user.EmailConfirmed,
                CreatedAt = user.CreatedAt,
                Roles = user.UserRoles.Select(ur => ur.Role.Name).ToList()
            };
            return ApiResponse<UserDto>.Success(userDto);
        }

        public async Task<ApiResponse<object>> UpdateUserAsync(Guid userId, UpdateUserDto updateDto)
        {
            var user = await _userRepository.FindByIdAsync(userId);
            if(user == null)
            {
                return ApiResponse<object>.Error("User not found.");
            }

            if (!string.IsNullOrWhiteSpace(updateDto.FirstName))
            {
                user.FirstName = updateDto.FirstName;
            }

            if (!string.IsNullOrWhiteSpace(updateDto.LastName))
            {
                user.LastName = updateDto.LastName;
            }
            user.IsActive = updateDto.IsActive; 
            user.UpdatedAt = DateTime.Now;

            await _userRepository.UpdateUserAsync(user);
            return ApiResponse<object>.Success(null!, "User updated successfully.");
        }

        public async Task<ApiResponse<object>> UpdateUserStatusAsync(Guid userId, UpdateUserStatusDto statusDto)
        {
            var user = await _userRepository.FindByIdAsync(userId);
            if (user == null)
            {
                return ApiResponse<object>.Error("User not found.");
            }
            user.IsActive = statusDto.IsActive;
            await _userRepository.UpdateUserAsync(user);
            return ApiResponse<object>.Success(null!, "User status updated successfully.");
        }

        private string GenerateRandomPassword(int length = 12)
        {
            const string validChars = "ABCDEFGHJKLMNOPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz0123456789!@#$%^&*?";
            var bytes = new byte[length];
            System.Security.Cryptography.RandomNumberGenerator.Fill(bytes);
            var chars = new char[length];
            for (int i = 0; i < length; i++)
            {
                chars[i] = validChars[bytes[i] % validChars.Length];
            }
            return new string(chars);
        }
    }
}

using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services
{
	public class UserService : IUserService
	{
		private readonly UserRepository _userRepository;
		private readonly ILogger<UserService> _logger;

		public UserService(UserRepository userRepository, ILogger<UserService> logger)
		{
			_userRepository = userRepository;
			_logger = logger;
		}

		public async Task<UserDto?> GetProfileUserAsync(int userId)
		{
			try
			{
				var user = await _userRepository.FindByIdAsync(userId);
				if (user == null)
				{
					return null;
				}

				return new UserDto
				{
					UserId = user.UserId,
					Username = user.Username,
					Email = user.Email,
					FirstName = user.FirstName,
					LastName = user.LastName,
					Phone = user.Phone,
					ProfileImagePath = user.ProfileImagePath,
					LastLoginAt = user.LastLoginAt,
					Role = user.Role
				};
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error getting profile for user {UserId}", userId);
				throw;
			}
		}

		public async Task<bool> UpdateProfileAsync(int userId, UpdateProfileDto updateDto)
		{
			try
			{
				var user = await _userRepository.FindByIdAsync(userId);
				if (user == null)
				{
					return false;
				}

				if (!string.IsNullOrWhiteSpace(updateDto.Email))
				{
					var existingUser = await _userRepository.FindByEmail(updateDto.Email);
					if (existingUser != null && existingUser.UserId != userId)
					{
						throw new InvalidOperationException("Email already exists");
					}

					user.Email = updateDto.Email;
				}

				if (updateDto.FirstName != null)
				{
					user.FirstName = updateDto.FirstName;
				}

				if (updateDto.LastName != null)
				{
					user.LastName = updateDto.LastName;
				}

				if (updateDto.Phone != null)
				{
					user.Phone = updateDto.Phone;
				}

				if (updateDto.ProfileImagePath != null)
				{
					user.ProfileImagePath = updateDto.ProfileImagePath;
				}

				user.UpdatedAt = DateTime.UtcNow;

				await _userRepository.UpdateUserAsync(user);
				_logger.LogInformation("Updated profile for user {UserId}", userId);

				return true;
			}
			catch (Exception ex)
			{
				_logger.LogError(ex, "Error updating profile for user {UserId}", userId);
				throw;
			}
		}
	}
}

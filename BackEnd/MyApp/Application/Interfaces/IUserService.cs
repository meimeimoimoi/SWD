using MyApp.Application.Features.Users.DTOs;
using MyApp.Domain.Entities;

namespace MyApp.Application.Interfaces
{
	public interface IUserService
	{
		Task<UserDto?> GetProfileUserAsync(int userId);
		Task<bool> UpdateProfileAsync(int userId, UpdateProfileDto updateDto);
		Task<List<Notification>> GetUserNotificationsAsync(int userId);
		Task<List<ActivityLog>> GetUserActivitiesAsync(int userId);
		Task<bool> LogActivityAsync(int userId, string action, string entityName, string? entityId = null, string? description = null);
	}
}

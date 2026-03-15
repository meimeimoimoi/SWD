using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
	public interface IUserService
	{
		Task<UserDto?> GetProfileUserAsync(int userId);
		Task<bool> UpdateProfileAsync(int userId, UpdateProfileDto updateDto);
	}
}

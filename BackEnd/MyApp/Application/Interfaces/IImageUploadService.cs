using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IImageUploadService
    {
        Task<ImageUploadResponseDto> UploadImageAsync(int userId, IFormFile imageFile);
        Task<ImageUploadResponseDto?> GetImageByIdAsync(int uploadId);
        Task<List<ImageUploadResponseDto>> GetUserImagesAsync(int userId);
        Task<byte[]?> GetImageBytesAsync(int uploadId);
    }
}

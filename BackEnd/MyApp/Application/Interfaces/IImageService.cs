using MyApp.Application.Features.Users.DTOs;

namespace MyApp.Application.Interfaces
{
    public interface IImageService
    {
        Task<ImageUploadResponseDto> UploadImageAsync(int userId, IFormFile imageFile);
        Task<ImageUploadResponseDto?> GetImageByIdAsync(int uploadId);
        Task<List<ImageUploadResponseDto>> GetUserImagesAsync(int userId);
        Task<bool> DeleteImageAsync(int uploadId, int userId);
        Task<byte[]?> GetImageBytesAsync(int uploadId);
    }
}

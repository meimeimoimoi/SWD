using MyApp.Application.Features.Users.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace MyApp.Infrastructure.Services
{
    public class ImageUploadService : IImageUploadService
    {
        private readonly ImageUploadRepository _imageUploadRepository;
        private readonly ILogger<ImageUploadService> _logger;

        // Allowed image types
        private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp" };
        private readonly string[] _allowedMimeTypes = { "image/jpeg", "image/png", "image/gif", "image/bmp" };
        private const long MaxFileSize = 10 * 1024 * 1024; // 10 MB

        public ImageUploadService(
            ImageUploadRepository imageUploadRepository,
            ILogger<ImageUploadService> logger)
        {
            _imageUploadRepository = imageUploadRepository;
            _logger = logger;
        }

        public async Task<ImageUploadResponseDto> UploadImageAsync(int userId, IFormFile imageFile)
        {
            try
            {
                // Validate file
                ValidateImageFile(imageFile);

                _logger.LogInformation("Processing image for user {UserId}: {FileName}", userId, imageFile.FileName);

                // Đọc metadata (width, height) từ stream, không lưu file
                int width = 0, height = 0;
                using (var stream = imageFile.OpenReadStream())
                using (var image = await Image.LoadAsync(stream))
                {
                    width = image.Width;
                    height = image.Height;
                }

                // Chỉ lưu metadata vào DB, không lưu file vật lý
                var imageUpload = new ImageUpload
                {
                    UserId = userId,
                    OriginalFilename = imageFile.FileName,
                    StoredFilename = null,
                    FilePath = null,
                    FileSize = imageFile.Length,
                    MimeType = imageFile.ContentType,
                    ImageWidth = width,
                    ImageHeight = height,
                    UploadStatus = "Pending",
                    UploadedAt = DateTime.UtcNow
                };

                var savedImage = await _imageUploadRepository.AddImageAsync(imageUpload);

                _logger.LogInformation(
                    "Image metadata saved to DB: UploadId={UploadId}, Size={FileSize}KB",
                    savedImage.UploadId, imageFile.Length / 1024);

                return MapToDto(savedImage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing image for user {UserId}", userId);
                throw;
            }
        }

        public async Task<ImageUploadResponseDto?> GetImageByIdAsync(int uploadId)
        {
            var image = await _imageUploadRepository.GetImageByIdAsync(uploadId);
            return image != null ? MapToDto(image) : null;
        }

        public async Task<List<ImageUploadResponseDto>> GetUserImagesAsync(int userId)
        {
            var images = await _imageUploadRepository.GetImagesByUserIdAsync(userId);
            return images.Select(MapToDto).ToList();
        }

        public async Task<byte[]?> GetImageBytesAsync(int uploadId)
        {
            _logger.LogWarning("GetImageBytesAsync called but images are no longer stored on disk. UploadId={UploadId}", uploadId);
            return null;
        }

        private void ValidateImageFile(IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("File is empty or null");

            if (file.Length > MaxFileSize)
                throw new ArgumentException($"File size exceeds the maximum allowed size of {MaxFileSize / (1024 * 1024)}MB");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!_allowedExtensions.Contains(extension))
                throw new ArgumentException($"File type '{extension}' is not allowed. Allowed types: {string.Join(", ", _allowedExtensions)}");

            if (!_allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
                throw new ArgumentException($"MIME type '{file.ContentType}' is not allowed");
        }

        private ImageUploadResponseDto MapToDto(ImageUpload image)
        {
            return new ImageUploadResponseDto
            {
                UploadId = image.UploadId,
                UserId = image.UserId,
                OriginalFilename = image.OriginalFilename,
                StoredFilename = image.StoredFilename,
                FilePath = image.FilePath,
                FileSize = image.FileSize,
                MimeType = image.MimeType,
                ImageWidth = image.ImageWidth,
                ImageHeight = image.ImageHeight,
                UploadStatus = image.UploadStatus,
                UploadedAt = image.UploadedAt
            };
        }
    }
}

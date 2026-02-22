using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class ImageUploadRepository
    {
        private readonly AppDbContext _context;

        public ImageUploadRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<ImageUpload> AddImageAsync(ImageUpload imageUpload)
        {
            _context.ImageUploads.Add(imageUpload);
            await _context.SaveChangesAsync();
            return imageUpload;
        }

        public async Task<ImageUpload?> GetImageByIdAsync(int uploadId)
        {
            return await _context.ImageUploads
                .Include(i => i.User)
                .FirstOrDefaultAsync(i => i.UploadId == uploadId);
        }

        public async Task<List<ImageUpload>> GetImagesByUserIdAsync(int userId)
        {
            return await _context.ImageUploads
                .Where(i => i.UserId == userId)
                .OrderByDescending(i => i.UploadedAt)
                .ToListAsync();
        }

    }
}

using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories;

public class ImageRepository
{
    private readonly AppDbContext _context;

    public ImageRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<ImageUpload?> GetImageUploadByIdAsync(int uploadId)
    {
        return await _context.ImageUploads
            .FirstOrDefaultAsync(i => i.UploadId == uploadId);
    }

    public async Task<ProcessedImage?> GetProcessedImageByUploadIdAsync(int uploadId)
    {
        return await _context.ProcessedImages
            .FirstOrDefaultAsync(p => p.UploadId == uploadId);
    }

    public async Task<ProcessedImage> CreateProcessedImageAsync(ProcessedImage processedImage)
    {
        _context.ProcessedImages.Add(processedImage);
        await _context.SaveChangesAsync();
        return processedImage;
    }

    public async Task<Prediction> CreatePredictionAsync(Prediction prediction)
    {
        _context.Predictions.Add(prediction);
        await _context.SaveChangesAsync();
        return prediction;
    }

    public async Task<List<Prediction>> GetPredictionsByUploadIdAsync(int uploadId)
    {
        return await _context.Predictions
            .Include(p => p.ModelVersion)
            .Include(p => p.Tree)
            .Include(p => p.Illness)
            .Where(p => p.UploadId == uploadId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();
    }

    public async Task<Prediction?> GetPredictionByIdAsync(int predictionId)
    {
        return await _context.Predictions
            .Include(p => p.ModelVersion)
            .Include(p => p.Tree)
            .Include(p => p.Illness)
            .Include(p => p.Upload)
            .FirstOrDefaultAsync(p => p.PredictionId == predictionId);
    }

    public async Task<List<Prediction>> GetPredictionHistoryAsync(int? userId = null, DateTime? fromDate = null, DateTime? toDate = null)
    {
        var query = _context.Predictions
            .Include(p => p.Tree)
            .Include(p => p.Illness)
            .Include(p => p.Upload)
            .Include(p => p.ModelVersion)
            .AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(p => p.Upload.UserId == userId.Value);
        }

        if (fromDate.HasValue)
        {
            query = query.Where(p => p.CreatedAt >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            query = query.Where(p => p.CreatedAt <= toDate.Value);
        }

        return await query
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync();
    }
}

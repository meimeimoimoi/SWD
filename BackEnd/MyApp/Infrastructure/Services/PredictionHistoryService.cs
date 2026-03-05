using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class PredictionHistoryService : IPredictionHistoryService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<PredictionHistoryService> _logger;

        public PredictionHistoryService(AppDbContext context, ILogger<PredictionHistoryService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<PredictionHistoryDto>> GetUserHistoryAsync(int userId)
        {
            _logger.LogInformation("Fetching prediction history for UserId={UserId}", userId);

            var predictions = await _context.Predictions
                .Include(p => p.Upload)
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .Where(p => p.Upload.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            _logger.LogInformation(
                "Found {Count} prediction records for UserId={UserId}", predictions.Count, userId);

            return predictions.Select(p => new PredictionHistoryDto
            {
                PredictionId = p.PredictionId,
                UploadId = p.UploadId,
                ImageUrl = p.Upload.StoredFilename,
                OriginalFilename = p.Upload.OriginalFilename,
                PredictedClass = p.PredictedClass,
                ConfidenceScore = p.ConfidenceScore,
                ProcessingTimeMs = p.ProcessingTimeMs,
                CreatedAt = p.CreatedAt,
                IllnessName = p.Illness?.IllnessName,
                IllnessSeverity = p.Illness?.Severity,
                TreeName = p.Tree?.TreeName
            }).ToList();
        }
    }
}

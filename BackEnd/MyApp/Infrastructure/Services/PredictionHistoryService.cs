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

            return predictions.Select(MapToDto).ToList();
        }

        public async Task<PredictionHistoryDto?> GetPredictionByIdAsync(int predictionId, int userId)
        {
            _logger.LogInformation(
                "Fetching prediction PredictionId={PredictionId} for UserId={UserId}",
                predictionId, userId);

            var prediction = await _context.Predictions
                .Include(p => p.Upload)
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .FirstOrDefaultAsync(p => p.PredictionId == predictionId && p.Upload.UserId == userId);

            return prediction == null ? null : MapToDto(prediction);
        }

        public async Task<List<PredictionHistoryDto>> GetAllHistoryAsync()
        {
            _logger.LogInformation("Fetching all prediction history (admin)");

            var predictions = await _context.Predictions
                .Include(p => p.Upload)
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            _logger.LogInformation("Found {Count} total prediction records", predictions.Count);

            return predictions.Select(MapToDto).ToList();
        }


        private static PredictionHistoryDto MapToDto(Domain.Entities.Prediction p) => new()
        {
            PredictionId       = p.PredictionId,
            UploadId           = p.UploadId,
            ImageUrl           = p.Upload?.StoredFilename,
            OriginalFilename   = p.Upload?.OriginalFilename,
            PredictedClass     = p.PredictedClass,
            ConfidenceScore    = p.ConfidenceScore,
            ProcessingTimeMs   = p.ProcessingTimeMs,
            CreatedAt          = p.CreatedAt,
            IllnessName        = p.Illness?.IllnessName,
            IllnessSeverity    = p.Illness?.Severity,
            IllnessId          = p.IllnessId,
            ScientificName     = p.Illness?.ScientificName,
            IllnessDescription = p.Illness?.Description,
            Symptoms           = p.Illness?.Symptoms,
            Causes             = p.Illness?.Causes,
            TreeId             = p.TreeId,
            TreeName           = p.Tree?.TreeName,
            TreeScientificName = p.Tree?.ScientificName,
            TreeDescription    = p.Tree?.Description,
            TreeImagePath      = p.Tree?.ImagePath
        };
    }
}

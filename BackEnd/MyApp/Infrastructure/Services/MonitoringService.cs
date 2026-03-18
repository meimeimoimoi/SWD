using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Infrastructure.Services
{
    public class MonitoringService : IMonitoringService
    {
        private readonly AppDbContext _context;
        private readonly ILogger<MonitoringService> _logger;

        public MonitoringService(AppDbContext context, ILogger<MonitoringService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<DashboardStatsDto> GetDashboardStatsAsync()
        {
            _logger.LogInformation("Fetching dashboard stats.");
            var today = DateTime.UtcNow.Date;

            var totalUsers       = await _context.Users.CountAsync();
            var activeUsers      = await _context.Users.CountAsync(u => u.AccountStatus == "Active");
            var totalPredictions = await _context.Predictions.CountAsync();
            var todayPredictions = await _context.Predictions.CountAsync(p => p.CreatedAt >= today);
            var totalModels      = await _context.ModelVersions.CountAsync();
            var activeModels     = await _context.ModelVersions.CountAsync(m => m.IsActive == true);

            return new DashboardStatsDto
            {
                TotalUsers       = totalUsers,
                ActiveUsers      = activeUsers,
                TotalPredictions = totalPredictions,
                TodayPredictions = todayPredictions,
                TotalModels      = totalModels,
                ActiveModels     = activeModels
            };
        }

        public async Task<PredictionStatsDto> GetPredictionStatsAsync(int days = 7)
        {
            _logger.LogInformation("Fetching prediction stats for last {Days} days.", days);
            var since = DateTime.UtcNow.Date.AddDays(-days + 1);
            var today = DateTime.UtcNow.Date;

            var allPredictions = await _context.Predictions.ToListAsync();
            var recentPredictions = allPredictions
                .Where(p => p.CreatedAt >= since)
                .ToList();

            var avgConfidence = allPredictions.Any()
                ? (double)allPredictions
                    .Where(p => p.ConfidenceScore.HasValue)
                    .Average(p => p.ConfidenceScore!.Value)
                : 0;

            // Class distribution
            var classGroups = allPredictions
                .Where(p => p.PredictedClass != null)
                .GroupBy(p => p.PredictedClass!)
                .Select(g => new ClassDistributionDto
                {
                    ClassName  = g.Key,
                    Count      = g.Count(),
                    Percentage = allPredictions.Count == 0 ? 0
                        : Math.Round((double)g.Count() / allPredictions.Count * 100, 2)
                })
                .OrderByDescending(x => x.Count)
                .ToList();

            // Daily trend
            var dailyTrend = Enumerable.Range(0, days)
                .Select(i => since.AddDays(i))
                .Select(date => new DailyPredictionDto
                {
                    Date  = date.ToString("yyyy-MM-dd"),
                    Count = recentPredictions.Count(p =>
                        p.CreatedAt.HasValue && p.CreatedAt.Value.Date == date)
                })
                .ToList();

            return new PredictionStatsDto
            {
                TotalPredictions  = allPredictions.Count,
                TodayPredictions  = allPredictions.Count(p => p.CreatedAt >= today),
                AverageConfidence = Math.Round(avgConfidence, 4),
                ClassDistribution = classGroups,
                DailyTrend        = dailyTrend
            };
        }

        public async Task<List<ModelAccuracyDto>> GetModelAccuracyAsync()
        {
            _logger.LogInformation("Fetching model accuracy stats.");

            var models = await _context.ModelVersions
                .Include(m => m.Predictions)
                    .ThenInclude(p => p.Ratings)
                .ToListAsync();

            return models.Select(m =>
            {
                var preds = m.Predictions.ToList();
                var allRatings = preds.SelectMany(p => p.Ratings).ToList();
                var positiveRatings = allRatings.Count(r =>
                    r.Rating1 != null &&
                    r.Rating1.Equals("positive", StringComparison.OrdinalIgnoreCase));

                var avgConf = preds.Any(p => p.ConfidenceScore.HasValue)
                    ? (double)preds
                        .Where(p => p.ConfidenceScore.HasValue)
                        .Average(p => p.ConfidenceScore!.Value)
                    : 0;

                return new ModelAccuracyDto
                {
                    ModelVersionId     = m.ModelVersionId,
                    ModelName          = m.ModelName,
                    Version            = m.Version,
                    IsActive           = m.IsActive,
                    IsDefault          = m.IsDefault,
                    TotalPredictions   = preds.Count,
                    AverageConfidence  = Math.Round(avgConf, 4),
                    PositiveRatingRate = allRatings.Count == 0 ? 0
                        : Math.Round((double)positiveRatings / allRatings.Count * 100, 2)
                };
            }).ToList();
        }

        public async Task<List<RatingDto>> GetRatingsAsync(int page = 1, int pageSize = 20)
        {
            _logger.LogInformation("Fetching ratings - page={Page}, size={Size}", page, pageSize);

            var ratings = await _context.Ratings
                .Include(r => r.Prediction)
                .OrderByDescending(r => r.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return ratings.Select(r => new RatingDto
            {
                RatingId        = r.RatingId,
                PredictionId    = r.PredictionId,
                PredictedClass  = r.Prediction?.PredictedClass,
                ConfidenceScore = r.Prediction?.ConfidenceScore,
                RatingValue     = r.Rating1,
                Comment         = r.Comment,
                CreatedAt       = r.CreatedAt
            }).ToList();
        }

        public async Task<List<ActivityLog>> GetActivityLogsAsync(int count = 50)
        {
            _logger.LogInformation("Fetching recent activity logs (count={Count}).", count);
            return await _context.ActivityLogs
                .Include(a => a.User)
                .OrderByDescending(a => a.CreatedAt)
                .Take(count)
                .ToListAsync();
        }
    }
}

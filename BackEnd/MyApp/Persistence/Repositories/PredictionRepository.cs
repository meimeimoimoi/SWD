using Microsoft.EntityFrameworkCore;
using MyApp.Application.Features.Users.DTOs;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class PredictionRepository
    {
        private readonly AppDbContext _context;

        public PredictionRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<Prediction?> GetPredictionByUploadIdAsync(int uploadId)
        {
            return await _context.Predictions
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .Include(p => p.ModelVersion)
                .Include(p => p.Upload)
                .FirstOrDefaultAsync(p => p.UploadId == uploadId);
        }

        public async Task<List<Prediction>> GetPredictionsByUserIdAsync(int userId)
        {
            return await _context.Predictions
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .Include(p => p.ModelVersion)
                .Include(p => p.Upload)
                    .ThenInclude(u => u.User)
                .Where(p => p.Upload.UserId == userId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<Prediction> AddPredictionAsync(Prediction prediction)
        {
            _context.Predictions.Add(prediction);
            await _context.SaveChangesAsync();
            return prediction;
        }

        public async Task<Prediction?> GetPredictionByIdAsync(int predictionId)
        {
            return await _context.Predictions
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .Include(p => p.ModelVersion)
                .Include(p => p.Upload)
                .FirstOrDefaultAsync(p => p.PredictionId == predictionId);
        }

        public async Task<(List<Prediction> predictions, int totalCount)> GetFilteredPredictionsByUserIdAsync(
            int userId,
            PredictionFilterRequestDto filter)
        {
            var query = _context.Predictions
                .Include(p => p.Illness)
                .Include(p => p.Tree)
                .Include(p => p.ModelVersion)
                .Include(p => p.Upload)
                    .ThenInclude(u => u.User)
                .Where(p => p.Upload.UserId == userId)
                .AsQueryable();

            // --- Tìm kiếm theo tên bệnh ---
            if (!string.IsNullOrWhiteSpace(filter.IllnessName))
            {
                var keyword = filter.IllnessName.Trim().ToLower();
                query = query.Where(p =>
                    p.Illness != null &&
                    p.Illness.IllnessName != null &&
                    p.Illness.IllnessName.ToLower().Contains(keyword));
            }

            // --- Lọc theo IllnessId ---
            if (filter.IllnessId.HasValue)
                query = query.Where(p => p.IllnessId == filter.IllnessId.Value);

            // --- Lọc theo Severity ---
            if (!string.IsNullOrWhiteSpace(filter.Severity))
            {
                var severity = filter.Severity.Trim().ToLower();
                query = query.Where(p =>
                    p.Illness != null &&
                    p.Illness.Severity != null &&
                    p.Illness.Severity.ToLower() == severity);
            }

            // --- Lọc theo ConfidenceScore ---
            if (filter.MinConfidence.HasValue)
                query = query.Where(p => p.ConfidenceScore >= filter.MinConfidence.Value);

            if (filter.MaxConfidence.HasValue)
                query = query.Where(p => p.ConfidenceScore <= filter.MaxConfidence.Value);

            // --- Lọc theo khoảng thời gian ---
            if (filter.DateFrom.HasValue)
                query = query.Where(p => p.CreatedAt >= filter.DateFrom.Value);

            if (filter.DateTo.HasValue)
                query = query.Where(p => p.CreatedAt <= filter.DateTo.Value.AddDays(1).AddTicks(-1));

            // --- Đếm tổng trước khi phân trang ---
            var totalCount = await query.CountAsync();

            // --- Sắp xếp ---
            query = (filter.SortBy?.ToLower(), filter.SortOrder?.ToLower()) switch
            {
                ("confidence", "asc")    => query.OrderBy(p => p.ConfidenceScore),
                ("confidence", _)        => query.OrderByDescending(p => p.ConfidenceScore),
                ("illnessname", "asc")   => query.OrderBy(p => p.Illness != null ? p.Illness.IllnessName : null),
                ("illnessname", _)       => query.OrderByDescending(p => p.Illness != null ? p.Illness.IllnessName : null),
                ("severity", "asc")      => query.OrderBy(p => p.Illness != null ? p.Illness.Severity : null),
                ("severity", _)          => query.OrderByDescending(p => p.Illness != null ? p.Illness.Severity : null),
                ("date", "asc")          => query.OrderBy(p => p.CreatedAt),
                _                        => query.OrderByDescending(p => p.CreatedAt),
            };

            // --- Phân trang ---
            var predictions = await query
                .Skip((filter.Page - 1) * filter.PageSize)
                .Take(filter.PageSize)
                .ToListAsync();

            return (predictions, totalCount);
        }
    }
}

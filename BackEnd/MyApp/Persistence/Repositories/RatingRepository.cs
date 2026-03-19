using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class RatingRepository
    {
        private readonly AppDbContext _context;

        public RatingRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<Rating> AddRatingAsync(Rating rating)
        {
            _context.Ratings.Add(rating);
            await _context.SaveChangesAsync();
            return rating;
        }

        public async Task<Rating?> GetRatingByPredictionIdAsync(int predictionId)
        {
            return await _context.Ratings
                .Include(r => r.Prediction)
                    .ThenInclude(p => p.Illness)
                .Include(r => r.Prediction)
                    .ThenInclude(p => p.Upload)
                        .ThenInclude(u => u.User)
                .FirstOrDefaultAsync(r => r.PredictionId == predictionId);
        }

        public async Task<IEnumerable<Rating>> GetAllRatingsAsync()
        {
            return await _context.Ratings
                .Include(r => r.Prediction)
                    .ThenInclude(p => p.Illness)
                .Include(r => r.Prediction)
                    .ThenInclude(p => p.Upload)
                        .ThenInclude(u => u.User)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();
        }

        public async Task<bool> ExistsByPredictionIdAsync(int predictionId)
        {
            return await _context.Ratings
                .AnyAsync(r => r.PredictionId == predictionId);
        }
    }
}

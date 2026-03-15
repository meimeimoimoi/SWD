using Microsoft.EntityFrameworkCore;
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
    }

}

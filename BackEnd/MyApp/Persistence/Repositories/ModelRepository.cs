using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class ModelRepository
    {
        private readonly AppDbContext _context;

        public ModelRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task<List<ModelVersion>> GetAllAsync()
        {
            return await _context.ModelVersions
                .OrderByDescending(m => m.CreatedAt)
                .ToListAsync();
        }

        public async Task<ModelVersion?> GetByIdAsync(int id)
        {
            return await _context.ModelVersions.FindAsync(id);
        }

        public async Task<bool> ExistsByNameAndVersionAsync(string modelName, string version)
        {
            return await _context.ModelVersions
                .AnyAsync(m => m.ModelName == modelName && m.Version == version);
        }

        public async Task<List<ModelVersion>> GetAllDefaultsExceptAsync(int excludeId)
        {
            return await _context.ModelVersions
                .Where(m => (m.IsDefault == true || m.IsActive == true) && m.ModelVersionId != excludeId)
                .ToListAsync();
        }

        public async Task<ModelVersion> AddAsync(ModelVersion model)
        {
            _context.ModelVersions.Add(model);
            await _context.SaveChangesAsync();
            return model;
        }

        public async Task UpdateAsync(ModelVersion model)
        {
            _context.ModelVersions.Update(model);
            await _context.SaveChangesAsync();
        }

        public async Task UpdateRangeAsync(List<ModelVersion> models)
        {
            _context.ModelVersions.UpdateRange(models);
            await _context.SaveChangesAsync();
        }

        public async Task<ModelVersion?> GetDefaultModelAsync()
        {
            return await _context.ModelVersions
                .FirstOrDefaultAsync(m => m.IsDefault == true && m.IsActive == true);
        }
    }
}

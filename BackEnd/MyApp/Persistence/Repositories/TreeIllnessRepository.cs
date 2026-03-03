using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class TreeIllnessRepository
    {
        private readonly AppDbContext _context;

        public TreeIllnessRepository(AppDbContext context)
        {
            _context = context;
        }
        public async Task<(List<TreeIllness> illnesses, int totalCount)> GetAllIllnessesAsync(
            string? search,
            string? severity,
            DateTime? createdFrom,
            DateTime? createdTo,
            DateTime? updatedFrom,
            DateTime? updatedTo,
            int page,
            int pageSize,
            string? sortBy = "CreatedAt",
            string? sortOrder = "desc")
        {
            var query = _context.TreeIllnesses
                .Include(i => i.TreatmentSolutions)
                .Include(i => i.Predictions)
                .AsQueryable();

            // Apply search filter
            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(i =>
                    (i.IllnessName != null && i.IllnessName.Contains(search)) ||
                    (i.ScientificName != null && i.ScientificName.Contains(search)) ||
                    (i.Description != null && i.Description.Contains(search)));
            }

            // Apply severity filter
            if (!string.IsNullOrWhiteSpace(severity))
            {
                query = query.Where(i => i.Severity == severity);
            }

            // Apply CreatedFrom filter
            if (createdFrom.HasValue)
            {
                query = query.Where(i => i.CreatedAt >= createdFrom.Value);
            }

            // Apply CreatedTo filter
            if (createdTo.HasValue)
            {
                // Add 1 day and use < to include the entire day
                var endDate = createdTo.Value.Date.AddDays(1);
                query = query.Where(i => i.CreatedAt < endDate);
            }

            // Apply UpdatedFrom filter
            if (updatedFrom.HasValue)
            {
                query = query.Where(i => i.UpdatedAt >= updatedFrom.Value);
            }

            // Apply UpdatedTo filter
            if (updatedTo.HasValue)
            {
                var endDate = updatedTo.Value.Date.AddDays(1);
                query = query.Where(i => i.UpdatedAt < endDate);
            }

            // Get total count before pagination
            var totalCount = await query.CountAsync();

            // Apply sorting
            query = sortBy?.ToLower() switch
            {
                "illnessname" => sortOrder?.ToLower() == "asc"
                    ? query.OrderBy(i => i.IllnessName)
                    : query.OrderByDescending(i => i.IllnessName),
                "severity" => sortOrder?.ToLower() == "asc"
                    ? query.OrderBy(i => i.Severity)
                    : query.OrderByDescending(i => i.Severity),
                "createdat" => sortOrder?.ToLower() == "asc"
                    ? query.OrderBy(i => i.CreatedAt)
                    : query.OrderByDescending(i => i.CreatedAt),
                "updatedat" => sortOrder?.ToLower() == "asc"
                    ? query.OrderBy(i => i.UpdatedAt)
                    : query.OrderByDescending(i => i.UpdatedAt),
                _ => query.OrderByDescending(i => i.CreatedAt) // Default
            };

            // Apply pagination
            var illnesses = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return (illnesses, totalCount);
        }

        public async Task<TreeIllness?> GetIllnessByIdAsync(int illnessId)
        {
            return await _context.TreeIllnesses
                .Include(i => i.TreatmentSolutions)
                .Include(i => i.Predictions)
                .Include(i => i.TreeIllnessRelationships)
                    .ThenInclude(r => r.Tree)
                .FirstOrDefaultAsync(i => i.IllnessId == illnessId);
        }
        public async Task<bool> ExistsAsync(int illnessId)
        {
            return await _context.TreeIllnesses.AnyAsync(i => i.IllnessId == illnessId);
        }

        public async Task<bool> ExistsByNameAsync(string illnessName)
        {
            return await _context.TreeIllnesses
                .AnyAsync(i => i.IllnessName != null && 
                              i.IllnessName.ToLower() == illnessName.ToLower());
        }

        public async Task<bool> ExistsByNameExcludingIdAsync(string illnessName, int excludeId)
        {
            return await _context.TreeIllnesses
                .AnyAsync(i => i.IllnessId != excludeId &&
                              i.IllnessName != null &&
                              i.IllnessName.ToLower() == illnessName.ToLower());
        }

        public async Task<Dictionary<string, int>> GetCountBySeverityAsync()
        {
            return await _context.TreeIllnesses
                .GroupBy(i => i.Severity)
                .Select(g => new { Severity = g.Key ?? "Unknown", Count = g.Count() })
                .ToDictionaryAsync(x => x.Severity, x => x.Count);
        }
        public async Task<TreeIllness> CreateIllnessAsync(TreeIllness illness)
        {
            // Set timestamps
            illness.CreatedAt = DateTime.UtcNow;
            illness.UpdatedAt = DateTime.UtcNow;

            _context.TreeIllnesses.Add(illness);
            await _context.SaveChangesAsync();

            return illness;
        }
        public async Task<TreeIllness> UpdateIllnessAsync(TreeIllness illness)
        {
            // Update timestamp
            illness.UpdatedAt = DateTime.UtcNow;

            _context.TreeIllnesses.Update(illness);
            await _context.SaveChangesAsync();

            return illness;
        }
    }
}

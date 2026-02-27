using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;
using MyApp.Persistence.Context;

namespace MyApp.Persistence.Repositories
{
    public class IllnessRepository
    {
        private readonly AppDbContext _context;
    
        public IllnessRepository(AppDbContext context)
        {
            _context = context;
        }
    
        public async Task<TreeIllness?> GetByNameAysnc(string illnessName)
        {
            return await _context.TreeIllnesses
                .Include(i => i.TreatmentSolutions)
                .FirstOrDefaultAsync(i => i.IllnessName == illnessName);
        }
        
    }
}

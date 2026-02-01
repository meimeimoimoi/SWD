using Microsoft.EntityFrameworkCore;
using SWD.Data.Entities;

namespace SWD.Data.Context
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
            : base(options)
        {
        }

        // DbSet properties will be added here
        // Example: public DbSet<Entity> Entities { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Configure entity relationships and constraints here
        }
    }
}

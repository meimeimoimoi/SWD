using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Context;

public partial class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<ImageUpload> ImageUploads { get; set; }

    public virtual DbSet<ModelVersion> ModelVersions { get; set; }

    public virtual DbSet<Prediction> Predictions { get; set; }

    public virtual DbSet<ProcessedImage> ProcessedImages { get; set; }

    public virtual DbSet<Rating> Ratings { get; set; }

    public virtual DbSet<RefreshToken> RefreshTokens { get; set; }

    public virtual DbSet<ResetPasswordToken> ResetPasswordTokens { get; set; }

    public virtual DbSet<SolutionCondition> SolutionConditions { get; set; }

    public virtual DbSet<SolutionImage> SolutionImages { get; set; }

    public virtual DbSet<TreatmentSolution> TreatmentSolutions { get; set; }

    public virtual DbSet<Tree> Trees { get; set; }

    public virtual DbSet<TreeIllness> TreeIllnesses { get; set; }

    public virtual DbSet<TreeIllnessRelationship> TreeIllnessRelationships { get; set; }

    public virtual DbSet<TreeStage> TreeStages { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<ActivityLog> ActivityLogs { get; set; }

    public virtual DbSet<SystemSetting> SystemSettings { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<Cart> Carts { get; set; }

    public virtual DbSet<CartItem> CartItems { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
}

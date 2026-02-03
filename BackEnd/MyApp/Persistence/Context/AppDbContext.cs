using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Context;

public partial class AppDbContext : DbContext
{
    public AppDbContext()
    {
    }

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

    public virtual DbSet<TreatmentSolution> TreatmentSolutions { get; set; }

    public virtual DbSet<Tree> Trees { get; set; }

    public virtual DbSet<TreeIllness> TreeIllnesses { get; set; }

    public virtual DbSet<TreeIllnessRelationship> TreeIllnessRelationships { get; set; }

    public virtual DbSet<TreeStage> TreeStages { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer(GetConnectionString());
    private string GetConnectionString()
    {
        IConfiguration config = new ConfigurationBuilder()
             .SetBasePath(AppContext.BaseDirectory)
                    .AddJsonFile("appsettings.json", true, true)
                    .Build();
        var strConn = config["ConnectionStrings:DefaultConnection"];

        return strConn;
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
    }
    //protected override void OnModelCreating(ModelBuilder modelBuilder)
    //{
    //    modelBuilder.Entity<ImageUpload>(entity =>
    //    {
    //        entity.HasKey(e => e.UploadId).HasName("PK__image_up__A13DEF58E7C35B7D");

    //        entity.ToTable("image_uploads");

    //        entity.HasIndex(e => e.UploadStatus, "idx_upload_status");

    //        entity.HasIndex(e => e.UploadedAt, "idx_uploaded_at");

    //        entity.HasIndex(e => e.UserId, "idx_user_id");

    //        entity.Property(e => e.UploadId).HasColumnName("upload_id");
    //        entity.Property(e => e.FilePath)
    //            .HasMaxLength(1000)
    //            .IsUnicode(false)
    //            .HasColumnName("file_path");
    //        entity.Property(e => e.FileSize).HasColumnName("file_size");
    //        entity.Property(e => e.ImageHeight).HasColumnName("image_height");
    //        entity.Property(e => e.ImageWidth).HasColumnName("image_width");
    //        entity.Property(e => e.MimeType)
    //            .HasMaxLength(100)
    //            .IsUnicode(false)
    //            .HasColumnName("mime_type");
    //        entity.Property(e => e.OriginalFilename)
    //            .HasMaxLength(500)
    //            .IsUnicode(false)
    //            .HasColumnName("original_filename");
    //        entity.Property(e => e.StoredFilename)
    //            .HasMaxLength(500)
    //            .IsUnicode(false)
    //            .HasColumnName("stored_filename");
    //        entity.Property(e => e.UploadStatus)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("upload_status");
    //        entity.Property(e => e.UploadedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("uploaded_at");
    //        entity.Property(e => e.UserId).HasColumnName("user_id");

    //        entity.HasOne(d => d.User).WithMany(p => p.ImageUploads)
    //            .HasForeignKey(d => d.UserId)
    //            .HasConstraintName("FK_upload_user");
    //    });

    //    modelBuilder.Entity<ModelVersion>(entity =>
    //    {
    //        entity.HasKey(e => e.ModelVersionId).HasName("PK__model_ve__D71A143AFF269214");

    //        entity.ToTable("model_versions");

    //        entity.HasIndex(e => e.IsActive, "idx_is_active");

    //        entity.HasIndex(e => e.IsDefault, "idx_is_default");

    //        entity.HasIndex(e => new { e.ModelName, e.Version }, "unique_model_version").IsUnique();

    //        entity.Property(e => e.ModelVersionId).HasColumnName("model_version_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Description).HasColumnName("description");
    //        entity.Property(e => e.IsActive)
    //            .HasDefaultValue(true)
    //            .HasColumnName("is_active");
    //        entity.Property(e => e.IsDefault)
    //            .HasDefaultValue(false)
    //            .HasColumnName("is_default");
    //        entity.Property(e => e.ModelName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("model_name");
    //        entity.Property(e => e.ModelType)
    //            .HasMaxLength(100)
    //            .IsUnicode(false)
    //            .HasDefaultValue("resnet18")
    //            .HasColumnName("model_type");
    //        entity.Property(e => e.Version)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("version");
    //    });

    //    modelBuilder.Entity<Prediction>(entity =>
    //    {
    //        entity.HasKey(e => e.PredictionId).HasName("PK__predicti__F1AE77BF0DB959B5");

    //        entity.ToTable("predictions");

    //        entity.HasIndex(e => e.CreatedAt, "idx_created_at_pred");

    //        entity.HasIndex(e => e.IllnessId, "idx_illness_id_pred");

    //        entity.HasIndex(e => e.ModelVersionId, "idx_model_version_id");

    //        entity.HasIndex(e => e.TreeId, "idx_tree_id_pred");

    //        entity.HasIndex(e => e.UploadId, "idx_upload_id_pred");

    //        entity.Property(e => e.PredictionId).HasColumnName("prediction_id");
    //        entity.Property(e => e.ConfidenceScore)
    //            .HasColumnType("decimal(5, 4)")
    //            .HasColumnName("confidence_score");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.IllnessId).HasColumnName("illness_id");
    //        entity.Property(e => e.ModelVersionId).HasColumnName("model_version_id");
    //        entity.Property(e => e.PredictedClass)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("predicted_class");
    //        entity.Property(e => e.ProcessingTimeMs).HasColumnName("processing_time_ms");
    //        entity.Property(e => e.TopNPredictions).HasColumnName("top_n_predictions");
    //        entity.Property(e => e.TreeId).HasColumnName("tree_id");
    //        entity.Property(e => e.UploadId).HasColumnName("upload_id");

    //        entity.HasOne(d => d.Illness).WithMany(p => p.Predictions)
    //            .HasForeignKey(d => d.IllnessId)
    //            .OnDelete(DeleteBehavior.SetNull)
    //            .HasConstraintName("FK_prediction_illness");

    //        entity.HasOne(d => d.ModelVersion).WithMany(p => p.Predictions)
    //            .HasForeignKey(d => d.ModelVersionId)
    //            .OnDelete(DeleteBehavior.SetNull)
    //            .HasConstraintName("FK_prediction_model");

    //        entity.HasOne(d => d.Tree).WithMany(p => p.Predictions)
    //            .HasForeignKey(d => d.TreeId)
    //            .OnDelete(DeleteBehavior.SetNull)
    //            .HasConstraintName("FK_prediction_tree");

    //        entity.HasOne(d => d.Upload).WithMany(p => p.Predictions)
    //            .HasForeignKey(d => d.UploadId)
    //            .HasConstraintName("FK_prediction_upload");
    //    });

    //    modelBuilder.Entity<ProcessedImage>(entity =>
    //    {
    //        entity.HasKey(e => e.ProcessedId).HasName("PK__processe__EE42C2329266644E");

    //        entity.ToTable("processed_images");

    //        entity.HasIndex(e => e.CreatedAt, "idx_created_at");

    //        entity.HasIndex(e => e.UploadId, "idx_upload_id");

    //        entity.Property(e => e.ProcessedId).HasColumnName("processed_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.PreprocessingSteps).HasColumnName("preprocessing_steps");
    //        entity.Property(e => e.ProcessedFilePath)
    //            .HasMaxLength(1000)
    //            .IsUnicode(false)
    //            .HasColumnName("processed_file_path");
    //        entity.Property(e => e.UploadId).HasColumnName("upload_id");

    //        entity.HasOne(d => d.Upload).WithMany(p => p.ProcessedImages)
    //            .HasForeignKey(d => d.UploadId)
    //            .HasConstraintName("FK_processed_upload");
    //    });

    //    modelBuilder.Entity<Rating>(entity =>
    //    {
    //        entity.HasKey(e => e.RatingId).HasName("PK__ratings__D35B278B2C910B23");

    //        entity.ToTable("ratings");

    //        entity.HasIndex(e => e.PredictionId, "idx_prediction_id");

    //        entity.Property(e => e.RatingId).HasColumnName("rating_id");
    //        entity.Property(e => e.Comment)
    //            .HasMaxLength(1000)
    //            .IsUnicode(false)
    //            .HasColumnName("comment");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.PredictionId).HasColumnName("prediction_id");
    //        entity.Property(e => e.Rating1)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("rating");

    //        entity.HasOne(d => d.Prediction).WithMany(p => p.Ratings)
    //            .HasForeignKey(d => d.PredictionId)
    //            .HasConstraintName("FK_rating_prediction");
    //    });

    //    modelBuilder.Entity<RefreshToken>(entity =>
    //    {
    //        entity.HasKey(e => e.RefreshTokenId).HasName("PK__refresh___B0A1F7C766869DA0");

    //        entity.ToTable("refresh_tokens");

    //        entity.HasIndex(e => e.JtiHash, "UQ__refresh___11D28A4E0314AB34").IsUnique();

    //        entity.HasIndex(e => e.IsRevoked, "idx_refresh_revoked");

    //        entity.Property(e => e.RefreshTokenId).HasColumnName("refresh_token_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.IsRevoked)
    //            .HasDefaultValue(false)
    //            .HasColumnName("is_revoked");
    //        entity.Property(e => e.JtiHash)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("jti_hash");
    //        entity.Property(e => e.UpdatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("updated_at");
    //    });

    //    modelBuilder.Entity<ResetPasswordToken>(entity =>
    //    {
    //        entity.HasKey(e => e.ResetTokenId).HasName("PK__reset_pa__9D878429B4763C71");

    //        entity.ToTable("reset_password_tokens");

    //        entity.HasIndex(e => e.TokenHash, "UQ__reset_pa__9F6BDB13B2CE46D6").IsUnique();

    //        entity.HasIndex(e => e.IsUsed, "idx_reset_used");

    //        entity.Property(e => e.ResetTokenId).HasColumnName("reset_token_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.IsUsed)
    //            .HasDefaultValue(false)
    //            .HasColumnName("is_used");
    //        entity.Property(e => e.TokenHash)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("token_hash");
    //        entity.Property(e => e.UpdatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("updated_at");
    //    });

    //    modelBuilder.Entity<SolutionCondition>(entity =>
    //    {
    //        entity.HasKey(e => e.ConditionId).HasName("PK__solution__8527AB15A8E109B8");

    //        entity.ToTable("solution_conditions");

    //        entity.Property(e => e.ConditionId).HasColumnName("condition_id");
    //        entity.Property(e => e.MinConfidence)
    //            .HasColumnType("decimal(5, 4)")
    //            .HasColumnName("min_confidence");
    //        entity.Property(e => e.Note).HasColumnName("note");
    //        entity.Property(e => e.SolutionId).HasColumnName("solution_id");
    //        entity.Property(e => e.WeatherCondition)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("weather_condition");

    //        entity.HasOne(d => d.Solution).WithMany(p => p.SolutionConditions)
    //            .HasForeignKey(d => d.SolutionId)
    //            .OnDelete(DeleteBehavior.ClientSetNull)
    //            .HasConstraintName("FK_condition_solution");
    //    });

    //    modelBuilder.Entity<TreatmentSolution>(entity =>
    //    {
    //        entity.HasKey(e => e.SolutionId).HasName("PK__treatmen__EA431C4996C956A8");

    //        entity.ToTable("treatment_solutions");

    //        entity.Property(e => e.SolutionId).HasColumnName("solution_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Description).HasColumnName("description");
    //        entity.Property(e => e.IllnessId).HasColumnName("illness_id");
    //        entity.Property(e => e.IllnessStageId).HasColumnName("illness_stage_id");
    //        entity.Property(e => e.MinConfidence)
    //            .HasColumnType("decimal(5, 4)")
    //            .HasColumnName("min_confidence");
    //        entity.Property(e => e.Priority).HasColumnName("priority");
    //        entity.Property(e => e.SolutionName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("solution_name");
    //        entity.Property(e => e.SolutionType)
    //            .HasMaxLength(100)
    //            .IsUnicode(false)
    //            .HasColumnName("solution_type");
    //        entity.Property(e => e.TreeStageId).HasColumnName("tree_stage_id");

    //        entity.HasOne(d => d.Illness).WithMany(p => p.TreatmentSolutions)
    //            .HasForeignKey(d => d.IllnessId)
    //            .OnDelete(DeleteBehavior.ClientSetNull)
    //            .HasConstraintName("FK_treatment_illness");

    //        entity.HasOne(d => d.TreeStage).WithMany(p => p.TreatmentSolutions)
    //            .HasForeignKey(d => d.TreeStageId)
    //            .OnDelete(DeleteBehavior.ClientSetNull)
    //            .HasConstraintName("FK_treatment_stage");
    //    });

    //    modelBuilder.Entity<Tree>(entity =>
    //    {
    //        entity.HasKey(e => e.TreeId).HasName("PK__trees__B80FA69880146702");

    //        entity.ToTable("trees", tb => tb.HasTrigger("trg_trees_updated_at"));

    //        entity.HasIndex(e => e.ScientificName, "idx_scientific_name");

    //        entity.HasIndex(e => e.TreeName, "idx_tree_name");

    //        entity.Property(e => e.TreeId).HasColumnName("tree_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Description).HasColumnName("description");
    //        entity.Property(e => e.ImagePath)
    //            .HasMaxLength(500)
    //            .IsUnicode(false)
    //            .HasColumnName("image_path");
    //        entity.Property(e => e.ScientificName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("scientific_name");
    //        entity.Property(e => e.TreeName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("tree_name");
    //        entity.Property(e => e.UpdatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("updated_at");
    //    });

    //    modelBuilder.Entity<TreeIllness>(entity =>
    //    {
    //        entity.HasKey(e => e.IllnessId).HasName("PK__tree_ill__F28BCB8F81CADBC2");

    //        entity.ToTable("tree_illnesses", tb => tb.HasTrigger("trg_tree_illnesses_updated_at"));

    //        entity.HasIndex(e => e.IllnessName, "idx_illness_name");

    //        entity.Property(e => e.IllnessId).HasColumnName("illness_id");
    //        entity.Property(e => e.Causes).HasColumnName("causes");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Description).HasColumnName("description");
    //        entity.Property(e => e.IllnessName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("illness_name");
    //        entity.Property(e => e.ScientificName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("scientific_name");
    //        entity.Property(e => e.Severity)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("severity");
    //        entity.Property(e => e.Symptoms).HasColumnName("symptoms");
    //        entity.Property(e => e.UpdatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("updated_at");
    //    });

    //    modelBuilder.Entity<TreeIllnessRelationship>(entity =>
    //    {
    //        entity.HasKey(e => e.RelationshipId).HasName("PK__tree_ill__C0CFD5549315CE3C");

    //        entity.ToTable("tree_illness_relationships");

    //        entity.HasIndex(e => e.IllnessId, "idx_illness_id");

    //        entity.HasIndex(e => e.TreeId, "idx_tree_id");

    //        entity.HasIndex(e => new { e.TreeId, e.IllnessId }, "unique_tree_illness").IsUnique();

    //        entity.Property(e => e.RelationshipId).HasColumnName("relationship_id");
    //        entity.Property(e => e.IllnessId).HasColumnName("illness_id");
    //        entity.Property(e => e.TreeId).HasColumnName("tree_id");

    //        entity.HasOne(d => d.Illness).WithMany(p => p.TreeIllnessRelationships)
    //            .HasForeignKey(d => d.IllnessId)
    //            .HasConstraintName("FK_tree_illness_illness");

    //        entity.HasOne(d => d.Tree).WithMany(p => p.TreeIllnessRelationships)
    //            .HasForeignKey(d => d.TreeId)
    //            .HasConstraintName("FK_tree_illness_tree");
    //    });

    //    modelBuilder.Entity<TreeStage>(entity =>
    //    {
    //        entity.HasKey(e => e.StageId).HasName("PK__tree_sta__CFC787609D9C4079");

    //        entity.ToTable("tree_stages");

    //        entity.Property(e => e.StageId).HasColumnName("stage_id");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Description).HasColumnName("description");
    //        entity.Property(e => e.StageName)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("stage_name");
    //    });

    //    modelBuilder.Entity<User>(entity =>
    //    {
    //        entity.HasKey(e => e.UserId).HasName("PK__users__B9BE370FEF387219");

    //        entity.ToTable("users", tb => tb.HasTrigger("trg_users_updated_at"));

    //        entity.HasIndex(e => e.Email, "UQ__users__AB6E61643CD88CAE").IsUnique();

    //        entity.HasIndex(e => e.Username, "UQ__users__F3DBC572B30B5982").IsUnique();

    //        entity.HasIndex(e => e.AccountStatus, "idx_account_status");

    //        entity.HasIndex(e => e.Email, "idx_email");

    //        entity.HasIndex(e => e.Username, "idx_username");

    //        entity.Property(e => e.UserId).HasColumnName("user_id");
    //        entity.Property(e => e.AccountStatus)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("account_status");
    //        entity.Property(e => e.CreatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("created_at");
    //        entity.Property(e => e.Email)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("email");
    //        entity.Property(e => e.FirstName)
    //            .HasMaxLength(100)
    //            .IsUnicode(false)
    //            .HasColumnName("first_name");
    //        entity.Property(e => e.LastLoginAt).HasColumnName("last_login_at");
    //        entity.Property(e => e.LastName)
    //            .HasMaxLength(100)
    //            .IsUnicode(false)
    //            .HasColumnName("last_name");
    //        entity.Property(e => e.PasswordHash)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("password_hash");
    //        entity.Property(e => e.Phone)
    //            .HasMaxLength(20)
    //            .IsUnicode(false)
    //            .HasColumnName("phone");
    //        entity.Property(e => e.ProfileImagePath)
    //            .HasMaxLength(500)
    //            .IsUnicode(false)
    //            .HasColumnName("profile_image_path");
    //        entity.Property(e => e.Role)
    //            .HasMaxLength(50)
    //            .IsUnicode(false)
    //            .HasColumnName("role");
    //        entity.Property(e => e.UpdatedAt)
    //            .HasDefaultValueSql("(getdate())")
    //            .HasColumnName("updated_at");
    //        entity.Property(e => e.Username)
    //            .HasMaxLength(255)
    //            .IsUnicode(false)
    //            .HasColumnName("username");
    //    });

    //    OnModelCreatingPartial(modelBuilder);
    //}

    //partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

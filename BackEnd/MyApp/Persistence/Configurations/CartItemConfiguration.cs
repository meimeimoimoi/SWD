using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class CartItemConfiguration : IEntityTypeConfiguration<CartItem>
    {
        public void Configure(EntityTypeBuilder<CartItem> entity)
        {
            entity.HasKey(e => e.CartItemId).HasName("PK_cart_items");

            entity.ToTable("cart_items");

            entity.Property(e => e.CartItemId).HasColumnName("cart_item_id");
            entity.Property(e => e.CartId).HasColumnName("cart_id");
            entity.Property(e => e.SolutionId).HasColumnName("solution_id");
            entity.Property(e => e.AddedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("added_at");

            entity.HasOne(d => d.Cart).WithMany(p => p.CartItems)
                .HasForeignKey(d => d.CartId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_cart_item_cart");

            entity.HasOne(d => d.Solution).WithMany()
                .HasForeignKey(d => d.SolutionId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_cart_item_solution");
        }
    }
}

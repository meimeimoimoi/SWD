using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddQuantityToCartItem : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "quantity",
                table: "cart_items",
                type: "int",
                nullable: false,
                defaultValue: 1);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "quantity",
                table: "cart_items");
        }
    }
}

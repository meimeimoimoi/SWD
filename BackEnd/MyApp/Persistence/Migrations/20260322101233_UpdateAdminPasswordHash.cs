using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <summary>
    /// Sets admin password_hash to BCrypt (BCrypt.Net-Next 4.0.3) for plaintext Admin123!.
    /// Matches SeedInitialMasterData and DataSeeder defaults.
    /// </summary>
    public partial class UpdateAdminPasswordHash : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                UPDATE [users]
                SET [password_hash] = N'$2a$11$61GJCQQAT3CQOcv4hIRdAeTmRUYOKaqoSxz/ID/iyP7xEdotkWe76', [updated_at] = GETUTCDATE()
                WHERE [username] = N'admin';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                UPDATE [users]
                SET [password_hash] = N'$2a$11$pWXwU3T/GT232Oj7JblhmunBP0J91XV4SvS1FEnEH753kNZMuxn.2', [updated_at] = GETUTCDATE()
                WHERE [username] = N'admin';
                """);
        }
    }
}

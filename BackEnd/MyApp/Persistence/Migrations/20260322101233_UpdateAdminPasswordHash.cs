using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    public partial class UpdateAdminPasswordHash : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                UPDATE [users]
                SET [password_hash] = N'$2a$11$61GJCQQAT3CQOcv4hIRdAeTmRUYOKaqoSxz/ID/iyP7xEdotkWe76', [updated_at] = GETUTCDATE()
                WHERE [username] = N'admin';
                """);
        }

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

using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUpdatedAtTriggers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_users_updated_at' AND parent_id = OBJECT_ID(N'dbo.users'))
                EXEC(N'CREATE TRIGGER dbo.trg_users_updated_at ON dbo.users AFTER UPDATE AS BEGIN SET NOCOUNT ON; UPDATE dbo.users SET updated_at = GETDATE() FROM dbo.users u INNER JOIN inserted i ON u.user_id = i.user_id; END');
                IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_trees_updated_at' AND parent_id = OBJECT_ID(N'dbo.trees'))
                EXEC(N'CREATE TRIGGER dbo.trg_trees_updated_at ON dbo.trees AFTER UPDATE AS BEGIN SET NOCOUNT ON; UPDATE dbo.trees SET updated_at = GETDATE() FROM dbo.trees t INNER JOIN inserted i ON t.tree_id = i.tree_id; END');
                IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = N'trg_tree_illnesses_updated_at' AND parent_id = OBJECT_ID(N'dbo.tree_illnesses'))
                EXEC(N'CREATE TRIGGER dbo.trg_tree_illnesses_updated_at ON dbo.tree_illnesses AFTER UPDATE AS BEGIN SET NOCOUNT ON; UPDATE dbo.tree_illnesses SET updated_at = GETDATE() FROM dbo.tree_illnesses ti INNER JOIN inserted i ON ti.illness_id = i.illness_id; END');
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP TRIGGER IF EXISTS dbo.trg_users_updated_at;
                DROP TRIGGER IF EXISTS dbo.trg_trees_updated_at;
                DROP TRIGGER IF EXISTS dbo.trg_tree_illnesses_updated_at;
                """);
        }
    }
}

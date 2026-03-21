-- =====================================================
-- SQL SERVER SCHEMA
-- Tree Disease Detection System
-- =====================================================

-- Drop tables if exists (in reverse order of dependencies)
IF OBJECT_ID('dbo.ratings', 'U') IS NOT NULL DROP TABLE dbo.ratings;
IF OBJECT_ID('dbo.predictions', 'U') IS NOT NULL DROP TABLE dbo.predictions;
IF OBJECT_ID('dbo.processed_images', 'U') IS NOT NULL DROP TABLE dbo.processed_images;
IF OBJECT_ID('dbo.image_uploads', 'U') IS NOT NULL DROP TABLE dbo.image_uploads;
IF OBJECT_ID('dbo.solution_conditions', 'U') IS NOT NULL DROP TABLE dbo.solution_conditions;
IF OBJECT_ID('dbo.treatment_solutions', 'U') IS NOT NULL DROP TABLE dbo.treatment_solutions;
IF OBJECT_ID('dbo.tree_illness_relationships', 'U') IS NOT NULL DROP TABLE dbo.tree_illness_relationships;
IF OBJECT_ID('dbo.tree_stages', 'U') IS NOT NULL DROP TABLE dbo.tree_stages;
IF OBJECT_ID('dbo.tree_illnesses', 'U') IS NOT NULL DROP TABLE dbo.tree_illnesses;
IF OBJECT_ID('dbo.trees', 'U') IS NOT NULL DROP TABLE dbo.trees;
IF OBJECT_ID('dbo.model_versions', 'U') IS NOT NULL DROP TABLE dbo.model_versions;
IF OBJECT_ID('dbo.reset_password_tokens', 'U') IS NOT NULL DROP TABLE dbo.reset_password_tokens;
IF OBJECT_ID('dbo.refresh_tokens', 'U') IS NOT NULL DROP TABLE dbo.refresh_tokens;
IF OBJECT_ID('dbo.notifications', 'U') IS NOT NULL DROP TABLE dbo.notifications;
IF OBJECT_ID('dbo.activity_logs', 'U') IS NOT NULL DROP TABLE dbo.activity_logs;
IF OBJECT_ID('dbo.system_settings', 'U') IS NOT NULL DROP TABLE dbo.system_settings;
IF OBJECT_ID('dbo.users', 'U') IS NOT NULL DROP TABLE dbo.users;
GO

-- =====================================================
-- USERS & AUTHENTICATION TABLES
-- =====================================================

CREATE TABLE dbo.users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    profile_image_path VARCHAR(500),
    account_status VARCHAR(50),
    last_login_at DATETIME2,
    role VARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_email ON dbo.users(email);
CREATE INDEX idx_username ON dbo.users(username);
CREATE INDEX idx_account_status ON dbo.users(account_status);
GO

-- =====================================================

CREATE TABLE dbo.refresh_tokens (
    refresh_token_id INT IDENTITY(1,1) PRIMARY KEY,
    jti_hash VARCHAR(255) NOT NULL UNIQUE,
    is_revoked BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_refresh_revoked ON dbo.refresh_tokens(is_revoked);
GO

-- =====================================================

CREATE TABLE dbo.reset_password_tokens (
    reset_token_id INT IDENTITY(1,1) PRIMARY KEY,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    is_used BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_reset_used ON dbo.reset_password_tokens(is_used);
GO

-- =====================================================
-- MODEL VERSIONS
-- =====================================================

CREATE TABLE dbo.model_versions (
    model_version_id INT IDENTITY(1,1) PRIMARY KEY,
    model_name VARCHAR(255) NOT NULL,
    version VARCHAR(50) NOT NULL,
    model_type VARCHAR(100) DEFAULT 'resnet18',
    description NVARCHAR(MAX),
    file_path VARCHAR(500),
    is_active BIT DEFAULT 1,
    is_default BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETDATE()
);

CREATE UNIQUE INDEX unique_model_version ON dbo.model_versions(model_name, version);
CREATE INDEX idx_is_active ON dbo.model_versions(is_active);
CREATE INDEX idx_is_default ON dbo.model_versions(is_default);
GO

-- =====================================================
-- TREES & ILLNESSES
-- =====================================================

CREATE TABLE dbo.trees (
    tree_id INT IDENTITY(1,1) PRIMARY KEY,
    tree_name VARCHAR(255),
    scientific_name VARCHAR(255),
    description NVARCHAR(MAX),
    image_path VARCHAR(500),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_tree_name ON dbo.trees(tree_name);
CREATE INDEX idx_scientific_name ON dbo.trees(scientific_name);
GO

-- =====================================================

CREATE TABLE dbo.tree_illnesses (
    illness_id INT IDENTITY(1,1) PRIMARY KEY,
    illness_name VARCHAR(255),
    scientific_name VARCHAR(255),
    description NVARCHAR(MAX),
    symptoms NVARCHAR(MAX),
    causes NVARCHAR(MAX),
    severity VARCHAR(50),
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE()
);

CREATE INDEX idx_illness_name ON dbo.tree_illnesses(illness_name);
GO

-- =====================================================

CREATE TABLE dbo.tree_illness_relationships (
    relationship_id INT IDENTITY(1,1) PRIMARY KEY,
    tree_id INT NOT NULL,
    illness_id INT NOT NULL,
    CONSTRAINT FK_tree_illness_tree FOREIGN KEY (tree_id) 
        REFERENCES dbo.trees(tree_id) ON DELETE CASCADE,
    CONSTRAINT FK_tree_illness_illness FOREIGN KEY (illness_id) 
        REFERENCES dbo.tree_illnesses(illness_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX unique_tree_illness ON dbo.tree_illness_relationships(tree_id, illness_id);
CREATE INDEX idx_tree_id ON dbo.tree_illness_relationships(tree_id);
CREATE INDEX idx_illness_id ON dbo.tree_illness_relationships(illness_id);
GO

-- =====================================================
-- TREE STAGES & TREATMENT SOLUTIONS
-- =====================================================

CREATE TABLE dbo.tree_stages (
    stage_id INT IDENTITY(1,1) PRIMARY KEY,
    stage_name VARCHAR(255),
    description NVARCHAR(MAX),
    created_at DATETIME2 DEFAULT GETDATE()
);
GO

-- =====================================================

CREATE TABLE dbo.treatment_solutions (
    solution_id INT IDENTITY(1,1) PRIMARY KEY,
    illness_id INT NOT NULL,
    illness_stage_id INT NULL,
    solution_name VARCHAR(255),
    solution_type VARCHAR(100),
    description NVARCHAR(MAX),
    tree_stage_id INT NOT NULL,
    min_confidence DECIMAL(5,4),
    priority INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_treatment_illness FOREIGN KEY (illness_id) 
        REFERENCES dbo.tree_illnesses(illness_id),
    CONSTRAINT FK_treatment_stage FOREIGN KEY (tree_stage_id) 
        REFERENCES dbo.tree_stages(stage_id)
);
GO

-- =====================================================

CREATE TABLE dbo.solution_conditions (
    condition_id INT IDENTITY(1,1) PRIMARY KEY,
    solution_id INT NOT NULL,
    min_confidence DECIMAL(5,4),
    weather_condition VARCHAR(255),
    note NVARCHAR(MAX),
    CONSTRAINT FK_condition_solution FOREIGN KEY (solution_id) 
        REFERENCES dbo.treatment_solutions(solution_id)
);
GO

-- =====================================================
-- IMAGE UPLOADS & PROCESSING
-- =====================================================

CREATE TABLE dbo.image_uploads (
    upload_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    original_filename VARCHAR(500),
    stored_filename VARCHAR(500),
    file_path VARCHAR(1000),
    file_size BIGINT,
    mime_type VARCHAR(100),
    image_width INT,
    image_height INT,
    upload_status VARCHAR(50),
    uploaded_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_upload_user FOREIGN KEY (user_id) 
        REFERENCES dbo.users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_user_id ON dbo.image_uploads(user_id);
CREATE INDEX idx_upload_status ON dbo.image_uploads(upload_status);
CREATE INDEX idx_uploaded_at ON dbo.image_uploads(uploaded_at);
GO

-- =====================================================

CREATE TABLE dbo.processed_images (
    processed_id INT IDENTITY(1,1) PRIMARY KEY,
    upload_id INT NOT NULL,
    processed_file_path VARCHAR(1000),
    preprocessing_steps NVARCHAR(MAX), -- JSON stored as NVARCHAR(MAX)
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_processed_upload FOREIGN KEY (upload_id) 
        REFERENCES dbo.image_uploads(upload_id) ON DELETE CASCADE
);

CREATE INDEX idx_upload_id ON dbo.processed_images(upload_id);
CREATE INDEX idx_created_at ON dbo.processed_images(created_at);
GO

-- =====================================================
-- PREDICTIONS & RATINGS
-- =====================================================

CREATE TABLE dbo.predictions (
    prediction_id INT IDENTITY(1,1) PRIMARY KEY,
    upload_id INT NOT NULL,
    model_version_id INT NULL,
    tree_id INT NULL,
    illness_id INT NULL,
    predicted_class VARCHAR(255),
    confidence_score DECIMAL(5,4),
    top_n_predictions NVARCHAR(MAX), -- JSON stored as NVARCHAR(MAX)
    processing_time_ms INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_prediction_upload FOREIGN KEY (upload_id) 
        REFERENCES dbo.image_uploads(upload_id) ON DELETE CASCADE,
    CONSTRAINT FK_prediction_model FOREIGN KEY (model_version_id) 
        REFERENCES dbo.model_versions(model_version_id) ON DELETE SET NULL,
    CONSTRAINT FK_prediction_tree FOREIGN KEY (tree_id) 
        REFERENCES dbo.trees(tree_id) ON DELETE SET NULL,
    CONSTRAINT FK_prediction_illness FOREIGN KEY (illness_id) 
        REFERENCES dbo.tree_illnesses(illness_id) ON DELETE SET NULL
);

CREATE INDEX idx_upload_id_pred ON dbo.predictions(upload_id);
CREATE INDEX idx_tree_id_pred ON dbo.predictions(tree_id);
CREATE INDEX idx_illness_id_pred ON dbo.predictions(illness_id);
CREATE INDEX idx_model_version_id ON dbo.predictions(model_version_id);
CREATE INDEX idx_created_at_pred ON dbo.predictions(created_at);
GO

-- =====================================================

CREATE TABLE dbo.ratings (
    rating_id INT IDENTITY(1,1) PRIMARY KEY,
    prediction_id INT NOT NULL,
    rating VARCHAR(50),
    comment VARCHAR(1000),
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_rating_prediction FOREIGN KEY (prediction_id) 
        REFERENCES dbo.predictions(prediction_id) ON DELETE CASCADE
);

CREATE INDEX idx_prediction_id ON dbo.ratings(prediction_id);
GO

-- =====================================================
-- APP EXTENSION TABLES (match EF Core migrations)
-- =====================================================

CREATE TABLE dbo.system_settings (
    setting_id INT IDENTITY(1,1) PRIMARY KEY,
    setting_key NVARCHAR(100) NOT NULL,
    setting_value NVARCHAR(MAX) NOT NULL,
    description NVARCHAR(MAX),
    setting_group NVARCHAR(50),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE()
);

CREATE UNIQUE INDEX IX_system_settings_setting_key ON dbo.system_settings(setting_key);
GO

CREATE TABLE dbo.activity_logs (
    activity_log_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NULL,
    action NVARCHAR(100) NOT NULL,
    entity_name NVARCHAR(100) NOT NULL,
    entity_id NVARCHAR(100),
    description NVARCHAR(MAX),
    ip_address NVARCHAR(50),
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_activity_user FOREIGN KEY (user_id)
        REFERENCES dbo.users(user_id) ON DELETE SET NULL
);

CREATE INDEX IX_activity_logs_user_id ON dbo.activity_logs(user_id);
GO

CREATE TABLE dbo.notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    title NVARCHAR(200) NOT NULL,
    message NVARCHAR(MAX) NOT NULL,
    type NVARCHAR(50),
    is_read BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_notification_user FOREIGN KEY (user_id)
        REFERENCES dbo.users(user_id) ON DELETE CASCADE
);

CREATE INDEX IX_notifications_user_id ON dbo.notifications(user_id);
GO

-- =====================================================
-- UTILITY: Update timestamp trigger examples
-- =====================================================

-- Example trigger for users table
CREATE TRIGGER trg_users_updated_at
ON dbo.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.users
    SET updated_at = GETDATE()
    FROM dbo.users u
    INNER JOIN inserted i ON u.user_id = i.user_id;
END;
GO

-- Example trigger for trees table
CREATE TRIGGER trg_trees_updated_at
ON dbo.trees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.trees
    SET updated_at = GETDATE()
    FROM dbo.trees t
    INNER JOIN inserted i ON t.tree_id = i.tree_id;
END;
GO

-- Example trigger for tree_illnesses table
CREATE TRIGGER trg_tree_illnesses_updated_at
ON dbo.tree_illnesses
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tree_illnesses
    SET updated_at = GETDATE()
    FROM dbo.tree_illnesses ti
    INNER JOIN inserted i ON ti.illness_id = i.illness_id;
END;
GO

PRINT 'Schema created successfully!';
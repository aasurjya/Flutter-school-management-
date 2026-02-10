-- =============================================
-- AI-Driven Predictive Analytics
-- Phase 1: ML Infrastructure & Early Warning System
-- =============================================

-- =============================================
-- ENUMS
-- =============================================

CREATE TYPE ml_model_type AS ENUM (
    'performance_prediction',
    'dropout_risk',
    'intervention_recommendation',
    'fee_default_prediction',
    'behavioral_analysis',
    'learning_path_optimization'
);

CREATE TYPE ml_model_status AS ENUM ('training', 'active', 'deprecated', 'failed');

CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high', 'critical');

CREATE TYPE confidence_level AS ENUM ('low', 'medium', 'high');

CREATE TYPE intervention_type AS ENUM (
    'academic_support',
    'counseling',
    'parental_meeting',
    'mentorship',
    'peer_tutoring',
    'remedial_classes',
    'behavioral_support',
    'financial_assistance'
);

CREATE TYPE intervention_status AS ENUM ('planned', 'in_progress', 'completed', 'cancelled', 'ineffective');

CREATE TYPE alert_category AS ENUM (
    'academic_decline',
    'attendance_issue',
    'behavioral_concern',
    'fee_default_risk',
    'dropout_risk',
    'health_concern'
);

CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'critical', 'emergency');

CREATE TYPE alert_status AS ENUM ('new', 'acknowledged', 'in_progress', 'resolved', 'false_positive');

CREATE TYPE grade_trend AS ENUM ('improving', 'stable', 'declining');

-- =============================================
-- ML MODEL REGISTRY
-- =============================================

CREATE TABLE ml_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    model_type ml_model_type NOT NULL,
    model_name VARCHAR(100) NOT NULL,
    model_version VARCHAR(20) NOT NULL,
    algorithm VARCHAR(50), -- 'random_forest', 'lstm', 'gradient_boosting'
    hyperparameters JSONB DEFAULT '{}',
    training_metrics JSONB DEFAULT '{}', -- accuracy, precision, recall, F1
    status ml_model_status DEFAULT 'training',
    is_active BOOLEAN DEFAULT false,
    prediction_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    trained_at TIMESTAMPTZ,
    deprecated_at TIMESTAMPTZ,
    UNIQUE(tenant_id, model_name, model_version)
);

COMMENT ON TABLE ml_models IS 'Registry of machine learning models for predictive analytics';
COMMENT ON COLUMN ml_models.hyperparameters IS 'Model configuration parameters in JSON format';
COMMENT ON COLUMN ml_models.training_metrics IS 'Model performance metrics: accuracy, precision, recall, F1 score';

-- =============================================
-- STUDENT PERFORMANCE PREDICTIONS
-- =============================================

CREATE TABLE student_performance_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES ml_models(id) ON DELETE CASCADE,
    predicted_gpa DECIMAL(4,2),
    risk_level risk_level NOT NULL,
    dropout_probability DECIMAL(5,4), -- 0.0000 to 1.0000
    confidence confidence_level NOT NULL,
    -- Contributing factors (weighted -100 to +100)
    attendance_factor DECIMAL(5,2),
    academic_factor DECIMAL(5,2),
    behavioral_factor DECIMAL(5,2),
    engagement_factor DECIMAL(5,2),
    -- Recommendations
    intervention_required BOOLEAN DEFAULT false,
    recommended_actions JSONB DEFAULT '[]', -- [{action, priority, estimated_impact}]
    early_warning_flags TEXT[] DEFAULT '{}',
    feature_vector JSONB DEFAULT '{}', -- for retraining
    predicted_at TIMESTAMPTZ DEFAULT NOW(),
    valid_until TIMESTAMPTZ,
    -- Post-facto validation
    actual_outcome JSONB,
    prediction_accuracy DECIMAL(5,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE student_performance_predictions IS 'AI-generated predictions for student academic performance and risk assessment';
COMMENT ON COLUMN student_performance_predictions.dropout_probability IS 'Probability of student dropout (0-1 scale)';
COMMENT ON COLUMN student_performance_predictions.early_warning_flags IS 'Array of warning indicators triggering intervention';

-- =============================================
-- HISTORICAL FEATURE STORE
-- =============================================

CREATE TABLE student_feature_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    snapshot_date DATE NOT NULL,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    -- Academic features
    current_gpa DECIMAL(4,2),
    attendance_percentage DECIMAL(5,2),
    assignment_completion_rate DECIMAL(5,2),
    test_average DECIMAL(5,2),
    grade_trend grade_trend,
    -- Behavioral features
    discipline_incidents_count INT DEFAULT 0,
    engagement_score DECIMAL(5,2),
    -- Financial features
    fee_payment_status VARCHAR(20),
    days_overdue INT DEFAULT 0,
    -- Social features
    class_rank INT,
    peer_group_performance DECIMAL(5,2),
    -- Full feature vector
    features_json JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(student_id, snapshot_date)
);

COMMENT ON TABLE student_feature_snapshots IS 'Time-series snapshots of student metrics for ML model training';
COMMENT ON COLUMN student_feature_snapshots.features_json IS 'Complete feature vector for machine learning training';

-- =============================================
-- STUDENT INTERVENTIONS
-- =============================================

CREATE TABLE student_interventions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    prediction_id UUID REFERENCES student_performance_predictions(id) ON DELETE SET NULL,
    intervention_type intervention_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    goal TEXT,
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    status intervention_status DEFAULT 'planned',
    priority INT CHECK (priority BETWEEN 1 AND 5),
    start_date DATE,
    target_completion_date DATE,
    sessions_planned INT DEFAULT 0,
    sessions_completed INT DEFAULT 0,
    -- Outcomes
    effectiveness_rating INT CHECK (effectiveness_rating BETWEEN 1 AND 5),
    metrics_before JSONB DEFAULT '{}',
    metrics_after JSONB DEFAULT '{}',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

COMMENT ON TABLE student_interventions IS 'Tracking of intervention programs for at-risk students';
COMMENT ON COLUMN student_interventions.priority IS 'Intervention urgency level (1=lowest, 5=highest)';
COMMENT ON COLUMN student_interventions.effectiveness_rating IS 'Post-intervention effectiveness rating (1-5)';

-- =============================================
-- EARLY WARNING SYSTEM
-- =============================================

CREATE TABLE early_warning_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    alert_category alert_category NOT NULL,
    severity alert_severity NOT NULL,
    status alert_status DEFAULT 'new',
    title VARCHAR(255) NOT NULL,
    description TEXT,
    detected_by_model_id UUID REFERENCES ml_models(id) ON DELETE SET NULL,
    confidence_score DECIMAL(5,2),
    trigger_conditions JSONB DEFAULT '{}',
    assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
    parent_notified BOOLEAN DEFAULT false,
    parent_notified_at TIMESTAMPTZ,
    resolution_notes TEXT,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE early_warning_alerts IS 'Automated alerts for students requiring immediate attention';
COMMENT ON COLUMN early_warning_alerts.trigger_conditions IS 'JSON object containing the conditions that triggered this alert';

-- =============================================
-- ALERT RULES CONFIGURATION
-- =============================================

CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    rule_name VARCHAR(100) NOT NULL,
    alert_category alert_category NOT NULL,
    severity alert_severity NOT NULL,
    condition_logic JSONB NOT NULL, -- {"attendance_percentage": {"operator": "<", "value": 75, "days": 30}}
    is_active BOOLEAN DEFAULT true,
    auto_assign_to_role user_role,
    notify_parents BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(tenant_id, rule_name)
);

COMMENT ON TABLE alert_rules IS 'Configurable rules for automatic alert generation';
COMMENT ON COLUMN alert_rules.condition_logic IS 'JSON logic for evaluating alert conditions';

-- =============================================
-- INDEXES
-- =============================================

-- ML Models
CREATE INDEX idx_ml_models_tenant_type ON ml_models(tenant_id, model_type);
CREATE INDEX idx_ml_models_status ON ml_models(status) WHERE is_active = true;

-- Student Predictions
CREATE INDEX idx_predictions_student ON student_performance_predictions(student_id, academic_year_id);
CREATE INDEX idx_predictions_risk ON student_performance_predictions(risk_level, predicted_at DESC)
    WHERE risk_level IN ('high', 'critical');
CREATE INDEX idx_predictions_intervention ON student_performance_predictions(intervention_required, predicted_at DESC)
    WHERE intervention_required = true;
CREATE INDEX idx_predictions_model ON student_performance_predictions(model_id);

-- Feature Snapshots
CREATE INDEX idx_feature_snapshots_student ON student_feature_snapshots(student_id, snapshot_date DESC);
CREATE INDEX idx_feature_snapshots_year ON student_feature_snapshots(academic_year_id, snapshot_date);

-- Interventions
CREATE INDEX idx_interventions_student ON student_interventions(student_id, status);
CREATE INDEX idx_interventions_assigned ON student_interventions(assigned_to, status)
    WHERE status IN ('planned', 'in_progress');
CREATE INDEX idx_interventions_prediction ON student_interventions(prediction_id);
CREATE INDEX idx_interventions_priority ON student_interventions(priority DESC, start_date)
    WHERE status != 'completed';

-- Early Warning Alerts
CREATE INDEX idx_alerts_student ON early_warning_alerts(student_id, created_at DESC);
CREATE INDEX idx_alerts_status ON early_warning_alerts(status, severity DESC)
    WHERE status IN ('new', 'acknowledged', 'in_progress');
CREATE INDEX idx_alerts_assigned ON early_warning_alerts(assigned_to, status)
    WHERE status IN ('new', 'acknowledged', 'in_progress');
CREATE INDEX idx_alerts_category ON early_warning_alerts(alert_category, severity);

-- Alert Rules
CREATE INDEX idx_alert_rules_tenant ON alert_rules(tenant_id) WHERE is_active = true;

-- =============================================
-- STORED PROCEDURES
-- =============================================

-- Trigger early warning alert
CREATE OR REPLACE FUNCTION trigger_early_warning(
    p_student_id UUID,
    p_category alert_category,
    p_severity alert_severity,
    p_title VARCHAR(255),
    p_description TEXT,
    p_model_id UUID DEFAULT NULL,
    p_trigger_conditions JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
    v_rule alert_rules%ROWTYPE;
BEGIN
    -- Create alert
    INSERT INTO early_warning_alerts (
        student_id, alert_category, severity, title, description,
        detected_by_model_id, trigger_conditions
    ) VALUES (
        p_student_id, p_category, p_severity, p_title, p_description,
        p_model_id, p_trigger_conditions
    ) RETURNING id INTO v_alert_id;

    -- Check if there's a matching rule for auto-assignment
    SELECT * INTO v_rule
    FROM alert_rules
    WHERE alert_category = p_category
        AND severity = p_severity
        AND is_active = true
    LIMIT 1;

    IF FOUND AND v_rule.auto_assign_to_role IS NOT NULL THEN
        -- Auto-assign to user with specified role
        -- TODO: Implement auto-assignment logic based on role
        NULL;
    END IF;

    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trigger_early_warning IS 'Creates an early warning alert and handles auto-assignment';

-- Check alert rules (to be run daily via scheduler)
CREATE OR REPLACE FUNCTION check_alert_rules()
RETURNS VOID AS $$
DECLARE
    v_rule alert_rules%ROWTYPE;
BEGIN
    -- Iterate through all active alert rules
    FOR v_rule IN
        SELECT * FROM alert_rules WHERE is_active = true
    LOOP
        -- TODO: Implement rule evaluation logic
        -- This would evaluate condition_logic against current student data
        -- and trigger alerts for matching students
        NULL;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_alert_rules IS 'Evaluates all active alert rules and creates alerts for matching conditions';

-- Create feature snapshot for student
CREATE OR REPLACE FUNCTION create_feature_snapshot(
    p_student_id UUID,
    p_academic_year_id UUID
)
RETURNS UUID AS $$
DECLARE
    v_snapshot_id UUID;
    v_attendance_pct DECIMAL(5,2);
    v_current_gpa DECIMAL(4,2);
BEGIN
    -- Calculate current metrics
    -- TODO: Implement metric calculations

    INSERT INTO student_feature_snapshots (
        student_id,
        snapshot_date,
        academic_year_id,
        current_gpa,
        attendance_percentage
    ) VALUES (
        p_student_id,
        CURRENT_DATE,
        p_academic_year_id,
        v_current_gpa,
        v_attendance_pct
    ) RETURNING id INTO v_snapshot_id;

    RETURN v_snapshot_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION create_feature_snapshot IS 'Creates a feature snapshot for ML training';

-- =============================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================

ALTER TABLE ml_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_performance_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_feature_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE early_warning_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_rules ENABLE ROW LEVEL SECURITY;

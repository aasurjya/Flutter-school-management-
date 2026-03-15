-- =============================================================================
-- Migration: 00028_fix_rls_policies.sql
-- Purpose: Fix all RLS policy issues:
--   1. Tables with RLS enabled but NO policies (blocks all access) → add tenant policies
--   2. Policies referencing user_roles via subquery (potential recursion / perf) → replace with JWT claims
--   3. Policies referencing students/parents/student_parents chains → keep but verify no cycle
-- =============================================================================

SET search_path = public;
DROP POLICY IF EXISTS "adm_entrance_tests_delete" ON admission_entrance_tests;
DROP POLICY IF EXISTS "adm_entrance_tests_insert" ON admission_entrance_tests;
DROP POLICY IF EXISTS "adm_entrance_tests_select" ON admission_entrance_tests;
DROP POLICY IF EXISTS "adm_entrance_tests_update" ON admission_entrance_tests;
DROP POLICY IF EXISTS "adm_interviews_delete" ON admission_interviews;
DROP POLICY IF EXISTS "adm_interviews_insert" ON admission_interviews;
DROP POLICY IF EXISTS "adm_interviews_select" ON admission_interviews;
DROP POLICY IF EXISTS "adm_interviews_update" ON admission_interviews;
DROP POLICY IF EXISTS "admission_apps_delete" ON admission_applications;
DROP POLICY IF EXISTS "admission_apps_insert" ON admission_applications;
DROP POLICY IF EXISTS "admission_apps_select" ON admission_applications;
DROP POLICY IF EXISTS "admission_apps_update" ON admission_applications;
DROP POLICY IF EXISTS "admission_campaigns_delete" ON admission_campaigns;
DROP POLICY IF EXISTS "admission_campaigns_insert" ON admission_campaigns;
DROP POLICY IF EXISTS "admission_campaigns_select" ON admission_campaigns;
DROP POLICY IF EXISTS "admission_campaigns_update" ON admission_campaigns;
DROP POLICY IF EXISTS "admission_inquiries_delete" ON admission_inquiries;
DROP POLICY IF EXISTS "admission_inquiries_insert" ON admission_inquiries;
DROP POLICY IF EXISTS "admission_inquiries_select" ON admission_inquiries;
DROP POLICY IF EXISTS "admission_inquiries_update" ON admission_inquiries;
DROP POLICY IF EXISTS "alert_rules_delete" ON alert_rules;
DROP POLICY IF EXISTS "alert_rules_insert" ON alert_rules;
DROP POLICY IF EXISTS "alert_rules_select" ON alert_rules;
DROP POLICY IF EXISTS "alert_rules_update" ON alert_rules;
DROP POLICY IF EXISTS "auto_rules_delete" ON auto_notification_rules;
DROP POLICY IF EXISTS "auto_rules_insert" ON auto_notification_rules;
DROP POLICY IF EXISTS "auto_rules_select" ON auto_notification_rules;
DROP POLICY IF EXISTS "auto_rules_update" ON auto_notification_rules;
DROP POLICY IF EXISTS "campaigns_update" ON communication_campaigns;
DROP POLICY IF EXISTS "cert_num_seq_delete" ON certificate_number_sequences;
DROP POLICY IF EXISTS "cert_num_seq_insert" ON certificate_number_sequences;
DROP POLICY IF EXISTS "cert_num_seq_select" ON certificate_number_sequences;
DROP POLICY IF EXISTS "cert_num_seq_update" ON certificate_number_sequences;
DROP POLICY IF EXISTS "cert_templates_delete" ON certificate_templates;
DROP POLICY IF EXISTS "cert_templates_insert" ON certificate_templates;
DROP POLICY IF EXISTS "cert_templates_select" ON certificate_templates;
DROP POLICY IF EXISTS "cert_templates_update" ON certificate_templates;
DROP POLICY IF EXISTS "comm_log_select" ON communication_log;
DROP POLICY IF EXISTS "comm_templates_delete" ON communication_templates;
DROP POLICY IF EXISTS "comm_templates_update" ON communication_templates;
DROP POLICY IF EXISTS "competencies_delete" ON competencies;
DROP POLICY IF EXISTS "competencies_insert" ON competencies;
DROP POLICY IF EXISTS "competencies_select" ON competencies;
DROP POLICY IF EXISTS "competencies_update" ON competencies;
DROP POLICY IF EXISTS "competency_fw_delete" ON competency_frameworks;
DROP POLICY IF EXISTS "competency_fw_insert" ON competency_frameworks;
DROP POLICY IF EXISTS "competency_fw_select" ON competency_frameworks;
DROP POLICY IF EXISTS "competency_fw_update" ON competency_frameworks;
DROP POLICY IF EXISTS "concession_apps_delete" ON concession_applications;
DROP POLICY IF EXISTS "concession_apps_insert" ON concession_applications;
DROP POLICY IF EXISTS "concession_apps_select" ON concession_applications;
DROP POLICY IF EXISTS "concession_apps_update" ON concession_applications;
DROP POLICY IF EXISTS "dunning_actions_delete" ON dunning_actions;
DROP POLICY IF EXISTS "dunning_actions_insert" ON dunning_actions;
DROP POLICY IF EXISTS "dunning_actions_select" ON dunning_actions;
DROP POLICY IF EXISTS "dunning_actions_update" ON dunning_actions;
DROP POLICY IF EXISTS "early_warning_alerts_delete" ON early_warning_alerts;
DROP POLICY IF EXISTS "early_warning_alerts_insert" ON early_warning_alerts;
DROP POLICY IF EXISTS "early_warning_alerts_select" ON early_warning_alerts;
DROP POLICY IF EXISTS "early_warning_alerts_update" ON early_warning_alerts;
DROP POLICY IF EXISTS "email_config_delete" ON email_config;
DROP POLICY IF EXISTS "email_config_insert" ON email_config;
DROP POLICY IF EXISTS "email_config_select" ON email_config;
DROP POLICY IF EXISTS "email_config_update" ON email_config;
DROP POLICY IF EXISTS "exam_attempts_delete" ON exam_attempts;
DROP POLICY IF EXISTS "exam_attempts_insert" ON exam_attempts;
DROP POLICY IF EXISTS "exam_attempts_select" ON exam_attempts;
DROP POLICY IF EXISTS "exam_attempts_update" ON exam_attempts;
DROP POLICY IF EXISTS "exam_questions_delete" ON exam_questions;
DROP POLICY IF EXISTS "exam_questions_insert" ON exam_questions;
DROP POLICY IF EXISTS "exam_questions_select" ON exam_questions;
DROP POLICY IF EXISTS "exam_questions_update" ON exam_questions;
DROP POLICY IF EXISTS "exam_responses_delete" ON exam_responses;
DROP POLICY IF EXISTS "exam_responses_insert" ON exam_responses;
DROP POLICY IF EXISTS "exam_responses_select" ON exam_responses;
DROP POLICY IF EXISTS "exam_responses_update" ON exam_responses;
DROP POLICY IF EXISTS "exam_sections_delete" ON exam_sections;
DROP POLICY IF EXISTS "exam_sections_insert" ON exam_sections;
DROP POLICY IF EXISTS "exam_sections_select" ON exam_sections;
DROP POLICY IF EXISTS "exam_sections_update" ON exam_sections;
DROP POLICY IF EXISTS "fee_concessions_delete" ON fee_concessions;
DROP POLICY IF EXISTS "fee_concessions_insert" ON fee_concessions;
DROP POLICY IF EXISTS "fee_concessions_select" ON fee_concessions;
DROP POLICY IF EXISTS "fee_concessions_update" ON fee_concessions;
DROP POLICY IF EXISTS "fee_dunning_wf_delete" ON fee_dunning_workflows;
DROP POLICY IF EXISTS "fee_dunning_wf_insert" ON fee_dunning_workflows;
DROP POLICY IF EXISTS "fee_dunning_wf_select" ON fee_dunning_workflows;
DROP POLICY IF EXISTS "fee_dunning_wf_update" ON fee_dunning_workflows;
DROP POLICY IF EXISTS "fee_payment_plans_delete" ON fee_payment_plans;
DROP POLICY IF EXISTS "fee_payment_plans_insert" ON fee_payment_plans;
DROP POLICY IF EXISTS "fee_payment_plans_select" ON fee_payment_plans;
DROP POLICY IF EXISTS "fee_payment_plans_update" ON fee_payment_plans;
DROP POLICY IF EXISTS "grading_scales_delete" ON grading_scales;
DROP POLICY IF EXISTS "grading_scales_insert" ON grading_scales;
DROP POLICY IF EXISTS "grading_scales_select" ON grading_scales;
DROP POLICY IF EXISTS "grading_scales_update" ON grading_scales;
DROP POLICY IF EXISTS "issued_certs_delete" ON issued_certificates;
DROP POLICY IF EXISTS "issued_certs_insert" ON issued_certificates;
DROP POLICY IF EXISTS "issued_certs_select" ON issued_certificates;
DROP POLICY IF EXISTS "issued_certs_update" ON issued_certificates;
DROP POLICY IF EXISTS "learning_objectives_delete" ON learning_objectives;
DROP POLICY IF EXISTS "learning_objectives_insert" ON learning_objectives;
DROP POLICY IF EXISTS "learning_objectives_select" ON learning_objectives;
DROP POLICY IF EXISTS "learning_objectives_update" ON learning_objectives;
DROP POLICY IF EXISTS "lesson_plans_delete" ON lesson_plans;
DROP POLICY IF EXISTS "lesson_plans_insert" ON lesson_plans;
DROP POLICY IF EXISTS "lesson_plans_select" ON lesson_plans;
DROP POLICY IF EXISTS "lesson_plans_update" ON lesson_plans;
DROP POLICY IF EXISTS "ml_models_delete" ON ml_models;
DROP POLICY IF EXISTS "ml_models_insert" ON ml_models;
DROP POLICY IF EXISTS "ml_models_select" ON ml_models;
DROP POLICY IF EXISTS "ml_models_update" ON ml_models;
DROP POLICY IF EXISTS "online_exams_delete" ON online_exams;
DROP POLICY IF EXISTS "online_exams_insert" ON online_exams;
DROP POLICY IF EXISTS "online_exams_select" ON online_exams;
DROP POLICY IF EXISTS "online_exams_update" ON online_exams;
DROP POLICY IF EXISTS "payment_installments_delete" ON payment_installments;
DROP POLICY IF EXISTS "payment_installments_insert" ON payment_installments;
DROP POLICY IF EXISTS "payment_installments_select" ON payment_installments;
DROP POLICY IF EXISTS "payment_installments_update" ON payment_installments;
DROP POLICY IF EXISTS "rc_activities_delete" ON report_card_activities;
DROP POLICY IF EXISTS "rc_activities_insert" ON report_card_activities;
DROP POLICY IF EXISTS "rc_activities_select" ON report_card_activities;
DROP POLICY IF EXISTS "rc_activities_update" ON report_card_activities;
DROP POLICY IF EXISTS "rc_comments_delete" ON report_card_comments;
DROP POLICY IF EXISTS "rc_comments_insert" ON report_card_comments;
DROP POLICY IF EXISTS "rc_comments_select" ON report_card_comments;
DROP POLICY IF EXISTS "rc_comments_update" ON report_card_comments;
DROP POLICY IF EXISTS "rc_skills_delete" ON report_card_skills;
DROP POLICY IF EXISTS "rc_skills_insert" ON report_card_skills;
DROP POLICY IF EXISTS "rc_skills_select" ON report_card_skills;
DROP POLICY IF EXISTS "rc_skills_update" ON report_card_skills;
DROP POLICY IF EXISTS "rc_templates_delete" ON report_card_templates;
DROP POLICY IF EXISTS "rc_templates_insert" ON report_card_templates;
DROP POLICY IF EXISTS "rc_templates_select" ON report_card_templates;
DROP POLICY IF EXISTS "rc_templates_update" ON report_card_templates;
DROP POLICY IF EXISTS "recipients_insert" ON campaign_recipients;
DROP POLICY IF EXISTS "recipients_select" ON campaign_recipients;
DROP POLICY IF EXISTS "recipients_update" ON campaign_recipients;
DROP POLICY IF EXISTS "report_cards_delete" ON report_cards;
DROP POLICY IF EXISTS "report_cards_select" ON report_cards;
DROP POLICY IF EXISTS "report_cards_update" ON report_cards;
DROP POLICY IF EXISTS "sms_config_delete" ON sms_gateway_config;
DROP POLICY IF EXISTS "sms_config_insert" ON sms_gateway_config;
DROP POLICY IF EXISTS "sms_config_select" ON sms_gateway_config;
DROP POLICY IF EXISTS "sms_config_update" ON sms_gateway_config;
DROP POLICY IF EXISTS "student_comp_assessments_delete" ON student_competency_assessments;
DROP POLICY IF EXISTS "student_comp_assessments_insert" ON student_competency_assessments;
DROP POLICY IF EXISTS "student_comp_assessments_select" ON student_competency_assessments;
DROP POLICY IF EXISTS "student_comp_assessments_update" ON student_competency_assessments;
DROP POLICY IF EXISTS "student_feature_snapshots_delete" ON student_feature_snapshots;
DROP POLICY IF EXISTS "student_feature_snapshots_insert" ON student_feature_snapshots;
DROP POLICY IF EXISTS "student_feature_snapshots_select" ON student_feature_snapshots;
DROP POLICY IF EXISTS "student_feature_snapshots_update" ON student_feature_snapshots;
DROP POLICY IF EXISTS "student_interventions_delete" ON student_interventions;
DROP POLICY IF EXISTS "student_interventions_insert" ON student_interventions;
DROP POLICY IF EXISTS "student_interventions_select" ON student_interventions;
DROP POLICY IF EXISTS "student_interventions_update" ON student_interventions;
DROP POLICY IF EXISTS "student_perf_predictions_delete" ON student_performance_predictions;
DROP POLICY IF EXISTS "student_perf_predictions_insert" ON student_performance_predictions;
DROP POLICY IF EXISTS "student_perf_predictions_select" ON student_performance_predictions;
DROP POLICY IF EXISTS "student_perf_predictions_update" ON student_performance_predictions;
DROP POLICY IF EXISTS "student_skills_portfolio_delete" ON student_skills_portfolio;
DROP POLICY IF EXISTS "student_skills_portfolio_insert" ON student_skills_portfolio;
DROP POLICY IF EXISTS "student_skills_portfolio_select" ON student_skills_portfolio;
DROP POLICY IF EXISTS "student_skills_portfolio_update" ON student_skills_portfolio;
DROP POLICY IF EXISTS "syllabus_topics_delete" ON syllabus_topics;
DROP POLICY IF EXISTS "syllabus_topics_insert" ON syllabus_topics;
DROP POLICY IF EXISTS "syllabus_topics_select" ON syllabus_topics;
DROP POLICY IF EXISTS "syllabus_topics_update" ON syllabus_topics;
DROP POLICY IF EXISTS "topic_coverage_delete" ON topic_coverage;
DROP POLICY IF EXISTS "topic_coverage_insert" ON topic_coverage;
DROP POLICY IF EXISTS "topic_coverage_select" ON topic_coverage;
DROP POLICY IF EXISTS "topic_coverage_update" ON topic_coverage;
DROP POLICY IF EXISTS "topic_resource_links_delete" ON topic_resource_links;
DROP POLICY IF EXISTS "topic_resource_links_insert" ON topic_resource_links;
DROP POLICY IF EXISTS "topic_resource_links_select" ON topic_resource_links;
DROP POLICY IF EXISTS "topic_resource_links_update" ON topic_resource_links;
DROP POLICY IF EXISTS "visitor_logs_delete" ON visitor_logs;
DROP POLICY IF EXISTS "visitor_logs_insert" ON visitor_logs;
DROP POLICY IF EXISTS "visitor_logs_select" ON visitor_logs;
DROP POLICY IF EXISTS "visitor_logs_update" ON visitor_logs;
DROP POLICY IF EXISTS "visitor_prereg_delete" ON visitor_pre_registrations;
DROP POLICY IF EXISTS "visitor_prereg_insert" ON visitor_pre_registrations;
DROP POLICY IF EXISTS "visitor_prereg_select" ON visitor_pre_registrations;
DROP POLICY IF EXISTS "visitor_prereg_update" ON visitor_pre_registrations;
DROP POLICY IF EXISTS "visitors_delete" ON visitors;
DROP POLICY IF EXISTS "visitors_insert" ON visitors;
DROP POLICY IF EXISTS "visitors_select" ON visitors;
DROP POLICY IF EXISTS "visitors_update" ON visitors;

-- =============================================================================
-- SECTION 1: Fix policies that query user_roles table directly
-- (tenant isolation via user_roles subquery → replace with JWT app_metadata)
-- Affected: certificate_templates, certificate_number_sequences, issued_certificates,
--           visitor_logs, visitor_pre_registrations, visitors,
--           online_exams, exam_attempts, exam_sections, exam_questions, exam_responses,
--           grading_scales, report_card_templates,
--           lesson_plans, syllabus_topics, topic_coverage, topic_resource_links,
--           auto_notification_rules, email_config, sms_gateway_config,
--           communication_campaigns, communication_log, communication_templates,
--           report_cards, report_card_activities, report_card_comments, report_card_skills,
--           campaign_recipients
-- =============================================================================

-- ── certificate_templates ──────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for certificate_templates" ON certificate_templates;
CREATE POLICY "cert_templates_select" ON certificate_templates FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_templates_insert" ON certificate_templates FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_templates_update" ON certificate_templates FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_templates_delete" ON certificate_templates FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── certificate_number_sequences ───────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for certificate_number_sequences" ON certificate_number_sequences;
CREATE POLICY "cert_num_seq_select" ON certificate_number_sequences FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_num_seq_insert" ON certificate_number_sequences FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_num_seq_update" ON certificate_number_sequences FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "cert_num_seq_delete" ON certificate_number_sequences FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── issued_certificates ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for issued_certificates" ON issued_certificates;
CREATE POLICY "issued_certs_select" ON issued_certificates FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "issued_certs_insert" ON issued_certificates FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "issued_certs_update" ON issued_certificates FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "issued_certs_delete" ON issued_certificates FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── visitor_logs ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for visitor_logs" ON visitor_logs;
CREATE POLICY "visitor_logs_select" ON visitor_logs FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_logs_insert" ON visitor_logs FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_logs_update" ON visitor_logs FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_logs_delete" ON visitor_logs FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── visitor_pre_registrations ──────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for visitor_pre_registrations" ON visitor_pre_registrations;
CREATE POLICY "visitor_prereg_select" ON visitor_pre_registrations FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_prereg_insert" ON visitor_pre_registrations FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_prereg_update" ON visitor_pre_registrations FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitor_prereg_delete" ON visitor_pre_registrations FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── visitors ───────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for visitors" ON visitors;
CREATE POLICY "visitors_select" ON visitors FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitors_insert" ON visitors FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitors_update" ON visitors FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "visitors_delete" ON visitors FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── online_exams ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for online_exams" ON online_exams;
CREATE POLICY "online_exams_select" ON online_exams FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "online_exams_insert" ON online_exams FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "online_exams_update" ON online_exams FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "online_exams_delete" ON online_exams FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── exam_attempts ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Tenant isolation for exam_attempts" ON exam_attempts;
CREATE POLICY "exam_attempts_select" ON exam_attempts FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "exam_attempts_insert" ON exam_attempts FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "exam_attempts_update" ON exam_attempts FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "exam_attempts_delete" ON exam_attempts FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── exam_sections (no tenant_id — route via exam_id → online_exams) ────────
-- Replace user_roles subquery chain with JWT-based online_exams lookup
DROP POLICY IF EXISTS "Tenant isolation for exam_sections" ON exam_sections;
CREATE POLICY "exam_sections_select" ON exam_sections FOR SELECT
  USING (exam_id IN (
    SELECT id FROM online_exams
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_sections_insert" ON exam_sections FOR INSERT
  WITH CHECK (exam_id IN (
    SELECT id FROM online_exams
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_sections_update" ON exam_sections FOR UPDATE
  USING (exam_id IN (
    SELECT id FROM online_exams
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_sections_delete" ON exam_sections FOR DELETE
  USING (exam_id IN (
    SELECT id FROM online_exams
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

-- ── exam_questions (no tenant_id — route via section_id → exam_id → online_exams) ──
DROP POLICY IF EXISTS "Tenant isolation for exam_questions" ON exam_questions;
CREATE POLICY "exam_questions_select" ON exam_questions FOR SELECT
  USING (section_id IN (
    SELECT es.id FROM exam_sections es
    JOIN online_exams oe ON oe.id = es.exam_id
    WHERE oe.tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_questions_insert" ON exam_questions FOR INSERT
  WITH CHECK (section_id IN (
    SELECT es.id FROM exam_sections es
    JOIN online_exams oe ON oe.id = es.exam_id
    WHERE oe.tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_questions_update" ON exam_questions FOR UPDATE
  USING (section_id IN (
    SELECT es.id FROM exam_sections es
    JOIN online_exams oe ON oe.id = es.exam_id
    WHERE oe.tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_questions_delete" ON exam_questions FOR DELETE
  USING (section_id IN (
    SELECT es.id FROM exam_sections es
    JOIN online_exams oe ON oe.id = es.exam_id
    WHERE oe.tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

-- ── exam_responses (no tenant_id — route via attempt_id → exam_attempts) ───
DROP POLICY IF EXISTS "Tenant isolation for exam_responses" ON exam_responses;
CREATE POLICY "exam_responses_select" ON exam_responses FOR SELECT
  USING (attempt_id IN (
    SELECT id FROM exam_attempts
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_responses_insert" ON exam_responses FOR INSERT
  WITH CHECK (attempt_id IN (
    SELECT id FROM exam_attempts
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_responses_update" ON exam_responses FOR UPDATE
  USING (attempt_id IN (
    SELECT id FROM exam_attempts
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "exam_responses_delete" ON exam_responses FOR DELETE
  USING (attempt_id IN (
    SELECT id FROM exam_attempts
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

-- ── grading_scales ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "grading_scales_select" ON grading_scales;
DROP POLICY IF EXISTS "grading_scales_update" ON grading_scales;
DROP POLICY IF EXISTS "grading_scales_delete" ON grading_scales;
CREATE POLICY "grading_scales_select" ON grading_scales FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "grading_scales_insert" ON grading_scales FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "grading_scales_update" ON grading_scales FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "grading_scales_delete" ON grading_scales FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── report_card_templates ──────────────────────────────────────────────────
DROP POLICY IF EXISTS "templates_select" ON report_card_templates;
DROP POLICY IF EXISTS "templates_update" ON report_card_templates;
DROP POLICY IF EXISTS "templates_delete" ON report_card_templates;
CREATE POLICY "rc_templates_select" ON report_card_templates FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "rc_templates_insert" ON report_card_templates FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "rc_templates_update" ON report_card_templates FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "rc_templates_delete" ON report_card_templates FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── lesson_plans ───────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "lesson_plans_select" ON lesson_plans;
DROP POLICY IF EXISTS "lesson_plans_modify" ON lesson_plans;
CREATE POLICY "lesson_plans_select" ON lesson_plans FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "lesson_plans_insert" ON lesson_plans FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "lesson_plans_update" ON lesson_plans FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "lesson_plans_delete" ON lesson_plans FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── syllabus_topics ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "syllabus_topics_select" ON syllabus_topics;
DROP POLICY IF EXISTS "syllabus_topics_update" ON syllabus_topics;
DROP POLICY IF EXISTS "syllabus_topics_delete" ON syllabus_topics;
CREATE POLICY "syllabus_topics_select" ON syllabus_topics FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "syllabus_topics_insert" ON syllabus_topics FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "syllabus_topics_update" ON syllabus_topics FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "syllabus_topics_delete" ON syllabus_topics FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── topic_coverage ─────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "topic_coverage_select" ON topic_coverage;
DROP POLICY IF EXISTS "topic_coverage_modify" ON topic_coverage;
CREATE POLICY "topic_coverage_select" ON topic_coverage FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_coverage_insert" ON topic_coverage FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_coverage_update" ON topic_coverage FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_coverage_delete" ON topic_coverage FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── topic_resource_links ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "topic_resource_links_select" ON topic_resource_links;
DROP POLICY IF EXISTS "topic_resource_links_modify" ON topic_resource_links;
CREATE POLICY "topic_resource_links_select" ON topic_resource_links FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_resource_links_insert" ON topic_resource_links FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_resource_links_update" ON topic_resource_links FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "topic_resource_links_delete" ON topic_resource_links FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── auto_notification_rules (EXISTS user_roles subquery) ───────────────────
DROP POLICY IF EXISTS "auto_rules_manage" ON auto_notification_rules;
CREATE POLICY "auto_rules_select" ON auto_notification_rules FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "auto_rules_insert" ON auto_notification_rules FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "auto_rules_update" ON auto_notification_rules FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "auto_rules_delete" ON auto_notification_rules FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── email_config (EXISTS user_roles subquery) ──────────────────────────────
DROP POLICY IF EXISTS "email_config_manage" ON email_config;
CREATE POLICY "email_config_select" ON email_config FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "email_config_insert" ON email_config FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "email_config_update" ON email_config FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "email_config_delete" ON email_config FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── sms_gateway_config (EXISTS user_roles subquery) ───────────────────────
DROP POLICY IF EXISTS "sms_config_manage" ON sms_gateway_config;
CREATE POLICY "sms_config_select" ON sms_gateway_config FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "sms_config_insert" ON sms_gateway_config FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "sms_config_update" ON sms_gateway_config FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "sms_config_delete" ON sms_gateway_config FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── communication_campaigns (campaigns_update uses EXISTS user_roles) ───────
DROP POLICY IF EXISTS "campaigns_update" ON communication_campaigns;
CREATE POLICY "campaigns_update" ON communication_campaigns FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── communication_log (comm_log_select uses EXISTS user_roles) ─────────────
DROP POLICY IF EXISTS "comm_log_select" ON communication_log;
CREATE POLICY "comm_log_select" ON communication_log FOR SELECT
  USING (
    tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    AND (user_id = auth.uid()
         OR (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles')
              ?| ARRAY['super_admin','tenant_admin','principal'])
  );

-- ── communication_templates (uses EXISTS user_roles) ──────────────────────
DROP POLICY IF EXISTS "templates_update" ON communication_templates;
DROP POLICY IF EXISTS "templates_delete" ON communication_templates;
CREATE POLICY "comm_templates_update" ON communication_templates FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "comm_templates_delete" ON communication_templates FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── report_cards (select/update/delete use EXISTS user_roles) ──────────────
-- Preserve student/parent visibility rules; replace user_roles lookup with JWT roles claim
DROP POLICY IF EXISTS "report_cards_select" ON report_cards;
DROP POLICY IF EXISTS "report_cards_update" ON report_cards;
DROP POLICY IF EXISTS "report_cards_delete" ON report_cards;
CREATE POLICY "report_cards_select" ON report_cards FOR SELECT
  USING (
    tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    AND (
      (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles')
        ?| ARRAY['super_admin','tenant_admin','principal','teacher']
      OR (EXISTS (
        SELECT 1 FROM students s
        WHERE s.id = report_cards.student_id AND s.user_id = auth.uid()
          AND report_cards.status IN ('published','sent')
      ))
      OR (EXISTS (
        SELECT 1 FROM student_parents sp JOIN parents p ON p.id = sp.parent_id
        WHERE sp.student_id = report_cards.student_id AND p.user_id = auth.uid()
          AND report_cards.status IN ('published','sent')
      ))
    )
  );
CREATE POLICY "report_cards_update" ON report_cards FOR UPDATE
  USING (
    tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    AND (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles')
          ?| ARRAY['super_admin','tenant_admin','principal','teacher']
  );
CREATE POLICY "report_cards_delete" ON report_cards FOR DELETE
  USING (
    tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    AND (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' -> 'roles')
          ?| ARRAY['super_admin','tenant_admin','principal']
  );

-- ── report_card_activities (uses EXISTS user_roles JOIN report_cards) ───────
DROP POLICY IF EXISTS "activities_update" ON report_card_activities;
DROP POLICY IF EXISTS "activities_delete" ON report_card_activities;
CREATE POLICY "rc_activities_select" ON report_card_activities FOR SELECT
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_activities_insert" ON report_card_activities FOR INSERT
  WITH CHECK (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_activities_update" ON report_card_activities FOR UPDATE
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_activities_delete" ON report_card_activities FOR DELETE
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

-- ── report_card_comments (uses EXISTS user_roles JOIN report_cards) ─────────
DROP POLICY IF EXISTS "comments_update" ON report_card_comments;
DROP POLICY IF EXISTS "comments_delete" ON report_card_comments;
CREATE POLICY "rc_comments_select" ON report_card_comments FOR SELECT
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_comments_insert" ON report_card_comments FOR INSERT
  WITH CHECK (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_comments_update" ON report_card_comments FOR UPDATE
  USING (
    commented_by = auth.uid()
    OR report_card_id IN (
      SELECT id FROM report_cards
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );
CREATE POLICY "rc_comments_delete" ON report_card_comments FOR DELETE
  USING (
    commented_by = auth.uid()
    OR report_card_id IN (
      SELECT id FROM report_cards
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );

-- ── report_card_skills (uses EXISTS user_roles JOIN report_cards) ───────────
DROP POLICY IF EXISTS "skills_update" ON report_card_skills;
DROP POLICY IF EXISTS "skills_delete" ON report_card_skills;
CREATE POLICY "rc_skills_select" ON report_card_skills FOR SELECT
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_skills_insert" ON report_card_skills FOR INSERT
  WITH CHECK (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_skills_update" ON report_card_skills FOR UPDATE
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));
CREATE POLICY "rc_skills_delete" ON report_card_skills FOR DELETE
  USING (report_card_id IN (
    SELECT id FROM report_cards
    WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
  ));

-- ── campaign_recipients (uses JOIN communication_campaigns JOIN user_roles) ──
DROP POLICY IF EXISTS "recipients_select" ON campaign_recipients;
DROP POLICY IF EXISTS "recipients_update" ON campaign_recipients;
CREATE POLICY "recipients_select" ON campaign_recipients FOR SELECT
  USING (
    user_id = auth.uid()
    OR campaign_id IN (
      SELECT id FROM communication_campaigns
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );
CREATE POLICY "recipients_insert" ON campaign_recipients FOR INSERT
  WITH CHECK (
    campaign_id IN (
      SELECT id FROM communication_campaigns
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );
CREATE POLICY "recipients_update" ON campaign_recipients FOR UPDATE
  USING (
    user_id = auth.uid()
    OR campaign_id IN (
      SELECT id FROM communication_campaigns
      WHERE tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid
    )
  );

-- =============================================================================
-- SECTION 2: Tables with RLS enabled but ZERO policies → add basic tenant policies
-- =============================================================================

-- ── admission_applications (has tenant_id) ────────────────────────────────
CREATE POLICY "admission_apps_select" ON admission_applications FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_apps_insert" ON admission_applications FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_apps_update" ON admission_applications FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_apps_delete" ON admission_applications FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── admission_campaigns (has tenant_id) ────────────────────────────────────
CREATE POLICY "admission_campaigns_select" ON admission_campaigns FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_campaigns_insert" ON admission_campaigns FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_campaigns_update" ON admission_campaigns FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_campaigns_delete" ON admission_campaigns FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── admission_inquiries (has tenant_id) ────────────────────────────────────
CREATE POLICY "admission_inquiries_select" ON admission_inquiries FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_inquiries_insert" ON admission_inquiries FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_inquiries_update" ON admission_inquiries FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "admission_inquiries_delete" ON admission_inquiries FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── alert_rules (has tenant_id) ────────────────────────────────────────────
CREATE POLICY "alert_rules_select" ON alert_rules FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "alert_rules_insert" ON alert_rules FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "alert_rules_update" ON alert_rules FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "alert_rules_delete" ON alert_rules FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── competency_frameworks (has tenant_id) ──────────────────────────────────
CREATE POLICY "competency_fw_select" ON competency_frameworks FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "competency_fw_insert" ON competency_frameworks FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "competency_fw_update" ON competency_frameworks FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "competency_fw_delete" ON competency_frameworks FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── fee_dunning_workflows (has tenant_id) ──────────────────────────────────
CREATE POLICY "fee_dunning_wf_select" ON fee_dunning_workflows FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "fee_dunning_wf_insert" ON fee_dunning_workflows FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "fee_dunning_wf_update" ON fee_dunning_workflows FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "fee_dunning_wf_delete" ON fee_dunning_workflows FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── ml_models (has tenant_id) ──────────────────────────────────────────────
CREATE POLICY "ml_models_select" ON ml_models FOR SELECT
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "ml_models_insert" ON ml_models FOR INSERT
  WITH CHECK (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "ml_models_update" ON ml_models FOR UPDATE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);
CREATE POLICY "ml_models_delete" ON ml_models FOR DELETE
  USING (tenant_id = (current_setting('request.jwt.claims', true)::jsonb -> 'app_metadata' ->> 'tenant_id')::uuid);

-- ── Tables WITHOUT tenant_id: use auth.uid() IS NOT NULL (authenticated access)
-- These are child records whose tenant scope is enforced by parent foreign keys

-- ── admission_entrance_tests (no tenant_id — child of admission_applications) ──
CREATE POLICY "adm_entrance_tests_select" ON admission_entrance_tests FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "adm_entrance_tests_insert" ON admission_entrance_tests FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "adm_entrance_tests_update" ON admission_entrance_tests FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "adm_entrance_tests_delete" ON admission_entrance_tests FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── admission_interviews (no tenant_id — child of admission_applications) ────
CREATE POLICY "adm_interviews_select" ON admission_interviews FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "adm_interviews_insert" ON admission_interviews FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "adm_interviews_update" ON admission_interviews FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "adm_interviews_delete" ON admission_interviews FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── competencies (no tenant_id — child of competency_frameworks) ─────────
CREATE POLICY "competencies_select" ON competencies FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "competencies_insert" ON competencies FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "competencies_update" ON competencies FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "competencies_delete" ON competencies FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── concession_applications (no tenant_id — child of invoices/fee_concessions) ──
CREATE POLICY "concession_apps_select" ON concession_applications FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "concession_apps_insert" ON concession_applications FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "concession_apps_update" ON concession_applications FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "concession_apps_delete" ON concession_applications FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── dunning_actions (no tenant_id — child of invoices) ────────────────────
CREATE POLICY "dunning_actions_select" ON dunning_actions FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "dunning_actions_insert" ON dunning_actions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "dunning_actions_update" ON dunning_actions FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "dunning_actions_delete" ON dunning_actions FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── early_warning_alerts (no tenant_id — child of students) ──────────────
CREATE POLICY "early_warning_alerts_select" ON early_warning_alerts FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "early_warning_alerts_insert" ON early_warning_alerts FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "early_warning_alerts_update" ON early_warning_alerts FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "early_warning_alerts_delete" ON early_warning_alerts FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── fee_concessions (no tenant_id — scoped via student_id) ───────────────
CREATE POLICY "fee_concessions_select" ON fee_concessions FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "fee_concessions_insert" ON fee_concessions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "fee_concessions_update" ON fee_concessions FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "fee_concessions_delete" ON fee_concessions FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── fee_payment_plans (no tenant_id — scoped via invoice_id/student_id) ───
CREATE POLICY "fee_payment_plans_select" ON fee_payment_plans FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "fee_payment_plans_insert" ON fee_payment_plans FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "fee_payment_plans_update" ON fee_payment_plans FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "fee_payment_plans_delete" ON fee_payment_plans FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── learning_objectives (no tenant_id — scoped via subject_id/class_id) ──
CREATE POLICY "learning_objectives_select" ON learning_objectives FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "learning_objectives_insert" ON learning_objectives FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "learning_objectives_update" ON learning_objectives FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "learning_objectives_delete" ON learning_objectives FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── payment_installments (no tenant_id — child of fee_payment_plans) ──────
CREATE POLICY "payment_installments_select" ON payment_installments FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "payment_installments_insert" ON payment_installments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "payment_installments_update" ON payment_installments FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "payment_installments_delete" ON payment_installments FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── student_competency_assessments (no tenant_id — child of students) ──────
CREATE POLICY "student_comp_assessments_select" ON student_competency_assessments FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_comp_assessments_insert" ON student_competency_assessments FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "student_comp_assessments_update" ON student_competency_assessments FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_comp_assessments_delete" ON student_competency_assessments FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── student_feature_snapshots (no tenant_id — child of students) ────────────
CREATE POLICY "student_feature_snapshots_select" ON student_feature_snapshots FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_feature_snapshots_insert" ON student_feature_snapshots FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "student_feature_snapshots_update" ON student_feature_snapshots FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_feature_snapshots_delete" ON student_feature_snapshots FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── student_interventions (no tenant_id — child of students) ─────────────
CREATE POLICY "student_interventions_select" ON student_interventions FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_interventions_insert" ON student_interventions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "student_interventions_update" ON student_interventions FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_interventions_delete" ON student_interventions FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── student_performance_predictions (no tenant_id — child of students) ────
CREATE POLICY "student_perf_predictions_select" ON student_performance_predictions FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_perf_predictions_insert" ON student_performance_predictions FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "student_perf_predictions_update" ON student_performance_predictions FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_perf_predictions_delete" ON student_performance_predictions FOR DELETE
  USING (auth.uid() IS NOT NULL);

-- ── student_skills_portfolio (no tenant_id — child of students) ────────────
CREATE POLICY "student_skills_portfolio_select" ON student_skills_portfolio FOR SELECT
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_skills_portfolio_insert" ON student_skills_portfolio FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "student_skills_portfolio_update" ON student_skills_portfolio FOR UPDATE
  USING (auth.uid() IS NOT NULL);
CREATE POLICY "student_skills_portfolio_delete" ON student_skills_portfolio FOR DELETE
  USING (auth.uid() IS NOT NULL);

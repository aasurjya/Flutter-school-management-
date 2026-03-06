# Competitive Feature Build Plan

## Competitor Analysis Summary

### US Leaders (PowerSchool, Alma, Skyward, Gradelink)
- Advanced analytics & state reporting
- AI-powered early intervention
- Parent engagement portals with real-time updates
- Gradebook with weighted averages, standards-based grading
- Curriculum mapping & standards alignment
- District-level multi-school management
- LMS integration (Google Classroom, Canvas)

### Europe Leaders (ManageBac, iSAMS, Classe365)
- IB/Cambridge curriculum management
- Competency-based assessment frameworks
- Alumni management & CRM
- Online store for school items
- Video classrooms & discussion forums
- GDPR compliance built-in
- Multi-language support

### Africa Leaders (SAFSMS/FlexiSAF, Zeraki, SchoolsFocus)
- Offline-first (critical for connectivity)
- Mobile money integration (M-Pesa, etc.)
- SMS-based parent communication
- Low-bandwidth optimization
- Multi-currency fee management
- Government reporting templates
- USSD fallback for non-smartphone users

## What We Have (35 modules)
academic, admin, ai_insights, announcements, assessments, assignments, attendance,
auth, canteen, dashboard, emergency, exams, fees, gamification, health, hostel,
insights, leave, library, messaging, notifications, parent, ptm, qr_scan,
question_paper, reports, resources, student, students, substitution, super_admin,
syllabus, teacher, timetable, transport

## What We're MISSING (Competitive Gaps)

### PHASE 1 - Core Gaps (Must-have to compete)
1. **Online Admission/Enrollment** - Full pipeline: inquiry → application → docs → interview → acceptance → enrollment
2. **Discipline/Behavior Management** - Incidents, referrals, consequences, behavior plans, positive behavior tracking
3. **Communication Hub** - SMS gateway, email campaigns, push notifications, in-app chat, announcement templates
4. **Report Card Generator** - Customizable templates, standards-based, skill-based, narrative comments, PDF/print
5. **Staff HR & Payroll** - Leave management, payroll processing, tax calculations, salary slips, attendance
6. **Inventory/Asset Management** - School assets, lab equipment, sports equipment, furniture tracking

### PHASE 2 - Differentiators (Win the market)
7. **LMS (Learning Management)** - Course content, video lessons, SCORM support, progress tracking, assignments
8. **Online Exam System** - Proctored online exams, auto-grading, question bank pooling, analytics
9. **Alumni Management** - Alumni directory, events, fundraising, mentorship programs, success stories
10. **Visitor Management** - Check-in/out, pre-registration, badge printing, emergency contact
11. **Certificate Generator** - Transfer, bonafide, character, migration, custom templates
12. **School Calendar & Events** - Academic calendar, events, holidays, exam schedules, parent meetings

### PHASE 3 - Market Winners (Beat everyone)
13. **AI Tutoring Assistant** - Per-student AI tutor, adaptive learning, concept explanations, practice problems
14. **Parent Engagement Portal** - Dedicated parent app, homework help requests, teacher booking, fee history
15. **Mobile Money & Multi-Gateway Payments** - M-Pesa, Stripe, Razorpay, Paystack, Flutterwave
16. **Offline-First Mode** - Full offline attendance, marks, sync queue with conflict resolution
17. **Multi-Language Support** - i18n: English, French, Swahili, Hindi, Arabic, Spanish, Portuguese
18. **WhatsApp/SMS Integration** - Automated notifications via WhatsApp Business API, SMS fallback
19. **School Bus GPS Tracking** - Live tracking, route optimization, parent notifications, geofencing
20. **Digital ID Cards** - Student/staff ID with QR, NFC support, access control integration

## Agent Roles
- **agent_admission** - Builds admission/enrollment pipeline
- **agent_discipline** - Builds behavior management system
- **agent_comms** - Builds communication hub
- **agent_reportcard** - Builds report card generator
- **agent_hr** - Builds HR & payroll
- **agent_inventory** - Builds asset management
- **agent_lms** - Builds learning management system
- **agent_online_exam** - Builds proctored exam system
- **agent_alumni** - Builds alumni management
- **agent_visitor** - Builds visitor management
- **agent_certificate** - Builds certificate generator
- **agent_calendar** - Builds school calendar & events
- **agent_ai_tutor** - Builds AI tutoring assistant
- **agent_payments** - Builds multi-gateway payments
- **agent_offline** - Builds offline-first mode
- **agent_i18n** - Builds multi-language support
- **agent_whatsapp** - Builds WhatsApp/SMS integration
- **agent_bus_tracking** - Builds GPS bus tracking
- **agent_digital_id** - Builds digital ID cards

## Execution Order
Phase 1 agents run first (1-6), then Phase 2 (7-12), then Phase 3 (13-20).
Each agent creates: migration SQL, model, repository, provider, screens, widgets, route registration.

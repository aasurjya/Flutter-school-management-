# Core-Flow UX & Feature Audit — Campusly (school_management)

> Generated 2026-06-29 by a fan-out audit workflow (5 flow auditors + 2 competitor/UX researchers → synthesizer).

> Scope: auth, dashboards, attendance, fees, messaging. Lenses: Don Norman/Nielsen UX, competitor SaaS gaps, CLAUDE.md known gaps.


## Executive summary

Across the five core flows the app has a strong repository/provider substrate but a recurring failure pattern: finished data layers and capable repo methods are wired to fabricated UI. The most dangerous items are not crashes but trust violations — fake-but-plausible data presented as live: the payment gateway simulates success and never records the payment against the invoice; the parent dashboard shows a green "child safely arrived at 08:14 AM" derived from an enrollment flag, not attendance; the student weekly attendance calendar is hardcoded; the attendance mark screen silently writes "present" for every untouched student; and the entire chat experience (open thread, send, compose) is canned/no-op despite a fully working MessageRepository. Attendance is the most mature flow (default-present, undo, offline sync) and its gaps are incremental; messaging and the admin/parent dashboards are the most hollow. The fastest wins are wiring already-built dead code (adminKpisProvider, MvBackedKpiStrip, messagesNotifier.sendMessage, recordPayment) into the screens that fake those exact values, plus a cluster of small safety fixes (mounted guards, confirmation dialogs, real error/empty states, 48dp tap targets). Genuinely missing table-stakes (real gateway SDK, FCM push, absence alerts) are larger follow-ups and should not block the first pass.


## Flow health

- **Auth & onboarding** — `usable-with-gaps` — Login/forgot-password/role-routing are solid and polished; self-service signup is unreachable dead code, demo credentials ship in the binary, and a few post-await calls lack mounted guards.
- **Dashboards** — `rough` — Layouts and state-coverage on teacher/student are good, but admin and parent dashboards present fabricated metrics and fake approval/action queues while the real KPI data layer (adminKpisProvider, MvBackedKpiStrip) sits unwired as dead code.
- **Attendance** — `usable-with-gaps` — Most mature flow — default-present, undo, offline sync, idempotent writes — but submit overwrites untouched students as present, the student weekly calendar is fabricated, report filters are dead no-ops, and overwrite has no pre-save confirmation.
- **Fees** — `broken` — Rich admin/parent read surfaces, but the core loop is non-functional: the gateway fakes success, never calls recordPayment, never reconciles the invoice, and never invalidates providers — parents see a green receipt while the invoice stays unpaid.
- **Messaging** — `broken` — Capable, idempotent MessageRepository exists, but the screen is a shell: opening any chat shows hardcoded strangers' messages, Send only shows 'coming soon', compose creates nothing, search/notifications are stubs, and previews/unread badges are always blank.

## Prioritized backlog


### 🔴 CRITICAL

- **Attendance submit silently overwrites untouched students as 'present'** _(flow: attendance · bug · effort L)_
  - Evidence: `mark_attendance_screen.dart:72-82,356-360; quick_mark_sheet.dart:35,164-171; getAttendanceBySection .limit(100) attendance_repository.dart:40-63`
  - Fix: Add an explicit unmarked/null initial status so untouched students are not defaulted to present. In _submitAttendance, filter _snapshotPayload() to only rows whose status differs from the loaded baseline, and block submit (or warn) if any student is still unmarked. Mirror in QuickMarkSheet by tracking explicitly-confirmed-present rows. Remove the .limit(100) cap on getAttendanceBySection (page with range) so the baseline is complete.
  - Impact: A teacher marks 2 absentees and submits; every untouched student (incl. genuinely absent ones, and any beyond the 100-record cap) is written 'present'. Corrupts the attendance ledger — the system of record parents and safety alerts depend on.
- **Payment gateway fakes success and never records the payment against the invoice** _(flow: fees · feature-gap · effort L)_
  - Evidence: `payment_gateway_provider.dart:162-203 ('Simulate gateway call', Future.delayed 2s, fabricated TXN id); recordPayment unused fee_repository.dart:388-432; research source teachmint/fedena/brightwheel CRITICAL`
  - Fix: Integrate a real gateway SDK (razorpay_flutter is already in pubspec) behind InitiatePaymentNotifier.pay(): server-side order create, launch SDK, and on the real success callback call feesNotifierProvider.recordPayment(...) passing gatewayPaymentId/orderId/signature so the existing idempotent payments-table write + invoice trigger runs. Until shipped, gate the Pay Now button behind a clearly labeled 'Demo/Sandbox' notice so it cannot be mistaken for a live charge.
  - Impact: Parent sees a green 'Payment Successful' receipt but no money moves and invoice paid_amount/status never change — invoice still shows pending/overdue. Core fees loop is non-functional and actively misleading.
- **Parent dashboard falsely reports 'Present at school · Safe arrival at 08:14 AM'** _(flow: dashboards · bug · effort M)_
  - Evidence: `parent_dashboard_screen.dart:267-269,338-339 (derived from childMap['is_active'] + hardcoded checkInTime constant)`
  - Fix: Drive the attendance row from a real per-child today's-attendance read (parentChildOverviewProvider exposes weekAttendancePct; add a today's check-in lookup or reuse the attendance repo). Show an explicit 'Attendance not recorded yet' state instead of defaulting to present, and delete the hardcoded 08:14 AM constant.
  - Impact: The single most safety-critical claim a parent reads is fabricated from an enrollment flag, not today's attendance. A child marked absent still shows green 'Safe arrival' — false reassurance.
- **Tapping any chat opens a fake conversation; Send only shows 'coming soon'** _(flow: messaging · bug · effort M)_
  - Evidence: `messages_screen.dart:341-351,607-805 (hardcoded bubbles, no threadId), 768-796 (Send shows SnackBar); working sendMessage proven in ai_message_composer_screen.dart:213-223`
  - Fix: Make _ChatDetailScreen a ConsumerStatefulWidget taking the Thread/threadId; watch messagesProvider(MessagesFilter(threadId)) and render real bubbles with loading/error/empty/data states. Add a TextEditingController to the input and on send call ref.read(messagesNotifierProvider.notifier).sendMessage(content:text); clear on success, show error+Retry on failure. Pass thread.id from _openChat.
  - Impact: Every conversation shows the same canned strangers' messages and no message can actually be sent — the messaging product is a shell despite a fully working idempotent MessageRepository.
- **Admin dashboard shows fabricated metrics + fake approval queue; real KPI layer is unwired dead code** _(flow: dashboards · feature-gap · effort M)_
  - Evidence: `admin_dashboard_screen.dart:196-247,328-399 (hardcoded 94.2%, '2 on leave', fake 'Mrs. Barua' approvals); mv_backed_kpi_strip.dart:29-117 + adminKpisProvider have zero references outside their own files`
  - Fix: Mount MvBackedKpiStrip (reads adminKpisProvider) at the top of AdminDashboardScreen's SliverList to replace _InstitutionPulseGrid literals. Add a real pending-approvals provider (leave requests + admission sign-offs filtered status='pending') behind _PrincipalApprovalQueue with loading/empty/error. Add ref.invalidate(adminKpisProvider) to onRefresh (currently only invalidates currentUserProvider, admin_dashboard_screen.dart:33-36).
  - Impact: Administrators make operational judgements off plausible fake numbers — worse than no numbers. The exact real metrics already exist as finished, cached, tenant-scoped providers that are mounted nowhere.
- **Compose 'New Message' sheet cannot create a thread or send** _(flow: messaging · feature-gap · effort L)_
  - Evidence: `messages_screen.dart:102-212 (ChoiceChips empty onSelected + hardcoded selected:true, no controllers, Send only Navigator.pop)`
  - Fix: Convert the sheet to a stateful form: bind type chips to state, replace 'To' with a real recipient search-select (reuse the picker from ai_message_composer_screen.dart), add controllers, and on Send call threadsNotifier.getOrCreatePrivateThread/createThread then messagesNotifier.sendMessage; show feedback and navigate into the new thread.
  - Impact: The most prominent action — the compose FAB — produces nothing, even though getOrCreatePrivateThread/createThread/sendMessage all exist and work.
- **Push notifications (FCM) for attendance/fees/grades/messages** _(flow: cross-cutting · feature-gap · effort L)_
  - Evidence: `no firebase_messaging dependency, no FCM token/onMessage wiring; research PowerSchool/ClassDojo CRITICAL`
  - Fix: Add firebase_messaging, register FCM tokens per user, handle foreground/background messages, and emit push on key events (new message, fee due, grade posted). Large follow-up — not first pass.
  - Impact: The app cannot push anything to a device; parents must remember to open it, killing the daily-use engagement loop every competitor relies on.
- **Automatic parent absence/tardy alert when a student is marked absent** _(flow: attendance · feature-gap · effort L)_
  - Evidence: `marking does not notify parents; research PowerSchool SafeArrival/ParentSquare/Skodefy CRITICAL`
  - Fix: On absent/tardy marks, trigger a server-side notification (edge function/RPC) sending push/SMS/email to linked parents. Depends on FCM (rank 39) and the corrected attendance write (rank 1). Large follow-up — not first pass.
  - Impact: The single most-valued safety feature is absent — a parent has no same-day way to learn their child is missing.

### 🟠 HIGH

- **Student self-view weekly attendance calendar is fully hardcoded** _(flow: attendance · bug · effort M)_
  - Evidence: `attendance_screen.dart:366-416 (statuses ['P','P','P','A','P','-'], today pinned to index 4), ignores real historyAsync above it`
  - Fix: Derive the weekly row from the real studentAttendanceProvider records for the current week, mapping each weekday to its actual status (em-dash for no-record/future days). Compute 'today' from DateTime.now().weekday, not a constant.
  - Impact: Students/parents see a fabricated week (e.g. a fake Thursday absence) presented as authoritative attendance — trust defect on a parent-facing surface.
- **Payment success does not invalidate invoice/summary providers — stale 'unpaid' state** _(flow: fees · bug · effort S)_
  - Evidence: `payment_checkout_screen.dart:36-39 (_SuccessScreen.onDone only resets+pops)`
  - Fix: Hoist invalidation into _PaymentCheckoutScreenState (which has ref) and in onDone call ref.invalidate on invoiceByIdProvider(widget.invoiceId), paginatedInvoicesProvider, studentFeeSummaryProvider, paymentsProvider, transactionsProvider.
  - Impact: Even once a real payment records, the parent returns to a Fees screen still showing the old pending amount and 'Pay Now', because providers are cached. Feedback lie.
- **Checkout charges full totalAmount instead of outstanding pendingAmount; no partial payments** _(flow: fees · bug · effort M)_
  - Evidence: `payment_checkout_screen.dart:93-101,201,229 (uses invoice.totalAmount); invoices_tab.dart:119 shows pendingAmount; research fedena/teachmint/classe365 partial payments`
  - Fix: Use invoice.pendingAmount (total - discount - paid) for both the displayed amount and the amount passed to pay()/recordPayment. Add an optional editable amount field with validation 0 < amount <= pendingAmount for partial/installment payments.
  - Impact: A partially-paid invoice would over-charge the parent (full original total), and families who cannot pay a full term at once are blocked.
- **Currency hardcoded to USD '$' at checkout/history but ₹ everywhere else** _(flow: fees · bug · effort M)_
  - Evidence: `payment_checkout_screen.dart:126,201,406; payment_history_screen.dart:159; pay() default 'USD' payment_gateway_provider.dart:167; ₹ used in fees_screen.dart:461, invoices_tab.dart:119`
  - Fix: Add one currency-format helper sourced from the tenant/gateway currency_code (the payment_gateways row already carries currency_code). Replace every hardcoded NumberFormat.currency(symbol:'\$') and the 'USD' default with the tenant currency.
  - Impact: Parent sees ₹ on the invoice then a $ amount at checkout — trust/correctness defect on a money screen for an INR deployment.
- **Chat list always shows blank previews and zero unread badges** _(flow: messaging · bug · effort M)_
  - Evidence: `message_repository.dart:53-74 (_threadFromRow never sets lastMessage/unreadCount); dead UI branches messages_screen.dart:311-317,476-515; research WhatsApp/Remind unread badges HIGH`
  - Fix: In getThreads fetch the latest message per thread (embedded ordered+limited messages relation or a threads_with_last_message view/RPC) and compute unreadCount from last_message_at vs the participant's last_read_at; set both in _threadFromRow in one query (no N+1). The bold-row/badge UI already exists and will light up.
  - Impact: Users cannot tell which chats are unread or what was last said — the triage signal of any inbox is missing.
- **Add skeleton/shimmer loaders to replace bare full-screen spinners** _(flow: cross-cutting · ux-norman · effort M)_
  - Evidence: `student_dashboard_screen.dart:40,266-269,483; research NN/g Skeleton Screens 101 (HIGH), 208 Center(CircularProgressIndicator) instances, no shimmer lib in pubspec`
  - Fix: Add one shared shimmer/skeleton placeholder widget mirroring each card shape (pulse-card, timeline row, list row) and use it in loading: branches instead of CircularProgressIndicator across the dashboards and attendance/fees/messaging lists. Apply NN/g timing: no loader under ~1s, skeleton for full-page, spinner only for a single module.
  - Impact: Dashboards/lists jump and reflow when data arrives and read as 'broken' during 2-10s loads; perceived performance suffers on the highest-visibility surfaces.
- **No pre-save confirmation when overwriting existing attendance** _(flow: attendance · known-gap · effort S)_
  - Evidence: `mark_attendance_screen.dart:320-382 (overwrites immediately when priorPayload != null; only post-hoc 6s UndoBanner)`
  - Fix: Before markBulkAttendance when priorPayload is non-empty, show an AlertDialog ('Attendance for this date already exists — overwrite N records?') with Cancel/Overwrite. Keep the UndoBanner as a secondary net.
  - Impact: A class re-marked from a stale screen can wipe a colleague's correct marks; if the teacher navigates away or misses the snackbar the overwrite stands.
- **Notifications tab is a permanent empty placeholder despite a real notifications module** _(flow: messaging · feature-gap · effort M)_
  - Evidence: `messages_screen.dart:420-440 (_NotificationsTab hardcoded 'No notifications yet'); real module at lib/features/notifications (unreadCountProvider, notification_center_screen)`
  - Fix: Wire _NotificationsTab to the existing notifications list provider in lib/features/notifications — render items with read/unread state and markAsRead on tap — or remove the tab to avoid a dead, misleading destination.
  - Impact: The tab perpetually lies that there are no notifications while a working notifications module exists elsewhere.
- **Teacher & parent dashboards show hardcoded grading/topics and a fully fake 'action required' ledger** _(flow: dashboards · feature-gap · effort M)_
  - Evidence: `teacher_dashboard_screen.dart:455,551 ('32/40 graded', index-derived topics); parent_dashboard_screen.dart:390-483 (static '$450 due', 'unread note'); teacherClassSummaryProvider/parentChildOverviewProvider dead`
  - Fix: Replace the '32/40 graded' literal with a real submissions-graded count and bind per-slot topic to lesson_plans/topic_coverage (or remove the topic line). Back _NeedsAttentionLedger with real outstanding-invoices + unread-threads providers (parentChildOverviewProvider.outstandingAmount), with loading/empty/error and an 'All caught up' empty state.
  - Impact: Every teacher sees identical fake grading counts and meaningless chapter numbers; every parent sees the same invented $450 due and fake note — these are the primary CTAs.
- **Student dashboard error state leaks raw exception and offers no retry** _(flow: dashboards · bug · effort S)_
  - Evidence: `student_dashboard_screen.dart:41 (Center(Text('Error loading dashboard: $err')))`
  - Fix: Replace with a friendly error card (use WarmCopy.loadFailed like the teacher/parent screens) plus a 'Retry' button calling ref.invalidate(currentStudentProvider). Never interpolate $err into user-facing text.
  - Impact: A transient profile-load failure dumps a raw Postgrest string with no recovery path; pull-to-refresh is undiscoverable from the bare-text state.
- **Signup screen is unreachable dead code — no route, no link, blocked by router for guests** _(flow: auth · feature-gap · effort M)_
  - Evidence: `signup_screen.dart:15-19; app_router.dart:676-680,701,716-718 (only public route is /login)`
  - Fix: Decide product intent. If self-signup is supported: add AppRoutes.signup, register a GoRoute, include /signup in isPublicRoute, and add a 'Create Account' TextButton on login. If admin-only: delete signup_screen.dart and the AuthNotifier.signUp/createUserWithRole paths. Pair with a self-service invite/link-code onboarding that auto-associates children (research Edsby/PowerSchool HIGH) if signup is kept.
  - Impact: A complete signup screen cannot be reached even by typing /signup; new users have no self-service entry point, and the dead path is confusing to maintain.
- **Demo email list + universal password hardcoded as a const, ships in production binary** _(flow: auth · known-gap · effort M)_
  - Evidence: `demo_accounts_panel.dart:32-81,138 (kDemoAccounts const + plaintext 'Universal password: Demo@2026')`
  - Fix: Build kDemoAccounts from AppEnvironment/.env values (empty in production) or strip the panel from release builds via a compile-time flag. Ensure demo tenant credentials are rotated/disabled in any production deployment.
  - Impact: Six working demo emails and a shared password are compiled into every build and trivially extractable from a release APK/web bundle; only the rendering is env-gated.
- **Admin 'Record Payment' reuses the parent gateway checkout instead of a cash/cheque entry form** _(flow: fees · feature-gap · effort M)_
  - Evidence: `invoice_card.dart:120-137,217-235 (routes to same /fees/pay/:invoiceId); recordPayment(paymentMethod,...) unreachable fee_repository.dart:388`
  - Fix: Branch on isAdmin: route 'Record Payment' to a dedicated manual-payment form (method dropdown cash/cheque/bank/online, amount defaulting to pendingAmount, reference, date, remarks) calling feesNotifierProvider.recordPayment and invalidating invoice providers. Keep gateway checkout only for the parent Pay Now path.
  - Impact: An accountant recording a front-desk cash/cheque payment is forced through a fake online-gateway flow with no field for method/amount/reference/date.
- **Gateway secret/webhook keys stored and read back in plaintext from the client** _(flow: fees · bug · effort M)_
  - Evidence: `payment_gateway_screen.dart:315-368; payment_gateway_repository.dart:34-56 (writes config), getGateways select('*') lines 7-17`
  - Fix: Stop returning secret_key/webhook_secret to the client: store them server-side (Supabase Vault/edge function env), have getGateways select only non-secret fields, and move config writes behind an RPC/edge function the client cannot read back. Never select('*') secrets to the device.
  - Impact: Secret keys live in a row the multi-tenant client selects with select('*'), exposing credentials to every admin device.
- **Add biometric unlock + persistent 'keep me signed in' session** _(flow: auth · feature-gap · effort L)_
  - Evidence: `no local_auth in pubspec, no biometric refs in lib/features/auth; no 'remember me'; research NN/g + ClassDojo/Google Classroom HIGH`
  - Fix: Add local_auth, persist the session, and add a biometric-gated quick re-login plus a 'Keep me signed in' toggle on the login screen. Larger follow-up — not first pass.
  - Impact: A 12-role daily-use audience re-types email+password every cold start; friction measurably reduces engagement.
- **Message attachments (photo/file) blocked by 'coming soon'** _(flow: messaging · feature-gap · effort M)_
  - Evidence: `messages_screen.dart:188,764 ('File attachment coming soon'); provider supports attachments; research ClassDojo/Brightwheel HIGH`
  - Fix: Wire the attachment button to an image/file picker, upload to Supabase storage, and pass the attachment ref through the existing sendMessage attachment support. Follow-up after the core send path is wired (rank 4).
  - Impact: Photo/file sharing is the center of parent-teacher communication in competitors; text-only is below baseline.

### 🟡 MEDIUM

- **Reports tab Period/Class filters are dead controls (empty onChanged)** _(flow: attendance · feature-gap · effort M)_
  - Evidence: `attendance_screen.dart:443-477 (both onChanged: (value){}); report always uses _selectedDate`
  - Fix: Wire the dropdowns to state — a period StateProvider that adjusts the date range passed to providers, and a class filter that scopes the section list — or remove the controls until implemented.
  - Impact: False affordance: visible dropdowns promise filtering they cannot deliver; report never changes.
- **Class-wise report error/empty/loading states are indistinguishable from real zero data** _(flow: attendance · ux-norman · effort M)_
  - Evidence: `attendance_screen.dart:582-617 (renders 0/0/0% in loading, error, and null branches); Mark tab collapses error to 'Pending' at 183-186`
  - Fix: Render distinct states: skeleton row on loading, inline error chip with retry on error, explicit 'Not marked' (not 0%) when data is null. Don't collapse errors into a plausible zero.
  - Impact: A teacher cannot tell whether a class had zero attendance, the query failed, or it is still loading — silent failure.
- **No unsaved-changes guard when leaving the mark-attendance screen** _(flow: attendance · ux-norman · effort S)_
  - Evidence: `mark_attendance_screen.dart:109-300 (_hasChanges tracked but no PopScope)`
  - Fix: Wrap the Scaffold in PopScope(canPop: !_hasChanges) and on attempted pop with unsaved changes show a 'Discard unsaved attendance?' confirmation dialog.
  - Impact: A teacher who marks 30 students then taps back loses all changes with no prompt — the most effort-intensive action in the flow.
- **Search field in messaging is a no-op** _(flow: messaging · feature-gap · effort M)_
  - Evidence: `messages_screen.dart:61-80 (onChanged only '// Search functionality coming soon')`
  - Fix: Debounce onChanged into a search-query StateProvider that client-side filters the loaded threads by displayTitle/lastMessage; or remove the search affordance until a server-side message search is backed.
  - Impact: Autofocused 'Search messages...' field filters nothing — false affordance.
- **Add a user-cancelled and pending/SCA payment state with graceful return** _(flow: fees · ux-norman · effort M)_
  - Evidence: `payment_gateway_provider.dart enum PaymentFlowState{idle,processing,success,failure}; _ErrorBanner hardcodes message payment_checkout_screen.dart:364-396; research Stripe/Razorpay HIGH`
  - Fix: Add 'cancelled' and 'pending' to PaymentFlowState. On cancel return to the invoice with a calm 'Payment cancelled — invoice unchanged' message; on pending show 'Awaiting bank confirmation'. Render the real errorMessage in _ErrorBanner (the message prop is currently dead) with a 'Try again' action.
  - Impact: Backing out of a gateway redirect is indistinguishable from failure; async/3DS settlement is shown as a false failure, risking panicked double-payment.
- **Forgot-password and splash call setState/context.go after await with no mounted guard** _(flow: auth · bug · effort S)_
  - Evidence: `login_screen.dart:532-559 (_handleResetPassword); splash_screen.dart:96,114 (unguarded context.go; line 106 is guarded)`
  - Fix: Add 'if (!mounted) return;' before setState in the success/catch/finally branches of _handleResetPassword, and wrap splash lines 96 and 114 context.go calls in 'if (mounted)' to match the guarded branch at 106.
  - Impact: Dismissing the dialog or disposing splash mid-request throws 'setState() after dispose()' / 'deactivated widget ancestor'.
- **Undo unavailable if prior-state read fails; offline undo races a second enqueue** _(flow: attendance · bug · effort M)_
  - Evidence: `mark_attendance_screen.dart:330-346,364-380 (second capped read decides undo; offline _restoreAttendance enqueues a racing write)`
  - Fix: Use the existingByStudentId snapshot already loaded at _loadStudents time as the undo baseline (no second network read), so undo is always available. For offline, have _restoreAttendance cancel/dequeue the pending overwrite rather than racing a second enqueue.
  - Impact: If the prior-state read throws, data is clobbered with no undo offered; offline, both writes land in the queue and ordering decides the winner.
- **Real money/primary-action tap targets below 48dp across flows** _(flow: cross-cutting · accessibility · effort M)_
  - Evidence: `mark_attendance_screen.dart:636-672 (status buttons ~38dp, bare GestureDetector, no semantics); fees_screen.dart:813-852 (_QuickAction); dashboard dense ListTiles parent_dashboard_screen.dart:427-475; login_screen.dart:332-339`
  - Fix: Enforce ConstrainedBox(minHeight:48)/BoxConstraints(minWidth:48,minHeight:48), replace bare GestureDetector with InkWell for ripple, wrap in Semantics(button:true, selected:isSelected, label:...), and remove dense:true on primary-action dashboard rows. Strengthen non-color cues for selected state.
  - Impact: The most-tapped controls (attendance status, fee quick-actions, dashboard action rows) are hard to hit and unannounced to screen readers.
- **Email validation regex rejects valid TLDs longer than 4 chars on signup + forgot-password** _(flow: auth · bug · effort S)_
  - Evidence: `signup_screen.dart:390 and login_screen.dart:535 use {2,4}; login_screen.dart:422 correctly uses {2,}`
  - Fix: Extract a single shared isValidEmail() helper using {2,} and use it at all three call sites so validation stays consistent.
  - Impact: Users with .education/.museum/.online/.school emails cannot sign up or reset their password.
- **QuickMark 'Undo' only re-opens the sheet — it does not revert the saved write** _(flow: attendance · ux-norman · effort M)_
  - Evidence: `quick_mark_sheet.dart:88-98 (onUndo calls showQuickMarkSheet again)`
  - Fix: Either rename the action to 'Edit', or capture prior server state before persistQuickMark and have onUndo re-write that prior payload (matching mark_attendance_screen._restoreAttendance).
  - Impact: Attendance is already written; 'Undo' reverts nothing — breaks the user's mental model and is inconsistent with the mark screen's real restore.
- **Section daily-attendance providers fan out one query per section (N+1)** _(flow: attendance · perf · effort M)_
  - Evidence: `attendance_screen.dart:159-200,568-617 (ref.watch(sectionDailyAttendanceProvider) inside .map over sections)`
  - Fix: Add a repo method fetching v_section_daily_attendance for ALL sections on a date in one query and expose a single date-keyed FutureProvider; index per-card lookups into that map.
  - Impact: A 30+ section school issues 30+ parallel maybeSingle queries on every date change against v_section_daily_attendance.
- **Mark screen never shows which date/section is being edited** _(flow: attendance · ux-norman · effort S)_
  - Evidence: `mark_attendance_screen.dart:122-124 (AppBar title just 'Mark Attendance')`
  - Fix: Show section name + formatted date in the AppBar title/subtitle and flag when selected date != today with an amber 'Editing 12 May 2026' banner.
  - Impact: A teacher editing a past date gets no on-screen reminder, raising risk of overwriting the wrong day.
- **No success feedback / no optimistic UI on message send** _(flow: messaging · ux-norman · effort M)_
  - Evidence: `messages_provider.dart:187-203 (sendMessage then loadMessages sets AsyncValue.loading())`
  - Fix: Make sendMessage optimistic: append the new Message to the current list immediately, reconcile with the server result, and on failure mark the bubble failed with tap-to-retry instead of a full-screen loading reset.
  - Impact: The whole message list flashes a spinner on every send instead of optimistically appending the bubble — reads as janky once the chat detail is wired.
- **Chat detail overflow actions (Mute/Block/Delete/Call) are all 'coming soon'; Delete is unguarded** _(flow: messaging · feature-gap · effort M)_
  - Evidence: `messages_screen.dart:642-704 (all SnackBars); muteThread/deleteMessage exist in repo`
  - Fix: Wire Mute to threadsNotifier.muteThread; guard Delete behind an AlertDialog confirmation if implemented; drop Block/Call/View Profile (or implement) rather than shipping dead destructive options.
  - Impact: Mute is implementable today; 'Delete Chat' is shown as a red destructive action with no confirmation and no effect.
- **Successful signup for a normal user dead-ends with a snackbar and bounce to login** _(flow: auth · ux-norman · effort M)_
  - Evidence: `signup_screen.dart:166-183; createUserWithRole creates role-less account auth_provider.dart:160-176`
  - Fix: Replace the snackbar+bounce with a dedicated 'Account pending approval' confirmation screen explaining next steps with a 'Back to sign in' action. Tie to the signup-intent decision (rank 17).
  - Impact: User's mental model ('I signed up, now I'm in') is violated by a fleeting 5s snackbar then a login screen they cannot yet use.
- **No receipt save/share/download on payment success or in history** _(flow: fees · feature-gap · effort M)_
  - Evidence: `payment_checkout_screen.dart:398-497 (_SuccessScreen only has 'Done'); FeesPdfBuilder exists; research Stripe/Razorpay MEDIUM`
  - Fix: Add 'Download receipt'/'Share' on _SuccessScreen and a receipt view on each Payment History tile and paid invoice, generating a per-payment PDF (reuse/extend FeesPdfBuilder); persist enough on the transaction to regenerate later.
  - Impact: Parents have no retrievable artifact for a financial transaction at the moment they want it.
- **Two overlapping unlinked communication surfaces confuse the mental model** _(flow: messaging · ux-norman · effort M)_
  - Evidence: `messages_screen.dart:39-48 (/messages tabs) vs Communication Hub app_router.dart:591-601,2057-2098`
  - Fix: Decide ownership: keep /messages for 1:1+class chats, move Announcements into the Communication Hub (or vice versa), add cross-links, and document the boundary in CLAUDE.md.
  - Impact: Announcements/notifications live in both /messages and /communication with no cross-navigation; users can't tell where to send a class announcement vs a 1:1 chat vs a bulk campaign.

### ⚪ LOW

- **School-wide 'Average Attendance' uses an unweighted mean of section percentages** _(flow: attendance · bug · effort S)_
  - Evidence: `attendance_repository.dart:280-297 (mean of section %s, not student-weighted)`
  - Fix: Compute sum(present_count)/sum(total_students) across sections, reusing getTodayStudentCounts (attendance_repository.dart:300-317).
  - Impact: A 3-student section drags the headline as hard as a 40-student section — statistically wrong figure.
- **Student avatar initial throws RangeError on empty names** _(flow: attendance · bug · effort S)_
  - Evidence: `mark_attendance_screen.dart:490-491 (studentName.substring(0,1) unguarded)`
  - Fix: Guard with studentName.isNotEmpty ? studentName[0] : '?' (or characters.firstOrNull) wherever an initial is derived.
  - Impact: A student with an empty fullName crashes the whole roster render.
- **Login post-success cannot distinguish profile load-error from missing profile** _(flow: auth · bug · effort S)_
  - Evidence: `login_screen.dart:72-86 (reads currentUserProvider synchronously; valueOrNull null on error)`
  - Fix: Inspect ref.read(authNotifierProvider) and branch on hasError vs data==null: show a retryable 'Could not load your profile' for errors vs 'No profile found' for a genuine null.
  - Impact: A transient profile-load failure is misattributed as 'profile not found, contact support' with no retry.
- **No localization wiring and time-insensitive greeting on dashboards** _(flow: dashboards · known-gap · effort L)_
  - Evidence: `student_dashboard_screen.dart:184,213 ('Good morning' always, hardcoded English); en/ar/fr/hi ARB files exist for shell`
  - Fix: Route dashboard strings through the existing intl/ARB layer; at minimum make the greeting time-aware (morning/afternoon/evening). Larger follow-up.
  - Impact: Highest-visibility surface is hardcoded English; greeting shows 'Good morning' at all hours.

## Recommended first pass

1. Forgot-password and splash call setState/context.go after await with no mounted guard
2. Student dashboard error state leaks raw exception and offers no retry
3. No pre-save confirmation when overwriting existing attendance
4. No unsaved-changes guard when leaving the mark-attendance screen
5. Payment success does not invalidate invoice/summary providers — stale 'unpaid' state
6. Email validation regex rejects valid TLDs longer than 4 chars on signup + forgot-password
7. Real money/primary-action tap targets below 48dp across flows
8. Student avatar initial throws RangeError on empty names
9. Admin dashboard shows fabricated metrics + fake approval queue; real KPI layer is unwired dead code
10. Class-wise report error/empty/loading states are indistinguishable from real zero data

## Quick wins

- Add 'if (!mounted) return;' guards in forgot-password and splash after await (login_screen.dart:532-559, splash_screen.dart:96,114)
- Replace student dashboard raw-exception error with a WarmCopy.loadFailed card + Retry (student_dashboard_screen.dart:41)
- Add an overwrite-confirmation AlertDialog before re-marking existing attendance (mark_attendance_screen.dart:320-382)
- Add PopScope unsaved-changes guard to the mark-attendance screen (mark_attendance_screen.dart:109-300)
- Invalidate invoice/summary providers in payment success onDone (payment_checkout_screen.dart:36-39)
- Extract a shared isValidEmail() {2,} helper for signup + forgot-password (signup_screen.dart:390, login_screen.dart:535)
- Enforce 48dp + InkWell + Semantics on attendance status buttons (mark_attendance_screen.dart:636-672)
- Guard the avatar-initial substring against empty names (mark_attendance_screen.dart:490-491)

## Appendix — competitor & UX research gaps


### Table-stakes feature-gap audit of the Flutter school app, benchmarked against leading K-12 SaaS (PowerSchool, Edsby, Gradelink, ClassDojo, Brightwheel, Teachmint, Fedena, Classe365). I verified the codebase first to avoid flagging features that already exist: the app already HAS a parent multi-child ChildSwitcher (lib/features/parent/presentation/widgets/child_switcher.dart), forgot/reset password (login_screen.dart:506), bulk "All Present/All Absent" attendance with present/absent/late statuses (mark_attendance_screen.dart:127,302), PDF receipt builders, and en/ar/fr/hi localization ARB files. So those are NOT gaps. The gaps below are capabilities that competitors treat as baseline for daily parent/teacher use but the app either stubs out, simulates, or omits entirely. The single highest-impact finding: online fee payment is a SIMULATION — payment_gateway_provider.dart:181 literally says "Simulate gateway call — in production this would launch a gateway SDK" — even though razorpay_flutter is in pubspec, no SDK is invoked and no real charge occurs. Combined with absent push notifications (no firebase_messaging dependency) and absent attendance-absence alerts, the two daily-use loops that make these products sticky for parents (pay fees, get notified my kid is absent) are non-functional.

- **Real online payment gateway execution (Razorpay/Stripe SDK launch + verification)** _(flow: fees · CRITICAL)_ — Online fee payment is the #1 reason parents open these apps daily. The app's checkout is a stub: payment_gateway_provider.dart:181 says 'Simulate gateway call — in production this would launch a gateway SDK', so it fakes success without charging. razorpay_flutter is in pubspec but never invoked, and there is no server-side signature/webhook verification. Teachmint (Teachpay), Fedena, Classe365 and Brightwheel all execute real ACH/card/UPI charges with instant confirmation. Without this, the core fees loop does not actually move money.
- **Push notifications (FCM) for grades, attendance, fees, and messages** _(flow: cross-cutting · CRITICAL)_ — No firebase_messaging dependency exists and no FCM token/onMessage wiring is present, so the app cannot push anything to a device. PowerSchool Mobile pushes real-time alerts for grade changes, attendance codes, assignments, teacher comments, bulletins and fee transactions. Push is the engagement backbone of every competitor; without it parents must remember to open the app, which kills daily use.
- **Automatic parent absence/tardy alert when a teacher marks a student absent** _(flow: attendance · CRITICAL)_ — Attendance marking exists (bulk All Present/All Absent, present/absent/late) but marking does not notify the parent. Skodefy, ParentSquare, Pikmykid and PowerSchool SchoolMessenger SafeArrival all auto-send SMS/email/push the moment a child is marked absent or tardy — this is the single most-valued safety feature for parents. Today a parent has no way to learn same-day that their child is missing.
- **Message attachments (photos/files) in school-parent chat** _(flow: messaging · HIGH)_ — The messaging provider already supports attachments, but the UI hard-codes a 'File attachment coming soon' SnackBar (messages_screen.dart:188,764), so parents/teachers cannot actually send a photo or document. ClassDojo and Brightwheel center their parent-teacher experience on sharing photos and files of the child's day; text-only chat is below baseline for daily K-12 communication.
- **Read receipts / delivery & message status** _(flow: messaging · MEDIUM)_ — No read_receipt/seen_at/delivered fields or UI exist in messaging. ClassDojo Plus gives teachers read receipts so they know a parent saw an urgent message; this is expected for time-sensitive school communication (e.g., early dismissal). Without it senders cannot tell whether critical messages landed.
- **In-message translation for multilingual families** _(flow: messaging · MEDIUM)_ — Localization ARB files (en/ar/fr/hi) exist for the app shell, but free-text chat messages are not translated. ClassDojo auto-translates messages and posts across 35+ languages so a teacher and a parent who speak different languages can still communicate. For diverse districts this is the difference between usable and unusable parent communication.
- **Partial payments and installment plans at checkout** _(flow: fees · HIGH)_ — The checkout pays the full invoice.totalAmount with no field for a partial amount or installment schedule. Fedena, Teachmint, iSchoolCloud and Classe365 all let parents pay partially or on an installment plan and track the remaining balance. Many families cannot pay a full term fee at once, so full-amount-only checkout blocks real collection.
- **Biometric / quick re-login (fingerprint / Face ID)** _(flow: auth · MEDIUM)_ — No local_auth dependency or biometric code exists; parents must type email+password every session. Access My School Portal and other parent apps offer biometric login as standard because parents open the app frequently for short check-ins. Friction at login measurably reduces daily-use engagement.
- **Self-service parent onboarding via invite/link code** _(flow: auth · HIGH)_ — There is a signup screen but no invite-code/link flow that ties a self-registering parent to the correct student(s). Edsby, Mobile Guardian, LiveSchool and ScholarPack onboard parents with a school-issued, time-limited link/access code that auto-associates children — avoiding manual admin linking and mis-linked records. Without it, parent account creation is either insecure or requires heavy admin effort.
- **Configurable parent dashboard with at-a-glance widgets (GPA, attendance %, fee due, assignments due, meal balance)** _(flow: dashboards · MEDIUM)_ — Parent screens are separate detail pages (child_progress, child_results, fee_payment, homework_tracker) rather than one consolidated, reorderable home. PowerSchool Mobile gives a customizable dashboard of widgets (GPA, attendance, assignments due/graded, fees, meal balance, bulletins). A single glanceable summary per child is what drives the daily 30-second check-in that makes these apps sticky.

### Grounded gap analysis for the Campusly school-management Flutter app, mapping each of the five flows to authoritative mobile-UX guidance (Nielsen Norman Group articles + Don Norman's six interaction principles). I inspected the actual code rather than reasoning abstractly, so recommendations are calibrated to what the app already has versus what it provably misses. Net picture: attendance is already mature (default-present, undo banner, offline sync), so its gaps are incremental; the biggest, most defensible gaps are in (1) login (no biometric/SSO/passwordless/persistent-session despite a 12-role daily-use audience), (2) loading UX (208 full-screen CircularProgressIndicator spinners and zero skeleton screens, directly contradicting NN/g perceived-performance guidance), (3) messaging (Send button pops without sending, search is a 'coming soon' stub, no read/delivery/typing/unread indicators — a near-empty shell), and (4) payment (no user-cancelled state in the PaymentFlowState enum, no save/share receipt action on the success screen, no pending/SCA-authentication state, currency hardcoded to '$'). Each gap below cites the heuristic/principle it satisfies and names competitors that ship it. Severity reflects both UX impact and how broken the current state is (e.g. messaging Send is functionally non-working = CRITICAL, not cosmetic).

- **Biometric unlock (Face ID / fingerprint) for returning users via local_auth** _(flow: auth · HIGH)_ — This is a daily-use app for teachers, parents and students across 12 roles, yet login is email+password only (no local_auth package in pubspec, no biometric refs in lib/features/auth). NN/g notes biometrics let users skip recall and entry of a password entirely, saving considerable time and effort. Norman's principle of reducing the gulf of execution: tapping a fingerprint is a fraction of the cognitive and motor cost of recalling and typing a password every session. Without it, every open of the app re-imposes full login friction.
- **Persistent session / 'Keep me signed in' so returning users are not forced to re-authenticate every launch** _(flow: auth · HIGH)_ — The login screen has no 'remember me' control and there is no onboarding/walkthrough at all (find found NO onboarding screens). Nielsen Heuristic 6 (recognition over recall) and 7 (flexibility/efficiency for frequent users): forcing a full credential entry on every cold start punishes the frequent users who make up almost the entire audience of a school app. A persistent, biometric-gated session is the expected default.
- **SMS/email OTP one-time-code autofill and a passwordless fallback path** _(flow: auth · MEDIUM)_ — Login only supports a password (AutofillHints.email + AutofillHints.password are wired, but there is no AutofillHints.oneTimeCode and no OTP/magic-link path). NN/g's passwordless guidance and 2025 login UX guides recommend OTP with OS-level one-tap SMS autofill plus a clear alternative method to avoid dead ends (Nielsen Heuristic 9, help users recover from errors). Parents in particular often cannot recall a password they set once; an OTP fallback removes that dead end. The current 'Forgot Password' dialog is the only recovery route.
- **Skeleton screens for dashboard and list loads instead of centered spinners** _(flow: dashboards · HIGH)_ — The codebase has 208 'Center(child: CircularProgressIndicator)' full-screen spinners and no skeleton/shimmer library in pubspec. NN/g (Skeleton Screens 101) explicitly recommends skeleton screens over spinners for full-page loads of 2-10s because the wireframe gives users a mental model of the page structure and reduces perceived wait and cognitive load; a blank/spinner screen reads as 'broken'. Norman's principle of providing a conceptual model and feedback: a skeleton signals 'content of this shape is arriving here'. Dashboards, which rely on predictable element placement, are the textbook case for skeletons.
- **Spinner-vs-skeleton timing discipline (no loader under ~1s; skeleton for full screen; spinner only for single modules; progress bar over 10s)** _(flow: dashboards · MEDIUM)_ — The app uses one indicator type (centered spinner) indiscriminately. NN/g gives concrete thresholds: under 1s show nothing (a flashing spinner is annoying and feels slower), 2-10s use a skeleton for full-page or a spinner for a single module, and over 10s use a determinate progress bar so users sense remaining time. Applying the wrong indicator (e.g. a brief spinner flash) actively degrades perceived performance — Nielsen Heuristic 1, visibility of system status, done badly.
- **Explicit visual information hierarchy on dashboards (primary KPI emphasis, F/Z-pattern layout, grouped scannable zones)** _(flow: dashboards · MEDIUM)_ — Dashboard best-practice guidance (NN/g-aligned) says users should not hunt for important information; visual weight via size/color/grouping and F- or Z-pattern placement should make the most important metric emerge first. On mobile, limited space makes this clarity essential. Combined with the known issue that the weekly attendance calendar renders hardcoded (not live) status data, dashboards risk both poor hierarchy and misleading content. Norman's mapping principle: the most consequential number should occupy the most prominent position.
- **Roster search / filter / jump-to-letter on the attendance marking screen** _(flow: attendance · MEDIUM)_ — MarkAttendanceScreen renders a plain ListView.builder of all students with no search or filter. The project's own known-issues list flags 'no pagination on most list screens — will crash with large datasets'. For a class of 40-60+ students a teacher cannot quickly locate one pupil. Nielsen Heuristic 7 (flexibility and efficiency of use) and Heuristic 6 (recognition not recall): a filter or sticky alpha-index lets the teacher jump straight to the student rather than scrolling and scanning. Attendance is otherwise strong (All Present default, undo banner, offline) so this is the main remaining gap.
- **Haptic + visual micro-feedback on each attendance status tap and on bulk actions** _(flow: attendance · LOW)_ — HapticFeedback is only used on two ID-card screens, never in attendance. NN/g and Norman both stress immediate feedback so the user is never left guessing whether an action registered (Norman's feedback principle; Nielsen Heuristic 1). When tapping through dozens of students quickly, a light haptic tick plus an instant color change confirms each mark landed and prevents double-tapping or skipped students — the difference between confident fast roll-call and error-prone tapping.
- **A distinct user-cancelled payment state (PaymentFlowState currently has no 'cancelled') with a graceful return path** _(flow: fees · HIGH)_ — payment_gateway_provider.dart defines enum PaymentFlowState { idle, processing, success, failure } — there is no 'cancelled'. When a user backs out of a gateway redirect/webview, the app cannot distinguish 'you cancelled' from 'it failed', so it either hangs in processing or shows a scary error. Nielsen Heuristic 9 (help users recover) and Heuristic 5 (error prevention): a cancel must return the user to the invoice with a calm 'Payment cancelled — your invoice is unchanged, try again when ready' message, not an error banner. Norman: the system model must match what actually happened.
- **Save / share / download-PDF receipt action on the payment success screen** _(flow: fees · MEDIUM)_ — The success screen shows on-screen receipt rows (Transaction ID, Gateway, Date) but exposes no save/share/download action there, even though the app has a payment_receipt_pdf_builder util. NN/g payment guidance and Stripe/GoCardless best-practice both call for post-transaction options to save the receipt or contact support. Parents need a receipt for their records; making them hunt for it later in payment history (when the success screen is the moment they want it) violates Heuristic 7 (efficiency) and Norman's principle of putting the affordance where the action is needed.
- **A 'pending / authentication-required' payment state for async settlement and bank SCA challenges** _(flow: fees · MEDIUM)_ — The flow models only instant success or failure. Real gateways return 'pending' (hold not yet settled) and SCA/3DS 'authentication required' outcomes; conflating these with failure is, per failed-payment-recovery guidance, 'actively confusing' (telling a user to fix a card that is fine). Nielsen Heuristic 1 (visibility of system status): the user should see 'Awaiting bank confirmation' rather than a false failure, with no double-charge from a panicked retry (Heuristic 5, error prevention).
- **Locale-aware currency formatting instead of hardcoded '$'** _(flow: fees · MEDIUM)_ — payment_checkout_screen.dart uses NumberFormat.currency(symbol: '\$') hardcoded. For a multi-tenant SaaS that will run in non-USD regions (the project notes no localization setup), showing the wrong currency symbol on a real money screen is a trust-breaking match-to-real-world failure (Nielsen Heuristic 2, match between system and the real world). Currency must come from tenant settings.
- **A working Send action in the message composer (currently the Send button only pops the sheet without sending)** _(flow: messaging · CRITICAL)_ — In messages_screen.dart the composer's Send button calls Navigator.pop(context) with no send call, and onChanged in search is a 'coming soon' stub (memory obs 8221 confirms the chat detail screen is stubbed with hardcoded messages and a 'Coming Soon' send). This is the most severe possible violation of Nielsen Heuristic 1 (visibility of system status): the user believes they sent a message and nothing was sent. It is a functional break, not a polish item.
- **Delivery and read-status indicators on sent messages (sent / delivered / read ticks)** _(flow: messaging · HIGH)_ — message_repository.dart has realtime/channel references but there is no delivery or read-receipt UI. WhatsApp's grey-tick / double-grey / blue-tick convention is the de facto user expectation, and NN/g classifies these as contextual indicators shown in close proximity to the message. For school-parent communication, a parent and teacher both need to know whether an urgent message was actually seen (Nielsen Heuristic 1; Norman's feedback principle).
- **Per-conversation unread badges with bold-row treatment, and accurate app-icon unread count** _(flow: messaging · HIGH)_ — There are unread/badge references in the messaging provider/screen but no visible per-thread unread indicator pattern. NN/g (Indicators vs Notifications) prescribes numeric badges and typographic emphasis (bold unread rows) shown next to the relevant element, and cautions to only badge when items can be marked read and arrive relatively infrequently. Without this, users cannot triage which conversations need attention — a direct hit to Heuristic 1 and recognition-not-recall (Heuristic 6).
- **Typing indicator and optimistic real-time message rendering** _(flow: messaging · MEDIUM)_ — No typing indicator exists and messages are not rendered optimistically/in real time (the detail screen is stubbed). NN/g notes typing indicators make a conversation feel natural, and real-time indicator systems measurably cut response times and missed communications. Optimistic send (show the bubble immediately, reconcile on server ack) plus a typing indicator close the feedback gap (Norman's feedback principle) and make the chat feel live rather than a form submission.
- **Optional, skippable, progressive onboarding for first-time users of complex role dashboards** _(flow: cross-cutting · LOW)_ — There are no onboarding/walkthrough screens at all. NN/g advises skipping onboarding when possible but using progressive, contextual guidance for genuinely complex flows; a 12-role education OS with dense dashboards is a reasonable case for a short, skippable, role-specific first-run tour or empty-state coaching. This supports Nielsen Heuristic 10 (help and documentation) without forcing a wall of tutorial screens — progressive disclosure (Norman) rather than upfront dump.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../data/models/communication.dart';
import '../../../data/repositories/communication_repository.dart';

// ============================================================
// Repository Provider
// ============================================================

final communicationRepositoryProvider =
    Provider<CommunicationRepository>((ref) {
  return CommunicationRepository(ref.watch(supabaseProvider));
});

// ============================================================
// Dashboard Stats
// ============================================================

final communicationDashboardStatsProvider =
    FutureProvider<CommunicationDashboardStats>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getDashboardStats();
});

// ============================================================
// Templates
// ============================================================

final templatesProvider =
    FutureProvider.family<List<CommunicationTemplate>, TemplateCategory?>(
  (ref, category) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getTemplates(category: category);
  },
);

final allTemplatesProvider =
    FutureProvider<List<CommunicationTemplate>>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getTemplates();
});

final activeTemplatesProvider =
    FutureProvider<List<CommunicationTemplate>>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getTemplates(activeOnly: true);
});

final templateByIdProvider =
    FutureProvider.family<CommunicationTemplate?, String>(
  (ref, id) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getTemplateById(id);
  },
);

// ============================================================
// Templates Notifier
// ============================================================

class TemplatesNotifier
    extends StateNotifier<AsyncValue<List<CommunicationTemplate>>> {
  final CommunicationRepository _repository;

  TemplatesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> load({TemplateCategory? category}) async {
    state = const AsyncValue.loading();
    try {
      final templates = await _repository.getTemplates(category: category);
      state = AsyncValue.data(templates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CommunicationTemplate> create(Map<String, dynamic> data) async {
    final template = await _repository.createTemplate(data);
    await load();
    return template;
  }

  Future<CommunicationTemplate> update(
      String id, Map<String, dynamic> data) async {
    final template = await _repository.updateTemplate(id, data);
    await load();
    return template;
  }

  Future<void> delete(String id) async {
    await _repository.deleteTemplate(id);
    await load();
  }

  Future<void> toggle(String id, bool active) async {
    await _repository.toggleTemplate(id, active);
    await load();
  }
}

final templatesNotifierProvider = StateNotifierProvider<TemplatesNotifier,
    AsyncValue<List<CommunicationTemplate>>>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return TemplatesNotifier(repo);
});

// ============================================================
// Campaigns
// ============================================================

final campaignsProvider =
    FutureProvider.family<List<CommunicationCampaign>, CampaignStatus?>(
  (ref, status) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getCampaigns(status: status);
  },
);

final allCampaignsProvider =
    FutureProvider<List<CommunicationCampaign>>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getCampaigns();
});

final campaignByIdProvider =
    FutureProvider.family<CommunicationCampaign?, String>(
  (ref, id) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getCampaignById(id);
  },
);

final campaignRecipientsProvider =
    FutureProvider.family<List<CampaignRecipient>, String>(
  (ref, campaignId) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getCampaignRecipients(campaignId);
  },
);

final campaignStatsProvider =
    FutureProvider.family<CampaignStats, String>(
  (ref, campaignId) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getCampaignStats(campaignId);
  },
);

// ============================================================
// Campaigns Notifier
// ============================================================

class CampaignsNotifier
    extends StateNotifier<AsyncValue<List<CommunicationCampaign>>> {
  final CommunicationRepository _repository;

  CampaignsNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> load({CampaignStatus? status}) async {
    state = const AsyncValue.loading();
    try {
      final campaigns = await _repository.getCampaigns(status: status);
      state = AsyncValue.data(campaigns);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<CommunicationCampaign> create(Map<String, dynamic> data) async {
    final campaign = await _repository.createCampaign(data);
    await load();
    return campaign;
  }

  Future<CommunicationCampaign> update(
      String id, Map<String, dynamic> data) async {
    final campaign = await _repository.updateCampaign(id, data);
    await load();
    return campaign;
  }

  Future<CommunicationCampaign> send(String id) async {
    final campaign = await _repository.sendCampaign(id);
    await load();
    return campaign;
  }

  Future<CommunicationCampaign> schedule(
      String id, DateTime scheduledAt) async {
    final campaign = await _repository.scheduleCampaign(id, scheduledAt);
    await load();
    return campaign;
  }

  Future<CommunicationCampaign> cancel(String id) async {
    final campaign = await _repository.cancelCampaign(id);
    await load();
    return campaign;
  }

  Future<void> delete(String id) async {
    await _repository.deleteCampaign(id);
    await load();
  }

  Future<void> retryFailed(String campaignId) async {
    await _repository.retryFailedRecipients(campaignId);
    await load();
  }
}

final campaignsNotifierProvider = StateNotifierProvider<CampaignsNotifier,
    AsyncValue<List<CommunicationCampaign>>>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return CampaignsNotifier(repo);
});

// ============================================================
// Communication Log
// ============================================================

final communicationLogProvider =
    FutureProvider.family<List<CommunicationLog>, CommunicationLogFilter>(
  (ref, filter) async {
    final repo = ref.watch(communicationRepositoryProvider);
    return repo.getCommunicationLog(filter);
  },
);

// ============================================================
// Auto Notification Rules
// ============================================================

final autoRulesProvider =
    FutureProvider<List<AutoNotificationRule>>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getAutoRules();
});

final activeAutoRulesProvider =
    FutureProvider<List<AutoNotificationRule>>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getAutoRules(activeOnly: true);
});

class AutoRulesNotifier
    extends StateNotifier<AsyncValue<List<AutoNotificationRule>>> {
  final CommunicationRepository _repository;

  AutoRulesNotifier(this._repository) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final rules = await _repository.getAutoRules();
      state = AsyncValue.data(rules);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AutoNotificationRule> create(Map<String, dynamic> data) async {
    final rule = await _repository.createAutoRule(data);
    await load();
    return rule;
  }

  Future<AutoNotificationRule> update(
      String id, Map<String, dynamic> data) async {
    final rule = await _repository.updateAutoRule(id, data);
    await load();
    return rule;
  }

  Future<void> delete(String id) async {
    await _repository.deleteAutoRule(id);
    await load();
  }

  Future<void> toggle(String id, bool active) async {
    await _repository.toggleAutoRule(id, active);
    await load();
  }
}

final autoRulesNotifierProvider = StateNotifierProvider<AutoRulesNotifier,
    AsyncValue<List<AutoNotificationRule>>>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return AutoRulesNotifier(repo);
});

// ============================================================
// SMS & Email Config
// ============================================================

final smsConfigProvider = FutureProvider<SmsConfig?>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getSmsConfig();
});

final emailConfigProvider = FutureProvider<EmailConfig?>((ref) async {
  final repo = ref.watch(communicationRepositoryProvider);
  return repo.getEmailConfig();
});

// ============================================================
// Selected state providers for campaign creation wizard
// ============================================================

final selectedTemplateIdProvider = StateProvider<String?>((ref) => null);
final selectedTargetTypeProvider =
    StateProvider<CampaignTargetType>((ref) => CampaignTargetType.all);
final selectedChannelsProvider =
    StateProvider<List<CommunicationChannel>>((ref) => [CommunicationChannel.inApp]);
final campaignCreateStepProvider = StateProvider<int>((ref) => 0);

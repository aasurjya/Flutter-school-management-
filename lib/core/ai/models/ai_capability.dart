/// Capabilities that an AI adapter can support.
enum AICapability {
  /// Standard text generation (chat completion).
  textGeneration,

  /// Vision — can process images alongside text.
  vision,

  /// Image generation — returns an image URL or base64.
  imageGeneration,

  /// Guaranteed JSON output mode.
  jsonMode,
}

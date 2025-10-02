

enum SettingType {
  // Persisted
  skipLgtm(bool, false, persist: true),
  skipCredentialsSent(bool, false, persist: true),

  // Never change, always false.
  // Only here because Fetcher expects it due to shared code with Nerdster.
  skipVerify(bool, false),
  httpFetch(bool, false),
  batchFetch(bool, false),

  dev(bool, false),
  bogus(bool, true);


  final Type type;
  final dynamic defaultValue;
  final List<String> aliases;
  final bool persist;
  final bool param;

  const SettingType(this.type, this.defaultValue,
      {this.aliases = const [], this.persist = false, this.param = true});
}

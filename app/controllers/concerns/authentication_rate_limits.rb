module AuthenticationRateLimits
  # Single web process by design. Restarting it clears counters.
  STORE = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)
end

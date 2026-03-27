if defined?(IRB)
  history_file = File.expand_path("tmp/.irb_history", __dir__)

  IRB.conf[:SAVE_HISTORY] = 1_000
  IRB.conf[:HISTORY_FILE] = history_file
end

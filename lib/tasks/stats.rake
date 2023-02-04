# frozen_string_literal: true

task :stats do
  require 'rails/code_statistics'

  CodeStatistics::TEST_TYPES << 'Services tests'

  ::STATS_DIRECTORIES << ['Services', 'app/services']
  ::STATS_DIRECTORIES << ['Services tests', 'test/services']
end

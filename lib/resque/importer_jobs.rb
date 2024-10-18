require_relative './base_job'

module Resque
  class ImporterJobs < BaseJob
    @queue = :imports

    def self.perform(options = {})
      puts 'run_action DataImport'
      run_action(options, @queue, lambda { |options| DataImport[options.symbolize_keys[:job_id]].run_import! })
    end
  end
end
# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Run all the selected cops and report the result.
      class ExecuteRunner < Base
        include Formatter::TextUtil

        self.command_name = :execute_runner

        def run
          execute_runner(@paths)
        end

        private

        def execute_runner(paths)
          runner = Runner.new(@options, @config_store)

          all_passed = runner.run(paths)
          display_warning_summary(runner.warnings)
          display_error_summary(runner.errors)
          maybe_print_corrected_source

          all_pass_or_excluded = all_passed || @options[:auto_gen_config]

          if runner.aborting?
            STATUS_INTERRUPTED
          elsif all_pass_or_excluded && runner.errors.empty?
            STATUS_SUCCESS
          else
            STATUS_OFFENSES
          end
        end

        def display_warning_summary(warnings)
          return if warnings.empty?

          warn Rainbow("\n#{pluralize(warnings.size, 'warning')}:").yellow

          warnings.each { |warning| warn warning }
        end

        def display_error_summary(errors)
          return if errors.empty?

          warn Rainbow("\n#{pluralize(errors.size, 'error')} occurred:").red

          errors.each { |error| warn error }

          warn <<~WARNING
            Errors are usually caused by RuboCop bugs.
            Please, report your problems to RuboCop's issue tracker.
            #{Gem.loaded_specs['rubocop'].metadata['bug_tracker_uri']}

            Mention the following information in the issue report:
            #{RuboCop::Version.version(true)}
          WARNING
        end

        def maybe_print_corrected_source
          # If we are asked to autocorrect source code read from stdin, the only
          # reasonable place to write it is to stdout
          # Unfortunately, we also write other information to stdout
          # So a delimiter is needed for tools to easily identify where the
          # autocorrected source begins
          return unless @options[:stdin] && @options[:auto_correct]

          puts '=' * 20
          print @options[:stdin]
        end
      end
    end
  end
end

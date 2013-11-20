require 'travis'
require 'travis/pro'

module Arf
  class Travis

    STATUSES = {
      broken: ->(build, _) { build.failed? || build.errored? },
      fixed:  ->(previous_build, event) { (previous_build.failed? || previous_build.errored?) && event.build.passed? }
    }

    def initialize(access_token: Arf.ACCESS_TOKEN)
      Travis::Pro.access_token = access_token
    end

    def listen_for_build_completions!
      Travis::Pro.listen(*repo_names) do |stream|
        stream.on 'build:finished' do |event|
          case event
          when EVENTS[:broken].curry(event.build)
            Arf::Broken.new(event.build)
          when EVENTS[:fixed].curry(event.repository.recent_builds.to_a[-2])
            Arf::Fixed.new(event.build)
          end.trigger!
        end
      end
    end

    private

    def user
      Travis::Pro::User.current
    end

    def repos
      @repos ||= user.repositories
    end

    def repo_names
      repos.map(&:name)
    end

  end
end
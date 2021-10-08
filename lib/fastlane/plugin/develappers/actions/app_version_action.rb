module Fastlane
  module Actions
    class AppVersionAction < Action
      def self.run(params)
        output = params[:output].downcase

        flavor = params[:flavor]

        tag_prefix = 'iOS'
        tag_prefix = "iOS/#{flavor.downcase}" unless flavor.nil?

        should_export = !params[:export_file].nil?

        if !output.eql?('code') || should_export

          # prev. version tag in git
          UI.message "Searching Tag matching '#{tag_prefix}/*'"

          tag_name = `git describe --tags --match "#{tag_prefix}/*" --abbrev=0`
          match = tag_name.match(/^.*v([.\d]*)-?\d*$/s)

          if match.nil?
            version_name = '0.1.0'
            UI.message "Version name is #{version_name} because of no matching tag"
          else
            version_name = match[1]
            UI.message "Version name is #{version_name} because of last tag #{tag_name}"
          end

        end

        if !output.eql?('name') || should_export
          build = other_action.latest_testflight_build_number(app_identifier: params[:app_identifier])
          build += 1
        end

        tag_name = "#{tag_prefix}/v#{version_name}-#{build}" if !output.eql?('tagname') || should_export

        if should_export
          export_file_path = params[:export_file]

          File.open(export_file_path, 'w') do |file|
            file.puts("VERSION_NAME=#{version_name}")
            file.puts("VERSION_CODE=#{build}")
            file.puts("TAG_NAME=#{tag_name}")
          end

          UI.important "VERSION_NAME, VERSION_CODE and TAG_NAME written to file #{export_file_path}"
        end

        if output.eql?('name')
          version_name
        elsif output.eql?('code')
          build
        elsif output.eql?('tagname')
          tag_name
        else
          {
            version_name: version_name,
            version_code: build,
            tag_name: tag_name
          }
        end
      end

      def self.description
        "Get's you the current version info"
      end

      def self.authors
        ['Johannes Starke']
      end

      def self.return_value
        'Full version, version name or version code'
      end

      def self.details; end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :app_identifier, env_name: 'APP_VERSION_APP_IDENTIFER',
                                       description: 'App identifier', type: String),

          FastlaneCore::ConfigItem.new(key: :flavor, env_name: 'APP_VERSION_FLAVOR',
                                       description: 'Build flavor', type: String, optional: true, default_value: nil),
          FastlaneCore::ConfigItem.new(key: :output,
                                       description: 'Output, options are Full|Name|Code|Tagname', type: String, optional: true, default_value: 'Full'),
          FastlaneCore::ConfigItem.new(key: :export_file,
                                       description: 'If a file is specified, the version information is exported to the file', type: String, optional: true)
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
      end
    end
  end
end

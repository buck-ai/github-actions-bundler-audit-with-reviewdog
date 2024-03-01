# frozen_string_literal: true

require 'json'

GEMFILE_LOCK_PATH = "#{ENV['GITHUB_WORKSPACE']}/Gemfile.lock"

CRITICALITY_MAPPING = {
    nil        => 0,
    'none'     => 0,
    'low'      => 0,
    'medium'   => 1,
    'high'     => 2,
    'critical' => 2
}.freeze

SEVERITIES = %w[INFO WARNING ERROR].freeze

piped_json = STDIN.each_line.to_a.last
json_input = JSON.parse(piped_json)
results    = json_input['results']

def result_formatter(result)
    advisory = result['advisory']
    gem      = result['gem']
    line     = `grep -n -E '^#{gem['name']}\s\(#{gem['version']}\)' #{GEMFILE_LOCK_PATH} | cut -d : -f 1`.to_i
    message  = [
        "#{gem['name']} has #{advisory['title']} on #{gem['version']} version.",
        "You can bump #{gem['name']} version from #{gem['version']} to #{advisory['patched_versions'].join(', ')}"
    ].join(' ')

    {
        message: message, 
        location: {
            path: GEMFILE_LOCK_PATH,
            range: {
                start: {
                    line: line,
                    column: 0
                }
            }
        },
        severity: SEVERITIES[CRITICALITY_MAPPING[advisory['criticality']]],
        code: {
            value: advisory['id'],
            url: advisory['url']
        }
    }
end

max_criticality_score = results.map { |result| CRITICALITY_MAPPING[result.dig('advisory', 'criticality')] }.max
max_severity          = SEVERITIES[max_criticality_score]

output  = {
    source: {
        name: 'bundler-audit',
        url: 'https://github.com/rubysec/bundler-audit'
    },
    severity: max_severity,
    diagnostics: results.map { |result| result_formatter(result) }
}

puts output.to_json

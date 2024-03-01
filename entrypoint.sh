#!/bin/sh -e

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

echo "::group:: Installing bundler-audit"

gem install -N bundler-audit

echo '::endgroup::'


echo '::group:: Running bundler-audit with reviewdog 🐶'

bundler-audit check --format json \
    | ruby ${GITHUB_ACTION_PATH}/rdjson_formatter.rb \
    | reviewdog -f=rdjson \
        -name="bundler-audit" \
        -reporter="${INPUT_REPORTER}" \
        -filter-mode="${INPUT_FILTER_MODE}" \
        -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
        -level="${INPUT_LEVEL}"

exit_code=$?

echo '::endgroup::'

exit $exit_code
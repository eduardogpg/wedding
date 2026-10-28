# Run using bin/ci

CI.run do
  step "Prepare test database", "env RAILS_ENV=test bin/rails db:prepare"
  step "Check autoloading", "env RAILS_ENV=test bin/rails zeitwerk:check"
  step "Tests: Rails", "bin/rails test"

  # Optional: Run system tests
  # step "Tests: System", "bin/rails test:system"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end

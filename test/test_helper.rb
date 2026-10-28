ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def wedding_attributes(**overrides)
      { partner_one: "Eduardo", partner_two: "Raquel", subdomain: "eduardo-and-raquel",
        wedding_date: Date.current + 90.days, invitation_text: "Celebrate with us.",
        timezone: "Mexico City", theme: "sage" }.merge(overrides)
    end

    def create_wedding(**overrides)
      Wedding.create!(wedding_attributes(**overrides))
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in
    host! "app.localhost"
    user = User.find_or_create_by!(email: "test-planner@example.com") { |planner| planner.password = "test-planner-password" }
    post session_path, params: { email: user.email, password: "test-planner-password" }
    assert_redirected_to root_path
  end
end

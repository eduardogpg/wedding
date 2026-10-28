class PlannerController < ApplicationController
  before_action :require_planner
  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:signed_in_at] && session[:signed_in_at] > 12.hours.ago.to_i
  end

  def require_planner
    unless current_user
      reset_session
      redirect_to new_session_path, alert: "Please sign in to manage your weddings."
    end
  end
end

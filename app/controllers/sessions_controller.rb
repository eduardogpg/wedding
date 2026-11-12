class SessionsController < ApplicationController
  layout "authentication"
  rate_limit to: 10, within: 3.minutes, only: :create,
    with: -> { redirect_to new_session_path, alert: "Demasiados intentos. Vuelve a probar en unos minutos." }

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password])
    if user
      reset_session
      session[:user_id] = user.id
      session[:signed_in_at] = Time.current.to_i
      redirect_to root_path, notice: "Qué bueno verte. Vamos a preparar algo memorable."
    else
      flash.now[:alert] = "El correo o la contraseña no son correctos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Cerraste la sesión."
  end
end

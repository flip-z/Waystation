class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      respond_to do |format|
        format.html { redirect_to edit_profile_path, notice: "Profile updated." }
        format.json { render json: { mic_mode: @user.mic_mode }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def profile_params
    params.require(:user).permit(:handle, :mic_mode, :chat_color)
  end
end

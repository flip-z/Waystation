class FileFoldersController < ApplicationController
  before_action :require_admin!
  before_action :set_folder, only: :destroy

  def create
    folder = FileFolder.new(folder_params)

    if folder.save
      redirect_to folder_redirect_target(folder.parent), notice: "Folder created."
    else
      redirect_back fallback_location: files_path, alert: folder.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @folder.children.exists? || @folder.file_entries.exists?
      redirect_back fallback_location: folder_redirect_target(@folder.parent),
                    alert: "Folder must be empty before deletion."
      return
    end

    parent = @folder.parent
    @folder.destroy
    redirect_to folder_redirect_target(parent), notice: "Folder deleted."
  end

  private

  def set_folder
    @folder = FileFolder.find(params[:id])
  end

  def folder_params
    params.require(:file_folder).permit(:name, :parent_id)
  end

  def folder_redirect_target(folder)
    folder ? file_folder_path(folder) : files_path
  end
end

class FilesController < ApplicationController
  before_action :require_file_read!
  before_action :set_folder, only: :index
  before_action :set_file_entry, only: %i[ show destroy ]
  before_action :require_file_upload!, only: :create
  before_action :require_admin!, only: :destroy

  def index
    prepare_index
  end

  def create
    @file_entry = current_user.file_entries.build(file_entry_params)

    if @file_entry.save
      redirect_to folder_redirect_target(@file_entry.folder), notice: "File uploaded."
    else
      @folder = @file_entry.folder
      prepare_index
      render :index, status: :unprocessable_entity
    end
  end

  def show
    unless @file_entry.file.attached? && @file_entry.downloadable?
      redirect_to folder_redirect_target(@file_entry.folder),
                  alert: "File is not available for download."
      return
    end

    redirect_to rails_blob_url(@file_entry.file, disposition: "attachment")
  end

  def destroy
    folder = @file_entry.folder
    @file_entry.destroy
    redirect_to folder_redirect_target(folder), notice: "File deleted."
  end

  private

  def set_folder
    folder_id = params[:folder_id] || params[:id]
    @folder = FileFolder.find_by(id: folder_id) if folder_id.present?
  end

  def set_file_entry
    @file_entry = FileEntry.find(params[:id])
  end

  def file_entry_params
    params.require(:file_entry).permit(:file, :folder_id)
  end

  def require_file_read!
    return if current_user&.can_read_files?

    redirect_to root_path, alert: "Not authorized to view files."
  end

  def require_file_upload!
    return if current_user&.can_upload_files?

    redirect_to files_path, alert: "Upload permission required."
  end

  def prepare_index
    folder_id = @folder&.id
    @folders = FileFolder.where(parent_id: folder_id).order(:name)
    @files = FileEntry
      .includes(:uploaded_by, file_attachment: :blob)
      .where(folder_id: folder_id)
      .order(created_at: :desc)
    @file_entry ||= FileEntry.new(folder: @folder)
    @folder_form = FileFolder.new(parent: @folder)
    @alerts = FileEntry
      .includes(:uploaded_by, :folder)
      .where(status: %i[ quarantined error ])
      .order(updated_at: :desc)
      .limit(10)
  end

  def folder_redirect_target(folder)
    folder ? file_folder_path(folder) : files_path
  end
end

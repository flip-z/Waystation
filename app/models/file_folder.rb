class FileFolder < ApplicationRecord
  belongs_to :parent, class_name: "FileFolder", optional: true
  has_many :children, class_name: "FileFolder", foreign_key: :parent_id, dependent: :destroy
  has_many :file_entries, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parent_id, case_sensitive: false }

  def breadcrumb_names
    parent ? parent.breadcrumb_names + [name] : [name]
  end
end

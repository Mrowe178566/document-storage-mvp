class PinsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Real per-user pinning ships in the FolderPin PR. Until then this page
    # serves as a polished landing for the nav item so the empty state
    # explains the upcoming feature rather than leaving a broken link.
    @pinned_folders = []
    add_breadcrumb "Pinned", pins_path
  end
end

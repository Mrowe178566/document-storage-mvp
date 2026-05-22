# Returns a small set of "suggested" folders for the dashboard, ranked by a
# weighted score over the signals we actually have in the database. Mirrors
# the idea of Dropbox/Drive "suggested for you" without inventing an
# Activity table.
#
# Scoring weights (intentionally simple — easy to tune from feedback):
#
#   file_count      : 1pt per file in the folder
#                     "this folder has stuff in it"
#   recent_uploads  : 3pt per upload in the last 7 days
#                     "this folder is being used right now"
#   starter_match   : 2pt if the folder name is in the manufacturing starter
#                     "this is a canonical folder we expect to matter"
#
# The starter bonus prevents brand-new bootstrapped workspaces from showing a
# random empty section — even with no uploads yet, the starter folders rank
# above any custom folders someone may have added since.
#
# TODO(ai-classifier): If we ever add a file-classification service that tags
# uploads with their semantic category (e.g. "blueprint", "invoice", "MSDS"),
# we can boost folders whose classifications cluster around a tight set of
# semantic types — that signals "this folder has a clear purpose."
#
# Usage:
#   folders = SuggestedFoldersQuery.call(workspace: current_workspace, limit: 4)
class SuggestedFoldersQuery
  RECENT_WINDOW = 7.days
  WEIGHT_FILE_COUNT     = 1
  WEIGHT_RECENT_UPLOADS = 3
  WEIGHT_STARTER_MATCH  = 2

  def self.call(workspace:, limit: 4)
    new(workspace: workspace, limit: limit).call
  end

  def initialize(workspace:, limit:)
    @workspace = workspace
    @limit = limit
  end

  def call
    folders = @workspace.folders.includes(:stored_files).to_a
    return [] if folders.empty?

    folders.sort_by { |f| -score_for(f) }.first(@limit)
  end

  private

  def score_for(folder)
    file_count       = folder.stored_files.size
    recent_count     = folder.stored_files.count { |sf| sf.created_at >= RECENT_WINDOW.ago }
    starter_match    = Workspaces::Bootstrap::MANUFACTURING_FOLDERS.include?(folder.name) ? 1 : 0

    (file_count       * WEIGHT_FILE_COUNT) +
    (recent_count     * WEIGHT_RECENT_UPLOADS) +
    (starter_match    * WEIGHT_STARTER_MATCH)
  end
end

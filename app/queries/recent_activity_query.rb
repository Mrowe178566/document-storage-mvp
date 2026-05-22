# Derives a unified activity feed for a workspace by pulling recent rows from
# the models that represent "something happened": file uploads, folder
# creations, member joins, and accepted invitations.
#
# There is intentionally no Activity table backing this — events are derived
# from existing model timestamps, which keeps the schema small. If we ever
# need persistent audit logging, swap this implementation for one that reads
# from an Activity table without changing callers.
#
# visible_folder_ids is an optional filter (typically passed from the
# dashboard controller via policy_scope) that hides file/folder events for
# restricted folders the current user can't see. Pass nil to get everything.
#
# Usage:
#   events = RecentActivityQuery.call(workspace: current_workspace, limit: 20)
#   events.each { |e| puts "#{e.timestamp} #{e.message}" }
class RecentActivityQuery
  Event = Struct.new(:type, :message, :actor_email, :timestamp, :icon, keyword_init: true)

  def self.call(workspace:, visible_folder_ids: nil, limit: 20)
    new(workspace: workspace, visible_folder_ids: visible_folder_ids, limit: limit).call
  end

  def initialize(workspace:, visible_folder_ids:, limit:)
    @workspace          = workspace
    @visible_folder_ids = visible_folder_ids
    @limit              = limit
  end

  def call
    events = []
    events.concat(file_events)
    events.concat(folder_events)
    events.concat(member_events)
    events.concat(invitation_events)

    events.sort_by { |e| e.timestamp }.reverse.first(@limit)
  end

  private

  # Pull more than @limit from each source so the merge has room to work —
  # otherwise files could crowd out folder events if a burst of uploads landed.
  def per_source_limit
    @limit * 2
  end

  def file_events
    files = @workspace.stored_files.includes(:user, :folder)
    files = files.where(folder_id: @visible_folder_ids) if @visible_folder_ids
    files.order(created_at: :desc).limit(per_source_limit).map do |file|
      Event.new(
        type: :file_uploaded,
        message: "uploaded <strong>#{ERB::Util.h(file.file_name)}</strong> to #{ERB::Util.h(file.folder&.name || 'a folder')}",
        actor_email: file.user&.email,
        timestamp: file.created_at,
        icon: "bi-file-earmark-arrow-up"
      )
    end
  end

  def folder_events
    folders = @workspace.folders.includes(:user)
    folders = folders.where(id: @visible_folder_ids) if @visible_folder_ids
    folders.order(created_at: :desc).limit(per_source_limit).map do |folder|
      Event.new(
        type: :folder_created,
        message: "created folder <strong>#{ERB::Util.h(folder.name)}</strong>",
        actor_email: folder.user&.email,
        timestamp: folder.created_at,
        icon: "bi-folder-plus"
      )
    end
  end

  def member_events
    @workspace.memberships
              .includes(:user)
              .order(created_at: :desc)
              .limit(per_source_limit)
              .map do |membership|
      Event.new(
        type: :member_joined,
        message: "joined as <strong>#{membership.role.capitalize}</strong>",
        actor_email: membership.user&.email,
        timestamp: membership.created_at,
        icon: "bi-person-plus"
      )
    end
  end

  def invitation_events
    @workspace.invitations
              .where.not(accepted_at: nil)
              .includes(:invited_by)
              .order(accepted_at: :desc)
              .limit(per_source_limit)
              .map do |invitation|
      Event.new(
        type: :invitation_accepted,
        message: "accepted invitation from <strong>#{ERB::Util.h(invitation.invited_by&.email || 'someone')}</strong>",
        actor_email: invitation.email,
        timestamp: invitation.accepted_at,
        icon: "bi-envelope-check"
      )
    end
  end
end

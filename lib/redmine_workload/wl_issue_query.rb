# frozen_string_literal: true

module WlIssueQuery
  ##
  # Returns all issues that fulfill the following conditions:
  #  * They are open
  #  * The project they belong to is active
  #
  # @param users [Array(User)] An array of user objects.
  # @return [ActiveRecord::Relation(Isue)] The set of issues meeting the
  #                                        conditions above.
  #
  #
  def open_issues_for_users(users, issues = nil)
    return issues if issues

    raise ArgumentError unless users.is_a?(Array)

    user_ids = users.map(&:id)

    issue = Issue.arel_table
    project = Project.arel_table
    issue_status = IssueStatus.arel_table

    # Fetch all issues that ...
    issues = Issue.joins(:project)
                  .joins(:status)
                  .joins(:assigned_to)
                  .where(issue[:assigned_to_id].in(user_ids))     # Are assigned to one of the interesting users
                  .where(project[:status].eq(1))                  # Do not belong to an inactive project
                  .where(issue_status[:is_closed].eq(false))      # Is open

    # Filter out all issues that have children; They do not *directly* add to
    # the workload
    issues.select(&:leaf?)
  end
end
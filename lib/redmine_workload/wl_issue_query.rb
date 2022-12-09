# frozen_string_literal: true

module WlIssueQuery
  include WlCalculationRestrictions
  ##
  # Returns all issues that fulfill the following conditions:
  #  * They are open
  #  * The project they belong to is active
  #  * They have no children if consider_parent_issues? is false
  #  * They are parent or child isse if consider_parent_issues? is true
  #
  # @param users [Array(User)] An array of user objects.
  # @return [Array(Issue)] The set of issues meeting the conditions above.
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

    # Filter out all issues that have children
    return issues.select(&:leaf?) unless consider_parent_issues?

    # Contains parent and child issues
    issues.split.flatten
  end
end

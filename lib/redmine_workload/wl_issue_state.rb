# frozen_string_literal: true

module WlIssueState
  ##
  # Redefines the overdue state of an issue. Instead of comparing issue.due_date
  # with the User.current.today (as in Issue#overdue?) it will compare by the
  # date given.
  #
  def issue_overdue?(issue, date)
    issue.due_date.present? && (issue.due_date < date) && !issue.closed?
  end
end

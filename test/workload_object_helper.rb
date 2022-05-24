# frozen_string_literal: true

module RedmineWorkload
  module WorkloadObjectHelper
    ##
    # Creates all objects required to analyse user or group workload objects
    # in tests.
    #
    # @param user [User] The current user.
    # @param role [Role] The role of the group to which issues should be assigned to.
    # @param main_group_strategy [Symbol|String] The strategy (:same or :distinct)
    #        to be used for setting the main group for user1 and user2.
    # @param vacation_strategy [Symbol|String] The strategy (:same or :distinct)
    #        to be used for setting up vacation for user1 and user2.
    # @param groups [Array(Group)] A list of groups, e.g., given by the method
    #        RedmineWorkload::WorkloadObjectHelper#groups_defined.
    # @return [GroupWorkload] A GroupWorkload object.
    #
    def prepare_group_workload(user:, role:, main_group_strategy:, vacation_strategy:, groups: nil)
      if groups
        groups.compact!
        groups_params = groups.map(&:id)
      else
        groups_params = nil
      end
      users = users_defined
      if users
        users.compact!
        users_params = users.map(&:id)
      else
        users_params = nil
      end
      user_setup(groups: groups, users: users, main_group_strategy: main_group_strategy, vacation_strategy: vacation_strategy) if groups
      issue_setup(groups: groups, users: users, role: role)
      group_selection = WlGroupSelection.new(groups: groups_params,
                                             user: user)
      user_selection = WlUserSelection.new(users: users_params,
                                           user: user,
                                           group_selection: group_selection)
      assignees = user_selection.all_selected
      user_workload = UserWorkload.new(assignees: assignees,
                                       time_span: first_day..last_day,
                                       today: first_day)

      GroupWorkload.new(users: user_selection,
                        user_workload: user_workload.hours_per_user_issue_and_day,
                        time_span: first_day..last_day)
    end

    def groups_defined
      [Group.generate!, Group.generate!]
    end

    def users_defined
      [User.generate!, User.generate!]
    end

    def user_setup(**params)
      group1, group2 = params[:groups]
      user1, user2 = params[:users]
      vacation_strategy = params[:vacation_strategy]
      main_group_strategy = params[:main_group_strategy]

      if vacation_strategy
        user1.wl_user_vacations.create(date_from: first_day, date_to: first_day)
        user2.wl_user_vacations.create(with_vacation_strategy(vacation_strategy))
      end

      user1.groups << group1
      assert user1.groups.include? group1
      user1.groups.reload
      assert Group.find(group1.id).users.include? user1

      user1.create_wl_user_data(threshold_highload_min: 6,
                                threshold_lowload_min: 3,
                                threshold_normalload_min: 4,
                                main_group: group1.id)
      assert_equal group1.id, user1.wl_user_data.main_group

      user2.groups << group1
      user2.groups << group2
      assert user2.groups.include? group1
      assert user2.groups.include? group2
      user2.groups.reload
      assert Group.find(group1.id).users.include? user2
      assert Group.find(group2.id).users.include? user2

      user2.create_wl_user_data(threshold_highload_min: 6,
                                threshold_lowload_min: 3,
                                threshold_normalload_min: 4,
                                main_group: with_main_group_strategy(group1, group2, main_group_strategy))
      assert_equal with_main_group_strategy(group1, group2, main_group_strategy), user2.wl_user_data.main_group
    end

    def with_main_group_strategy(group1, group2, main_group_strategy)
      case main_group_strategy.to_sym
      when :distinct
        group2.id
      when :same
        group1.id
      end
    end

    def with_vacation_strategy(vacation_strategy)
      case vacation_strategy.to_sym
      when :distinct
        { date_from: last_day, date_to: last_day }
      when :same
        { date_from: first_day, date_to: first_day }
      end
    end

    def issue_setup(**params)
      project = Project.generate!
      params[:groups]&.each do |group|
        project.members << Member.new(principal: group,
                                      roles: [params[:role]])
      end
      with_settings issue_group_assignment: '1' do
        params[:users].each do |user|
          group = user.groups.take
          User.add_to_project(user, project, @manager) unless params[:groups]
          Issue.generate!(author: user,
                          assigned_to: user,
                          status: IssueStatus.find(1), # New, not closed
                          project: project,
                          tracker: trackers(:trackers_001),
                          priority: enumerations(:enumerations_004),
                          estimated_hours: 12.0,
                          start_date: first_day,
                          due_date: last_day)
          next unless user.groups.any?

          Issue.generate!(author: user,
                          assigned_to: group,
                          status: IssueStatus.find(1), # New, not closed
                          project: project,
                          tracker: trackers(:trackers_001),
                          priority: enumerations(:enumerations_004),
                          estimated_hours: 12.0,
                          start_date: first_day,
                          due_date: last_day)

          Issue.generate!(author: user,
                          assigned_to: group,
                          status: IssueStatus.find(1), # New, not closed
                          project: project,
                          tracker: trackers(:trackers_001),
                          priority: enumerations(:enumerations_004),
                          estimated_hours: 12.0) # unscheduled: without dates
        end
      end
    end

    def first_day
      Date.new(2022, 5, 25) # Wednesday
    end

    def last_day
      Date.new(2022, 5, 30) # Monday
    end
  end
end

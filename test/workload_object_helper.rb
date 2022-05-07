# frozen_string_literal: true

module RedmineWorkload
  module WorkloadObjectHelper
    def prepare_group_workload(user:, role:,groups: nil)
      if groups
        groups.compact!
        groups_params = groups.map(&:id)
      else   
        group_params = nil
      end
      if users = users_defined
        users.compact!
        user1, user2 = users
        users_params = users.map(&:id)
      else
        user_params = nil
      end
      user_setup(groups: groups, users: users) if groups
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

      user1.groups << group1
      assert user1.groups.include? group1

      user1.create_wl_user_data(threshold_highload_min: 6,
                                threshold_lowload_min: 3,
                                threshold_normalload_min: 4,
                                main_group: group1.id)
      assert_equal group1.id, user1.wl_user_data.main_group

      user2.groups << [group1, group2]
      assert user2.groups.include? group1
      assert user2.groups.include? group2

      user2.create_wl_user_data(threshold_highload_min: 6,
                                threshold_lowload_min: 3,
                                threshold_normalload_min: 4,
                                main_group: group2.id)
      assert_equal group2.id, user2.wl_user_data.main_group
    end

    def issue_setup(**params)
      project = Project.generate!
      params[:groups]&.each do |group|
        project.members << Member.new(:principal => group, 
                                      :roles => [params[:role]])
      end
      with_settings :issue_group_assignment => '1' do
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
          if user.groups.any?                
            Issue.generate!(author: user,
                                  assigned_to: group,
                                  status: IssueStatus.find(1), # New, not closed
                                  project: project,
                                  tracker: trackers(:trackers_001),
                                  priority: enumerations(:enumerations_004),
                                  estimated_hours: 12.0,
                                  start_date: first_day,
                                  due_date: last_day)
          end
        end
      end
    end

    def first_day
      Date.new(2013, 5, 25)
    end

    def last_day
      Date.new(2013, 6, 4)
    end  
  end
end

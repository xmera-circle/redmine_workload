### Workload-Plugin for Redmine

A complete rewrite of the original workload-plugin from Rafael Calleja. The
plugin calculates how much work each user would have to do per day in order
to hit the deadlines for all his issues.

To be able to do this calculation, the issues start date, due date and
estimated time must be filled in. Issues that have not filled in one of
these fields will be shown in the overview, but the workload resulting from
these issues will be ignored.

#### Installation

1. To install it, simply clone it into the plugins-directory. Execute

    git clone https://github.com/JostBaron/redmine_workload.git redmine_workload

 in your plugins directory. 

2. database migration:

	cd ..
	rake redmine:plugins:migrate
	
3. reload web service

	touch tmp/restart.txt
    
#### Configuration

There are two places where this plugin might be configured:

1. In the plugin settings, available in the administration area under "plugins".
2. In the Roles-section of the administration area, the plugin adds a new
  permission "view workload data in own projects". When this permission is given
  to a user in a project, he might see the workload of all the members of that
  project.

#### Permissions

The plugin shows the workload as follows:

* An anonymous user can't see any workload.
* An admin user can see the workload of everyone.
* Any normal user can see the following workload:

  - He may always see his own workload.
  - He may see the workload of every user that is member of a project for which
    he has the permission "view workload data in own projects" (see above).
  - When showing the issues that contribute to the workload, only issues visible
    to the current user are shown. Invisible issues are only summarized.

#### Holidays, Vacation and User Workload Data

National holidays and user vacation is counted as day off (like weekend).

Admins can setup National Holidays in plugin-settings.
Users can get permissions to setup their vacations and Workload Data with 'Roles and permissions'.  
You can specify user(s), who should be able to setup national holidays with 'Roles and permissions'.


#### ToDo

* Improve performance - requests still take up to 5 seconds.
* Add legend (again).
* Use nicer colors for workload indications.

### Workload-Plugin for Redmine

A complete rewrite of the original workload-plugin from Rafael Calleja. The
plugin calculates how much work each user would have to do per day in order
to hit the deadlines for all his issues.

To be able to do this calculation, the issues start date, due date and
estimated time must be filled in. Issues that have not filled in one of
these fields will be shown in the overview, but the workload resulting from
these issues will be ignored.

#### Installation

To install it, simply clone it into the plugins-directory. Execute

    git clone https://github.com/JostBaron/redmine_workload.git redmine_workload

in your plugins directory. Then restart your redmine. There is no need for
database migration, as this plugin does not change anything in the database.

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

#### ToDo

* Make it possible to display the workload starting with another day than the
start of a month.
* Improve performance - requests still take up to 5 seconds.
* Add legend (again).
* Use nicer colors for workload indications.

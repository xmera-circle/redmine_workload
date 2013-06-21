### Workload-Plugin for Redmine

A complete rewrite of the original workload-plugin from Rafael Calleja. The
plugin calculates, how much work a user would have to do in order to hit the
deadline for all his issues.

To be able to do this, the issue start date, due date and estimated time must be
filled. Issues that have not filled out one of these fields will be shown in the
overview, but the workload resulting from these issues will be ignored.

The thresholds at which a user is considered to have too much or not enough work
may be configured in the plugin settings.

#### Installation

The plugin is tested with redmine 2.3.1.

To install it, simply clone it into the plugins-directory. Execute

    git clone https://github.com/JostBaron/redmine_workload.git redmine_workload

in your plugins directory. Then restart your redmine. There is no need for
database migration, as this plugin does not change anything in the database.
You may configure the workload plugin in the plugin-settings dialog in redmines
administration area.

#### ToDo

* Implement access restrictions. Not all users may see the workload of all
users.
* Make it possible to display the workload starting with another day than the
start of a month.
* Improve performance - requests still take up to 5 seconds.
* Add legend (again).
* Use nicer colors for workload indications.

# Workload Plugin for Redmine

A complete rewrite of the original workload-plugin from Rafael Calleja.
The plugin calculates how much work each user would have to do per day in order to hit the deadlines for all his issues.
It also calculates this information for a [group](https://www.redmine.org/projects/redmine/wiki/RedmineGroups).
It calculates issues (number and hours) that are behind schedule and calculates issues that are unplanned (number and hours) so far.
To be able to do all this calculations, the issues start date, due date and estimated time must be filled in.
Issues that have not filled in one of these fields will be shown in the overview, but the workload resulting from these issues will be ignored.

![Group Workload](screenshots/group-workload-example.png?raw=true "Group Workload Example")

## New Features in Version 2.1.0

### consider workload of parent issues

By default parent issues are ignored when calculating workloads. With this setting the administrator can change the default behaviour by considering also all parent issues in the calculation.

## New Features in Version 2.0.x

Fortunately the German company [MENTOR GmbH & Co. Präzisions-Bauteile KG](https://www.mentor.de.com/) invested in this project to make these features possible:

### support of Redmine 5

Version 2.0.2 supports Redmine 5 and is backward compatible with Redmine 4.

### style-rework

The actual table has been a bit bulky and sticked out from the formatting of other areas. Especially when using themes like [Purplemine](https://github.com/mrliptontea/PurpleMine2).
Now the css has been reworked to make the style more compact and gantt-like.

### workload per group

This introduces a new level of information for issues adressed to [groups](https://www.redmine.org/projects/redmine/wiki/RedmineGroups).
It now can show informations about issues adressed to a group and calculates the workload of this group.
To avoid missleading informations therefore each user needs to define the group where he/she puts his/her effort in.

### unplanned issues

The Plugin now calculates "unplanned" issues. This applys to issues that dont have a `start date` or a `due date`.
The result now is shown close to overdue issues.

### export

The only way to have a look on the data was the workload page.
There has been no way to transfer data, e.g. to excel, to draw some charts.
Now there is a feature to export the workload per user and per role to build charts external.

## Installation / Uninstallation

Please refer to [redmine.org -> Plugins](https://www.redmine.org/projects/redmine/wiki/Plugins)

## How it Works

![Workload Calculation Process](screenshots/workload_calculation.png?raw=true "Workload Caclulation Process")

## Configuration

There are three places where this plugin might be configured:

1. In the plugin settings, available in the administration area under `plugins`.
You can configure working days, thresholds here and set global holidays.

2. In the roles section of the administration area, the plugin adds new permissions as described below.
There is no need to configure this plugin on project level.

3. On the workload page each user can setup his vacations.
Here thresholds can be set divergent to global configuration. The `main group` needs to be set.


## Permissions

The plugin shows the workload as follows:
* An *admin user* can see the workload of everyone and configure user independent settings.
* Any normal user can **see** workload as configured per role under project permissions:
  - *view own workloads*: a role with this permission can see own workload
  - *view own group workloads*: a role with this permission can see workloads of all users in his/her configured `main group`
  - *view all workloads*:  a role with this permission can see workload of everyone.
  - When showing the issues that contribute to the workload, only issues visible to the current user are shown. Invisible issues are only summarized.
* Any normal user can **configure** own settings as set per role under project permissions:
  - *Edit national Holidays*
  - *Edit own vacations*
  - *Edit own workload thresholds*

## Holidays, Vacation and User Workload Data

National holidays and user vacation is counted as day off (like weekend).
Admins can setup National Holidays in plugin settings.
Users can get permissions to setup their vacations and workload data with 'Roles and permissions'.
You can specify user(s), who should be able to setup national holidays with 'Roles and permissions'.

## CSV-Export

Here you can export the values that are shown in the browser to use it in other systems (e.g. draw charts).

|Column|possible values|description|
|------|---------------|-----------|
|Status|planned, available|Describes if this Line shows planned workload or available hours per day.|
|Type|aggregation, group, user|Describes if this Line shows hours for one `user`, hours that assigned to a `group` or hours that are `aggregated` for the group.|
|Main group|*group-name*|Reports the configured `main group` for a `user` and (implicit) for a `group`. Is empty in case of aggregation.|
|Number of overdue issues|*number*|Number of issues that are behind schedule.|
|Hours of overdue issues|*hours*|Aggregated hours of issues that are behind schedule.|
|Number of unplanned issues|*number*|Number of issues that are unplanned.|
|Hours of unplanned issues|*hours*|Aggregated hours of issues that are unplanned.|
|..date..|*datum* and *hours*|Column is named from the belonging datum. Lists per line the hours per day.|
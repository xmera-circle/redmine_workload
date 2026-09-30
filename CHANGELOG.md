# Changelog for Redmine Workload

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 4.2.0 - unreleased

### Added

* Administrators can keep groups out of the workload group filter. The mark is
  a boolean group custom field, "Exclude from workload planning", created on
  install and editable both on the group form and collected on a new page
  linked from the plugin settings. If the field is deleted nothing is
  excluded; the page offers to recreate it. An excluded group also grants no
  view: with `view_own_group_workloads` its members are not visible through it

### Changed

* The built-in pseudo groups (non member, anonymous) no longer appear in the
  group filter

## 4.1.0 - 2026-09-09

### Changed

* The working days are read from Redmine's own 'Non-working days' setting
  instead of the plugin's weekday checkboxes, so both always agree (#30).
  Installations whose plugin setting differed from Redmine's get Redmine's
  days; the default (Monday to Friday) is unchanged. The settings page notes
  that changes take up to 12 hours to show because the calculation is cached
* The user list follows Redmine's 'Users display format' setting instead of
  always sorting by last name (#2)
* The expand/collapse trigger uses Redmine's sprite icon instead of a unicode
  character that rendered differently across browsers (#3)
* camelCase methods, parameters and variables renamed to snake_case; the
  corresponding Rubocop exclusions removed (#4)

### Fixed

* Collapsing a level left the triggers below it marked as opened, so the next
  click on them appeared to do nothing (#3)

## 4.0.0 - 2026-08-27

### Changed

* Updated for Redmine 6.1.x / Rails 7.2 compatibility
* Fixed Rails version comparisons to use Gem::Version
* Updated database adapter detection for Rails 7.2
* Updated ActiveRecord migrations to version 7.2
* Removed deprecated `unloadable` from controllers and models
* Fixed Ruby version comparison for PostgreSQL requirement
* Declared `requires_redmine version_or_higher: '6.1'`
* CI now runs against Redmine 6.1-stable on Ruby 3.2 instead of 5.0-stable
* Icons are rendered with `sprite_icon` instead of the legacy icon font
  classes, so they follow the active theme
* The plugin's javascript and stylesheet are no longer injected into every
  Redmine page, only into the plugin's own views
* Rubocop targets Ruby 3.2, the lowest version Redmine 6.1 allows

### Fixed

* HTTP 500 when an invalid date such as `2026-01-32` was entered in a workload
  filter; invalid input now falls back to the default value (#41)
* HTTP 500 when the 'Use as today' date was set beyond the last day of the
  displayed time span; the date is capped and a flash warning is shown (#40)
* `test/test_helper.rb` no longer uses `Rails.root` at load time. Rails 7.2 runs
  plugin tests in a separate process that requires the test files before the
  environment is loaded, where `Rails.root` does not exist
* `WlUserSelectionTest` accounts for Redmine 6's `fixtures :all`, which makes
  `users(:users_008)` a member of two groups
* An unscoped `legend` rule in the plugin's stylesheet restyled the legend of
  every fieldset in the whole Redmine installation; it is now scoped to the
  plugin's own views

### Removed

* Dead `Rails.version < '6'` branches in `init.rb` and `user_patch.rb`
* Ruby version guard for PostgreSQL and `RedmineWorkload.postgresql?`,
  unreachable since Redmine 6.1 requires Ruby >= 3.2

## 3.0.2 - 2023-07-24

### Deletes

* second border-right css for .controller-workloads .data .holiday.today

## 3.0.1 - 2023-07-19

### Fixed

* CSS styling for today line when user has holiday today

## 3.0.0 - 2023-07-18

### Added

* api support for csv export of workloads

### Fixed

* general workday setting what leads to a breaking change for postgres user
since they need to use ruby > 3.1.z

## 2.2.2 - 2023-05-05

### Added

* github actions for automated tests
* github pull request template

### Fixed

* zeitwerk issues
* postgres default keyword error
* test errors

## 2.2.1 - 2023-02-17

### Fixed

* nil error in data.keys.sort for very large time spans

## 2.2.0 - 2023-01-19

### Changed

* how to decide when an issue is overdue by comparing with a given date

## 2.1.0 - 2022-12-09

### Added

* Plugin setting 'workload_of_parent_issues' as option to include parent issues 
  in the workload calculation

## 2.0.2 - 2022-11-14

### Added

* support for Redmine 5 with backward compatability to Redmine 4
* translations for some permissions

### Fixed

* nil error in WorkloadsHelper#load_class_for_hour 
* nil error when user enters conflicting dates

## 2.0.1 - 2022-06-21

### Fixed

* undefined method 'id' in GroupWorkload#total_availabilities_of

## 2.0.0 - 2022-06-07

### Added

* week numbers to workload table header
* group issues to workload table if a group is selected
* calculation of group workload based on user main group setting
* presentation of summarized group workload in workload table
* additional infos about unscheduled issues
* permissions :view_all_workloads, :view_own_group_workloads, :view_own_workloads
* csv export of users or groups

### Changed

* using of dynamic action segments in routes due to deprecation warning
* styling of workload table to look similar as gantt diagram
* user and group selection to be in a separate class to make it reusable
* permissions to be global again, i.e., not dependend of project module enabled
* display of current user to show only if visited workload index page or when
selected explicitly
* error messages to translate field names

### Fixed

* broken unit test
* missing closing selectors in some views causing the site footer to be displayed
not at the bottom of the page

---

**NOTE** Changes prior and equal to version 1.1.0 are not reported.

# Changelog for Redmine Workload

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
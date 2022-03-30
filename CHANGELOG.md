# Changelog for Redmine Workload

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

### Added

* week numbers to workload table header
* group issues to workload table if a group is selected
* calculation of group workload based on user main group setting
* presentation of summarized group workload in workload table

### Changed

* WorkLoadHelper#workload_admin? to be deprecated in Redmine Workload 2.0.0
* using of dynamic action segments in routes due to deprecation warning
* styling of worload table to look similar as gantt diagram
* user and group selection to be in a separate class to make it reusable

### Fixed

* broken unit test

---

**NOTE** Changes prior and equal to version 1.1.0 are not reported yet.
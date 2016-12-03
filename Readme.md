# Summary

Syncs tasks from a Taskpaper file to Things. 

Will only sync the tasks with the following tags:

@flag
@due
@today
@start

Flag and Today tagged tasks will show up as "Today" in Things.

Due tagged tasks will be added with a due date. (and show up in today on the due date)

Start tagged tasks will be scheduled for their start date. (and show up in today on the due date)

Completing tasks in either Taskpaper or Things will mark them complete between the two.

However, making any changes in Things (other than completing) will not sync back to Taskpaper. This app is designed so that Taskpaper is the source of truth. Things is simply a way to quickly look at what is marked as today, due, and scheduled.

## Format

For @due and @start they need to have dates with format of (YYYY-MM-DD)

Example:

@start(2016-12-03)
@due(2016-12-03)

IMPORTANT: Things needs to have an Area called "Taskpaper". Thats where all the tasks will be synced to. If the area doesn't exist the app will not work.

## Sync

You can either sync manually by clicking the sync button.

Or, by default, the app will sync every 30 minutes. To change this edit the Repeat Sync field. (in minutes)

## Usage

1. In Things, create a new Area called "Taskpaper"
2. Run the TPThingsSync app
3. Click Pick File and select the taskpaper file you'd like to sync with Things
4. Click sync


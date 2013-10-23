# Alfred 2 Top Process Workflow

The initial motive of this workflow is to avoid frequent visits to the Activity Monitor when the fan goes loud. Now it has been evloved with two major features:

- 1) List/Kill Top Processes by Memory/CPU/IO Usage

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/mixed%20top%20processes.png) 


- 2) (*working in progress*) Get a glance of system status including internal battery, fan speed, CPU/GPU Temperature, bluetooth battery, disk capacity, etc.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/glance.png) 

## Usage

### 0. Show Help 

Just type `-?`, `-h`, or `--help` after the keyword to show help.

For example, `top -h`

### 1. Top Processes

#### A. Keywords:

##### 1.) `top`: Show a mixed processes list based on top cpu/memory usage.


###### 1. `top -m`, `top --memory` to show processes ranked by memory usage

###### 2. `top -c`, `top --cpu`, to show processes ranked by cpu usage

###### 3. `top -i`, `top --io`, to show processes ranked by io usage with **callback** from top io trace collector.

   Top IO requires [DTrace][Dtrace] and it would take a while to finish. The new **callback** design is to run the job in he background and post a notification (OSX 10.8+) using notification center. Click on the notification to show the result in alfred.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/callback.png) 




###### **Modifier Key**

   - `none`    : The default action is to list files opened by process ID
   - `control` : Kill the selected process
   - `command` : kill forcefully (`kill -9`)
   - `alt`     : Nice (lower) the selected process's cpu priority


##### 2.) `kill`: Filter process to kill.

###### **Modifier Key**

   - `none`: The default action is to kill by process ID
   - `command` : kill forcefully (`kill -9`)

##### 3.) `lsof`: List files opened by process id

###### **Modifier Key**

   - `none`: The default action is to reveal file in Finder

#### B. Filter by Query

##### 1.) Type process name to filter

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/filtered%20by%20query.png)

##### 2.) To search for process state, use **:idle**, **:sleep**, **:stopped**, **:zombie**, **:uninterruptible**, **:runnable**, etc.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/top%20sleep.png) 


### 2. Glance an Eye on your system

#### A. Keywords:

1. `glance`: Show system information including internal battery, bluetooth battery, disk capacity, etc.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/battery.png)

#### B. Change Display Order

1. Activate `Alfred Preferences` → `Advanced` → `Top Result Keyword Latching`

    ![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/Alfred_Preferences_Learning.png)

2. Hit `Enter` for the feedback item you wish to show up on the top.



## Installation

Two ways are provided:

1. You can download the [Top Processes.alfredworkflow](https://github.com/zhaocai/alfred2-top-workflow/raw/master/Top%20Processes.alfredworkflow) and import to Alfred 2. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install. Check `rake -T` for available tasks.
This method create a symlink to the alfred workflow directory: "~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows". This method is suitable for **developers**.


## Troubleshooting

### 1. Does not work in Mac OSX 10.9 (Maverick)

In OSX 10.9, the system ruby is upgraded to 2.0.0. You need to download the new version of this workflow which packs the ruby gems for 2.0.0 inside.

If the downloaded version does not work, try 

1.) open `Terminal.app`. If you use rvm or rbenv, switch to the system ruby.
2. run `cd "$HOME/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows/me.zhaowu.top" && rake bundle:update`


### 2. iotop causes mouse lagging

This issue is not caused by this workflow but by [DTrace][DTrace]. The related system log message is `IOHIDSystem cursor update overdue. Resending.`.
In my Macbook Pro, any [DTrace][DTrace] based program will introduce this issue including the mac built-in `/usr/bin/iotop`, and `/Applications/Xcode.app/Contents/Applications/Instruments.app` .

I upgrade to OS X 10.9 and this issue is resolved.

### 3. Encoding::CompatibilityError: incompatible character encodings: ASCII-8BIT and UTF-8

Add the following contents to `/etc/launchd.conf`. Restart is required.
```sh
setenv LANG en_US.UTF-8
setenv LC_ALL en_US.UTF-8
```


## Copyright

Copyright (c) 2013 Zhao Cai <caizhaoff@gmail.com>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.



[DTrace]: https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/dtrace.1.html

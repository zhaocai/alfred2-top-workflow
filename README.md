# Alfred 2 Top Process Workflow

The initial motive of this workflow is to avoid frequent visits to the Activity Monitor when the fan goes loud. Now it has been evloved with two major features:

- 1) List/Kill Top Processes by Memory/CPU/IO Usage

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/mixed%20top%20processes.png) 


- 2) (*working in progress*) Get a glance of system status including internal battery, fan speed, CPU/GPU Temperature, bluetooth battery, disk capacity, etc.

![](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/glance.png) 

## Usage

### 1. Top Processes

#### A. Keywords:

##### 1.) `top`: Show a mixed processes list based on top cpu/memory usage.

   - `top /m`, `top /mem`, `top /memory` to show processes ranked by memory usage
   - `top /c`, `top /cpu`, to show processes ranked by cpu usage
   - `top /i`, `top /io`, to show processes ranked by io usage

###### **Modifier Key**

   - `none`: The default action is to list files opened by process ID
   - `^` key to `kill`
   - `⌘` key to force kill (`kill -9`)
   - `alt` : nice cpu priority


##### 2.) `kill`: Filter process to kill.

###### **Modifier Key**

   - `none`: The default action is to kill by process ID
   - `⌘` key to force kill (`kill -9`)

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

2. Hit `↩` for the feedback item you wish to show up on the top.



## Installation

Two ways are provided:

1. You can download the [Top Processes.alfredworkflow](https://github.com/zhaocai/alfred2-top-workflow/raw/master/Top%20Processes.alfredworkflow) and import to Alfred 2. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install. Check `rake -T` for available tasks.
This method create a symlink to the alfred workflow directory: "~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows". This method is suitable for **developers**.


## Troubleshooting

### 1. Does not work in Mac OSX 10.9 (Maverick)

In OSX 10.9, the system ruby is upgraded to 2.0.0. You just need to download the new version of this workflow which packs the ruby gems for 2.0.0 inside. 

If you cloned the source code, you can simply run `rake bundle:update` in the terminal to update the bundle gems.


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

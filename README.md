# Alfred 2 Top Process Workflow

Alfred 2 Workflow to List/Kill Top Processes by Memory/Cpu Usage. The initial motive is to avoid frequent visits to the Activity Monitor when the fan goes loud.

![workflow](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/workflow.png)

## Usage

### A. Keywords:

1. `top`: Show a mixed processes list based on top cpu and memory usage
3. `memory top`: Processes list based on top memory usage
4. `cpu top`: Processes list based on top cpu usage
1. `kill`: Filter process to kill.
2. `lsof`: List files opened by process id


### B. Modifier Key

#### Keywords: `top`, `cpu top`, `memory top`

1. `none`: The default action is to list files opened by process ID
2. `^` key to `kill`
3. `⌘` key to force kill (`kill -9`)

#### Keywords: `kill`

1. `none`: The default action is to kill by process ID
3. `⌘` key to force kill (`kill -9`)

#### Keywords: `lsof`

1. `none`: The default action is to reveal file in Finder

### C. Query
1. now you can search for process state like idle, sleep, stopped, zombie, uninterruptible, runnable, etc.


## Screenshots

### 1. Mixed Processes List:

![mixed top processes](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/mixed%20top%20processes.png)

### 2. Filtered By Query:
![filtered by query](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/filtered%20by%20query.png)



## Installation

Two ways are provided:

1. You can download the [Top Processes.alfredworkflow](https://github.com/zhaocai/alfred2-top-workflow/raw/master/Top%20Processes.alfredworkflow) and import to Alfred 2. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install. Check `rake -T` for available tasks.
This method create a symlink to the alfred workflow directory: "~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows". This method is suitable for **developers**.


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

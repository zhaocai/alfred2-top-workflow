# Alfred 2 Top Process Workflow

Alfred 2 Workflow to List/Kill Top Processes by Memory/Cpu Usage. The initial motive is to avoid frequent visits to the Activity Monitor when the fan goes loud.

## Usage

3 Keywords are defined:

1. `top`: show a mixed processes list based on top cpu and memory usage
2. `memory top`
3. `cpu top`

## Screenshots

### mixed processes list:

![mixed top processes](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/mixed%20top%20processes.png)

### filtered by query:
![filtered by query](https://raw.github.com/zhaocai/alfred2-top-workflow/master/screenshots/filtered%20by%20query.png)



## Installation

Two ways are provided:

1. You can download the [Top Processes.alfredworkflow](https://github.com/zhaocai/alfred2-top-workflow/raw/master/Top%20Processes.alfredworkflow) and import to Alfred 2. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install.
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

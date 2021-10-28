# ASUS PRIME x570 PRO Version Checker
Script that checks if you have the latest PRIME x570-PRO bios, audio driver and chipset, made in ruby.
The script only checks the latest chipset and audio driver for Windows 10, not Windows 11.

Main script only works on Windows.
Linux version only checks the bios version.

# Gem dependencies
- bundler

# Linux dependencies
- dmidecode

# Usage
Start by installing all the dependencies. This is done by running the command 'bundler install'. (And when on linux, install the dependencies with your favorite package manager.)

On Windows, simply execute the provided bat file. You can also open command prompt and execute the command 'ruby check_version.rb' from there (which is what the bat file does).

On Linux, run the command 'ruby check_version_linux.rb' or './check_version_linux.rb'.

# Configuration (Windows only)
After running the script at least once, a configuration file will be made (config.json).
You can choose what you want to be checked by the script by editing the variables in this json file.
By default, every version will be checked.

It is also possible to not check for beta versions.

# ASUS PRIME x570 PRO Version Checker
Script that checks if you have the latest PRIME x570-PRO bios, audio driver and chipset, made in ruby.

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

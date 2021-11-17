# ASUS PRIME x570 PRO Version Checker
A script that checks if you have the latest PRIME x570-PRO bios, audio driver and chipset, made in ruby. There's a main script made for Windows 10, a script for Windows 11 and a script for Linux. The only difference (currently) between the windows 10 and 11 versions is the chipset driver check. The linux version only checks the bios version.

# Gem dependencies
- bundler

# Linux dependencies
- dmidecode

# Usage
Start by installing all the dependencies. First install the bundler gem with the command `gem install bundler`. After this, run the command `bundler install` in the cloned folder to install all the gems required for this script (and when on linux, also install the linux dependencies with your favorite package manager).

On Windows, simply execute one of the provided bat files. You can also open command prompt and execute the command `ruby check_version.rb` or `ruby check_version_win11.rb` (which is what the bat files do).

On Linux, run the command `ruby check_version_linux.rb` or `./check_version_linux.rb`.

# Configuration (Windows only)
After running the script at least once, a configuration file will be made (config.json). You can choose what you want to be checked by the script by editing the variables in this json file. It is also possible to ignore beta versions. By default, the script will check everything and will also notice you of any beta versions.

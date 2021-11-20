#!/usr/bin/ruby

require 'httparty'
require 'launchy'

# All calls to ASUS' API parsed to json (just one because linux only support bios check)
BIOSJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl').body)

# Returns the installed version
def get_installed_version(to_check)
	installed = %x(sudo dmidecode -s bios-version 2>&1)

    return installed.strip if installed =~ /\d/

    # Raise error if installed somehow doesn't contain a number
    puts "Installed #{to_check} version not found, skipping...\n\n"
    return -1
end

# Returns the newest version from ASUS' website
def get_newest_version(to_check)
	begin
		newest = BIOSJSON['Result']['Obj'][0]['Files'][0]['Version']
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return -1
	end
    return newest if newest =~ /\d/

    puts "Newest #{to_check} version not found, skipping...\n\n"
    return -1
end

# Returns whether newest version is a release and not a beta
def is_release?(to_check)
    is_release = BIOSJSON['Result']['Obj'][0]['Files'][0]['is_release']

    return true if is_release == '1'
end

# Returns the download link of the newest version
def get_download_link(item)
	download_link = BIOSJSON['Result']['Obj'][0]['Files'][0]['DownloadUrl']['Global']
	
	return download_link
end

# Asks user if it wants to download updates. If yes, opens browser to all outdated versions
def download_updates
	puts 'Would you like to download the updates? This will open your default browser. (y/n)'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        UPDATE_AVAILABLE.each { |key, value|
			link = get_download_link(key.to_s)
			Launchy.open(link) if value == true && link != ''
		}
    end
end

# Print info to tell user whether a new version is available. 
def check_for_updates(to_check)
    puts "\t- #{to_check.upcase} -"

    installed = get_installed_version(to_check)
    newest = get_newest_version(to_check)
    # Return if version couldn't be found
    return if installed == -1 or newest == -1
    
    if Gem::Version.new(installed) < Gem::Version.new(newest)
        # Set hash to true for later use
		UPDATE_AVAILABLE[to_check.to_sym] = true
        puts "There is a newer #{to_check} available!"
        puts "Installed version: #{installed}"
        puts "Newest version: #{newest}"
        puts "\n"
        puts "Warning! This is a beta version." unless is_release?(to_check)
		puts "\n"
    else
        puts "You have the latest #{to_check}."
        puts "Installed version: #{installed}"
		puts "\n"
    end
end

# Hash for possible future version checks on linux, unlikely tho
UPDATE_AVAILABLE = {bios: false}

# Check for updates 
check_for_updates('bios')

# Download updates if available
if UPDATE_AVAILABLE.has_value?(true)
    download_updates
end

#!/usr/bin/ruby

require 'httparty'
require 'launchy'

BIOSLINK = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl'

def get_installed_version(to_check)
	installed = %x(sudo dmidecode -s bios-version 2>&1)

    return installed.strip if installed =~ /\d/

    puts "Installed #{to_check} version not found, skipping...\n\n"
    return -1
end

def get_newest_version(to_check)
	begin
		newest = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['Version']
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return -1
	end
    return newest if newest =~ /\d/

    puts "Newest #{to_check} version not found, skipping...\n\n"
    return -1
end

def is_release?(to_check)
    is_release = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['is_release']

    return true if is_release == '1'
end

def open_browser
    puts 'Would you like to open your webbrowser to the update page? (Y/n)'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        Launchy.open("https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/")
    end
end

def check_for_updates(to_check)
    puts "\t- #{to_check.upcase} -"

    installed = get_installed_version(to_check)
    newest = get_newest_version(to_check)
    return if installed == -1 or newest == -1
    
    if installed.tr('.', '') < newest.tr('.', '')
        puts "There is a newer #{to_check} available!"
        puts "Installed version: #{installed}"
        puts "Newest version: #{newest}"
        puts "\n"
        puts "Warning! This is a beta version." unless is_release?(to_check)
		puts "\n"
        return true
    else
        puts "You have the latest #{to_check}."
        puts "Installed version: #{installed}"
		puts "\n"
    end
end

bios = check_for_updates('bios')

if bios
    open_browser
end

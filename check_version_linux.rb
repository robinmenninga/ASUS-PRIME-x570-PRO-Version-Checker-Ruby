#!/usr/bin/ruby

require 'httparty'
require 'launchy'

BIOSLINK = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl'

def getCurrentVersion(toCheck)
	current = %x(sudo dmidecode -s bios-version 2>&1)

    return current if current =~ /\d/

    puts "Current #{toCheck} version not found, skipping...\n\n"
    return -1
end

def getNewestVersion(toCheck)
	
	begin
		newest = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['Version']
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return -1
	end
    return newest if newest =~ /\d/

    puts "Newest #{toCheck} version not found, skipping...\n\n"
    return -1
end

def isRelease(toCheck)
    is_release = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['IsRelease']

    return true if is_release == '1'
end

def isCheckable(toCheck)
    checks = ['bios']
    checkable = checks.include? toCheck
    puts 'Wrong parameter' unless checkable
    return checkable
end

def openBrowser
    puts 'Would you like to open your webbrowser to the update page? (Y/n)'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        Launchy.open("https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/")
    end
end

def checkForUpdates(toCheck)
    return unless isCheckable(toCheck)

    puts "\t- #{toCheck.upcase} -"

    current = getCurrentVersion(toCheck)
    newest = getNewestVersion(toCheck)
    return if current == -1 or newest == -1
    
    if current < newest
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}"
        puts "Newest #{toCheck} version: #{newest}"
        puts "\n"
        puts "Warning! This is a beta version." unless isRelease(toCheck)
		puts "\n"
        return true
    else
        puts "You have the latest #{toCheck}.\n\n"
    end
end

bios = checkForUpdates('bios')

if bios
    openBrowser
end

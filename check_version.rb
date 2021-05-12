require 'httparty'
require 'launchy'

def getCurrentVersion(toCheck)
    case toCheck
    when 'bios'
        current = %x(wmic bios get name 2>&1).tr("Name \n", '')
    when 'chipset'
        current = %x(wmic datafile where 'name="C:\\\\AMD\\\\Chipset_Driver_Installer\\\\AMD_Chipset_Software.exe"' get version 2>&1).tr("Version \n", '')
    when 'audiodriver'
        current = %x(powershell.exe -EncodedCommand "RwBlAHQALQBXAG0AaQBPAGIAagBlAGMAdAAgAFcAaQBuADMAMgBfAFAAbgBQAFMAaQBnAG4AZQBkAEQAcgBpAHYAZQByACAALQBGAGkAbAB0AGUAcgAgACIARABlAHYAaQBjAGUATgBhAG0AZQAgAD0AIAAnAFIAZQBhAGwAdABlAGsAIABIAGkAZwBoACAARABlAGYAaQBuAGkAdABpAG8AbgAgAEEAdQBkAGkAbwAnACIAIAB8ACAAcwBlAGwAZQBjAHQAIABkAHIAaQB2AGUAcgB2AGUAcgBzAGkAbwBuACAAfAAgAEYAbwByAG0AYQB0AC0AVABhAGIAbABlACAALQBIAGkAZABlAFQAYQBiAGwAZQBIAGUAYQBkAGUAcgBzAA==").tr("\n", '')
    end
    if current =~ /\d/
        return current
    end
    puts "Current #{toCheck} version not found, skipping...\n\n"
    return -1
end

def getNewestVersion(toCheck)
    link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=45'
    case toCheck
    when 'bios'
        link = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl'
        newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][0]['Files'][0]['Version']
    when 'chipset'
        newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][1]['Files'][0]['Version']
    when 'audiodriver'
        newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][2]['Files'][0]['Version']
    end

    return newest if newest =~ /\d/

    puts "Newest #{toCheck} version not found, skipping...\n\n"
    return -1
end

def isRelease(toCheck)
    case toCheck
    when 'bios'
        is_release = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][0]['Files'][0]['IsRelease']
    when 'chipset'
        is_release = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][1]['Files'][0]['IsRelease']
    when 'audiodriver'
        is_release = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][2]['Files'][0]['IsRelease']
    end

    return true if is_release == '1'
end

def isCheckable(toCheck)
    checks = ['bios', 'chipset', 'audiodriver']
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
    
    if current.tr('.', '') < newest.tr('.', '') 
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}."
        puts "Newest #{toCheck} version: #{newest}."
        puts "\n"
        puts "Warning! This is a beta version." unless isRelease
		puts "\n"
        return true
    else
        puts "You have the latest #{toCheck}.\n\n"
    end
end

bios = checkForUpdates('bios')
chipset = checkForUpdates('chipset')
audiodriver = checkForUpdates('audiodriver')

if bios or chipset or audiodriver
    openBrowser
end
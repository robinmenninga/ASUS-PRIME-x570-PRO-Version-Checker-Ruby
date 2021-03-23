require 'httparty'
require 'launchy'


def checkForUpdates(toCheck)
    case toCheck
    when 'chipset'
        option = 2
        if File.exist?('C:/AMD/Chipset_Driver_Installer/AMD_Chipset_Software.exe') then
            current = %x(wmic datafile where 'name="C:\\\\AMD\\\\Chipset_Driver_Installer\\\\AMD_Chipset_Software.exe"' get version).tr("Version \n", '')
        else
            puts 'Chipset software exe file not found, skipping chipset version check.'
            return
        end
    when 'bios'
        option = 0
        current = %x(wmic bios get name).tr("Name \n", '')
		unless current =~ /\d/ 
			puts 'Cannot find version number, either the website is down or something is wrong with the script.'
			return
		end
    else
        puts 'Wrong parameter, choose between \'bios\' and \'chipset\'.'
    end
    
    link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu=&osid=45'
    newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['Version']
    if current.tr('.', '') < newest.tr('.', '') 
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}."
        puts "Newest #{toCheck} version: #{newest}."
        true
    else
        puts "You have the latest #{toCheck}."
    end
end

bios = checkForUpdates('bios')
chipset = checkForUpdates('chipset')

if bios or chipset
    puts 'Would you like to open your webbrowser to the update page? (y/n)'
    if gets.chomp == 'y' 
        Launchy.open("https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/")
    end
end
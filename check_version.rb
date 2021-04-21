require 'httparty'
require 'launchy'


def checkForUpdates(toCheck)
    case toCheck
    when 'chipset'
        option = 1
        link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu=&osid=45'
        if File.exist?('C:/AMD/Chipset_Driver_Installer/AMD_Chipset_Software.exe') then
            current = %x(wmic datafile where 'name="C:\\\\AMD\\\\Chipset_Driver_Installer\\\\AMD_Chipset_Software.exe"' get version).tr("Version \n", '')
        else
            puts 'Chipset software exe file not found, skipping chipset version check.'
            return
        end
    when 'bios'
        option = 0
        link = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu='
        current = %x(wmic bios get name).tr("Name \n", '')
		unless current =~ /\d/ 
			puts 'Cannot find current version.'
			return
		end
    else
        puts 'Wrong parameter, choose between \'bios\' and \'chipset\'.'
    end
    
    newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['Version']
    unless newest =~ /\d/
        puts "Cannot find newest #{toCheck} version."
        return
    end
    is_release = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['IsRelease']
    puts "\t- #{toCheck.upcase} -"
    if current.tr('.', '') < newest.tr('.', '') 
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}."
        puts "Newest #{toCheck} version: #{newest}."
        puts "\n"
        if (is_release == '0')
            puts "Warning! This is a beta version."
        end
		puts "\n"
        true
    else
        puts "You have the latest #{toCheck}."
		puts "\n\n"
    end
end

bios = checkForUpdates('bios')
chipset = checkForUpdates('chipset')

if bios or chipset
    puts 'Would you like to open your webbrowser to the update page? (Y/n)'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        Launchy.open("https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/")
    end
end
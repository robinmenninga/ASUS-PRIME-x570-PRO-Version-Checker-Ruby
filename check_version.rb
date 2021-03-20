require 'httparty'
require 'json'
require 'launchy'


def checkForUpdates(toCheck)
    case toCheck
    when 'chipset'
        option = 2
        current = %x(wmic datafile where 'name="C:\\\\AMD\\\\Chipset_Driver_Installer\\\\AMD_Chipset_Software.exe"' get version).tr("Version \n", '')
    when 'bios'
        option = 0
        current = %x(wmic bios get name).tr("Name \n", '')
    else
        puts 'Wrong parameter, choose between \'bios\' and \'chipset\''
    end
    
    link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu=&osid=45'
    newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['Version']
    if current.tr('.', '') < newest.tr('.', '') then
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}"
        puts "Newest #{toCheck} version: #{newest}"
        true
    else
        puts "You have the latest #{toCheck}."
    end
end

if checkForUpdates('bios') or checkForUpdates('chipset') then
    puts 'Would you like to open your webbrowser to the update page? (y/n)'
    if gets.chomp == 'y' then
        Launchy.open("https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/")
    end
end
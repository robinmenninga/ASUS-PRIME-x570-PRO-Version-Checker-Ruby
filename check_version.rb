require 'httparty'
require 'json'


def checkForUpdates(toCheck)
    case toCheck
    when 'chipset'
        option = 2
    when 'bios'
        option = 0
        current = %x(wmic bios get name).tr("Name \n", '')
    else
        puts 'Wrong parameter, choose between \'bios\' and \'chipset\''
    end

    json = JSON.parse(File.read('version.json'))
    if toCheck == 'chipset' then
        current = json[toCheck]
    end
    link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu=&osid=45'
    newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['Version']
    if current.tr('.', '') < newest.tr('.', '') then
        puts "There is a newer #{toCheck} available!"
        puts "Current #{toCheck} version: #{current}"
        puts "Newest #{toCheck} version: #{newest}"
        if toCheck == 'chipset' then
            puts "Would you like to update the version file to the newest #{toCheck}? You can always do this manually later. (y/n)"
            if gets.chomp == 'y' then
                json[toCheck] = newest
                File.open('version.json', 'w') { |file| file.write(JSON.pretty_generate(json)) }
            end
        end
    else puts "You have the latest #{toCheck}." end
end

if File.exist?('version.json') then
    checkForUpdates('bios')
    checkForUpdates('chipset')
else
    File.open('version.json', 'w') { |file| file.write(JSON.pretty_generate({:bios => "0", :chipset => "0"})) }
    puts "Please enter your current versions in the newly made file \'version.json\'"
end
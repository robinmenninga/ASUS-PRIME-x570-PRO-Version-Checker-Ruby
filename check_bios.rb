require 'httparty'
require 'json'


def checkForUpdates(toCheck)
    if toCheck == 'chipset' then
        textfile = 'chipsetversion.txt'
        option = 2
    elsif toCheck == 'bios' then
        textfile = 'biosversion.txt'
        option = 0
    else
        puts 'Wrong parameter, choose between \'bios\' and \'chipset\''
    end
    
    if File.exist?(textfile) then
        current = File.open(textfile).read
        link = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&cpu=&osid=45'
        newest = JSON.parse(HTTParty.get(link).body)['Result']['Obj'][option]['Files'][0]['Version']
        if current.tr('.', '') < newest.tr('.', '') then
            puts "There is a newer #{toCheck} available!"
            puts "Current #{toCheck} version: #{current}"
            puts "Newest #{toCheck} version: #{newest}"
            puts "Would you like to update the version file to the newest #{toCheck}? You can always do this manually later. (y/n)"
            if gets.chomp == 'y' then File.open(textfile, 'w') { |file| file.write(newest) } end
        else puts "You have the latest #{toCheck}." end
    else 
        File.open(textfile, 'w') { |file| file.write('0') }
        puts "Please enter your current #{toCheck} version in the newly made file \'#{textfile}\'"
    end
end

checkForUpdates('bios')
checkForUpdates('chipset')
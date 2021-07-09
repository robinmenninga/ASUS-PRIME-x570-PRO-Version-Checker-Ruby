require 'httparty'
require 'launchy'

DRIVERLINK = 'https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=45'
BIOSLINK = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl'

def get_installed_version(to_check)
    case to_check
    when 'bios'
        installed = %x(wmic bios get name 2>&1).tr("Name \n", '')
    when 'chipset'
        installed = %x(wmic datafile where 'name="C:\\\\AMD\\\\Chipset_Driver_Installer\\\\AMD_Chipset_Software.exe"' get version 2>&1).tr("Version \n", '')
    when 'audiodriver'
        installed = %x(powershell.exe -EncodedCommand "RwBlAHQALQBXAG0AaQBPAGIAagBlAGMAdAAgAFcAaQBuADMAMgBfAFAAbgBQAFMAaQBnAG4AZQBkAEQAcgBpAHYAZQByACAALQBGAGkAbAB0AGUAcgAgACIARABlAHYAaQBjAGUATgBhAG0AZQAgAD0AIAAnAFIAZQBhAGwAdABlAGsAIABIAGkAZwBoACAARABlAGYAaQBuAGkAdABpAG8AbgAgAEEAdQBkAGkAbwAnACIAIAB8ACAAcwBlAGwAZQBjAHQAIABkAHIAaQB2AGUAcgB2AGUAcgBzAGkAbwBuACAAfAAgAEYAbwByAG0AYQB0AC0AVABhAGIAbABlACAALQBIAGkAZABlAFQAYQBiAGwAZQBIAGUAYQBkAGUAcgBzAA==").tr("\n", '')
    end
    
    return installed.strip if installed =~ /\d/

    puts "Installed #{to_check} version not found, skipping...\n\n"
    return -1
end

def get_newest_version(to_check)
	begin
		case to_check
		when 'bios'
			newest = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['Version']
		when 'chipset'
			newest = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][1]['Files'][0]['Version']
		when 'audiodriver'
			newest = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][2]['Files'][0]['Version']
		end
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return -1
	end
	
    return newest if newest =~ /\d/

    puts "Newest #{to_check} version not found, skipping...\n\n"
    return -1
end

def is_release?(to_check)
    case to_check
    when 'bios'
        is_release = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['IsRelease']
    when 'chipset'
        is_release = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][1]['Files'][0]['IsRelease']
    when 'audiodriver'
        is_release = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][2]['Files'][0]['IsRelease']
    end

    return true if is_release == '1'
end

def check?(to_check)
	unless File.exists?('config.json')
		puts "No config file found, creating..."
		puts "\n"
		json = {
			'checks' => {
				'bios' => true,
				'chipset' => true,
				'audiodriver' => true
			}
		}
		File.open('config.json', 'w') {|f| f.write(JSON.pretty_generate(json)) }
	end
	
	JSON.parse(File.read('config.json'))['checks'][to_check]
end

def open_browser
    puts 'Would you like to open your webbrowser to the update page? (Y/n)'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        Launchy.open('https://www.asus.com/us/Motherboards-Components/Motherboards/All-series/PRIME-X570-PRO/HelpDesk_Download/')
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
        puts 'Warning! This is a beta version.' unless is_release?(to_check)
		puts "\n"
        return true
    else
        puts "You have the latest #{to_check}."
        puts "Installed version: #{installed}"
		puts "\n"
    end
end

check?('bios') ? bios = check_for_updates('bios') : bios = false
check?('chipset') ? chipset = check_for_updates('chipset') : chipset = false
check?('audiodriver') ? audiodriver = check_for_updates('audiodriver') : audiodriver = false

if bios or chipset or audiodriver
    open_browser
end
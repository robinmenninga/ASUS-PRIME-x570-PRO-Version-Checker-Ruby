require 'httparty'
require 'launchy'

BIOSJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl').body)
DRIVERJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=45').body)

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
			newest = BIOSJSON['Result']['Obj'][0]['Files'][0]['Version']
		when 'chipset'
			newest = DRIVERJSON['Result']['Obj'][1]['Files'][0]['Version']
		when 'audiodriver'
			newest = DRIVERJSON['Result']['Obj'][2]['Files'][0]['Version']
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
        is_release = BIOSJSON['Result']['Obj'][0]['Files'][0]['IsRelease']
    when 'chipset'
        is_release = DRIVERJSON['Result']['Obj'][1]['Files'][0]['IsRelease']
    when 'audiodriver'
        is_release = DRIVERJSON['Result']['Obj'][2]['Files'][0]['IsRelease']
    end

    return true if is_release == '1'
end

def create_config
	puts "No config file found, creating..."
	puts "\n"
	json = {
		'checks' => {
			'bios' => true,
			'chipset' => true,
			'audiodriver' => true
		}, 'prefs' => {
			'check_beta' => true
		}
	}
	File.open('config.json', 'w') {|f| f.write(JSON.pretty_generate(json)) }
end

def check?(to_check)
	unless File.exists?('config.json')
		create_config
	end
	
	JSON.parse(File.read('config.json'))['checks'][to_check]
end

def check_beta?
	unless File.exists?('config.json')
		create_config
	end
	
	JSON.parse(File.read('config.json'))['prefs']['check_beta']	
end

def get_download_link(item)
	begin
		case item
		when 'bios'
			download_link = BIOSJSON['Result']['Obj'][0]['Files'][0]['DownloadUrl']['Global']
		when 'chipset'
			download_link = DRIVERJSON['Result']['Obj'][1]['Files'][0]['DownloadUrl']['Global']
		when 'audiodriver'
			download_link = DRIVERJSON['Result']['Obj'][2]['Files'][0]['DownloadUrl']['Global']
		end
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return
	end
	
	return download_link
end

def download_updates
	puts 'Would you like to download the updates? This will open your default browser.'
	answer = gets.chomp
    if answer == 'y' or answer == ''
        UPDATE_AVAILABLE.each { |key, value|
			link = get_download_link(key.to_s)
			Launchy.open(link) if value == true && link != ''
		}
    end
end

def check_for_updates(to_check)
    puts "\t- #{to_check.upcase} -"

    installed = get_installed_version(to_check)
    newest = get_newest_version(to_check)
    return if installed == -1 or newest == -1
    is_release = is_release?(to_check)
	betastop = !check_beta? && !is_release
	
    if Gem::Version.new(installed) < Gem::Version.new(newest) && !betastop
		UPDATE_AVAILABLE[to_check.to_sym] = true
        puts "There is a newer #{to_check} available!"
        puts "Installed version: #{installed}"
        puts "Newest version: #{newest}"
        puts "\n"
        puts 'Warning! This is a beta version.' unless is_release
		puts "\n"
    else
        puts "You have the latest #{to_check}."
        puts "Installed version: #{installed}"
		puts "\n"
    end
end

UPDATE_AVAILABLE = {bios: false, chipset: false, audiodriver: false}

check_for_updates('bios') if check?('bios')
check_for_updates('chipset') if check?('chipset')
check_for_updates('audiodriver') if check?('audiodriver')

if UPDATE_AVAILABLE.has_value?(true)
    download_updates
end
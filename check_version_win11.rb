require 'httparty'
require 'launchy'

BIOSJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl').body)
WIN11DRIVERJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=52').body)
DRIVERJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=45').body)

def get_installed_version(to_check)
	begin
		case to_check
		when 'bios'
			installed = %x(wmic bios get name 2>&1).tr("Name \n", '')
		when 'chipset'
			installed = %x(wmic datafile where 'name="C:\\\\Program Files (x86)\\\\AMD\\\\Chipset_Software\\\\AMD_Chipset_Drivers.exe"' get version 2>&1).tr("Version \n", '')
		when 'audiodriver'
			installed = %x(powershell.exe -EncodedCommand "RwBlAHQALQBXAG0AaQBPAGIAagBlAGMAdAAgAFcAaQBuADMAMgBfAFAAbgBQAFMAaQBnAG4AZQBkAEQAcgBpAHYAZQByACAALQBGAGkAbAB0AGUAcgAgACIARABlAHYAaQBjAGUATgBhAG0AZQAgAD0AIAAnAFIAZQBhAGwAdABlAGsAIABIAGkAZwBoACAARABlAGYAaQBuAGkAdABpAG8AbgAgAEEAdQBkAGkAbwAnACIAIAB8ACAAcwBlAGwAZQBjAHQAIABkAHIAaQB2AGUAcgB2AGUAcgBzAGkAbwBuACAAfAAgAEYAbwByAG0AYQB0AC0AVABhAGIAbABlACAALQBIAGkAZABlAFQAYQBiAGwAZQBIAGUAYQBkAGUAcgBzAA==").tr("\n", '')
		end
		
		raise 'Returned variable does not contain a number.' unless installed =~ /\d/ 
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get installed #{to_check} version, skipping...\n\n"
		return -1
	end
	
	return installed.strip
end

def get_newest_version(to_check)
	begin
		case to_check
		when 'bios'
			newest = BIOSJSON['Result']['Obj'][0]['Files'][0]['Version']
		when 'chipset'
			newest = WIN11DRIVERJSON['Result']['Obj'][0]['Files'][0]['Version']
		when 'audiodriver'
			newest = DRIVERJSON['Result']['Obj'][2]['Files'][0]['Version']
		end

		raise 'Returned variable does not contain a number.' unless newest =~ /\d/ 
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get latest #{to_check} version, skipping...\n\n"
		return -1
	end
	
	return newest
end

def is_release?(to_check)
	begin
		case to_check
		when 'bios'
			is_release = BIOSJSON['Result']['Obj'][0]['Files'][0]['IsRelease']
		when 'chipset'
			is_release = DRIVERJSON['Result']['Obj'][1]['Files'][0]['IsRelease']
		when 'audiodriver'
			is_release = DRIVERJSON['Result']['Obj'][2]['Files'][0]['IsRelease']
		end
		

		raise 'Returned variable does not contain a number.' unless is_release =~ /\d/
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to check if #{to_check} is release or not.\n\n"
		return true
	end
	
	return true if is_release == '1'
end

def create_config
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
	JSON.parse(File.read('config.json'))['checks'][to_check]
end

def check_beta?
	JSON.parse(File.read('config.json'))['prefs']['check_beta']
end

def config_exists?
	File.exists?('config.json')
end

def check_corrupt
	begin
		JSON.parse(File.read('config.json'))
	rescue JSON::ParserError => e
		puts "Config file is corrupt. Renaming to 'config_corrupt.json'. Creating a new config file."
		File.rename("config.json", "config_corrupt.json")
		create_config
	end
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

		raise 'Download link does not contain link' unless download_link =~ /http/i
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get download link of #{to_check}.\n\n"
		return ''
	end
	
	return download_link
end

def download_updates
	puts 'Would you like to download the updates? This will open your default browser. (y/n)'
	answer = gets.chomp
	if answer == 'y' or answer == ''
		UPDATE_AVAILABLE.each { |key, value|
			if value == true
				link = get_download_link(key.to_s)
				Launchy.open(link) if link != ''
			end
		}
	end
end

def show_update_description
	notes = ""
	name = ""
	UPDATE_AVAILABLE.each { |key, value|
		if value == true
			case key.to_s
			when 'bios'
				name = 'Bios'
				notes = BIOSJSON['Result']['Obj'][0]['Files'][0]['Description']
			when 'chipset'
				name = 'Chipset'
				notes = DRIVERJSON['Result']['Obj'][1]['Files'][0]['Description']
			when 'audiodriver'
				name = 'Audiodriver'
				notes = DRIVERJSON['Result']['Obj'][2]['Files'][0]['Description']
			end
		end
	}
	if notes == ""
		puts "#{name} update description not available."
		puts "\n"
		return
	end
	puts "#{name} update description:"
	puts "\n"
	puts '----------------------------------------'
	puts notes
	puts '----------------------------------------'
	puts "\n"
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
		puts "Warning! This is a beta version.\n\n" unless is_release
	else
		puts "You have the latest #{to_check}."
		puts "Installed version: #{installed}"
		puts "\n"
	end
end

UPDATE_AVAILABLE = {bios: false, chipset: false, audiodriver: false}

unless config_exists?
	puts "No config file found, creating..."
	create_config
end

check_corrupt

check_for_updates('bios') if check?('bios')
check_for_updates('chipset') if check?('chipset')
check_for_updates('audiodriver') if check?('audiodriver')

if UPDATE_AVAILABLE.has_value?(true)
	show_update_description
	download_updates
end

require 'httparty'
require 'launchy'

# All calls to ASUS' API parsed to json
BIOSJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl').body)
DRIVERJSON = JSON.parse(HTTParty.get('https://www.asus.com/support/api/product.asmx/GetPDDrivers?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl&osid=45').body)

# Returns the installed version
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
		
		# Raise error if installed somehow doesn't contain a number
		raise 'Returned variable does not contain a number.' unless installed =~ /\d/ 
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get installed #{to_check} version, skipping...\n\n"
		return -1
	end
	
	return installed.strip
end

# Returns the newest version from ASUS' website
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

		# Raise error if version from website somehow doesn't contain a number
		raise 'Returned variable does not contain a number.' unless newest =~ /\d/ 
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get latest #{to_check} version, skipping...\n\n"
		return -1
	end
	
	return newest
end

# Returns whether newest version is a release and not a beta
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
		
		# Raise error if version from website somehow doesn't contain a number (should be either 0 or 1)
		raise 'Returned variable does not contain a number.' unless is_release =~ /\d/
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to check if #{to_check} is release or not.\n\n"
		# If it can't find out, say it's a release
		return true
	end
	
	return true if is_release == '1'
end

# Create a config file
def create_config
	puts "\n"
	# Default config file structure
	json = {
		'checks' => {
			'bios' => true,
			'chipset' => true,
			'audiodriver' => true
		}, 'prefs' => {
			'check_beta' => true
		}
	}
	# Write default structure to file called config.json and make it pretty
	File.open('config.json', 'w') {|f| f.write(JSON.pretty_generate(json)) }
end

# Check config file if version should be checked
def check?(to_check)
	JSON.parse(File.read('config.json'))['checks'][to_check]
end

# Check config file if beta versions should be checked
def check_beta?
	JSON.parse(File.read('config.json'))['prefs']['check_beta']
end

# Check if config file exists
def config_exists?
	File.exists?('config.json')
end

# Check if config file is valid by trying to parse it
def check_corrupt
	begin
		JSON.parse(File.read('config.json'))
	rescue JSON::ParserError => e
		puts "Config file is corrupt. Renaming to 'config_corrupt.json'. Creating a new config file."
		File.rename("config.json", "config_corrupt.json")
		create_config
	end
end

# Returns the download link of the newest version
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

		# Raise error if variable doesn't contain link
		raise 'Download link does not contain link' unless download_link =~ /http/i
	rescue => err
		puts "An error occured: (#{err.message})"
		puts "Unable to get download link of #{to_check}.\n\n"
		# Returns empty string if download link cannot be found
		return ''
	end
	
	return download_link
end

# Asks user if it wants to download updates. If yes, opens browser to all outdated versions
def download_updates
	puts 'Would you like to download the updates? This will open your default browser. (y/n)'
	answer = gets.chomp
	if answer == 'y' or answer == ''
		# Go through each available update and open the link in browser
		UPDATE_AVAILABLE.each { |key, value|
			if value == true
				link = get_download_link(key.to_s)
				Launchy.open(link) if link != ''
			end
		}
	end
end

# Prints update description 
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

# Print info to tell user whether a new version is available. 
def check_for_updates(to_check)
	puts "\t- #{to_check.upcase} -"

	installed = get_installed_version(to_check)
	newest = get_newest_version(to_check)
	# Return if version couldn't be found
	return if installed == -1 or newest == -1
	is_release = is_release?(to_check)
	# Boolean that's true if it shouldn't notify for beta versions
	betastop = !check_beta? && !is_release

	if Gem::Version.new(installed) < Gem::Version.new(newest) && !betastop
		# Set hash to true for later use
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

# Hash containing whether updates are available. For use by other functions after all checks are done
UPDATE_AVAILABLE = {bios: false, chipset: false, audiodriver: false}

# Create config if it doesn't exist
unless config_exists?
	puts "No config file found, creating..."
	create_config
end

# Check if json is corrupt
check_corrupt

# Check for updates if set by config
check_for_updates('bios') if check?('bios')
check_for_updates('chipset') if check?('chipset')
check_for_updates('audiodriver') if check?('audiodriver')

# If any update is available, show their descriptions and ask user if it wants to download the updates
if UPDATE_AVAILABLE.has_value?(true)
	show_update_description
	download_updates
end

#!/usr/bin/ruby

require 'httparty'
require 'launchy'

BIOSLINK = 'https://www.asus.com/support/api/product.asmx/GetPDBIOS?website=us&model=PRIME-X570-PRO&pdhashedid=aDvY2vRFhs99nFdl'

def get_installed_version(to_check)
	installed = %x(sudo dmidecode -s bios-version 2>&1)

    return installed.strip if installed =~ /\d/

    puts "Installed #{to_check} version not found, skipping...\n\n"
    return -1
end

def get_newest_version(to_check)
	begin
		newest = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['Version']
	rescue => err
		puts "An error occured: (#{err.class}: #{err.message})"
		return -1
	end
    return newest if newest =~ /\d/

    puts "Newest #{to_check} version not found, skipping...\n\n"
    return -1
end

def is_release?(to_check)
    is_release = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['is_release']

    return true if is_release == '1'
end

def get_download_link(item)
	begin
		case item
		when 'bios'
			download_link = JSON.parse(HTTParty.get(BIOSLINK).body)['Result']['Obj'][0]['Files'][0]['DownloadUrl']['Global']
		when 'chipset'
			download_link = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][1]['Files'][0]['DownloadUrl']['Global']
		when 'audiodriver'
			download_link = JSON.parse(HTTParty.get(DRIVERLINK).body)['Result']['Obj'][2]['Files'][0]['DownloadUrl']['Global']
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
    
    if Gem::Version.new(installed) < Gem::Version.new(newest)
		UPDATE_AVAILABLE[to_check.to_sym] = true
        puts "There is a newer #{to_check} available!"
        puts "Installed version: #{installed}"
        puts "Newest version: #{newest}"
        puts "\n"
        puts "Warning! This is a beta version." unless is_release?(to_check)
		puts "\n"
    else
        puts "You have the latest #{to_check}."
        puts "Installed version: #{installed}"
		puts "\n"
    end
end

# hash for possible future version checks on linux, unlikely tho
UPDATE_AVAILABLE = {bios: false}

check_for_updates('bios')

if UPDATE_AVAILABLE.has_value?(true)
    download_updates
end

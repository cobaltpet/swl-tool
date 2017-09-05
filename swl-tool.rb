#!/usr/local/bin/ruby -w

# swl-tool: a script to fetch, archive, and search shortwave broadcasting schedules
# EiBi shortwave schedules kindly created by Eike Bierwirth : http://www.eibispace.de
# This script created by Eric Weatherall : cobaltpet gmail com
# Developed in a secret location in Northern California
# Env: ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin16]

require 'net/http'
require 'uri'

require_relative '_ScheduleParser'
require_relative '_EiBiScheduleParser'

# TODO: incorporate Aoki http://www.geocities.jp/binewsjp/
# TODO: incorporate hfcc.org?
# TODO: add ionosphere day/night filters -id -in to prefer compatible frequencies -- determine the cutoff? 11MHz?
# TODO: add local sunrise-sunset lookups to automatically assist with ionosphere advice
# TODO: add a time station filter: why doesn't "-l TS" work? (must match full string; can't use -TS as a broadcaster filter due to the hyphen)
# TODO: update BroadcastEntry with station type and program contents flags?
# TODO: day of week filtering when using -tn option
# TODO: allow customization of file path for those who already have an EiBi archive or wish to keep files in a particular location
# TODO: log region as NA:WNA (continent:locale)

=begin
swl-tool software license (The 3-Clause BSD License aka BSD-3-Clause)

Copyright (c) 2017 Eric Weatherall : cobaltpet gmail com : http://cobaltpet.blogspot.com/
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
=end

Author = "Eric Weatherall"
AuthorEmail = "cobaltpet gmail com"
AuthorBlog = "http://cobaltpet.blogspot.com/"
ScriptVersion = "2017-09-04 2005UTC"

### Options

$options = Hash::new

DebugOptionKey = "debugOpt"                           # boolean
DebugDebugOptionKey = "debugDebugOpt"                 # boolean
BroadcasterOptionKey = "broadcasterOpt"               # string
FrequencyOptionKey = "frequencyOpt"                   # integer
FrequencyToleranceOptionKey = "frequencyToleranceOpt" # integer
LanguageOptionKey = "languageOpt"                     # string
RegionOptionKey = "regionOpt"                         # string
MeterBandOptionKey = "meterOpt"                       # integer
MeterBandToleranceOptionKey = "meterToleranceOpt"     # integer
ScheduleOptionKey = "scheduleOpt"                     # string
HourOptionKey = "hourOpt"                             # integer
MinuteOptionKey = "minuteOpt"                         # integer
InactiveDisplayOptionKey = "inactiveOpt"              # boolean

def setDefaultOptions
    # note that debug logging is not possible in this method
    # disable debug mode
    $options[DebugOptionKey] = false
    $options[DebugDebugOptionKey] = false
    # do not set a default broadcaster
    # do not set a default frequency or tolerance
    # do not set a default language
    # do not set a default meter band or tolerance
    # do not set a default region
    # do not set a default schedule code
    $options[InactiveDisplayOptionKey] = false

    # default behavior: display broadcasts around now (UTC) aka -tn
    # determine current UTC time
    utcHour = Time.now.utc.hour
    utcMinute = Time.now.utc.min
    $options[HourOptionKey] = utcHour
    $options[MinuteOptionKey] = utcMinute
end

# Ensure that the user has provided a valid parameter for command-line options requiring them
# The options array may not be empty and the next option [0] may not begin with a hyphen
def requireParameterForOption(opt, options)
    if 0 == options.count
        log(ErrorLabel, "Parameter for option #{opt} is missing!")
    else
        if options[0][0].eql?("-")
            log(ErrorLabel, "Parameter for option #{opt} may not begin with a hyphen.")
        end
    end
end

# Certain parameters do not make sense unless paired with another option
def requirePairedOptions(thisOption, thatOption)
    unless ARGV.include?(thatOption)
        log(ErrorLabel, "You must use #{thatOption} when using #{thisOption}")
    end
end

# Certain pairs of differing options may not be used together
def disallowOptionPairs(firstOption, secondOption)
    if ARGV.include?(firstOption) && ARGV.include?(secondOption)
        log(ErrorLabel, "The options #{firstOption} and #{secondOption} may not be used together")
    end
end

# Most options will not behave as expected if duplicated
def disallowOptionDuplication(option)
    count = 0
    for opt in ARGV
        count += 1 if option.eql?(opt)
    end
    log(ErrorLabel, "The option #{option} may only be used once") if count > 1
end

# Interpret the command-line options
def parseCommandLineOptions
    setDefaultOptions() # this must remain as the first line
    # debug is a special case so debug logs will start right away
    if ARGV.include?("-d") || ARGV.include?("-dd")
        $options[DebugOptionKey] = true
    end

    log(DebugLabel, "ARGV: #{ARGV}")
    if ARGV.include?("-h")
        showHelpAndExit()
    else
        showTerseCredits()
    end

    # treat ARGV as read-only; copy its contents to another array that we will modify
    removeTimeKeys = false
    options = Array::new(ARGV)
    while options.count > 0
        opt = options.shift
        log(DebugLabel, "opt: #{opt}")
        case opt
        when "-d"
            # debug already handled above
            {}
        when "-dd"
            $options[DebugDebugOptionKey] = true
            $options[DebugOptionKey] = true
        when "-b"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            broadcaster = options.shift
            $options[BroadcasterOptionKey] = broadcaster
        when "-bt"
            # this is described as a broadcaster option but we are searching for a specific language code
            # the options -b and -bt may be used together since they write into distinct option keys
            $options[LanguageOptionKey] = "-TS"
            removeTimeKeys = true
        when "-f"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            disallowOptionPairs("-f", "-m")
            frequency = options.shift.to_i
            $options[FrequencyOptionKey] = frequency
        when "-ft"
            requireParameterForOption(opt, options)
            requirePairedOptions(opt, "-f") # frequency tolerance makes no sense without -f
            fTolerance = options.shift.to_i
            $options[FrequencyToleranceOptionKey] = fTolerance
        when "-i"
            $options[InactiveDisplayOptionKey] = true
        when "-l"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            language = options.shift
            $options[LanguageOptionKey] = language
        when "-le"
            $options[LanguageOptionKey] = "E"
        when "-lk"
            $options[LanguageOptionKey] = "K"
        when "-ls"
            $options[LanguageOptionKey] = "S"
        when "-m"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            disallowOptionPairs("-f", "-m")
            mb = options.shift.to_i
            $options[MeterBandOptionKey] = mb
        when "-mt"
            requireParameterForOption(opt, options)
            requirePairedOptions(opt, "-m") # meter tolerance makes no sense without -m
            mTolerance = options.shift.to_i
            $options[MeterBandToleranceOptionKey] = mTolerance
        when "-r"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            region = options.shift
            $options[RegionOptionKey] = region
        when "-rna"
            $options[RegionOptionKey] = "NAm"
        when "-rsa"
            $options[RegionOptionKey] = "SAm"
        when "-reu"
            $options[RegionOptionKey] = "Eu"
        when "-raf"
            $options[RegionOptionKey] = "Af"
        when "-ras"
            $options[RegionOptionKey] = "As"
        when "-roc"
            $options[RegionOptionKey] = "Oc"
        when "-s"
            requireParameterForOption(opt, options)
            scheduleCode = options.shift
            if scheduleCode.length != 3
                log(ErrorLabel, "Schedule code parameter must be 3 characters e.g. a17")
            end
            $options[ScheduleOptionKey] = scheduleCode.downcase
            # forcing a schedule code changes time behavior from -tn to -ta unless the user requests otherwise
            unless ARGV.include?("-t") || ARGV.include?("-tn")
                removeTimeKeys = true
            end
        when "-t"
            requireParameterForOption(opt, options)
            disallowOptionDuplication(opt)
            disallowOptionPairs("-t", "-ta")
            disallowOptionPairs("-t", "-tn")
            timeString = options.shift
            if timeString.length == 4
                hour = timeString[0,2].to_i
                minute = timeString[2,2].to_i
                if (0..23).include?(hour) && (0..59).include?(minute)
                    $options[HourOptionKey] = hour
                    $options[MinuteOptionKey] = minute
                else
                    log(ErrorLabel, "Invalid time string passed to -t! #{timeString} does not satisfy h(0..23) & m(0..59)")
                end
            else
                log(ErrorLabel, "Incorrect parameter length for -t!")
            end
        when "-ta"
            disallowOptionPairs("-t", "-ta")
            disallowOptionPairs("-ta", "-tn")
            removeTimeKeys = true
        when "-tn"
            disallowOptionPairs("-t", "-tn")
            disallowOptionPairs("-ta", "-tn")
            {}
        else
            log(WarningLabel, "Unrecognized option: #{opt}")
        end
    end

    # when -bt, -s or -ta is used
    if removeTimeKeys
        $options.delete(HourOptionKey)
        $options.delete(MinuteOptionKey)
    end
end

### Info and help

def showTitleAndAuthor
    authorEmailComponents = AuthorEmail.split(" ")
    puts "swl-tool.rb version #{ScriptVersion} by #{Author} : #{authorEmailComponents[0]}@#{authorEmailComponents[1]}.#{authorEmailComponents[2]} : #{AuthorBlog}"
end

def showTerseCredits
    showTitleAndAuthor()
    log("credit", "Shortwave broadcast schedule data from EiBi")
end

def showHelpAndExit
    showTitleAndAuthor()
    eiBiCredit()
    puts
    puts "Usage: swl-tool.rb [options]"
    puts
    puts "  -d  : show debug log messages"
    puts "  -dd : show lots of debug log messages"
    puts "  -h  : show help and exit"
    puts
    puts "  -b [broadcaster] : display broadcasts by this broadcaster"
    puts "  -bt : display time stations"
    puts "  -f [frequency in kHz] : display broadcasts on this frequency"
    puts "  -ft [frequency in kHz] : use a +- tolerance when filtering by frequency (must also use -f)"
    puts "  -i : display inactive broadcasts"
    puts "  -l [language] : display broadcasts that use this language (EiBi language codes)"
    puts "  -le, -lk, -ls : shortcuts for specifying languages"
    puts "  -m [meterband] : display broadcasts within this meter band"
    puts "  -mt [frequency in kHz]: use a +- tolerance when confining to a meter band (must also use -m)"
    puts "  -r [region] : display broadcasts targeting this region"
    puts "  -rna, -rsa, -reu, -raf, -ras, -roc : shortcuts for specifying regions"
    puts "  -s [xnn] : force this schedule code rather than using the current period"
    puts "  -t [hhmm] : display broadcasts around this time in UTC"
    puts "  -ta : display broadcasts at any time"
    puts "  -tn : display broadcasts around now [default]"
    exit(1)
end

### Output

InfoLabel = "info"
ScheduleLabel = "s"
DebugLabel = "debug"
DebugDebugLabel = "debugdebug"
ErrorLabel = "error"
WarningLabel = "warning"

# Log a message prefixed with a label in the format "label: message"
# Label constants are recommended for consistency and to ensure correct handling of debug and error features
def log(label, message)
    error = label.eql?(ErrorLabel)
    displayLog = true
    if (DebugLabel.eql?(label) && (false == $options[DebugOptionKey])) ||
       (DebugDebugLabel.eql?(label) && (false == $options[DebugDebugOptionKey]))
        displayLog = false
    end

    formattedMessage = "#{label}: #{message}"
    if error
        formattedMessage = "***\n" + formattedMessage + "\n***"
    end
    if displayLog
        puts formattedMessage
    end
    if error
        exit(1)
    end
end

def selfishStats
    if $options[DebugOptionKey] == true
        englishBC = 0
        northAmBC = 0
        for bc in $schedule
            languages = bc[:languages].split(',')
            for l in languages
                if l.eql?("E")
                    englishBC += 1
                end
            end
            region = bc[:targetRegion]
            if ["NAm", "WNA", "ENA", "CNA", "Am", "USA"].include?(region)
                northAmBC += 1
            end
        end
        log("selfish", "#{englishBC} English broadcasts / #{northAmBC} North America broadcasts")
    end
end

def doubleDebug
    if $options[DebugDebugOptionKey] == true
        debugBroadcasters()
        debugLanguages()
        debugRegions()
        debugDays()
    end
end

def debugLanguages
    log(DebugLabel, "language hash size: #{$languages.count}")
    langs = Hash::new
    for bc in $schedule
        codes = bc[:languages].split(',')
        for code in codes
            count = langs["#{code}"]
            if count == 0 || count == nil
                count = 1
            else
                count += 1
            end
            langs["#{code}"] = count
        end
    end
    for key in langs.keys
        puts "#{langs[key]} => #{key}    languagecount"
    end
end

def debugBroadcasters
    broadcasters = Hash::new
    # get a unique list of all broadcasters
    for bc in $schedule
        broadcaster = bc[:broadcaster]
        broadcasters[broadcaster] = broadcaster
    end
    for key in broadcasters.keys
        log(DebugLabel, "broadcaster: #{key}")
    end
end

def debugRegions
    regions = Hash::new
    # get a unique list of all the regions
    for bc in $schedule
        target = bc[:targetRegion]
        regions[target] = target
    end
    for key in regions.keys
        log(DebugLabel, "region: #{key}")
    end
end

def debugDays
    daysHash = Hash::new
    for bc in $schedule
        days = bc[:days]
        unless days == nil
            daysHash["#{days}"] = days
        end
    end
    for day in daysHash.keys
        log(DebugLabel, "day: #{day}")
    end
end

### Schedule management

$schedule = Array::new

# BroadcastEntry value types
# frequency:    integer
# broadcaster:  string
# origin:       string
# targetRegion: string
# languages:    string
# startHour:    integer
# startMinute:  integer
# endHour:      integer
# endMinute:    integer
# days:         string
# type:         string ### not yet used
# contents:     string ### not yet used
# inactive:     boolean
BroadcastEntry = Struct::new(:frequency, :broadcaster, :origin, :targetRegion, :languages, :startHour, :startMinute, :endHour, :endMinute, :days, :type, :contents, :inactive)
# broadcast type: a=analog, d=digital, f=fax, m=morse, n=numbers, t=time, v=volmet, x=navtex, w=weather
# broadcast contents: m=music, n=news, r=religion, w=weather, 

# BUG: the schedule code is based on assumptions; authoritative reference needed
# Current assumption is that "A" summer schedule begins during Mar; "B" winter schedule begins during Oct
def currentScheduleCode
    year = Time.now.utc.year
    twoDigitYear = year.to_s[2,2].to_i
    month = Time.now.utc.month
    log(DebugDebugLabel, "date #{twoDigitYear}-#{month}")

    case month
    when 1..2
        letter = "b"
        twoDigitYear -= 1
    when 3..9
        letter = "a"
    when 10..12
        letter = "b"
    else
        log(ErrorLabel, "Date parsing error! twoDigitYear(#{twoDigitYear}) month(#{month})")
    end
    code = letter + twoDigitYear.to_s
    log(DebugDebugLabel, "scheduleCode #{code}")
    return code
end

def previousScheduleCode
    # if B, change to A
    # if A, change to B and subtract a year
    current = currentScheduleCode()
    currentLetter = current[0]
    currentYear = current[1, 2].to_i
    if currentLetter.eql?("a")
        currentLetter = "b"
        currentYear -= 1
    elsif currentLetter.eql?("b")
        currentLetter = "a"
    else
        puts "*** ERROR: unrecognized schedule code: #{current}"
    end
    return currentLetter + currentYear.to_s
end

### Schedule display

# shortwave broadcast band reference: https://en.wikipedia.org/wiki/Shortwave_bands#International_broadcast_bands
def doesFrequencyMatchMeterBand(freq)
    result = true
    if $options.keys.include?(MeterBandOptionKey)
        mb = $options[MeterBandOptionKey]
        tolerance = nil
        if $options.keys.include?(MeterBandToleranceOptionKey)
            tolerance = $options[MeterBandToleranceOptionKey]
        else
            tolerance = 0
        end

        result = false
        unless [120, 90, 75, 60, 49, 41, 31, 25, 22, 19, 16, 15, 13, 11].include?(mb)
            log(ErrorLabel, "The specified value #{mb} is not a recognized broadcasting meter band [120, 90, 75, 60, 49, 41, 31, 25, 22, 19, 16, 15, 13, 11]")
        else
            log(DebugLabel, "#{freq} in #{mb}m?")
            case mb
            when 120
                result = ((2300-tolerance)..(2495+tolerance)).include?(freq)
            when 90
                result = ((3200-tolerance)..(3400+tolerance)).include?(freq)
            when 75
                result = ((3900-tolerance)..(4000+tolerance)).include?(freq)
            when 60
                result = ((4750-tolerance)..(5060+tolerance)).include?(freq)
            when 49
                result = ((5800-tolerance)..(6200+tolerance)).include?(freq)
            when 41
                result = ((7200-tolerance)..(7450+tolerance)).include?(freq)
            when 31
                result = ((9400-tolerance)..(9900+tolerance)).include?(freq)
            when 25
                result = ((11600-tolerance)..(12100+tolerance)).include?(freq)
            when 22
                result = ((13570-tolerance)..(13870+tolerance)).include?(freq)
            when 19
                result = ((15100-tolerance)..(15830+tolerance)).include?(freq)
            when 16
                result = ((17480-tolerance)..(17900+tolerance)).include?(freq)
            when 15
                result = ((18900-tolerance)..(19020+tolerance)).include?(freq)
            when 13
                result = ((21450-tolerance)..(21850+tolerance)).include?(freq)
            when 11
                result = ((25600-tolerance)..(26100+tolerance)).include?(freq)
            end
        end
    end # if MeterBandOptionKey
    return result
end

def doesBroadcastMatchBroadcasterFilter(bc)
    match = true
    broadcaster = bc[:broadcaster]
    if broadcaster != nil
        requiredBroadcaster = $options[BroadcasterOptionKey]
        if requiredBroadcaster != nil
            unless broadcaster.include?(requiredBroadcaster)
                match = false
            end
        end
    end
    return match
end

def doesBroadcastMatchFrequencyFilter(bc)
    match = nil
    if $options.keys.include?(FrequencyOptionKey)
        frequency = bc[:frequency]
        requiredFrequency = $options[FrequencyOptionKey]
        frequencyTolerance = $options[FrequencyToleranceOptionKey]
        if frequencyTolerance != nil
            if frequencyTolerance > 0
                match = (requiredFrequency-frequencyTolerance..requiredFrequency+frequencyTolerance).include?(frequency)
            end
        else
            match = (frequency == requiredFrequency)
        end
    else
        match = true
    end # if FrequencyOptionKey
    return match
end

def doesBroadcastMatchLanguageFilter(bc)
    match = true
    languages = bc[:languages].split(',')
    requiredLanguage = $options[LanguageOptionKey]
    if requiredLanguage != nil
        found = false
        for l in languages
            if l.eql?(requiredLanguage)
                found = true
                break
            end
        end
        match = found
    end
    return match
end

def doesBroadcastMatchMeterBandFilter(bc)
    match = doesFrequencyMatchMeterBand(bc[:frequency])
    return match
end

# When specified region is generic (e.g. Eu instead of WEu), incorporate all of its sub-regions
def doesBroadcastMatchRegionFilter(bc)
    match = true
    region = bc[:targetRegion]
    requiredRegion = $options[RegionOptionKey]
    unless requiredRegion == nil
        case requiredRegion
        when "NAm"
            match = ["NAm", "WNA", "ENA", "CNA", "Am", "USA"].include?(region)
        when "CAm"
            match = ["CAm", "Car", "LAm"].include?(region)
        when "SAm"
            match = ["SAm", "LAm"].include?(region)
        when "Eu"
            match = ["NEu", "WEu", "SEu", "EEu", "CEu", "SEE", "Eu"].include?(region)
        when "Af"
            match = ["NAf", "WAf", "SAf", "EAf", "CAf", "Af", "WIO"].include?(region)
        when "As"
            match = ["SAs", "CAs", "As", "SEA", "FE", "Tib"].include?(region)
        when "Oc"
            match = ["NOc", "WOc", "SOc", "EOc", "Oc"].include?(region)
        end
    end
    return match
end

# this value will either be the default of now in UTC (same as -ta option), or a user-specified UTC time
def filterMinutes
    filterHour = $options[HourOptionKey].to_i
    filterMinute = $options[MinuteOptionKey].to_i
    return (filterHour * 60) + filterMinute
end

# Test cases: 
# - end time is less than start time (broadcast wraps around 0000 UTC)
# - filtering time is near 0000 UTC (and we need to check for broadcasts back to 2330 UTC
def doesBroadcastMatchTimeFilter(bc)
    match = nil
    if $options.keys.include?(HourOptionKey) && $options.keys.include?(MinuteOptionKey)
        toleranceMinutes = 30
        # convert start time, end time, and current time to minutes offset from 0000 UTC for easy comparison
        broadcastStartMinutes = ((bc[:startHour] * 60) + bc[:startMinute]) - toleranceMinutes
        broadcastEndMinutes = ((bc[:endHour] * 60) + bc[:endMinute]) + toleranceMinutes
        if broadcastEndMinutes < broadcastStartMinutes
            # the broadcast wraps around 0000 UTC
        end
        if (broadcastStartMinutes <= filterMinutes()) && (broadcastEndMinutes >= filterMinutes())
            match = true
        else
            match = false
        end
    else # if HourOptionKey && MinuteOptionKey
        match = true
    end
    return match
end

def timeStringFromHoursAndMinutes(hours, minutes)
    hourString = hours.to_s
    if hourString.length < 2
        hourString = "0" + hourString
    end
    minuteString = minutes.to_s
    if minuteString.length < 2
        minuteString = "0" + minuteString
    end
    return hourString + minuteString
end

# source for language codes and definitions: http://eibispace.de/dx/README.TXT
# this hash table is incomplete; filled in with most frequently occuring languages from A17 and other languages as noticed
$languages = {"A"   => "Arabic", 
              "AB"  => "Abkhaz",
              "AD"  => "Adygea / Adyghe / Circassian",
              "AF"  => "Afrikaans",
              "AFA" => "Afar",
              "AFG" => "Pashto / Dari",
              "AH"  => "Amharic", 
              "AL"  => "Albanian",
              "AM"  => "Amoy",
              "AMD" => "Tibetan Amdo",
              "Ang" => "Angelus programme",
              "AR"  => "Armenian",
              "ASS" => "Assamese",
              "AV"  => "Avar",
              "AY"  => "Aymara",
              "AZ"  => "Azeri / Azerbaijani",
              "BC"  => "Baluchi",
              "BE"  => "Bengali / Bangla", 
              "BEM" => "Bemba",
              "BH"  => "Bhili",
              "BJ"  => "Bhojpuri / Bihari",
              "BM"  => "Bambara / Bamanankan",
              "BON" => "Bondo",
              "BOS" => "Bosnian",
              "BR"  => "Burmese",
              "BSL" => "Bislama",
              "BU"  => "Bulgarian",
              "BUN" => "Bundeli / Bundelkhandi / Bundelkandi",
              "BUR" => "Buryat",
              "BY"  => "Byelorussian / Belarusian",
              "C"   => "Chinese", 
              "C-F" => "Chin-Falam / Halam",
              "C-H" => "Chin-Haka",
              "C-Z" => "Chin-Zomin / Zomi-Chin",
              "CA"  => "Cantonese", 
              "CC"  => "Chaochow (dialect of Min-Nan)",
              "CD"  => "Chowdary / Chaudhry / Chodri",
              "CH"  => "Chin",
              "CHE" => "Chechen",
              "CHG" => "Chhattisgarhi",
              "CKW" => "Chokwe",
              "CR"  => "Creole / Haitian",
              "CZ"  => "Czech",
              "D"   => "German", 
              "D-P" => "Lower German",
              "DA"  => "Danish", 
              "DAO" => "Dao",
              "DI"  => "Dinka",
              "DO"  => "Dogri-Kangri",
              "DR"  => "Dari / Eastern Farsi",
              "DY"  => "Dyula / Jula",
              "DZ"  => "Dzongkha",
              "E"   => "English", 
              "EGY" => "Egyptian Arabic",
              "EO"  => "Esperanto",
              "F"   => "French", 
              "FI"  => "Finnish", 
              "FS"  => "Farsi", 
              "FT"  => "Fiote / Vili",
              "FU"  => "Fulani / Fulfulde",
              "GA"  => "Garhwali",
              "GE"  => "Georgian",
              "GM"  => "Gamit",
              "GR"  => "Greek", 
              "GU"  => "Gujarati",
              "HA"  => "Haussa", 
              "HAD" => "Hadiya",
              "HAS" => "Hassinya / Hassaniya",
              "HB"  => "Hebrew", 
              "HI"  => "Hindi", 
              "HK"  => "Hakka",
              "HM"  => "Hmong / Miao languages",
              "HMA" => "Hmar",
              "HR"  => "Croatian / Hrvatski",
              "HU"  => "Hungarian",
              "I"   => "Italian", 
              "IB"  => "Iban",
              "IN"  => "Indonesian", 
              "INU" => "Inuktikut",
              "IS"  => "Icelandic",
              "J"   => "Japanese", 
              "JV"  => "Javanese",
              "K"   => "Korean", 
              "KA"  => "Karen",
              "KAN" => "Kannada",
              "KAO" => "Kaonde",
              "KBO" => "Kok Borok / Tripuri",
              "KC"  => "Kachin / Jingpho",
              "KG"  => "Kyrgyz / Kirghiz",
              "KH"  => "Khmer",
              "KHA" => "Kham / Khams",
              "KHM" => "Khmu",
              "KHR" => "Kharia / Khariya",
              "KHS" => "Khasi / Kahasi",
              "KHT" => "Khota",
              "KK"  => "KiKongo / Kongo",
              "KMB" => "Kimbundu / Mbundu / Luanda",
              "KNK" => "KinyaRwanda-KiRundi",
              "KNU" => "Kanuri",
              "KRB" => "Karbi / Mikir / Manchati",
              "KRW" => "KinyaRwanda",
              "KS"  => "Kashmiri",
              "KU"  => "Kurdish",
              "KUN" => "Kunama",
              "KUR" => "Kurukh / Kurux",
              "KZ"  => "Kazakh", 
              "L"   => "Latin", 
              "LAD" => "Ladakhi / Ladak",
              "LAH" => "Lahu",
              "LAO" => "Lao",
              "LOZ" => "Lozi / Silozi",
              "LU"  => "Lunda",
              "LUG" => "Luganda",
              "LUN" => "Lunyaneka / Nyaneka",
              "LUV" => "Luvale",
              "M"   => "Mandarin", 
              "MAG" => "Maghi / Magahi / Maghai",
              "MAI" => "Maithili / Maithali",
              "MAL" => "Malayalam",
              "MAO" => "Maori", 
              "MAR" => "Marathi",
              "MEI" => "Meithei / Manipuri / Meitei",
              "MIE" => "Mien / Iu Mien",
              "MIS" => "Mising",
              "ML"  => "Malay / Baku",
              "MO"  => "Mongolian", 
              "MON" => "Mon",
              "MSY" => "Malagasy",
              "MUN" => "Mundari",
              "MW"  => "Marwari",
              "MY"  => "Maya (Yucatec)",
              "MZ"  => "Mizo / Lushai",
              "NDE" => "Ndebele",
              "NE"  => "Nepali / Lhotshampa", 
              "NIU" => "Niuean",
              "NL"  => "Dutch",
              "NO"  => "Norwegian",
              "NU"  => "Nuer",
              "NW"  => "Newar / Newari",
              "NY"  => "Nyanja",
              "OO"  => "Oromo",
              "OR"  => "Odia / Oriya / Orissa",
              "P"   => "Portuguese", 
              "PO"  => "Polish",
              "PJ"  => "Punjabi",
              "PS"  => "Pashto", 
              "Q"   => "Quechua", 
              "R"   => "Russian", 
              "RO"  => "Romanian", 
              "ROS" => "Rosary",
              "Ros" => "Rosary",
              "RWG" => "Rawang",
              "S"   => "Spanish", 
              "SD"  => "Sindhi",
              "SGA" => "Shangaan / Tsonga",
              "SHA" => "Shan",
              "SHC" => "Sharchogpa / Sarchopa / Tshangla",
              "SHO" => "Shona",
              "SHP" => "Sherpa",
              "SI"  => "Sinhalese / Sinhala",
              "SK"  => "Slovak",
              "SLM" => "Pijin / Solomon Islands Pidgin",
              "SM"  => "Samoan",
              "SO"  => "Somali", 
              "SNK" => "Sanskrit",
              "SNT" => "Santhali",
              "SR"  => "Serbian",
              "SUD" => "Sudanese Arabic",
              "SUN" => "Sunda / Sundanese",
              "SWA" => "Swahili / Kisuaheli", 
              "SWE" => "Swedish",
              "T"   => "Thai", 
              "TAG" => "Tagalog",
              "TAH" => "Tachelhit / Sous",
              "TAM" => "Tamil",
              "TB"  => "Tibetan", 
              "TEL" => "Telugu",
              "TIG" => "Tigrinya / Tigray", 
              "TJ"  => "Tajik",
              "TK"  => "Turkmen",
              "TL"  => "Tai-Lu / Lu",
              "TNG" => "Tonga",
              "TO"  => "Tongan",
              "TP"  => "Tok Pisin", 
              "TSH" => "Tshwa",
              "TT"  => "Tatar",
              "TTB" => "Tatar-Bashkir",
              "TU"  => "Turkish",
              "TV"  => "Tuva / Tuvinic",
              "TW"  => "Taiwanese / Fujian / Hokkien / Min Nan",
              "UI"  => "Uighur", 
              "UK"  => "Ukrainian",
              "UM"  => "Umbundu",
              "UR"  => "Urdu", 
              "UZ"  => "Uzbek",
              "VN"  => "Vietnamese", 
              "Vn"  => "Vernacular",
              "VV"  => "Vasavi",
              "W"   => "Wolof", 
              "WAO" => "Waodani / Waorani",
              "YK"  => "Yakutian / Sakha",
              "YO"  => "Yoruba",
              "Z"   => "Zulu",
              "ZA"  => "Zarma / Zama",
              "ZWE" => "Languages of Zimbabwe",
              "-CW" => "Morse", 
              "-MX" => "Music", 
              "-TS" => "Time station"}

def languagesFromString(string)
    languages = []
    codes = string.split(',')
    for code in codes
        language = $languages["#{code}"]
        if language != nil
            languages.push(language)
        else
            languages.push(code)
            log(DebugLabel, "Unrecognized language code: #{code}")
        end
    end
    # build a return string from the array that we have
    ls = ""
    for l in languages
        ls << l << ","
    end
    return ls.chop
end

=begin
Example values to parse:
Sa
SaSu
Mo,Th
Mo-Fr
2356

Examples that won't currently be parsed:
irr
+-50
1.Sa
Ram
24Dec
Xmas
sum
A17
tent
25th
Haj
win
alt
HBF
=end
# Generate a 7-char string to display day-of-week info alongside a broadcast entry
# In both the EiBi data and the 'days' array, 1 = Monday ... 7 = Sunday
# current output of "......." with -ta: 12095 - 10752 - 10481 - 10352 - 9620

def markDay(day, days)
    case day
    when 1, "Mo"
        days[1] = "M"
    when 2, "Tu"
        days[2] = "T"
    when 3, "We"
        days[3] = "W"
    when 4, "Th"
        days[4] = "T"
    when 5, "Fr"
        days[5] = "F"
    when 6, "Sa"
        days[6] = "S"
    when 7, "Su"
        days[0] = "S"
    end
end

# generate the days string for schedule display
# BUG: this method enforces starting the week on Sunday
# BUG: this is a large method that should be broken up
def daysString(bc)
    result = nil
    returnInput = false

    inactive = bc[:inactive]
    if inactive
        result = "inactiv"
    else
        result = "SMTWTFS"
        data = bc[:days]
        if (data != nil) && (data.length > 0)
            days = Array.new(7, ".") # note that this is a zero-based array but the data is one-based
            twoCharDays = "(Mo|Tu|We|Th|Fr|Sa|Su)"

            # search for hyphenated weekday range e.g. Mo-Fr
            if (/^#{twoCharDays}-#{twoCharDays}$/ =~ data) != nil
                mark = false
                first = data[0,2]
                second = data[3,2]

                daysArray = ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                unless daysArray.include?(first) && daysArray.include?(second)
                    log(DebugLabel, "Error parsing hyphenated day range! #{data}")
                else
                    # To ensure proper recording of all combinations of hypenated ranges, 
                    # first rotate the array until the first specified day is element 0
                    until daysArray[0].eql?(first)
                        # displaying full a17 schedule results in 1147 daysArray rotates
                        log(DebugDebugLabel, "daysArray rotate")
                        daysArray.rotate!
                    end
                    for d in daysArray
                        if first.eql?(d)
                            mark = true
                        elsif second.eql?(d)
                            mark = false
                        end
                        if mark || second.eql?(d)
                            markDay(d, days)
                        end 
                    end
                end
            # search for comma-separated weekday list e.g. Mo,Th
            elsif (/^#{twoCharDays},#{twoCharDays}$/ =~ data) != nil
                data.split(",").each do |day|
                    markDay(day, days)
                end
            # search for two adjacent days e.g. "SaSu"
            elsif (/^#{twoCharDays}{2}$/ =~ data) != nil
                first = data[0,2]
                second = data[2,2]
                markDay(first, days)
                markDay(second, days)
            # search for a single day e.g. "Tu"
            elsif (/^#{twoCharDays}$/ =~ data) != nil
                markDay(data, days)
            # search for day-of-week digit list e.g. 2356
            elsif (/^[1-7]+$/ =~ data) != nil
                #log(DebugLabel, "chopping digits #{data}")
                data.split("").each do |digit|
                    markDay(digit.to_i, days)
                end
            elsif (/^+-.+$/ =~ data) != nil
                returnInput = true
            else
                returnInput = true
                case data
                # for now, don't interpret these known cases
                when "Ram", "Haj", "HBF", "Xmas", "sum", "win", "alt", "irr", "tent", "plan", "Tests"
                    # BUG: this implementation results in data loss. original string could be displayed
                    days[0] = "*" # the indicator for an unparsed day value
                else
                    log(DebugLabel, "Unparsed day string: #{data}")
                end
            end
            result = days.join
        end # if data != nil && data.length > 0
    end # if inactive

    if returnInput
        result = bc[:days]
        result += "." while result.length < 7
    end
    return result
end

def doesBroadcastMatchInactiveFilter(bc)
    match = true
    if bc[:inactive]
        displayInactive = $options[InactiveDisplayOptionKey]
        if (nil == displayInactive) || (false == displayInactive)
            match = false
        end
    end
    return match
end

def showMatchingScheduleData
    # filters: broadcaster, frequency, language, meterband, region, time
    for bc in $schedule
        # This boolean chain will stop executing once false
        if doesBroadcastMatchFrequencyFilter(bc) &&
           doesBroadcastMatchLanguageFilter(bc) &&
           doesBroadcastMatchBroadcasterFilter(bc) &&
           doesBroadcastMatchMeterBandFilter(bc) &&
           doesBroadcastMatchRegionFilter(bc) &&
           doesBroadcastMatchTimeFilter(bc) &&
           doesBroadcastMatchInactiveFilter(bc)

            # convert frequency into 5-char string
            freqString = bc[:frequency].to_s
            while freqString.length < 5
                freqString = " " + freqString
            end

            # convert times into 4-char strings
            startTimeString = timeStringFromHoursAndMinutes(bc[:startHour], bc[:startMinute])
            endTimeString = timeStringFromHoursAndMinutes(bc[:endHour], bc[:endMinute])

            # compose the broadcast time/days string
            broadcastTime = "#{startTimeString} - #{endTimeString} #{daysString(bc)}"

            # expand language code to description
            language = languagesFromString(bc[:languages])

            # expand station name to the maximum 23 characters per http://eibispace.de/dx/README.TXT
            stationName = bc[:broadcaster]
            stationName += " " while stationName.length < 23

            log(ScheduleLabel, "#{freqString} kHz : [#{broadcastTime}] : #{stationName} : #{language} to #{bc[:targetRegion]}")
        end
    end
end

### Files

def storagePath
    return Dir.home + "/.swl-tool/"
end

def createDirectoryIfNeeded
    storagePath = storagePath()
    unless Dir.exist?(storagePath)
        log(InfoLabel, "Creating directory for files: #{storagePath}")
        Dir.mkdir(storagePath, 0700)
        # BUG: unhandled SystemCallError
    end
end

### EiBi

def eiBiCredit
    puts "EiBi shortwave broadcasting schedule info by Eike Bierwirth : http://www.eibispace.de"
end

def isEiBiFetchNeeded(scheduleCode)
    fetchNeeded = false
    # look for file locally
    # if missing, or if present and more than a week old, then fetch

    expectedFile = storagePath + filenameForEiBiSchedule(scheduleCode)
    if File.exist?(expectedFile)
        mtime = File::new(expectedFile).mtime
        if mtime < (Time::now - 60*60*24*7)
            log(InfoLabel, "EiBi schedule file too old; fetching")
            fetchNeeded = true
            # BUG: rename existing file to an archived copy with creation timestamp
        end
    else
        log(InfoLabel, "EiBi schedule file not found; fetching")
        fetchNeeded = true
    end
    return fetchNeeded
end

# Note that a06 is the earliest csv -- this is checked in the calling method
# Note that b15 is currently the newest csv in the archive path
def fetchEiBiSchedule(scheduleCode)
    # create an array of up to two EiBi urls to check: the /dx directory and the /archive directory
    eibiURLs = Array.new

    # always add the /archive url
    eibiURLs.push(urlForEiBiSchedule(scheduleCode, true))

    # if the scheduleCode is newer than b15, insert the /dx url at the beginning of the array
    scheduleCodeYear = scheduleCode[1,2].to_i
    if scheduleCodeYear >= 16
        eibiURLs.insert(0, urlForEiBiSchedule(scheduleCode, false))
    end

    success = nil
    for url in eibiURLs
        success = nil
        uri = URI(url)
        filename = filenameForEiBiSchedule(scheduleCode)
 
        log(InfoLabel, "Trying #{url} ...")
        response = Net::HTTP.get_response(uri)
        responseCode = response.code.to_i
        log(DebugLabel, "http response code for #{url} is #{responseCode}")

        case responseCode
        when 200..299
            success = true
            if response.class.body_permitted?
                File.open(storagePath() + filename, "w") { |f|
                    f.write(response.body)
                    f.flush()
                }
                break
            else
                log(ErrorLabel, "http response body not permitted? #{response}")
            end
        when 400..499
            success = false
        else
            log(DebugLabel, "Unhandled http response code #{responseCode}")
            success = false
        end
    end # for url in eibiURLs
    return success
end

def fetchAndLoadEiBiSchedule
    loaded = false
    available = false

    scheduleCodes = nil
    # first check if the user is overriding the automatic schedule fetch with a specific schedule code
    if $options.keys.include?(ScheduleOptionKey)
        scheduleCodes = [$options[ScheduleOptionKey]]
        # Note that a06 is the earliest eibi csv available
        scheduleCodeYear = scheduleCodes[0][1,2].to_i
        if scheduleCodeYear < 6
            log(ErrorLabel, "Schedule code #{scheduleCodes[0]} is less than the minimum: a06")
        end
    else
        # otherwise use the current and previous schedule codes
        scheduleCodes = [currentScheduleCode(), previousScheduleCode()]
    end
    for attempt in 0..(scheduleCodes.length - 1)
        scheduleCode = scheduleCodes[attempt]
        log(DebugLabel, "checking schedule #{scheduleCode}")
        success = true
        # check if we have a fresh copy. if not, fetch
        if isEiBiFetchNeeded(scheduleCode)
            success = fetchEiBiSchedule(scheduleCode)
            unless success
                log(DebugLabel, "http fetch error")
            end
        end
        if success
            available = true
            break
        end
    end
    if available
        loaded = parseEiBiSchedule(scheduleCode)
    else
    end
    return loaded
end

# This is for the CSV file
def filenameForEiBiSchedule(scheduleCode)
    return "sked-#{scheduleCode}.csv"
end

# note that archived csv begins with B06
def urlForEiBiSchedule(scheduleCode, useArchiveURL)
    url = nil
    filename = filenameForEiBiSchedule(scheduleCode)
    if useArchiveURL
        url = "http://www.eibispace.de/archive/" + filename
    else
        url = "http://www.eibispace.de/dx/" + filename
    end
    return url
end

def parseEiBiSchedule(scheduleCode)
    loaded = false
    schedulePath = storagePath() + filenameForEiBiSchedule(scheduleCode)
    if File.exist?(schedulePath)
        log(DebugLabel, "parsing #{schedulePath}")
        # open the file
        firstLineSkipped = false
        File.open(schedulePath, "rb:iso-8859-1").each_line do |line|
            if firstLineSkipped
                # parse into BroadcastEntry elements
                bce = parseEiBiTextLine(line.chomp)
                $schedule.push(bce) unless nil == bce
            else
                firstLineSkipped = true
            end
        end
        # the file has been processed although this is no guarantee of valid schedule data
        loaded = true
    end
    unless loaded
        log(ErrorLabel, "Could not find an EiBi schedule in #{storagePath()}")
    else
        log(InfoLabel, "Loaded #{$schedule.count} schedule entries")
    end
    return loaded
end

# first two lines of an example EiBi csv file
=begin
kHz:75;Time(UTC):93;Days:59;ITU:49;Station:201;Lng:49;Target:62;Remarks:135;P:35;Start:60;Stop:60;
16.4;0000-2400;;NOR;JXN Marine Norway;;NEu;no;1;;
=end

$parserLine = 0
def parseEiBiTextLine(line)    
    $parserLine += 1
    log(DebugDebugLabel, "parser line #{$parserLine}")
    fields = line.split(';')
    save = true
    bc = BroadcastEntry::new

    frequency = fields[0].to_i
    if frequency < 1711 || frequency > 30000
        save = false
        log(DebugDebugLabel, "Disregarding entry for #{frequency} kHz")
    else
        bc[:frequency] = frequency
    end

    inactive = fields[8].eql?("8")
    bc[:inactive] = inactive
    if inactive
        log(DebugDebugLabel, "inactive: #{line}")
    end

    # hhmm-hhmm -- note that this block could be omitted for inactives
    bc[:startHour] = fields[1][0,2].to_i
    bc[:startMinute] = fields[1][2,2].to_i
    bc[:endHour] = fields[1][5,2].to_i
    bc[:endMinute] = fields[1][7,2].to_i

    unless inactive
        bc[:days] = fields[2]
    end

    bc[:origin] = fields[3]
    bc[:broadcaster] = fields[4]
    bc[:languages] = fields[5]
    bc[:targetRegion] = fields[6]
    # ignoring the EiBi "Remarks"/Transmitter field
    # ignoring the EiBi "Persistence" field
    # ignoring the start/stop date fields

    if save
        log(DebugDebugLabel, "bc = #{bc}")
    else
        bc = nil
    end
    return bc
end

### Main

def main
    parseCommandLineOptions()
    createDirectoryIfNeeded()
    if fetchAndLoadEiBiSchedule()
        selfishStats()
        doubleDebug()
        showMatchingScheduleData()
    else
        log(ErrorLabel, "Could not load EiBi schedule")
    end
end

main()

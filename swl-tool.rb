#!/usr/local/bin/ruby -w

# swl-tool: a script to fetch, archive, and search shortwave broadcasting schedules
# EiBi shortwave schedules kindly created by Eike Bierwirth : http://www.eibispace.de
# This script created by Eric Weatherall : cobaltpet gmail com
# Developed in a secret location in Northern California
# Env: ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin16]

require_relative '_Common'
require_relative '_BroadcastEntry'
require_relative '_ScheduleParser'
require_relative '_EiBiScheduleParser'
require_relative '_Filter'

# TODO: incorporate Aoki http://www.geocities.jp/binewsjp/
# TODO: incorporate hfcc.org?
# TODO: add ionosphere day/night filters -id -in to prefer compatible frequencies -- determine the cutoff? 11MHz?
# TODO: add local sunrise-sunset lookups to automatically assist with ionosphere advice
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
ScriptVersion = "2017-09-07 0016UTC"

### Options

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
            $options[BroadcastFlagsOptionKey] = BroadcastFlagTime
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
            log(WarningLabel, "Language filter support is currently broken. See https://github.com/cobaltpet/swl-tool/issues/30")
            language = options.shift
            $options[LanguageOptionKey] = language
        when "-le"
            log(WarningLabel, "Language filter support is currently broken. See https://github.com/cobaltpet/swl-tool/issues/30")
            $options[LanguageOptionKey] = "E"
        when "-lk"
            log(WarningLabel, "Language filter support is currently broken. See https://github.com/cobaltpet/swl-tool/issues/30")
            $options[LanguageOptionKey] = "K"
        when "-ls"
            log(WarningLabel, "Language filter support is currently broken. See https://github.com/cobaltpet/swl-tool/issues/30")
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
        #debugLanguages() # BUG: disabled due to languages work in progress
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
    log(DebugLabel, "schedule count for debugdays: #{$schedule.count}")
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

def showMatchingScheduleData
    # filters: broadcaster, frequency, language, meterband, region, time
    for bc in $schedule
        # This boolean chain will stop executing once false
        if doesBroadcastMatchFrequencyFilter(bc, $options[FrequencyOptionKey], $options[FrequencyToleranceOptionKey]) &&
           doesBroadcastMatchLanguageFilter(bc, $options[LanguageOptionKey]) &&
           doesBroadcastMatchBroadcasterFilter(bc, $options[BroadcasterOptionKey]) &&
           doesBroadcastMatchBroadcastFlagsFilter(bc, $options[BroadcastFlagsOptionKey]) &&
           doesBroadcastMatchMeterBandFilter(bc, $options[MeterBandOptionKey], $options[MeterBandToleranceOptionKey]) &&
           doesBroadcastMatchRegionFilter(bc, $options[RegionOptionKey]) &&
           doesBroadcastMatchTimeFilter(bc, $options[HourOptionKey], $options[MinuteOptionKey]) &&
           doesBroadcastMatchInactiveFilter(bc, $options[InactiveDisplayOptionKey])

            # convert frequency into 5-char string
            freqString = bc[:frequency].to_s
            while freqString.length < 5
                freqString = " " + freqString
            end

            # convert times into 4-char strings
            startTimeString = timeStringFromHoursAndMinutes(bc[:startHour], bc[:startMinute])
            endTimeString = timeStringFromHoursAndMinutes(bc[:endHour], bc[:endMinute])

            # compose the broadcast time/days string
            broadcastTime = "#{startTimeString} - #{endTimeString} #{bc[:daysPrintable]}"

            # expand station name to the maximum 23 characters per http://eibispace.de/dx/README.TXT
            stationName = bc[:broadcaster]
            stationName += " " while stationName.length < 23

            log(ScheduleLabel, "#{freqString} kHz : [#{broadcastTime}] : #{stationName} : #{bc[:languages]} to #{bc[:targetRegion]}")
        end
    end
end

### EiBi

def eiBiCredit
    puts "EiBi shortwave broadcasting schedule info by Eike Bierwirth : http://www.eibispace.de"
end

### Main

def main
    parseCommandLineOptions()
    createDirectoryIfNeeded(storagePath())

    eibiParser = EiBiScheduleParser.new
    eibiParser.localFilePath = storagePathSubdirectory("eibi")
    createDirectoryIfNeeded(eibiParser.localFilePath)

    scheduleCodes = nil
    # first check if the user is overriding the automatic schedule fetch with a specific schedule code
    if $options.keys.include?(ScheduleOptionKey)
        scheduleCodes = [$options[ScheduleOptionKey]]
    else
        # otherwise use the current and previous schedule codes
        scheduleCodes = [currentScheduleCode(), previousScheduleCode()]
    end
    for attempt in 0..(scheduleCodes.length - 1)
        scheduleCode = scheduleCodes[attempt]
        log(DebugLabel, "checking schedule #{scheduleCode}")

        records = eibiParser.broadcastEntryRecordsForScheduleCode("a17")
        if records.count > 0
            $schedule.push(records).flatten!
            selfishStats()
            doubleDebug()
            showMatchingScheduleData()
            break
        end
    end
end

main()

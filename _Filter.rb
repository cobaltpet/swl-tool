#!/usr/local/bin/ruby -w

# _Filter.rb -- Filter methods for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require_relative '_Common'

# shortwave broadcast band reference: https://en.wikipedia.org/wiki/Shortwave_bands#International_broadcast_bands
def doesFrequencyMatchMeterBand(freq, mb, tolerance)
    result = true
    unless nil == mb
        if nil == tolerance
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
    end
    return result
end

def doesBroadcastMatchBroadcasterFilter(bc, requiredBroadcaster)
    match = true
    broadcaster = bc[:broadcaster]
    if broadcaster != nil
        if requiredBroadcaster != nil
            unless broadcaster.include?(requiredBroadcaster)
                match = false
            end
        end
    end
    return match
end

def doesBroadcastMatchBroadcastFlagsFilter(bc, requiredFlags)
    match = nil

    if nil == requiredFlags
        match = true
    else
        flags = bc[:flags]
        flags = "" if nil == flags
        log(DebugLabel, "flags.include?(requiredFlags) / (#{flags}) / (#{requiredFlags})")
        match = flags.include?(requiredFlags)
    end
    
    return match
end

def doesBroadcastMatchFrequencyFilter(bc, requiredFrequency, frequencyTolerance)
    match = nil
    frequency = bc[:frequency]
    unless nil == requiredFrequency
        if nil == frequencyTolerance
            match = (frequency == requiredFrequency)
        else
            match = (requiredFrequency-frequencyTolerance..requiredFrequency+frequencyTolerance).include?(frequency)
        end
    else
        match = true
    end
    return match
end

def doesBroadcastMatchLanguageFilter(bc, requiredLanguage)
    match = true
    languages = bc[:languages].split(',')
    unless nil == requiredLanguage
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

def doesBroadcastMatchMeterBandFilter(bc, mb, tolerance)
    match = doesFrequencyMatchMeterBand(bc[:frequency], mb, tolerance)
    return match
end

# When specified region is generic (e.g. Eu instead of WEu), incorporate all of its sub-regions
def doesBroadcastMatchRegionFilter(bc, requiredRegion)
    match = true
    region = bc[:targetRegion]
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
def filterMinutes(hour, minute)
    return (hour * 60) + minute
end

# Test cases: 
# - end time is less than start time (broadcast wraps around 0000 UTC)
# - filtering time is near 0000 UTC (and we need to check for broadcasts back to 2330 UTC
def doesBroadcastMatchTimeFilter(bc, requiredHour, requiredMinute)
    match = nil
    if nil == requiredHour || nil == requiredMinute
        match = true
    else
        toleranceMinutes = 30
        # convert start time, end time, and current time to minutes offset from 0000 UTC for easy comparison
        broadcastStartMinutes = ((bc[:startHour] * 60) + bc[:startMinute])
        broadcastEndMinutes = ((bc[:endHour] * 60) + bc[:endMinute])

        inverted = nil
        if broadcastEndMinutes < broadcastStartMinutes
            # the broadcast wraps around 0000 UTC
            log(DebugLabel, "inverted time range")
            inverted = true
            tmp = broadcastStartMinutes
            broadcastStartMinutes = broadcastEndMinutes + toleranceMinutes
            broadcastEndMinutes = tmp - toleranceMinutes
        else
            inverted = false
            broadcastStartMinutes -= toleranceMinutes
            broadcastEndMinutes += toleranceMinutes
        end

        fMinutes = filterMinutes(requiredHour, requiredMinute)
        within = (broadcastStartMinutes <= fMinutes) && (broadcastEndMinutes >= fMinutes)
        match = within != inverted
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

def doesBroadcastMatchInactiveFilter(bc, displayInactive)
    match = true
    if bc[:inactive]
        if (nil == displayInactive) || (false == displayInactive)
            match = false
        end
    end
    return match
end

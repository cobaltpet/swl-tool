#!/usr/local/bin/ruby -w

# _BroadcastEntry.rb -- BroadcastEntry struct for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

# BroadcastEntry value types
# frequency:     integer
# broadcaster:   string
# origin:        string
# targetRegion:  string
# languages:     string
# startHour:     integer
# startMinute:   integer
# endHour:       integer
# endMinute:     integer
# days:          string
# daysPrintable: string
# type:          string ### not yet used
# contents:      string ### not yet used
# inactive:      boolean
BroadcastEntry = Struct::new(:frequency, :broadcaster, :origin, :targetRegion, :languages, :startHour, :startMinute, :endHour, :endMinute, :days, :daysPrintable, :type, :contents, :inactive)
# broadcast type: a=analog, d=digital, f=fax, m=morse, n=numbers, t=time, v=volmet, x=navtex, w=weather
# broadcast contents: m=music, n=news, r=religion, w=weather, 

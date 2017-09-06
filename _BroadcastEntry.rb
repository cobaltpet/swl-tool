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
# inactive:      boolean
# flags:         string

BroadcastEntry = Struct::new(:frequency, :broadcaster, :origin, :targetRegion, :languages, :startHour, :startMinute, :endHour, :endMinute, :days, :daysPrintable, :inactive, :flags)

# Values within the 'flags' field:
BroadcastFlagAnalog =    "a"
BroadcastFlagDigital =   "d"
BroadcastFlagNumbers =   "e"
BroadcastFlagFax =       "f"
BroadcastFlagMusic =     "m"
BroadcastFlagNews =      "n"
BroadcastFlagMorse =     "o"
BroadcastFlagReligious = "r"
BroadcastFlagTime =      "t"
BroadcastFlagVolmet =    "v"
BroadcastFlagWeather =   "w"
BroadcastFlagNavtex =    "x"

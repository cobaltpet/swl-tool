#!/usr/local/bin/ruby -w

# _EiBiScheduleParser.rb -- EiBiScheduleParser class for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

require_relative '_ScheduleParser'

class EiBiScheduleParser < ScheduleParser
    def broadcastEntryRecordsFromFile(filePath)
        puts "*** #{self.class.name} must be subclassed and #{__method__.to_s} must be overridden"
    end
end

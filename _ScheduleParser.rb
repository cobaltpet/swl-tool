#!/usr/local/bin/ruby -w

# _ScheduleParser.rb -- ScheduleParser class for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

class ScheduleParser
    # The caller should set this with a combination of a consistent base path and a class-specific subdirectory
    localFilePath = "/tmp"
    attr_accessor :localFilePath

    # Return an array of BroadcastEntry items for the specified scheduleCode (a string in the form "xnn" e.g. "a17")
    def broadcastEntryRecordsForScheduleCode(scheduleCode)
        puts "*** #{self.class.name} must be subclassed and #{__method__.to_s} must be overridden"
    end
end

#!/usr/local/bin/ruby -w

# _Common.rb -- Common code and resources for swl-tool
# Refer to swl-tool.rb for author info, software license, and script version

### Logging

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

### Files

def storagePath
    return Dir.home + "/.swl-tool/"
end

def storagePathSubdirectory(subdir)
    return storagePath() + subdir + "/"
end

def createDirectoryIfNeeded(path)
    unless Dir.exist?(path)
        log(InfoLabel, "Creating directory for files: #{path}")
        Dir.mkdir(path, 0700)
        # BUG: unhandled SystemCallError
    end
end

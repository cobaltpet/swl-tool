swl-tool
========

swl-tool is a ruby script that fetches, parses, and displays shortwave broadcast schedule info.

Usage
=====

    $ ./swl-tool.rb -h  
    swl-tool.rb version 2017-09-04 0054UTC by Eric Weatherall : cobaltpetxxxxxxxcom : http://cobaltpet.blogspot.com/  
    EiBi shortwave broadcasting schedule info by Eike Bierwirth : http://www.eibispace.de

    Usage: swl-tool.rb [options]

      -d  : show debug log messages  
      -dd : show lots of debug log messages  
      -h  : show help and exit

      -b [broadcaster] : display broadcasts by this broadcaster  
      -f [frequency in kHz] : display broadcasts on this frequency  
      -ft [frequency in kHz] : use a +- tolerance when filtering by frequency (must also use -f)  
      -i : display inactive broadcasts  
      -l [language] : display broadcasts that use this language (EiBi language codes)  
      -le, -lk, -ls : shortcuts for specifying languages  
      -m [meterband] : display broadcasts within this meter band  
      -mt [frequency in kHz]: use a +- tolerance when confining to a meter band (must also use -m)  
      -r [region] : display broadcasts targeting this region  
      -rna, -rsa, -reu, -raf, -ras, -roc : shortcuts for specifying regions  
      -s [xnn] : force this schedule code rather than using the current period  
      -t [hhmm] : display broadcasts around this time in UTC  
      -ta : display broadcasts at any time  
      -tn : display broadcasts around now [default]

Example output
==============

    $ echo "time = now; language = english; region = north america; meter band = 49"
    time = now; language = english; region = north america; meter band = 49

    $ ./swl-tool.rb -tn -le -rna -m 49  
    swl-tool.rb version 2017-09-04 0054UTC by Eric Weatherall : cobaltpetxxxxxxxcom : http://cobaltpet.blogspot.com/  
    credit: Shortwave broadcast schedule data from EiBi  
    info: Loaded 12377 schedule entries  
    s:  5803 kHz : [0115 - 0200 SMTWTFS] : VFF Iqaluit Radio : English to NAm  
    s:  5850 kHz : [0030 - 0100 SMTWTFS] : Radio Slovakia Int. : English to WNA  
    s:  5850 kHz : [0100 - 0600 SMTWTFS] : Brother Stair : English to WNA  
    s:  5850 kHz : [0100 - 0700 SMTWTFS] : Brother Stair : English to WNA  
    s:  5920 kHz : [0000 - 0100 .M.....] : Brother Stair : English to ENA  
    s:  5920 kHz : [0000 - 0100 S.TWTFS] : World Harvest Radio 2 : English to ENA  
    s:  5920 kHz : [0100 - 0200 ..TWTFS] : World Harvest Radio 6 : English to ENA  
    s:  5930 kHz : [0000 - 1200 SMTWTFS] : Dr.Gene Scott : English to NAm  
    s:  5935 kHz : [0000 - 1200 SMTWTFS] : Dr.Gene Scott : English to NAm  
    s:  5990 kHz : [0100 - 0500 SMTWTFS] : Radio Habana Cuba : English to ENA  
    s:  6000 kHz : [0100 - 0500 SMTWTFS] : Radio Habana Cuba : English to ENA  
    s:  6020 kHz : [0000 - 0100 SMTWTFS] : China Radio Int. : English to ENA  
    s:  6020 kHz : [0100 - 0200 SMTWTFS] : China Radio Int. : English to ENA  
    s:  6030 kHz : [0000 - 2400 SMTWTFS] : CFVP Calgary Funny AM : English to WNA  
    s:  6070 kHz : [0000 - 2400 SMTWTFS] : CFRX Toronto, CFRB 1010 : English to NAm  
    s:  6145 kHz : [0100 - 0500 SMTWTFS] : Radio Habana Cuba : English to CNA  
    s:  6145 kHz : [0000 - 0100 S......] : Mighty KBC : English to NAm  
    s:  6145 kHz : [0000 - 0100 S......] : Mighty KBC : English to NAm  
    s:  6145 kHz : [0000 - 0300 S......] : Mighty KBC : English to NAm  
    s:  6160 kHz : [0000 - 2400 SMTWTFS] : CKZN St John's : English to ENA  
    s:  6165 kHz : [0000 - 0100 SMTWTFS] : Radio Habana Cuba : English to CNA  
    s:  6165 kHz : [0100 - 0120 SMTWTFS] : Radio Habana Cuba : English to CNA  
    s:  6165 kHz : [0100 - 0500 SMTWTFS] : Radio Habana Cuba : English to CNA

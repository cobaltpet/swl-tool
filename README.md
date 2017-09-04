$ ./swl-tool.rb -h  
swl-tool.rb version 2017-09-04 0054UTC by Eric Weatherall : cobaltpetxxxxxxxcom  
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

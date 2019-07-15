**HHiSSpred Copyright (C) 2012 by Mensur Dlakic**

These are short instructions about installing and testing HHiSSpred. More 
details will be available when the work is accepted for publication. Among
other things, we plan to make the predictions available in more user-friendly
formats, including PSIPRED format for those applications that rely on it.

If you are reading this, that means that the archive has been unpacked. We 
keep the program in /home/user/HHiSSpred, but it can be installed anywhere 
as long as you have the writing privilege.

There are 5 files ending in .com in this directory, and a3m2chk.com in bin
directory. In each of them 1-3 variables have to be set. The most common
parameter to customize in all classifier scripts is the directory where
HHiSSpred is located. Specifically, change the line that reads:

set HHISPRED = "$HOME/HHiSSpred"

You can leave it like that if the distribution was unpacked in your $HOME 
directory, or provide the full path within quotation marks. 

Second variable is the location of PSI-BLAST database, which is to be set
on this line:

set PSIDB = "$HOME/db/uniref90_01252012.pfilt"

We use UniProt filteredat 90% identity which can be downloaded here:

ftp://ftp.uniprot.org/pub/databases/uniprot/uniref/uniref90/uniref90.fasta.gz

This database first has to be filtered using PFILT, which is part of the
PSIPRED package and can be downloaded here:

http://bioinfadmin.cs.ucl.ac.uk/downloads/pfilt/

Finally, PFILT-processed database has to be formated for use with PSI-BLAST.

Third variable is the location of HHblits database, which is to be set
on this line:

set UNIPDB = "$HOME/db/uniprot20_02Sep11"

We use uniprot20_02Sep11 which can be downloaded here:

http://wwwuser.gwdg.de/~compbiol/data/hhsuite/databases/hhsuite_dbs/

HHiSSpred **DOES NOT** work with BLAST+ executables. We use BLAST
version 2.2.19 and that is the only version that is guaranteed to reproduce
our results. HHiSSpred uses blastpgp and makemat.

Another requirement is HHsuite of programs which can be downloaded here:

https://github.com/soedinglab/hh-suite/releases

HHiSSpred needs hhblits, hhmake, hhfilter and the perl script reformat.pl, all
of which are part of HHsuite. Versions 2.0.9 and above are all tested and should
work. All HHsuite and BLAST programs are expected to be in the path and the
scripts will not work if they cannot be found.

Once all variables are set, copy HHiSSpred-??.com scripts into a directory 
that is in your $PATH. If you have root privilege, it will probably be 
/usr/local/bin or something like that. If not, copy into a directory in 
the $PATH to which you have writing access.

The package can be tested by going to test directory and typing:

./test.sh

That should give several .ss files (final predictions are in ??-2nd.ss). Compare
those files to .ss files in examples directory.

**What do individual scripts do?**

HHiSSpred-chk.com runs HHblits, converts its alignment into .chk files by using
PSI-BLAST, and predicts secondary structures based on those .chk files. Final
prediction is an average of 10 neural networks.

HHiSSpred-hhm.com runs HHblits, filters the alignment to effective number of
sequences = 7, makes a .hhm file from this alignment, converts .hhm into .chk,
and predicts secondary structures based on those .chk files. Notice that this
script starts from the same HHblits alignment as HHiSSpred-chk.com. Final
prediction is an average of 10 neural networks.

HHiSSpred-psi.com runs PSI-BLAST to make .chk files directly, and predicts
secondary structures based on those .chk files. It should be in principle very
similar to PSIPRED. Final prediction is an average of 10 neural networks.

HHiSSpred-jury-hhm-chk.com runs HHiSSpred-hhm.com and HHiSSpred-chk.com in first
stage of training, then uses jury-like consensus to combine both types of
networks into final prediction. Final prediction is an average of
20 neural networks.

HHiSSpred-jury-hhm-psi.com runs HHiSSpred-hhm.com and HHiSSpred-psi.com in first
stage of training, then uses jury-like consensus to combine both types of    
networks into final prediction. Final prediction is an average of                 
20 neural networks. This is the best predictor in our tests.

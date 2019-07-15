#!/bin/csh
#        
# Please set up the HHISSPRED below to directory where HHiSSpred was unpacked.
# We will assume that it is $HOME/HHiSSpred.
#

set HHISSPRED = "$HOME/HHiSSpred"

if ( "$1" == "" ) then
    echo ""
    echo "This script converts .a3m files into PSI-BLAST"
    echo "checkpoints. Useful either for restarting PSI-BLAST"
    echo "or for making matrices for secondary structure prediction."
    echo ""
    echo "The correct syntax is:"
    echo ""
    echo "a3m2chk.com file <a3m file> <chk file>"
    echo ""
    if (-e $HHISSPRED) then
    echo " It appears that HHISSPRED is set properly."
    endif
    if (! -e $HHISSPRED) then
    echo " It appears that HHISSPRED is NOT set properly."
    endif
    echo ""
    exit 9
endif

if ( "$2" == "" ) then
    set FASTA=$1:r.chk
    else
    set FASTA=$2
    endif

echo ""
echo " Converting .a3m file $1 ..."
echo ""
reformat.pl -v 0 -r -noss a3m psi $1 $1:r.tmpfile.psi 
blastpgp -b 1 -j 1 -h 0.001 -d $HHISSPRED/bin/db/do_not_delete -i $1:r.fas -B $1:r.tmpfile.psi -C $FASTA >& /dev/null
echo "./$FASTA:r.chk" > $FASTA:r.pn
echo "./$FASTA:r.seq" > $FASTA:r.sn
makemat -P $FASTA:r -S 100.0
rm $FASTA:r.pn $FASTA:r.sn $1:r.tmpfile.psi $FASTA:r.aux $FASTA:r.mn
echo " Done ..."
echo ""

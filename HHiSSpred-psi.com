#!/bin/csh      
#        
# Please set up the HHISSPRED below to directory where HHiSSpred was unpacked.
# We will assume that it is $HOME/HHiSSpred.
# Please set up the PSIDB below to directory where pfilt-processed PSI-BLAST   
# database is located.                                                        
# These are the only two parameters to be edited.
#

set HHISSPRED = "$HOME/HHiSSpred"           
set PSIDB = "$HOME/db/uniref90_01252012.pfilt"              

if ( "$1" == "" ) then
    echo ""
    echo " This script predicts secondary structure from PSI-BLAST checkpoints."
    echo " Its only input is a sequence file in FASTA format."
    echo ""
    echo " Please make sure that HHISSPRED (line 8 in this script)"
    echo " is set properly."
    echo ""
    echo " Usage:"
    echo ""
    echo " HHiSSpred-psi.com <FASTA file>"
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

    echo ""
set whereis = `which blastpgp`
#
     if ( $whereis == "blastpgp: Command not found" ) then
         echo ""
         echo " ERROR: Cannot find blastpgp."
         echo ""
         echo " Please make sure that blastpgp is installed."
         echo ""
         exit 9
     else
         echo " Found blastpgp."
     endif

     if (! -e $HHISSPRED/bin/mtx2net ) then
         echo ""
         echo " ERROR: Cannot find mtx2net."
         echo ""
         echo " Please make sure that HHISSPRED points to HHiSSpred directory."
         echo ""
         exit 9
     else
         echo " Found mtx2net."
     endif

     if (! -e $HHISSPRED/bin/ceh2net ) then
         echo ""
         echo " ERROR: Cannot find ceh2net."
         echo ""
         echo " Please make sure that HHISSPRED points to HHiSSpred directory."
         echo ""
         exit 9
     else
         echo " Found ceh2net."
     endif

echo ""
echo " Predicting secondary structure for $1 ..."
cp $1 $1:r-psi.seq
if ( -e $1:r-psi.chk ) then
echo " It appears that PSI-BLAST search was already done for $1 ..."
endif
if ( ! -e $1:r-psi.chk ) then
echo " Running PSI-BLAST ..."
blastpgp -a 8 -b 0 -j 3 -h 0.001 -i $1 -d $PSIDB -C $1:r-psi.chk >& /dev/null
endif
echo " Making PSI-BLAST matrix ..."
echo $1:r-psi.seq > $1:r-psi.sn
echo $1:r-psi.chk > $1:r-psi.pn
makemat -P $1:r-psi -S 100.0
rm $1:r-psi.?n $1:r-psi.aux
echo " Making files for 1st neural network ..."
$HHISSPRED/bin/mtx2net $1:r-psi.mtx >& /dev/null
echo " Running 1st neural network ..."
$HHISSPRED/bin/psi-1st-net 315 `head -1 $1:r-psi.mtx | awk '{print $1}'` $1:r-psi-1st.data $1:r-psi-1st.ss >& /dev/null
echo " Making files for 2nd neural network ..."
$HHISSPRED/bin/ceh2net $1:r-psi-1st.ss >& /dev/null
echo " Running 2nd neural network ..."
$HHISSPRED/bin/psi-2nd-net 60 `head -1 $1:r-psi.mtx | awk '{print $1}'` $1:r-psi-2nd.data $1:r-psi-2nd.ss
echo ""
echo " Final secondary structure prediction is in $1:r-psi-2nd.ss "
echo ""

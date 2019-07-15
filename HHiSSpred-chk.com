#!/bin/csh      
#        
# Please set up the HHISSPRED below to directory where HHiSSpred was unpacked.
# We will assume that it is $HOME/HHiSSpred.
# Please set up the UNIPDB below to directory where HHblits database
# uniprot20_02Sep11 is located. We assume it is in $HOME/db/uniprot20_02Sep11.
# These are the only two parameters to be edited.
#

set HHISSPRED = "$HOME/HHiSSpred"           
set UNIPDB = "$HOME/db/uniprot20_02Sep11"

if ( "$1" == "" ) then
    echo ""
    echo " This script predicts secondary structure from HHblits alignments"
    echo " converted into PSI-BLAST-like checkpoints. Its only input is a"
    echo " sequence file in FASTA format."
    echo ""
    echo " Please make sure that HHISSPRED (line 8 in this script)"
    echo " is set properly."
    echo ""
    echo " Usage:"
    echo ""
    echo " HHiSSpred-chk.com <FASTA file>"
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
set whereis = `which hhblits`
#
     if ( $whereis == "hhblits: Command not found" ) then
         echo ""
         echo " ERROR: Cannot find hhblits."
         echo ""
         echo " Please make sure that hhblits is installed."
         echo ""
         exit 9
     else
         echo " Found hhblits."
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
cp $1 $1:r-chk.seq
if ( -e $1:r.a3m ) then
echo " It appears that HHblits search was already done for $1 ..."
endif
if ( ! -e $1:r.a3m ) then
echo " Running HHblits ..."
hhblits -i $1 -d $UNIPDB -cpu 4 -n 3 -aliw 45 -realign_max 10000 -cov 20 -neffmax 13.0 -alt 1 -oa3m $1:r.a3m >& /dev/null
endif
if ( -e $1:r.hhr ) then
rm $1:r.hhr
endif
if ( -e $1:r-chk.chk ) then
echo " It appears that .a3m file was already converted to .chk ..."
endif
if ( ! -e $1:r-chk.chk ) then
echo " Converting .a3m file to .chk ..."
$HHISSPRED/bin/a3m2chk.com $1:r.a3m $1:r-chk.chk >& /dev/null
endif
echo " Making files for 1st neural network ..."
$HHISSPRED/bin/mtx2net $1:r-chk.mtx >& /dev/null
echo " Running 1st neural network ..."
$HHISSPRED/bin/chk-1st-net 315 `head -1 $1:r-chk.mtx | awk '{print $1}'` $1:r-chk-1st.data $1:r-chk-1st.ss >& /dev/null
echo " Making files for 2nd neural network ..."
$HHISSPRED/bin/ceh2net $1:r-chk-1st.ss >& /dev/null
echo " Running 2nd neural network ..."
$HHISSPRED/bin/chk-2nd-net 60 `head -1 $1:r-chk.mtx | awk '{print $1}'` $1:r-chk-2nd.data $1:r-chk-2nd.ss
echo ""
echo " Final secondary structure prediction is in $1:r-chk-2nd.ss "
echo ""

#!/bin/csh
#          
# Please set up the HHISSPRED below to directory where HHiSSpred was unpacked.
# We will assume that it is $HOME/HHiSSpred.          
# Please set up the UNIPDB below to directory where HHblits database
# uniprot20_02Sep11 is located. We assume it is in $HOME/db/uniprot20_02Sep11.
# Please set up the PSIDB below to directory where pfilt-processed PSI-BLAST
# database is located.
# These are the only three parameters to be edited.         
#        

set HHISSPRED = "$HOME/HHiSSpred"
set UNIPDB = "$HOME/db/uniprot20_02Sep11"
set PSIDB = "$HOME/db/uniref90_01252012.pfilt"

if ( "$1" == "" ) then
    echo ""
    echo " This script predicts secondary structure by combining HHblits"
    echo " alignments filtered to effective number of sequences = 7 and"
    echo " PSI-BLAST checkpoints."
    echo " Its only input is a sequence file in FASTA format."
    echo ""
    echo " Please make sure that HHISSPRED (line 8 in this script)"
    echo " is set properly."
    echo ""
    echo " Usage:"
    echo ""
    echo " HHiSSpred-jury-hhm-psi.com <FASTA file>"
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

set whereis = `which hhfilter`
#
     if ( $whereis == "hhfilter: Command not found" ) then
         echo ""
         echo " ERROR: Cannot find hhfilter."
         echo ""
         echo " Please make sure that hhfilter is installed."
         echo ""
         exit 9
     else
         echo " Found hhfilter."
     endif

set whereis = `which hhmake`
#
     if ( $whereis == "hhmake: Command not found" ) then
         echo ""
         echo " ERROR: Cannot find hhmake."
         echo ""
         echo " Please make sure that hhmake is installed."
         echo ""
         exit 9
     else
         echo " Found hhmake."
     endif

     if (! -e $HHISSPRED/bin/hhm2chk ) then
         echo ""
         echo " ERROR: Cannot find hhm2chk."
         echo ""
         echo " Please make sure that HHISSPRED points to HHiSSpred directory."
         echo ""
         exit 9
     else
         echo " Found hhm2chk."
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
if ( -e $1:r-neff-7.a3m ) then
echo " It appears that HHfilter was already run for $1 ..."
endif
if ( ! -e $1:r-neff-7.a3m ) then
echo " Running HHfilter ..."
hhfilter -i $1:r.a3m -o $1:r-neff-7.a3m -id 94 -neff 7 >& /dev/null
endif
if ( -e $1:r-hhm.hhm ) then
echo " It appears that HHmake was already run for $1 ..."
endif
if ( ! -e $1:r-hhm.hhm ) then
echo " Running HHmake ..."
hhmake -i $1:r-neff-7.a3m -o $1:r-hhm.hhm -pcm 2 -pca 1.0 -csw 1.6 -Blosum65 -gapb 1.0 -gapd 0.15 -gape 1.0 -id 100 -diff 0 >& /dev/null
endif
echo " Converting .hhm file to .chk ..."
$HHISSPRED/bin/hhm2chk $1:r-hhm.hhm >& /dev/null
if ( -e $1:r-psi.chk ) then
echo " It appears that PSI-BLAST search was already done for $1 ..."
endif
if ( ! -e $1:r-psi.chk ) then
echo " Running PSI-BLAST ..."
blastpgp -a 8 -b 0 -j 3 -h 0.001 -i $1 -d $PSIDB -C $1:r-psi.chk >& /dev/null
endif
echo " Making PSI-BLAST matrices ..."
echo $1:r-hhm.seq > $1:r-hhm.sn
echo $1:r-hhm.chk > $1:r-hhm.pn
makemat -P $1:r-hhm -S 100.0
rm $1:r-hhm.?n $1:r-hhm.aux
echo $1:r-psi.seq > $1:r-psi.sn
echo $1:r-psi.chk > $1:r-psi.pn
makemat -P $1:r-psi -S 100.0
rm $1:r-psi.?n $1:r-psi.aux
echo " Making files for 1st neural networks ..."
$HHISSPRED/bin/mtx2net $1:r-hhm.mtx >& /dev/null
$HHISSPRED/bin/mtx2net $1:r-psi.mtx >& /dev/null
echo " Running 1st neural networks ..."
$HHISSPRED/bin/hhm-1st-net 315 `head -1 $1:r-hhm.mtx | awk '{print $1}'` $1:r-hhm-1st.data $1:r-hhm-1st.ss >& /dev/null
$HHISSPRED/bin/psi-1st-net 315 `head -1 $1:r-psi.mtx | awk '{print $1}'` $1:r-psi-1st.data $1:r-psi-1st.ss >& /dev/null
echo " Making files for 2nd neural networks ..."
$HHISSPRED/bin/ceh2net $1:r-hhm-1st.ss >& /dev/null
$HHISSPRED/bin/ceh2net $1:r-psi-1st.ss >& /dev/null
echo " Running JURY of 2nd neural networks ..."
$HHISSPRED/bin/jury-hhm-psi 60 `head -1 $1:r-hhm.mtx | awk '{print $1}'` $1:r-hhm-2nd.data $1:r-psi-2nd.data $1:r-jury-hhm-psi.ss
echo ""
echo " Final secondary structure prediction is in $1:r-jury-hhm-psi.ss "
echo ""

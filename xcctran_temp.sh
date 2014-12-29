#!/bin/bash
#author by xlp
#transfrom the sky coords to xy coords with cctran 
#to crossmatch the xy coords between sex output and cctran output
#to derive the real xy coords and its sky coords 
#the final result is named as GwacStandall.cat and refcom1d.cat
#update file should be update according to the different sky region.
#Update at 20130108 by xlp
#======================================
if [ $# -ne 5 ]
then
        echo "usage:command like this"
	echo "./xcctran.sh input_RaDecfile_all input_RaDecfile_stand database_accfile fitfile G1P1"
	echo "output: *_allxy *_standxy"
	echo "cat ../result/PointName.cat ==== you could find the alias for any skyfiled" 
        exit 0
fi
#=====================================
DIR_data=`pwd`
result_dir=$HOME/tempfile/result
RaDecfileAll=$1
RaDecfileStand=$2
Accfile=$3
FITFILE=$4
skyfield=$5

DETECT_TH=3 
maglimitSigma=5 
Num_IdeaCatalog=60000 #the base of max num for the refcom3d.cat

ID_CamaraType=`gethead $FITFILE "IMAGEID" | cut -c14-14`
OUTPUT=`echo $FITFILE | sed 's/\.fit/.fit.sex/'`
OUTPUT_new=`echo $FITFILE | sed 's/\.fit/.fit.sex_xy/'`
skyfield_cat=`echo $skyfield"_update.cat"`
XYfilecctranAll=`echo $RaDecfileAll"_allxy"`
XYfilecctranStand=`echo $RaDecfileStand"_standxy"`

rm -rf $XYfilecctranAll $XYfilecctranStand refcom_subbg.fit refcom1d.cat refcom2d.cat

echo $RaDecfileAll $RaDecfileStand $Accfile $FITFILE $skyfield $Initial_limit $skyfield_cat $ID_CamaraType  

if [ "$ID_CamaraType"x = "M"x ]
then
	Initial_limit=14.0 # the upper limit for mini-gwac when get the catalog from USNO B1.0 by xGetCatalog.sh
	ratio_num=2.0  # The upper num is 100 thousand 
elif  [ "$ID_CamaraType"x = "G"x ] 
then
	Initial_limit=17.0 # the upper limit for GWAC when get the catalog from USNO B1.0 by xGetCatalog.sh
	ratio_num=3.0
fi

#=====================================
gnuplot xplot.gn
#=====================================

sex $FITFILE  -c  daofind.sex  -CATALOG_NAME $OUTPUT -DETECT_THRESH $DETECT_TH -ANALYSIS_THRESH $DETECT_TH
#cat $OUTPUT | awk '{if($4==0) print($1,$2,$3)}' >allres0
cat $OUTPUT | awk '{print($1,$2,$3)}' >allres0
#cat $OUTPUT | sort -n -r -k 3 | awk '{if($4==0 && ($3)-$5/($6)>1000 )print($1,$2,$3)}' | column -t >refcom1d.cat
#============================================================
        Npixel=`gethead $FITFILE "NAXIS1"`
        if [ $Npixel -gt 1024 ] # greater than 1k
        then
                Nbstar=10
                Ng=2
        else
                Nbstar=6
                Ng=0
        fi
        Nb=`echo $Npixel $Nbstar | awk '{print(int($1/$2))}'`
rm -rf refcom1d.cat
#========================================================
#get the bright objects for the first geomap with linear correction 
       for((i=$Ng;i<($Nbstar-$Ng);i++))
        do
                for((j=$Ng;j<($Nbstar-$Ng);j++))
                do
                        cat allres0 | awk '{if( (nb*i)<$1 && $1<=(nb*(i+1)) &&    (nb*j)<$2 && $2<=(nb*(j+1))) print($1,$2,$3)}' i=$i j=$j nb=$Nb |sort -n -r -k 3 | head -1 | column -t >>refcom1d.cat
                done
        done
        # for the 1d geomap with trinangle

rm -rf refcom2d.cat 
#=======================================================
        Nbstar=30
        Nb=`echo $Npixel $Nbstar | awk '{print(int($1/$2))}'`
        for((i=0;i<$Nbstar;i++))
        do
                for((j=0;j<$Nbstar;j++))
                do
                        cat allres0 | awk '{if( (nb*i)<$1 && $1<=(nb*(i+1)) &&    (nb*j)<$2 && $2<=(nb*(j+1))) print($1,$2,$3)}' i=$i j=$j nb=$Nb | sort -n -r -k 3 | head -1 | column -t >>refcom2d.cat
                done
        done
        #for second geomap with tolerence
#======================================
cp refcom2d.cat GwacStandall.cat

#======================================================
#echo $RaDecfileAll $XYfilecctranAll
cd $HOME/iraf
cp -f login.cl.old login.cl
echo noao >> login.cl
echo digiphot >> login.cl
echo image >> login.cl
echo imcoords >>login.cl
echo "cd $DIR_data" >> login.cl
echo flpr >> login.cl
echo "imarith( \"$FITFILE\",\"-\",\"bak.fit\",\"refcom_subbg.fit\")" >> login.cl
echo "cctran(input=\"$RaDecfileAll\",output=\"$XYfilecctranAll\", database=\"$Accfile\",solutions=\"first\", geometry=\"geometric\",forward-,lngunits=\"degrees\",latunits=\"degrees\",projection=\"tan\",xcolumn=1,ycolumn=2, lngform=\"%12.3f\",latform=\"%12.3f\",min_sigdigits=7) " >>login.cl
echo logout >> login.cl
cl < login.cl >xlogfile.log
cd $HOME/iraf
cp -f login.cl.old login.cl
#cd $DIR_data
#======================================
#echo $RaDecfileStand $XYfilecctranStand
cd $HOME/iraf
cp -f login.cl.old login.cl
echo noao >> login.cl
echo digiphot >> login.cl
echo image >> login.cl
echo imcoords >>login.cl
echo "cd $DIR_data" >> login.cl
echo flpr >> login.cl
echo "cctran(input=\"$RaDecfileStand\",output=\"$XYfilecctranStand\", database=\"$Accfile\",solutions=\"first\", geometry=\"geometric\",forward-,lngunits=\"degrees\",latunits=\"degrees\",projection=\"tan\",xcolumn=1,ycolumn=2,lngform=\"%12.3f\",latform=\"%12.3f\",min_sigdigits=7) " >>login.cl
echo logout >> login.cl
cl < login.cl >xlogfile.log 
cd $HOME/iraf
cp -f login.cl.old login.cl
cd $DIR_data
#======================================
wc $XYfilecctranStand   $XYfilecctranAll
#======================================
paste $XYfilecctranAll |  awk '{if($1>0 && $1<3056 && $2>0 && $2<3056 && $6>0) print($1,$2,$6)}' >refcom3d_noupdate0.cat  # R2mag, $5 is R1mag, $6 is R2mag
#===================================================
#decrease the number of temp 
#wc refcom3d_noupdate0.cat

#===================
Num_refcom3d0=`wc -l refcom3d_noupdate0.cat | awk '{print($1)}'`
ratio_refcom3d0_pre=`echo $Num_refcom3d0 $Num_IdeaCatalog | awk '{print($1/$2)}'`
echo $ratio_refcom3d0_pre
deltamag_decrease=0
while [ `echo " $ratio_refcom3d0_pre > $ratio_num " | bc ` -eq 1 ]; do
        echo "deltamag_decrease is: " $deltamag_decrease  
        bb=`echo $deltamag_decrease | awk '{print($1+0.2)}'`
        deltamag_decrease=`echo $bb`
        cat refcom3d_noupdate0.cat | awk '{if($3 < (Initial_limit - deltamag_decrease))print($1,$2,$3)}' Initial_limit=$Initial_limit deltamag_decrease=$deltamag_decrease | sort -n -k 3 >temp
        mv temp refcom3d_noupdate0.cat
        Num_refcom3d0=`wc -l refcom3d_noupdate0.cat | awk '{print($1)}'`
        ratio_refcom3d0_pre=`echo $Num_refcom3d0 $Num_IdeaCatalog | awk '{print($1/$2)}'`
done
##====================
#echo $ratio_refcom3d0_pre 
#if [ `echo " $ratio_refcom3d0_pre > 5.0 " | bc ` -eq 1 ]
#then
#	deltamag_decrease=2.0
#elif [ `echo " $ratio_refcom3d0_pre > 3.0 " | bc ` -eq 1 ]   
#then
#	deltamag_decrease=1.0
#elif [ `echo " $ratio_refcom3d0_pre > 2.0 " | bc ` -eq 1  ]
#then	 
#	deltamag_decrease=0.5
#elif [ `echo "  $ratio_refcom3d0_pre > 1 " | bc ` -eq 1 ]
#then
#	deltamag_decrease=0.3
#else
#	deltamag_decrease=0
#fi
#echo $deltamag_decrease $Initial_limit
##head -10 refcom3d_noupdate0.cat
##cp refcom3d_noupdate0.cat temp.refcom3d_noupdate0.cat
#cat refcom3d_noupdate0.cat | awk '{if($3 < (Initial_limit - deltamag_decrease))print($1,$2,$3)}' Initial_limit=$Initial_limit deltamag_decrease=$deltamag_decrease | sort -n -k 3 >temp
#mv temp refcom3d_noupdate0.cat
#echo "Second time for refcom3d_noupdate0.cat imstat"
#echo "decrease mag: "$deltamag_decrease
#wc refcom3d_noupdate0.cat 
#=================================================

cp refcom3d_noupdate0.cat refcom3d.cat
cat $OUTPUT | awk '{print($1,$2,$7)}' | sort -n -k 3 >image.cat
#wc refcom3d.cat 
#wc image.cat
#tail -1 refcom3d.cat
#tail -1 image.cat
#sleep 5
#cp image.cat refcom3d.cat ../
./xCrossImageRefcom3d #output is the newOT.cat
cat newOT.cat refcom3d.cat | column -t >temp #update the refcom3d.cat
mv temp refcom3d.cat
cp refcom3d.cat refcom3d_noupdate.cat
rm -rf newOT.cat
wc image.cat refcom3d_noupdate.cat
./xlimit #output is the newOTT.cat   refall_magbin.cat, the letter file contains the magbin and num, which is for the maglimit estimate.
ls newOTT.cat refall_magbin.cat
gnuplot << EOF
set term png
set output "white-standard.png"
set xlabel "mini-gwac white mag"
set ylabel "Standard R2 mag (USNO B1.0)"
set grid
set key left
f(x)=a*x+b
a=1
fit [13:5][13:5] f(x) 'newOTT.cat' u 3:6 via a,b  
plot [14:5][14:5]'newOTT.cat' u 3:6 t 'R2',f(x)
quit
EOF
#in the gnuplot, a=1 is aiming to make the fit to be corrected.

aa=`cat fit.log | tail -9 | head -1 | awk '{print($3)}'`
bb=`cat fit.log | tail -8 | head -1 | awk '{print($3)}'`
echo "the transformation format is f(x)="$aa"*x+"$bb
echo "f(x)="$aa"*x+"$bb >imagetrans.cat
#instrumental magnitude is x, with the f(x), these magnitude could be transfermed to the standard R2 mag.
mv newOTT.cat limitnewOT.cat
rm -rf fit.log SameStar.cat newOTT.cat
#=====================================

cat $XYfilecctranStand | awk '{if($1>0 && $2>0 && $1<3056 && $2<3056 && $3>0) print($1,$2,$3)}' | sort -n -r -k 3 | head -1000 >GwacStandall_mag.cat #R1mag, $3 is R1mag, $4 is R2mag
cat $OUTPUT | awk '{print($1,$2,$7*k+xb)}' k=$aa xb=$bb | sort -n -k 3 >image.cat #this magnitude has been standardlized
date
./xCrossImageStand #output is the SameStar.cat
date
cat SameStar.cat | awk '{print($5,$6,$7*k+xb)}' k=$aa xb=$bb  >GwacStandall_mag.cat #flux calibration file
mv image.cat refcom4d.cat
#========================================

#$3 is the flux in area, area=4 pixel, detect_th is the detection mini-sigma, $6 is the threshold, thus $6/detect_th is the stddev of the background. maglimitSigma=5
#the sn of the star is that flux/stdev/sqrt(area), 
#the delta magnitude is that 2.512*log(sn/maglimitSigma)
#the limit magnitude is that the R2 magnitude + deltamagniutde.
cat  $OUTPUT | awk '{if($8<0.2)print($1,$2,($7*k+xb)+2.512*log($3*DETECT_TH/$6/sqrt(4)/maglimitSigma)/log(10),$7)}' k=$aa xb=$bb DETECT_TH=$DETECT_TH maglimitSigma=$maglimitSigma >refcom_maglimit.cat  # area=4 for aperature phot

#=========================
sum=0
for R2limitmag in `cat refcom_maglimit.cat | awk '{print($3)}'`
do
        sum1=`echo $sum $R2limitmag | awk '{print($1+$2)}'`
        sum=`echo $sum1`
        j=`echo $i | awk '{print($1+1)}'`
        i=`echo $j`
done
averagelimit=`echo $sum $i | awk '{print($1/$2)}'`
echo "average for the" $maglimitSigma  " sigma limit R magnitude:" $averagelimit
echo $averagelimit "  the" $maglimitSigma  " sigma limit R magnitude" >refcom_avermaglimit.cat

#======================================
#date >time1
#month=`cat time1 | awk '{print($2)}'`
#day=`cat time1 | awk '{print($3)}'`
#timex=`cat time1 | awk '{print($4)}'`
#newname3d=`echo "refcom3d.cat"_$month"_"$day"_"$timex`
#newname1d=`echo "refcom1d.cat"_$month"_"$day"_"$timex`
#standobj=`echo "GwacStandall.cat"_$month"_"$day"_"$timex`

touch noupdate.flag
mkdir $result_dir"/"$skyfield

mv white-standard.png limitnewOT.cat refcom3d_noupdate*.cat imagetrans.cat  noupdate.flag refall.png refstand.png refcom.fit refall_magbin.cat refcom.acc refcom2d.cat refcom1d.cat refcom3d.cat refcom4d.cat GwacStandall.cat GwacStandall_mag.cat refcom_maglimit.cat refcom_avermaglimit.cat refcom_subbg.fit refall.txt refall.txt_allxy refstand.txt_standxy refstand.txt  $result_dir"/"$skyfield
wait

rm -rf time1 white-standard.png refstand.txt_standxy *.png imagetrans.cat  refcom_maglimit.cat refcom.fit.sex noupdate.flag refall_magbin.cat refstand.txt refcom2d.cat bak.fit GwacStandall.cat  refcom_avermaglimit.cat GwacStandall_mag.cat refall.txt refall.txt_allxy refcom.acc allres0 refcom4d.cat 

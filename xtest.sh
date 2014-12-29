Initial_limit=14
Num_IdeaCatalog=50000
Num_refcom3d0=`wc -l refcom3d_noupdate0.cat | awk '{print($1)}'`
ratio_refcom3d0_pre=`echo $Num_refcom3d0 $Num_IdeaCatalog | awk '{print($1/$2)}'`
echo $ratio_refcom3d0_pre
deltamag_decrease=0
while [ `echo " $ratio_refcom3d0_pre > 2.0 " | bc ` -eq 1 ]; do
        echo "deltamag_decrease is: " $deltamag_decrease  
        bb=`echo $deltamag_decrease | awk '{print($1+0.2)}'`
        deltamag_decrease=`echo $bb`
        cat refcom3d_noupdate0.cat | awk '{if($3 < (Initial_limit - deltamag_decrease))print($1,$2,$3)}' Initial_limit=$Initial_limit deltamag_decrease=$deltamag_decrease | sort -n -k 3 >temp
        mv temp refcom3d_noupdate0.cat
        Num_refcom3d0=`wc -l refcom3d_noupdate0.cat | awk '{print($1)}'`
        ratio_refcom3d0_pre=`echo $Num_refcom3d0 $Num_IdeaCatalog | awk '{print($1/$2)}'`
done  

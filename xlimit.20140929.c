#include  <stdio.h>
#include  <math.h>
#include  <stdlib.h>
#include <sys/io.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>
#define CriRadius 1.0
main()
{
        int     i,j,k,m,N0,N1,N2,NumCross;
        float   rxc1,ryc2,rflux3,rflux4,rflux5,oxc1,oyc2,oflux3;
        float   inputxc1,inputyc2;
	float	deltax,deltay,deltaxy,deltamag;
        float   x1[200000],x2[200000],x3[200000],x4[200000],x5[200000],k1[200000],k2[200000],k3[200000];
        FILE    *fp1;
        FILE    *fave;
        char    *refall, *objall;

        refall="refcom3d_noupdate0.cat";
        objall="image.cat";

        printf("refall = %s\n",refall);
        printf("objall = %s\n",objall);

        i=0;
        j=0;
        m=0;
        fave=fopen("newOT.cat","w+");

        fp1=fopen(refall,"r");
        if(fp1)
        {
	//	printf("#####refcom3d.cat#####");
                while((fscanf(fp1,"%f %f %f\n",&rxc1,&ryc2,&rflux3))!=EOF)
                {
                x1[i]=rxc1;
                x2[i]=ryc2;
                x3[i]=rflux3;
	//	x4[i]=rflux4;
	//	x5[i]=rflux5;
                i++;
                }
                N1=i;
        }
        fclose(fp1);

        fp1=fopen(objall,"r");
        if(fp1)
        {
	  //printf("#########image.cat###########3");
          while((fscanf(fp1,"%f %f %f \n",&oxc1,&oyc2,&oflux3))!=EOF)
          {
          k1[m]=oxc1;
          k2[m]=oyc2;
          k3[m]=oflux3;
          m++;
          }
          N2=m;
        }
        fclose(fp1);
        
	for(m=0;m<N2;m++)
        {
        	      for(i=0;i<N1;i++)
                      {
			deltax=x1[i]-k1[m];
			deltay=x2[i]-k2[m];
			//deltamag=fabs(x3[m]-k3[m]);
			deltaxy=sqrt(deltax*deltax+deltay*deltay);
			if(deltaxy<CriRadius)
//                      	if(deltaxy<CriRadius && deltamag<2.0)
                        {
				fprintf(fave,"%.3f %.3f %.3f %.3f %.3f %.3f \n",k1[m],k2[m],k3[m],x1[i],x2[i],x3[i]);
				break;
			}
                      }
        }
        fclose(fave);
}


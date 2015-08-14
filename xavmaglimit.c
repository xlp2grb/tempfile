#include  <stdio.h>
#include  <math.h>
#include  <stdlib.h>
#include <sys/io.h>
#include <unistd.h>
#include <string.h>
#include <stdbool.h>
main(  )
{
    int     i,N1;
	float	rxc1,ryc1,maglimit,mag;
	float	sum,averagemaglimit;
    float   r10[400000];
    FILE    *fp1; 
	FILE	*fave;
	char    *refnew;

	refnew="refcom_maglimit.cat";
	i=N1=0;
	fave=fopen("newav.cat","a+");
	sum=0;
	averagemaglimit=0;

	fp1=fopen(refnew,"r");	
	if(fp1)
	{
	    while((fscanf(fp1,"%f %f %f %f\n",&rxc1,&ryc1,&maglimit,&mag))!=EOF)
	        {
                r10[i]=maglimit;
		        sum=sum+r10[i];
		        i++;
		    }
		N1=i;
	}
	fclose(fp1);

	averagemaglimit=sum/N1;
	fprintf(fave,"%.0f\n",averagemaglimit);
	fclose(fave);
}

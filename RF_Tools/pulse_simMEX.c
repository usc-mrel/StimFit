#include "mex.h"
#include <math.h>


void mexFunction(int nlhs, mxArray *left[], int nrhs, const mxArray *right[]) {
    
    /*  Declare variables */
    mwSize Nz, Nt, i, iNt, ind;
    double *pMin, *pCOS, *pSIN, *pCTRF, *pSTRF, *pcpRF, *pspRF, *pMout;
    double cpRF, spRF;
    double Mx, My, Mz;
    mxArray *Mout;
    
    /*  Get pointers to input */
    pMin  = mxGetPr(right[0]);
    pCOS  = mxGetPr(right[1]);
    pSIN  = mxGetPr(right[2]);
    pCTRF = mxGetPr(right[3]);
    pSTRF = mxGetPr(right[4]);
    pcpRF = mxGetPr(right[5]);cpRF = pcpRF[0];
    pspRF = mxGetPr(right[6]);spRF = pspRF[0];
    
    
    /*  Determine number of elements */
    Nz = mxGetN(right[0]);
    Nt = mxGetN(right[3]);
    
    /*  Create output and assign pointer */
    Mout  = mxCreateDoubleMatrix(3,Nz,mxREAL);
    pMout = mxGetPr(Mout);
    
    /*  Initialize output magnetization */
    for (i=0; i<Nz; i++) {
        ind = 3*i;
        pMout[ind]   = pMin[ind];
        pMout[ind+1] = pMin[ind+1];
        pMout[ind+2] = pMin[ind+2];
    }
    
    /*  Loop through all time points */
    for (iNt=0; iNt<Nt; iNt++) {
        
        /*  Loop through spatial positions and apply rotation */
        for (i=0; i<Nz; i++) {
            ind = 3*i;
            Mx = pMout[ind];
            My = pMout[ind+1];
            pMout[ind]   =  pCOS[i]*Mx + pSIN[i]*My;
            pMout[ind+1] = -pSIN[i]*Mx + pCOS[i]*My;
            /*pMout[ind+2] =  pMin[ind+2];*/
        }
        
        /*  Apply RF tip */
        for (i=0; i<Nz; i++) {
            ind = 3*i;
            Mx = pMout[ind];
            My = pMout[ind+1];
            Mz = pMout[ind+2];
            
            pMout[ind]   = Mx*(cpRF*cpRF + pCTRF[iNt]*spRF*spRF) + 
                           My*(cpRF*spRF - pCTRF[iNt]*cpRF*spRF) - 
                           Mz*(spRF*pSTRF[iNt]);
            pMout[ind+1] = My*(pCTRF[iNt]*cpRF*cpRF + spRF*spRF) + 
                           Mx*(cpRF*spRF - cpRF*spRF*pCTRF[iNt]) +
                           Mz*(cpRF*pSTRF[iNt]);
            pMout[ind+2] = Mz*pCTRF[iNt] -
                           My*cpRF*pSTRF[iNt] +
                           Mx*spRF*pSTRF[iNt];
        }
    }
    
    /*  Assign output */
    left[0] = Mout;
}
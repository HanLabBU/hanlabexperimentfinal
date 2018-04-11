#include "mex.h"
void svListFeatures(int, mxArray_tag** const, int, mxArray_tag** const);
 
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    svListFeatures(1,plhs,0,NULL);
}
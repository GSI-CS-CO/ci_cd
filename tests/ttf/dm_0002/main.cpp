#include <stdio.h>
#include <iostream>
#include <string>
#include <inttypes.h>
#include "sched-builder.h"
using namespace std;

#define EXPECTED_ARGUMENTS 6

int main (int argc, char* argv[])
{
  /* Parameters */
  string sName = "default";
  unsigned int uiEvents = 0;
  unsigned int uiCPU = 0;
  unsigned int uiLoops = 0;
  unsigned int uiMaxOffset = 0;
  bool fVerbose = false;
  int iRet = 0;

  /* Parse command line arguments */
  try
  {
    if      (argc == 1)                  { throw 0; }
    else if (argc != EXPECTED_ARGUMENTS) { throw 1; }
    else
    {
      sName = argv[1];
      uiCPU = atoi(argv[2]);
      uiEvents = atoi(argv[3]);
      uiLoops = atoi(argv[4]);
      uiMaxOffset = atoi(argv[5]);
    }
  }
  catch (...)
  {
    cerr << "Could not get/parse all arguments" << endl;
    cerr << "Example usage" << endl;
    cerr << argv[0] << " <<Schedule Name>> <<CPU ID>> <<Events>> <<Loops>> <<Offset/Duration [ns]>>" << endl;
    return 1;
  }

  /* Build schedule bases on arguments */
  SchedBuilder myBuilder((sName.c_str()), uiCPU, uiEvents, uiLoops, uiMaxOffset, fVerbose);
  iRet = myBuilder.BuildRandomSchedule();

  /* Done */
  return iRet;
}

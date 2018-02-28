#ifndef SCHED_BUILDER_H
#define SCHED_BUILDER_H

#include <iostream>
#include <fstream>
#include <iomanip>
#include <vector>
#include <random>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
using namespace std;

class SchedBuilderEvent
{
  public:
    SchedBuilderEvent(uint64_t uEventID, uint64_t uParameter, uint32_t uOffset);
    ~SchedBuilderEvent();
    void PrintEvent(void);
    uint64_t GetEventID(void);
    uint64_t GetParameter(void);
    uint64_t GetOffset(void);

  private:
    uint64_t m_uEventID;
    uint64_t m_uParameter;
    uint32_t m_uOffset;
};

class SchedBuilder
{
  public:
    SchedBuilder(string sName,
                 unsigned int uiCPU,
                 unsigned int uiEvents,
                 unsigned int uiLoops,
                 unsigned int uiMaxOffset,
                 bool fVerboseMode);
    ~SchedBuilder();
    int BuildRandomSchedule(void);
    void AddRandomEvent(void);
    void PrintHeader(void);
    void PrintFooter(void);
    void PrintEvents(void);
    void PrintCompareFile(void);

  private:
    vector<SchedBuilderEvent> m_vEvents;
    string m_sName;
    string m_sFileName;
    string m_sCompareName;
    unsigned int m_uiCPU;
    unsigned int m_uiGeneratedEvents;
    unsigned int m_uiLatestOffset;
    unsigned int m_uiLoops;
    unsigned int m_uiMaxOffset;
    unsigned int m_uiEvents;
    const char* m_cName;
    const char* m_cFileName;
    const char* m_cCompareName;
    bool m_fVerboseMode;
};

#endif /* SCHED_BUILDER_H */

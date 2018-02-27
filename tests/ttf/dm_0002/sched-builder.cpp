#include "sched-builder.h"

SchedBuilderEvent::SchedBuilderEvent(uint64_t uEventID, uint64_t uParameter, uint32_t uOffset): m_uEventID(uEventID), m_uParameter(uParameter), m_uOffset(uOffset) { }

SchedBuilderEvent::~SchedBuilderEvent() { }

void SchedBuilderEvent::PrintEvent(void)
{
  std::cout << "0x" << setfill('0') << std::setw(16) << std::hex << m_uEventID << "  ";
  std::cout << "0x" << setfill('0') << std::setw(16) << std::hex << m_uParameter << "  ";
  std::cout << setfill('0') << std::setw(10) << std::dec << m_uOffset << std::endl;
}

uint64_t SchedBuilderEvent::GetEventID(void) { return m_uEventID; }

uint64_t SchedBuilderEvent::GetParameter(void) { return m_uParameter; }

uint64_t SchedBuilderEvent::GetOffset(void) { return m_uOffset; }

SchedBuilder::SchedBuilder(string sName,
                          unsigned int uiCPU,
                          unsigned int uiEvents,
                          unsigned int uiLoops,
                          unsigned int uiMaxOffset,
                          bool fVerboseMode)
{
  ofstream of_file;

  /* Get parameters */
  m_uiCPU = uiCPU;
  m_sName = sName;
  m_sFileName = sName + "_cpu"  + to_string(uiCPU) + ".dot";
  m_sCompareName = sName + "_cpu" + to_string(uiCPU) + ".cmp";
  m_fVerboseMode = fVerboseMode;
  m_uiGeneratedEvents = 0;
  m_uiLatestOffset = 0;
  m_uiLoops = uiLoops;
  m_uiMaxOffset = uiMaxOffset;
  m_uiEvents = uiEvents;

  /* Get const char from file name */
  m_cName = m_sName.c_str();
  m_cFileName = m_sFileName.c_str();
  m_cCompareName = m_sCompareName.c_str();

  /* Clean file */
  of_file.open (m_cFileName);
  of_file << "";
  of_file.close();

  /* Initialize random seed */
  srand(time(NULL)+uiCPU);
}

SchedBuilder::~SchedBuilder() { }

void SchedBuilder::PrintHeader(void)
{
  ofstream of_file;

  /* Print header */
  of_file.open (m_cFileName, ios::app);
  of_file << "digraph g {" << "\n";
  of_file << "name=\"" << m_cName << "\";" << std::endl << std::endl;

  of_file << "graph []" << std::endl;
  of_file << "edge  [type=\"defdst\"]" << std::endl << std::endl;

  of_file << "subgraph cpu" << m_uiCPU << " {" << std::endl;
  of_file << "  node  [cpu=\"" << m_uiCPU << "\"];" << std::endl << std::endl;
  of_file.close();
}

void SchedBuilder::PrintFooter(void)
{
  ofstream of_file;

  /* Print footer */
  of_file.open (m_cFileName, ios::app);
  of_file << "}\n";
  of_file.close();
}

void SchedBuilder::PrintEvents(void)
{
  ofstream of_file;
  unsigned int ui_ID = 0;

  /* Print events to console */
  if (m_fVerboseMode)
  {
    std::cout << "EventID             Parameter           Offset" << std::endl;
    std::cout << "--------------------------------------------------" << std::endl;
  }
  /* Print events to file (and console) */
  of_file.open (m_cFileName, ios::app);

  /* Start event */
  of_file << "  CPU" << m_uiCPU << "_START" << " [type=\"flow\", pattern=\"" << "CPU" << m_uiCPU << "_PATTERN\"," << " patentry=\"true\",";
  of_file <<  " toffs=\"" << std::dec << 0 << "\",";
  of_file <<  " qty=\"" << std::dec << m_uiLoops << "\"];";
  of_file << std::endl;

  for (std::vector<SchedBuilderEvent>::iterator it = m_vEvents.begin() ; it != m_vEvents.end(); ++it)
  {
    if (m_fVerboseMode) { it->PrintEvent(); }

    /* Build events */
    of_file << "  CPU" << m_uiCPU << "_EVT_" << ui_ID << " [type=\"tmsg\", " << "pattern=\"" << "CPU" << m_uiCPU << "_PATTERN\",";
    of_file <<  " toffs=\"" << std::dec << it->GetOffset() << "\",";
    of_file <<  " id=\"" << "0x" << std::hex << it->GetEventID() << "\",";
    of_file <<  " par=\"" << "0x" << std::hex << it->GetParameter() << "\"];";
    of_file << std::dec << std::endl;
    ui_ID++;
  }

  /* Stop event */
  of_file <<  "  CPU" << m_uiCPU << "_STOP " << " [type=\"block\", pattern=\"" << "CPU" << m_uiCPU << "_PATTERN\",";
  of_file <<  " tperiod=\"" << std::dec << m_uiMaxOffset << "\",";
  of_file <<  " qlo=\"1\"];";
  of_file << std::endl;

  /* Build event chain */
  ui_ID = 0;
  of_file << std::endl;
  of_file << "  CPU" << m_uiCPU << "_START -> ";
  for (std::vector<SchedBuilderEvent>::iterator it = m_vEvents.begin() ; it != m_vEvents.end(); ++it)
  {
    of_file << "CPU" << m_uiCPU << "_EVT_" << ui_ID;
    if (ui_ID < m_uiGeneratedEvents) { of_file << " -> "; }
    ui_ID++;
  }
  of_file << "CPU" << m_uiCPU << "_STOP";
  of_file << ";";
  of_file << std::endl;

  /* Create control loop */
  of_file << "  CPU" << m_uiCPU << "_STOP -> " << "CPU" << m_uiCPU << "_EVT_0 [type=\"altdst\"];" << std::endl;
  of_file << "  CPU" << m_uiCPU << "_START -> " << "CPU" << m_uiCPU << "_STOP [type=\"target\"];" << std::endl;
  of_file << "  CPU" << m_uiCPU << "_START -> " << "CPU" << m_uiCPU << "_EVT_0 [type=\"flowdst\"];" << std::endl;
  of_file << std::endl;
  of_file << "  }" << std::endl << std::endl;

  of_file.close();
}

void SchedBuilder::AddRandomEvent(void)
{
  uint64_t uEventID = 0;
  uint64_t uParameter = 0;
  uint32_t uOffset = 0;
  uint32_t uOffsetMin = 0;
  uint32_t uOffsetMax = 0;
  uint32_t uAvoidEndlessCalc = 0;

  /* Generate event ID and parameter */
  uOffsetMin = m_uiLatestOffset;
  //if (m_uiEvents > 1) { uOffsetMax = m_uiLatestOffset+(m_uiMaxOffset/(m_uiEvents/2)); }
  if (m_uiEvents > 1)
  {
    do { uOffsetMax = m_uiLatestOffset+(m_uiMaxOffset/m_uiEvents); }
    while (uOffsetMax >= m_uiMaxOffset); /* Ugly fix for """random""" distribution */
  }
  else { uOffsetMax = m_uiMaxOffset/m_uiEvents; }
  uEventID = ( (uint64_t(rand())<<32) ) xor uint64_t(rand()); srand(rand());
  uParameter = ( (uint64_t(rand())<<32) ) xor uint64_t(rand()); srand(rand());
  do
  {
    uOffset = ((rand() % (m_uiMaxOffset-1)));
    srand(rand());
    if (uAvoidEndlessCalc> 1000) { uOffset = uOffsetMax; }
    else                         { uAvoidEndlessCalc++; }
  }
  while ((uOffset < uOffsetMin) || (uOffset > uOffsetMax));
  m_uiLatestOffset = uOffset;

  /* Setup format ID to 0 */
  uEventID = uEventID & 0x0fffffffffffffff;

  /* Insert event */
  m_vEvents.push_back(SchedBuilderEvent(uEventID, uParameter, uOffset));
  m_uiGeneratedEvents++;
}

int SchedBuilder::BuildRandomSchedule(void)
{
  unsigned int uiCnt = 0;

  /* Create Schedule */
  for (uiCnt = 0; uiCnt < m_uiEvents; uiCnt++) { AddRandomEvent(); }
  PrintHeader();
  PrintEvents();
  PrintFooter();
  PrintCompareFile();

  /* Done */
  return 0;
}

void SchedBuilder::PrintCompareFile(void)
{
  ofstream of_file;

  /* Print offset, event id, and parameter */
  of_file.open (m_sCompareName);
  for (std::vector<SchedBuilderEvent>::iterator it = m_vEvents.begin() ; it != m_vEvents.end(); ++it)
  {
    of_file << "0x" << setfill('0') << std::setw(16) << std::hex << it->GetOffset() << " ";
    of_file << "0x" << setfill('0') << std::setw(16) << std::hex << it->GetEventID() << " ";
    of_file << "0x" << setfill('0') << std::setw(16) << std::hex << it->GetParameter() << endl;
  }
  of_file.close();
}

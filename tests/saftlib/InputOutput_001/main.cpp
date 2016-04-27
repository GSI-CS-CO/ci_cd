/* Synopsis */
/* ==================================================================================================== */
/* Simple test application for IOs and ECA */

/* Defines */
/* ==================================================================================================== */
#define __STDC_FORMAT_MACROS
#define __STDC_CONSTANT_MACROS
#define ECA_EVENT_ID   UINT64_C(0xffff000000000000)
#define ECA_EVENT_MASK UINT64_C(0xffff000000000000)

/* Includes */
/* ==================================================================================================== */
#include <stdio.h>
#include <iostream>
#include <giomm.h>
#include <inttypes.h>

#include <SAFTd.h>
#include <TimingReceiver.h>
#include <Output.h>
#include <Input.h>
#include <SoftwareActionSink.h>
#include <SoftwareCondition.h>

/* Globals */
/* ==================================================================================================== */
static const char *deviceName = NULL; /* Name of the device */
static const char *inputName  = NULL; /* Name of the input */
static const char *outputName = NULL; /* Name of the output */

/* Types */
/* ==================================================================================================== */
typedef struct s_IOToggle
{
  guint64 HighOffset;
  guint64 LowOffset;
} t_IOToggle;

/* Namespaces */
/* ==================================================================================================== */
using namespace saftlib;
using namespace std;



static void catch_input(guint64 event, guint64 param, guint64 deadline, guint64 executed, guint16 flags)
{
  guint64 time = deadline - 5000;
  guint64 ns    = time % 1000000000;
  time_t  s     = time / 1000000000;
  struct tm *tm = gmtime(&s);
  char date[40];
  static char full[80];
  
  strftime(date, sizeof(date), "%Y-%m-%d %H:%M:%S", tm);
  snprintf(full, sizeof(full), "%s.%09ld", date, (long)ns);
  
  std::cout << inputName << " went " << ((event&1)?"high":"low ") << " at " << date << full << std::endl;
}






/* Function main() */
/* ==================================================================================================== */
int main (int argc, char** argv)
{
  /* Helper */
  guint64 wrTime = 0L;
  bool output_found = false;
  bool input_found = false;
  
  /* Evaluate arguments */
  if (argc == 4)
  {
    deviceName = argv[1];
    inputName  = argv[2];
    outputName = argv[3];
  }
  else
  {
    std::cerr << "Usage: <application> <unique device name> <input> <output>" << std::endl;
    std::cerr << "Example: baseboard IO1 IO2" << std::endl;
    return -1;
  }
  
  /* Initialize Glib stuff */
  Gio::init();
  Glib::RefPtr<Glib::MainLoop> loop = Glib::MainLoop::create();
  
  /* Try to connect to saftd */
  try 
  {
    /* Confirm device exists */
    map<Glib::ustring, Glib::ustring> devices = SAFTd_Proxy::create()->getDevices();
    if (devices.find(deviceName) == devices.end()) 
    {
      std::cerr << "Device '" << deviceName << "' does not exist!" << std::endl;
      return -1;
    }
    Glib::RefPtr<TimingReceiver_Proxy> receiver = TimingReceiver_Proxy::create(devices[deviceName]);
    
    /* Alive check */
    wrTime = receiver->ReadCurrentTime();
    std::cout << "White Rabbit Time: 0x" << std::hex << wrTime << std::dec << std::endl;
    
    /* Search for IO names */
    std::map< Glib::ustring, Glib::ustring > outs;
    std::map< Glib::ustring, Glib::ustring > ins;
    Glib::ustring io_path;
    Glib::ustring io_partner;
    outs = receiver->getOutputs();
    ins = receiver->getInputs();
    Glib::RefPtr<Output_Proxy> output_proxy;
    Glib::RefPtr<Input_Proxy> input_proxy;
    Glib::RefPtr<Output_Proxy> output_proxy_partner;
    Glib::RefPtr<Input_Proxy> input_proxy_partner;
    
    /* Configure input */
    for (std::map<Glib::ustring,Glib::ustring>::iterator it=ins.begin(); it!=ins.end(); ++it)
    {
      if (it->first == inputName) 
      { 
        /* Get input */
        input_proxy = Input_Proxy::create(it->second);
        /* Set input enable if available */
        if (input_proxy->getInputTerminationAvailable()) { input_proxy->setInputTermination(true); }
        /* Turn off output enable if the IO is bidirectional */
        io_partner = input_proxy->getOutput();
        if (io_partner != "")
        {
          output_proxy_partner = Output_Proxy::create(io_partner);
          if (output_proxy_partner->getOutputEnableAvailable()) { output_proxy_partner->setOutputEnable(false); }
        }
        input_found = true;
      }
    }
    if (!input_found)
    { 
      std::cerr << "Input '" << inputName << "' does not exist!" << std::endl; 
      return -1;
    }
    
    /* Configure output */
    for (std::map<Glib::ustring,Glib::ustring>::iterator it=outs.begin(); it!=outs.end(); ++it)
    {
      if (it->first == outputName) 
      { 
        /* Get output */
        output_proxy = Output_Proxy::create(it->second);
        /* Set output enable if available */
        if (output_proxy->getOutputEnableAvailable()) { output_proxy->setOutputEnable(true); }
        /* Turn off output enable if the IO is bidirectional */
        io_partner = output_proxy->getInput();
        if (io_partner != "")
        {
          input_proxy_partner = Input_Proxy::create(io_partner);
          if (input_proxy_partner->getInputTerminationAvailable()) { input_proxy_partner->setInputTermination(false); }
        }
        output_found = true;
      }
    }
    if (!output_found)
    { 
      std::cerr << "Output '" << outputName << "' does not exist!" << std::endl; 
      return -1;
    }

    guint64 prefix = UINT64_C(0xfffe000000000000) + (random() << 1);
    // Create a SoftwareCondition to catch the event
    Glib::RefPtr<SoftwareActionSink_Proxy> sas = SoftwareActionSink_Proxy::create(receiver->NewSoftwareActionSink(""));
    Glib::RefPtr<SoftwareCondition_Proxy> cond = SoftwareCondition_Proxy::create(sas->NewCondition(true, prefix, -2, 5000));
    cond->Action.connect(sigc::ptr_fun(&catch_input));
    
    // Setup the event
    Glib::RefPtr<Input_Proxy> input = Input_Proxy::create(ins[inputName]);
    input->setInputTermination(true);
    input->setEventEnable(false);
    input->setEventPrefix(prefix);
    input->setEventEnable(true);
    
    Glib::ustring output_path = input->getOutput();
    if (output_path != "") {
      Glib::RefPtr<Output_Proxy> output = Output_Proxy::create(output_path);
      output->setOutputEnable(false);
    }
    

    
    /* Configure ECA and run */
    output_proxy->NewCondition(true, ECA_EVENT_ID, ECA_EVENT_MASK, 0,         true); 
    output_proxy->NewCondition(true, ECA_EVENT_ID, ECA_EVENT_MASK, 100000000, false);
    output_proxy->NewCondition(true, ECA_EVENT_ID, ECA_EVENT_MASK, 200000000, true); 
    output_proxy->NewCondition(true, ECA_EVENT_ID, ECA_EVENT_MASK, 300000000, false);
    
    /* Trigger events */
    wrTime = receiver->ReadCurrentTime() +1000000000L;
    receiver->InjectEvent(ECA_EVENT_ID, 0x00000000, wrTime);
    
    // run the loop printing IO events
    loop->run();
    
  }
  catch (const Glib::Error& error)
  {
    std::cerr << "Failed to invoke method: " << error.what() << std::endl;
  }
  
  /* Done */
  return 0;
}

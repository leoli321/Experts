//+------------------------------------------------------------------+
//|                                                  PanelDialog.mqh |
//|                   Copyright 2009-2015, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\ListView.mqh>
#include <Controls\ComboBox.mqh>
#include <Controls\SpinEdit.mqh>
#include <Controls\RadioGroup.mqh>
#include <Controls\CheckGroup.mqh>
#include <Controls\Label.mqh>

extern int   Lots = 1;
extern int   EnableInd = 0;
extern int   EnableKReverse = 0;
extern int   EnableDayClose = 0;
int     KTradeMode = -1;
int     TradeDirection = 0;
bool    Immediate = false;
string  msg = "";
int     command = -1;
datetime KTradeModeTime = 0;
string KTradeModeStr[3] = {"No","Buy","Sell"};
   
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
//--- indents and gaps
#define INDENT_LEFT                         (11)      // indent from left (with allowance for border width)
#define INDENT_TOP                          (11)      // indent from top (with allowance for border width)
#define INDENT_RIGHT                        (11)      // indent from right (with allowance for border width)
#define INDENT_BOTTOM                       (41)      // indent from bottom (with allowance for border width)
#define CONTROLS_GAP_X                      (10)      // gap by X coordinate
#define CONTROLS_GAP_Y                      (10)      // gap by Y coordinate
//--- for buttons
#define BUTTON_WIDTH                        (100)     // size by X coordinate
#define BUTTON_HEIGHT                       (20)      // size by Y coordinate
//--- for the indication area
#define EDIT_HEIGHT                         (20)      // size by Y coordinate
#define RADIO_HEIGHT                        (45)       
//+------------------------------------------------------------------+
//| Class CPanelDialog                                               |
//| Usage: main dialog of the SimplePanel application                |
//+------------------------------------------------------------------+
class CPanelDialog : public CAppDialog
  {
private:
   CEdit             m_edit;                          // the display field object
   CEdit             m_edit_price;                  
   CEdit             m_edit_takeprofit;
   CButton           m_button1;                       // the button object
   CButton           m_button2;                       // the button object
   CButton           m_button3;                       // the fixed button object
   CButton           m_button4;
   CButton           m_button5;
   CListView         m_list_view;                     // the list object
   CRadioGroup       m_radio_group;                   // the radio buttons group object
   CRadioGroup       m_radio_group2;                   // the radio buttons group object
   CCheckGroup       m_check_group;                   // the check box group object
   CLabel            m_label;
   CLabel            m_label2;
public:
                     CPanelDialog(void);
                    ~CPanelDialog(void);
   //--- create
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   //--- chart event handler
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);

protected:
   //--- create dependent controls
   bool              CreateLabel(void);   
   bool              CreateEdit(void);
   bool              CreateButton1(void);
   bool              CreateButton2(void);
   bool              CreateButton3(void);
   bool              CreateButton4(void);
   bool              CreateRadioGroup(void);
   bool              CreateRadioGroup2(void);
   bool              CreateCheckGroup(void);
   bool              CreateListView(void);
   //--- internal event handlers
   virtual bool      OnResize(void);
   //--- handlers of the dependent controls events
   void              OnClickButton1(void);
   void              OnClickButton2(void);
   void              OnClickButton3(void);
   void              OnClickButton4(void);
   void              OnClickButton5(void);
   void              OnChangeRadioGroup(void);
   void              OnChangeRadioGroup2(void);
   void              OnChangeCheckGroup(void);
   void              OnChangeListView(void);
   bool              OnDefault(const int id,const long &lparam,const double &dparam,const string &sparam);
public:
   void              UpdateKTradeMode();  
   void              UpdateLabel(string msg); 
   double            GetOpenPrice();
   double            GetTakeProfit();
  };
//+------------------------------------------------------------------+
//| Event Handling                                                   |
//+------------------------------------------------------------------+
EVENT_MAP_BEGIN(CPanelDialog)
ON_EVENT(ON_CLICK,m_button1,OnClickButton1)
ON_EVENT(ON_CLICK,m_button2,OnClickButton2)
ON_EVENT(ON_CLICK,m_button3,OnClickButton3)
ON_EVENT(ON_CLICK,m_button4,OnClickButton4)
ON_EVENT(ON_CLICK,m_button5,OnClickButton5)
ON_EVENT(ON_CHANGE,m_radio_group,OnChangeRadioGroup)
ON_EVENT(ON_CHANGE,m_radio_group2,OnChangeRadioGroup2)
ON_EVENT(ON_CHANGE,m_check_group,OnChangeCheckGroup)
ON_EVENT(ON_CHANGE,m_list_view,OnChangeListView)
ON_OTHER_EVENTS(OnDefault)
EVENT_MAP_END(CAppDialog)
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPanelDialog::CPanelDialog(void)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPanelDialog::~CPanelDialog(void)
  {
  }
//+------------------------------------------------------------------+
//| Create                                                           |
//+------------------------------------------------------------------+
bool CPanelDialog::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
      return(false);
//--- create dependent controls
   if(!CreateLabel())
      return(false);
   if(!CreateEdit())
      return(false);
   if(!CreateButton1())
      return(false);
   if(!CreateButton2())
      return(false);
   if(!CreateButton3())
      return(false);
   if(!CreateButton4())
      return(false);
   if(!CreateRadioGroup())
      return(false);
   if(!CreateRadioGroup2())
      return(false);
   if(!CreateCheckGroup())
      return(false);
   if(!CreateListView())
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the display Label                                         |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateLabel(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP;
   int x2=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_label.Create(m_chart_id,m_name+"Label",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_label))
      return(false);
   m_label.Alignment(WND_ALIGN_WIDTH,INDENT_LEFT,0,INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X,0);
   m_label.Text("Semi-auto trade system started.");
//--- succeed
   x2 = x1 + BUTTON_WIDTH;
   y1=ClientAreaHeight()-(INDENT_BOTTOM) + CONTROLS_GAP_Y;
   y2=y1+EDIT_HEIGHT;
   if(!m_label2.Create(m_chart_id,m_name+"Label2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_label2))
      return(false);
   m_label2.Text("OpenPrice / TakeProfit :");
   return(true);
  } 
  
void CPanelDialog::UpdateLabel(string newmsg)
{
   m_label.Text(newmsg);
}

//+------------------------------------------------------------------+
//| Create the display field                                         |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateEdit(void)
  {
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+EDIT_HEIGHT;
   int x2=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
   int y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_edit.Create(m_chart_id,m_name+"Edit",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_edit.ReadOnly(true))
      return(false);
   if(!Add(m_edit))
      return(false);
   m_edit.Alignment(WND_ALIGN_WIDTH,INDENT_LEFT,0,INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X,0);
//--- succeed
//--- coordinates
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   x1=INDENT_LEFT+sx+CONTROLS_GAP_X;
   x2=x1+sx;
   y1=ClientAreaHeight()-(INDENT_BOTTOM) + CONTROLS_GAP_Y;
   y2=y1+EDIT_HEIGHT;
//--- create
   if(!m_edit_price.Create(m_chart_id,m_name+"EditPrice",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_edit_price))
      return(false);
//--- coordinates
   sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   x1=ClientAreaWidth()-(sx+INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
   x2=x1+sx;
//--- create
   if(!m_edit_takeprofit.Create(m_chart_id,m_name+"EditTakeProfit",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_edit_takeprofit))
      return(false);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button1" button                                      |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton1(void)
  {
//--- coordinates
   int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
   int y1=INDENT_TOP;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button1.Create(m_chart_id,m_name+"Button1",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button1.Text("KTrade Now"))
      return(false);
   if(!Add(m_button1))
      return(false);
   m_button1.Alignment(WND_ALIGN_RIGHT,0,0,INDENT_RIGHT,0);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button2" button                                      |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton2(void)
  {
//--- coordinates
   int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
   int y1=INDENT_TOP+BUTTON_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button2.Create(m_chart_id,m_name+"Button2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button2.Text("Close All"))
      return(false);
   if(!Add(m_button2))
      return(false);
   m_button2.Alignment(WND_ALIGN_RIGHT,0,0,INDENT_RIGHT,0);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button3" fixed button                                |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton3(void)
  {
//--- coordinates
   int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
   int y1=ClientAreaHeight()-(INDENT_BOTTOM+BUTTON_HEIGHT);
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button3.Create(m_chart_id,m_name+"Button3",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button3.Text("Add Position"))
      return(false);
   if(!Add(m_button3))
      return(false);
   //m_button3.Locking(true);
   m_button3.Alignment(WND_ALIGN_RIGHT|WND_ALIGN_BOTTOM,0,0,INDENT_RIGHT,INDENT_BOTTOM);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "Button4" fixed button                                |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateButton4(void)
  {
//--- coordinates
   int x1=ClientAreaWidth()-(INDENT_RIGHT+BUTTON_WIDTH);
   int y1=INDENT_TOP+2*BUTTON_HEIGHT+2*CONTROLS_GAP_Y;
   int x2=x1+BUTTON_WIDTH;
   int y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button4.Create(m_chart_id,m_name+"Button4",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button4.Text("Print Log"))
      return(false);
   if(!Add(m_button4))
      return(false);
   m_button4.Alignment(WND_ALIGN_RIGHT|WND_ALIGN_BOTTOM,0,0,INDENT_RIGHT,INDENT_BOTTOM);
//--- succeed
//--- coordinates
   y1=ClientAreaHeight()-(INDENT_BOTTOM) + CONTROLS_GAP_Y;
   y2=y1+BUTTON_HEIGHT;
//--- create
   if(!m_button5.Create(m_chart_id,m_name+"Button5",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!m_button5.Text("Add Grid"))
      return(false);
   if(!Add(m_button5))
      return(false);
   m_button5.Alignment(WND_ALIGN_RIGHT|WND_ALIGN_BOTTOM,0,0,INDENT_RIGHT,INDENT_BOTTOM);
//--- succeed
   return(true);
  }  
//+------------------------------------------------------------------+
//| Create the "RadioGroup" element                                  |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateRadioGroup(void)
  {
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   int x1=INDENT_LEFT;
   int y1=INDENT_TOP+EDIT_HEIGHT*2+CONTROLS_GAP_Y;
   int x2=x1+sx;
   int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
   if(!m_radio_group.Create(m_chart_id,m_name+"RadioGroup",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_radio_group))
      return(false);
   m_radio_group.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
   for(int i=0;i<3;i++)
      if(!m_radio_group.AddItem("KTradeMode:"+KTradeModeStr[i],i-1))
         return(false);
   m_radio_group.Value(KTradeMode);
//--- succeed
   return(true);
  }
  //+------------------------------------------------------------------+
//| Create the "RadioGroup" element                                  |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateRadioGroup2(void)
  {
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   int x1=INDENT_LEFT+sx+CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT*2+CONTROLS_GAP_Y;
   int x2=x1+sx;
   int y2=y1 + RADIO_HEIGHT; //ClientAreaHeight()-INDENT_BOTTOM;
//--- create
   if(!m_radio_group2.Create(m_chart_id,m_name+"RadioGroup2",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_radio_group2))
      return(false);
   m_radio_group2.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
   for(int i=0;i<2;i++)
      if(!m_radio_group2.AddItem("Trade as:"+KTradeModeStr[i+1],i))
         return(false);
   m_radio_group2.Value(TradeDirection);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "CheckGroup" element                                  |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateCheckGroup(void)
  {
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   int x1=INDENT_LEFT+sx+CONTROLS_GAP_X;
   int y1=INDENT_TOP+EDIT_HEIGHT*2+CONTROLS_GAP_Y+RADIO_HEIGHT+CONTROLS_GAP_Y;
   int x2=x1+sx;
   int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
   if(!m_check_group.Create(m_chart_id,m_name+"CheckGroup",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_check_group))
      return(false);
   m_check_group.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
   if(!m_check_group.AddItem("Enable Indicators",0))
         return(false);
   if(!m_check_group.AddItem("Enable KReverse",0))
         return(false);
   if(!m_check_group.AddItem("Enable DayClose",0))
         return(false);
   if( EnableInd == 1) m_check_group.Check(0, 1);
   if( EnableKReverse == 1) m_check_group.Check(1, 1);
   if( EnableDayClose == 1) m_check_group.Check(2, 1);

//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Create the "ListView" element                                    |
//+------------------------------------------------------------------+
bool CPanelDialog::CreateListView(void)
  {
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- coordinates
   int x1=ClientAreaWidth()-(sx+INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
   int y1=INDENT_TOP+EDIT_HEIGHT*2+CONTROLS_GAP_Y;
   int x2=x1+sx;
   int y2=ClientAreaHeight()-INDENT_BOTTOM;
//--- create
   if(!m_list_view.Create(m_chart_id,m_name+"ListView",m_subwin,x1,y1,x2,y2))
      return(false);
   if(!Add(m_list_view))
      return(false);
   m_list_view.Alignment(WND_ALIGN_HEIGHT,0,y1,0,INDENT_BOTTOM);
//--- fill out with strings
   for(int i=2;i<=6;i++)
      if(!m_list_view.ItemAdd("Lots="+IntegerToString(i), i))
         return(false);
   m_list_view.SelectByValue(Lots);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Handler of resizing                                              |
//+------------------------------------------------------------------+
bool CPanelDialog::OnResize(void)
  {
//--- call method of parent class
   if(!CAppDialog::OnResize()) return(false);
//--- coordinates
   int x=ClientAreaLeft()+INDENT_LEFT;
   int y=m_radio_group.Top();
   int sx=(ClientAreaWidth()-(INDENT_LEFT+INDENT_RIGHT+BUTTON_WIDTH))/3-CONTROLS_GAP_X;
//--- move and resize the "RadioGroup" element
   m_radio_group.Move(x,y);
   m_radio_group.Width(sx);
//--- move and resize the "CheckGroup" element
   x=ClientAreaLeft()+INDENT_LEFT+sx+CONTROLS_GAP_X;
   m_check_group.Move(x,y);
   m_check_group.Width(sx);
//--- move and resize the "ListView" element
   x=ClientAreaLeft()+ClientAreaWidth()-(sx+INDENT_RIGHT+BUTTON_WIDTH+CONTROLS_GAP_X);
   m_list_view.Move(x,y);
   m_list_view.Width(sx);
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton1(void)
  {
   m_edit.Text("Button [Trade Now] clicked.");
   Immediate = true;
   msg = "Get new instruction: Trade Now.";
   m_label.Text(msg);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton2(void)
  {
   m_edit.Text("Button [Close All] clicked.");
   msg = "Get new instruction: Close All.";
   m_label.Text(msg);
   command = 1;
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton3(void)
  {
   m_edit.Text("Button [Add Position] clicked.");
   msg = "Get new instruction: Add Position.";
   m_label.Text(msg);
   command = 2;
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnClickButton4(void)
  {
   m_edit.Text("Button [Print Log] clicked.");
   msg = "Get new instruction: Print Log.";
   m_label.Text(msg);
   command = 0;
  }  
void CPanelDialog::OnClickButton5(void)
  {
   m_edit.Text("Button [Add Grid] clicked.");
   msg = "Get new instruction: Add Grid.";
   m_label.Text(msg);
   command = 3;
  } 
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeListView(void)
  {
   Lots = m_list_view.Value();
   m_edit.Text("Lots set to "+Lots);
  }
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeRadioGroup(void)
  {
   KTradeMode = m_radio_group.Value();
   KTradeModeTime = TimeCurrent();
   m_edit.Text("KTradeMode set to "+KTradeModeStr[m_radio_group.Value()+1]+" at "+TimeToStr(KTradeModeTime));
  }

void CPanelDialog::OnChangeRadioGroup2(void)
  {
   TradeDirection = m_radio_group2.Value();
   m_edit.Text("Trade set to "+KTradeModeStr[m_radio_group2.Value()+1]);
  }
    
void CPanelDialog::UpdateKTradeMode(void)
  {
   KTradeModeTime = 0;
   m_radio_group.Value(KTradeMode);
   //m_radio_group.Redraw();
   m_edit.Text("KTradeMode="+IntegerToString(m_radio_group.Value()));
   m_label.Text(msg);
  }  
//+------------------------------------------------------------------+
//| Event handler                                                    |
//+------------------------------------------------------------------+
void CPanelDialog::OnChangeCheckGroup(void)
  {
   int newvalue = m_check_group.Check(0);
   if( EnableInd != newvalue) 
   {
      EnableInd = newvalue;
      m_edit.Text("Enable Indicators set to "+EnableInd);
   }
   newvalue = m_check_group.Check(1);
   if( EnableKReverse != newvalue) 
   {
      EnableKReverse = newvalue;
      m_edit.Text("EnableKReverse set to "+EnableKReverse);
   }
   newvalue = m_check_group.Check(2);
   if( EnableDayClose != newvalue) 
   {
      EnableDayClose = newvalue;
      m_edit.Text("EnableDayClose set to "+EnableDayClose);
   }
  }
 double CPanelDialog::GetOpenPrice(void)
  {
      string s = m_edit_price.Text();  
      return(StringToDouble(s));
  }
  double CPanelDialog::GetTakeProfit(void)
  {
      string s = m_edit_takeprofit.Text();  
      return(StringToDouble(s));
  }
//+------------------------------------------------------------------+
//| Rest events handler                                                    |
//+------------------------------------------------------------------+
bool CPanelDialog::OnDefault(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
//--- restore buttons' states after mouse move'n'click
   if(id==CHARTEVENT_CLICK)
      m_radio_group.RedrawButtonStates();
//--- let's handle event by parent
   return(false);
  }
//+------------------------------------------------------------------+

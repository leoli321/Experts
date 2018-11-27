//+------------------------------------------------------------------+
//|                                      DragTrade_Example_v_1.0.mq4 |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2009, TheXpert"
#property link      "theforexpert@gmail.com"

extern int      Magic          = -1;
extern int      EAMagic        = 1234;
extern int      TimesToRepeat  = 3;
extern int      Slippage       = 3;

#include <DragTrade_v_1.0/DragTradeLib_v_1.0.mqh>

bool Testing;

int init()
{
   Testing = IsTesting();

   DragTrade_Init(Magic, EAMagic, TimesToRepeat, Slippage, "Drag Trade Example");

   Comment_("Test Example of using Drag Trade Library");

   return(0);
}

int deinit()
{
   DragTrade_Deinit();
   return(0);
}

int start()
{
   if (Testing)
   {
      DragTrade_Start();
   }
   else
   {
      while (!IsStopped())
      {
         RefreshRates();
         
         DragTrade_Start();
         Sleep(200);
      }
   }
   
   return(0);
}
//+------------------------------------------------------------------+
//| MACD and Break Line                                              +
//+------------------------------------------------------------------+
#property copyright   "2015 michael"
#property link        "For M15"

#include <7common.mqh>

input double TakeProfit    =100;
input double StopLoss      =100;
input double Lots          =0.1;
input int    maxOrders     = 1;

extern int       FastMAPeriod=60;
extern int       SlowMAPeriod=130;
extern int       SignalMAPeriod=45;
extern int       Roc1 = 160;
extern int       Roc2 = 280;
extern double       MACDOpenLevel = 3;
extern int       Test = 0;
//------
#define MAGICMA  20151112
string EAName = "mymacd-M15-v0.1";
//must be global to use continually
datetime     cur = 0;
datetime     pt = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop)
   if(TimeCurrent() - cur <  Period()*60 - 30) return;
   cur = TimeCurrent();
//--- to simplify the coding and speed up access data are put into internal variables
   double sig;
   //for( int k = 0; k <= 10; k++)
   int k = 6;
   {
      sig = iCustom(Symbol(), 0, "MACD_2Line", FastMAPeriod, SlowMAPeriod, SignalMAPeriod, Roc1, Roc2, MACDOpenLevel, 4, k);
      //if( sig != EMPTY_VALUE && sig >= 0 ) break;
   }
   int op = -1;
   if( sig != EMPTY_VALUE && sig >= 0){
      if( sig == 0 || sig == 2*Point*100) op = 0;
      else op = 1;
   }
   if( sig >= 0 && TimeCurrent() - pt > 60){
      Print("op=",op,"k=",k,"sig=",sig,"@",TimeToStr(Time[0]));
      pt = TimeCurrent();
   }
   
   double lots = Lots;
   int mag = MAGICMA;
   if( op != -1 ) 
   {
      int t = GetLastOrder(mag, OP_SELL);
      string s[2];
      s[0] = EAName+"逢低买入";
      s[1] = EAName+"逢高卖出";
      if( t != -1){
         if( OrderType() == OP_SELL && sig == 2*Point*100) CloseOrder(t, op);
         else if( OrderType() == OP_BUY && sig == 3*Point*100) CloseOrder(t, op);
      }
      if( GetTotalOrders(mag, OP_SELL) < maxOrders)
      {
         t = GetLastOrder(mag, OP_SELL);
         if( t != -1 ){
            if( checkProfitOrders(mag) == False) CloseOrder(t, op);
            //add position
            OpenOrder(op, lots, -StopLoss, TakeProfit, mag, s[op],2);
         }
         else{
            t = getHistoryOrder(mag, -1);
            int factor = 1;
            if( t >= 0 && MathAbs(StopLoss + OrderProfit()) < 10) factor = 2;
            if( !( t >= 0 && op == OrderType())) 
               OpenOrder(op, lots*factor, -StopLoss, TakeProfit*factor, mag, s[op],2); //new position
         }
      }
      //Print(s[op],"op=",op,"sig=",sig,"lots=",lots);
   }
   
}

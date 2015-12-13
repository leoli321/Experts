//+------------------------------------------------------------------+
//| MACD and Break Line                                              +
//+------------------------------------------------------------------+
#property copyright   "2015 (c) michael"
#property link        "michaelitg@outlook.com"

#include <7common.mqh>

input double TakeProfit    = 100;
input double StopLoss      = 200;
input double Lots          = 0.1;
input int    maxOrders     = 1;
input int    bband         = 100;
input double factor1       = 1.4;
input double factor2       = 2;

extern int       FastMAPeriod=60;
extern int       SlowMAPeriod=130;
extern int       SignalMAPeriod=45;
extern int       Roc1 = 160;
extern int       Roc2 = 280;
extern double    MACDOpenLevel = 9;

//------
#define MAGICMA  20151112
string EAName = "mymacd-H1-v0.1";
//must be global to use continually
datetime     cur = 0;
datetime     pt = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   if(TimeCurrent() - cur <  Period()*60 - 30) return;
   cur = TimeCurrent();
   
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
   /*
   if( sig >= 0 && TimeCurrent() - pt > 60){
      Print("op=",op,"k=",k,"sig=",sig,"@",TimeToStr(Time[0]));
      pt = TimeCurrent();
   }
   */
   double lots = Lots;
   int mag = MAGICMA;
   if( op != -1 && getHistoryOrder( mag, 4)<0 ) //如果有单子刚刚平仓，则等待
   {
      double factor = 1;
      int t = GetLastOrder(mag, OP_SELL);
      string s[2];
      s[0] = EAName+"逢低买入";
      s[1] = EAName+"逢高卖出";
      if( t != -1){
         //有反向信号，判断持仓是否应该平掉。如果平掉同时增大新仓的参数
         double b=iBands(Symbol(),0,bband,2,0,PRICE_CLOSE,MODE_MAIN,0);
         if( OrderProfit() < 0 && ((OrderType() == OP_BUY && op == 1 && Ask < b) || (OrderType() == OP_SELL && op == 0 && Ask > b))){  //b is necessary
            CloseOrder(t, op);
            factor = factor1;
         }
         
      }
      if( GetTotalOrders(mag, OP_SELL) < maxOrders)
      {
            t = GetLastOrder(mag, OP_SELL);
            if( t != -1 && maxOrders > 1 ){  //多仓位系统，暂时放着
               //if( checkProfitOrders(mag) == False) CloseOrder2(mag, 4); //CloseOrder(t, op);
               //add position
               //OpenOrder(op, lots, -StopLoss, TakeProfit, mag, s[op],0);
            }
            else{
               t = getHistoryOrder(mag, -1); //获取最后一个平仓的单子
               if( OrderLots() <= Lots || CurTime() - OrderCloseTime() > 48 * Period() * 60 ) //如果最后平仓的是大幅亏损的单子，则必须冷静一段时间
               {
                  if( t >= 0 && MathAbs(OrderClosePrice()- OrderStopLoss()) < 20*Point && op != OrderType() && CurTime() - OrderCloseTime() < 48 * 4 * Period() * 60) 
                  //如果是止损单，而且相隔不超过2天，则加大新仓参数
                           factor = factor2;
                  int hp = checkHistoryOrder(mag);
                  if( MathAbs(hp) >= 3 && MathAbs(hp) < 5){   //如果连续亏损超过3次，但没有到5次，则把信号反过来，同时加大参数
                     if( op == 0) op = 1; else op = 0; 
                     //getHistoryOrder(mag, -1);
                     //op = 1 - OrderType();
                     factor = factor2;}
                  if( MathAbs(hp) < 5 || getHistoryOrder( mag, 48*4)< 0 ) //如果连续亏损超过5次，则也必须冷静一段时间
                     OpenOrder(op, lots*factor, -StopLoss, TakeProfit*factor, mag, s[op],0); //new position
               }
            }
      }
      //Print(s[op],"op=",op,"sig=",sig,"lots=",lots);
   }
   
}

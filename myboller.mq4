//+------------------------------------------------------------------+
//| MACD and Break Line                                              +
//+------------------------------------------------------------------+
#property copyright   "2016 michael"
#property link        "http://www.mql4.com"

#include<stdlib.mqh>
/*
半自动系统，用于Boller线上下轨自动挂单，复合仓交易。核心思想是从波段追趋势。
平仓后重新挂
*/

//----
extern int    orderdirection = 2;  //0 - buy 1 - sell 2 - all
extern int    UseMidAsUporDown = 0;  //1 - upper 2 -- lower
extern int    band = 20;
extern int    TakeProfit = 0;
extern int    StopLoss = 80;
extern double Lots = 4;
extern double PriceChange = 3;
extern int    StepUpper = 3;
extern int    StepLower = 3;
extern string Filter1 = "-----Filter 1 width--------------";
extern double MinWidth = 0;

//------
int MagicBuy = 211010;
int MagicSell = 211040;
int glbOrderType[100];
int glbOrderTicket[100];

//must be global to use continually
datetime     pt = 0;

void init()
{
   if( Period() < 15) band *= 4;
   else if( Period() < 60) band *= 2;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   Comment("myboller v0.13 1/8/2016 band=", band, " orderdirection=", orderdirection);
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop)
   RefreshRates();
   //if(TimeCurrent() - Time[0] <  Period()*60 - 30) return;
   OpenTrade();
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//获取OP_BUY或OP_BUY_LIMIT或OP_BUY_STOP
int GetTotalOrders(int mag, int oType)
{
   int totalOrders = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if( OrderType() == oType || OrderType() == oType + 2 || OrderType() == oType + 4)
      {
         glbOrderType[totalOrders] = OrderType();
         glbOrderTicket[totalOrders] = OrderTicket();
         totalOrders++;
      }
     }
     return(totalOrders);
}

int CloseOrders(int mag)
{
   int totalOrders = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      {
         glbOrderTicket[totalOrders++] = OrderTicket();
      }
     }
     for(i=0;i<totalOrders;i++)
     {
      if(OrderSelect( glbOrderTicket[i], SELECT_BY_POS,MODE_TRADES)==false) break;
      if (OrderType() == OP_BUY) {
            if( OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 30, White)  == false) 
            Print("Err (", GetLastError(), ") when close buy order ",OrderTicket());
            Sleep(500);
      }
      else{
         if (OrderType() == OP_SELL) {
               if( OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 30, White) == false)
                Print("Err (", GetLastError(), ") when close sell order ",OrderTicket());
               Sleep(500);
         }
         else if( OrderDelete(OrderTicket()) == false) Print("Err (", GetLastError(), ") when delete order ",OrderTicket());
     }
    }
    return(totalOrders);
}

int OpenTrade()
  {
      double sl, tp,newtp;
      double lots = Lots;
     
       double bPrice = iBands(Symbol(),0,band,2,0,PRICE_CLOSE,MODE_LOWER,0);
       if( UseMidAsUporDown == 1) bPrice = iBands(Symbol(),0,band,2,0,PRICE_CLOSE,MODE_MAIN,0);
       double sPrice = iBands(Symbol(),0,band,2,0,PRICE_CLOSE,MODE_UPPER,0);
       if( UseMidAsUporDown == 2) sPrice = iBands(Symbol(),0,band,2,0,PRICE_CLOSE,MODE_MAIN,0);
       double buyPrice = NormalizeDouble(bPrice + StepUpper*getPoint(), Digits);
       double sellPrice = NormalizeDouble(sPrice - StepLower*getPoint(), Digits);
       
       //Filter1: 如果宽度太小，说明方向还没有选择好，删除所有挂单
       double w = sellPrice - buyPrice;
       if( w < MinWidth)
       {
         CloseOrders(MagicBuy+Period());
         CloseOrders(MagicSell+Period());                  
         return 0;
       }
       
      //挂单在下轨买入，止盈上轨，止损用参数
       sl = buyPrice - StopLoss*getPoint();
       tp = sellPrice;
       //没有买单，下挂单
       int n = GetTotalOrders(MagicBuy+Period(), OP_BUY );
       if( n <= 0 && (orderdirection == 0 || orderdirection == 2 )) 
       {
         OpenOrder(OP_BUYLIMIT, lots, buyPrice, sl, tp, MagicBuy+Period(), "mybollerv0.1", Blue);
       }
       else{
       //已经有买单且价格变化很大，修改价格到最新的上下轨
           for( int k = 0; k < n; k++)
           {
              if( OrderSelect(glbOrderTicket[k], SELECT_BY_TICKET, MODE_TRADES) == false) break;
              if( TimeCurrent() - pt > 900){
                  Print("===Deubg==n=",n, "ticket=",OrderTicket(),"tk=",OrderTakeProfit(),"tp=",tp,"gap=",MathAbs(OrderTakeProfit() - tp),"pricechange=",PriceChange*getPoint());
                  pt = TimeCurrent();
               }
              if((OrderType() == OP_BUYLIMIT && MathAbs(OrderOpenPrice() - buyPrice) >= PriceChange * getPoint()) || MathAbs(OrderTakeProfit() - tp) >= PriceChange * getPoint() )
              {
                  newtp = tp;
                  if( OrderType() == OP_BUY ) sl = OrderStopLoss();
                  if( OrderType() == OP_BUYLIMIT && MathAbs(OrderTakeProfit() - tp) >= 3*PriceChange * getPoint()) newtp = OrderTakeProfit() + PriceChange * getPoint();
                  if(OrderModify(glbOrderTicket[k], buyPrice, sl, newtp, 0, Green) == false)
                      Print("Err (", GetLastError(), ") Modify Buy Price= ", buyPrice, " SL= ", sl, " TP= ", tp, "newtp=", newtp);
                  else
                     Print("====OK (", GetLastError(), ") Modify Buy Price= ", buyPrice, " SL= ", sl, " TP= ", tp, "newtp=", newtp);

              }
           }
      }
 
       //挂单在上轨卖出，止盈下轨，止损用参数
       sl = sellPrice + StopLoss*getPoint();
       tp = buyPrice;
       //没有卖单，下挂单
       n = GetTotalOrders(MagicSell+Period(), OP_SELL );
       if( n <=  0 && (orderdirection == 1 || orderdirection == 2 ))  
       {
         OpenOrder(OP_SELLLIMIT, lots, sellPrice, sl, tp, MagicSell+Period(), "mybollerv0.1", Red);
       }
       //已经有麦单且价格变化很大，修改价格到最新的上下轨
       else{
       for( k = 0; k < n; k++)
           {
           if( OrderSelect(glbOrderTicket[k], SELECT_BY_TICKET, MODE_TRADES) == false) break;
           if((OrderType() == OP_SELLLIMIT &&MathAbs(OrderOpenPrice() - sellPrice) >= PriceChange * getPoint()) || (MathAbs(OrderTakeProfit() - tp) >= PriceChange * getPoint() && MathAbs(OrderTakeProfit() - tp) < 3*PriceChange*getPoint()) )
           {
               newtp = tp;
               if( OrderType() == OP_SELL ) sl = OrderStopLoss();
               if( OrderType() == OP_SELLLIMIT && MathAbs(OrderTakeProfit() - tp) >= 3*PriceChange * getPoint()) newtp = OrderTakeProfit();
               if(OrderModify(glbOrderTicket[k], sellPrice, sl, newtp, 0, Red) == false)
                   Print("Err (", GetLastError(), ") Modify Sell Price= ", sellPrice, " SL= ", sl, " TP= ", tp, "newtp=", newtp);
               else
                  Print("======OK (", GetLastError(), ") Modify Sell Price= ", sellPrice, " SL= ", sl, " TP= ", tp, "newtp=", newtp);
           }
         }
     }
   return(0);
  }

///-----------------common-------------
double getPoint()
{
      double point=MarketInfo(Symbol(),MODE_POINT);
      if( point <= 0.0001) point = 0.0001;
      else point = 0.01;
      if( Ask > 800 && Ask < 1500) point = 0.1;  //gold
      if( Ask > 1500) point = 1;
      return(point);
}

void OpenOrder(int op, double aLots, double aprice, double aStopLoss, double aTakeProfit, int mag, string c="", int clr=Blue)
{
           double point = getPoint();
           if( c == "") c = "myea openorder";
           RefreshRates();
           double onelot = 1;
           if( aLots >= 4) onelot = 2;
           if( Ask < 500){
             onelot *= 0.1;  //AUD
             aLots *= 0.1;
           }
           double lot = 0;
           int    factor = 0;  //one long, one short
           while( lot < aLots)
           {
                  if(OrderSend(Symbol(), op, onelot, NormalizeDouble(aprice, Digits), 500, aStopLoss, aTakeProfit+factor*(aTakeProfit-aprice), c, mag, 0, clr) == -1)
                  { Print("myea Error = ",ErrorDescription(GetLastError())); }
                  Sleep(1000);
                  lot += onelot;
                  factor = 1 - factor;
           }            
           Print("OpenOrder total:",c,"onelot=",onelot,"==",aprice,"=lots=",aLots,"==op==",op,"=sl=",aStopLoss,"==tk",aTakeProfit);

}

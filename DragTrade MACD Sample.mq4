/* =============================================================================================== */
/* Copyright (c) 2010 Andrey Nikolaevich Trukhanovich (aka TheXpert)                                  */
/*                                                                                                 */
/* Permission is hereby granted, free of charge, to any person obtaining a copy of this software           */
/* and associated documentation files (the "Software"),   */
/* to deal in the Software without restriction, including without limitation the rights           */
/* to use, copy, modify, merge, publish, distribute,                 */
/* sublicense, and/or sell copies of the Software, and to permit persons              */
/* to whom the Software is furnished to do so, subject to the following conditions:       */
/*                                                                                                 */
/*                                                                                                 */
/* The above copyright notice and this permission notice shall be included in all copies or substantial         */
/* portions of the Software.                                                         */
/*                                                                                                 */
/* THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS       */
/* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR     */
/* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR    */
/* IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER      */
/* DEALINGS IN THE SOFTWARE.                                                          */
/* =============================================================================================== */

//+------------------------------------------------------------------+
//|                                                  MACD Sample.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                     Modified by TheXpert, theforexpert@gmail.com |
//+------------------------------------------------------------------+

extern string _1_                      = "EA Settings";

extern double TakeProfit               = 50;
extern double Lots                     = 0.1;
extern double TrailingStop             = 30;
extern double MACDOpenLevel            = 3;
extern double MACDCloseLevel           = 2;
extern double MATrendPeriod            = 26;

extern double Magic                    = 12345;

extern string _2_                      = "Drag Trade Settings";

extern double DragTradeMagic           = 54321;
extern int    DragTradeTimesToRepeat   = 3;
extern int    DragTradeSlippage        = 3;

#include <DragTrade_v_1.0/DragTradeLib_v_1.0.mqh>

bool CriticalError;

int init()
{
   DragTrade_Init(DragTradeMagic, Magic, DragTradeTimesToRepeat, DragTradeSlippage, "Drag Trade Example");
   CriticalError = false;

   return(0);
}

int start()
{
   if (CriticalError) return (0);
   
   DragTrade_Start();
   
   double MacdCurrent, MacdPrevious, SignalCurrent;
   double SignalPrevious, MaCurrent, MaPrevious;
   int cnt, ticket, total;

   if (Bars < 100)
   {
      Comment("Bars less than 100, EA will be stopped");
      Comment_("Bars less than 100, EA will be stopped");
      Print("Bars less than 100, EA will be stopped");
      CriticalError = true;
      
      return(0);  
   }
   
   if (TakeProfit < 10)
   {
      Comment("TakeProfit less than 10");
      Comment_("TakeProfit less than 10");
      Print("TakeProfit less than 10");
      CriticalError = true;
      
      return(0);  // check TakeProfit
   }

   MacdCurrent =     iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   MacdPrevious =    iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 1);
   SignalCurrent =   iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 0);
   SignalPrevious =  iMACD(NULL, 0, 12, 26, 9, PRICE_CLOSE, MODE_SIGNAL, 1);
   
   MaCurrent =       iMA(NULL, 0, MATrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 0);
   MaPrevious =      iMA(NULL, 0, MATrendPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);

   total = DT_GetOrdersCount(Magic);
   if(total == 0) 
   {
      // no opened orders identified
      if(AccountFreeMargin() < 1000*Lots)
      {
         Comment("We have no money. Free Margin = " + AccountFreeMargin());
         Comment_("We have no money. Free Margin = " + AccountFreeMargin());
         Print("We have no money. Free Margin = ", AccountFreeMargin());
         CriticalError = true;

         return (0);  
      }
      
      // check for long position (BUY) possibility
      if (
            MacdCurrent > SignalCurrent && 
            MacdPrevious < SignalPrevious &&
            MacdCurrent < -MACDOpenLevel*Point && 
            MaCurrent > MaPrevious
         )
      {
         DT_OpenBuy(Magic, TakeProfit, 0, Lots, "macd sample");
         return (0); 
      }
      
      // check for short position (SELL) possibility
      if (
            MacdCurrent < SignalCurrent && 
            MacdPrevious > SignalPrevious && 
            MacdCurrent > MACDOpenLevel*Point && 
            MaCurrent < MaPrevious
         )
      {
         DT_OpenSell(Magic, TakeProfit, 0, Lots, "macd sample");
         return (0); 
      }
   }
   
   if (
         MacdCurrent < SignalCurrent && 
         MacdPrevious > SignalPrevious &&
         MacdCurrent > MACDCloseLevel*Point
      )
   {
      DT_CloseBuys(Magic, 3);
   }
      
   if (
         MacdCurrent > SignalCurrent &&
         MacdPrevious < SignalPrevious && 
         MacdCurrent < -MACDCloseLevel*Point
      )
   {
      DT_CloseSells(Magic, 3);
   }
   
   // it is important to enter the market correctly, 
   // but it is more important to exit it correctly...   
   for(cnt=0;cnt<total;cnt++)
   {
      OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
      if(OrderType()<=OP_SELL &&   // check for opened position 
         OrderSymbol()==Symbol())  // check for symbol
      {
         if(OrderType()==OP_BUY)   // long position is opened
         {
            // check for trailing stop
            if(TrailingStop>0)  
            {                 
               if(Bid-OrderOpenPrice()>Point*TrailingStop)
               {
                  if(OrderStopLoss()<Bid-Point*TrailingStop)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                  }
               }
            }
         }
         else // go to short position
         {
            // check for trailing stop
            if(TrailingStop>0)  
            {                 
               if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
               {
                  if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                  }
               }
            }
         }
      }
   }
   return(0);
}

int deinit()
{
   DragTrade_Deinit();
   
   return(0);
}
//+------------------------------------------------------------------+
//|                                                 PriceCrossMA.mq4 |
//|                                       Copyright ?2006, firedave | 
//|                    Partial Function Copyright ?2006, codersguru | 
//|                                        http://www.fx-review.com/ | 
//|                                        http://www.forex-tsd.com/ | 
//+------------------------------------------------------------------+

#property copyright "Copyright ?2006, firedave"
#property link      "http://www.fx-review.com"


//----------------------- INCLUDES
#include <stdlib.mqh>


//----------------------- EA PARAMETER
extern string  
         Expert_Name       = "---------- Price Cross MA v0.3";
extern double 
         StopLoss          = 300,
         TakeProfit        = 600,
         TrailingStop      = 0;

extern string  
         MA_Setting        = "---------- Moving Average Setting";
extern int
         MAPeriod          = 180,
         MAMethod          = 0,   //0:SMA 1:EMA 2:SMMA 3:LWMA
         MAPrice           = 0;   //0:CLOSE 1:OPEN
         
extern string  
         Order_Setting     = "---------- Order Setting";
extern int
         NumberOfTries     = 5,
         Slippage          = 5;
extern bool
         StopAndReverse    = true;  // if signal change, exit and reverse order

extern string  
         Time_Parameters   = "---------- EA Active Time";
extern bool    
         UseHourTrade      = false;         
extern int     
         StartHour         = 10,
         EndHour           = 11;
         
extern string  
         MM_Parameters     = "---------- MoneyManagement by L.Williams";
extern double 
         Lots              = 1;
extern bool 
         MM                = false, //Use Money Management or not
         AccountIsMicro    = false; //Use Micro-Account or not
extern int 
         Risk              = 10; //10%

extern bool 
         Show_Settings     = true;


//----------------------- GLOBAL VARIABLE
static int 
         TimeFrame         = 0;
string
         TicketComment     = "PriceCrossMA v0.3";
int
         MagicNumber       = 20060410;




//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   return(0);
}

//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
  
//----------------------- PREVENT RE-COUNTING WHILE USER CHANGING TIME FRAME
//----------------------- SOURCE : CODERSGURU
   TimeFrame=Period(); 
   return(0);

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
{

   double 
         OpenPricePrevious,
         ClosePricePrevious,
         OpenPriceCurrent,
         MAValuePrevious,
         MAValueCurrent;
                  
   int   
         cnt,
         ticket,
         total;
         
//----------------------- TIME FILTER
   if (UseHourTrade)
   {
      if(!(Hour()>=StartHour && Hour()<=EndHour))
      {
         Comment("Non-Trading Hours!");
         return(0);
      }
   }

         
//----------------------- CHECK CHART NEED MORE THAN 100 BARS
   if(Bars<100)
   {
      Print("bars less than 100");
      return(0);  
   }


//----------------------- ADJUST LOTS IF USING MONEY MANAGEMENT
   if(MM==true) Lots = subLotSize();


//----------------------- ENTRY

//----------------------- TOTAL ORDER BASE ON MAGICNUMBER AND SYMBOL
   total = subTotalTrade();

//----------------------- SET VALUE FOR VARIABLE
      OpenPricePrevious    = iOpen (NULL,TimeFrame,1);
      ClosePricePrevious   = iClose(NULL,TimeFrame,1);
      OpenPriceCurrent     = iOpen (NULL,TimeFrame,0);
      MAValuePrevious      = iMA   (NULL,TimeFrame,MAPeriod,0,MAMethod,MAPrice,1);
      MAValueCurrent       = iMA   (NULL,TimeFrame,MAPeriod,0,MAMethod,MAPrice,0);


//----------------------- IF NO TRADE
   if(total < 1) 
   {
//----------------------- BUY CONDITION   
      if(OpenPricePrevious<MAValuePrevious &&
         OpenPriceCurrent >MAValueCurrent)
      {
         ticket = subOpenOrder(OP_BUY); // open BUY order
         return(0);
      }

//----------------------- SELL CONDITION   
      if(OpenPricePrevious>MAValuePrevious &&
         OpenPriceCurrent <MAValueCurrent)
      {
         ticket = subOpenOrder(OP_SELL); // open SELL order
         return(0);
      }
      return(0);
   }
   
//----------------------- CHECK OPEN ORDER
//----------------------- FOR SIGNAL CHANGE - STOP AND REVERSE
//----------------------- AND TRAILING STOP
   total = OrdersTotal();

   if(TrailingStop>0 ||
      StopAndReverse)
   {
      for(cnt=0;cnt<total;cnt++)
      {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);

         if(OrderType()<=OP_SELL &&
            OrderSymbol()==Symbol() &&
            OrderMagicNumber()==MagicNumber)
         {
            if(OrderType()==OP_BUY)   // buy position is opened   
            {
               if(StopAndReverse)  // signal change, close order and open new one 
               {
                  if(OpenPricePrevious>MAValuePrevious &&
                     OpenPriceCurrent <MAValueCurrent)
                  {
                     OrderClose(OrderTicket(),OrderLots(),Bid,Slippage,Violet); // close buy order
                     ticket = subOpenOrder(OP_SELL); // open sell order
                     return(0);
                  }
               }
               if(TrailingStop>0) // trailing stop
               {
                  if(Bid-OrderOpenPrice()>Point*TrailingStop &&
                     OrderStopLoss()<Bid-Point*TrailingStop)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                  }
               }
            }
            if(OrderType()==OP_SELL)   // sell position is opened   
            {
               if(StopAndReverse)  // signal change, close order and open new one 
               {
                  if(OpenPricePrevious<MAValuePrevious &&
                     OpenPriceCurrent >MAValueCurrent)
                  {
                     OrderClose(OrderTicket(),OrderLots(),Ask,Slippage,Violet); // close sell order
                     ticket = subOpenOrder(OP_BUY); // open buy order
                     return(0);
                  }
               }
               if(TrailingStop>0) // trailing stop
               {
                  if(OrderOpenPrice()-Ask>Point*TrailingStop)
                  {
                  if(OrderStopLoss()>Ask+Point*TrailingStop || OrderStopLoss()==0)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                     return(0);
                  }
                  }
               }
            }
         }
      }
   }            
   return(0);
}

//----------------------- END PROGRAM

//+------------------------------------------------------------------+
//| FUNCTION DEFINITIONS
//+------------------------------------------------------------------+

//----------------------- MONEY MANAGEMENT FUNCTION  
//----------------------- SOURCE : CODERSGURU
double subLotSize()
{
     double lotMM = MathCeil(AccountFreeMargin() *  Risk / 1000) / 100;
	  
	  if(AccountIsMicro==false) //normal account
	  {
	     if (lotMM < 0.1) lotMM = Lots;
	     if ((lotMM > 0.5) && (lotMM < 1)) lotMM=0.5;
	     if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	     if  (lotMM > 100) lotMM = 100;
	  }
	  else //micro account
	  {
	     if (lotMM < 0.01) lotMM = Lots;
	     if (lotMM > 1.0) lotMM = MathCeil(lotMM);
	     if  (lotMM > 100) lotMM = 100;
	  }
	  
	  return (lotMM);
}

//----------------------- NUMBER OF ORDER BASE ON SYMBOL AND MAGICNUMBER FUNCTION
int subTotalTrade()
{
   int
      cnt, 
      total;
   for(cnt=0;cnt<OrdersTotal();cnt++){
      if(OrderSelect(cnt,SELECT_BY_POS)){
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber){
            total++;
         }
      }
   }
   return(total);
}

//----------------------- OPEN ORDER FUNCTION
//----------------------- SOURCE : CODERSGURU
int subOpenOrder(int type)
{
   int
         ticket      = 0,
         err         = 0,
         c           = 0;
         
   double         
         aStopLoss   = 0,
         aTakeProfit = 0,
         bStopLoss   = 0,
         bTakeProfit = 0;

   if(StopLoss!=0)
   {
      aStopLoss   = Ask-StopLoss*Point;
      bStopLoss   = Bid+StopLoss*Point;
   }
   
   if(TakeProfit!=0)
   {
      aTakeProfit = Ask+TakeProfit*Point;
      bTakeProfit = Bid-TakeProfit*Point;
   }

   if(type==OP_BUY)
   {
      for(c=0;c<NumberOfTries;c++)
      {
         ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,aStopLoss,aTakeProfit,TicketComment,MagicNumber,0,Green);
         err=GetLastError();
         if(err==0)
         { 
            break;
         }
         else
         {
            if(err==4 || err==137 ||err==146 || err==136) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               Print("Open Order error: ",err," lots=",Lots);
               break;
            }  
         }
      }   
   }
   if(type==OP_SELL)
   {   
      for(c=0;c<NumberOfTries;c++)
      {
         ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,bStopLoss,bTakeProfit,TicketComment,MagicNumber,0,Red);
         err=GetLastError();
         if(err==0)
         { 
            break;
         }
         else
         {
            if(err==4 || err==137 ||err==146 || err==136) //Busy errors
            {
               Sleep(5000);
               continue;
            }
            else //normal error
            {
               Print("Open Order error: ",err," lots=",Lots);
               break;
            }  
         }
      }   
   }  
   return(ticket);
}

//----------------------- END FUNCTION
#include<stdlib.mqh>
extern string version = "1.04 01/21/2016";
extern int    RunPeriod = 60;
extern bool   EnableInd = false;
extern double StopLoss = 70;  //M15 - 80 H1 - 70
extern double TkRate = 2;
extern int    TradeMode = 2;
extern int    MaxGap = 50;
extern int    Lots = 1;
extern int    MaxLots = 2;
extern int    MATrade = -1;
extern int    MAPeriod = 100;
extern int    KTradeMode = -1;
extern bool   Immediate = false;
extern int    MagSpecial = 0;


#define MAGICMA  2016012100
#define MAGICMB  2016011000

string trendLineName = "";
string indName = "";
double signalPrice = 0;

datetime pt, st;
datetime dt = 0, dt2 = 0;
datetime ptime1 = 0;
datetime ptime2 = 0;
datetime ptime3 = 0;
datetime ptime4 = 0;
datetime dtime1 = 0;
datetime dtime2 = 0;
datetime dtime3 = 0;

int init()
{
     return(0);
}

double getPoint()
{
      double point=MarketInfo(Symbol(),MODE_POINT);
      if( point <= 0.0001) point = 0.0001;
      else point = 0.01;
      if( Ask > 800 && Ask < 1500) point = 0.1;  //gold
      if( Ask > 1500) point = 1;
      return(point);
}

//检查是否有在n根K线内平仓的单子
int getHistoryOrder(int mag, int aKFilter)
{
   int hstTotal=OrdersHistoryTotal();
   int i;
   int k = hstTotal-10;
   if(k < 0) k = 0;
   for( i = hstTotal-1; i >= k; i--){
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)== true)
            if(OrderType()<=OP_SELL &&   // check for opened position 
               OrderSymbol()==Symbol())  // check for symbol
               {
                  if( (OrderMagicNumber()) == mag)
                  {
                      if( CurTime() - OrderCloseTime() < aKFilter * Period() * 60 )
                      {
                         //if( OrderType() == op && OrderProfit() < 0) 
                         return(OrderTicket());
                      }
                  }
               }
   }
   return(-1);
}

void OpenOrder(int op, double aLots, int aStopLoss, int aTakeProfit, int mag, string c="",string extrac="")
{
           double point = getPoint();
           double aprice, sl, tk;
           if( c == "") c = "myea openorder";
           int coef = 1;
           if( op == OP_BUY)
           {     
                  aprice = Ask;
                  sl = Ask - aStopLoss * point;
                  if( aTakeProfit > 0){
                     tk = Ask + aTakeProfit * point;
                  }
                  else tk = 0;
                  RefreshRates();
                  if(OrderSend(Symbol(), op, aLots*coef, NormalizeDouble(Ask, Digits), 500, sl, tk, c, mag) == -1)
                  { Print("myea Error = ",ErrorDescription(GetLastError())); }
           }
           if( op == OP_SELL)
           {
                  aprice = Bid;
                  sl = Bid + aStopLoss * point;
                  if( aTakeProfit > 0) tk = Bid - aTakeProfit * point;
                  else tk = 0;
                  RefreshRates();
                  if(OrderSend(Symbol(), op, aLots*coef, NormalizeDouble(Bid, Digits), 500, sl, tk, c, mag) == -1)
                  { Print("myea Error = ",ErrorDescription(GetLastError())); }
           }
           Print("OpenOrder:",c,extrac,"point=",point,"==",Ask,"=lots=",aLots,"==op==",op,"==price=",aprice,"=sl=",sl,"==tk",tk);

}

int GetOrder(int mag, int maxType)
{
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if( OrderType() <= maxType) return(OrderTicket());
     }
     return(-1);
}

void OpenReverseOrder(int ticket, int op, double aLots, int aStopLoss, int aTakeProfit, int mag,string c="")
{
      if( OrderSelect(ticket,SELECT_BY_TICKET, MODE_TRADES)==false )return;
      double lots = OrderLots();
      double opt = OrderProfit();
      int n;
      //if( CurTime() - OrderOpenTime() < KFilter * Period() * 60) return;
      n = CloseOrder(ticket, op);
      
      if( n == 1 && opt < 0 ){
         lots = 2 * lots;
         if( lots > MaxLots) lots = MaxLots;
      }
      else lots = aLots;
      //Print("====myea-OpenReverseOrder","==lots=",lots,"==n=",n,"==op=",op);
      if( n > 0 )
      {
         OpenOrder(op, lots, aStopLoss, aTakeProfit, mag, c,+"[原单"+ticket+"]");
       }
}
int CloseOrder(int ticket, int op)
{
      int nClosed = 0;
      if( OrderSelect(ticket,SELECT_BY_TICKET, MODE_TRADES)==false )return(false);
      int mag = OrderMagicNumber();
      if(OrderType()==OP_BUY && op == OP_SELL)
        {
         if( OrderClose(OrderTicket(),OrderLots(),Bid,50,White) != true)
         {
            Print("Close order error:",ErrorDescription(GetLastError()));
         }
         nClosed++;
         int t = GetOrder(mag, OP_SELL);
         while( t >= 0)
         {
            if( OrderClose(OrderTicket(),OrderLots(),Bid,50,White) != true)
            {
               Print("Close order error:",ErrorDescription(GetLastError()));
            }
             nClosed++;
             t = GetOrder(mag, OP_SELL);
         }
         
         return(nClosed);
        }
      if(OrderType()==OP_SELL && op == OP_BUY)
        {

         if( OrderClose(OrderTicket(),OrderLots(),Ask,50,White) != true)
         {
            Print("Close order error:",ErrorDescription(GetLastError()));
         }
         nClosed++;
         t = GetOrder(mag, OP_SELL);
         while( t >= 0)
         {
            if( OrderClose(OrderTicket(),OrderLots(),Ask,50,White) != true)
            {
               Print("Close order error:",ErrorDescription(GetLastError()));
            }
             nClosed++;
             t = GetOrder(mag, OP_SELL);
         }
         return(nClosed);
        }
      return(nClosed);
}

void ClosePendingOrder(int mag)
{
   int t = GetOrder(mag, OP_SELLSTOP);
   if( t == -1) return;  
   bool done = false;
   while( !done)
   {
      done = true;
      for( int i = 0; i < OrdersTotal(); i++)
      {
         if( OrderSelect(i, SELECT_BY_POS, MODE_TRADES)==false )return;
         if(OrderType()<= OP_SELL || OrderSymbol() != Symbol() || OrderMagicNumber() != mag ) continue;
         if(OrderDelete(OrderTicket())!=true)
         {
                  Print("Delete order error:",ErrorDescription(GetLastError()));
         }
         done = false;
         break;
      }
   }
}


int GetTotalOrders(int mag, int maxType)
{
   int totalOrders = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if( OrderType() <= maxType) totalOrders++;
     }
     return(totalOrders);
}


double getOrderPoint()
{
      double point=MarketInfo(OrderSymbol(),MODE_POINT);
      if( point <= 0.0001) point = 0.0001;
      else point = 0.01;
      double p = OrderOpenPrice();
      if( p > 800 && p < 1500) point = 0.1;  //gold
      if( p > 1500) point = 1;
      return(point);
}

int GetLastOrder(int mag, int maxType)
{
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if( OrderType() <= maxType) return(OrderTicket());
     }
     return(-1);
}

double myATR(int t, int s, int p)
{
   int i;
   double c1, max, tmax;
   max = 0;
   tmax = 0;
   for( i = s; i <= p+s; i++)
   {
      max = iHigh(Symbol(), t, i) - iLow(Symbol(), t, i);
      c1 = MathAbs(iHigh(Symbol(), t, i) - iClose(Symbol(), t, i+1));
      if( max < c1) max = c1;
      c1 = MathAbs(iLow(Symbol(), t, i) - iClose(Symbol(), t, i+1));
      if( max < c1) max = c1;
      tmax += max; 
   }
   return tmax; //return(tmax / p);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   int sl, tp , t;
   string cs = " TradeMode="+TradeMode+" MATrade="+MATrade+"KTrade="+KTradeMode+"Lots="+Lots+"RP="+RunPeriod+"MagSpecial="+MagSpecial;
   string comment;
   comment = "my1-2-3:";
   Comment( comment+version+cs);
   if( Period() != RunPeriod ) return(0);
   sl = StopLoss; // MathAbs(Close[0] - objPrice) / Point / 10 + StopLoss;
   tp = sl * TkRate;
   int op = -1;
   int mag = MAGICMA+Period()+MagSpecial;
   while( KTradeMode >= 0)
   {      
      RefreshRates(); 
      if( Immediate )
      {
         op = KTradeMode;
      }
      else{
         if( TimeCurrent() - Time[0] < 30){ KTradeMode = -1; break; }
         if( TimeCurrent() - Time[0] < Period() * 60 - 10) return(0);
         if( KTradeMode == 0 && Close[0] > Close[1]) op = 0;
         if( KTradeMode == 1 && Close[0] < Close[1]) op = 1;
      }
      if( op != -1)
      {
         OpenOrder(op, Lots, sl, tp, mag, "mmy123:KTrade("+Period()+")");
         KTradeMode = -1;
      }
   }
   string ss[2];
   ss[0] = "买"; ss[1]="卖";
   double price[2];
   price[0] = Ask;
   price[1] = Bid;
   double lot;
      
   mag = MAGICMB+Period()+MagSpecial;
   if( MATrade >= 0)
   {
      double point = getPoint();
      double p = NormalizeDouble(iMA(Symbol(), 0, MAPeriod, 0, MODE_SMA,PRICE_CLOSE, 1), Digits);
      t = GetOrder(mag, OP_SELLSTOP);
      lot = Lots;
      if( MATrade == 0)
         {
            sl = p - sl * point;
            tp = p + tp * point;
            if( t == -1)
            {
               if(OrderSend(Symbol(), OP_BUYLIMIT, lot, p, 5, sl, tp, comment+"Ma"+MAPeriod+"(M"+Period()+")"+MagSpecial, mag, 0, Green) < 0)
                  Print("OpenMa Err (", GetLastError(), ") Open Price= ", p, " SL= ", sl," TP= ", tp, ",matrade=", MATrade);
            }
         }
         else
         {
            sl = p + sl * point;
            tp = p - tp * point;
            if( t == -1)
            {
               if(OrderSend(Symbol(), OP_SELLLIMIT, lot, p, 5, sl, tp, comment+"Ma"+MAPeriod+"(M"+Period()+")"+MagSpecial, mag, 0, Red) < 0)
                  Print("OpenMa Err (", GetLastError(), ") Open Price= ", p, " SL= ", sl," TP= ", tp, "matrade=", MATrade);
             }
         }
      if( t != -1 && OrderType() > 1)
      {
             if(MathAbs( p - OrderOpenPrice()) >= 5 && MathAbs( p - (Ask+Bid)/2) > 8)
             {
                  if(OrderModify(t, p, sl, tp, 0, Blue) == false)
                    Print("Modify Ma Err (", GetLastError(), ") Price= ", p,"OrderOpenPrice=",OrderOpenPrice(),"SL ", sl," TP= ", tp, "t=", t);           
             }  
      }
   }
   else
      ClosePendingOrder(mag);
      
   op = getBreakSignal();
   //if( true )
   {
      //double macd = iMACD(Symbol(), Period(), 24, 52, 9, PRICE_CLOSE, MODE_MAIN,0 );
      //if( macd > 0 && op == 1) op = 0;
      //else if( macd < 0 && op == 0) op = 1;
      //else op = -1;
   }

   while( op != -1 ) 
   {
      mag = MAGICMA+Period()+MagSpecial;
      string s[2];
      s[0] = "上破"; s[1] = "下破";
      string bn;
      if( StringLen(trendLineName) == 0) bn = "指标"+indName;
      else bn = "趋势线"+trendLineName;
      if( TimeCurrent() - dtime3 > 180)
      {
           dtime3 = TimeCurrent();
           Alert("my1-2-3: ",Symbol()," ",Period()," ",s[op],bn,",",ss[op],"价格:",price[op],"指标价格:",signalPrice);
      } 
      if( MATrade < 0 && (TradeMode == 2 || TradeMode == op) && getHistoryOrder(mag, 1) < 0)
      {
         t = GetOrder(mag, OP_SELL);
         lot = Lots;
         if( StringLen(trendLineName) == 0) bn = indName;
         else bn = changeShortName(trendLineName);
         if( t == -1 ){
               comment = "123("+Period()+")"+s[op]+bn+"新"+ss[op]+"单";
               OpenOrder(op, lot, sl, tp, mag, comment);
         }
         else{
               comment = "123("+Period()+")"+s[op]+bn+"反手"+ss[op]+"单";
               OpenReverseOrder(t, op, lot, sl, tp, mag,comment);
         }     
      }    
      break;
   }
   return(0);
  }

string changeShortName(string name)
{
   int m = StringLen(name) - 5;
   if( m < 0) m = 0;
   string n = StringSubstr(name, m);
   string lname[2] = {"Horizontal Line ",""};
   string sname[2] = {"HL","TL"};
   for( int i = 0; i < 2; i++)
      if(StringFind(name, lname[i]) >= 0) return sname[i]+n;
   return n;
}

int getBreakSignal()
{
   int i,j,ObjType;
   double price[4];
   for (i = 0; i < ObjectsTotal(); i++)
   {
       trendLineName = ObjectName(i);
       string f = StringSubstr(trendLineName,0,1);
       if( f == "#" || f == "_" ) continue; //skip the system lines for orders
       ObjType = ObjectType(trendLineName);
       switch (ObjType)
       {
         case OBJ_HLINE:
           for( j = 1; j <= 3; j++) price[j] = ObjectGet(trendLineName, OBJPROP_PRICE1);
           ///Print("ObjName=",ObjName,"y1=",y1,"y2=",y2);
           break;
         case OBJ_TREND :
         case OBJ_TRENDBYANGLE :
           for( j = 1; j <= 3; j++) price[j] = ObjectGetValueByShift(trendLineName, j);
           ///Print("ObjName=",ObjName,"y1=",y1,"y2=",y2);
           break;
         default :
           continue;
       }
       int r = getSignal(price);
       if( r >= 0) return r;
    }
    
    trendLineName = "";
    if( Period() < 60 || EnableInd == false) return(-1);
    int ct = ChartIndicatorsTotal(0,0);
    for( int ck = 0; ck < ct; ck++) 
    {
      indName = ChartIndicatorName(0, 0, ck);
      int ret = getIndPrice(indName, price);
      if( ret < 0) continue;
      r = getSignal(price);
      if( r >= 0) return r;
    }
 
    return -1;
  }

int getSignal(double& price[4])
{
       int relation[4];
       int ret = -1;
       for(int j = 1; j <= 3; j++)
       {
         if( Close[j] < price[j]) relation[j] = 0;
         else relation[j] = 1;
       }
       if( Period() < 60)
       {
         if( relation[3] == 0 && relation[2] == 1 && relation[1] == 1) ret = 0;
         if( relation[3] == 1 && relation[2] == 0 && relation[1] == 0) ret = 1;
       }
       else
       {
         if( relation[2] == 0 && relation[1] == 1) ret = 0;
         if( relation[2] == 1 && relation[1] == 0) ret = 1;
       }
       if( ret >= 0)
       {
         if( Period() < 60 && MathAbs(Close[1] - price[1]) > MaxGap * getPoint() ){
             if( TimeCurrent() - dtime2 > 180)
             {
                 dtime2 = TimeCurrent();
                 Alert("Find signale(M",Period(),") ",trendLineName, "-", indName, " but gap too large c=",Close[1],"p=",price[1],"gap=",MathAbs(Close[1]-price[1]));
             } 
             ret = -1;
         }
       }
       signalPrice = price[1];
       return ret;
}

int getParam(string name)
{
   int s = StringFind(name, "(", 0);
   if( s < 0) return -1;
   int e = StringFind(name, ")", s);
   if( e < 0) return -1;
   string tmp = StringSubstr(name, s+1, e-s-1);
   return( StringToInteger(tmp));
}

int getIndPrice(string name, double& price[4])
{
   int para = getParam(name);
   if( para < 0) return -1;
   int j;
   if( StringFind(name, "Bands", 0) >= 0)
   {
      for( j = 1; j <= 3; j++) price[j] = iBands(Symbol(),0,para,2,0,PRICE_CLOSE,MODE_MAIN,j);     
      return 0;
   }
   else if(StringFind(name, "MA", 0) >= 0)
   {
      for( j = 1; j <= 3; j++) price[j] = iMA(Symbol(),0,para,0,MODE_SMA,PRICE_CLOSE,j);
      return 0;
   }
   return -1;
}    
// the end.
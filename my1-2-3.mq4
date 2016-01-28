#include<stdlib.mqh>
#include "PanelDialog.mqh"

extern string version = "1.18 01/28/2016";
extern int    RunPeriod = 60;
extern double StopLoss = 90;  //M15 - 70
extern double TkRate = 1.5;  //general : 120 and 4
extern int    TradeMode = 2;
extern int    MaxLots = 6;
extern int    MATrade = -1;
extern int    MAPeriod = 100;
extern int    MASpace = 15;
//extern int    KTradeMode = -1;
//extern bool   Immediate = false;
extern int    MagSpecial = 0;
extern int    TestFlag = 0;
extern int    KSpace = 10;
extern int    MaxGap = 50;


#define MAGICMA  2016012100
#define MAGICMB  2016011000

CPanelDialog ExtDialog;
string trendLineName = "";
string indName = "";
double signalPrice = 0;

datetime pt, st;
datetime dt = 0, dt2 = 0, at = 0;
datetime dtime1 = 0, dtime2 = 0, dtime3 = 0, dtime4 = 0, dtime5 = 0;

int init()
{
//--- create application dialog
   string v = " TradeMode="+TradeMode+" MATrade="+MATrade+"MaxLots="+MaxLots;
   string title = "my1-2-3 v" + version + v;
   if(!ExtDialog.Create(0, title,0,0,450,600,700))
     return(INIT_FAILED);
//--- run application
   if(!ExtDialog.Run())
     return(INIT_FAILED);
     return(0);
}
void OnDeinit(const int reason)
  {
//--- destroy application dialog
   ExtDialog.Destroy(reason);
  }
  
  void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   ExtDialog.ChartEvent(id,lparam,dparam,sparam);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   int sl, tp , t;
   double lot;
   string ss[2] = {"买","卖"};
   string comment = "my1-2-3:";
   Comment("KTrademode=",KTradeMode, "Bid=",Bid,"command=",command);
   if( Period() != RunPeriod ){
       ExtDialog.UpdateLabel("Run Period is not correct!");
       return(0);
   }
   sl = StopLoss; // MathAbs(Close[0] - objPrice) / Point / 10 + StopLoss;
   tp = sl * TkRate;
   int op = -1;
   int mag = MAGICMA+Period()+MagSpecial;
   if( EnableDayClose == 1 && TimeHour(TimeCurrent()) == 20 && TimeMinute(TimeCurrent()) == 50)
   {
      Print("my1-2-3: Day Close enabled and is executing at ",TimeToStr(TimeCurrent()),"------------------------------------------------------");
      command = 1;
   }
   if( command == 0)
   {
      dtime1 = dtime2 = dtime4 = dtime5 = 0;
      getBreakSignal();
      command = -1;
      ExtDialog.UpdateLabel("Log printed at "+TimeToStr(TimeCurrent()));
   }
   if( command == 1)
   {
      double profit = CloseAllOrders();
      command = -1;
      ExtDialog.UpdateLabel("All orders of "+Symbol()+" closed, total profit="+DoubleToStr(profit,0)+".");
   }
   else if( command == 2)
   {
      comment = "123("+Period()+")"+"加仓"+ss[TradeDirection]+"单";
      OpenOrder(TradeDirection, Lots, sl, tp, mag, comment);
      ExtDialog.UpdateLabel("Add position of "+Symbol()+" lots="+Lots+".");
      command = -1;
   }
   if( KTradeMode >= 0)
   { 
      //Alert("KTradeMode=",KTradeMode,"time=",(TimeCurrent() - Time[0]));     
      RefreshRates(); 
      //msg = "Time:"+(TimeCurrent() - Time[0]);
      if( Immediate )
      {
         msg = "KTrade Now ";
         op = KTradeMode;
         Immediate = false;
      }
      else{
         msg = "";
         if( TimeCurrent() - KTradeModeTime > RunPeriod*60){ msg = "KTrade expired!"; KTradeMode = -1; ExtDialog.UpdateKTradeMode();return(0); }
         if( TimeCurrent() - Time[0] < RunPeriod * 60 - 15){ ExtDialog.UpdateLabel("KTrade is waiting for candle closing..."); return(0);}
         if( KTradeMode == 0 && Close[0] > Close[1]) op = 0;
         if( KTradeMode == 1 && Close[0] < Close[1]) op = 1;
      }
      if( op != -1)
      {
         t = getOrder(mag, OP_SELL);
         lot = Lots;
         if( t == -1 ){
               comment = "123("+Period()+")"+"K线开新"+ss[op]+"单";
               OpenOrder(op, lot, sl, tp, mag, comment);
         }
         else{
               comment = "123("+Period()+")"+"K线反手"+ss[op]+"单";
               OpenReverseOrder(t, op, lot, sl, tp, mag,comment);
         } 
         msg += comment;
         KTradeMode = -1;
         ExtDialog.UpdateKTradeMode();
      }
   }
   RefreshRates(); 
   if( TimeCurrent() - Time[0] > 30) return 0;
   double price[2];
   price[0] = Ask;
   price[1] = Bid;
      
   mag = MAGICMB+Period()+MagSpecial;
   if( MATrade >= 0)
   {
      double point = getPoint();
      double p;
      if( MAPeriod < 1000) p = NormalizeDouble(iMA(Symbol(), 0, MAPeriod, 0, MODE_SMA,PRICE_CLOSE, 1), Digits);
      else{
         string name = "Trendline "+MAPeriod;
         if(ObjectFind(name) == 0)
         {
            int factor = 1;
            if( MATrade == 1) factor = -1;
            string tname = "_trade " + MAPeriod;
            SetObject(tname,
                 ObjectGet(name, OBJPROP_TIME1),
                 ObjectGet(name, OBJPROP_PRICE1) + factor*MASpace*Point,
                 ObjectGet(name, OBJPROP_TIME2),
                 ObjectGet(name, OBJPROP_PRICE2) + factor*MASpace*Point,
                 ObjectGet(name, OBJPROP_COLOR));
            p = NormalizeDouble(ObjectGetValueByShift(tname,0),Digits);          
         }
      }
      t = getOrder(mag, OP_SELLSTOP);
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
      else bn = trendLineName;
      if( TimeCurrent() - dtime3 > 180)
      {
           dtime3 = TimeCurrent();
           Alert("my1-2-3: ",Symbol()," ",Period()," ",s[op],bn,",",ss[op],"价格:",price[op],"指标价格:",signalPrice);
      } 
      if( (TradeMode == 2 || TradeMode == op) && getHistoryOrder(mag, 1, op) < 0 )
      {
         t = getOrder(mag, OP_SELL);
         lot = Lots;
         if( StringLen(trendLineName) == 0) bn = indName;
         else bn = changeShortName(trendLineName);
         if( t == -1 ){
               at = TimeCurrent();
               comment = "123("+Period()+")"+s[op]+bn+"新"+ss[op]+"单";
               OpenOrder(op, lot, sl, tp, mag, comment);
         }
         else{
               if( OrderType() == op && OrderProfit() > 0 && TimeCurrent() - at > 180)
               {
                  at = TimeCurrent();
                  double tt = getTotalOrderLots(mag, op);
                  if( Ask < 500) tt *= 10;
                  if( tt >= MaxLots) break;
                  if( lot > MaxLots - tt) lot = MaxLots - tt;
                  comment = "123("+Period()+")"+s[op]+bn+"加"+ss[op]+"单";
                  OpenOrder(op, lot, sl, tp, mag, comment);
               }
               else{
                  comment = "123("+Period()+")"+s[op]+bn+"反手"+ss[op]+"单";
                  OpenReverseOrder(t, op, lot, sl, tp, mag,comment);
               }
         }     
      }    
      break;
   }
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
int getHistoryOrder(int mag, int aKFilter, int op)
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
                         if( OrderType() == op) // && OrderProfit() < 0) 
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
           RefreshRates();
           if( op == OP_BUY)
           {     
                  aprice = Ask;
                  sl = Ask - aStopLoss * point;
                  if( aTakeProfit > 0)  tk = Ask + aTakeProfit * point;
                  else tk = 0;
           }
           if( op == OP_SELL)
           {
                  aprice = Bid;
                  sl = Bid + aStopLoss * point;
                  if( aTakeProfit > 0) tk = Bid - aTakeProfit * point;
                  else tk = 0;
           }
           double onelot = 1;
           if( aLots >= 4) onelot = 2;
           if( Ask < 500){
             onelot *= 0.1;  //AUD
             aLots *= 0.1;
           }
           double lot = 0;
           while( lot < aLots)
           {
                  if(OrderSend(Symbol(), op, onelot, NormalizeDouble(aprice, Digits), 500, sl, tk, c, mag) == -1)
                  { Print("myea Error = ",ErrorDescription(GetLastError())); }
                  Sleep(1000);
                  lot += onelot;
           }            
           Print("OpenOrder total:",c,extrac,"onelot=",onelot,"==",aprice,"=lots=",aLots,"==op==",op,"=sl=",sl,"==tk",tk);

}

int getOrder(int mag, int maxType)
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

double getTotalOrderLots(int mag, int oType)
{
   double t = 0;
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if( (mag != 0 && OrderMagicNumber()!= mag) || OrderSymbol()!=Symbol()) continue;
      //---- check order type 
      if( OrderType() == oType) t += OrderLots();
     }
     return(t);
}


void OpenReverseOrder(int ticket, int op, double aLots, int aStopLoss, int aTakeProfit, int mag,string c="")
{
      if( OrderSelect(ticket,SELECT_BY_TICKET, MODE_TRADES)==false )return;
      double lots = OrderLots();
      double opt = OrderProfit();
      int n = CloseOrder(ticket, op);
      //Print("====myea-OpenReverseOrder","==lots=",lots,"==n=",n,"==op=",op);
      if( n > 0 )
      {
         if( opt < 0 ){
            lots = 2 * n;
            if( lots > MaxLots) lots = MaxLots;
         }
         else lots = aLots;
         OpenOrder(op, lots, aStopLoss, aTakeProfit, mag, c,+"[原单"+ticket+"]");
      }
}

double CloseAllOrders()
  {
   bool   result;
   double price,totalprofit = 0;
   int    cmd,error;
//----
   int tickets[1000];
   int j = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) && OrderSymbol() == Symbol())
     {
      cmd=OrderType();
      if(cmd==OP_BUY || cmd==OP_SELL)
      {
         tickets[j] = OrderTicket();
         j++;
      }
     }
   }  
   for(i = 0; i < j; i++)
   {
     Print("close-----:",i,"/", j);
     if(OrderSelect(tickets[i],SELECT_BY_TICKET,MODE_TRADES))
     {
      OrderPrint();
      int    digits=MarketInfo(OrderSymbol(),MODE_DIGITS);
      double point = getOrderPoint();
      cmd=OrderType();
      
      //---- first order is buy or sell
      if(cmd==OP_BUY || cmd==OP_SELL)
        {
            if(cmd==OP_BUY) price=OrderOpenPrice() + OrderProfit()/(OrderLots()*10)*point;
            else            price=OrderOpenPrice() - OrderProfit()/(OrderLots()*10)*point;
            price = NormalizeDouble(price, digits );
            Print("OpenPrice=", OrderOpenPrice(), " ClosePrice=",price," Profit=",OrderProfit());
            totalprofit += OrderProfit();
            result=OrderClose(OrderTicket(),OrderLots(),price,50,CLR_NONE);
            if(result!=TRUE) { error=GetLastError(); Print("LastError = ",error); }
            else error=0;
        }
     }
     else Print( "Error when order select ", GetLastError());
   }

//----
   return(totalprofit);
  }
  
int CloseOrder(int ticket, int op)
{
      int nClosed = 0;
      if( OrderSelect(ticket,SELECT_BY_TICKET, MODE_TRADES)==false )return(false);
      int mag = OrderMagicNumber();
      if(OrderType()==OP_BUY && op == OP_SELL)
        {
         nClosed += OrderLots();
         if( OrderClose(OrderTicket(),OrderLots(),Bid,50,White) != true)
         {
            Print("Close order error:",ErrorDescription(GetLastError()));
         }
         int t = getOrder(mag, OP_SELL);
         while( t >= 0)
         {
            nClosed += OrderLots();
            if( OrderClose(OrderTicket(),OrderLots(),Bid,50,White) != true)
            {
               Print("Close order error:",ErrorDescription(GetLastError()));
            }
             t = getOrder(mag, OP_SELL);
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
         t = getOrder(mag, OP_SELL);
         while( t >= 0)
         {
            if( OrderClose(OrderTicket(),OrderLots(),Ask,50,White) != true)
            {
               Print("Close order error:",ErrorDescription(GetLastError()));
            }
             nClosed++;
             t = getOrder(mag, OP_SELL);
         }
         return(nClosed);
        }
      return(nClosed);
}

void ClosePendingOrder(int mag)
{
   int t = getOrder(mag, OP_SELLSTOP);
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
   double point = getPoint();
   //k线反转
   if( Period() >= 60 && EnableKReverse == 1)
   {  
      int timeframe = 0;
      int ii = 1;
      trendLineName = "K线反转";
      if( TimeCurrent() - dtime1 > 180)
      {
           Print("getBreakSignal K reverse: N+2=",iOpen(Symbol(), timeframe, ii+1),"-",iClose(Symbol(), timeframe, ii+1),
                  "N+1=",iOpen(Symbol(), timeframe, ii),"-",iClose(Symbol(), timeframe, ii));
      }

      if( iOpen(Symbol(), timeframe, ii+1) >= iClose(Symbol(), timeframe, ii+1)+KSpace*point &&  //ii+1 is down
          iOpen(Symbol(), timeframe, ii) <= iClose(Symbol(), timeframe, ii)-KSpace*point && //ii is up
          iClose(Symbol(), timeframe, ii) > iOpen(Symbol(), timeframe, ii+1) ) //ii is reverse ii+1
      {
         dtime1 = TimeCurrent(); return 0;
      }
      if( iOpen(Symbol(), timeframe, ii+1) <= iClose(Symbol(), timeframe, ii+1)-KSpace*point &&  //ii+1 is up
          iOpen(Symbol(), timeframe, ii) >= iClose(Symbol(), timeframe, ii)+KSpace*point && //ii is down
          iClose(Symbol(), timeframe, ii) < iOpen(Symbol(), timeframe, ii+1) ) //ii is reverse ii+1
      {
         dtime1 = TimeCurrent(); return 1;
      }
   }
   dtime1 = TimeCurrent();
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
           break;
         case OBJ_TREND :
         case OBJ_TRENDBYANGLE :
           for( j = 1; j <= 3; j++) price[j] = ObjectGetValueByShift(trendLineName, j);
           ///Print("ObjName=",ObjName,"y1=",y1,"y2=",y2);
           break;
         default :
           continue;
       }
       if( TimeCurrent() - dtime2 > 180)
       {
           Print("getBreakSignal Line: ", trendLineName, " price1=",price[1]," price2=",price[2]," price3=",price[3],"Close[1]=",Close[1]);
       }
       int r = getSignal(price);
       if( r >= 0){ dtime2 = TimeCurrent(); return r;}
    }
    dtime2 = TimeCurrent();
    trendLineName = "";
    if( Period() < 60 || EnableInd == 0) return(-1);
    int ct = ChartIndicatorsTotal(0,0);
    int ret;
    if( TestFlag == 1) ct = 1;
    for( int ck = 0; ck < ct; ck++) 
    {
      if( TestFlag == 1) indName = "Bands(50)";
      else indName = ChartIndicatorName(0, 0, ck);
      /*
      if( StringFind(indName, "Bands") >= 0)
      {
         for( int bk = 0; bk <=2; bk++)
         {
            ret = getIndPrice(indName, price, bk); //MODE_MAIN 0 MODE_UPPER 1 MODE_LOWER 2
            if( ret < 0) continue;
            r = getSignal(price);
            if( r >= 0) return r;
         }
      }
      else
      */
      {
      ret = getIndPrice(indName, price);
      if( ret < 0) continue;
      if( TimeCurrent() - dtime5 > 180)
      {
           Print("getBreakSignal Indicator: ", indName, " price=",price[1]," price2=",price[2]," price3=",price[3],"Close[1]=",Close[1]);
      }         
      r = getSignal(price);
      if( r >= 0){dtime5 = TimeCurrent();  return r;}
      }     
    }
    dtime5 = TimeCurrent();
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
             if( TimeCurrent() - dtime4 > 180)
             {
                 dtime4 = TimeCurrent();
                 Print("getSignal: Find signale(M",Period(),") ",trendLineName, "-", indName, "close[1]=",Close[1],"signal price=",price[1],"gap=",MathAbs(Close[1]-price[1]));
             } 
             if( Period() < 60 && MathAbs(Close[1] - price[1]) > MaxGap * getPoint() ){ ret = -1; }
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

int getIndPrice(string name, double& price[4], int mode= 0)
{
   int para = getParam(name);
   if( para < 0) return -1;
   int j;
   if( StringFind(name, "Bands", 0) >= 0)
   {
      for( j = 1; j <= 3; j++) price[j] = iBands(Symbol(),0,para,2,0,PRICE_CLOSE,mode,j);     
      return 0;
   }
   else if(StringFind(name, "MA", 0) >= 0)
   {
      for( j = 1; j <= 3; j++) price[j] = iMA(Symbol(),0,para,0,MODE_SMA,PRICE_CLOSE,j);
      return 0;
   }
   return -1;
}

void SetObject(string name,datetime T1,double P1,datetime T2,double P2,color clr)
  {
   if(ObjectFind(name) == -1)
     {
       ObjectCreate(name, OBJ_TREND, 0, T1, P1, T2, P2);
       ObjectSet(name, OBJPROP_COLOR, clr);
       ObjectSet(name, OBJPROP_STYLE, STYLE_DOT);
     }
   else
     {
       ObjectSet(name, OBJPROP_TIME1, T1);
       ObjectSet(name, OBJPROP_PRICE1, P1);
       ObjectSet(name, OBJPROP_TIME2, T2);
       ObjectSet(name, OBJPROP_PRICE2, P2);
       ObjectSet(name, OBJPROP_COLOR, clr);
       ObjectSet(name, OBJPROP_STYLE, STYLE_DOT);
     } 
  }
// the end.
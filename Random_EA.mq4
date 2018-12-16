//+------------------------------------------------------------------+
//|                                                    Random EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

// This is a VERY basic EA, designed to simulate placing trades at random in the Strategy Tester.
// This EA is NOT designed to be used to trade live with real money. Neither the strategy nor the code are adequate to use with real money!
// This EA is not desgined to be used to place trades on a demo server. There is not sufficient error reporting or handling to do this.
// This EA only places 1 trade at a time, and a maximum of 1 trade per bar. Trades are placed at the start of the bar only.
// You can chose the percentage chance that a trade will be made in any given bar, and the stop loss and take profit.
// You can also chose to use random stop loss and take profit sizes each trade (randomised between the values of 100 to 1000 points).
// Select LotsizeType 0 if you want to test a dynamic lotsize which risks a certain percentage of the account per trade.
//    - the ammount risked per trade may change if the desired lotsize is above or below the lotsize thresholds of the server.
// Select LotsizeType 1 if you want to use a constant lotize value according to StaticLotsize.

#property copyright ""
#property link      ""

// External variables ----

extern int OptimizationNumber = 0;  // Use this number when running multiple optimizations

extern int PercentageTradeChancePerBar = 10; // percentage chance to trade during any given bar

extern int LotsizeType = 1;  // 0 = lotsize determined by % of account risked per trade, 1 = static lotsize
extern double StaticLotsize = 0.01;
extern double MaxDecimalPercentRiskPerTrade = 0.01;  // as a "decimal percent", so 0.01 means 1% and 0.2 means 20% for example.

extern double SLPoints = 300; // this is a measure of the number of points lost (including points lost as spread)
extern double TPPoints = 300; // this is a measure of the number of points gained (after points lost to spread are removed)
extern bool UseRandomTPSL = false; // select true to use randomized SL and TP each trade (between values of 100 to 1000 points).

// Internal variables ----

double SlippagePoints = 30;
int random_number;
int bars_count;
int once_per_bar;
double lotsize;
int digits;
double points;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

// Check that this is being run on a backtest or optimization ----
if ( (IsTesting() == false) && (IsOptimization() == false) )
   { Alert("This EA is not designed to run on live data !!"); }

// Check that StaticLotsize is within the lotsizes permitted ----
if ( StaticLotsize < MarketInfo(Symbol(), MODE_MINLOT) )
   { StaticLotsize = MarketInfo(Symbol(), MODE_MINLOT); Alert("StaticLotsize has been changed to "+StaticLotsize+"."); }
if ( StaticLotsize > MarketInfo(Symbol(), MODE_MAXLOT) )
   { StaticLotsize = MarketInfo(Symbol(), MODE_MINLOT); Alert("StaticLotsize has been changed to "+StaticLotsize+"."); }   

// Find digits for this currency for use later on ----
digits = MarketInfo(Symbol(), MODE_DIGITS);
points = MarketInfo(Symbol(), MODE_POINT);

// Seed the random generator for use later on ----  
int random_seed;
random_seed = GetTickCount();  
MathSrand(random_seed);    
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
   
// Check to see if this is new bar, and reset once_per_bar if it is ---- 
if ( bars_count != Bars )
   { once_per_bar = 0; }   
bars_count = Bars;   
   
// Only trade if there are no trades already open, and only place one trade per bar ----
if ( (OrdersTotal() == 0) && (once_per_bar == 0) )
   {
   
   if ( RANDOM(100) <= PercentageTradeChancePerBar )
      {
      
      if ( UseRandomTPSL == true )
         { SLPoints = RANDOM(1000); TPPoints = RANDOM(1000); }
      
      lotsize = LOTSIZE(); 
      
      random_number = RANDOM(3); 
      
      // 50% chance to make a long trade ----
      if ( (random_number > 2.0) && (lotsize > 0.0) )
         {       
         RefreshRates();
         if ( OrderSend(Symbol(), OP_BUY, lotsize, NormalizeDouble(Ask,digits), (SlippagePoints*points), NormalizeDouble(Ask-(SLPoints*points),digits), NormalizeDouble(Ask+(TPPoints*points),digits), "", 0, 0, Lime) == false )
         { Print(GetLastError()); } 
         }

      // 50% chance to make a short trade ----
      if ( (random_number < 2.0) && (lotsize > 0.0) )
         {
         RefreshRates();
         if ( OrderSend(Symbol(), OP_SELL, lotsize, NormalizeDouble(Bid,digits), (SlippagePoints*points), NormalizeDouble(Bid+(SLPoints*points),digits), NormalizeDouble(Bid-(TPPoints*points),digits), "", 0, 0, Red) == false )
         { Print(GetLastError()); }     
         }
      
      }
   
   }   

// Toggle once_per_bar to show that bar is complete ----   
once_per_bar = 1;   
      
//----
   return(0);
  }
//+------------------------------------------------------------------+


// FUNCTIONS --------------------------------------------------------
// ------------------------------------------------------------------

int RANDOM(int f_random_range)        // This function returns a random number between 0 and "random_range"
{
double f_ret;
f_ret = (MathRand()%f_random_range+1);
return(f_ret);
} 

double LOTSIZE()        // This function determines the lotsize to use in the order
{
double f_lotsize; f_lotsize = 0;
double f_deposit_money_value_per_point;
double f_required_margin;
double f_lotstep;

if ( LotsizeType == 0 ) // dynamic lotsize
   {
   
   f_deposit_money_value_per_point = MarketInfo(Symbol(), MODE_TICKVALUE);
   f_required_margin = MarketInfo(Symbol(), MODE_MARGINREQUIRED); 
   f_lotstep = MarketInfo(Symbol(), MODE_LOTSTEP);

   if ( (points != 0) && ((SLPoints * f_deposit_money_value_per_point) != 0) )
      {
      if ( (SLPoints * f_deposit_money_value_per_point) != 0 )      
         { f_lotsize = (AccountBalance() * MaxDecimalPercentRiskPerTrade) / (SLPoints * f_deposit_money_value_per_point); }
      else { Alert("(points == 0) || ((SLPoints * f_deposit_money_value_per_point) != 0) == 0 in LOTSIZE() function."); }   
      } 
   else { Alert("points == 0 in LOTSIZE() function."); } 
            
   if ( points != 0 )
      {  
      while ( ( (f_lotsize*f_required_margin) + ((SLPoints * f_deposit_money_value_per_point)*f_lotsize) ) > (AccountBalance()-(f_lotsize * f_required_margin * MaxDecimalPercentRiskPerTrade)) )
            { f_lotsize = f_lotsize - 0.01; }
      } 
   else { Alert("points == 0 in LOTSIZE() function."); }                  
          
   if ( f_lotstep != 0 ) 
      { f_lotsize = f_lotstep*(MathFloor(f_lotsize/f_lotstep)); }
   else { Alert("f_lotStep == 0 in LOTSIZE() function."); }
         
   if ( f_lotstep == 0 )
      { Alert("f_lotStep == 0."); } 
       
   if ( f_lotsize < MarketInfo(Symbol(), MODE_MINLOT) )
      { f_lotsize = MarketInfo(Symbol(), MODE_MINLOT); Alert("f_lotsize was too small. Now changed to "+f_lotsize+"."); }
   if ( f_lotsize > MarketInfo(Symbol(), MODE_MAXLOT) )
      { f_lotsize = MarketInfo(Symbol(), MODE_MINLOT); Alert("f_lotsize was too big. Now changed to "+f_lotsize+"."); }   

   }

if ( LotsizeType == 1 )  // static lotsize
   { f_lotsize = StaticLotsize; }

f_lotsize = NormalizeDouble(f_lotsize,2);

return(f_lotsize);
}
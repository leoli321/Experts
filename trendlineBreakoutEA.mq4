string VERSION = "TL BO 1.0";

// external global variables
extern int EXT_SWINGS = 2; // swing level, 0 is lowest, 2 is most common
extern int EXT_NO_SWING_LMT = 12; // don't consider the latest X bars as swing points to draw trend lines 
extern int EXT_ATR = 300; // ATR(x)
extern double EXT_ATR_MAX_SLOPE = 0.05; // multiple of ATR that would be considered maximum slope 
extern double EXT_ATR_BUFFER = 0.05; // multiple of ATR to add to low/high for it to be considered a "touch"
extern int EXT_NULL_CLOSES = 0; // number of closes beyond trend line to nullify it as a valid trend line
extern int EXT_NUM_TOUCHES = 3; // (inclusive) number of touches needed to be considered a valid trend line
extern int EXT_RES_COLOR = IndianRed; // horizontal resistance line http://docs.mql4.com/constants/colors
extern int EXT_SUP_COLOR = PaleGreen; // horizontal support line http://docs.mql4.com/constants/colors
extern int EXT_SLOPE_RES_COLOR = LightSalmon; // sloping resistance line http://docs.mql4.com/constants/colors
extern int EXT_SLOPE_SUP_COLOR = Lime; // sloping support line http://docs.mql4.com/constants/colors
extern double EXT_ATR_INI_STOP = 0.1; // additional buffer to add beyond the initial stop
extern int EXT_LOOKBACK = 3; // number of bars to find highest high/lowest low
extern double EXT_RISK_MINAMT = 50; // dollar value of the minimum amount to risk per trade
extern double EXT_RISK_DIVISOR = 10; // AccountBalance/X = risk per trade
extern int EXT_MAX_SLIP = 10; // maximum points of slippage allowed for order 10 = 1 pip
extern double EXT_ATR_TRAILSTOP = 2; // multiple for trailing the market ATR(EXT_ATR) * X
extern double EXT_ATR_BO = 2; // multiple of ATR to determine if bar is a BO

// global variables
datetime NOWPER;
int GATE_ACTIVE, TRADE_TKT;
double EXIT_PRICE, TRADE_LOTS, GATE_RES, GATE_SUP;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
//----
	string sym = Symbol();
	int per = Period();
	// check if currency is active
	GATE_ACTIVE = isActive( sym, false );
  // remove all previous trend lines and plots
  ObjectsDeleteAll( 0 );
  // get resistance line
  GATE_RES = getTrendLine( sym, per, true );
  // get support line
  GATE_SUP = getTrendLine( sym, per, false );

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
	string sym = Symbol();
	int per = Period();
	int d = Digits;
  datetime t = iTime( sym, per, 0 );

  // if the system is not active, look for a new position
	if ( GATE_ACTIVE == -1 ) {
		// looking for breakouts UP
		if ( GATE_RES > 0 ) {
			if ( Bid > GATE_RES && GATE_RES > 0 && isBO( sym, per, true ) && getTrend( sym, per, true ) > 0 ) doBuy( sym, per );
		}
		// looking for breakouts DOWN
	  if ( GATE_SUP > 0 ) {
	  	if ( Bid < GATE_SUP && GATE_SUP > 0 && isBO( sym, per, false ) && getTrend( sym, per, false ) < 0 ) doSell( sym, per );
	  }
	} else {
		// first we'll check to see if the exit price has been hit
		// LONG trades
		if ( GATE_ACTIVE == OP_BUY && EXIT_PRICE > Bid && EXIT_PRICE > 0 ) exitNow( sym, TRADE_TKT, TRADE_LOTS, Bid );
		// SHORT trades
		if ( GATE_ACTIVE == OP_SELL && Ask > EXIT_PRICE && EXIT_PRICE > 0 ) exitNow( sym, TRADE_TKT, TRADE_LOTS, Ask );

		// if the gate is active let's analyse whether it's stop loss needs amending
		GATE_ACTIVE = isActive( sym, true );
	}

	// only do at the change of every bar
	if ( t != NOWPER ) {

	  GATE_RES = getTrendLine( sym, per, true );
	  GATE_SUP = getTrendLine( sym, per, false );

	  // let's comment the values of the trend line to see what their price is
	  Comment( "RES=" + DoubleToStr( GATE_RES, d ) + "  SUP=" + DoubleToStr( GATE_SUP, d ) );

	  NOWPER = t;

	}

//----
   return(0);
}
//+------------------------------------------------------------------+

// this function will determine whether the current bar is a breakout bar
bool isBO( string sym, int per, bool isUp ) {
	// get the multiplier of ATR to determine if it has broken out
	double bo = EXT_ATR_BO * iATR( sym, per, EXT_ATR, 1 );
	// check current bar to determine if breakout has happened
	if ( isUp && iClose( sym, per, 0 ) - iOpen( sym, per, 0 ) > bo ) return ( true );
	if ( !isUp && iOpen( sym, per, 0 ) - iClose( sym, per, 0 ) > bo ) return ( true );
	return( false );
}

// this function will determine the trend
int getTrend( string sym, int per, bool isUp ) {
	// checking if price is greater than it's MA(300)
	if ( isUp && iClose( sym, per, 0 ) > iMA( sym, per, 300, 0, MODE_SMA, PRICE_CLOSE, 0 ) ) return ( 1 );
	// checking if price is less than it's MA(300)
	if ( !isUp && iClose( sym, per, 0 ) < iMA( sym, per, 300, 0, MODE_SMA, PRICE_CLOSE, 0 ) ) return ( -1 );
	return( 0 );
}


// placing an at-market sell order
int doSell( string sym, int per ) {
	// check whether the system is allowed to place a trade
	int trade = checkIsTradeAllowed(), tkt = 0;
	if ( trade == 0 ) RefreshRates();
	if ( trade > 0 ) {
		// order type
		int ord = OP_SELL;
		// get entry price
		double entry = Bid;
		// get spread as SELL orders pay the spread on their exit
		double spread = MarketInfo( sym, MODE_SPREAD ) * MarketInfo( sym, MODE_POINT );
		// get initial stop loss - we will use the highest high over X periods plus a buffer
		double exit = N( iHigh( sym, per, iHighest( sym, per, MODE_HIGH, EXT_LOOKBACK, 0 ) ) + ( EXT_ATR_INI_STOP * iATR( sym, per, EXT_ATR, 1 ) ) );
		// add spread to initial stop loss value
		exit += spread;
		// check if stop loss is beyond the currency's stop level
		double stopPt = MarketInfo( sym, MODE_STOPLEVEL ) * MarketInfo( sym, MODE_POINT );
		// if not amend the exit to meet stop level requirements
		if ( MathAbs( entry - exit ) < stopPt ) exit = entry + stopPt;
		// get the amount to risk per trade
		double riskAmt = getRiskAmount();
		// now calculate what the amount risked per trade equates to in lot size
		double lots = MathMax( getLots( sym, entry, exit, riskAmt ), MarketInfo( sym, MODE_LOTSTEP ) );
		// as we have an at market ordering process we don't need an expiry value
		datetime expy = 0;
		// storing a value for the MagicNumber can be subjective, you can do whatever you want, I will just use
		// the active chart's Period() value
		int magic = per;
		// our last minute check to see that we DON'T have an active open order on this currency
		// if we do exit this function with 0
		if ( isActive( sym, false ) ) return( 0 );
		// submit AT MARKET sell order
		tkt = OrderSend( sym, ord, lots, entry, EXT_MAX_SLIP, exit, 0, VERSION, magic, expy, 0 );
		if ( tkt > 0 ) {
			// change the active currency's GATE_ACTIVE flag to true
			GATE_ACTIVE = ord;
			// set global exit price
			EXIT_PRICE = exit;
			// our entry order has been placed let's now notify ourselves of the order
			SendMail( "NEW SELL Order " + sym, 
				"Entry = " + D( entry ) + "\n" +
				"StopLoss = " + D( exit ) + "\n" +
				"Initial Risk = " + D( riskAmt, 2 ) + "\n" +
				"Actual Risk = " + D( profitAtStop( sym, entry, exit, lots, OP_SELL ), 2 ) + "\n" +
				"Lots = " + D( lots, 2 ) + "\n" +
				"Expiry = " + TimeToStr( expy ) + "\n" +
				"MagicNum = " + magic + "\n" +
				"HHV = " + D( iHigh( sym, per, iHighest( sym, per, MODE_HIGH, EXT_LOOKBACK, 0 ) ) ) + "\n" +
				"Version = " + VERSION + "\n"
			);
		} else if ( tkt == -1 ) {
			// here's what we will do when something goes wrong - try to return as much details as possible
			if ( GetLastError() > 0 ) {
				SendMail( "ERR with NEW SELL Order " + sym,
					"Entry = " + D( entry ) + "\n" +
					"StopLoss = " + D( exit ) + "\n" +
					"Initial Risk = " + D( riskAmt, 2 ) + "\n" +
					"Actual Risk = " + D( profitAtStop( sym, entry, exit, lots, OP_SELL ), 2 ) + "\n" +
					"Lots = " + D( lots, 2 ) + "\n" +
					"Expiry = " + TimeToStr( expy ) + "\n" +
					"MagicNum = " + magic + "\n" + 					
					"HHV = " + D( iHigh( sym, per, iHighest( sym, per, MODE_HIGH, EXT_LOOKBACK, 0 ) ) ) + "\n" +
					"Version = " + VERSION + "\n"
				);
			}
		}
	}
	return ( tkt );
}

int doBuy( string sym, int per ) {
	int trade = checkIsTradeAllowed(), tkt = 0;
	if ( trade == 0 ) RefreshRates();
	if ( trade > 0 ) {
		int ord = OP_BUY;		
		double entry = Ask; // spread paid at entry
		double exit = N( iLow( sym, per, iLowest( sym, per, MODE_LOW, EXT_LOOKBACK, 0 ) ) - ( EXT_ATR_INI_STOP * iATR( sym, per, EXT_ATR, 1 )) ); // bid price
		double stopPt = MarketInfo( sym, MODE_STOPLEVEL ) * MarketInfo( sym, MODE_POINT );
		if ( MathAbs( entry - exit ) < stopPt ) exit = entry - stopPt;
		double riskAmt = getRiskAmount();
		double lots = MathMax( getLots( sym, entry, exit, riskAmt ), MarketInfo( sym, MODE_LOTSTEP ) );
		datetime expy = 0;
		int magic = per;
		if ( isActive( sym, false ) ) return( 0 ); // last minute check!
		// submit AT MARKET entry order
		tkt = OrderSend( sym, ord, lots, entry, EXT_MAX_SLIP, exit, 0, VERSION, magic, expy, 0 ); 
		if ( tkt > 0 ) {
			GATE_ACTIVE = ord;
			EXIT_PRICE = exit;
			SendMail( "NEW BUY Order for " + sym, 
				"Entry = " + D( entry ) + "\n" +
				"StopLoss = " + D( exit ) + "\n" +
				"Initial Risk = " + D( riskAmt, 2 ) + "\n" +
				"Actual Risk = " + D( profitAtStop( sym, entry, exit, lots, OP_BUY ), 2 ) + "\n" +
				"Lots = " + D( lots, 2 ) + "\n" +
				"Expiry = " + TimeToStr( expy ) + "\n" +
				"MagicNum = " + magic + "\n" + 
				"LLV = " + D( iLow( sym, per, iLowest( sym, per, MODE_LOW, EXT_LOOKBACK, 0 ) ) ) + "\n" +
				"Version = " + VERSION
			);
		} else if ( tkt == -1 ) {
			if ( GetLastError() > 0 ) {
				SendMail( "ERR with NEW BUY Order for " + sym,
					"Entry = " + D( entry ) + "\n" +
					"StopLoss = " + D( exit ) + "\n" +
					"Initial Risk = " + D( riskAmt, 2 ) + "\n" +
					"Actual Risk = " + D( profitAtStop( sym, entry, exit, lots, OP_BUY ), 2 ) + "\n" +
					"Lots = " + D( lots, 2 ) + "\n" +
					"Expiry = " + TimeToStr( expy ) + "\n" +
					"MagicNum = " + magic + "\n" + 
					"LLV = " + D( iLow( sym, per, iLowest( sym, per, MODE_LOW, EXT_LOOKBACK, 0 ) ) ) + "\n" +
					"Version = " + VERSION
				);
			}
		}
	}
	return( tkt );
}


// amended from http://articles.mql4.com/141
int checkIsTradeAllowed( uint MaxWaiting_sec = 30 ) {
	// check firstly whether it's the end of the forex day
	// Pepperstone will not allow us to trade between 17:00 - 17:05 NY EST
	if ( Hour() == 0 && Minute() < 5 ) {
			Print( "Cannot trade during this time, closing market" );
			return( -1 );
	}
	if ( !IsTradeAllowed() ) {
		uint StartWaitingTime = GetTickCount();
		while( true ) {
			if ( IsStopped() ) {
				Print("The expert was terminated by the user!");
				return( -1 );
			} 
			if ( GetTickCount() - StartWaitingTime > MaxWaiting_sec * 1000 ) {
				Print("Waiting limit exceeded");
				return( -2 );
			}
			if ( IsTradeAllowed() ) return( 0 );
			Sleep( 100 );
		}
	} else {
		return( 1 );
	}
	return( -1 );
}


// calculates the amount of money to risk per trade
double getRiskAmount() {
	return( MathMax( EXT_RISK_MINAMT, ( AccountBalance() + getStopPL() ) / EXT_RISK_DIVISOR ) );
}

// calculates the total profit/loss of all open positions as though every open trade were to 
// exit immediately at their current stop prices
double getStopPL() {
  int tot = OrdersTotal();
	double result = 0;
	for( int i = tot; i >= 0; i -= 1 ) {
		if ( OrderSelect( i, SELECT_BY_POS, MODE_TRADES) ) {
			result += profitAtStop( OrderSymbol(), OrderOpenPrice(), OrderStopLoss(), OrderLots(), OrderType() );		
		}
	}
	return( result );
}

// calculates the profit/loss of the trade if it's stop is hit
double profitAtStop( string sym, double open, double stop, double lots, int type ) {    
    double result = lots * MarketInfo( sym, MODE_TICKVALUE ) / MarketInfo( sym, MODE_TICKSIZE );
    if ( type == OP_BUY ) {
        return( N( ( stop - open ) * result, 2 ) );
    } else if ( type == OP_SELL ) {
        return( N( ( open - stop ) * result, 2 ) );
    }
    return ( 0 );
}

// shortcut function to NormalizeDouble
double N( double d, int dig = 0 ) {
	if ( dig == 0 ) dig = Digits;
	return( NormalizeDouble( d, dig ) );
}


// calculates the position size of the trade according to entry, initial stop loss and risk
double getLots( string sym, double entry, double stop, double risk ) {
	double dist = MathAbs( entry - stop ),
				result = ( risk * MarketInfo( sym, MODE_TICKSIZE ) ) / ( dist * MarketInfo( sym, MODE_TICKVALUE ) );
	return( N( result, 2 ) ); 
}
 
// shortcut function to convert double to string
string D( double d, int dig = 0 ) {
	if ( dig == 0 ) dig = Digits;
	return( DoubleToStr( d, dig ) );
}

// check if the symbol currently has an open position
int isActive( string sym, bool checkStop ) {
	int tots = OrdersTotal();
	for ( int i = tots; i >= 0; i -= 1 ) {
		if ( OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) ) {
			if ( OrderSymbol() == sym ) {
				// check if we are checking the trailing stop on an active order
				if ( checkStop && OrderType() < 2 ) { 
					// as we are checking stops let's check this one
					// notice here how when we stored the OrderMagicNumber we used it to store the Period
					// the purpose of this is to help us differentiate what time period was used in case we
					// use multiple time frames for this EA on the same currency
					EXIT_PRICE = getTrailingStop( sym, OrderOpenPrice(), OrderStopLoss(), OrderOpenTime(), OrderMagicNumber(), OrderType() );
					TRADE_TKT = OrderTicket();
					TRADE_LOTS = OrderLots();
				}
				return ( OrderType() );
			}
		}
	}
	return ( -1 );
}

// this function requires the following parameters:
// sym = currency
// op = opening price of the current trade
// sl = stop loss price of the current trade
// ot = opening datetime of the current trade
// per = active chart's period - for calculating ATR distance properly
// type = order type of the current trade
double getTrailingStop( string sym, double op, double sl, datetime ot, int per, int type ) {
	double temp;	
	// make the result for this function initially equal the stop loss
	double result = sl;	
	// calculate the trailing stop distance
	double atr = iATR( sym, per, EXT_ATR, 1 ) * EXT_ATR_TRAILSTOP;
	// check if we are operating in the bar of entry, if so move to minute charts to find out
	// what the highest high or lowest low is since entry (rather than using the whole bar)
	// As Pepperstone timestamp their bars with the opening time of that bar we can frame
	// our logic by checking if the current bar is less than or equal to the current bar
	// if it is, then the current bar *IS* the bar of entry.
	if ( iTime( sym, per, 0 ) <= ot ) {
		temp = getMinutePrice( sym, ot, atr, type );
		if ( type == OP_BUY && temp > result ) result = temp;
		if ( type == OP_SELL && temp < result ) result = temp;
	}
	// get bars of current periods' chart	
	int b = iBars( sym, per );	
	// let's loop through the bars now, starting with the most recent bar
	for ( int i = 0; i < b; i += 1 ) {
		// if the time of the active chart is LESS than the time of when the trade opened, end
		if ( iTime( sym, per, i ) < ot ) break;
		// calculate the ATR trailing distance - using active chart's period
		// and always using the previous bar's ATR as the current bar is still
		// forming
		atr = iATR( sym, per, EXT_ATR, i+1 ) * EXT_ATR_TRAILSTOP;
		// for long trades
		if ( type == OP_BUY ) {
			// using the high of the minute chart subtract the ATR distance
			temp = iHigh( sym, per, i ) - atr;
			// compare against the current best result, and if it is better modify result
			if ( temp > result ) result = temp;
		// for short trades
		} else if ( type == OP_SELL ) {
			// using the low of the minute chart add the ATR distance
			temp = iLow( sym, per, i ) + atr;
			// compare against the current best result, and if it is better modify result
			if ( temp < result ) result = temp;
		}
	}
	// return the result, normalizing the double
	return ( N( result ) );
}

// this function will return the highest high or lowest low in the minute chart
// parameters of this function: 
// sym = currency's symbol
// ot = opening datetime of the trade
// atr = atr value used as trailing distance
// type = order type of the trade
double getMinutePrice( string sym, datetime ot, double atr, int type ) {
	int per = PERIOD_M1;
	int b = iBars( sym, per );
	// better to start with a value, rather than 0
	double result = iClose( sym, per, 0 );
	for ( int i = 0; i < b; i += 1 ) {
		// once the active bar is less than the opening time then we are analysing
		// bars PRIOR to entry, therefore exit
		if ( iTime( sym, per, i ) < ot ) break;
		if ( type == OP_BUY && iHigh( sym, per, i ) > result ) result = iHigh( sym, per, i );
		if ( type == OP_SELL && iLow( sym, per, i ) < result ) result = iLow( sym, per, i );
	}
	// now that we have found the highest value since entry let's subtract the atr distance
	if ( type == OP_BUY ) return( result - atr );
	// now that we hav found the lowest value since entry let's add the atr distance
	if ( type == OP_SELL ) return ( result + atr );
}

// this function exits at market, but needs the following params:
// sym = currency symbol
// tkt = trades' ticket number
// lots = trades' lot size
// p = price to exit at
bool exitNow( string sym, int tkt, double lots, double p ) {
	// check if it's okay to exit trade
	int trade = checkIsTradeAllowed();
	// place trade if ok to place order
	if ( trade > 0 ) {
		if ( OrderClose( tkt, lots, p, EXT_MAX_SLIP, 0 ) ) {
			// trade has successfuly closed
			EXIT_PRICE = 0;
			GATE_ACTIVE = -1; // reset
			// let's now loop through the historical trades and obtain some data to return
			int t = OrdersHistoryTotal();
			for ( int i = t; i >= 0; i -= 1 ) {
				if ( OrderSelect( i, SELECT_BY_POS, MODE_HISTORY ) ) {
					if ( OrderTicket() == tkt ) {
						double op = OrderOpenPrice();
						datetime ot = OrderOpenTime();
						double sl = OrderStopLoss();
						double pr = OrderProfit();
						int typ = OrderType();
						string d;
						if ( typ == 0 ) d = "LONG";
						if ( typ == 1 ) d = "SHORT";
						double cp = OrderClosePrice();
						datetime ct = OrderCloseTime();
						int mag = OrderMagicNumber();
						double comm = OrderCommission();
						double swap = OrderSwap();
						double slip;
						if ( typ == OP_BUY ) slip = cp - p;
						if ( typ == OP_SELL ) slip = p - cp;
						break;
					}
				}
			}
			// Send alerts
			SendMail( "EXIT of " + d + " for " + sym, 
				"PROFIT/LOSS = " + D( pr, 2 ) + "\n" +
				"ALERT price = " + D( p ) + "\n" +
				"CLOSE price = " + D( cp ) + "\n" +
				"CLOSE time = " + TimeToStr( ct ) + "\n" +
				"COMMISSION charged = " + D( comm, 2 ) + "\n" +
				"SWAP charges = " + D( swap, 2 ) + "\n" +
				"SLIPPAGE = " + D( slip ) + "\n" +
				"\n" +
				"OPEN price = " + D( op ) + "\n" +
				"OPEN time = " + TimeToStr( ot ) + "\n" +
				"MAGIC number = " + mag + "\n" +
				"STOP LOSS = " + D( sl ) + "\n"
			);
			return( true );
		} else {
			// alert at the failure of closing the trade
			SendMail("ERR EXIT of " + d + " for " + sym, 
				"ERR = " + GetLastError() + "\n" +
				"ALERT price = " + D( p ) + "\n" +
				"CLOSE price = " + D( cp ) + "\n" +
				"CLOSE time = " + TimeToStr( ct ) + "\n"
			);
		}
	}
	return( false );
}

//
// TREND LINE SCRIPTS
//

double getTrendLine( string sym, int per, bool isUp ) {
   int swingArray[], tempArray[];
   initBarsArray( sym, per, swingArray ); // initialise array with all bars

   // refine the array according to the swing level set
   for ( int s = 0; s <= EXT_SWINGS; s += 1 ) {
      int arrLen = ArraySize( swingArray );     
      for ( int a = 2; a < arrLen; a += 1 ) {
         if ( isUp ) {
            if ( isPeak( sym, swingArray[a-2], swingArray[a-1], swingArray[a], per ) ) intArrayPush( tempArray, swingArray[a-1] );
         } else {
            if ( isTrough( sym, swingArray[a-2], swingArray[a-1], swingArray[a], per ) ) intArrayPush( tempArray, swingArray[a-1] );
         }
      }
      // copy array
      flushArray( swingArray );
      ArrayCopy( swingArray, tempArray );
      flushArray( tempArray );
   }

   // now that we have an array of all valid swing points we test each combination
   // of points to determine whether they are trend lines that meet our specifications
   double result, tempResult;
   int arrSize = ArraySize( swingArray );
   for ( a = 0; a < arrSize; a += 1 ) {
      // first we will test the horizontal trend line value of this swing point
      tempResult = getLastValidPoint( sym, swingArray[a], swingArray[a], per, isUp );     

      // if we get a number other than zero from our valid point function we will plot this trend line
      if ( tempResult > 0 ) {
         // let's compare the last valid point of the horizontal trend line to see if
         // it is closer to price than our current result
         if ( result == 0 ) result = tempResult;
         if ( isUp && tempResult < result ) result = tempResult;
         if ( !isUp && tempResult > result ) result = tempResult;

         // draw trend line
         if ( isUp ) {
            ObjectCreate( "Res@" + swingArray[a],OBJ_TREND,0,Time[swingArray[a]],High[swingArray[a]],Time[0], tempResult );
            ObjectSet( "Res@" + swingArray[a], OBJPROP_STYLE, STYLE_SOLID );
            ObjectSet( "Res@" + swingArray[a], OBJPROP_COLOR, EXT_RES_COLOR ); 
         } else {
            ObjectCreate( "Sup@" + swingArray[a],OBJ_TREND,0,Time[swingArray[a]],Low[swingArray[a]],Time[0], tempResult );
            ObjectSet( "Sup@" + swingArray[a], OBJPROP_STYLE, STYLE_SOLID );
            ObjectSet( "Sup@" + swingArray[a], OBJPROP_COLOR, EXT_SUP_COLOR ); 
         }
      }

      // next we'll test sloping trend lines
      for ( int b = a + 1; b < arrSize; b += 1 ) {
         // get last valid point of sloping trend line
         tempResult = getLastValidPoint( sym, swingArray[a], swingArray[b], per, isUp );

         if ( tempResult > 0 ) {
            // let's compare the last valid point of the sloping trend line to see if
            // it is closer to price than our current result
            if ( result == 0 ) result = tempResult;
            if ( isUp && tempResult < result ) result = tempResult;
            if ( !isUp && tempResult > result ) result = tempResult;

            // draw trend line
            if ( isUp ) {
               ObjectCreate( "SlopeRes@" + swingArray[a],OBJ_TREND,0,Time[swingArray[a]],High[swingArray[a]],Time[0], tempResult );
               ObjectSet( "SlopeRes@" + swingArray[a], OBJPROP_STYLE, STYLE_SOLID );
               ObjectSet( "SlopeRes@" + swingArray[a], OBJPROP_COLOR, EXT_SLOPE_RES_COLOR ); 
            } else {
               ObjectCreate( "SlopeSup@" + swingArray[a],OBJ_TREND,0,Time[swingArray[a]],Low[swingArray[a]],Time[0], tempResult );
               ObjectSet( "SlopeSup@" + swingArray[a], OBJPROP_STYLE, STYLE_SOLID );
               ObjectSet( "SlopeSup@" + swingArray[a], OBJPROP_COLOR, EXT_SLOPE_SUP_COLOR ); 
            }
         }
      }
   }

   // return the value of the closest trend line's current value
   return ( result );
}

void intArrayPush( int& arr[], int elem ) {
   int size = ArraySize( arr );
   ArrayResize( arr, size + 1 );
   arr[ size ] = elem;
}

void initBarsArray( string sym, int per, int& arr[] ) {
   int b = iBars( sym, per );
   for ( int i = b - 1; i > EXT_NO_SWING_LMT; i -= 1 ) {
      intArrayPush( arr, i );
   }
}

void flushArray( int& arr[] ) {
   ArrayInitialize( arr, 0 );
   ArrayResize( arr, 0 );
}

bool isTrough( string sym, int left, int mid, int right, int per ) {
   if ( iLow( sym, per, left ) >= iLow( sym, per, mid ) && iLow( sym, per, mid ) < iLow( sym, per, right ) ) return ( true );
   return ( false ); 
}

bool isPeak( string sym, int left, int mid, int right, int per ) {
   if ( iHigh( sym, per, left ) <= iHigh( sym, per, mid ) && iHigh( sym, per, mid ) > iHigh( sym, per, right ) ) return ( true );
   return ( false );
}

double getLastValidPoint( string sym, int b1, int b2, int per, bool isUp ) {
   // first we'll obtain the slope of the trend line to check its gradient
   double slope = getSlope( sym, b1, b2, per, isUp ), pt, buffer;

   // we will use a multiple of the ATR to check whether a trend line is too sharp
   // if it is we will exit with a value of 0
   if ( MathAbs( slope ) > iATR( sym, per, EXT_ATR, 0 ) * EXT_ATR_MAX_SLOPE ) return ( 0 );

   // otherwise we will now test whether the trend line has had the right amount of
   // touches without exceeding the number of closes beyond it.
   int x = 0, t = 0, lastTouch;
   for ( int i = b1; i >= 0; i -= 1 ) {
      // adding a buffer in case price gets close to trend line but doesn't actually touch
      buffer = iATR( sym, per, EXT_ATR, i ) * EXT_ATR_BUFFER; 

      if ( isUp ) {
         pt = iHigh( sym, per, b1 ) + ( slope * ( b1 - i ) );
         if ( iClose( sym, per, i ) > pt && i > 0 ) x += 1;
         // a "touch" is made when it has formed a peak
         if ( i == lastTouch && isPeak( sym, i+2, i+1, i, per ) ) t += 1;
         if ( iHigh( sym, per, i ) + buffer >= pt ) lastTouch = i-1; 
      } else {
         pt = iLow( sym, per, b1 ) + ( slope * ( b1 - i ) );         
         if ( iClose( sym, per, i ) < pt && i > 0 ) x += 1;
         // a "touch" is made when it has formed a trough
         if ( i == lastTouch && isTrough( sym, i+2, i+1, i, per ) ) t += 1;
         if ( iLow( sym, per, i ) - buffer <= pt ) lastTouch = i-1;     
      }     

      // check if trend line has broken the number of closes to nullify it
      if ( x > EXT_NULL_CLOSES ) {
         // we want to plot our broken lines, however, we only want to plot
         // those broken trend lines which exceeded our number of touches and which
         // didn't get broken between their swing points
         if ( i < b2 && t >= EXT_NUM_TOUCHES ) {
            if ( isUp ) {
               ObjectCreate( "BrokenTL@" + b1,OBJ_TREND,0,Time[b1],High[b1],Time[i], pt );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_RAY, false );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_STYLE, STYLE_SOLID );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_COLOR, EXT_SLOPE_RES_COLOR ); 
            } else {
               ObjectCreate( "BrokenTL@" + b1,OBJ_TREND,0,Time[b1],Low[b1],Time[i], pt );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_RAY, false );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_STYLE, STYLE_SOLID );
               ObjectSet( "BrokenTL@" + b1, OBJPROP_COLOR, EXT_SLOPE_SUP_COLOR ); 
            }
         }
         return ( 0 );
      }
   }

   // if trend line exceeds the number of touches return the current value of the trend line
   if ( t >= EXT_NUM_TOUCHES ) return ( pt );
   // otherwise return 0
   return ( 0 );
}

double getSlope( string sym, int b1, int b2, int per, bool isUp ) {
   if ( b1 == b2 ) return ( 0 );
   if ( isUp ) {
      return ( ( iHigh( sym, per, b1 ) - iHigh( sym, per, b2 ) ) / ( b2 - b1 ) ); // b2 - b1 is deliberate
   } else {
      return ( ( iLow( sym, per, b1 ) - iLow( sym, per, b2 ) ) / ( b2 - b1 ) ); // b2 - b1 is deliberate
   }
}
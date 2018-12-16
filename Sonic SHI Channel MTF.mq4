
#property copyright "Copyright © 2004, Shurka & Kevin"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 1
#property indicator_color1 CLR_NONE

extern bool    Indicator_On?                = true;
extern string  Select_the_chart_timeframe   = "0=default/currently open chart";
extern string  of_the_channel_you_want_on   = "1=M1, 5=M5, 15=M15, 30=M30";
extern string  the_currently_open_chart     = "60=H1, 240=H4, 1440=D, 10080=W"; 
extern int     Timeframe                    = 0;
extern int     AllBars                      = 240;
extern int     BarsForFract                 = 0;
extern int     ChannelLinesThickness_12345  = 1;
extern color   Color_M1_Channel             = Turquoise;
extern color   Color_M5_Channel             = SteelBlue;
extern color   Color_M15_Channel            = Lime;
extern color   Color_M30_Channel            = Silver;
extern color   Color_H1_Channel             = Magenta;
extern color   Color_H4_Channel             = DarkSlateBlue;
extern color   Color_D_Channel              = DarkOrange;
extern color   Color_W_Channel              = Red;

double g_ibuf_88[];
int gi_92 = 0;
double gd_96 = 0.0;
int gi_104 = -1;
int gi_108 = -1;
int gi_112 = 0;
double g_price_116 = 0.0;
double g_price_124 = 0.0;
double g_price_132 = 0.0;
int gi_140 = 0;
int gi_144 = 300;
int gi_148 = 0;
int gi_152 = 0;
double gd_156 = 0.0;
int g_datetime_164;
int g_datetime_168;
color g_color_172;

int init() {
   SetIndexStyle(0, DRAW_ARROW);
   SetIndexArrow(0, 164);
   SetIndexBuffer(0, g_ibuf_88);
   SetIndexEmptyValue(0, 0.0);
  
   if (Timeframe == 0) Timeframe = Period();
   return (0);
}

int deinit() {
   DelObj();
   return (0);
}

void DelObj() {   
   int obj_total= ObjectsTotal(); 
   for (int i= obj_total; i>=0; i--)
      {
      string name= ObjectName(i);   
      if (StringSubstr(name,0,6)=="shiMTF")  ObjectDelete(name);
      }    
}

int start() {
   if (Indicator_On? == false) {DelObj(); return(0);}
  
   int li_unused_0 = IndicatorCounted();
   if (AllBars == 0 || iBars(Symbol(), Timeframe) < AllBars) gi_144 = iBars(Symbol(), Timeframe);
   else gi_144 = AllBars;
   if (BarsForFract > 0) gi_148 = BarsForFract;
   
   else {
      switch (Timeframe) {
      
      case PERIOD_M1:
         gi_148 = 12;
         g_color_172 = Color_M1_Channel;
         break;
      case PERIOD_M5:
         gi_148 = 48;
         g_color_172 = Color_M5_Channel;
         break;
      case PERIOD_M15:
         gi_148 = 24;
         g_color_172 = Color_M15_Channel;
         break;
      case PERIOD_M30:
         gi_148 = 24;
         g_color_172 = Color_M30_Channel;
         break;
      case PERIOD_H1:
         gi_148 = 12;
         g_color_172 = Color_H1_Channel;
         break;
      case PERIOD_H4:
         gi_148 = 15;
         g_color_172 = Color_H4_Channel;
         break;
      case PERIOD_D1:
         gi_148 = 10;
         g_color_172 = Color_D_Channel;
         break;
      case PERIOD_W1:
         gi_148 = 6;
         g_color_172 = Color_W_Channel;
         break;
      default:
         DelObj();
         return (-1);
      }
   }
      
   gi_92 = 2;
   gi_104 = -1;
   gi_108 = -1;
   gi_112 = 0;
   while (gi_104 == -1 || gi_108 == -1 && gi_92 < gi_144) {
      if (gi_112 < 1 && gi_92 == iLowest(Symbol(), Timeframe, MODE_LOW, gi_148 << 1 + 1, gi_92 - gi_148)) {
         if (gi_112 == 0) {
            gi_112 = -1;
            gi_104 = gi_92;
            g_price_116 = iLow(Symbol(), Timeframe, gi_104);
         } else {
            gi_108 = gi_92;
            g_price_124 = iLow(Symbol(), Timeframe, gi_108);
         }
      }
      if (gi_112 > -1 && gi_92 == iHighest(Symbol(), Timeframe, MODE_HIGH, gi_148 << 1 + 1, gi_92 - gi_148)) {
         if (gi_112 == 0) {
            gi_112 = 1;
            gi_104 = gi_92;
            g_price_116 = iHigh(Symbol(), Timeframe, gi_104);
         } else {
            gi_108 = gi_92;
            g_price_124 = iHigh(Symbol(), Timeframe, gi_108);
         }
      }
      gi_92++;
   }
   if (gi_104 == -1 || gi_108 == -1) {
      DelObj();
      return (-1);
   }
   gd_96 = (g_price_124 - g_price_116) / (gi_108 - gi_104);
   g_price_116 -= gi_104 * gd_96;
   gi_104 = 0;
   gi_152 = 0;
   gd_156 = 0;
   if (gi_112 == 1) {
      g_price_132 = iLow(Symbol(), Timeframe, 2) - 2.0 * gd_96;
      for (gi_140 = 3; gi_140 <= gi_108; gi_140++)
         if (iLow(Symbol(), Timeframe, gi_140) < g_price_132 + gd_96 * gi_140) g_price_132 = iLow(Symbol(), Timeframe, gi_140) - gd_96 * gi_140;
      if (iLow(Symbol(), Timeframe, 0) < g_price_132) {
         gi_152 = 0;
         gd_156 = g_price_132;
      }
      if (iLow(Symbol(), Timeframe, 1) < g_price_132 + gd_96) {
         gi_152 = 1;
         gd_156 = g_price_132 + gd_96;
      }
      if (iHigh(Symbol(), Timeframe, 0) > g_price_116) {
         gi_152 = 0;
         gd_156 = g_price_116;
      }
      if (iHigh(Symbol(), Timeframe, 1) > g_price_116 + gd_96) {
         gi_152 = 1;
         gd_156 = g_price_116 + gd_96;
      }
   } else {
      g_price_132 = iHigh(Symbol(), Timeframe, 2) - 2.0 * gd_96;
      for (gi_140 = 3; gi_140 <= gi_108; gi_140++)
         if (iHigh(Symbol(), Timeframe, gi_140) > g_price_132 + gd_96 * gi_140) g_price_132 = iHigh(Symbol(), Timeframe, gi_140) - gi_140 * gd_96;
      if (iLow(Symbol(), Timeframe, 0) < g_price_116) {
         gi_152 = 0;
         gd_156 = g_price_116;
      }
      if (iLow(Symbol(), Timeframe, 1) < g_price_116 + gd_96) {
         gi_152 = 1;
         gd_156 = g_price_116 + gd_96;
      }
      if (iHigh(Symbol(), Timeframe, 0) > g_price_132) {
         gi_152 = 0;
         gd_156 = g_price_132;
      }
      if (iHigh(Symbol(), Timeframe, 1) > g_price_132 + gd_96) {
         gi_152 = 1;
         gd_156 = g_price_132 + gd_96;
      }
   }
   g_price_124 = g_price_116 + gi_144 * gd_96;
   g_datetime_164 = iTime(Symbol(), Timeframe, gi_104);
   g_datetime_168 = iTime(Symbol(), Timeframe, gi_144);
   if (gd_156 != 0.0) g_ibuf_88[gi_152] = gd_156;
   DelObj();
   string l_text_8 = " Channel size = " + DoubleToStr(MathAbs(g_price_132 - g_price_116) / Point, 0) + " Slope = " + DoubleToStr((-gd_96) / Point, 2);
   if (g_price_132 < g_price_116) {
      ObjectCreate("shiMTFTL1-" + Timeframe, OBJ_TREND, 0, g_datetime_168, g_price_132 + gd_96 * gi_144, g_datetime_164, g_price_132);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_WIDTH, ChannelLinesThickness_12345);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetText("shiMTFTL1-" + Timeframe, l_text_8);
      ObjectCreate("shiMTFTL2-" + Timeframe, OBJ_TREND, 0, g_datetime_168, g_price_124, g_datetime_164, g_price_116);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_WIDTH, ChannelLinesThickness_12345);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetText("shiMTFTL2-" + Timeframe, l_text_8);
      ObjectCreate("shiMTFMIDL-" + Timeframe, OBJ_TREND, 0, g_datetime_168, (g_price_124 + g_price_132 + gd_96 * gi_144) / 2.0, g_datetime_164, (g_price_116 + g_price_132) / 2.0);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_WIDTH, 1);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetText("shiMTFMIDL-" + Timeframe, l_text_8);
   }
   if (g_price_132 > g_price_116) {
      ObjectCreate("shiMTFTL2-" + Timeframe, OBJ_TREND, 0, g_datetime_168, g_price_132 + gd_96 * gi_144, g_datetime_164, g_price_132);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_WIDTH, ChannelLinesThickness_12345);
      ObjectSet("shiMTFTL2-" + Timeframe, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetText("shiMTFTL2-" + Timeframe, l_text_8);
      ObjectCreate("shiMTFTL1-" + Timeframe, OBJ_TREND, 0, g_datetime_168, g_price_124, g_datetime_164, g_price_116);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_WIDTH, ChannelLinesThickness_12345);
      ObjectSet("shiMTFTL1-" + Timeframe, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetText("shiMTFTL1-" + Timeframe, l_text_8);
      ObjectCreate("shiMTFMIDL-" + Timeframe, OBJ_TREND, 0, g_datetime_168, (g_price_124 + g_price_132 + gd_96 * gi_144) / 2.0, g_datetime_164, (g_price_116 + g_price_132) / 2.0);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_COLOR, g_color_172);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_WIDTH, 1);
      ObjectSet("shiMTFMIDL-" + Timeframe, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetText("shiMTFMIDL-" + Timeframe, l_text_8);
   }
   return (0);
}
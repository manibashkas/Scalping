//+------------------------------------------------------------------+
//|                                                  ScalperTits.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include  <C_MT\custom_functions_kit.mqh>
#include  <C_MT\C_TrailingStop.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
extern int pointTo = 30; // points to pending order
extern int stoploss_point = 21; // stoploss point exhibition
extern int takeprofit_point = 10;  // takeprofit point exhibition
extern double volume_L = 1.0; // initial lot
extern int max_risk = 5; // what amount of funds used to 1 order in %
extern bool Trailing_Stop = true;
extern int int_Trailing_Profit = 80; // Trailing Starts at profit *points
extern int int_Trailing_Stop_Level = 25; // Trailing distance *points
extern int int_trailing_Step = 5;      //  Trailing Step *points

double trailing_profit;
double trailing_stoplevel;
double trailing_step;

double stop_loss;
double take_profit;
double point_to_break;
double high; // high round level
double low; // low round level
double point; // current point
double correct_volume_L; // correct lot
double min_stoplevel; 
int slippage = 3;
int factor; // price factor
int magic = 111; // magic number

C_TrailingStop trailing_listener(magic);

double Optimal_Lot()
   {
      double free = AccountFreeMargin();
      double one_Lot = MarketInfo(Symbol(), MODE_MARGINREQUIRED);
      double lot = NormalizeDouble(free*max_risk/100/one_Lot, 3);
      double correct_lot = (lot > 1)?(MathFloor(lot)):lot;
      if(correct_lot < MarketInfo(Symbol(), MODE_MINLOT))
         {
            Print("lot size less than min lot. your lot should not be less than ", MarketInfo(Symbol(), MODE_MINLOT), 
                  " please check your depo or max risk");
            correct_lot = MarketInfo(Symbol(), MODE_MINLOT);
         }
      Print("Optimal lot is ", correct_lot);
      if(volume_L != correct_lot)
         Print("initial lot is not optimal with your max risk");
      
      return correct_lot;
   }

/*double GetVolume(double &volume) // correct volume calculation
   {
      double correct_volume = MarketInfo(Symbol(), MODE_MINLOT);
      double volume_step = MarketInfo(Symbol(), MODE_LOTSTEP);
      do
         correct_volume+=volume_step;
      while(correct_volume <= volume);
      correct_volume-=volume_step;
      return correct_volume;
   }*/

void GetLevels() // find roun levels
   {
      high = MathCeil(Ask*factor)/100;
      low = MathFloor(Bid*factor)/100;
   }
   
double CheckCross() // return -low if down, return 0 if nothing, high if up
   {
      if(Ask == high)
         return high;
      if(Bid == low)
         return -low;
      return 0;  
   }
   
void CustomOrderSend(double cross, double &correct_volume)
   {
      if(TimeHour(TimeCurrent()) > 20 && TimeHour(TimeCurrent()) < 23)
         {
            if(OrdersTotal())
               for(int i = 0; i< OrdersTotal(); i++)   
               if(OrderSelect(i, SELECT_BY_POS))
                  if(OrderMagicNumber() == magic)
                     if(OrderType() == OP_BUYLIMIT || OrderType() == OP_SELLLIMIT)
                        if(OrderDelete(OrderTicket()))
                           Print("Pending order deleted successfully");
            return;
         }
   
      if(!cross)
         return;
         
      if(OrdersTotal())
            for(int i = 0; i< OrdersTotal(); i++)   
               if(OrderSelect(i, SELECT_BY_POS))
                  if(OrderMagicNumber() == magic)
                     if(OrderComment() == DoubleToString(cross))
                        return;
                        
         
      double price;
      int cmd;
      double stoploss;
      double takeprofit;
      
      if(cross > 0)
         {
            price = cross + point_to_break;
            cmd = OP_SELLLIMIT;
            stoploss = price + stop_loss;
            takeprofit = price - take_profit;
         }
      else
         {
            price = -cross - point_to_break;
            cmd = OP_BUYLIMIT;
            stoploss = price - stop_loss;
            takeprofit = price + take_profit;
         }
         
      int ticket = OrderSend(Symbol(), cmd, Optimal_Lot(), price, slippage, stoploss,takeprofit,DoubleToString(cross),magic);
   }
   

int OnInit()
  {
   Optimal_Lot();
   stop_loss = Pips_to_Points(stoploss_point);
   take_profit = Pips_to_Points(takeprofit_point);
   point_to_break = Pips_to_Points(pointTo);
   
   min_stoplevel = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD))*point;
   CheckMinStopLevel(stop_loss, min_stoplevel, "stop loss");
  
   factor = (Digits%2 == 0)?100:1000;
   point = (Digits%2 == 0)?Point:Point*10;
   
   if(!Trailing_Stop)
         trailing_listener.TurnOff();
      
      if(Trailing_Stop)
         {
           // check Trailing Stop parameters 
         trailing_profit = Pips_to_Points(int_Trailing_Profit);
         trailing_stoplevel = Pips_to_Points(int_Trailing_Stop_Level);
         trailing_step = Pips_to_Points(int_trailing_Step);
         
         CheckMinStopLevel(trailing_profit,min_stoplevel, "Trailing Profit");
         CheckMinStopLevel(trailing_stoplevel,min_stoplevel, "Trailing Stop Level");
         
         trailing_listener.SetProfit(trailing_profit);
         trailing_listener.SetTrailingStopLevel(trailing_stoplevel);
         trailing_listener.SetTrailingStep(trailing_step);
         }
 
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CustomOrderSend(CheckCross(), correct_volume_L);
   
   GetLevels();
   trailing_listener.Monitor();
//---
   
  }
//+------------------------------------------------------------------+

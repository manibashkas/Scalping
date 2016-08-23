//+------------------------------------------------------------------+
//|                                                          RSG.mq4 |
//|                        Copyright 2016, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <C_MT\custom_functions_kit.mqh>
#include <C_MT\C_TrailingStop.mqh>
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//----------------------------------------------+
// EMA13                                        |
//  EMA21                                       |
//  MACD Histogram (13,21,1) - ˆ‚ÂÚ  –¿—Õ€…     |
//* MACD Histogram (21,34,1) - ˆ‚ÂÚ Œ–¿Õ∆≈¬€…   |
//* MACD Histogram (34,144,1) - ˆ‚ÂÚ «≈À≈Õ€…    |
//Ì‡ Ã5 ËÒÔÓÎ¸ÁÛÂÏ Ã¿—ƒ 21,34,1                 |
//----------------------------------------------+
extern int slippage = 3;
extern int stoploss_point = 10;
extern int takeprofit_point = 30;
extern double volume = 1;
extern bool Trailing_Stop = true;
extern int int_Trailing_Profit = 20; // Trailing Starts at profit *points
extern int int_Trailing_Stop_Level = 10; // Trailing distance *points
extern int int_trailing_Step = 5;      //  Trailing Step *points

double trailing_profit;
double trailing_stoplevel;
double trailing_step;

double stop_loss;
double take_profit;
double minstop_level;
int magic = 312;

C_TrailingStop trailing_listener(magic);

bool Is_Trend_Up()
   {
      if(iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE, 1) < iMA(Symbol(), PERIOD_M5, 34, 0, MODE_EMA, PRICE_CLOSE, 1) &&
         iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE, 0) > iMA(Symbol(), PERIOD_M5, 34, 0, MODE_EMA, PRICE_CLOSE, 0) &&
         iMACD(Symbol(), PERIOD_M5, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0)
            return true;
      return false;
   }
   
bool Is_Trend_Down()
   {
      if(iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE, 1) > iMA(Symbol(), PERIOD_M5, 34, 0, MODE_EMA, PRICE_CLOSE, 1) &&
         iMA(Symbol(), PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE, 0) < iMA(Symbol(), PERIOD_M5, 34, 0, MODE_EMA, PRICE_CLOSE, 0) &&
         iMACD(Symbol(), PERIOD_M5, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0)
            return true;
      return false;
   }
   
void Order_Send_Monitor()
   {
      if(Is_Trend_Down())
         {
            if(iMA(Symbol(), PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE, 1) > iMA(Symbol(), PERIOD_M1, 34, 0, MODE_EMA, PRICE_CLOSE, 1) &&
               iMA(Symbol(), PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE, 0) < iMA(Symbol(), PERIOD_M1, 34, 0, MODE_EMA, PRICE_CLOSE, 0))
                  {
                     if(iMACD(Symbol(), PERIOD_M1, 13, 21, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0 &&
                        iMACD(Symbol(), PERIOD_M1, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0 &&
                        iMACD(Symbol(), PERIOD_M1, 31, 144, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0)
                           CustomOrderSend(OP_SELL);
                  }
         }
      if(Is_Trend_Up())
         {
            if(iMA(Symbol(), PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE, 1) < iMA(Symbol(), PERIOD_M1, 34, 0, MODE_EMA, PRICE_CLOSE, 1) &&
               iMA(Symbol(), PERIOD_M1, 21, 0, MODE_EMA, PRICE_CLOSE, 0) > iMA(Symbol(), PERIOD_M1, 34, 0, MODE_EMA, PRICE_CLOSE, 0))
                  {
                     if(iMACD(Symbol(), PERIOD_M1, 13, 21, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0 &&
                        iMACD(Symbol(), PERIOD_M1, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0 &&
                        iMACD(Symbol(), PERIOD_M1, 31, 144, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0)
                           CustomOrderSend(OP_BUY);
                  }
            
         }
   }
   
void CustomOrderSend(int operation)
   {
      double price = (operation == OP_BUY)?Ask:Bid;
      double stoploss = (operation == OP_BUY)?(price - stop_loss):(price + stop_loss);
      double takeprofit = (operation == OP_BUY)?(price + take_profit):(price - take_profit);
      if(!OrdersTotal())
         {
            int ticket = OrderSend(Symbol(), operation, volume, price, slippage, stoploss, takeprofit, " ", magic);
            if(ticket < 0)
               {
                  GetLastError();
                  if(GetLastError() == 130)
                     Print("price = ", price, " stoploss = ", stoploss, " takeprofit = ", takeprofit);
               }
         }
      if(iMACD(Symbol(), PERIOD_M1, 13, 21, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0 ||
                  iMACD(Symbol(), PERIOD_M1, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) < 0)
                     {
                        for(int i = 0; i < OrdersTotal(); i++)
                           {
                              if(OrderSelect(i, SELECT_BY_POS))
                                 if(OrderMagicNumber() == magic)
                                    if(OrderType() == OP_BUY)
                                       if(OrderClose(OrderTicket(), OrderLots(), Ask, slippage))
                                          {
                                             i--;
                                             Print("Orderclosed");
                                          }
                           }
                     }
                if(iMACD(Symbol(), PERIOD_M1, 13, 21, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0 ||
                   iMACD(Symbol(), PERIOD_M1, 21, 34, 1, PRICE_CLOSE, MODE_MAIN, 0) > 0)     
                      {
                        for(int i = 0; i < OrdersTotal(); i++)
                           {
                              if(OrderSelect(i, SELECT_BY_POS))
                                 if(OrderMagicNumber() == magic)
                                    if(OrderType() == OP_SELL)
                                       if(OrderClose(OrderTicket(), OrderLots(), Bid, slippage))
                                          {
                                             i--;
                                             Print("Orderclosed");
                                          }
                           }
                     } 
           
   }
   
int OnInit()
  {
      stop_loss = Pips_to_Points(stoploss_point);
      take_profit = Pips_to_Points(takeprofit_point);
      
      minstop_level = (MarketInfo(Symbol(), MODE_STOPLEVEL) + MarketInfo(Symbol(), MODE_SPREAD))*Point;
      CheckMinStopLevel(stop_loss, minstop_level, "stoploss");
      
      if(!Trailing_Stop)
         trailing_listener.TurnOff();
      
      if(Trailing_Stop)
         {
           // check Trailing Stop parameters 
         trailing_profit = Pips_to_Points(int_Trailing_Profit);
         trailing_stoplevel = Pips_to_Points(int_Trailing_Stop_Level);
         trailing_step = Pips_to_Points(int_trailing_Step);
         
         CheckMinStopLevel(trailing_profit,minstop_level, "Trailing Profit");
         CheckMinStopLevel(trailing_stoplevel,minstop_level, "Trailing Stop Level");
         
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
  Order_Send_Monitor();
  trailing_listener.Monitor();
//---
   
  }
//+------------------------------------------------------------------+

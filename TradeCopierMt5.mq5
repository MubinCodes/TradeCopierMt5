//+------------------------------------------------------------------+
//| TradeCopierEA.mq5                                                |
//| MetaTrader 5 Master-Slave Trade Copier                           |
//| Author: MubinCodes                                               |
//| GitHub: https://github.com/MubinCodes                            |
//|                                                                  |
//| This EA demonstrates a file-based trade copier for MetaTrader 5. |
//| It supports master/slave mode and synchronizes open positions,   |
//| stop-loss, take-profit, and position closing across MT5 terminals|
//|                                                                  |
//| Disclaimer: This project is for educational and portfolio        |
//| demonstration purposes only. Trading involves risk.              |
//+------------------------------------------------------------------+


#property copyright "https://www.fiverr.com/sellers/mubinbhaiya/"
#property link      "https://www.fiverr.com/sellers/mubinbhaiya/"

#define FILE_NAME MQLInfoString(MQL_PROGRAM_NAME)+".bin"
#include <trade/trade.mqh>
#include <arrays/arraylong.mqh>

enum ENUM_MODE {MODE_MASTER, MODE_SLAVE}; 
input ENUM_MODE Mode= MODE_SLAVE;

CTrade trade; // Create a trade object
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      if(Mode == MODE_MASTER){
         int file = FileOpen(FILE_NAME, FILE_WRITE|FILE_BIN|FILE_COMMON);
         
         if(file != INVALID_HANDLE){
            if(PositionsTotal() == 0){

            }else{
               for(int i = PositionsTotal()-1; i >= 0; i--){
                  CPositionInfo pos;
                  if(pos.SelectByIndex(i)){
                     FileWriteLong(file, pos.Ticket());
                     int length = StringLen(pos.Symbol());
                     FileWriteInteger(file,length);
                     FileWriteString(file, pos.Symbol());
                     FileWriteDouble(file, pos.Volume());
                     FileWriteInteger(file, pos.PositionType());
                     FileWriteDouble(file, pos.PriceOpen());
                     FileWriteDouble(file, pos.StopLoss());
                     FileWriteDouble(file, pos.TakeProfit());
                     
                  }
                  
                  
               }
               
            }
            FileClose(file);
         }
      }else if(Mode == MODE_SLAVE){
         CArrayLong arr;
         arr.Sort();
         
         int file = FileOpen(FILE_NAME, FILE_READ|FILE_BIN|FILE_COMMON); 
         if(file != INVALID_HANDLE){
            while(!FileIsEnding(file)){
               ulong posTicket = FileReadLong(file);
               int length = FileReadInteger(file);
               string posSymbol = FileReadString(file, length);
               double posVolume = FileReadDouble(file);
               ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)FileReadInteger(file);
               double posPriceOpen = FileReadDouble(file);
               double posSl = FileReadDouble(file);
               double posTp = FileReadDouble(file);
               
               for(int i = PositionsTotal()-1; i >= 0; i--){
                  CPositionInfo pos;
                  if(pos.SelectByIndex(i)){
                     if(StringToInteger(pos.Comment()) == posTicket){
                        if(arr.SearchFirst(posTicket) < 0){
                           arr.InsertSort(posTicket);
                        }
                        
                        //SL TP modification
                        if(pos.StopLoss() != posSl || pos.TakeProfit() != posTp){
                           trade.PositionModify(pos.Ticket(), posSl, posTp);
                        }
                        break;
                     }
                     
                  }
               }
               
               if(arr.SearchFirst(posTicket) < 0){
                  if(posType == POSITION_TYPE_BUY){
                     trade.Buy(posVolume, posSymbol, 0, posSl, posTp, IntegerToString(posTicket));
                     
                     
                  }else if(posType == POSITION_TYPE_SELL){
                     trade.Sell(posVolume, posSymbol, 0, posSl, posTp, IntegerToString(posTicket));
                     
                  }
                  if(trade.ResultRetcode() == TRADE_RETCODE_DONE) arr.InsertSort(posTicket);
               }
                  
            }
            FileClose(file);
            
            for(int i = PositionsTotal()-1; i >= 0; i--){
               CPositionInfo pos;
               if(pos.SelectByIndex(i)){
                  if(arr.SearchFirst(StringToInteger(pos.Comment())) < 0){
                     trade.PositionClose(pos.Ticket());
                  }
               }
               
            }
                  
            
            
         }
      }
  }
//+------------------------------------------------------------------+

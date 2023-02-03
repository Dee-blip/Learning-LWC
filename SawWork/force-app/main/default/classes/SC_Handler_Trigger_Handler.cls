/*
Author          : Pinkesh / Sumukh SS
Description     : Apex Controller for SOCC Car RunBooks
Test Class      : SC_SOCC_Instruction_Manager_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh 								SOCC CAR 2 - RunBooks 
------------------------------------------------------------------------------------------------------------------
*/
public class SC_Handler_Trigger_Handler
{

      public static void checkHandlerDuplicates(List<Handler__c> HandlerList)
      {
      
          //Collect all Policy Domains
          set<Id> pdList = new set<Id>();
          
          for(Handler__c varHandler:HandlerList)
          {
              
              pdList.add(varHandler.Policy_Domain__c); 
          }
          
          //Create a Map of pdId and List of Handlers
          Map<String,List<Handler__c>> pdHandlerMap = new Map<String,List<Handler__c>>();
          
          List<Handler__c> completeHandlerList = [Select Id,Name,Policy_Domain__c from Handler__c where Policy_Domain__c in:pdList];          
        
         if(completeHandlerList.size()>0)
        {
          
          for(Handler__c varHandler:completeHandlerList)
          {
              
              if(pdHandlerMap.containsKey(varHandler.Policy_Domain__c))
              {
                   List<Handler__c> tempList = pdHandlerMap.get(varHandler.Policy_Domain__c);
                   tempList.add(varHandler);
                   pdHandlerMap.put(varHandler.Policy_Domain__c,tempList);
              }
              else
              {
                  system.debug('In else');
                   pdHandlerMap.put(varHandler.Policy_Domain__c,new List<Handler__c>{varHandler});
              }
          
          }
          
          System.debug('pdHandlerMap'+pdHandlerMap);
          
          //Loop through and add error if relevant
          for(Handler__c varHandler:HandlerList)
          {
              
              //get all Handlers Based on Pd of the iterating Handler rec
              List<String> checkListHandlerNames = new List<String>();
              //make a string List of all Names 
              for(Handler__c varHandlerRecord : pdHandlerMap.get(varHandler.Policy_Domain__c))
              {
                  checkListHandlerNames.add(varHandlerRecord.Name.toUppercase());
              }
              
              System.debug('checkListHandlerNames'+checkListHandlerNames);
              
              
              
              if(checkListHandlerNames.size()>0 && checkListHandlerNames.contains(varHandler.Name.toUppercase()))
              {
              
                     varHandler.addError('A handler with similar name already exists on the Policy Domain. Please use a different Name!');
              }
          
          }
        }
      }

}
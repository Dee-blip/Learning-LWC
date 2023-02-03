/***
    EB_EntitledAccPrdTrigger
    @version 1.0
    @author Jayalakshmi Anantharaman (janantha@akamai.com)
    @date 06/08/2010
    @Description : CR 1733044 This trigger is called on 'before insert' events on the Entitled Account Product Map object.
                   It takes care of the following :
                   - Populating the Account.         
*/ 

trigger EB_EntitledAccPrdTrigger on EB_EntitledAccountProduct__c (before insert) 
{
    List<String> akamAccountId = new List<String>();
    List<EB_EntitledAccountProduct__c> accProductMapList = new List<EB_EntitledAccountProduct__c>();
    Map<String,String> akamIdAccId = new Map<String,String>(); 
    Integer i = 0;
    Integer j = 0;
    if(trigger.new[i].EB_Account__c==null)
    {
        for(j=0;j<trigger.new.size();j++)
        {
            akamAccountId.add(trigger.new[j].EB_AKAMAccountId__c);
            accProductMapList.add(trigger.new[j]);
        }
       
        List<Account> accountList = [select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c in :akamAccountId];
        for(Account acc:accountList)
        {
            akamIdAccId.put(acc.AKAM_Account_ID__c,acc.Id);
        }
        
        i=0;
        j=0;
        
        while(i<accProductMapList.size())
        {
            trigger.new[i].EB_Account__c = akamIdAccId.get(akamAccountId.get(i));
            
            if(trigger.new[i].EB_Account__c == null)
            {
                trigger.new[i].addError('Invalid Akam Account Id : ' + akamAccountId.get(i));
            }
            
            i++;
        }
    }
}
/***
    EB_AccountCPCodeTrigger
    @version 1.0
    @author Jayalakshmi Anantharaman (janantha@akamai.com)
    @date 12/08/2010
    @Description : This trigger is called on 'before insert' events on the Account CPCode Map object.
                   It takes care of the following :
                   - Populating the Account.
    @Modified: On 08/09/2010 by janantha for CR# 778665 for displaying an error if an invalid Akam account Id is entered.
                  
*/ 

trigger EB_AccountCPCodeTrigger on EB_AccountCPCodeMap__c (before insert) 
{
    List<String> akamAccountId = new List<String>();
    List<EB_AccountCPCodeMap__c> accCPCodeList = new List<EB_AccountCPCodeMap__c>();
    Map<String,String> akamIdAccId = new Map<String,String>(); 
    Integer i = 0;
    Integer j = 0;
    if(trigger.new[i].EB_Account__c==null)
    {
        for(j=0;j<trigger.new.size();j++)
        {
            akamAccountId.add(trigger.new[j].EB_AKAM_AccountId__c);
            accCPCodeList.add(trigger.new[j]);
        }
       
        List<Account> accountList = [select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c in :akamAccountId];
        for(Account acc:accountList)
        {
            akamIdAccId.put(acc.AKAM_Account_ID__c,acc.Id);
        }
        
        i=0;
        j=0;
        
        while(i<accCPCodeList.size())
        {
            trigger.new[i].EB_Account__c = akamIdAccId.get(akamAccountId.get(i));
            //start of changes on 08/09/2010 by janantha for CR# 778665 for displaying an error if an invalid Akam account Id is entered
            if(trigger.new[i].EB_Account__c == null)
            {
            	trigger.new[i].addError('Invalid Akam Account Id : ' + akamAccountId.get(i));
            }
            //end of changes on 08/09/2010 by janantha for CR# 778665 for displaying an error if an invalid Akam account Id is entered
            i++;
        }
    }
}
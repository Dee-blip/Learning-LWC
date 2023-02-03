//Account service class - contains queries 
global without sharing class SF1_AccountService {
    
    public static List<Account> SearchExistingAccounts(String AccountName,String AccountDomain,String AccountCountry,String AccountState,Integer oset)
    {   List<Account> Accs = new list<Account>();
        al.SoqlBuilder soql = new al.SoqlBuilder().selectx(new Set<Object>{'Id','Name','Website','BillingCountry','OwnerId','Owner.Name','Account_Status__c','BillingState'}).fromx('Account').limitx(10);
          al.NestableCondition  andCond = new al.AndCondition();
          al.NestableCondition orCond = new al.OrCondition();
          String query;
          // Don't query if there is no filter criteria
          Boolean flag = false;
          
          if(!String.isBlank(AccountName))
          {
            flag = true;
            orCond.add(new al.FieldCondition('Name').likex('%'+ AccountName + '%'));
          }
          if(!String.isBlank(AccountDomain))
          {
            flag = true;
            orCond.add(new al.FieldCondition('Website').likex('%'+ AccountDomain+ '%'));
          }
          if(!String.isBlank(AccountCountry))
          {
            flag = true;
            andCond.add(new al.FieldCondition('BillingCountry').likex('%'+ AccountCountry+ '%'));
          }
          if(!String.isBlank(AccountState))
          {
            flag = true;
            andCond.add(new al.FieldCondition('BillingState').likex('%'+ AccountState+ '%'));
          }

          andCond.add(orCond);
          query = soql.wherex(andCond).toSoql(new al.SoqlOptions().escapeSingleQuotes());

           System.debug('Final Query------->'+query);
           query+=' OFFSET '+String.valueOf(oset);
           System.debug('Final Query------->'+query);
 
                for(Account a : Database.query(query)) 
                {
                  Accs.add(a);                  
                }
               
                return Accs;

    }
    
    public static Account getAccount(Id pid){
        Account selectedAccount = [select id, Customer_or_Account__c from Account where id=:pid];
        return  selectedAccount;
    }

}
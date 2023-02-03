global virtual class EB_BatchableMailerWizard {
/*
Author: Sharath
Version: 1.0
Created date: 09/16/2010
Description:CR-819957. Parent Batchable class for Create Mailer. This is extended by 2 child classes, which invoke the start methods of this class 
*/

    global final String Query;
    List<String> allAccounts= new List<String>();
    
    /* 
Author: Sharath
Version: 1.0
Created date: 09/16/2010
    Description: Contructor with no parameters for the class to be inherited. 
    */
    global EB_BatchableMailerWizard()
    {
        
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 09/16/2010
    Description: Parameterised contructor for initialising the query
    */
    global EB_BatchableMailerWizard(String q)
    {
        Query = q;
    }
    
    global EB_BatchableMailerWizard(String q,List<String> acc)
    {
        Query = q;
        allAccounts=acc;
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 09/16/2010
    Description: this method returns a Database.QueryLocator which is used as an input to the execute method. 
    */
    virtual global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    /* 
Author: Sharath
Version: 1.0
Created date: 09/16/2010
    Description: this method executes the query returned by start method.
    */
    virtual global void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        Database.query(Query);
    }
    
    /*
Author: Sharath
Version: 1.0
Created date: 09/16/2010
    Description: this method can be used to send mails regarging the batch job. 
    */
    virtual global void finish(Database.BatchableContext BC)
    {
    
    }
}
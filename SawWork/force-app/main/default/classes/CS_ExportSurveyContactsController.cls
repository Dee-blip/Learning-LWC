/*
CR 1718023 CSAT: Q32012 Oct-2012 To create the relationship contact report in Salesforce 
Created On: 29 August 2013
Created By: ssawhney
Description: This class implements the export functionality for the report 
*/
public class CS_ExportSurveyContactsController
{
    public string contactSOQL = '';
       
    //set the primary service related information
    private map<Id, account> getPrimaryServices(list<Contact> contacts) {
        //fetch all the account ids
        Set<Id> accIds = new Set<Id>();
        for(Contact cnt : contacts)
        {
            accIds.add(cnt.AccountId);
        }     
        //query the account team to fetch the services primary contacts and store in map   
        map<Id, account> servicePrimary = new map<Id, account>([Select Id, (Select User.Email, User.Name from AccountTeamMembers where TeamMemberRole = 'Services - Primary' limit 1) from Account where Id in :accIds]);
        return servicePrimary ;    
    }
    
    //set the secondary service related information
    private map<Id, account> getSecondaryServices(list<Contact> contacts) {
        //fetch all the account ids
        Set<Id> accIds = new Set<Id>();
        for(Contact cnt : contacts)
        {
            accIds.add(cnt.AccountId);
        }     
        //query the account team to fetch the services primary and secondary contacts and store in map   
        map<Id, account> serviceSecondary = new map<Id, account>([Select Id, (Select User.Email, User.Name from AccountTeamMembers where TeamMemberRole = 'Services - Secondary' limit 1) from Account where Id in :accIds]);
        return serviceSecondary;    
    }
        
    // method for getting the page controller    
    public ApexPages.StandardSetController objController
    {
        get{
            if(objController == null){
                try{
                    if(contactSOQL != ''){
                        objController = new ApexPages.StandardSetController(Database.getQueryLocator(contactSOQL));
                        objController.setPageSize(1000);
                    }
                }
                catch(Exception e){
                    ApexPages.Message myMsg;
                    myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No matching records were found ');
                    ApexPages.addMessage(myMsg);
                }
            }
            return objController;
        }
        set;
    }

    //constructor
    public CS_ExportSurveyContactsController(string sql) 
    {
        //The current query is passed from the previous page
        contactSOQL = sql;
    }
    
    /*
    Created On: 29 August 2013
    Created By: ssawhney
    Description: This method is used to create a list of list of contacts which enables to have 1000 * 1000 records in total for this list
    */
    public List<List<ContactInformation>>  getAllSurveyContacts()
    {
        List<List<ContactInformation>> lstContactInfo = new List<List<ContactInformation>>();  
        //variable used for checking if the first page processed     
        boolean moveNext = false;
        do
        {
             List<ContactInformation> cntList =new List<ContactInformation>();
             if(moveNext)
                 objController.Next();
             //get the contact records on the current page
             list<Contact> lstContact = (list<Contact>)objController.getRecords();
             
             //get the primary and the secondary services
             map<Id, account> primary = getPrimaryServices(lstContact);
             map<Id, account> secondary = getSecondaryServices(lstContact);
             
             //create the contact information
             for(Contact contact: lstContact)
             {
                 ContactInformation info = new ContactInformation(contact, primary.get(contact.AccountId), secondary.get(contact.AccountId));
                 cntList.add(info);
             }
             lstContactInfo.add(cntList);
             moveNext = true;
        }while (objController.getHasNext());
        return lstContactInfo;
    }
    
    /*
        Created On: 29 August 2013
        Created By: ssawhney
        Description: Inner class used to store the contcat information
    */
    public class ContactInformation
    {
        public Contact cnt{get;set;}
        public Account serviceSecondary{get;set;}
        public Account servicePrimary{get;set;}
        public ContactInformation(Contact obj, Account primary, Account secondary)
        {
            cnt = obj;
            serviceSecondary = secondary;
            servicePrimary = primary;
        }
    }
}
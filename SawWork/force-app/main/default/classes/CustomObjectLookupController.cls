public class CustomObjectLookupController {

    public List<Sobject> objectList { get; set; }
    public String query { get; set; }
    public String oppId{get;set;}
    private Opportunity opp{get;set;}

    public CustomObjectLookupController()
    {
     query=Apexpages.currentpage().getParameters().get('query');
     oppId=Apexpages.currentpage().getParameters().get('opp');
     if(query!=null && query!='' && oppId!=null && oppId!='')
     runQuery();
    }
    public PageReference runQuery() {
     
     opp=[select Id,Partner_Involved__c,Partner_Involved__r.ParentId from Opportunity where id=:oppId];
     objectList = [Select Id,Name,Title,Phone,Email 
                      from Contact 
                      where Name like : '%'+query+'%' 
                      and 
                         (AccountId =: opp.Partner_Involved__c 
                          or 
                          AccountId =: opp.Partner_Involved__r.ParentId)
                      and Active_Partner__c=true
                      and Can_Accept_POA__c='Yes'];
     return null;
    }
    
}
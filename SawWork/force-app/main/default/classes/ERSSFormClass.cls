/**
   @author: Nagaraj Desai
   SFDC-3957 : Lightning compatibility of eRSSForm Link on Opportunity
 **/
public class ERSSFormClass {
    public String listOfRssFormJSON {get;set;}
    public String opptyId {get;set;}
    public ERSSFormClass() {
         init();       
    }
    
    private void init() {
        List<RSS_Form__c> listOfRssForm = new List<RSS_Form__c>();
        opptyId = ApexPages.currentPage().getParameters().get('oppId');
        listOfRssForm = [SELECT Id, submitted__c, submit_locked__c, submit_version__c, published__c, locked__c, version__c, Submitted_By__c, LastModifiedById FROM RSS_Form__c WHERE (published__c = true OR (submitted__c = true AND locked__c = false)) AND services_form__c = false AND opportunity__c = :opptyId ORDER BY version__c DESC ,submit_version__c DESC];
        listOfRssFormJSON = JSON.serialize(listOfRssForm);
        System.DEBUG('listOfRssFormJSON: ' + listOfRssFormJSON);
    }
}
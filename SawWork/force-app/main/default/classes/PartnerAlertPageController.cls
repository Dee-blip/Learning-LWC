public without sharing class PartnerAlertPageController {

   public Opportunity oppty{get;set;}
   public PartnerAlertPageController(ApexPages.StandardController controller) {    }
  
  public PageReference checkForRenewal()
  {
    PageReference pRef;
   User usr=[Select id,ContactId from user where id=:UserInfo.getUserId()][0];
   if(usr.contactId!=null)
   {
   Contact con=[select Id,isRenewalRequired__c,isRebateTCToShow__c from Contact where id=:usr.contactId][0];
       if(!con.isRebateTCToShow__c && con.isRenewalRequired__c =='Yes')
       {
        con.isRebateTCToShow__c=true;
        con.Validation_Override__c=true;
        try
        {
          update con;
        }
        catch(Exception e)
        {
          pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
        }
        
       }
   }
  oppty=[select id,isRebateTCToShow__c,Partner_Owner__r.AccountId,Associated_Lead__c from Opportunity where id=:ApexPages.currentPage().getParameters().get('id')][0];
   
   return null;
  }
}
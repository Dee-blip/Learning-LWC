/*   Developer        Date          CR         Description
     Ruchika Sharma   16-03-2015    2954603    Ability to Track OEM Pipeline without affecting Akamai Pipeline
     
     Controller for OEMContactCustomPage. 
     This class takes parameter from page url to get OEM Account Id, which is used in OEMContactCustomPage

      Sonali Tandon    16 November 2015  Commenting out code as part of CR 3205251. Added filter on Contact Look up instead. 
*/
public with sharing class OEMContactCustomController {

    /*public String oemAccountId {get; set;}
    public OEM_Contact__c oemContact {get;set;}
    private ApexPages.StandardController stdcontroller;
    private String oemOpptyID;

    public OEMContactCustomController(ApexPages.StandardController controller) {
            stdcontroller = controller;
            oemContact = new OEM_Contact__c();
            Map<String,String> parameters = new Map<String,String>();
            parameters = ApexPages.currentPage().getParameters();
            if(parameters!=null){
                System.debug('parameters : '+parameters);
                oemOpptyID = parameters.get('pId');
                if(oemOpptyID!=null && !String.isBlank(oemOpptyID)){
                          System.debug('oemOpptyID: '+oemOpptyID);
                          oemContact.OEM_Opportunity__c = oemOpptyID;
                          List<OEM_Opportunity__c> oemObj= new List<OEM_Opportunity__c>();
                          oemObj = [Select Account_Name__c from OEM_Opportunity__c  where id=:oemOpptyID];
                          if(oemObj!=null){
                          
                              oemAccountId = oemObj[0].Account_Name__c;
                              System.debug('oemAccountId: '+oemAccountId);
                            }
                        
                     }
        }
            
    }

  public PageReference save()
  {    
     
      try{
        insert oemContact;
        String rUrl = '/'+oemOpptyId;
        PageReference rPage = new PageReference(rUrl);
       rPage.setRedirect(true);
       return rPage;
        }
      catch(Exception ex){
        ApexPages.addMessages(ex);
      }
       
      return null;
    
  }*/

}
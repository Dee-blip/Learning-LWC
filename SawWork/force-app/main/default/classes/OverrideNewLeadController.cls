//SFDC-4546
public with sharing class OverrideNewLeadController {

    public String ErrorMsg { get; set; }
    public String severity { get; set; }
    String Prefix;
    public PageReference Back() {

        return new PageReference('/' + Prefix + '/o');
    }
    public OverrideNewLeadController(ApexPages.StandardController stdController) {
        
            Prefix =  Lead.SObjectType.getDescribe().getKeyPrefix();
            
       }

       public Pagereference redirect(){
            PageReference retURL = null;
            severity='error';
            String profileIds = GsmUtilClass.getGSMSettingValue('Partner_Profile_Ids_For_Lead_exlcusion');

            if(!profileIds.contains(UserInfo.getProfileId())){
                String metadataName = 'Restrict_Lead_Creation';
                   if(metadataName != null){
                     ErrorMsg = GsmUtilClass.getErrorPageSettingValue(metadataName);  //Error_Page_Settings__c.getInstance(ApexPages.currentPage().getParameters().get('ErrorType')).value__c ;
                   }
                }else{
                     retURL = new Pagereference ('/'+ Prefix+ '/e?');
                     retURL.getParameters().put('nooverride', '1');
                    retURL.getParameters().remove('save_new');
                    retURL.setRedirect(true);       
                }

            
            return retURL;
       }

}
public class CreateAndViewClosePlanController {
    public Opportunity oppty{get;set;}
    public List<Close_Plan__c> cpList{get;set;}
    public CreateAndViewClosePlanController(ApexPages.StandardController controller){
        oppty=(Opportunity)controller.getRecord();
        cpList = [select Id from Close_Plan__c where Opportunity__c =: oppty.Id];
    }
    
    public PageReference navigateToCreateAndViewClosePlan(){
        PageReference returnUrl;
        if(cpList.size() > 0){
            returnURL = new PageReference('/'+cpList[0].Id);
        }else{
            String Prefix =  Schema.SobjectType.Close_Plan__c.getKeyPrefix();
            String opptyFieldId = GsmUtilClass.getGSMSettingValue('ClosePlan_OpptyFieldId');
            returnURL = new PageReference('/'+ Prefix+ '/e');
            returnURL.getParameters().put('CF'+opptyFieldId,oppty.Name);
            returnURL.getParameters().put('CF'+opptyFieldId+'_lkid',oppty.Id);
            returnURL.getParameters().put('retURL',oppty.Id);
        }
        returnURL.setRedirect(true);
        return returnURL;
    }
}
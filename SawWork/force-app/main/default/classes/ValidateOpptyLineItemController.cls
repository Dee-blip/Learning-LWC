/***
    ValidateOpptyLineItemController
    @version 1.0
    @author : Ruchika Sharma <rsharma@akamai.com>
    @Description : This class is used as a VisualForce controller for the VisualForce page "apex/ValidateOpptyLineItemPage" and "apex/ValidateOpptyLineItemDeletePage".
             This VisualForce duo, redirects the user to :
             - apex/addProductPageMerged page, if logged in user is pilot for new product wizard.
             - else, /apex/OpportunityLineItemsEdit2 to open edit page if action is coming from edit link
             - else, will delete the product, if action is coming from delete link
    
  
*/
public with sharing class ValidateOpptyLineItemController
{
  public OpportunityLineItem opptyLineItem;
  public Boolean isEligibleToAddProduct{get;set;}
  public String partnerManageProductsErrorMessage{get;set;}
  public Boolean isParentOpptyLocked{get;set;}
  public Opportunity opptynew{get;set;}
  public String parentOpptyLockedErrorMEssage{get;set;}
  public Boolean isOliDeleteFailed{get;set;}
  public Set<String> oliDeleteFailedErrorMEssage{get;set;}

  public ValidateOpptyLineItemController(ApexPages.StandardController stdController)
    {
      this.opptyLineItem = (OpportunityLineItem)stdController.getRecord();
      opptyLineItem = [Select id,Opportunityid from OpportunityLineItem where id=:opptyLineItem.id];
      opptynew=[select Id,Name,OwnerId,Account.OwnerIDAlt__r.Profile.Name,amg_opportunity_status__c,RecordType.Name from Opportunity where id =:opptyLineItem.Opportunityid][0];
      isParentOpptyLocked = false;
      isOliDeleteFailed = false;
      oliDeleteFailedErrorMEssage = new Set<String>();
      String userTypeString=Userinfo.getUserType();
      if(userTypeString!='' && userTypeString.contains('Partner') && opptynew.Account.OwnerIDAlt__r.Profile.Name !='Sales - Partner Account Executive' )
      {
        isEligibleToAddProduct=false;
      }
      else
      {
        isEligibleToAddProduct=true;
      }
      partnerManageProductsErrorMessage=GSMSettings.getValue('OpptyLineItems_ManageProductsError');
      //SFDC-839
      String amgOppRecordType = [select Id, Value__c from GSM_Settings__mdt where DeveloperName = 'OppTrigger_bi_amgOppRecordType'].Value__c;
      if(opptynew.RecordType.Name== amgOppRecordType && opptynew.amg_opportunity_status__c!=null && opptynew.amg_opportunity_status__c=='Submitted'){
        isParentOpptyLocked = true;
        parentOpptyLockedErrorMEssage = [select Id, Value__c from GSM_Settings__mdt where DeveloperName = 'validateOppty_parentOpptyLockedErrorMsg'].Value__c;
      }

    }
  /**
	 UpdateOppty()
	 - Returns true if there are data-issues on the Opportunity Record
	 - Else returns false.
  */
  public Boolean UpdateOppty()
    {
      try
      {
        update this.opptynew;
        //if(!isEligibleToAddProduct)
        //throw new CustomException('You are authorized to add products. Please contact your administrator');
      }
      catch(Exception e)
      {
        System.debug('Exception: '+e.getMessage());
        return false;
      }
      return true;
    }

  public Pagereference pageRedirect()
    {
      // If there is a data-issue or the parent record is locked
      //SFDC-839
      if(!isEligibleToAddProduct || isParentOpptyLocked)
      {
        System.debug('prod not eligible ');
        return null;
      }
      //else if(!UpdateOppty() && isEligibleToAddProduct)
        //{
      //  System.debug('error on oppty:');
      //  PageReference opptyPage = new PageReference('/' + oppty.id+'/e?save=1&retURL=/'+oppty.id);
      //      opptyPage.setRedirect(true);
      //      return opptyPage;
      //}
      // No data-issue
      else
      {
        String urlPrefix = '';
        PageReference opptyLineItemsPage;
        //String pilotUserString = GsmUtilClass.getGSMSettingValue('Product_Wizard_Pilot_Users');
        //String pilotUserString1 = GsmUtilClass.getGSMSettingValue('Product_Wizard_Pilot_Users_1');
        String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');

        //System.debug('pilotUserString.contains(userId): '+pilotUserString.contains(userId));
        //urlPrefix = '/apex/addProductPageMerged?oppId=';
        //  opptyLineItemsPage = new PageReference(urlPrefix+opptynew.id);
        //  System.debug('opptyLineItemsPage: '+opptyLineItemsPage);
        //  return opptyLineItemsPage;
        ///apex/OpportunityLineItemsEdit2?retURL=00k7A0000034otJ&retURL=%2F0067A000002e1sK&sfdc.override=1
        //SFDC-1952
        //newProductWizardGA.equalsIgnoreCase('True') || 
        if(GsmUtilClass.isPilotUser(opptynew.OwnerId)){
          urlPrefix = '/apex/addProductPageChangedEMRI?oppId=';
          opptyLineItemsPage = new PageReference(urlPrefix+opptynew.id+'&id='+opptynew.Id+'&sfdc.override=1');
        }
        else{
          urlPrefix = '/apex/addProductPageMerged?oppId=';
          opptyLineItemsPage = new PageReference(urlPrefix+opptynew.id+'&id='+opptynew.Id+'&sfdc.override=1');
        }
        opptyLineItemsPage.setRedirect(true);
        System.debug('opptyLineItemsPage: '+opptyLineItemsPage);
        return opptyLineItemsPage;
      }
    }


  public Pagereference pageRedirectDel()
    {
      // If there is a data-issue or the parent record is locked
      //SFDC-839
      if(!isEligibleToAddProduct || isParentOpptyLocked)
      {
        System.debug('prod not eligible ');
        return null;
      }
      // No data-issue
      else
      {
        String urlPrefix = '';
        PageReference opptyLineItemsPage;
        String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');
        //pilotUserString.contains(userId) || pilotUserString1.contains(userId)
        //newProductWizardGA.equalsIgnoreCase('True') ||
        if(GsmUtilClass.isPilotUser(opptynew.OwnerId)){
          urlPrefix = '/apex/addProductPageChangedEMRI?oppId=';
          opptyLineItemsPage = new PageReference(urlPrefix+opptynew.id+'&id='+opptynew.Id+'&sfdc.override=1');
          system.debug('will redirect page: '+opptyLineItemsPage);
          opptyLineItemsPage.setRedirect(true);
        }
        else if(newProductWizardGA.equalsIgnoreCase('True')){
          urlPrefix = '/apex/addProductPageMerged?oppId=';
          opptyLineItemsPage = new PageReference(urlPrefix+opptynew.id+'&id='+opptynew.Id+'&sfdc.override=1');
          system.debug('will redirect page: '+opptyLineItemsPage);
          opptyLineItemsPage.setRedirect(true);
        }
        //commenting it out as newProductWizardGA is always true now. 
        //else{
        //  OpportunityLineItem oli = new OpportunityLineItem(id=opptyLineItem.id);

        //    try
        //       {

        //          system.debug('came in else');
        //           delete oli;
        //           opptyLineItemsPage = new PageReference(urlPrefix+'/'+opptynew.id);
        //       }
        //       catch(DMLException de)
        //       {
        //         system.debug('de: '+de);
        //           for(integer i=0;i<de.getNumDml();i++)
        //           {  system.debug('de.getDmlMessage(i) for oli delete: '+de.getDmlMessage(i));
        //               //resultSet.add(de.getDmlMessage(i));
        //               isOliDeleteFailed = true;
        //               //oliDeleteFailedErrorMEssage.add(de.getDmlMessage(i));
        //               //system.debug('oliDeleteFailedErrorMEssage: '+oliDeleteFailedErrorMEssage);
        //               system.debug('isOliDeleteFailed: '+isOliDeleteFailed);
        //           }
        //           //for(String errorMsg: oliDeleteFailedErrorMEssage)
        //           // ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errorMsg));
        //       }
        //}

        System.debug('opptyLineItemsPage: '+opptyLineItemsPage);
        return opptyLineItemsPage;
      }
    }

  /** Begin Rajesh Kumar SFDC-5897 Added below method to sanitize input */
  public  Component.Apex.OutputText getHtmlMessage(){
    Component.Apex.OutputText htmltext = new Component.Apex.OutputText(escape = false);
    htmltext.value = parentOpptyLockedErrorMEssage;
    return htmltext ;
  }
  /** End Rajesh Kumar SFDC-5897 Added below method to sanitize input */

}
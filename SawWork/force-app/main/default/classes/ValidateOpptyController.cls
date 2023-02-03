/***
    ValidateOpptyController
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class is used as a VisualForce controller for the VisualForce page "apex/ValidateOppty".
             This VisualForce duo, redirects the user to :
             - Opportunity Edit page, if there are data-issue errors on the Opportunity.
             - apex/OpportunityAddLineItems page, if there are no data-issue errors on the Opportunity.

  @History
  --Developer         --Date      --Change
  Karteek Kumar M     18/03/2010    Created the class.
  Ali KM          16/02/2012    CR 1477954 Forecasting: Need to update QA env for forecasting
                      -> Redirect page to either general Oppty-Prod Wizard or OOTB Forecast Enabled Forecast Wizard depending on feature toggle.  
  Ali KM          27/02/2012    CR 1477954 Forecasting: Need to update QA env for forecasting  
                      -> Commenting out the code as this feature is not going live with 3.5 release.      
  Ruchika Sharma    31/03/2016    CR 3348741 - Ability for CSM's to route Opptys to Sales
                                              - Lock opportunity product related list    
  Ruchika Sharma    29/08/2016    SFDC-1147 - Redirect Pilot users to new product wizard
*/
public class ValidateOpptyController
{
    public Opportunity oppty;
    public Boolean isEligibleToAddProduct{get;set;}
    public String partnerManageProductsErrorMessage{get;set;}
    public Boolean isParentOpptyLocked{get;set;}
    public String parentOpptyLockedErrorMEssage{get;set;}
    public Id opptyOwnerID;

    public ValidateOpptyController(ApexPages.StandardController stdController)
        {
            this.oppty = (Opportunity)stdController.getRecord();
            Opportunity opptynew=[select Id,Name,OwnerId,Account.OwnerIDAlt__r.Profile.Name,amg_opportunity_status__c,RecordType.Name from Opportunity where id =:oppty.Id][0];
            opptyOwnerID =opptynew.OwnerId;

            isParentOpptyLocked = false;
            String userTypeString=Userinfo.getUserType();
            if(userTypeString!='' && userTypeString.contains('Partner') && opptynew.Account.OwnerIDAlt__r.Profile.Name !='Sales - Partner Account Executive' )
            {
                isEligibleToAddProduct=false;
            }
            else
            {
                isEligibleToAddProduct=true;
            }
            partnerManageProductsErrorMessage = GSMSettings.getValue('OpptyLineItems_ManageProductsError');
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
                update this.oppty;
                //if(!isEligibleToAddProduct)
                //throw new CustomException('You are authorized to add products. Please contact your administrator');
            }
            catch(Exception e)
            {
                return false;
            }
            return true;
        }
    /**
	   Redirects the user to :
	   - Opportunity Edit page, if there are data-issue errors on the Opportunity.
	   - apex/OpportunityAddLineItems page, if there are no data-issue errors on the Opportunity.
	*/
    public Pagereference pageRedirect()
        {
            if(UserInfo.getUiThemeDisplayed() != 'Theme4t') {
                // If there is a data-issue or the parent record is locked
                //SFDC-839
                if(!isEligibleToAddProduct || isParentOpptyLocked)
                {
                    //System.debug('prod not eligible ');
                    return null;
                }
                //SFDC-1952
                else if(!UpdateOppty() && isEligibleToAddProduct  )
                {
                    System.debug('error on oppty:');
                    PageReference opptyPage = new PageReference('/' + oppty.id+'/e?save=1&retURL=/'+oppty.id);
                    opptyPage.setRedirect(true);
                    return opptyPage;
                }
                // No data-issue
                else
                {
                    String urlPrefix = '';
                    PageReference opptyLineItemsPage;
                    //SFDC-1147 - Redirect Pilot users to new product wizard
                    //String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');

                    //newProductWizardGA.equalsIgnoreCase('True') ||
                    //SFDC-1952
                    if(GsmUtilClass.isPilotUser(opptyOwnerID))
                        urlPrefix = '/apex/addProductPageChangedEMRI?oppId=';
                    else
                        urlPrefix = '/apex/addProductPageMerged?oppId=';
                    //Sonali Tandon -CR 2841078 - Visual WF 4.2: Add Opportunity product
                    String flow =ApexPages.currentPage().getParameters().get('flow');
                    //System.debug('flow : ' + ApexPages.currentPage().getParameters().get('flow'));
                    //System.debug('flow :' + flow);
                    // If redirected from 'Changing a Churn Opportunity to a Cancelled or Downgraded Product' flow
                    if(flow == 'yes')
                        opptyLineItemsPage = new PageReference(urlPrefix+oppty.id+'&id='+oppty.Id+'&sfdc.override=1'+'&flow=yes');
                    else
                        //If redirected as usual from add product on oppty detail page
                        opptyLineItemsPage = new PageReference(urlPrefix+oppty.id+'&id='+oppty.Id+'&sfdc.override=1');
                    opptyLineItemsPage.setRedirect(true);
                    System.debug('opptyLineItemsPage: '+opptyLineItemsPage);
                    return opptyLineItemsPage;
                }
            } else {
                return null;
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
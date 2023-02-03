public class L2Q_CarrierQuoteManagementController{

    public L2Q_CarrierQuoteManagementController(ApexPages.StandardController stdController) {}

    @AuraEnabled
    public static NominumAPICalloutClass.APIResponse createAccountAndUpdateNomAccount(Opportunity opptyObj)
    {
        NominumAPICalloutClass.APIResponse ar ;
        String returnMessage;
        try
        {

            NominumAPICalloutClass nm = new NominumAPICalloutClass();
            String nominumUserIdForCurrentUser = nm.getNominumUserId(UserInfo.getUserEmail());
            System.Debug(LoggingLevel.error, 'AGH_D in createAccountAndUpdateNomAccountV2 oppty is'+opptyObj);

            if(nominumUserIdForCurrentUser==null)
            {
                //SFDC-2870
                ar = new NominumAPICalloutClass.APIResponse(gsmUtilClass.getGSMSettingValue('Nominum_User_Access_Error'));
                return ar;
            }
            if(opptyObj.Account.NOM_Account_ID__c!=null)
            {
                //SFDC-2870
                ar = new NominumAPICalloutClass.APIResponse((id)opptyObj.Account.NOM_Account_ID__c);
                ar.responseMessage = 'Account already exists in Carrier CRM.';
                return ar;
            }
            if(String.isBlank(nm.isCurrencyValid(opptyObj.Account.CurrencyIsoCode)))
            {
                ar = new NominumAPICalloutClass.APIResponse('Account currency is not yet supported in Carrier CRM.');
                return ar;
            }

            // create account
            returnMessage = nm.createAccount(new AccountWrapper(opptyObj.AccountId,nominumUserIdForCurrentUser));
            // if the creation succeeded you get an 18 digit ID
            if(returnMessage.length()==18)
            {
                //updaete nom id on sf account
                String nomAccountId = returnMessage;
                returnMessage = updateSObject(
                        new Account(Id=opptyObj.AccountId
                            ,Validation_Override__c=true
                            ,NOM_Account_ID__c=nomAccountId));

                if(returnMessage.length()==18)
                {
                    //SFDC-2870
                    ar = new NominumAPICalloutClass.APIResponse((id)nomAccountId);
                    ar.responseMessage = 'Account has been created in Carrier CRM.';
                    return ar;
                }
            }

        }
        catch(Exception e)
        {
            returnMessage = String.format('Unexpected error occured: {0},  STACK_TRACE: {1}'
                    , new List<String>{e.getMessage(),e.getStackTraceString()});
        }
        ar = new NominumAPICalloutClass.APIResponse(returnMessage);
        return ar;
    }

    //SFDC-2870
    @AuraEnabled
    public static String getUserResponseMessage(){
        return gsmUtilClass.getGSMSettingValue('Nominum_user_Response_Message');
    }

    @AuraEnabled
    public static Opportunity populateOppty(String opptyId)
    {
        Opportunity o = [select AccountId
            ,Account.NOM_Account_ID__c
            ,Account.CurrencyIsoCode
            ,NOM_Opportunity_Id__c
            ,CurrencyIsoCode
            ,StageName
            ,Probability
            ,Name
            ,CloseDate
            ,AKAM_Opportunity_ID__c 
            ,(select product_name__c, forecast_group__c from OpportunityLineItems where Forecast_Group__c='Carrier')
            from Opportunity where id=:opptyId];
        return o;
    }

    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiTheme();
        return theme;
    }

    @AuraEnabled
    public static NominumAPICalloutClass.APIResponse createOpportunityAndUpdateNomOpportunity(Opportunity o, String nomAccountId, List<OpportunityLineItem> carrierProducts)
    {
        String returnMessage;
        NominumAPICalloutClass.APIResponse ar ;
        try
        {
            NominumAPICalloutClass nm = new NominumAPICalloutClass();
            //SFDC-2870
            if(o.NOM_Opportunity_Id__c!=null)
            {
                ar = new NominumAPICalloutClass.APIResponse((Id)o.NOM_Opportunity_Id__c);
                ar.responseMessage = 'Opportunity already exists in Carrier CRM. Please wait while we redirect you to the Opportunity record.';
                return ar;
            }
            else
            {
              if(carrierProducts==null || carrierProducts.size()<1)
                {
                    //SFDC-2870
                    ar = new NominumAPICalloutClass.APIResponse(gsmUtilClass.getGSMSettingValue('Nominum_No_Carrier_Prod_Error'));
                    return ar;
                }
                if(String.isBlank(nm.isCurrencyValid(o.CurrencyIsoCode)))
                {
                    ar = new NominumAPICalloutClass.APIResponse('Opportunity currency is not yet supported in Carrier CRM.');
                    return ar;
                }
                if(!GSMSettings.contains('NominumOpportunityAllowedStages',o.StageName))
                {
                    ar = new NominumAPICalloutClass.APIResponse('You cannot create a Quote for an Opportunity that is in Sales Stage 6. Signed or Closed');//SFDC-3539
                    return ar;
                }
            }

            String nominumUserIdForCurrentUser = nm.getNominumUserId(Userinfo.getUserEmail());
            // get reordtype id for oppty
            String rtId = nm.getRecordTypeId(GSMSettings.getValue('NominumOpportunityRecordTypeName'));
            String nominumOpportunityId= nm.createOpportunity(
                        new OpportunityWrapper(o
                            ,nomAccountId
                            ,nominumUserIdForCurrentUser
                            ,rtId));

            if(nominumOpportunityId.length()!=18)
            {
                // error
                return new NominumAPICalloutClass.APIResponse(nominumOpportunityId);
            }


            returnMessage = updateSObject(
                    new Opportunity(Id=o.Id
                        ,Validation_Override__c=true
                        ,NOM_Opportunity_Id__c=nominumOpportunityId));

            // success
            if(returnMessage.length()==18)
            {
                ar = new NominumAPICalloutClass.APIResponse((id)nominumOpportunityId);
                ar.responseMessage = 'Opportunity has been created in Carrier CRM. Please wait while we create a Quote for you.';
                return ar;
            }

        }
        catch(Exception e)
        {
            returnMessage = String.format('Unexpected error occured: {0},  STACK_TRACE: {1}'
                    , new List<String>{e.getMessage(),e.getStackTraceString()});
        }

        return new NominumAPICalloutClass.APIResponse(returnMessage);

    }


    @AuraEnabled
    public static NominumAPICalloutClass.APIResponse createQuoteAndRedirect( String nomOpptyId)
    {
        String returnMessage;
        try
        {
            NominumAPICalloutClass nm = new NominumAPICalloutClass();
            String nominumQuoteId = nm.getQuoteId(nomOpptyId);

            System.Debug(LoggingLevel.Error,'AGH_D in createQuoteAndRedirect nominumQuoteId'+nominumQuoteId);

            if(!String.isBlank(nominumQuoteId) && nominumQuoteId.length()==18)
            {
                NominumAPICalloutClass.APIResponse ar = new NominumAPICalloutClass.APIResponse((Id)nomOpptyId);
                ar.link = GSMSettings.getValue('NominumInstanceDomain')+nomOpptyId;
                ar.responseMessage = 'Opportunity already exists in Carrier CRM. Please wait while we redirect you to the Opportunity record.';
                return ar;
            }

            String quoteRecordTypeId = nm.getRecordTypeId(GSMSettings.getValue('NominumQuoteRecordTypeName'));
            returnMessage = nm.createQuote(
                        new QuoteWrapper(quoteRecordTypeId
                            ,nomOpptyId
                            ,'Draft'
                            ,'Quote'));

            if(returnMessage.length()==18)
            {
                NominumAPICalloutClass.APIResponse ar = new NominumAPICalloutClass.APIResponse((Id)returnMessage);
                ar.link = GSMSettings.getValue('NominumInstanceDomain')+returnMessage;
                ar.responseMessage = 'Quote has been created in Carrier CRM. Please wait while we redirect you to it.';
                return ar;
            }
        }
        catch(Exception e)
        {
            returnMessage = String.format('Unexpected error on quote creation: {0},  STACK_TRACE: {1}'
                    , new List<String>{e.getMessage(),e.getStackTraceString()});
        }

        return new NominumAPICalloutClass.APIResponse(returnMessage);
    }

    public static string updateSObject(Sobject sobj)
    {
        try
        {
            update sobj;
            return sobj.id;
        }
        catch(Exception e)
        {
            return String.format('{0} update failed: {1}' 
                    ,new List<String>{findObjectType(sobj.id),e.getMessage()});
        }
    }

    private static string findObjectType(String eyeDee)
    {
         return ((Id)eyeDee).getSObjectType().getDescribe().getName();
    }


    private class AccountWrapper
    {
        private string Name;
        private string BillingState;
        private string BillingCity;
        private string BillingCountry;
        private string BillingPostalCode;
        private string BillingStreet;
        private string ShippingStreet;
        private string ShippingCity;
        private string ShippingState;
        private string ShippingCountry;
        private string ShippingPostalCode;
        private string CurrencyIsoCode;
        private string AKAM_Account_ID;
        private string AkamaiSalesforceAccountId;
        private string OwnerId;

        AccountWrapper(Id accId, String ownerId)
        {
            Account acnt = [select id
                                  ,name
                                  ,BillingCity
                                  ,BillingState
                                  ,BillingCountry
                                  ,BillingStreet
                                  ,BillingPostalCode
                                  ,ShippingCity
                                  ,ShippingState
                                  ,ShippingStreet
                                  ,ShippingCountry
                                  ,ShippingPostalCode
                                  ,CurrencyIsoCode
                                  ,AKAM_account_ID__c 
                                  from Account where id=:accId];

            this.Name = acnt.Name;
            this.BillingCity = acnt.BillingCity;
            this.BillingState = acnt.BillingState;
            this.BillingCountry = acnt.BillingCountry;
            this.BillingStreet = acnt.BillingStreet;
            this.BillingPostalCode = acnt.BillingPostalCode;
            this.ShippingCity = acnt.ShippingCity;
            this.ShippingState = acnt.ShippingState;
            this.ShippingStreet = acnt.ShippingStreet;
            this.ShippingCountry = acnt.ShippingCountry;
            this.ShippingPostalCode = acnt.ShippingPostalCode;
            this.CurrencyIsoCode = acnt.CurrencyIsoCode;
            this.AKAM_Account_ID = acnt.AKAM_account_ID__c;
            this.OwnerId = ownerId;
            this.AkamaiSalesforceAccountId= acnt.Id;
        }
    }

    private class OpportunityWrapper
    {
        private string Name;
        private string StageName;
        private string AkamaiSalesforceOpportunityId;
        private string AKAM_Opportunity_ID;
        private string CloseDate;
        private string RecordTypeId;
        private String OwnerId;
        private string AccountId;
        private string OpportunityCurrency;

        OpportunityWrapper(Opportunity oppty, String nomAccountId, String ownerId, String recTypeId)
        {
            this.Name = oppty.Name;
            this.StageName = GSMSettings.getValue('NominumOpportunityStageName');
            this.AKAM_Opportunity_ID= oppty.AKAM_Opportunity_ID__c;
            this.AkamaiSalesforceOpportunityId= oppty.Id;
            this.CloseDate = String.valueOf(oppty.CloseDate);
            this.OwnerId = ownerId;
            this.RecordTypeId = recTypeId;
            this.AccountId = nomAccountId;
            this.OpportunityCurrency = oppty.CurrencyIsoCode;

        }
    }

    private class QuoteWrapper
    {
        private string recordTypeId;
        private string status;
        private string opportunityId;
        private string quoteType;

        QuoteWrapper(String recordTypeId, String opportunityId, String status, String quoteType)
        {
            this.RecordTypeId= recordTypeId;
            this.status=status;
            this.opportunityId=opportunityId;
            this.quoteType = quoteType;
        }
    }

}
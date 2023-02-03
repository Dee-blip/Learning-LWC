public without sharing class MarketPlaceContactRoleController
{

        public Integer count = 0;
        public String redirectionMessage {get; set;}
        public String redirectionURL {get; set;}

        // SFDC- 2694
        public Id objectId {get; set;}
        public Boolean isValidData {get; set;}
        public String errorMessage {get; set;} // SFDC-3664
        public Schema.SObjectType objectType {get; set;} // SFDC-3664
        private static Lead lead {get; set;}
        private static Opportunity oppty {get; set;}
        private static Contact contact {get; set;}
        private Boolean markLeadInProcess;

        // END - SFDC-2694

        //Begin JIRA#:SFDC-6634 Rajesh Kumar
        private static string errorData = '';
        private static string callerSource = '';
        //End JIRA#:SFDC-6634 Rajesh Kumar

        public PageReference decrementCounter()
        {
                if(count>0)
                        count= count-1;
                return null;
        }

        public PageReference updateLeadStatus()
        {
                if(markLeadInProcess)
                {
                        lead.Status = 'In Process';
                        lead.Disposition__c= 'In Process';
                        lead.Validation_Override__c=true;
                        DMLResults res = new DMLResults();
                        res.dmlUpdate(new List<Lead>{lead});
                        res.insertRecordsInErrorLog();
                }
                return null;
        }
        public Integer getCount() {
                return count;
        }


        // SFDC - 2694 : Function to validate opportunity and lead before redirecting to BuyAkamai
        private Boolean validateObject(Id objectId, Schema.SObjectType objectType)
        {
                Boolean returnVal = true;
                if(objectType == Schema.Opportunity.SObjectType)
                {
                        errorMessage = '';
                        if(CurrentUser.isPartner)
                        {
                                if(!CurrentUser.hasStartTrialPermissions)
                                {
                                        errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + 'You do not have start trial permissions' + '<br/>';
                                        returnVal=false;

                                }
                                if(!CurrentUser.hasViewTrialPermissions)
                                {
                                        errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + 'You do not have view trial permissions' + '<br/>';
                                        returnVal=false;

                                }

                                // check for permissions
                        }
                        oppty = [SELECT Deal_Type__c,StageName, Account.Is_Restricted_Country__c, Account.Owner.Id, Account.Type, AKAM_Opportunity_ID__c,RecordType.Name,Account.ECUSTOMS__RPS_Status__c,Account.Override_Visual_Compliance__c FROM Opportunity WHERE Id = :objectId];
                        if(!(GsmUtilClass.getGSMSettingValue('OpptyStageValidForBuyAkamai').split(',')).contains(oppty.StageName))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('OpptyStageInvalidForBuyAkamaiErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(!(GsmUtilClass.getGSMSettingValue('OpptyRecordTypesValidForBuyAkamai').containsIgnoreCase(oppty.RecordType.Name)))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;You cannot start trial for ' + oppty.RecordType.Name + ' opportunities.<br/>';
                                returnVal = false;
                        }
                        if(oppty.Account.Is_Restricted_Country__c)
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('RestrictedCountryErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(String.valueOf(oppty.Account.Owner.Id).equals(GsmUtilClass.getGSMSettingValue('ONA_User_Id')))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('AccountOwnerNotAssignedErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(!(GsmUtilClass.getGSMSettingValue('AccountStatusLeadProspect').split(',')).contains(oppty.Account.Type)  && !(oppty.Account.Type).contains('Inactive'))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('AccountStatusInvalidErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(!returnVal && CurrentUser.isPartner)
                        {
                            if(callerSource != 'lightning') //JIRA#:SFDC-6634 Rajesh Kumar  added condition that page message should not come for lightning for partner
                            {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, errorMessage));
                            }
                        }
                        //SFDC-6364 - VC Validations
                        if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(oppty.Account.ECUSTOMS__RPS_Status__c) && !oppty.Account.Override_Visual_Compliance__c )
                        {
                            errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Red') + '<br/>';
                            returnVal = false;
                        }
                        if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(oppty.Account.ECUSTOMS__RPS_Status__c) && !oppty.Account.Override_Visual_Compliance__c )
                        {
                            errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Pending') + '<br/>';
                            returnVal = false;
                        }
                        if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(oppty.Account.ECUSTOMS__RPS_Status__c) && !oppty.Account.Override_Visual_Compliance__c )
                        {
                            errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_DS_Alert') + '<br/>';
                            returnVal = false;
                        }

                }
                else if(objectType == Schema.Lead.SObjectType)
                {
                        errorMessage = '';
                        lead = [SELECT Status,OwnerId, RecordType.Name,Associated_Account__r.Is_Restricted_Country__c, Associated_Account__r.Owner.Id, Associated_Account__r.Type, AKAM_Lead_ID__c, Associated_Account__r.AKAM_Account_ID__c FROM Lead WHERE Id = :objectId];
                        if(lead.Associated_Account__r.Is_Restricted_Country__c)
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('RestrictedCountryErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(String.valueOf(lead.Associated_Account__r.Owner.Id).equals(GsmUtilClass.getGSMSettingValue('ONA_User_Id')))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('AccountOwnerNotAssignedErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(lead.OwnerId == null || String.valueOf(lead.OwnerId).equals(GsmUtilClass.getGSMSettingValue('ONA_User_Id')))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('LeadOwnerNotAssignedErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(!(GsmUtilClass.getGSMSettingValue('AccountStatusLeadProspect').split(',')).contains(lead.Associated_Account__r.Type) && !(lead.Associated_Account__r.Type).contains('Inactive'))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('AccountStatusInvalidErrorMsg') + '<br/>';
                                returnVal = false;
                        }
                        if(!GsmUtilClass.getGSMSettingValue('StartTrialAllowedLeadRecordTypes').containsIgnoreCase(lead.RecordType.Name))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp; You cannot start trial on a ' + lead.RecordType.Name+ '<br/>';
                                returnVal = false;
                        }
                        if(!GsmUtilClass.getGSMSettingValue('StartTrialAllowedLeadStatuses').containsIgnoreCase(lead.Status))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp; You cannot start trial if the lead is ' + lead.Status+ ' <br/>';
                                returnVal = false;
                        }
                        if(!GsmUtilClass.getGSMSettingValue('StartTrialAllowedLeadProfileIds').contains(userinfo.getProfileId()))
                        {
                                errorMessage += '<br/><b>•</b> &nbsp;&nbsp; You dont have permission to start trial. <br/>';
                                returnVal = false;
                        }
                        if(!returnVal && CurrentUser.isPartner)
                        {
                                if(callerSource != 'lightning') //JIRA#:SFDC-6634 Rajesh Kumar  added condition that page message should not come for lightning for partner
                                {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, errorMessage));
                                }
                        }

                }
                else if(objectType == Schema.Contact.SObjectType)
                {
                    errorMessage = '';
                    contact = [SELECT Id, Account.AKAM_Account_ID__c FROM Contact WHERE Id = :objectId];
                    if(!GsmUtilClass.getGSMSettingValue('StartTrialAllowedContactProfileIds').contains(userinfo.getProfileId()))
                    {
                        errorMessage += '<br/><b>•</b> &nbsp;&nbsp; You dont have permission to start trial. <br/>';
                        returnVal = false;
                    }
                    if(!returnVal && CurrentUser.isPartner)
                    {
                        if(callerSource != 'lightning') //JIRA#:SFDC-6634 Rajesh Kumar  added condition that page message should not come for lightning for partner
                        {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, errorMessage));
                        }
                    }
                }
                else
                {
                        returnVal = false;
                }
                //Begin JIRA#:SFDC-6634 Rajesh Kumar
                errorData = errorMessage;
                //Begin JIRA#:SFDC-6634 Rajesh Kumar
                return returnVal;
        }

        @AuraEnabled
        public static Map<String, String> getBuyAkamaiSupportedProducts() {
                Map<String, String> mapOfProductVsAccountType = new Map<String, String>();
                String productNameVsAccountTypeJSON = GSMSettings.getVerbose('StartTrial_ProductNameAccountTypeJSON');
                mapOfProductVsAccountType = (Map<String, String>)JSON.deserialize(productNameVsAccountTypeJSON, Map<String, String>.Class);
                return mapOfProductVsAccountType;
        }

        //SFDC-3664 @Nagaraj Desai
        @AuraEnabled
        public static String createAdminOpportunityForManualTrial(String objectId) {
                String returnVal = '';
                String opportnityFields = GsmUtilClass.getGSMSettingValue('StartTrial_OpptyFieldsForManualTrial');
                if(opportnityFields != null && opportnityFields != '') {
                        List<String> listOfFields = new List<String>();
                        listOfFields = opportnityFields.split(',');
                        listOfFields.add('Name'); // add Name field for the query
                        al.SoqlBuilder soqlQuery = new al.SoqlBuilder().selectx(listOfFields).fromx('Opportunity').wherex(new al.FieldCondition('Id', objectId));
                        Opportunity oppty = Database.query(soqlQuery.toSoql());
                        listOfFields.remove(listOfFields.indexOf('Name')); // remove Name field to avoid iteration
                        Opportunity manualTrialOppty = new Opportunity();
                        for(String eachField : listOfFields) {
                                if(oppty.get(eachField) != null) {
                                        manualTrialOppty.put(eachField, oppty.get(eachField));
                                }
                        }
                        manualTrialOppty.put('Name', oppty.Name + ' - Paper POC');
                        manualTrialOppty.put('Parent_Buy_Opportunity__c', oppty.Id);
                        manualTrialOppty.put('StageName', '5. Negotiate');
                        manualTrialOppty.put('Opportunity_Type__c', 'POC/Trial');
                        manualTrialOppty.put('Validation_Override__c', true);
                        try {
                                insert manualTrialOppty;
                                /* SFDC-4178
                                Order_Approval__c manualTrialOA = new Order_Approval__c();
                                manualTrialOA.Associated_Opportunity__c = manualTrialOppty.Id;
                                manualTrialOA.CCG_Owner__c = UserInfo.getUserId();
                                insert manualTrialOA;
                                */
                                String orderAppId = OrderApprovalClass.Create_OrderApproval(manualTrialOppty.Id, manualTrialOppty.RecordTypeId, manualTrialOppty.StageName, '');
                                //returnVal = manualTrialOA.Id;
                                returnVal = orderAppId.split(':')[1];
                                returnVal += ',' + GSMLite_UtilClass.getUIThemeDescription();
                        }
                        catch (Exception e) {
                                Error_log__c erroLog = new Error_log__c(Name = 'MarketPlace Manual Admin Oppty Creatio Error', Class__c = 'MarketPlaceContactRoleController',Error_Message__c = e.getMessage());
                                insert erroLog;
                        }
                }
                return returnVal;
        }

        public MarketPlaceContactRoleController()
        {
                // SFDC - 2694 : added validation before direct redirection
                objectId = ApexPages.currentPage().getParameters().get('id');
                objectType = (objectId).getSObjectType();
                isValidData = validateObject(objectId, objectType);
                markLeadInProcess = (objectType == Schema.Lead.SObjectType && 'New'.equalsIgnoreCase(lead.Status));

                if(isValidData)
                {
                        count = Integer.valueOf(GsmUtilClass.getGSMSettingValue('MarketPlace_Timeout'));
                        redirectionMessage = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionMessage');
                        if(objectType == Schema.Opportunity.SObjectType)
                        {
                            redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLOpportunity').replaceAll('##AKAM_Opportunity_ID__c##',  oppty.AKAM_Opportunity_ID__c).replaceAll('##Deal_Type__c##', oppty.Deal_Type__c);
                        }
                        else if (objectType == Schema.Lead.SObjectType)
                        {
                            redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLLead').replaceAll('##AKAM_Account_ID__c##',  lead.Associated_Account__r.AKAM_Account_ID__c).replaceAll('##AKAM_Lead_ID__c##', lead.AKAM_Lead_ID__c);
                        }
                        else if (objectType == Schema.Contact.SObjectType)
                        {
                               redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLContact').replaceAll('##AKAM_Account_ID__c##',  contact.Account.AKAM_Account_ID__c);
                        }

                }
                // END SFDC - 2694
                //refreshContact();
        }
          //Begin JIRA#:SFDC-6634 Rajesh Kumar
          public MarketPlaceContactRoleController(String recId)
          {
          }
          /***
           * Author:Rajesh Kumar
           * JIRA# : SFDC-6634
           * Description : Below method verify error if any before redirecting to buyakamai for partner user
           * Notes : We are not handling error using try catch we are letting bubble up the error to client side
           */
 @AuraEnabled
 public static ReturnWrapper checkPartnerredirect(String objectrecordId,String caller) {
         callerSource = caller;
         MarketPlaceContactRoleController mc = new MarketPlaceContactRoleController('dummyData');
         ReturnWrapper ret = new ReturnWrapper();
         Boolean isValid = true;
         String redirectionURL = '';
         String redirectionMessage = '';
         Integer count = 0;
         Id objectId = Id.valueOf(objectrecordId);
         Schema.SObjectType objectType = objectId.getSobjectType();
         isValid =  mc.validateObject(objectId, objectType);
        if (isValid) {
                 count = Integer.valueOf(GsmUtilClass.getGSMSettingValue('MarketPlace_Timeout'));
                 redirectionMessage = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionMessage');
                 if (objectType == Schema.Opportunity.SObjectType) {
                         redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLOpportunity').replaceAll('##AKAM_Opportunity_ID__c##', oppty.AKAM_Opportunity_ID__c).replaceAll('##Deal_Type__c##', oppty.Deal_Type__c);
                 } else if (objectType == Schema.Lead.SObjectType) {
                         redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLLead').replaceAll('##AKAM_Account_ID__c##', lead.Associated_Account__r.AKAM_Account_ID__c).replaceAll('##AKAM_Lead_ID__c##', lead.AKAM_Lead_ID__c);
                 } else if (objectType == Schema.Contact.SObjectType) {
                         redirectionURL = GsmUtilClass.getGSMSettingValue('MarketPlace_redirectionURLContact').replaceAll('##AKAM_Account_ID__c##', contact.Account.AKAM_Account_ID__c);
                 }
                 ret.redirectionMessage = redirectionMessage;
         }
         ret.isValid = isValid;
         ret.erroMessage = errorData;
         ret.isPartner = CurrentUser.isPartner;
         ret.uithemeDisplayed = UserInfo.getUiThemeDisplayed();
         ret.redirectionURL = redirectionURL;
         ret.objectType = String.valueOf(objectType);
         ret.count = count;
         return ret;
 }
 public class ReturnWrapper {
         @AuraEnabled
         public boolean isPartner;
         @AuraEnabled
         public string uithemeDisplayed;
         @AuraEnabled
         public string erroMessage;
         @AuraEnabled
         public boolean isValid;
         @AuraEnabled
         public string redirectionURL;
         @AuraEnabled
         public string objectType;
         @AuraEnabled
         public Integer count;
         @AuraEnabled
         public string redirectionMessage ;

 }
 //End JIRA#:SFDC-6634 Rajesh Kumar
}
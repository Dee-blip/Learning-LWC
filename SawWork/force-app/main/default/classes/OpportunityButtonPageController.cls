public class OpportunityButtonPageController
{
        PageReference pageRef;
        public static Id recordId {get; set;}
        public static Id recordTypeId;
        public static String stageName, getField, profileName,oppName,dupOpp;
        //public Boolean showSubmitForApproval {get; set;}
        public Id oppId {get; set;}
        public String fcm {get; set;}
        public String rebate {get; set;}
        public Boolean fromCampaignManagerButton {get; set;}
        public String backToOppty {get; set;}
        public Boolean viewOrderFormMobile {get; set;}
        public Boolean viewOrderFormDesktop {get; set;}
        public Boolean viewKnowYourCustMobile {get; set;}
        public Boolean viewKnowYourCustDesktop {get; set;}
        public String accountAkamId {get; set;}
        public String abiURL {get; set;}
        public static Id currentUserId;
        public static Id oppOwnerId;
        public Boolean viewMigrateDealRegData {get; set;}
        public Boolean viewMigrateDealRegDataResult {get; set;}
        public String migrateDealRegData {get; set;}

        public PageReference init()
        {
                String fromButton;

                fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
                recordId     = ApexPages.currentPage().getParameters().get('recordId');
                recordTypeId = ApexPages.currentPage().getParameters().get('recordTypeId');
                oppId = recordId;
                stageName    = ApexPages.currentPage().getParameters().get('stageName');
                getField     = ApexPages.currentPage().getParameters().get('getField');
                fcm     = ApexPages.currentPage().getParameters().get('fcm');
                rebate     = ApexPages.currentPage().getParameters().get('rebate');
                accountAkamId  = ApexPages.currentPage().getParameters().get('associatedAccountId');
                profileName = ApexPages.currentPage().getParameters().get('profileName');
                currentUserId = ApexPages.currentPage().getParameters().get('currentUserId');
                oppOwnerId = ApexPages.currentPage().getParameters().get('oppOwnerId');
                oppName = ApexPages.currentPage().getParameters().get('oppName');
                dupOpp = ApexPages.currentPage().getParameters().get('dupOpp');
                fromCampaignManagerButton = false;
                viewOrderFormMobile = false;
                viewOrderFormDesktop = false;
                viewKnowYourCustMobile = false;
                viewKnowYourCustDesktop = false;
                viewMigrateDealRegData = false;
                viewMigrateDealRegDataResult = false;
                String userTheme = UserInfo.getUiThemeDisplayed();
                backToOppty = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
                System.debug('inside CampaignManager');
                System.debug('fromButton: ' + fromButton);
                if(stageName != null && !String.isBlank(stageName)) {
                    stageName = String.escapeSingleQuotes(stageName.escapeHtml4());
                }
                if(accountAkamId != null && !String.isBlank(accountAkamId)) {
                    accountAkamId = String.escapeSingleQuotes(accountAkamId.escapeHtml4());
                }
                if(oppName != null && !String.isBlank(oppName)) {
                    oppName = String.escapeSingleQuotes(oppName.escapeHtml4());
                }
                if(!String.isBlank(fromButton))
                {
                        if(fromButton == 'CreateViewOrderForm')
                        {
                            if(userTheme == 'Theme4t') {
                                viewOrderFormMobile = true;    
                            } else {
                                pageRef = createViewOrderForm();
                                return pageRef;
                            }
                        }

                        if(fromButton == 'SubmitForApproval')
                        {
                                //showSubmitForApproval = true;
                                pageRef = submitForOppApproval();
                                return pageRef;
                        }

                        if(fromButton == 'CampaignManager')
                        {
                                //showSubmitForApproval = true;
                                fromCampaignManagerButton = true;
                                pageRef = campaignManagerApproval();
                                return pageRef;
                        }
                        if(fromButton == 'KnowYourCustomer')
                        {
                            
                            if(userTheme == 'Theme4t') {
                                viewKnowYourCustMobile = true;    
                            }  
                            else {
                                viewKnowYourCustDesktop = true;
                                backToOppty = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
                                abiURL = System.Label.Know_Your_Customer+accountAkamId+'%22';
                            }  
                        }

                        if(fromButton == 'SalesRepAcknowledge')
                        {
                                pageRef = salesRepAcknowledge();
                                return pageRef;
                        }

                        if(fromButton == 'TransferOpptyToPartner') {
                                pageRef = transferOpptyToPartner();
                                return pageRef;
                        }
                        if(fromButton == 'MigrateDealRegData')
                        {
                                if(profileName.contains('Sales Op') || 
                                   profileName.contains('Business Operation') || 
                                   profileName.contains('Partner Support') ||
                                   profileName.contains('System Administrator')) {
                                        if(dupOpp != null && dupOpp != '') {
                                            viewMigrateDealRegData = true;    
                                            migrateDealRegData = 'Deal Registration Information will be copied from '+
                                                                 oppName + ' to its duplicate opportunity ' +dupOpp +
                                                                 '. Are you sure you want to continue?';
                                        }
                                        else {
                                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please fill in a Duplicate Opportunity and try again.'));    
                                        }
                                } else {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'You do not have sufficient privileges to perform this action.'));        
                                }
                        }
                }

                return null;
        }

        public PageReference createViewOrderForm()
        {
                String result;

                try
                {
                        result = OrderApprovalClass.Create_OrderApproval(recordId,recordTypeId,stageName,getField);
                }

                catch(Exception err)
                {
                        String myRegExp = 'INSUFFICIENT_ACCESS';
                        String errString = err+'';
                        if(errString.contains(myRegExp) != true)
                                result = '0:You do not have sufficient access to create an Order Approval.';
                        else
                                result = '0:An unexpected error has occurred. Please contact your System Administrator\n\n' + 'Error : ' + err;
                }
                String resultFlag = result.substring(0, result.indexOf(':'));
                String resultMessage = result.substring(result.indexOf(':') + 1, result.length());
                if (resultMessage != null && resultMessage.startsWith('/')) {
                        resultMessage = resultMessage.replaceFirst('/','');
                }
                if(resultFlag == '1')
                {
                        pageRef = new PageReference('/' + resultMessage);
                        pageRef.setRedirect(true);

                        List<Order_Approval__c> oaList = [select Id, Associated_Opportunity__r.Id, Associated_Opportunity__r.Momentum_Order_Form_Initiated__c, Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c from Order_Approval__c where Associated_Opportunity__c = :recordId];

                        System.debug('Order Approval : ' + oaList);

                        OpportunityButtonPageController.updateMomentumFields(oaList);

                        resultFlag = '';
                        return pageRef;
                }

                else
                {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, resultMessage));
                        return null;
                }
        }

        @TestVisible public static void updateMomentumFields(List<Order_Approval__c> oaList)
        {
                List<Opportunity> opptyList = new List<Opportunity>();

                System.debug('Order Approval : ' + oaList);

                for(Order_Approval__c eachOA : oaList)
                {
                        Opportunity newOppty = new Opportunity();
                        newOppty.Id = eachOA.Associated_Opportunity__r.Id;

                        if(eachOA.Associated_Opportunity__r.Momentum_Order_Form_Initiated__c != true)
                        {
                                newOppty.Momentum_Order_Form_Initiated__c = true;
                        }

                        if(eachOA.Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c == null)
                        {
                                newOppty.Momentum_Order_Form_Initiated_Date__c = System.now();
                        }

                        newOppty.Validation_Override__c = true;

                        opptyList.add(newOppty);
                        System.debug('Oppty List : ' + opptyList);
                }

                if(opptyList.size() > 0)
                {
                        Database.SaveResult[] resultSet = Database.update(opptyList, false);

                        System.debug('Result Set : ' + resultSet);

                        Integer index = 0;
                        List<Error_log__c> errorLogList = new List<Error_log__c>();

                        for (Database.SaveResult sr : resultSet)
                        {
                                if (!sr.isSuccess())
                                {
                                        for(Database.Error err : sr.getErrors())
                                        {
                                                Error_log__c erroLog = new Error_log__c(Class__c = 'OpportunityButtonPageController',Error_Message__c = err.getMessage(),RecordId__c = opptyList.get(index).Id);
                                                errorLogList.add(erroLog);
                                        }
                                }
                                index++;
                        }

                        if(errorLogList.size() > 0)
                        {
                                insert errorLogList;
                        }
                }
        }

        public PageReference submitForOppApproval() {
                String result;
                system.debug('FCM = '+fcm);
                if(rebate=='false') {
                        if(fcm==null || fcm == '') {
                                system.debug('FCM loggic');
                                pageRef = new PageReference('/apex/FCMselectionpage?oppty='+(Id)recordId);
                                pageRef.setRedirect(true);
                                return pageRef;
                        }
                    
                        else {
                                result = OpportunityButtonPageController.submitForApproval((Id)recordId);
                                if(result!='')
                                {
                                    if(result.startsWith('Succesfully submitted')){
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,result));
                                        pageRef = new PageReference('/'+(Id)recordId);
                                        pageRef.setRedirect(true);
                                        return pageRef;
                                    }
                                    else{
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,result));
                                        return null;
                                    }
                                } else {
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Some unknown exception occurred'));
                                        return null;
                                }
                        }

                }
                else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please Accept/Reject Rebate Terms And Conditions'));
                        return null;
                }
        }

        public PageReference campaignManagerApproval() {
                String result =  'Error . Contact system Administrator';
                result = OpportunityButtonPageController.campaignManagerApproval((Id)recordId);
                System.debug('result: ' + result);
                if(result!='') {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,result));
                }
                // else {
                //     pageRef = new PageReference('/'+(Id)recordId);
                //     pageRef.setRedirect(true);
                //     return pageRef;
                // }
                return null;
        }
        @TestVisible public static String submitForApproval(Id p_OppId) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitted for approval. Please approve.');
                req.setObjectId(p_OppId);
                String customSettingsExceptionCheck = GsmUtilClass.getGSMSettingValue('DealRegSubmit_ProfileException');
                String userProfileId = userinfo.getProfileId();
                // submit the approval request for processing
                Boolean isOppty=String.valueOf(p_OppId).startsWith('006');
                Opportunity oppty;
                if(isOppty)
                {
                        oppty = [Select CloseDate from Opportunity where Id=:p_OppId][0];
                }

                if(!isOppty || customSettingsExceptionCheck.contains(userProfileId) || ( isOppty && oppty.CloseDate!=null && oppty.CloseDate>=Date.today()))
                {
                        String statusMessage = '';
                        Boolean hasError=false;
                        try
                        {	
                            	if (!Test.isRunningTest())
                                	Approval.ProcessResult result = Approval.process(req);
                        }
                        catch(System.DmlException e)
                        {
                                
                                hasError=true;
								for (Integer i = 0; i < e.getNumDml(); i++)
                                {
                                        if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||e.getDmlType(i) == Statuscode.FIELD_INTEGRITY_EXCEPTION)
                                        {
                                                statusMessage += e.getDmlMessage(i);
                                        }
                                        else
                                                throw e;
                                }
                        }
                        catch(Exception e)
                        {
                                hasError=true;
                                String errMessage = e.getMessage();
                                if(errMessage.contains('MANAGER_NOT_DEFINED'))
                                        statusMessage += 'Fund Request Approver on the Channel Mapping is an invalid user.';
                                else
                                        statusMessage += errMessage;
                        }

                        if(hasError)
                                return statusMessage;
                        else
                                return 'Succesfully submitted for approval.';
                }
                else
                {
                        return 'A Deal Registration can not be submitted after the close date.';
                }
        }

        @TestVisible public static String campaignManagerApproval(Id opptyId){
                Opportunity updateObject;
                for(Opportunity o:[Select id, Associated_Lead__c, Campaign_Manager_Approved__c from Opportunity where id = :opptyId]) {
                        if(o != null) {updateObject = o;}
                }

                if(updateObject.Associated_Lead__c == null) {
                        return 'There is no lead associated with this Opportunity';
                }

                if(updateObject.Campaign_Manager_Approved__c == true) {
                        return 'This Tieback has already been approved';
                }

                updateObject.Campaign_Manager_Approved__c = true;
                updateObject.Validation_Override__c = true;

                update updateObject;

                return 'Successfully Approved this tieback';
        }

        public PageReference salesRepAcknowledge() {
            String errorMessage;
            if((profileName=='Partner Support') || (profileName=='Sales Operations') || 
                (profileName=='Business Operations') || (profileName=='System Administrator') || 
                (currentUserId==oppOwnerId)) {
                try {
                    Boolean result = DealReg.AcknowledgeButton(recordId);
                    pageRef = new PageReference('/'+recordId);
                    pageRef.setRedirect(true);
                    return pageRef;
                } catch (Exception e) {
                    if(e.getMessage().contains('INSUFFICIENT_ACCESS')) {
                        errorMessage = 'You do not have sufficient access to perform this operation.';
                    } else {
                        errorMessage = 'An unexpected error has occurred. Please contact your System Administrator. Error = '+e.getMessage();

                    }
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You do not have sufficient access to perform this operation.'));    
            } 
            return null;    
        }

        public PageReference transferOpptyToPartner() {
            if(profileName=='Sales - Partner Account Executive' || profileName=='Business Operations' ||
                profileName=='Sales Operations' || profileName=='Partner Support' ||
                profileName=='System Administrator' || profileName=='Sales - Rep') {
                pageRef = new PageReference('/apex/TransferOpptyToPartner?id='+recordId);
                pageRef.setRedirect(true);
                return pageRef;    
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You do not have sufficient access to perform this task.'));        
            }

            return null;
        }

        public PageReference performMigrateDealRegData() {
            recordId     = ApexPages.currentPage().getParameters().get('recordId');
            String result = GsmUtilClass.migrateDealRegData(recordId);
            viewMigrateDealRegData = false;
            viewMigrateDealRegDataResult = true;
            migrateDealRegData = '';
            migrateDealRegData = result;
            return null;
        }

        public PageReference backToOppty() {
            recordId     = ApexPages.currentPage().getParameters().get('recordId');
            pageRef = new PageReference('/'+(Id)recordId);
            pageRef.setRedirect(true);
            return pageRef;
        }

}
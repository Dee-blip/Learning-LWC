//SFDC-1440
global without sharing Class PartnerOrderAcceptanceClass {
    private static Boolean createCaseForPoadHasRun = false;
    public static void createCaseForPoad(List < Partner_Order_Acceptance_Document__c > caseCreationForPoad) {
        //SFDC-8428 : Start
        if(createCaseForPoadHasRun) {
            return;
        }
        createCaseForPoadHasRun = true;
        //SFDC-8428 : End
        String queueId = GsmUtilClass.getGSMSettingValue('PartnerOrderAcceptance_QueueId');
        String poadRecordType = GsmUtilClass.getGSMSettingValue('PartnerOrderAcceptance_RecordType');
        List < Case > newBillingCases = new List < Case > ();
        List < Id > poadIds = new List < Id > ();
        for (Partner_Order_Acceptance_Document__c eachPoad: caseCreationForPoad) {
            poadIds.add(eachPoad.Id);
        }
        if (poadIds.size() > 0) {
            Map < Id, String > mapOfPoadToPartnerAccountName = new Map < Id, String > ();
            Map < Id, String > mapOfPoadToPartnerAccountId = new Map < Id, String > ();
            List < Id > partnerAccounts = new List < Id > ();
            List < Partner_Order_Acceptance_Document__c > partnerAccountDetailsOfPoad = [select Id, Opportunity__r.Partner_Involved__c, Opportunity__r.Partner_Involved__r.Id, Opportunity__r.Partner_Involved__r.Name from Partner_Order_Acceptance_Document__c where Id in: poadIds and Opportunity__r.Partner_Involved__r.Partner_Billing_Training__c = null];
            if (partnerAccountDetailsOfPoad != null && partnerAccountDetailsOfPoad.size() > 0) {
                for (Partner_Order_Acceptance_Document__c eachAccountDetails: partnerAccountDetailsOfPoad) {
                    mapOfPoadToPartnerAccountName.put(eachAccountDetails.Id, eachAccountDetails.Opportunity__r.Partner_Involved__r.Name);
                    mapOfPoadToPartnerAccountId.put(eachAccountDetails.Id, eachAccountDetails.Opportunity__r.Partner_Involved__r.Id);
                    partnerAccounts.add(eachAccountDetails.Opportunity__r.Partner_Involved__c);
                }
                for (Partner_Order_Acceptance_Document__c eachPoad: caseCreationForPoad) {
                    //Create cases for the Partner Account
                    Case newBillingCase = new Case();
                    newBillingCase.RecordTypeId = poadRecordType;
                    newBillingCase.Origin = 'First Invoice Confirmation';
                    newBillingCase.Service__c = 'Contract / Invoice Enquiry';
                    newBillingCase.Request_Type__c = 'Contract/Invoice Interpretation';
                    newBillingCase.OwnerId = queueId;
                    newBillingCase.AccountId = mapOfPoadToPartnerAccountId.get(eachPoad.Id);
                    newBillingCase.Subject = 'Partner Onboarding - ' + mapOfPoadToPartnerAccountName.get(eachPoad.Id);
                    newBillingCase.Description = 'Partner Onboarding - ' + mapOfPoadToPartnerAccountName.get(eachPoad.Id);
                    newBillingCases.add(newBillingCase);
                }
                List < Account > poadPartnerAccounts = new List < Account > ();
                try {
                    if (newBillingCases.size() > 0) {
                        Database.SaveResult[] resultSet = Database.insert(newBillingCases, false);
                        Integer index = 0;
                        List < Error_log__c > errorLogList = new List < Error_log__c > ();
                        for (Database.SaveResult sr: resultSet) {
                            if (!sr.isSuccess()) {
                                for (Database.Error err: sr.getErrors()) {
                                    Error_log__c erroLog = new Error_log__c(Class__c = 'PartnerOrderAcceptanceClass', Error_Message__c = err.getMessage(), RecordId__c = newBillingCases.get(index).Id);
                                    errorLogList.add(erroLog);
                                }
                            } else {
                                Account newAccount = new Account();
                                newAccount.Id = newBillingCases[index].AccountId;
                                newAccount.Partner_Billing_Training__c = Date.today();
                                newAccount.Validation_Override__c = true;

                                poadPartnerAccounts.add(newAccount);
                            }

                            index++;
                        }

                        if (errorLogList.size() > 0) {
                            insert errorLogList;
                        }

                    }
                } catch (Exception e) {
                    Sawyer.saw(e);
                }

                Database.SaveResult[] resultSet = Database.update(poadPartnerAccounts, false);
                Integer index = 0;
                List < Error_log__c > errorLogList = new List < Error_log__c > ();
                for (Database.SaveResult sr: resultSet) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err: sr.getErrors()) {
                            Error_log__c erroLog = new Error_log__c(Class__c = 'PartnerOrderAcceptanceClass', Error_Message__c = err.getMessage(), RecordId__c = poadPartnerAccounts.get(index).Id);
                            errorLogList.add(erroLog);
                        }
                    }
                    index++;
                }
                if (errorLogList.size() > 0) {
                    insert errorLogList;
                }
            }
        }
    }
} //End of SFDC-1440
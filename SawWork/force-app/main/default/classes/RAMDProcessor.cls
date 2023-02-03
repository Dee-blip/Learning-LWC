/**
 * Created by kusharma on 30/10/17.
 */

public with sharing class RAMDProcessor {

    Set<String> sOrangeZoneCountries = new Set<String>();
    List<Account> lOZoneAccounts = new List<Account>();
    List<Account> lAccountsForReview = new List<Account>();
    List<Account> lNonOZoneAccounts = new List<Account>();
    List<Account> lAccountNoSalesPrimary = new List<Account>();
    List<Account> lAccountsToUpdate = new List<Account>();
    Map<String, RAMD_Processor__c> mRAMDRecsToProcess = new Map<String, RAMD_Processor__c>();
    Map<String, String> mRAMDProccessorAndEmailTemplate = new Map<String, String>();
    Map<String, String> mTeamplateNameAndId = new Map<String, String>();
    List<Messaging.SingleEmailMessage> lEmailMessages = new List<Messaging.SingleEmailMessage>();
    List<RAMD_Setting__mdt> lRAMDSettings = new List<RAMD_Setting__mdt>();
    Map<String, String> mRAMDSettings = new Map<String, String>();
    String emailTemplateId;
    //changes : adding recursive check
    public static Boolean isFirstTime = true;

    public RAMDProcessor() {
        for (RAMD_Orange_Zone_Countries__c varOZoneCountries : [
                SELECT Id, Country_Name__c
                FROM RAMD_Orange_Zone_Countries__c
                WHERE Active__c = true
        ]) {
            sOrangeZoneCountries.add(varOZoneCountries.Country_Name__c);
        }

        for (RAMD_Setting__mdt varRAMDSetting : [
                SELECT Id, Value__c, Label, DeveloperName
                FROM RAMD_Setting__mdt
        ]) {
            lRAMDSettings.add(varRAMDSetting);
            mRAMDSettings.put(varRAMDSetting.DeveloperName, varRAMDSetting.Value__c);
        }
        System.debug('$$$$$$$ mRAMDSettings $$$$$$$$ ' + mRAMDSettings);
        for (EmailTemplate varEmailTemplate : [
                SELECT Id, Name
                FROM EmailTemplate
                WHERE Name IN ('GSS Management review OZone', 'GSS Management Review: Account Country Change',
                               'GSS Management review: No Sales Primary', 'GSS Management review OZone Modification')
        ]) {
            mTeamplateNameAndId.put(varEmailTemplate.Name, varEmailTemplate.Id);
            emailTemplateId = varEmailTemplate.Id;
        }
    }

    /*
    This method should be called from batch class that process all the recs present in RAMD Proccessor object.
     */
    public void pendingRecProcessor(List<RAMD_Processor__c> lRAMDRecsToProcessor) {
        List<Account> lAllAccountsToUpdate = new List<Account>();
        System.debug('##sOrangeZoneCountries## ' + sOrangeZoneCountries);
        System.debug('## lRAMDRecsToProcessors## ' + lRAMDRecsToProcessor);
        for (RAMD_Processor__c varRAMDProcessor :lRAMDRecsToProcessor) {
            orangeZoneCheck(varRAMDProcessor);
        }
        System.debug('##lOZoneAccounts## ' + lOZoneAccounts + ' ###lAccountsForReview## ' + lAccountsForReview);
        Database.update(lAccountsToUpdate, false);
        updateRAMDRecsToProcess(lRAMDRecsToProcessor);
        if (mRAMDSettings.get('InactivateOZoneEmail').equalsIgnoreCase('false')) {
            sendRequestForReview(lRAMDRecsToProcessor);
        }


    }

    private void updateRAMDRecsToProcess(List<RAMD_Processor__c> lRAMDRecsToProcessors) {
        for (RAMD_Processor__c varRamdProcessor : lRAMDRecsToProcessors) {
            varRamdProcessor.Processing_Status__c = 'Completed';

        }
        Database.update(lRAMDRecsToProcessors, false);
    }

    private void orangeZoneCheck(RAMD_Processor__c varRAMDProcessor) {
        System.debug('###varRAMDProcessor### ' + varRAMDProcessor);
        if (varRAMDProcessor.Event_Type__c != null
                && varRAMDProcessor.Event_Type__c.equalsIgnoreCase('Sales Primary Movement')) {
            salesPrimaryChangeOZoneCheck(varRAMDProcessor);
        }
        else if (varRAMDProcessor.Event_Type__c != null
                && varRAMDProcessor.Event_Type__c.equalsIgnoreCase('Account Country Change')) {
            accountCountryChangeOzoneCheck(varRAMDProcessor);
        } else if (varRAMDProcessor.Event_Type__c != null
                && (varRAMDProcessor.Event_Type__c.equalsIgnoreCase('New Record')
                || varRAMDProcessor.Event_Type__c.equalsIgnoreCase('New OZone Country'))) {
            newRecOZoneCheck(varRAMDProcessor);
        }

    }

    private void newRecOZoneCheck(RAMD_Processor__c varRAMDProcessor) {
        if (sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Billing country is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, true, varRAMDProcessor.Account_Country__c,
                    'Billing country is ozone', 'OZone Account');
        }
        else if (!sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Sales - Primary is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'Pending Verification');
            mRAMDProccessorAndEmailTemplate.put(varRAMDProcessor.Id, mTeamplateNameAndId.get('GSS Management review OZone'));
        }
        else {
            varRAMDProcessor.Processing_Reason__c = 'Not OZone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', '');
        }
    }

    private void accountCountryChangeOzoneCheck(RAMD_Processor__c varRAMDProcessor) {
        if (sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && !varRAMDProcessor.Account__r.Orange_Zone__c) {
            varRAMDProcessor.Processing_Reason__c = 'Billing country is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, true, varRAMDProcessor.Account_Country__c,
                    'Billing country is ozone', 'OZone Account');
        }
        else if (!sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Sales - Primary is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'Pending Verification');
            mRAMDProccessorAndEmailTemplate.put(varRAMDProcessor.Id, mTeamplateNameAndId.get('GSS Management Review: Account Country Change'));
        }
        else if (!sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && !sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)
                && varRAMDProcessor.Account__r.Orange_Zone__c) {
            varRAMDProcessor.Processing_Reason__c = 'Not OZone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', '');
        }
        else {
            varRAMDProcessor.Processing_Reason__c = 'Nothing to process';
            System.debug(' *** No update has to be done on Account *** ');
        }
    }

    private void salesPrimaryChangeOZoneCheck(RAMD_Processor__c varRAMDProcessor) {
        if (sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Billing country is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, true, varRAMDProcessor.Account_Country__c,
                    'Billing country is ozone', 'Orange Zone Account');
        }
        else if (varRAMDProcessor.Sales_Primary__c == null && varRAMDProcessor.Account__r.Orange_Zone__c
                && sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country_Old__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Request is on hold';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'On Hold');
            mRAMDProccessorAndEmailTemplate.put(varRAMDProcessor.Id, mTeamplateNameAndId.get('GSS Management review: No Sales Primary'));
            System.debug('**** Send Email Here **** ' + mTeamplateNameAndId.get('GSS Management review: No Sales Primary'));
        }
        else if (varRAMDProcessor.Sales_Primary__c != null
                && sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'Sales - Primary is ozone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'Pending Verification');
            System.debug('**** Send Email Here for movement of Sales Primary from Ozone **** ' + mTeamplateNameAndId.get('GSS Management review OZone'));
            mRAMDProccessorAndEmailTemplate.put(varRAMDProcessor.Id, mTeamplateNameAndId.get('GSS Management review OZone Modification'));
        }
        else if (varRAMDProcessor.Sales_Primary__c != null && varRAMDProcessor.Account__r.Orange_Zone__c
                && !sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
            varRAMDProcessor.Processing_Reason__c = 'New Sales - Primary is not ozone';
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'Pending Verification');
            System.debug('**** Send Email Here for movement of Sales Primary Not form Ozone **** ');
            mRAMDProccessorAndEmailTemplate.put(varRAMDProcessor.Id, mTeamplateNameAndId.get('GSS Management review: No Sales Primary'));
        }
        else {
            varRAMDProcessor.Processing_Reason__c = 'Nothing to process';
            System.debug('The RAMD Processor that are not being updated salesPrimaryChangeOZoneCheck');
        }
    }

    /*private void userCountryChange(RAMD_Processor__c varRAMDProcessor) {
        if (sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && !varRAMDProcessor.Account__r.Orange_Zone__c) {
            accountToUpdate(varRAMDProcessor.Account__c, true, varRAMDProcessor.Account_Country__c,
                    'Billing country is ozone', 'Orange Zone Account');
        }
        else if (!sOrangeZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                && sOrangeZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', 'Pending Verification');
        }
        else if (varRAMDProcessor.Account__r.Orange_Zone__c) {
            accountToUpdate(varRAMDProcessor.Account__c, false, '',
                    '', '');
        }
        else {
            System.debug('*** The RAMD Processor that are not being updated userCountryChange *** ');
        }
    }*/

    private void accountToUpdate(String accountId, Boolean oZoneStatus,
            String oZoneCountry, String oZoneDecisionReason,
            String oZoneProcessingString) {
        Account varAccount = new Account();
        varAccount.Id = accountId;
        varAccount.Orange_Zone__c = oZoneStatus;
        varAccount.Orange_zone_country__c = oZoneCountry;
        varAccount.Orange_Zone_Decision_Reason__c = oZoneDecisionReason;
        varAccount.OZone_Status__c = oZoneProcessingString;
        lAccountsToUpdate.add(varAccount);

    }

    private void sendRequestForReview(List<RAMD_Processor__c> lRAMDRecsToProcessors) {

        List<String> lUsersIdsToSendEmail = new List<String>();
        List<Messaging.SingleEmailMessage> lEmailMessageToSend = new List<Messaging.SingleEmailMessage>();
        for (PermissionSetAssignment varPermissionSetAssignment: [
                SELECT Id, PermissionSetId, Assignee.Name, AssigneeId,PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN ('RAMD_Admin_Users','RAMD_GSS_Management_Users')
        ]) {
            lUsersIdsToSendEmail.add(varPermissionSetAssignment.AssigneeId);

        }
        for (RAMD_Processor__c varRamdProcessor :lRAMDRecsToProcessors) {
            System.debug(' ******** Send Email Here to lRAMDRecsToProcessors ******** ' + varRamdProcessor.Id + ' ### ' + mTeamplateNameAndId + ' ### ' + mRAMDProccessorAndEmailTemplate.containsKey(varRamdProcessor.Id));

            if (mRAMDProccessorAndEmailTemplate.containsKey(varRamdProcessor.Id)) {
                Messaging.SingleEmailMessage varEmailMessage = new Messaging.SingleEmailMessage();
                varEmailMessage.setTemplateId(mRAMDProccessorAndEmailTemplate.get(varRamdProcessor.Id));
                varEmailMessage.setWhatId(varRamdProcessor.Id);
                varEmailMessage.setTargetObjectId(lUsersIdsToSendEmail[0]);
                varEmailMessage.setOrgWideEmailAddressId(mRAMDSettings.get('FromAddressForEmails'));
                varEmailMessage.setSaveAsActivity(false);
                varEmailMessage.setToAddresses(lUsersIdsToSendEmail);
                lEmailMessageToSend.add(varEmailMessage);

            }
        }
        Messaging.sendEmail(lEmailMessageToSend);

    }

    public void processInactiveCountries(List<RAMD_Orange_Zone_Countries__c> lTriggerNew, Boolean isUpdate, Map<Id, RAMD_Orange_Zone_Countries__c> mOldMap){
        List<String> lInactiveCountries = new List<String>();
        List<RAMD_Processor__c> lAccountWithInactiveCountries = new List<RAMD_Processor__c>();
        List<String> lAccountsIdToUpdate = new List<String>();
        List<Account> lAccountsToUpdate = new List<Account>();
        if(isUpdate){
            for (RAMD_Orange_Zone_Countries__c varRAMDCountryUpdated: lTriggerNew) {
                if (!varRAMDCountryUpdated.Active__c
                        && mOldMap.get(varRAMDCountryUpdated.Id).Active__c) {
                    lInactiveCountries.add(varRAMDCountryUpdated.Country_Name__c);
                }

            }
        }

        if (!lInactiveCountries.isEmpty()) {
            for (RAMD_Processor__c varRAMDProcessor : [SELECT Id, Account__c, Account__r.OZone_validation_override__c FROM RAMD_Processor__c WHERE Account_Country__c IN : lInactiveCountries OR Sales_Primary_Country__c IN : lInactiveCountries]) {
                if (!varRAMDProcessor.Account__r.OZone_validation_override__c) {
                    lAccountsIdToUpdate.add(varRAMDProcessor.Account__c);
                }

            }

            if (!lAccountsIdToUpdate.isEmpty()) {
                for (String varAccountId : lAccountsIdToUpdate){
                    Account varAccount = new Account();
                    varAccount.Id = varAccountId;
                    varAccount.Orange_Zone__c =false;
                    varAccount.Orange_Zone_Decision_Reason__c = '';
                    varAccount.Orange_zone_country__c = '';
                    varAccount.OZone_Status__c = '';
                    lAccountsToUpdate.add(varAccount);
                }

            }

            if (!lAccountsToUpdate.isEmpty()) {
                Database.update(lAccountsToUpdate);
            }
        }

    }

    /*private void updateAccountRecs(List<Account> lAllAccountsToUpdate) {
        System.debug(' ******** Update all recs here ******** ' + lAllAccountsToUpdate);
        Database.update(lAllAccountsToUpdate, false);
    }*/
    /*
    This is a future method for handeling public sector Accounts from Contract Details.

    @future
    public static void checkPublicSectorAccount(List<String> lContractDetailIds) {
        List<String> lPublicSectorAccountId = new List<String>();
        List<Account> lPublicSectorAccounts = new List<Account>();
        for (Merge_Contract_Detail__c varContractDetail: [
                SELECT Id, Product_Id__c, Original_Contract_Id__r.Account_Name__c
                FROM Merge_Contract_Detail__c
                WHERE Id IN :lContractDetailIds
        ]) {
            lPublicSectorAccountId.add(varContractDetail.Original_Contract_Id__r.Account_Name__c);
        }
        for (String varAccountId :lPublicSectorAccountId) {
            Account varAccountToUpdate = new Account();
            varAccountToUpdate.Id = varAccountId;
            varAccountToUpdate.Public_Sector_Account__c = true;
            lPublicSectorAccounts.add(varAccountToUpdate);
        }
        if (!lPublicSectorAccounts.isEmpty()) {
            update lPublicSectorAccounts;

        }
    }
    */


    /*
    This should be called from Account Trigger to check Account Country change.
     */
    public void accountCountryChange(List<Account> lAccounts, Map<Id, Account> oldMap, Boolean isInsert) {
        Map<String, String> mAccountAndNewCountry = new Map<String, String>();
        List<RAMD_Processor__c> lRAMDProcessorRecsToUpdate = new List<RAMD_Processor__c>();
        List<Account> lAccountsToUpdate = new List<Account>();
        if ( !isInsert && mRAMDSettings.get('InactivateAccountTrigger').equalsIgnoreCase('false')) {
            for (Account varAccount :lAccounts) {
                if (varAccount.Account_Status__c != null && varAccount.Account_Status__c.containsIgnoreCase('Active')
                        && !varAccount.Account_Status__c.containsIgnoreCase('Inactive')
                        && (varAccount.BillingCountry != oldMap.get(varAccount.Id).BillingCountry)) {
                    System.debug(' ### Inside Account Country update ### ');
                    mAccountAndNewCountry.put(varAccount.Id, varAccount.BillingCountry);
                    varAccount.OZone_Status__c = '';
                    varAccount.Orange_Zone_Decision_Reason__c = '';
                    varAccount.Orange_Zone__c = false;
                    varAccount.Orange_zone_country__c = '';
                }
            }

            System.debug('## mAccountAndNewCountry ## ' + mAccountAndNewCountry);
            if (!mAccountAndNewCountry.keySet().isEmpty()) {
                lRAMDProcessorRecsToUpdate = [
                        SELECT Id, OwnerId, IsDeleted, Name,
                                CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                                SystemModstamp, ConnectionReceivedId, ConnectionSentId, Account_Country__c,
                                Account__c, Manually_Managed_Account__c, Processing_Status__c,
                                Sales_Primary_Country__c, Sales_Primary__c, Transaction_Id__c, Event_Type__c,
                                Account__r.BillingCountry, Sales_Primary__r.Country,Account_Country_Old__c
                        FROM RAMD_Processor__c
                        WHERE Account__c = :mAccountAndNewCountry.keySet()
                        AND Manually_Managed_Account__c = false
                ];
                for (RAMD_Processor__c varRAMDProcessor :lRAMDProcessorRecsToUpdate) {
                    varRAMDProcessor.Processing_Status__c = 'Pending';
                    varRAMDProcessor.Account_Country_Old__c = varRAMDProcessor.Account_Country__c;
                    varRAMDProcessor.Account_Country__c = mAccountAndNewCountry.get(varRAMDProcessor.Account__c);
                    varRAMDProcessor.Event_Type__c = 'Account Country Change';
                    varRAMDProcessor.Processing_Reason__c = '';
                }
                System.debug('## lRAMDProcessorRecsToUpdate ## ' + lRAMDProcessorRecsToUpdate);
                if (!lRAMDProcessorRecsToUpdate.isEmpty()) {
                    Database.update(lRAMDProcessorRecsToUpdate, false);

                }
            }
        }
    }

    /*
    This should be called from a User Trigger to check the User Country Change.
     */
    public void userCountryChange(List<User> lUsers, Map<Id, User> oldUserMap, Boolean isInsert) {
        List<RAMD_Processor__c> lRAMDProcessorRecsToUpdate = new List<RAMD_Processor__c>();
        Map<String, String> mUserAndNewCountry = new Map<String, String>();
        if ( !isInsert && mRAMDSettings.get('InactivateUserTrigger').equalsIgnoreCase('false')) {
            for (User varUser :lUsers) {
                if (varUser.Country != oldUserMap.get(varUser.Id).Country) {
                    mUserAndNewCountry.put(varUser.Id, varUser.Country);
                }
            }


            if (!mUserAndNewCountry.keySet().isEmpty()) {
                lRAMDProcessorRecsToUpdate = [
                        SELECT Processing_Status__c, Sales_Primary_Country__c,
                                Sales_Primary__c,Event_Type__c,Sales_Primary_Country_Old__c,Sales_Primary_Name_Old__c,
                                Sales_Primary__r.Name
                        FROM RAMD_Processor__c
                        WHERE Sales_Primary__c IN :mUserAndNewCountry.keySet()
                        AND Manually_Managed_Account__c = false
                ];
                for (RAMD_Processor__c varRAMDProcessor :lRAMDProcessorRecsToUpdate) {
                    varRAMDProcessor.Sales_Primary_Country_Old__c = varRAMDProcessor.Sales_Primary_Country__c;
                    varRAMDProcessor.Sales_Primary_Name_Old__c = varRAMDProcessor.Sales_Primary__r.Name;
                    varRAMDProcessor.Processing_Status__c = 'Pending';
                    varRAMDProcessor.Sales_Primary_Country__c = mUserAndNewCountry.get(varRAMDProcessor.Sales_Primary__c);
                    varRAMDProcessor.Processing_Reason__c = '';
                    varRAMDProcessor.Event_Type__c = 'Sales Primary Movement';
                }
                if (!lRAMDProcessorRecsToUpdate.isEmpty()) {
                    Database.update(lRAMDProcessorRecsToUpdate, false);

                }
            }
        }
    }

    /*
    This method should be called from Batch class.
     */
    public void processATMChanges(List<Account> lAccountsToProcess) {
        System.debug(' ##@#@##@ ' + lAccountsToProcess);
        Map<String, AccountTeamMember> mAccountAndATM = new Map<String, AccountTeamMember>();
        Map<String, RAMD_Processor__c> mRAMDProcessorRecs = new Map<String, RAMD_Processor__c>();
        List<RAMD_Processor__c> lRAMDProccessProcessorsToUpsert = new List<RAMD_Processor__c>();
        for (AccountTeamMember varATM : [
                SELECT Id, AccountId,Account.BillingCountry,
                        CreatedDate, UserId, User.Country
                FROM AccountTeamMember
                WHERE AccountId IN :lAccountsToProcess
                AND TeamMemberRole = 'Sales - Primary'
                ORDER BY AccountId DESC,
                        CreatedDate ASC
        ]) {
            if (!mAccountAndATM.containsKey(varATM.AccountId)) {
                mAccountAndATM.put(varATM.AccountId, varATM);
            }


        }

        for (RAMD_Processor__c varRAMDProcessor: [
                SELECT Id, OwnerId, IsDeleted, Name,
                        CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,
                        SystemModstamp, ConnectionReceivedId, ConnectionSentId, Account_Country__c,
                        Account__c, Manually_Managed_Account__c, Processing_Status__c,
                        Sales_Primary_Country__c, Sales_Primary__c, Transaction_Id__c, Event_Type__c,
                        Sales_Primary_Country_Old__c,Sales_Primary_Name_Old__c,Sales_Primary__r.Name
                FROM RAMD_Processor__c
                WHERE Account__c IN :lAccountsToProcess
        ]) {
            mRAMDProcessorRecs.put(varRAMDProcessor.Account__c, varRAMDProcessor);

        }
        System.debug('##@@ mRAMDProcessorRecs ' + mRAMDProcessorRecs + '!!!! mAccountAndATM ' + mAccountAndATM);
        for (Account varAccount :lAccountsToProcess) {
            if (mRAMDProcessorRecs.containsKey(varAccount.Id)) {
                if (!mRAMDProcessorRecs.get(varAccount.Id).Manually_Managed_Account__c) {
                    if (mAccountAndATM.containsKey(varAccount.Id)
                            && (mRAMDProcessorRecs.get(varAccount.Id).Sales_Primary__c != mAccountAndATM.get(varAccount.Id).UserId)) {
                        lRAMDProccessProcessorsToUpsert.add(createRAMDProcessor('Pending', mAccountAndATM.get(varAccount.Id).UserId, mAccountAndATM.get(varAccount.Id).User.Country,
                                varAccount.Id, varAccount.BillingCountry, 'Sales Primary Movement', mRAMDProcessorRecs.get(varAccount.Id).Sales_Primary__r.Name,
                                mAccountAndATM.get(varAccount.Id).User.Country, mRAMDProcessorRecs.get(varAccount.Id).Id, ''));
                    } else if (!mAccountAndATM.containsKey(varAccount.Id)
                            && mRAMDProcessorRecs.containsKey(varAccount.Id)
                            && mRAMDProcessorRecs.get(varAccount.Id).Sales_Primary__c != null) {
                        //This is the case where Sales Primary is not present On Account. It is deleted now.
                        //Earlier it was present on the Acccount.
                        lRAMDProccessProcessorsToUpsert.add(createRAMDProcessor('Pending', null, '',
                                varAccount.Id, varAccount.BillingCountry, 'Sales Primary Movement', mRAMDProcessorRecs.get(varAccount.Id).Sales_Primary__r.Name,
                                mRAMDProcessorRecs.get(varAccount.Id).Sales_Primary_Country__c, mRAMDProcessorRecs.get(varAccount.Id).Id, ''));
                    }
                }
            }

            else if (!mRAMDProcessorRecs.containsKey(varAccount.Id)) {
                System.debug(' #### inside no ATM found ');
                if (mAccountAndATM.containsKey(varAccount.Id)) {
                    lRAMDProccessProcessorsToUpsert.add(createRAMDProcessor('Pending', mAccountAndATM.get(varAccount.Id).UserId, mAccountAndATM.get(varAccount.Id).User.Country,
                            varAccount.Id, varAccount.BillingCountry, 'New Record', '',
                            '', null, ''));

                }
                else {
                    lRAMDProccessProcessorsToUpsert.add(createRAMDProcessor('Pending', null, '',
                            varAccount.Id, varAccount.BillingCountry, 'New Record', '',
                            '', null, ''));
                    System.debug('!!!%%%% ' + varAccount);
                }
            }

        }
        System.debug(' ###$$$$ ' + lRAMDProccessProcessorsToUpsert);
        Database.upsert(lRAMDProccessProcessorsToUpsert, false);

    }

    private RAMD_Processor__c createRAMDProcessor(String processingStatus, String salesPrimaryId, String salesPrimaryCountry,
            String accountId, String accountCountry, String eventType, String salesPrimaryNameOld,
            String salesPrimaryCountryOld, String existingRAMDProcessorId, String processingReason) {
        RAMD_Processor__c varRAMDProcessorToUpsert = new RAMD_Processor__c();
        varRAMDProcessorToUpsert.Id = existingRAMDProcessorId;
        varRAMDProcessorToUpsert.Sales_Primary_Name_Old__c = salesPrimaryNameOld;
        varRAMDProcessorToUpsert.Sales_Primary_Country_Old__c = salesPrimaryCountryOld;
        varRAMDProcessorToUpsert.Processing_Status__c = processingStatus;
        varRAMDProcessorToUpsert.Sales_Primary__c = salesPrimaryId;
        varRAMDProcessorToUpsert.Sales_Primary_Country__c = salesPrimaryCountry;
        varRAMDProcessorToUpsert.Event_Type__c = eventType;
        varRAMDProcessorToUpsert.Processing_Reason__c = processingReason;
        varRAMDProcessorToUpsert.Account__c = accountId;
        varRAMDProcessorToUpsert.Account_Country__c = accountCountry;

        return varRAMDProcessorToUpsert;
    }

    public void processNewOZoneCountry(List<RAMD_Processor__c> lRAMDRecsToProcessors) {
        Set<String> sNewOZoneCountries = new Set<String>();
        List<RAMD_Orange_Zone_Countries__c> lOZoneCountriesProcessed = new List<RAMD_Orange_Zone_Countries__c>();
        lOZoneCountriesProcessed = [
                SELECT Id, Country_Code__c, Country_Name__c,Processed__c
                FROM RAMD_Orange_Zone_Countries__c
                WHERE Processed__c = false
                AND Active__c = true
        ];
        for (RAMD_Orange_Zone_Countries__c varRAMDOrangeZoneCountries : lOZoneCountriesProcessed) {
            sNewOZoneCountries.add(varRAMDOrangeZoneCountries.Country_Name__c);
        }
        List<RAMD_Processor__c> lRAMDProcessorsToUpdate = new List<RAMD_Processor__c>();

        for (RAMD_Processor__c varRAMDProcessor :lRAMDRecsToProcessors) {
            if (sNewOZoneCountries.contains(varRAMDProcessor.Account_Country__c)
                    || sNewOZoneCountries.contains(varRAMDProcessor.Sales_Primary_Country__c)) {
                varRAMDProcessor.Processing_Status__c = 'Pending';
                varRAMDProcessor.Processing_Reason__c = '';
                varRAMDProcessor.Event_Type__c = 'New OZone Country';
                lRAMDProcessorsToUpdate.add(varRAMDProcessor);
            }

        }

        if (!lRAMDProcessorsToUpdate.isEmpty()) {
            Database.update(lRAMDProcessorsToUpdate, false);
        }
    }

}
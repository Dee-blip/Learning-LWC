/**
 * Created by kusharma on 28/11/17.
 * Modified by Sujay - Added a line at 92 to Sort the list as per FFPSA-408
 */

public with sharing class RAMDPendingRequestProcessorCtrl {
    public String akamAccountId = ApexPages.currentPage().getParameters().get('akamAccountId');
    List<Account> lAccountToShow { get; set; }
    List<Account> lPendingAccounts = new List<Account>();
    List<String> lPendingAkamAccountIds = new List<String>();
    List<RAMD_Processor__c> lRAMDProcessors = new List<RAMD_Processor__c>();
    List<RAMDDataWrapper> lWrappedRecsToDisplay = new List<RAMDDataWrapper>();
    public List<SelectOption> lOZoneCountries {
        get {
            if (lOZoneCountries == null) {
                lOZoneCountries = new List<SelectOption>();
                lOZoneCountries.add(new SelectOption('--None--', '--None--'));
            }
            return lOZoneCountries;
        }
        set;
    }
    public String oZoneCountry { get; set; }
    public String newPendingRecToDisplay { get; set; }
    public List<RAMDDataWrapper> lPendingRecsListToDisplay {
        get {
            if (lPendingRecsListToDisplay == null) {
                lPendingRecsListToDisplay = new List<RAMDDataWrapper>();
            }
            return lPendingRecsListToDisplay;
        }
        set;
    }

    public List<SelectOption> lOZoneReasons {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('--None--', '--None--'));

            Schema.DescribeFieldResult fieldResult = Account.Orange_Zone_Decision_Reason__c.getDescribe();
            List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry varPicklistEntry : picklistEntries) {
                options.add(new SelectOption(varPicklistEntry.getLabel(), varPicklistEntry.getValue()));
            }
            return options;
        }
        set;
    }

    public RAMDDataWrapper currentRecToDisplay { get; set; }
    public String oZoneResponse { get; set; }

    public RAMDPendingRequestProcessorCtrl() {
        System.debug('### ' + akamAccountId);
        getAllPendingRecords();
    }

    public void getAllPendingRecords(){
        lRAMDProcessors.clear();
        lOZoneCountries.clear();
        lAccountToShow = [
                SELECT Id, Orange_Zone__c, OZone_Status__c, Orange_zone_country__c,
                        OZone_validation_override__c, OZone_Validation_Override_Reason__c,
                        Name, AKAM_Account_ID__c,Orange_Zone_Decision_Reason__c, (
                        SELECT Id, Sales_Primary_Country__c, Sales_Primary__r.Name,
                                Event_Type__c,Processing_Reason__c, Account_Country__c,
                                Sales_Primary_Name_Old__c, Sales_Primary_Country_Old__c
                        FROM RAMD_Orange_Zone_processor__r
                )
                FROM Account
                WHERE AKAM_Account_ID__c = :akamAccountId
        ];

        lRAMDProcessors = [
                SELECT Account__c, Account__r.AKAM_Account_ID__c
                FROM RAMD_Processor__c
                WHERE Processing_Status__c = 'Pending'
                ORDER BY LastModifiedDate DESC
                LIMIT 100
        ];
        if (!lAccountToShow.isEmpty()) {
            Account varAccount = lAccountToShow[0];
            lWrappedRecsToDisplay.add(new RAMDDataWrapper(varAccount));
            currentRecToDisplay = new RAMDDataWrapper(varAccount);
            oZoneResponse = '--None--';
        }

        for (RAMD_Orange_Zone_Countries__c varOZoneCountry : [SELECT Id,Country_Name__c FROM RAMD_Orange_Zone_Countries__c]) {
            lOZoneCountries.add(new SelectOption(varOZoneCountry.Country_Name__c, varOZoneCountry.Country_Name__c));
        }
        lOZoneCountries.sort();
        lOZoneCountries.add(0,new SelectOption('--None--', '--None--'));


        System.debug(' ### RAMDPendingRequestProcessorCtrl currentRecToDisplay ' + currentRecToDisplay);
        displayRecsToUser();
    }

    public void displayRecsToUser() {
        lPendingRecsListToDisplay.clear();
        for (RAMD_Processor__c varRAMDProcessor : lRAMDProcessors) {
            lPendingAkamAccountIds.add(varRAMDProcessor.Account__r.AKAM_Account_ID__c);
        }
        lPendingAccounts = [
                SELECT Id, Orange_Zone__c, OZone_Status__c, Orange_zone_country__c,
                        OZone_validation_override__c, OZone_Validation_Override_Reason__c,
                        Orange_Zone_Decision_Reason__c,AKAM_Account_ID__c,Name, (
                        SELECT Id, Sales_Primary_Country__c, Sales_Primary__r.Name,
                                Event_Type__c,Processing_Reason__c, Sales_Primary_Name_Old__c,
                                Sales_Primary_Country_Old__c,Account_Country__c
                        FROM RAMD_Orange_Zone_processor__r
                )
                FROM Account
                WHERE OZone_Status__c IN ('Pending Verification', 'On Hold')
        ];

        for (Account varAccount :lPendingAccounts) {
            lPendingRecsListToDisplay.add(new RAMDDataWrapper(varAccount));
            oZoneResponse = '--None--';
        }
        System.debug('****** RAMDPendingRequestProcessorCtrl lPendingRecsListToDisplay ' + lPendingRecsListToDisplay);
    }

    public Boolean validateRecord(){
        System.debug('### ' + currentRecToDisplay.oZoneResponse + '$#$# ' + currentRecToDisplay.oZoneCountry);
        if (currentRecToDisplay.oZoneResponse =='--None--') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select OZone status for the Account'));
            return false;
        }
        if (currentRecToDisplay.oZoneResponse == 'Yes' && (currentRecToDisplay.oZoneCountry == '--None--' || currentRecToDisplay.accountOZoneReason == '--None--')){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'OZone country and OZone Reason are mandatory for OZone Account'));
            return false;
        }
        if (currentRecToDisplay.oZoneValidationOverride && currentRecToDisplay.oZoneValidationOverrideReason == '') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Validation Override Reason is mandatory for OZone Validation Override'));
            return false;
        }
        return true;
    }

    public void actionSupportCall() {
        System.debug(' #### actionSupportCall ' + newPendingRecToDisplay);
        akamAccountId = newPendingRecToDisplay.trim();
        lAccountToShow.clear();
        lAccountToShow = [
                SELECT Id, Orange_Zone__c, OZone_Status__c, Orange_zone_country__c,
                        OZone_validation_override__c, OZone_Validation_Override_Reason__c,
                        Name, AKAM_Account_ID__c,Orange_Zone_Decision_Reason__c, (
                        SELECT Id, Sales_Primary_Country__c, Sales_Primary__r.Name,
                                Event_Type__c,Processing_Reason__c, Account_Country__c,
                                Sales_Primary_Name_Old__c, Sales_Primary_Country_Old__c
                        FROM RAMD_Orange_Zone_processor__r
                )
                FROM Account
                WHERE AKAM_Account_ID__c = :akamAccountId
        ];
        System.debug(' ###$$$ ' + lAccountToShow);
        if (!lAccountToShow.isEmpty()) {
            Account varAccount = lAccountToShow[0];
            lWrappedRecsToDisplay.add(new RAMDDataWrapper(varAccount));

            currentRecToDisplay = new RAMDDataWrapper(varAccount);
            oZoneResponse = '--None--';
        }
    }

    public void saveAccountRec() {
        if (validateRecord()) {


            Account varAccountToUpdate = new Account();
            varAccountToUpdate.Id = currentRecToDisplay.accountId;
            varAccountToUpdate.Orange_zone_country__c = currentRecToDisplay.oZoneCountry == '--None--' ? '' : currentRecToDisplay.oZoneCountry;
            varAccountToUpdate.Orange_Zone_Decision_Reason__c = currentRecToDisplay.accountOZoneReason == '--None--' ? '' : currentRecToDisplay.accountOZoneReason;
            varAccountToUpdate.Orange_Zone__c = currentRecToDisplay.oZoneResponse == 'Yes' ? true : false;
            varAccountToUpdate.OZone_Status__c = currentRecToDisplay.oZoneResponse == 'Yes' ? 'Orange Zone Account' : 'Not Orange Zone';
            varAccountToUpdate.OZone_validation_override__c = currentRecToDisplay.oZoneValidationOverride;
            System.debug('### oZoneValidationOverride ' + currentRecToDisplay.oZoneValidationOverrideReason);
            varAccountToUpdate.OZone_Validation_Override_Reason__c = currentRecToDisplay.oZoneValidationOverrideReason;
            if (!varAccountToUpdate.Orange_Zone__c && !varAccountToUpdate.OZone_validation_override__c) {
                varAccountToUpdate.Orange_zone_country__c = '';
                varAccountToUpdate.Orange_Zone_Decision_Reason__c ='';

            }
            update varAccountToUpdate;

            RAMD_Processor__c varRAMDProcessor = new RAMD_Processor__c();
            varRAMDProcessor.Id = currentRecToDisplay.ramdProcessorId;
            varRAMDProcessor.Manually_Managed_Account__c = currentRecToDisplay.oZoneValidationOverride;
            update varRAMDProcessor;
            getAllPendingRecords();
            actionSupportCall();

            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Records have been updated successfully'));
        }

    }

    public Class RAMDDataWrapper {
        public String accountId { get; set; }
        public String name { get; set; }
        public String akamAccountId { get; set; }
        public String salesPrimaryName { get; set; }
        public String salesPrimaryCountry { get; set; }
        public String accountCountry { get; set; }
        public String processingReason { get; set; }
        public String oldSalesPrimary { get; set; }
        public String oldSalesPrimaryCountry { get; set; }
        public String accountOZoneStatus { get; set; }
        public String accountOZoneReason { get; set; }
        public Boolean orangeZone { get; set; }
        public Boolean oZoneValidationOverride { get; set; }
        public String oZoneValidationOverrideReason { get; set; }
        public String ramdProcessorId {get;set;}
        public List<SelectOption> lOZoneOpts {
            get {
                lOZoneOpts = new List<SelectOption>{
                        new SelectOption('--None--', '--None--'), new SelectOption('Yes', 'Yes'), new SelectOption('No', 'No')
                }; return lOZoneOpts;
            }
            set;
        }
        public String oZoneCountry { get; set; }
        public String oZoneResponse { get; set; }

        public RAMDPendingRequestProcessorCtrl.RAMDDataWrapper(Account accountRec) {
            System.debug('### '+ accountRec.Id + '$$#$#$# ' + accountRec.RAMD_Orange_Zone_processor__r);
            this.accountId = accountRec.Id;
            this.name = accountRec.Name;
            this.akamAccountId = accountRec.AKAM_Account_ID__c;

            if ( !accountRec.RAMD_Orange_Zone_processor__r.isEmpty()) {
                this.salesPrimaryName = accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary__r.Name == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary__r.Name;
                this.salesPrimaryCountry = accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Country__c == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Country__c;
                this.accountCountry = accountRec.RAMD_Orange_Zone_processor__r[0].Account_Country__c == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Account_Country__c;
                this.processingReason = accountRec.RAMD_Orange_Zone_processor__r[0].Processing_Reason__c == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Processing_Reason__c;
                this.oldSalesPrimary = accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Name_Old__c == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Name_Old__c;
                this.oldSalesPrimaryCountry = accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Country_Old__c == null ? '' : accountRec.RAMD_Orange_Zone_processor__r[0].Sales_Primary_Country_Old__c;
                this.ramdProcessorId = accountRec.RAMD_Orange_Zone_processor__r[0].Id;
            }

            this.accountOZoneStatus = accountRec.OZone_Status__c == null ? '' : accountRec.OZone_Status__c;
            this.accountOZoneReason = accountRec.Orange_Zone_Decision_Reason__c == '--None--' ? '' : accountRec.Orange_Zone_Decision_Reason__c;
            this.orangeZone = accountRec.Orange_Zone__c;
            this.oZoneValidationOverrideReason = accountRec.OZone_Validation_Override_Reason__c;
            this.oZoneValidationOverride = accountRec.OZone_validation_override__c;
            this.oZoneResponse = accountRec.Orange_Zone__c?'Yes':'No';
            this.oZoneCountry = accountRec.Orange_zone_country__c;
        }

    }

}
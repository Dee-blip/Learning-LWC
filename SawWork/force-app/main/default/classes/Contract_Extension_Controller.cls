/***
        Contract_Extension_Controller
        Requirements :
        CR 964875 Project Simple - Create contract extension button
                1. Create a "Extend Contract" button on the Contract detail page and on the related list on the Account detail page
                2. Should allow a user to extend a contract if it is not a revenue or usage commit.
                3. Do the following validation
                        - Contract is Active
                        - Contract is Locked
                        - Effective End Date is greater than Today
                4. Allow user to select an extension date - the date must be greater the Effective End Date
                5. On Submit - do the following :
                        - Create an Opportunity
                        - Create an Order Approval
                        - Submit a request to Momentum for Order Form creation
                        - Provide a link for the user to navigate to the Order Approval that was created.
                6. On Opportunity, update the following values from the Old Contract's associated Opportunity :
                        - CurrencyIsoCode
                        - Order Region
                        - Order Locale
                        - Deal Type
                 7. On Order Approval, update the following values :
                        - SA# = NA
                        - SA Status = Completed

        Implementation Notes :
        - The "Extend Upto" date on the Page is mapped to Opportunity.CloseDate field, bcos there is no inputDate VisualForce component
        - The Momentum Link is stored in a Custom Setting

        History :
        -- Developer            -- Date                         -- Change
        Karteek Kumar M         01/05/2011                      Created the class
        Ali KM                  17/May/2011                     Contract Extension Enhancements & Bug fixes for following CRs:
                                                                - CR 1109955 The default focus should be on 'Submit' button and not 'Return to Contract'
                                                                        --> Fixed on Contract Extension Page.
                                                                        CR 1105131 1Click Extension of term: The SA# for the Order Approval - "OA-86896" has been updated mail trigger to
                                                                        opty owner.
                                                                        --> We are still in the process of determining the logic of SA # generation & update. Thus we wont be stamping
                                                                        the 2 fields (CCG# & CCG Status). Also updated the Email Alert workflow to not send Emails when Current User is same as
                                                                        Opportunity Owner.
                                                                        CR 1105014 1Click Extension of term: Trigger an email when extension of contract fails
                                                                        --> Fixed in Contract Extension Controller class.
                                                                        CR 1100442 1Click Enhancement: Allow the Rep to Enter Region and Locale when extending contracts without oppty
                                                                        --> Added a new mandatory section - 'Order Information' thats rendered when Contract doesn't have an opportunity.
                                                                        CR 1098282 1 Click: Disable Validation on Return to Contract button.
                                                                        --> Fixed in Contract Extension Page.
                                                                        CR 1088616 1Click Enhancement: Notify Rep of recent extension
                                                                        --> Added JS OnClick Button that pops up if there were any Extensions in the past and shows the last requested Date
                                                                        & Status = In-Progress/Failed/Successful
        Ali KM                  23/May/2011                     CR 1113555 1Click Extension: User friend error message
                                                                - Added following logic to handle Extensions for Indirect Opptys with missing Partner Involved
                                                                        -> Do Not allow extension of Contracts that have Oppty Deal Type = Indirect & PartnerInvolved = null
                                                                        -> For extension of Contracts without associated Opportunity
                                                                            - Check if Contract.Contract__Type__c equals 'Indirect Customer', if yes then check if Contract.Parent_Account_Name__c is not null
                                                                            - If above condition satisfies, set following values for Oppty fields.
                                                                                -> Deal Type = Indirect
                                                                                -> Partner Involved = Contract.Parent_Account_Name__c
                                                                            - Also, set Oppty.Validation Override = true; so that any other errors (especially - missing Channel Manager) are not thrown.
        Ali KM                  23/May/2011                     CR 1118244 1Click Contract Extension - SA # auto update requirements.
                                                                    - Now stamping CCG (SA) details based on following:
                                                                        SA Owner¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬† : SA Queue
                                                                        SA Approved Date¬†¬†¬†¬†¬†¬†¬† : <Current Date>
                                                                        SA Status¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬† : Completed
                                                                        SA Approval Notes¬†¬†¬†¬†¬†¬† : Contract Extension - Auto Approved
                                                                        SA #            : ED – Auto Approval (Direct Deals)
                                                                                          EI – Auto Approval (Indirect Deals)
                                                                                          E0 – Auto Approval (Other Deals)
        Ali KM                  03/Jun/2011                     CR 1142794 Need to have validation check on number of characters for Contract title field
                                                                    - In Momentum, Order Form Name = Opportunity Name for Contract Extensions. The Max length is set to 80 Characters as attachment naming length with
                                                                    extension = 80 characters.
                                                                    -Added maxLength attribute for 'Contract title' VF  text field.
                                                                    -Added code to truncate opp.Name if > 75 characters
                                                                    -Changed the Contract Extension Opportunity Naming convention. Examples:
                                                                        ->Before: Contract Extension :3-2EXJJA-2011-06-30-Zynga Akamai Contract Extension - 6.30.11
                                                                        ->Now: CE:3-2EXJJA-Zynga Akamai Contract Extension - 6.30.11
        Ali KM                  14/Jun/2011                     CR 1130536 Implementation 1-click deferment of b.e.d
                                                                    - Added logic to handle BED & CE in this controller
                                                                CR 1127746 1Click Extension of term - Issue with currency
                                                                    - Added logic to map Oppty.CurrencyISO to Contract.Currency__c field if Opportunity is not associated and if its unavailable user is requested to
        Ali KM                  20/Jun/2011                     CR 1127746 1Click Extension of term - Issue with currency
                                                                    - Reverting the Logic that stamps new Oppty.CurrencyISO with Contract.Currency__c ; instead user will need to enter this field manually on
                                                                    Contract Extension/BED Deferment screen.
        Ali KM                  08/Jul/2011                     CR 1195789 Internal - Adding Order Approval Lookups on Contracts: for BED/CE reporting purposes
                                                                    - Added 2 new Order Approval Lookup fields on Contracts:
                                                                    - Updating the Lookup from code once CE or BEDD request is made.
        Ali KM                  25/Jul/2011                     CR 1127746 1Click Extension of term - Issue with currency
                                                                    - Instead of copying the region/locale/currency from associated Opportunity to
                                                                        new CE/BEDD oppty directly (with no option for user to intervene); we will
                                                                        pre-populate these fields with associated Oppty's region/locale/currency and
                                                                        also make them editable on CE/BEDD screen. This way user will have an option to
                                                                        change the values as needed.
        Ali KM                  09/Jan/2012                     CR 1481959 Few Click Enhancement - Capture AOO validation errors in SF.com
                                                                    - Added validation to ensure Contract.Currency__c is not null
                                                                    - Populating the new extension Opportunity.CurrencyISO = Contract.Currency__c
                                                                    - Made Currency__c as 'READ ONLY' for the user.
        Ali KM                  20/Feb/2012                     CR 1541341 Few Click: Change 'Contract expiration check' to 1 day before Effective End Date
                                                                    - Changed 'Billing Effective Date' validation to consider a contract as expired if billing effective date <= today.
                                                                      Previously it would consider a contract as expired only if billing effective date < today.
        Ali KM                  05/Jul/2012                     CR 1766000 BED and Contract Ext. Automation Update Request
                                                                    - SA # on Oppty is not synced with OA.SA # due to FirstRunFlag on SA being set to False.
                                                                    In-order to re-run the update am resetting the FirstRunFlag to true.
        Ali KM                  27/Sep/2012                     CR 1886230 - Flex requirement in SFDC to allow users to enter Extension of Term orders until 1 day
                                                                after expiry (i.e. GMT+12 Hrs)
                                                                    - Updated the Validation check for Contract expirty to allow users to request for AOO until 1 day after the
                                                                    Effective End Date. i.e. if Effective End Date = 2012-09-26, users can request AOO until end of 2012-09-27 in
                                                                    their timezone (India/UK/US).
        Ali KM                  30/Nov/2012                     CR 1970038 - AOO - add a button 'View Opportunity' on few click submit screen.
                                                                    - Added a new button 'View Opportunity' thats  rendered once user Submits the BEDD/Contract Extension request.

        Ali KM                  8/May/2013                      CR 2211491 - FewClicks : Contract Extension of Indirect Customers is generating wrong format OF.
                                                                - For Indirect Extension there is a bug, we should be looking at ContractHeader.ParentAccountName.PartnerType (PartnerInvolved.PartnerType)
                                                                    and not ContractHeader.Account.PartnerType.

        Poojashri Rao           29/May/2013                     CR 2233046 - One click extension:: Getting error in SF during contract extension of Tier1 reseller contract
                                                                - Extension of Tier 1 Reseller and Var Contracts should be allowed, even though no partners are Involved.
                                                                - The GsmCustomSetting "Contract_Extension#AllwdContractTypes" holds all such Contract Types which are extendable without partners.


        Poojashri Rao          20/Jun/2013                      CR 2265482 : Issues in 1-click extension of term feature
                                                                - Deal Type of the new Opportunity created ater Extension should always be derived from the Contract Type of the original Contract irrespective of the opportunity Involved.
                                                                i.e Henceforth only for "Indirect Customer" Contract types , the Deal Type of The new Opportunity is set to Indirect.


*/

global class Contract_Extension_Controller
{
    public Merge_Contract_Header__c contractHeader {get; set;}

    public Boolean initializeFlag {get; set;}
    public Boolean contractCurrencyEmptyFlag {get; set;}
    public Boolean missingOpptyInfoFlag {get; set;}
    public Boolean contractAlreadyExtended {get; set;}
    public Boolean isContractExtensionRequest {get; set;}
    public Boolean isBEDDefermentRequest {get; set;}
    public Boolean isMissingOpptyCurrency {get; set;}
    public Boolean extendedFlag {get; set;}
    public String momentumLink {get; set;}
    public String title {get;set;}
    public String extendedEndDate {get; set;}
    public String automationRequestType {get; set;}

    public Opportunity opp {get; set;}
    public Order_Approval__c oa {get; set;}

    public String pageTitle {get; set;}
    public String addendumType {get; set;}
    public String deferToDate {get; set;}
    public String strErrMsg {get; set;}
    //public String opptyContractOnlyRecTypeName;
    public String OrderRegionAsPerAcc {get; set;}
    public String OrderRegionAsPerAccOriginalVal;
    
    /**
        Contract_Extension_Controller()
        - Constructor for the controller
        - Initialize the Contract Header record
    */


    public void SetErrorMsg(String key)
    {

        initializeFlag =  false;
        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getGSMSettingValue(key)); // SFDC-2705 Custom Settings Migration
        ApexPages.addMessage(errMsg);

    }

    public Contract_Extension_Controller()
    {
        // initialize flags
        pageTitle = 'Automation Request';
        addendumType = 'extension_of_term';
        isBEDDefermentRequest = false;
        isContractExtensionRequest = false;
        //contractAlreadyExtended = false;
        isMissingOpptyCurrency = false;
        missingOpptyInfoFlag = false;
        initializeFlag = true;
        contractCurrencyEmptyFlag = false;
        //opptyContractOnlyRecTypeName = GsmUtilClass.GetCustomSettingValue('BatchableUpdateContract', 'RecTypeName');
        momentumLink = GsmUtilClass.getGSMSettingValue('Contract_Extension_MomentumLink'); // SFDC-2705 Custom Settings Migration
        automationRequestType = ApexPages.currentPage().getParameters().get('requestType');
        System.debug('requestType=' + automationRequestType);
        for(Merge_Contract_Header__c ch:[select Id,
                                                Name,
                                                Original_Contract_Id__c,
                                                Active__c,
                                                Locked__c,
                                                Effective_End_Date__c ,
                                                Effective_Start_Date__c,
                                                Account_Name__c,
                                                Account_Name__r.Partner_Type__c,
                                                Contract_Type__c,
                                                Currency__c,
                                                Parent_Account_Name__c,
                                                Parent_Account_Name__r.Partner_Type__c,
                                                Opportunity_Name__c,
                                                Opportunity_Name__r.AccountId,
                                                Opportunity_Name__r.Validation_Override__c,
                                                Opportunity_Name__r.RecordTypeId,
                                                Opportunity_Name__r.CurrencyIsoCode,
                                                Opportunity_Name__r.Deal_Type__c,
                                                Opportunity_Name__r.Order_Locale__c,
                                                Opportunity_Name__r.Order_Region__c,
                                                Opportunity_Name__r.Partner_Involved__c,
                                                CurrencyIsoCode,
                                                ContractExtension_OA_Id__c,
                                                BEDDeferment_OA_Id__c
                                         from Merge_Contract_Header__c
                                         where Id = :ApexPages.currentPage().getParameters().get('id')])
            contractHeader = ch;

        if ( automationRequestType == null || ( !automationRequestType.equalsIgnoreCase('CE') && !automationRequestType.equalsIgnoreCase('BEDD') ) )
        {
            //System.debug('requestType=' + automationRequestType);
            SetErrorMsg('Contract_Extension_Error_MissingType'); // SFDC-2705 Custom Settings Migration
            return;
        }
        else
        {
            // Decide Action based on requestType, CE -> Contract Extension OR BEDD -> Billing Effective Date Deferment
            if(automationRequestType.equalsIgnoreCase('CE'))
            {
                isContractExtensionRequest = true;
                pageTitle = GsmUtilClass.getGSMSettingValue('Contract_Extension_pageTitle'); // SFDC-2705 Custom Settings Migration
                //addendumType = 'extension_of_term';
            }
            else if (automationRequestType.equalsIgnoreCase('BEDD'))
            {
                isBEDDefermentRequest = true;
                pageTitle = GsmUtilClass.getGSMSettingValue('Contract_Extension_BED_pageTitle'); // SFDC-2705 Custom Settings Migration
                addendumType = 'deferment_of_billing_effective_date';
            }
        }
        if(contractHeader == null)
        {
            SetErrorMsg('Contract_Extension_Error_ContractId'); // SFDC-2705 Custom Settings Migration
            return;
        }
        if(!contractHeader.Active__c)
        {
            if (isBEDDefermentRequest)
                SetErrorMsg('Contract_Extension_BED_errInactive'); // SFDC-2705 Custom Settings Migration
            else //if (isContractExtensionRequest)
                SetErrorMsg('Contract_Extension_Error_Inactive'); // SFDC-2705 Custom Settings Migration
            return;
        }
        if(!contractHeader.Locked__c)
        {
            if (isBEDDefermentRequest)
                SetErrorMsg('Contract_Extension_BED_errUnlocked'); // SFDC-2705 Custom Settings Migration
            else //if (isContractExtensionRequest)
                SetErrorMsg('Contract_Extension_Error_Unlocked'); // SFDC-2705 Custom Settings Migration
          return;
        }
        if(contractHeader.Effective_End_Date__c < Date.today().addDays(-1*Integer.valueOf(GsmUtilClass.getGSMSettingValue('Contract_Extension_ExpiryGraceDays')))) // SFDC-2705 Custom Settings Migration
        {
            SetErrorMsg('Contract_Extension_Error_Expired'); // SFDC-2705 Custom Settings Migration
            return;
        }
        if(contractHeader.Effective_End_Date__c == null)
        {

            if (isBEDDefermentRequest)
                SetErrorMsg('Contract_Extension_BED_errEffectDt'); // SFDC-2705 Custom Settings Migration
            else //if (isContractExtensionRequest)
                SetErrorMsg('Contract_Extension_Error_EffectiveDt'); // SFDC-2705 Custom Settings Migration

            return;
        }
        if (contractHeader.Currency__c==null)
        {
            initializeFlag = false;
            contractCurrencyEmptyFlag = true;
            if (isBEDDefermentRequest)
                strErrMsg = GsmUtilClass.getGSMSettingValue('Contract_Extension_BED_EmptyCurncy'); // SFDC-2705 Custom Settings Migration //'Contract cannot be extended: Contract Currency is empty.';
            else //if (isContractExtensionRequest) Contract_Extension#BED#errEmptyCurncy
                strErrMsg = GsmUtilClass.getGSMSettingValue('Contract_Extension_Error_EmptyCurncy'); // SFDC-2705 Custom Settings Migration //Billing Effective Date cannot be deferred: Contract Currency is empty.'; // modified by Chandra to remove extra #
            /*
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, strErrMsg);
            ApexPages.addMessage(errMsg);
            */
            return;
        }
        if(contractHeader.Opportunity_Name__c == null || String.valueOf(contractHeader.Opportunity_Name__c).equals('')) { // SFDC-2705 impacts bug SFDC-2744
                        if (isBEDDefermentRequest) {
                                SetErrorMsg('Contract_Extension_NoOpportunityBED');
                        }
                        else { //if (isContractExtensionRequest)
                                SetErrorMsg('Contract_Extension_NoOpportunityCER');
                        }
                        return;
        }
        if(contractHeader.Opportunity_Name__r.Deal_Type__c !=null && contractHeader.Opportunity_Name__r.Deal_Type__c != 'Direct' && contractHeader.Opportunity_Name__r.Partner_Involved__c == null && !(GsmUtilClass.getGSMSettingValue('Contract_Extension_AllwdContractTypes').split(',')).contains(contractHeader.Contract_Type__c))// SFDC-2705 Custom Settings Migration //porao:allowing tier1 resellers, var customers to go through without partners.
        {

            if (isBEDDefermentRequest)
                SetErrorMsg('Contract_Extension_BED_errIndirect'); // SFDC-2705 Custom Settings Migration
            else //if (isContractExtensionRequest)
                SetErrorMsg('Contract_Extension_Error_Indirect'); // SFDC-2705 Custom Settings Migration

            return;
        }

        // Create a new Opportunity
        opp = new Opportunity();

        String strPartnerInvolvedContractType = GsmUtilClass.getGSMSettingValue('Contract_Extension_ContractType'); // SFDC-2705 Custom Settings Migration

        // porao : CR 2265482
          if (contractHeader.Contract_Type__c!=null && strPartnerInvolvedContractType.contains(contractHeader.Contract_Type__c))
                    opp.Deal_Type__c = 'Indirect';

        else

                    opp.Deal_Type__c = 'Direct';  //porao: CR 2233046
        // Changes made for CR 1100442
        //CR 1100442 1Click Enhancement: Allow the Rep to Enter Region and Locale when extending contracts without oppty
        if(contractHeader.Opportunity_Name__c == null)
            //|| contractHeader.Opportunity_Name__r.RecordTypeId == Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opptyContractOnlyRecTypeName).getRecordTypeId())
            {
                // set missingOpptyFlag to true
                missingOpptyInfoFlag = true;

                //set the Partner Involved logic for Indirect Deal Types.
                // Ensure that Partner Involved.Partner Type is not empty.

              if (contractHeader.Parent_Account_Name__c!=null && contractHeader.Parent_Account_Name__r.Partner_Type__c!=null)

                opp.Partner_Involved__c = contractHeader.Parent_Account_Name__c;

                // Default Order Region/Locale to --none--
                opp.Order_Locale__c = '';
                //opp.Order_Region__c = '';
            }
        // Changes made for CR 1100442  -- end --
        else
        {
            opp.Order_Locale__c = contractHeader.Opportunity_Name__r.Order_Locale__c;
            //opp.Order_Region__c = contractHeader.Opportunity_Name__r.Order_Region__c;
            //opp.CurrencyIsoCode = contractHeader.Opportunity_Name__r.CurrencyIsoCode;
        }
        List<Opportunity> oppList = new List<Opportunity>();
        if (contractHeader.Opportunity_Name__c != null && !String.valueOf(contractHeader.Opportunity_Name__c).equals('')) { // SFDC-2705 imacting bug - SFDC-2744 
          oppList.add(contractHeader.Opportunity_Name__r);          
        }
        Map<String,String> emptyMap = new Map<String,String>();
        if(oppList.size() > 0) {
          OrderRegionAsPerAcc = OpportunityTriggerClass.updateOrderRegion(oppList,emptyMap).orderRegionValue; // SFDC-2705 imacting bug - SFDC-2744         
          opp.Order_Region__c = OrderRegionAsPerAcc;
          OrderRegionAsPerAccOriginalVal = OrderRegionAsPerAcc;
        }
    }

    /**
        submit()
        - Create the Opportunity
        - Create the Order Approval
        - Toggle the extended flag to intiate Momentum GET Request
    */
    public PageReference submit()
    {
        if(isBEDDefermentRequest && opp.CloseDate == null)
        {
            String errMessage;
            //if (isContractExtensionRequest)
            //  errMessage = GetCustomSettingValue('Error-BadDate');
            //else if (isBEDDefermentRequest)
                SetErrorMsg('Contract_Extension_BED_ErBadDate'); // SFDC-2705 Custom Settings Migration


            return null;
        }

        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(contractHeader.Opportunity_Name__r);
        Map<String,String> oppIdRelaredOrderRegionMap = new Map<String,String>();
        System.debug('Updated order region : '+opp.Order_Region__c);
        oppIdRelaredOrderRegionMap.put(contractHeader.Opportunity_Name__c, opp.Order_Region__c);
        Boolean validationToFireForAllignment = OpportunityTriggerClass.updateOrderRegion(oppList,oppIdRelaredOrderRegionMap).validationFiresForContract;

        if (validationToFireForAllignment) {
            String errMessage = GSMUtilClass.getGSMSettingValue('AccFinanceRegionCheck_ValidationMessage');
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errMessage);
            ApexPages.addMessage(errMsg);
            return null;
        }

        // The "Extend Upto" date must be greater than the old Contract's Effective End Date
        if(isContractExtensionRequest && (opp.CloseDate == null || opp.CloseDate <= contractHeader.Effective_End_Date__c))
        {
            SetErrorMsg('Contract_Extension_Error_BadDate'); // SFDC-2705 Custom Settings Migration
            return null;
        }

        // Convert the Date into YYYY-MM-DD
        if (isBEDDefermentRequest)
            deferToDate = ReturnFormattedDateString(opp.CloseDate, GsmUtilClass.getGSMSettingValue('Contract_Extension_DateFormat') ); // SFDC-2705 Custom Settings Migration
        else //if(isContractExtensionRequest)
            extendedEndDate = ReturnFormattedDateString(opp.CloseDate, GsmUtilClass.getGSMSettingValue('Contract_Extension_DateFormat') ); // SFDC-2705 Custom Settings Migration

        // Populate the Opportunity Details
        if(isBEDDefermentRequest)
        {
            opp.Name = 'BEDD:' + contractHeader.Original_Contract_Id__c + '-' + title;
            opp.Bed_Change__c = true;
        }
        else // if Contract Extension
        {
            opp.Name = 'CE:' + contractHeader.Original_Contract_Id__c + '-' + title;
            opp.Contract_Extension__c = true;
        }

        if (opp.Name.length() > 75)
        {
            //Ex: CE:3-2EXJJA-Zynga Akamai Contract Extension - 6.30.11
            String strOpptyName = opp.Name;
            opp.Name = strOpptyName.substring(0,75);
            System.assertEquals(75, opp.Name.length());
            //System.debug('Updated Oppty Name=' + opp.Name);
        }
        opp.CloseDate = Date.today().addDays(10);
        opp.StageName = '1. Identify Need'; //SFDC-3539
        opp.AccountId = contractHeader.Account_Name__c;
        opp.CurrencyIsoCode = contractHeader.Currency__c;
        // Changes for CR 1100442 1Click Enhancement: Allow the Rep to Enter Region and Locale when extending contracts without oppty -- start --

        if (!missingOpptyInfoFlag)
        {
            //opp.Deal_Type__c = contractHeader.Opportunity_Name__r.Deal_Type__c;
            opp.Partner_Involved__c = contractHeader.Opportunity_Name__r.Partner_Involved__c;
            //opp.Order_Locale__c = contractHeader.Opportunity_Name__r.Order_Locale__c;
            //opp.Order_Region__c = contractHeader.Opportunity_Name__r.Order_Region__c;
            //opp.CurrencyIsoCode = contractHeader.Opportunity_Name__r.CurrencyIsoCode;
        }
        //  -- end --

        // set Validation override=true to bypass Missing Channel Manager validation rule
        opp.Validation_Override__c = true;
        opp.Opportunity_Type__c = 'Contract Change';
        try
        {
            insert opp;
        }
        catch (Dmlexception dmlEx )
        {
            String strDMLException = dmlEx.getDmlMessage(0);
            if (dmlEx.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
            {
                //strExceptionMessage =  getCustomSettingsValue('PartInvolErrMsg');
                //if (strDMLException.contains('Partner Involved is mandatory'))
                if (strDMLException.contains('Partner_Involved__c'))
                {
                    if (isBEDDefermentRequest)
                        SetErrorMsg('Contract_Extension_BED_errIndirect'); // SFDC-2705 Custom Settings Migration
                    else //if (isContractExtensionRequest)
                        SetErrorMsg('Contract_Extension_Error_Indirect'); // SFDC-2705 Custom Settings Migration
                         return null;
                }
            }
            else
                throw new CustomException( dmlEx );
        }

        // Populate the Order Approval Details
        //OrderApprovalClass.Create_OrderApproval(opp.Id, opp.RecordTypeId, opp.StageName, '');

        // Since we have 2 operations on OA in same transaction and in-order to sync the SA # over to Oppty resetting the UpdateOpptyFirstRunFlag to true.
        //OrderApprovalClass.UpdateOpptyFirstRunFlag = true;

        oa = [select Id,
                     Contract_Extension_Original_Contract_Id__c,
                     Associated_Opportunity__r.AKAM_Opportunity_Id__c,
                     Associated_Opportunity__r.Deal_Type__c,
                     Automation_Request_Type__c,
                     CCG__c,
                     CCG_Status__c
              from Order_Approval__c
              where Associated_Opportunity__c = :opp.Id];
        oa.Contract_Extension_Original_Contract_Id__c = contractHeader.Original_Contract_Id__c;

        /*
        // Setting SA (CCG) fields for BED deferment
        SA Owner                : SA Queue
        SA Approved Date        : <Current Date>
        SA Status               : Completed
        SA Approval Notes       : Deferment of billing effective date - Auto Approved
        SA #                    : DBEDD – Auto Approval (Direct Deals)
                                  DBEDI – Auto Approval (Indirect Deals)
                                  DBED0 – Auto Approval (Other Deals)
        // Setting SA (CCG) fields for Contract Extension.
        SA Owner¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬† : SA Queue
        SA Approved Date¬†¬†¬†¬†¬†¬†¬† : <Current Date>
        SA Status¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬†¬† : Completed
        SA Approval Notes¬†¬†¬†¬†¬†¬† : Contract Extension - Auto Approved
        SA #                    : ED – Auto Approval (Direct Deals)
                                  EI – Auto Approval (Indirect Deals)
                                  E0 – Auto Approval (Other Deals)
        */
        /*
        //SFDC-4178
        if (isBEDDefermentRequest)
        {
            oa.Automation_Request_Type__c = automationRequestType;
            if (opp.Deal_Type__c != null && (opp.Deal_Type__c == 'Indirect' || opp.Deal_Type__c == 'Direct'))
            {
                if (opp.Deal_Type__c == 'Indirect')
                    oa.CCG__c = 'DBEDI – Auto Approval';
                else if (opp.Deal_Type__c == 'Direct')
                    oa.CCG__c = 'DBEDD – Auto Approval';
            }
            else
                oa.CCG__c = 'DBED0 – Auto Approval';

            oa.CCG_Approval_Notes__c = 'Deferment of billing effective date - Auto Approved';
        }
        else
        {
            oa.Automation_Request_Type__c = automationRequestType;
            if (opp.Deal_Type__c != null && (opp.Deal_Type__c == 'Indirect' || opp.Deal_Type__c == 'Direct'))
            {
                if (opp.Deal_Type__c == 'Indirect')
                    oa.CCG__c = 'EI – Auto Approval';
                else if (opp.Deal_Type__c == 'Direct')
                    oa.CCG__c = 'ED – Auto Approval';
            }
            else
                oa.CCG__c = 'E0 – Auto Approval';

            oa.CCG_Approval_Notes__c = 'Contract Extension - Auto Approved';
        }
        */
        oa.Automation_Request_Type__c = automationRequestType;
        //oa.CCG_Status__c = 'In Progress';
        //oa.CCG_Approved_Date__c = DateTime.now();
        // --- end ---

        // Added following lines as part of CR 1105014
        oa.ContractExtension_OrderFormUploadCheck__c = Datetime.now().addMinutes(Integer.valueOf(GsmUtilClass.getGSMSettingValue('Contract_Extension_WaitingMinutes')));
        // set Validation override=true to bypass validation rules
        oa.Validation_Override__c = true;
        //oa.Times_Reviewed__c = '0';
        update oa;

        // Changes for CR 1088616 1Click Enhancement: Notify Rep of recent extension -- start ---
        //update the contractheader with oa details.
        if (isBEDDefermentRequest)
        {
            contractHeader.BEDDeferment_OA_Id__c = oa.Id;
            contractHeader.B_E_D_Deferment_Order_Approval__c = oa.Id;
        }
        else
        {
            contractHeader.ContractExtension_OA_Id__c = oa.Id;
            contractHeader.Contract_Extension_Order_Approval__c = oa.Id;
        }
        // Changes for CR 1088616 1Click Enhancement: Notify Rep of recent extension -- end ---
        update contractHeader;

        // Flip the extendedFlag, this will make the page submit a GET request to Momentum
        extendedFlag = true;
        //ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.INFO, GetCustomSettingValue('SuccessMessage'));
        //ApexPages.addMessage(errMsg);

        return null;
    }
    /**
        ReturnFormattedDateString(Date pDate, String pFormat)
        - Converted the DATE to the required Format
        - Momentum needs the format in YYYY-MM-DD
    */
    public static String ReturnFormattedDateString(Date pDate, String pFormat)
    {
        String dateString = pFormat;

        Integer i_year = pDate.year();
        Integer i_month = pDate.month();
        Integer i_day = pDate.day();

        String str_year = i_year + '';
        String str_month = i_month + '';
        String str_day = i_day + '';

        if(i_month < 10)
            str_month = '0' + str_month;
        if(i_day < 10)
            str_day = '0' + str_day;

        dateString = dateString.replaceAll('MM', str_month);
        dateString = dateString.replaceAll('DD', str_day);
        dateString = dateString.replaceAll('YYYY', str_year);

        return dateString;
    }
    /**
        cancel()
        - Button to redirect the user to the Contract Header record
    */
    public PageReference cancel()
    {
        return new PageReference('/' + contractHeader.Id);
    }
    /**
        viewOA()
        - Button to redirect the user to the newly created Order Approval
    */
    public PageReference viewOA()
    {
        if(oa == null)
            return null;
        return new PageReference('/' + oa.Id);
    }

    /**
        viewOppty()
        - Button to redirect the user to the newly created Opportunity
    */
    public PageReference viewOppty()
    {
        if(opp == null)
            return null;
        return new PageReference('/' + opp.Id);
    }
    
        public static String getErrorMessage() {
        String errorMessage;
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Not A Valid Contract';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Please validate if all required Fields are present';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Opportunity';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Account';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate pageReference';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        
        return errorMessage;
    }
    
    

    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static testmethod void unitTest()
    //{
    //    /*Account newAccount = new Account();
    //    newAccount.Name = '_TEST_ Account 12';
    //    newAccount.BillingCountry = 'India';*/
    //    Account newAccount = utilTestClass.CreateAccount('_TEST_ Account 12');
    //    insert newAccount;

    //    Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
    //    contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
    //    contractHeader.Name = '_TEST CONTRACT _ 12';
    //    contractHeader.Account_Name__c = newAccount.Id;
    //    contractHeader.Active__c = true;
    //    contractHeader.Locked__c = true;
    //    contractHeader.Effective_End_Date__c = Date.today();
    //    insert contractHeader;

    //    PageReference extendPage = Page.Contract_Extension;
    //    Test.setCurrentPageReference(extendPage);
    //    extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
    //    extendPage.getParameters().put('requestType', 'ce');
    //    //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
    //    //Apexpages.currentPage().getParameters().put('requestType', 'ce');
    //    Contract_Extension_Controller controller = new Contract_Extension_Controller();
    //    //controller.automationRequestType = 'ce';
    //    // Extension date
    //    if(controller.opp!=null)  // modified by chandra to handle null pointer exception

    //    {controller.opp.CloseDate = Date.today().addDays(30);

    //    controller.submit();
    //    controller.cancel();
    //    controller.viewOA();}
    //}
}
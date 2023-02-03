public class OpportunityGetBaseline {

    public Opportunity opp;
    public String oppId{get;set;}
    public String currencyCode;
    //SFDC-1395
    //public static Boolean currencyMismatch {get; set;}
    public Boolean showError {get;set;}
    public static Boolean isRunning= true;
    public Boolean hideGetBaselineButton {get;private set;}
    public List<Merge_Contract_Header__c> setOfSelectedContracts{get;set;}
    public Set<String> contractCurrencySet ;




    public OpportunityGetBaseline(ApexPages.StandardController controller){

        oppId                   = ApexPages.currentPage().getParameters().get('opportunityID');
        currencyCode            = ApexPages.currentPage().getParameters().get('currencyCode');
        if(oppId != null && !String.isBlank(oppId)) {
            oppId = String.escapeSingleQuotes(oppId.escapeHtml4());
        }
        if(currencyCode != null && !String.isBlank(currencyCode)) {
            currencyCode = String.escapeSingleQuotes(currencyCode.escapeHtml4());
        }
        hideGetBaselineButton   = true;
        //SFDC-1395
        //currencyMismatch        = false;
        showError               = false;
        execute();

    }
    // SFDC-1394
    public void execute()
    {
        if(OpportunityUtilClass.isClosed(oppId))
        {
            showError = true;
            Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR, Label.Opportunity_is_in_Closed_Stage));

        }
        /*
         if(OpportunityUtilClass.hasAssociatedRenewalContract(oppId))
         {
            showError = true;
            Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR,GsmUtilClass.getErrorPageSettingValue('ContractAlreadyAssociated')));      

         }
         */

        

    }

    //Method called on Select of any input checkbox for the contract
    public PageReference inputCheckForGetBaseline(){

        setOfSelectedContracts = new List<Merge_Contract_Header__c>();
        contractCurrencySet = new Set<String>();
        System.debug('cwlist:'+OpportunityCreateNew.cwList);
        if(OpportunityCreateNew.cwList.size() >0)
        {
            for(OpportunityCreateNew.ContractWrapper cw: OpportunityCreateNew.cwList )
            {
                if(cw.Checkbox)
                {
                    //SFDC-1395
                    //currencyMismatch = !cw.mch.Currency__c.equalsIgnoreCase(currencyCode);
                    setOfSelectedContracts.add(cw.mch);
                    contractCurrencySet.add(cw.mch.Currency__c);
                }

            }
            // SFDC-1394
            /*if(setOfSelectedContracts.size()>0)
            {
                System.debug('setOfSelectedContracts' +setOfSelectedContracts);
                String firstCurrency = setOfSelectedContracts[0].Currency__c;
                 for(Merge_Contract_Header__c mch : setOfSelectedContracts)
                {
                    if(!firstCurrency.equalsIgnoreCase(mch.Currency__c))
                        Apexpages.addMessage(new ApexPages.Message (ApexPages.Severity.ERROR, 'All selected contracts must be of the same currency.'));
                }


            }*/
           
            //SFDC-1395
            System.debug('contractCurrencySet:'+setOfSelectedContracts);
            hideGetBaselineButton = (setOfSelectedContracts.size() == 0 || ApexPages.hasMessages())? True: False ; 
        }

        return null;
    }
    //Method called on getBaseline. Update the Opporunity for Currency or Renew Contract Id and call getBaseline method to fetch the baseline from Contract
    // SFDC-1394
    public PageReference getBaseline(){

        GsmUtilClass.disableLossReasonValidation= false; //SFDC-8121

        List<String> listOfOriginalContractIds = new List<String>();
        List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();

        for(Merge_Contract_Header__c mch : setOfSelectedContracts)
        {          
            listOfOriginalContractIds.add(mch.Original_Contract_Id__c);
        }

        CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(listOfOriginalContractIds);
        roc.setOpportunityCurrency(currencyCode);

        roc.setContractCurrency(contractCurrencySet);
        //roc.setContractCurrency(setOfSelectedContracts[0].Currency__c);
        String closeDateFromParameter = Apexpages.currentPage().getParameters().get('closeDate');
        if(closeDateFromParameter != null && !String.isBlank(closeDateFromParameter)) {
            closeDateFromParameter = String.escapeSingleQuotes(closeDateFromParameter.escapeHtml4());
        }
        Date opptyCloseDate = Date.parse(closeDateFromParameter);
        roc.setOpportunityCloseDate(opptyCloseDate);
        String contractName = roc.buildContractName();
        
        Opportunity opptyRecord = new Opportunity(Id = oppId, Opportunity_Type__c = 'Renewal', Validation_Override__c = true, Renew_Contract_Id_Text__c=contractName);
        
        DMLResults results = new DMLResults(true);
        results.clear();
        results.dmlUpdate(new List<Opportunity>{opptyRecord});
        results.withClassName('OpportunityGetBaseline').insertRecordsInErrorLog();
        if(results.failureCount>0)
        {
            showError = true;
            Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while updating the opportunity.'));
        }

        opptyLineItemList = roc.createOpportunityProducts(Id.valueOf(oppId));

        for(OpportunityLineItem newOLi :opptyLineItemList) 
        {
            if(newOli.UnitPrice == null)
                newOli.UnitPrice= 0.00;
        } 


        if(opptyLineItemList.size()>0 && !showError)
        {
            results.clear();
            results.dmlInsert(opptyLineItemList);
            results.withClassName('OpportunityGetBaseline').insertRecordsInErrorLog();
            if(results.failureCount>0)
            {
                showError = true;
                Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while inserting the opportunity products.'));
            }
        }

        if(!showError)
        {
            roc.createRenewalContractObjects(Id.valueOf(oppId));
            if(roc.errorOccured)
            {
                showError = true;
                Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while inserting the associated contracts.'));
            }
        }

        System.debug(LoggingLevel.ERROR, showError);

        if(!showError)
        {
            showError = true;
            Apexpages.addmessage(new Apexpages.Message(Apexpages.Severity.CONFIRM,'Opportunity get baseline successfully completed.'));
        }

        return null;
    }


}
global class SalesApprovedCountryBatchClass extends GenericBatchClass
{

     global List<Sales_Approved_Country__c> sacList = new List<Sales_Approved_Country__c>();
     global string IsleManfields = GSMUtilClass.getGSMSettingValue('Isle_of_Man_Field_Check').replaceAll(' ', '');


     global SalesApprovedCountryBatchClass()
     {
         super();
         Set<String> setOfCountries=new Set<String>();
         for(Sales_Approved_Country__c sac : [Select Name, Has_Changed__c from Sales_Approved_Country__c where Has_Changed__c=true])
         {
             setOfCountries.add(sac.Name);
             sacList.add(sac);
         }
         query = 'select Id, Name, Is_Restricted_Country__c, Sales_Approval_Status__c, Validation_Override__c, BillingCountry, ShippingCountry,' + IsleManfields + ' from Account where BillingCountry in '+Util.inClausify(setOfCountries) + ' or ShippingCountry in '+Util.inClausify(setOfCountries);
         className = 'SalesApprovedCountryBatchClass';
         errorAddressCustomSetting = 'SalesApprovedCountryBatch_EmailId';
     }

    
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Account> listOfAccountsQueried= (List<Account>)scope;
        List<Account> listOfAccountsToBeUpdated = new List<Account>();
        Map<String, Sales_Approved_Country__c> countryToSac = new Map<String, Sales_Approved_Country__c>();
        //SV - Changing below list to set and renaming variable allAccountsBillingCountry to allAccountsCountry to accomodate ShippingCountry
        Set<String> allAccountsCountry = new Set<String>();
        List<Account> listOfAccountsWithBillingOrShippingCountry = new List<Account>();
        list<string> isleofManCountryList =new list<string>();
        isleofManCountryList= GsmUtilClass.getGSMSettingValue('RestrictedPlaceList').toLowerCase().split(','); //SFDC-7471
       List<String> isleManfieldList = new List<String>();//MARIT-318
        isleManfieldList = IsleManfields.split(','); //SFDC-7471


        for(Account eachAccount : listOfAccountsQueried)
        {
            Boolean addAccount = false;
            Boolean IsleofManFlag = true;
          for(string fieldname : isleManfieldList){
                if(eachAccount.get(fieldname)!=null && isleofManCountryList.Contains(string.valueof(eachAccount.get(fieldname)).toLowerCase())){
                      IsleofManFlag =false;
                      Break;
                  }  
             }
            if(((eachAccount.BillingCountry != null && eachAccount.BillingCountry != '')  || (eachAccount.ShippingCountry != null && eachAccount.ShippingCountry != '') )
                && IsleofManFlag)
          
            {
                if ((eachAccount.BillingCountry != null && eachAccount.BillingCountry != '')) {
                    allAccountsCountry.add(eachAccount.BillingCountry.toUpperCase());
                    addAccount = true;
                }
                if (eachAccount.ShippingCountry != null && eachAccount.ShippingCountry != '') {
                    allAccountsCountry.add(eachAccount.ShippingCountry.toUpperCase());
                    addAccount = true;
                }
                if (addAccount) {
                    listOfAccountsWithBillingOrShippingCountry.add(eachAccount);
                }
            }
        }

        for(Sales_Approved_Country__c sac : [select Country_Uppercase__c, Is_Reselling_Allowed__c, Is_Direct_Allowed__c from Sales_Approved_Country__c where Country_Uppercase__c in :allAccountsCountry])
        {
            countryToSac.put(sac.Country_Uppercase__c, sac);
        }

        for(Account acc :listOfAccountsWithBillingOrShippingCountry)
        {
            String oldApprovalStatus = acc.Sales_Approval_Status__c;
            Boolean oldRestrictedStatus = acc.Is_Restricted_Country__c;

            Sales_Approved_Country__c sac;
            Sales_Approved_Country__c sacShipping;

            if (acc.BillingCountry != null) 
                sac = countryToSac.get(acc.BillingCountry.toUpperCase());
            if (acc.ShippingCountry != null)
                sacShipping = countryToSac.get(acc.ShippingCountry.toUpperCase());
            
            if(sac!=null || sacShipping != null)
            {
                
                String salesApprovedStatusRelatedToBilling = '';
                String salesApprovedStatusRelatedToShipping = '';
                
                if (sac != null)
                    salesApprovedStatusRelatedToBilling = GsmUtilClass.getSalesApprovalStatus(sac);
                if (sacShipping != null)
                    salesApprovedStatusRelatedToShipping = GsmUtilClass.getSalesApprovalStatus(sacShipping);

                //acc.Sales_Approval_Status__c = GsmUtilClass.getSalesApprovalStatus(sac);
                if (salesApprovedStatusRelatedToBilling =='Both Restricted' || salesApprovedStatusRelatedToShipping =='Both Restricted') {
                    acc.Sales_Approval_Status__c = 'Both Restricted';
                    acc.Is_Restricted_Country__c = true;
                } else {
                    acc.Sales_Approval_Status__c = salesApprovedStatusRelatedToBilling;
                    acc.Is_Restricted_Country__c = false;
                }

                if((acc.Sales_Approval_Status__c != oldApprovalStatus) || acc.Is_Restricted_Country__c != oldRestrictedStatus)
                {
                    acc.Validation_Override__c = true;
                    listOfAccountsToBeUpdated.add(acc);
                }
            }

        }

        if(listOfAccountsToBeUpdated.size()>0)
            super.execute(BC, listOfAccountsToBeUpdated);


    }

    global override void finish(Database.BatchableContext BC)
    {
        for(Sales_Approved_Country__c sac : sacList)
            sac.Has_Changed__c = false;

        update sacList;

        super.finish(BC);
    }

   
 }
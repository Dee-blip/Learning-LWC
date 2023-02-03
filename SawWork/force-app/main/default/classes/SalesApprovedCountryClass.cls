public class SalesApprovedCountryClass
{
    public static Boolean updateRestrictedCountryOnAccountsFirstRunFlag = true;
	
    public static void updateRestrictedCountryOnAccounts(List<Account> listOfAccountsWithChangedCountry)
    {
        System.Debug('AGH_DEBUG WOW');
        if(!updateRestrictedCountryOnAccountsFirstRunFlag)
            return;

        Set<String> setOfCountries = new Set<String>();

        for(Account acc : listOfAccountsWithChangedCountry)
        {
            if(acc.BillingCountry!=null)
                setOfCountries.add(acc.BillingCountry);

            if (acc.ShippingCountry!=null)
                setOfCountries.add(acc.ShippingCountry);
        }

        Map<String, Sales_Approved_Country__c> countryToSac= new Map<String, Sales_Approved_Country__c>();

        System.Debug('AGH_DEBUG WOW  1');
        for(Sales_Approved_Country__c sac : [select Id, Name, Is_Reselling_Allowed__c, Is_Direct_Allowed__c from Sales_Approved_Country__c where Name in :setOfCountries])
        {
            System.Debug('AGH_DEBUG WOW2');
            countryToSac.put(sac.Name.toLowerCase(), sac);
        }
        if(countryToSac.size()>0)
        {
            for(Account acc : listOfAccountsWithChangedCountry)
            {
                String salesApprovedStatusFromBilling = '';
                String salesApprovedStatusFromShipping = '';
                if (acc.BillingCountry != null && countryToSac.get(acc.BillingCountry.toLowerCase()) != null) {
                    System.debug('Checking primary');
                    salesApprovedStatusFromBilling = GsmUtilClass.getSalesApprovalStatus(countryToSac.get(acc.BillingCountry.toLowerCase()));
                    System.debug('salesApprovedStatusFromBilling'+salesApprovedStatusFromBilling);
                } 
                if (acc.ShippingCountry != null && countryToSac.get(acc.ShippingCountry.toLowerCase()) != null) {
                    System.debug('Checking billing');
                    salesApprovedStatusFromShipping = GsmUtilClass.getSalesApprovalStatus(countryToSac.get(acc.ShippingCountry.toLowerCase()));
                    System.debug('salesApprovedStatusFromShipping'+salesApprovedStatusFromShipping);
                }

                //acc.Sales_Approval_Status__c = GsmUtilClass.getSalesApprovalStatus(sac);
                if (salesApprovedStatusFromBilling =='Both Restricted' || salesApprovedStatusFromShipping =='Both Restricted') {
                    acc.Sales_Approval_Status__c = 'Both Restricted';
                    acc.Is_Restricted_Country__c = true;
                } else {
                    acc.Sales_Approval_Status__c = salesApprovedStatusFromShipping;
                    acc.Is_Restricted_Country__c = false;
                }
            }
        }
        updateRestrictedCountryOnAccountsFirstRunFlag =false;
    }

}
/*
 * Test class name - AccountTriggerTestClass
 * Vandhana Krishnamurthy 		18 Jun 2021  ESESP-5494 : Support Differentiation for AkaTec (Saturn)
 * Aditi                        06 Jan 2022  ESESP-5717 : Saturn: Support Delivery Type Exceptions for APJ
*/

public class SC_AccountSupportDeliveryTypeMappClass 
{
	public static void updateAccountOnMapperChange(Map<Id,Account_Support_Delivery_Type_Mapper__c> newMap, Map<Id,Account_Support_Delivery_Type_Mapper__c> oldMap)
    {
        String addSuppLev = '';
        String exemptedCountries = '';
        String exemptedTerritory = '';

        Set<String> newMapSupportLevels = new Set<String>();
        Set<String> oldMapSupportLevels = new Set<String>();
        Set<String> newMapExemptedCountries = new Set<String>();
        Set<String> oldMapExemptedCountries = new Set<String>();
        Set<String> newMapExemptedTerritory = new Set<String>();
        Set<String> oldMapExemptedTerritory = new Set<String>();
                
        Map<Id,Account_Support_Delivery_Type_Mapper__c> mapNewMapperRec = new Map<Id,Account_Support_Delivery_Type_Mapper__c>();
        Map<Id,Account_Support_Delivery_Type_Mapper__c> mapOldMapperRec = new Map<Id,Account_Support_Delivery_Type_Mapper__c>();
        
        for(Account_Support_Delivery_Type_Mapper__c eachMapperRec : newMap.values())
        {
            if( (eachMapperRec.Support_Level__c != oldMap.get(eachMapperRec.Id).Support_Level__c) 
               || (eachMapperRec.Additional_Support_Levels__c  != oldMap.get(eachMapperRec.Id).Additional_Support_Levels__c ) 
               || (eachMapperRec.Exception_Countries__c != oldMap.get(eachMapperRec.Id).Exception_Countries__c)
               || (eachMapperRec.Exemption_Territories__c != oldMap.get(eachMapperRec.Id).Exemption_Territories__c))
            {
                mapNewMapperRec.put(eachMapperRec.Id,eachMapperRec);
                mapOldMapperRec.put(eachMapperRec.Id,oldMap.get(eachMapperRec.Id));
            }
        }
        
        System.debug('mapNewMapperRec :: '+mapNewMapperRec);
        System.debug('mapOldMapperRec :: '+mapOldMapperRec);
        
        for(Id eachRecId : mapNewMapperRec.keyset())
        {
            newMapSupportLevels.addAll(mapNewMapperRec.get(eachRecId).Support_Level__c.split(';'));
            oldMapSupportLevels.addAll(mapOldMapperRec.get(eachRecId).Support_Level__c.split(';'));
            System.debug('newMapSupportLevels :: '+newMapSupportLevels);
            
            if(String.isNotBlank(mapNewMapperRec.get(eachRecId).Additional_Support_Levels__c))
            {
                addSuppLev = mapNewMapperRec.get(eachRecId).Additional_Support_Levels__c.replace('\r\n','\n');
                addSuppLev = addSuppLev.replaceAll('[\n,]',';');
                newMapSupportLevels.addAll(addSuppLev.split(';'));
            }
            System.debug('newMapSupportLevels :: '+newMapSupportLevels);
            
            if(String.isNotBlank(mapOldMapperRec.get(eachRecId).Additional_Support_Levels__c))
            {
                addSuppLev = mapOldMapperRec.get(eachRecId).Additional_Support_Levels__c.replace('\r\n','\n');
                addSuppLev = addSuppLev.replaceAll('[\n,]',';');
                oldMapSupportLevels.addAll(addSuppLev.split(';'));
            }
            System.debug('newMapSupportLevels :: '+newMapSupportLevels);

            
            if(String.isNotBlank(mapNewMapperRec.get(eachRecId).Exception_Countries__c))
            {
                exemptedCountries = mapNewMapperRec.get(eachRecId).Exception_Countries__c.replace('\r\n','\n');
                exemptedCountries = exemptedCountries.replaceAll('[\n,]',';');
                newMapExemptedCountries.addAll(exemptedCountries.split(';'));
            }
            
            if(String.isNotBlank(mapOldMapperRec.get(eachRecId).Exception_Countries__c))
            {
                exemptedCountries = mapOldMapperRec.get(eachRecId).Exception_Countries__c.replace('\r\n','\n');
                exemptedCountries = exemptedCountries.replaceAll('[\n,]',';');
                oldMapExemptedCountries.addAll(exemptedCountries.split(';'));
            }
            if(String.isNotBlank(mapNewMapperRec.get(eachRecId).Exemption_Territories__c))
            {
                exemptedTerritory = mapNewMapperRec.get(eachRecId).Exemption_Territories__c.replace('\r\n','\n');
                exemptedTerritory = exemptedTerritory.replaceAll('[\n,]',';');
                newMapExemptedTerritory.addAll(exemptedTerritory.split(';'));
            }
            
            if(String.isNotBlank(mapOldMapperRec.get(eachRecId).Exemption_Territories__c))
            {
                exemptedTerritory = mapOldMapperRec.get(eachRecId).Exemption_Territories__c.replace('\r\n','\n');
                exemptedTerritory = exemptedTerritory.replaceAll('[\n,]',';');
                oldMapExemptedTerritory.addAll(exemptedTerritory.split(';'));
            }
        }


        System.debug('newMapSupportLevels :: '+newMapSupportLevels);
        System.debug('oldMapSupportLevels :: '+oldMapSupportLevels);
        System.debug('newMapExemptedCountries :: '+newMapExemptedCountries);
        System.debug('oldMapExemptedCountries :: '+oldMapExemptedCountries);
        System.debug('newMapExemptedTerritory :: '+newMapExemptedTerritory);
        System.debug('oldMapExemptedTerritory :: '+oldMapExemptedTerritory);
        
        updateAccountSuppDelType(newMapSupportLevels,oldMapSupportLevels,newMapExemptedCountries,oldMapExemptedCountries,newMapExemptedTerritory,oldMapExemptedTerritory);
    }
    
    
    @future
    public static void updateAccountSuppDelType(Set<String> newMapSupportLevels, Set<String> oldMapSupportLevels, Set<String> newMapExemptedCountries, Set<String> oldMapExemptedCountries, Set<String> newMapExemptedTerritory, Set<String> oldMapExemptedTerritory)
    {
        Set<String> addedSupportLevels = new Set<String>();
        Set<String> removedSupportLevels = new Set<String>();
        Set<String> addedCountries = new Set<String>();
        Set<String> removedCountries = new Set<String>();
        Set<String> addedTerritory = new Set<String>();
        Set<String> removedTerritory = new Set<String>();

        Set<String> allSupportLevels = new Set<String>();
        Set<String> allCountries = new Set<String>();
        Set<String> allTerritory = new Set<String>();
        Database.SaveResult[] dbSRList;

        addedSupportLevels.addAll(newMapSupportLevels);
        addedSupportLevels.removeAll(oldMapSupportLevels);
        removedSupportLevels.addAll(oldMapSupportLevels);
        removedSupportLevels.removeAll(newMapSupportLevels);
        addedCountries.addAll(newMapExemptedCountries);
        addedCountries.removeAll(oldMapExemptedCountries);
        removedCountries.addAll(oldMapExemptedCountries);
        removedCountries.removeAll(newMapExemptedCountries);
        addedTerritory.addAll(newMapExemptedTerritory);
        addedTerritory.removeAll(oldMapExemptedTerritory);
        removedTerritory.addAll(oldMapExemptedTerritory);
        removedTerritory.removeAll(newMapExemptedTerritory);
        
        allSupportLevels.addAll(addedSupportLevels);
        allSupportLevels.addAll(removedSupportLevels);
        allCountries.addAll(addedCountries);
        allCountries.addAll(removedCountries);
        allTerritory.addAll(addedTerritory);
        allTerritory.addAll(removedTerritory);

        Map<String,Set<String>> mapOfNameToList = new Map<String,Set<String>>();
        mapOfNameToList.put('Support Levels',newMapSupportLevels);
        mapOfNameToList.put('Exempted Countries',newMapExemptedCountries);
        mapOfNameToList.put('Exempted Territory',newMapExemptedTerritory);

        
        List<Account> lstAcc = [SELECT Id,Support_Delivery_Type__c,Validation_Override__c,Support_Level__c,BillingCountry,TERR_HIER_5__c
                                FROM Account 
                                WHERE Type != 'Lead' AND (NOT Type LIKE '%inacti%')
                                AND (Support_Level__c IN :allSupportLevels
                                OR BillingCountry IN :allCountries OR TERR_HIER_5__c IN :allTerritory)];
        
        System.debug('lstAcc :: '+lstAcc);
        
        List<Account> lstAcc2Update = new List<Account>();
        List<Id> lstFailedAccUpdate = new List<Id>();
        
        for(Account eachAcc : lstAcc)
        {
            System.debug('eachAcc :: '+eachAcc);
            if(addedSupportLevels.contains(eachAcc.Support_Level__c)){
                //Only if the country is not matching or when country+terr is matching it will be global
                if(!mapOfNameToList.get('Exempted Countries').contains(eachAcc.BillingCountry) ||
                (mapOfNameToList.get('Exempted Countries').contains(eachAcc.BillingCountry) && mapOfNameToList.get('Exempted Territory').contains(eachAcc.TERR_HIER_5__c))){
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Global'){
                        eachAcc.Support_Delivery_Type__c = 'Global';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                else{
                    //Always if the Support level+country matches and the terr does not match then we have geo
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
            }
            else if(removedSupportLevels.contains(eachAcc.Support_Level__c))
            {
                //if the support level is not matching it is always geo
                if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                    eachAcc.Support_Delivery_Type__c = 'Geo';
                    eachAcc.Validation_Override__c = true;
                    lstAcc2Update.add(eachAcc);
                }
            }
            else if(addedCountries.contains(eachAcc.BillingCountry))
            {
                System.debug('mapOfNameToList :: '+mapOfNameToList);
                System.debug('eachAcc.Support_Level__c :: '+eachAcc.Support_Level__c);
                System.debug('eachAcc.TERR_HIER_5__c :: '+eachAcc.TERR_HIER_5__c);
                //If country is added only when support level and terr matches it will be global as the country is an exception
                if(mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c) && mapOfNameToList.get('Exempted Territory').contains(eachAcc.TERR_HIER_5__c)){
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Global'){
                        eachAcc.Support_Delivery_Type__c = 'Global';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                else{
                    //in all other cases the SDT should be geo as the support level matches it is an exception
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                System.debug('Support_Delivery_Type__c set in addedCountries :: '+eachAcc.Support_Delivery_Type__c);
            }
            else if(removedCountries.contains(eachAcc.BillingCountry))
            {
                //if a country is removed the support level matches only then the SDT is global in all other cases it will be geo
                if(mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c)){
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Global'){
                        eachAcc.Support_Delivery_Type__c = 'Global';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }else{
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                System.debug('Support_Delivery_Type__c set in removedCountries :: '+eachAcc.Support_Delivery_Type__c);
            }
            else if(addedTerritory.contains(eachAcc.TERR_HIER_5__c))
            {
                //Whenever a territory is added always it will be Global if Support Level is matching whether we have the country in mapper or not
                if(mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c)){
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Global'){
                        eachAcc.Support_Delivery_Type__c = 'Global';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                else{
                    //Only when Support Level is not there in the mapper
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
            }
            else if(removedTerritory.contains(eachAcc.TERR_HIER_5__c))
            {
                //If after removing terr we have the support level and the country matching then it is geo as per exception
                if(mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c) && mapOfNameToList.get('Exempted Countries').contains(eachAcc.BillingCountry)){
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                else if(!mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c) && mapOfNameToList.get('Exempted Countries').contains(eachAcc.BillingCountry)){
                    //if the support level does not match even though the country is present then also it is geo as support level determines the global value
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Geo'){
                        eachAcc.Support_Delivery_Type__c = 'Geo';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
                else if(mapOfNameToList.get('Support Levels').contains(eachAcc.Support_Level__c) && !mapOfNameToList.get('Exempted Countries').contains(eachAcc.BillingCountry)){
                    //if only support level matches then it is geo
                    if(eachAcc.Support_Delivery_Type__c != null && eachAcc.Support_Delivery_Type__c != 'Global'){
                        eachAcc.Support_Delivery_Type__c = 'Global';
                        eachAcc.Validation_Override__c = true;
                        lstAcc2Update.add(eachAcc);
                    }
                }
            }
            //eachAcc.Validation_Override__c = true;
            //lstAcc2Update.add(eachAcc);
            System.debug('lstAcc2Update :: '+lstAcc2Update);
        }
        
        try
        {
            dbSRList = Database.update(lstAcc2Update, false);
            
            for(Integer i=0; i < dbSRList.size(); i++)
            {
                if(!dbSRList[i].isSuccess())
                {
                    lstFailedAccUpdate.add(lstAcc2Update[i].Id);
                    
                }
            }
        }
        
		catch(Exception e)
        {
            System.debug('Exception' + e);
            string setEmailSub = 'Exception: Account Support Delivery Type update failed!';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                      				'Class Name = SC_AccountSupportDeliveryTypeMappClass\n' + 
                                	'Method Name = updateAccountOnMapperChange\n';
            errorMessage += e.getCause() + '..'+ e.getLineNumber() + '..' + e.getMessage() + '..' + e.getTypeName() + '..' + e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
          	sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        }        
    }
}
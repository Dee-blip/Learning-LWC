public class GSMSettings
{

        public static String getValue(String developerName)
        {
            GSM_Settings__mdt  mdtRecord = [select Id, Value__c from GSM_Settings__mdt  where DeveloperName = :developerName];
            return mdtRecord.Value__c;
        }

        public static Boolean contains(String developerName, String strToMatch)
        {
            if(String.isBlank(strToMatch))
                return false;

            Set<String> sset = getSetOfStrings(developerName);
            return sset.contains(strToMatch);

        }

        public static Set<String> getSetOfStrings(String developerName)
        {
            Set<String> setOfStrings = new Set<String>();
            setOfStrings.addAll(GSMSettings.getValue(developerName).split('\\s*,\\s*'));
            return setOfStrings;
        }

        public static Set<String> getValues(String developerName)
        {
            Set<String> valueSet = new Set<String>();
            String devName = ''+developerName+'%';
            for(GSM_Settings__mdt mdt : [select id, Value__c from GSM_Settings__mdt where DeveloperName like :devName])
            {
                valueSet.add(mdt.Value__c);
            }

            return valueSet;
        }


        public static Map<String, Set<String>> getSyncToSiebelFields(String sObjectLabel, Boolean excludeExpansions)
        {
            
            Set<String> crmIntegrationProfileIds = getSetOfStrings('ProfileIdCRMIntegration');
            Set<String> mulesoftIntegrationProfileIds = getSetOfStrings('ProfileIdMulesoftIntegration');
            Map<String, Set<String>> integrationProfileIdToSiebelFields = new Map<String, Set<String>>();

            for(String cId: crmintegrationProfileIds)
            {
                integrationProfileIdToSiebelFields.put(cId, new Set<String>());
            }
            for(String cId: mulesoftintegrationProfileIds)
            {
                integrationProfileIdToSiebelFields.put(cId, new Set<String>());
            }
            integrationProfileIdToSiebelFields.put('NonIntegrationUser', new Set<String>());

            /*
               Naming scheme for the gsm settings will be 
               developername = SyncToSiebelFieldList_CRM1, SyncToSiebelFieldList_Mulesoft1, SyncToSiebelFieldList_NonIntegration1
               */
            for(GSM_Settings__mdt gsm:[select developerName,value__c from GSM_Settings__mdt where developername like :('SiebelFields_'+sObjectLabel+'_%')])
            {
                if(excludeExpansions && !gsm.developerName.contains('Expanded') || !excludeExpansions)
                {
                    Set<String> cIds = gsm.developerName.contains('CRM') ? crmintegrationProfileIds : (gsm.developerName.contains('Mulesoft') ? mulesoftintegrationProfileIds : new Set<String>{'NonIntegrationUser'});
                    for(String field: gsm.Value__c.split(','))
                    {
                        for(String cId: cIds)
                        {
                            integrationProfileIdToSiebelFields.get(cId).add(field.trim());
                        }
                    }
                }
            }

            System.Debug(LoggingLevel.Error, 'AGH_D in sync to siebel'+integrationProfileIdToSiebelFields);
            return integrationProfileIdToSiebelFields;
            
        }

        public static Integer getInt(String developerName)
        {
            return Integer.valueOf(getValue(developerName));
        }

        public static boolean getBoolean(String developerName)
        {
            return Boolean.valueOf(getValue(developerName));
        }

        public static String getVerbose(String developerName)
        {
            GSM_Settings_Verbose__mdt  mdtRecord = [select Id, Value__c from GSM_Settings_Verbose__mdt  where DeveloperName = :developerName];
            return mdtRecord.Value__c;
        }

        public static Map<String, String> getMap(String developerName)
        {
            GSM_Settings__mdt  mdtRecord = [select Id, Value__c from GSM_Settings__mdt  where DeveloperName = :developerName];
            Map<String, String> metMap = (Map<String, String>) JSON.deserialize(mdtRecord.Value__c, Map<String,String>.class);

            return metMap;
        }

        public static Map<String, String> getLargeMap(String developerName)
        {
            GSM_Settings_Verbose__mdt  mdtRecord = [select Id, Value__c from GSM_Settings_Verbose__mdt  where DeveloperName = :developerName];
            Map<String, String> metMap = (Map<String, String>) JSON.deserialize(mdtRecord.Value__c, Map<String,String>.class);

            return metMap;
        }
}
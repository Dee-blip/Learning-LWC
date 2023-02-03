public class Util {

    public static final String CONFIG_NAME ='MDF_CONFIGURATIONS';
    public static final String ACCOUNT_OBJECT_NAME ='Account';
    public static final String FUND_REQUEST = 'FR'; 
    public static final String FUND_CLAIM = 'FC';
    public static final String NUMBER_TYPE ='Number'; 
    public static final String String_TYPE ='String';
    public static final String NUMBER_STRING_TYPE ='NUMBER_STRING';
    
    /**
     * Method to check if the org has multi currency enabled.
     * @return multiCurrencyEnabled.
     */
    public static boolean isMultiCurrencyEnabled() {
        boolean multiCurrencyEnabled = false;
        Map<String,Schema.SObjectType> objTypeMap = Schema.getGlobalDescribe();
        if (objTypeMap != null && objTypeMap.size() > 0) {
            if (objTypeMap.containsKey('CurrencyType')) {
                multiCurrencyEnabled = true;
            }
        }
        return multiCurrencyEnabled;
    }
    
    
    
    
    
    /* Submits an object for approval*/
    public static Approval.ProcessResult submitForApproval(Id objId, String message) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(message);
        req.setObjectId(objId);
        Approval.ProcessResult result = Approval.process(req,false);
        return result;
    }
    
    /**
     * Tests specified new and old records for changes in specified set of fields.
     * 
     * @return <code>true</code> if changed; <code>false</code> otherwise.
     */
    public static Boolean hasChanges(Set<String> fieldNames, SObject oldRecord, SObject newRecord) {
        if (oldRecord == null) {
            return true;
        }
        Boolean changed = false;
        for (String field : fieldNames) {
            changed = (oldRecord.get(field) != newRecord.get(field));
            if (changed) break;
        }
        return changed;
    }
    
    public static Boolean hasChanges(String field, SObject oldRecord, SObject newRecord) {
        if (oldRecord == null) {
            return true;
        }
        return (oldRecord.get(field) != newRecord.get(field));
    } 

    /** isInserted() is a Trigger helper method. 
    Checks if record is 1.inserted and 2. Field value !=null **/
    public static Boolean isInserted(String field, SObject newRecord)
    {
        return (Trigger.isInsert && newRecord.get(field)!=null);
    
    }

    //SFDC-1453
    public static Boolean isInserted(Set<String> fieldNames, SObject newRecord) {

        Boolean inserted = false;
        for (String field : fieldNames) {
            inserted = (newRecord.get(field)!=null);
            if (inserted) break;
        }
        return inserted;
    }

    /** hasChangedFrom() is a Trigger helper method. 
    For a record, checks if old value of a record has changed based on operator. **/
    public static Boolean hasChangedFrom(String field, SObject oldRecord, String oldValue, String operator)
    {   
        // treat 'null' as null
        if(oldValue == 'null')
            oldValue = null;

        if(operator.equalsIgnoreCase('equals'))
            return (oldRecord.get(field) == oldValue);
        else if(operator.equalsIgnoreCase('notequals'))
            return (oldRecord.get(field) != oldValue);
        
        return false;

    }
    /** hasChangedFrom() is a Trigger helper method. 
    For a record, checks if new value of a record has changed based on operator. **/
    public static Boolean hasChangedTo(String field,SObject newRecord, String newValue,String operator)
    {   
        // treat 'null' as null
        if(newValue == 'null')
            newValue = null;

        if(operator.equalsIgnoreCase('equals'))
            return (newRecord.get(field) == newValue); 
        
        if(operator.equalsIgnoreCase('notequals'))
            return (newRecord.get(field) != newValue); 

        if(operator.equalsIgnoreCase('contains'))
        {
            String tempString = String.valueOf(newRecord.get(field));
            if(tempString!=null)
                return tempString.contains(newValue);
        }

        return false;
    }
    
    /**
     * Method to get the all the currencies that are enabled in the org and are active.
     */ 
    public static Map<String, CurrencyWrapper> getCurrencies() {
        Map<String, CurrencyWrapper> currencyMap = new Map<String, CurrencyWrapper>();
        for (SObject cur : Database.query('Select c.IsoCode, c.IsCorporate, c.IsActive, c.DecimalPlaces, c.ConversionRate From CurrencyType c Where c.IsActive='+ true))
         {
            currencyMap.put((String)cur.get('IsoCode'), new CurrencyWrapper(cur));
        }
        return currencyMap;
    } 
    
    public static void convertAmountToCorporateCurrency( Map<String, CurrencyWrapper>  currencyMap, SObject fundObj) {
        CurrencyWrapper corporateCurrency = getCorporateCurrency(currencyMap);
        String recordIsoCode = (String)fundObj.get('CurrencyIsoCode');
        Decimal amountInOrgCurrency = (Decimal)fundObj.get('Amount__c');
        amountInOrgCurrency.setScale(2); 
        if (!recordIsoCode.equalsIgnoreCase(corporateCurrency.getIsoCode())) {
            CurrencyWrapper recordCurrency = currencyMap.get(recordIsoCode);
            amountInOrgCurrency.setScale(recordCurrency.getDecimalPlaces());
            amountInOrgCurrency = amountInOrgCurrency.divide(recordCurrency.getConversionRate(), 2,System.Roundingmode.UP);
        } 
        fundObj.put('Amount_In_Corporate_Currency__c', amountInOrgCurrency);
        
    } 
    
   
    
    public static CurrencyWrapper getCorporateCurrency(Map<String, CurrencyWrapper> currencyMap)  {
        CurrencyWrapper corporateCurrency = null;
        for (CurrencyWrapper currenyInfo : currencyMap.values()) {
            if (currenyInfo.isCorporateCurrency()) {
                corporateCurrency = currenyInfo;
                break;
            }
        }
        
        return corporateCurrency;
    }     
    
    public static Map<String,Object> convertJSONToMap(String jsonString){
        Map<String, Object> mapFromJson;
        try {
            mapFromJson = (Map<String, Object>)JSON.deserializeUntyped(jsonString);       
        } catch(Exception e){
            mapFromJson = new Map<String, Object>();
        }
        return mapFromJson;
    }
    
    public static String convertMapToJson(Map <String,Object> mapObject){
        String jsonFromMap = JSON.serialize(mapObject);
        return jsonFromMap;
    }
    
    public static List<Object> convertJSONToList(String jsonString){
        List<Object> listFromJson;
        try {
            listFromJson = (List<Object>)JSON.deserializeUntyped(jsonString);       
        } catch(Exception e){
            listFromJson = new List<Object>();
        }
        return listFromJson;
    }
    
    public static String convertMapToJson(List<Object> listObject){
        String jsonFromList = JSON.serialize(listObject);
        return jsonFromList;
    }
    
    public static Boolean isOrganizationProduction(){
        //String orgId = UserInfo.getOrganizationId(); // [select Division from Organization][0].Id;
        //TODO : add the org ID of DR as well.
        //Boolean status = orgId.contains('00DA0000000Hu5a') ? true : false;
        Organization org = [Select ISSANDBOX from ORGANIZATION LIMIT 1];
        Boolean status = !(org.IsSandbox);
        return status;
    }
    
    public static Boolean isUserId(String userId){
        Boolean success = (userId.substring(0,3)=='005') ? true : false;
        return success;
    }
    
    public static Boolean isContactId(String conId){
        Boolean success = (conId.substring(0,3)=='003') ? true : false;
        return success;
    }
    
    public static Id getSystemAdminProfileId(){
        //SFDC-2572
        Id sysAdminId = GsmUtilClass.getPRMSettingValue('SystemAdminProfileID');
      //Id sysAdminId = [Select Id from Profile where name = 'System Administrator'][0].Id;
        return sysAdminId;
    }

    public static void updateCronRunWithResult(String jobType, String res)
    {
        List<Cron_Batch_Run__c> listOfCronRuns = [select id, CreatedDate, Result__c from Cron_Batch_Run__c  where Batch_Job_Type__c = :jobType and Result__c!=null order by CreatedDate DESC limit 1];
        if(listOfCronRuns.size()>0)
        {
            String resultString = res;
            if(resultString.length() >= 32000)
                resultString = resultString.substring(0, 31999);
            if(listOfCronRuns!=null && listOfCronRuns.size()>0)
            {
                listOfCronRuns[0].Results__c = resultString;
                /*
                   AGH - dont mark as failure because it sends alerts to eae ops
                if(resultString.containsIgnoreCase('failure'))
                    listOfCronRuns[0].Result__c = 'Failure';
                    */
                update listOfCronRuns[0];
            }
        }
    }

    public static String inClausify(Set<String> strSet) 
    {
        List<String> escapedSet = new List<String>();
        for(String s : strSet)
        {
            escapedSet.add(String.escapeSingleQuotes(s));
        }
        String inClause = String.format( '(\'\'{0}\'\')', new List<String> { String.join( escapedSet , '\',\'') });
        return inClause;
    }

    /*
       TODO - 
       1. Maybe pass the field API names and the field headings you want in the email. Maybe this could be an overloaded
       method with these two additional parameters if it's needed?
       2. Do we need this for insert?

    */
    public static String updateAndSaveLogs(List<SObject> listOfRecordsToBeUpdated, String jobName, Boolean saveErrorLog)
    {
        Integer failedUpdates = 0;
        Integer successfulUpdates = 0;
        Boolean errorFlag = false;
        List<String> errorString = new List<String>();
        Integer totalUpdates = listOfRecordsToBeUpdated.size();
        String res='1: No Records to Update';

        if(totalUpdates>0)
        {
            Database.SaveResult[] srList = Database.update(listOfRecordsToBeUpdated, false);
            List<Error_Log__c> errorLogs = new List<Error_Log__c>();
            Integer count=0;
            String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';

            for (Database.SaveResult sr : srList) 
            {
                if (!sr.isSuccess()) 
                {
                    errorFlag = true;
                    failedUpdates = failedUpdates +1;
                    String errMessage='';
                    for(Database.Error err : sr.getErrors()) 
                    {                  
                        errMessage += err.getFields() +': ' + err.getMessage() + '<br/>';

                    }
                    String recordURL = '<a href="'+ baseUrl+listOfRecordsToBeUpdated[count].Id+'">' +listOfRecordsToBeUpdated[count].get('Name') + '</a>';           

                    errorString.add('<tr><td>'+recordURL+'</td><td>' + errMessage +'</td></tr>');

                    if(saveErrorLog)
                    {
                        Error_Log__c el = new Error_Log__c(Name=jobName, Class__c=jobName, Error_Message__c=errMessage , RecordId__c=listOfRecordsToBeUpdated[count].Id);
                        errorLogs.add(el);
                    }
                }
                count = count + 1;      
            }
            if(errorLogs.size()>0)
                Database.insert(errorLogs, false);
            //Ignoring insert errors for errorlogs

            String emailMessage = 'Your update job '+ jobName + ' has finished. ' +'<br/>Total Record Updates Tried: ' + totalUpdates +'<br/>Failed records : '+  failedUpdates + '<br/><br/>';

            jobName = jobName.replaceAll(' ', '');
            String emailTo = GSMUtilClass.getGSMSettingValue(jobName+'_'+'ToEmail');

            if(errorFlag)
            {
                String tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Record Link</th><th>Error</th></tr>';
                emailMessage = emailMessage + '<br/>' +tableBegin;
                for( String str : errorString)
                {
                    emailMessage = emailMessage + str;
                }
                emailMessage = emailMessage + '</table>';

                res = '1: Total Updates Tried: '+totalUpdates+ '.\n Failed records: '+ failedUpdates+'.\n Results mailed to '+emailTo;
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses;
                if(String.isBlank(emailTo))
                {
                    toAddresses = new String[]{'eae-ops@akamai.com'};
                }
                else
                {
                    toAddresses =emailTo.split(',');
                }

                mail.setToAddresses(toAddresses);
                mail.setReplyTo('noreply@salesforce.com');
                mail.setSenderDisplayName('Update Job Summary');
                mail.setSubject('Update Job completed');
                mail.setPlainTextBody(emailMessage);
                mail.setHtmlBody(emailMessage);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            else
            {
                res='1: All '+totalUpdates + ' succeeded.';
            }



        }

        return res;

    }

    public static Boolean stringContains(String customSettingString, String valueToMatch)
    {
        Set<String> stringSet = new Set<String>();
        stringSet.addAll(customSettingString.split('\\s*,\\s*'));
        return stringSet.contains(valueToMatch);
    }

    public static LunaControlCenterSettings__c getLunaSettings(){
        LunaControlCenterSettings__c lunaSettings = Util.isOrganizationProduction() ? LunaControlCenterSettings__c.getInstance('Production') : LunaControlCenterSettings__c.getInstance('Staging');
        return lunaSettings;
    }

    public static Boolean isLunaConnectionActive(){
        Boolean success = false;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        success = lunaSettings.Activate_Connection__c;
        return success;
    }

    public static String getLunaIdpUrl(){
        String idpUrl;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        idpUrl = lunaSettings.IDP_login_url__c;
        return idpUrl;
    }
    
    public static String getLunaPortalUrl()
    {
        String lunaUrl;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        lunaUrl = lunaSettings.Luna_Link_via_IDP__c;
        return lunaUrl;
    }
    
    public static String getMyAkamaiDocLink()
    {
        String myAkamaiDocLink;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        myAkamaiDocLink = lunaSettings.My_Akamai_Doc_Link__c;
        return myAkamaiDocLink;
    }

    public static String getLunaProfilePageUrl(){
        String profileUrl;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        profileUrl = lunaSettings.Change_Password_URL__c;
        return profileUrl;
    }
    
    public static String getCsodSamlUrl(){
        String csodSamlUrl;
        LunaControlCenterSettings__c lunaSettings = getLunaSettings();
        if(isLunaConnectionActive())
        {
            csodSamlUrl = lunaSettings.CSOD_Link__c;
        }
        else
        {
            //SFDC-2572
            csodSamlUrl = GsmUtilClass.getPRMSettingValue('Akamai_University_SAML_URL');
        }
        return csodSamlUrl;
    }

    public static Boolean isPartnerAdminProfile(User partnerUser){
       //SFDC-2572
        return ((partnerUser != null) && (partnerUser.Profile.Name == GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')));
    }

    

    public static boolean isLevel3Partner(String akamAccountId)
    {
    
        // Rahul Gaira      12/12/2014  CR 2866701 PRM: Channel -- Level 3 Prohibited Account Custom Setting
         //                       -> Level3PartnerAccountAKAMId Custom Label is moved to the GSM Custom Setting
       
        List<String> level3PartnerAkamAccountIds = GSMSettings.getValue('Level3PartnerAccountAKAMId').split(',');
        //List<String> level3PartnerAkamAccountIds = Label.Level3PartnerAccountAKAMId.split(',');
      
        for(String ithAkamAccountId: level3PartnerAkamAccountIds)
        {
            if(akamAccountId.trim()==ithAkamAccountId.trim())
            {
                return true;
            }
        }
        return false;
    }

    public static String createCommunityAwareURL(String rawURL)
    {
        System.Debug('##commm ' + Network.getNetworkId());
        //if(Network.getNetworkId()==Label.Partner_Community_ID)
        //SFDC-2572
        if(Network.getNetworkId()!=null && GsmUtilClass.getPRMSettingValue('PrefixCommunityName')=='TRUE')
        {
            rawURL = rawURL.replace('apex', Label.Partner_Community_Name + '/apex');
        }
        return rawURL;
    }

    public static List<String> pluckField(List<SObject> records, Schema.SObjectField field) 
    {
		List<String> results = new List<String>();
		for (SObject rec : records) {
			results.add((String)rec.get(field));
		}
		return results;
	}

    public static String pluckAsString(List<SObject> records, Schema.SObjectField field) 
    {
        return String.join(pluckField(records, field),',');
	}
    
}
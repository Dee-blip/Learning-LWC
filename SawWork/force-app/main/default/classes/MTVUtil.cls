public without sharing class MTVUtil {

    public static List<User> getUsers(Set<Id> SetContactID){
        return [Select ID,Name,ProfileID,Email,CompanyName,Username,UserRole.Name,Profile.Name, Contact.Account.Name from user where ContactID in: SetContactID order by Contact.Account.Name];
    } 
    
    public static void addAssoc(List<Object_Association__c> prefToAddList){
        try{
            insert prefToAddList;
        }catch(DMLException e){
            System.debug('Exception in inserting preferred Association: '+ e);
        }
    }

    public static Boolean hasChanges(Set<String> fieldNames, SObject oldRecord, SObject newRecord) {
        if (oldRecord == null) {
            return true;
        }
        Boolean changed = false;
        for (String field : fieldNames) {
            changed = changed || (oldRecord.get(field) != newRecord.get(field));
        }
        return changed;
    }

    public static Boolean hasChanges(String fieldName, SObject oldRecord, SObject newRecord) {
        if (oldRecord == null) {
            return true;
        }
        return (oldRecord.get(fieldName) != newRecord.get(fieldName));
    }

    public static void addToMapAsString(Id sObjectId, Object value, Map<Id, String> m) {
        if (value == null) {
            return;
        }
        String x = (String) value;
        if(m.containsKey(sObjectId)){
            x = x + ',' + m.get(sObjectId);
        }
        m.put(sObjectId, x);
    }



    public static void addToMap(Id sObjectId, Object value, Map<Id, Set<id>> m) {
        if (value == null) {
            return;
        }
        Id x = (Id) value;
        Set<id> s = m.get(sObjectId);
        if(s == null){
            s = new Set<Id>();
            m.put(sObjectId, s);
        }
        s.add(x);
    }

    
    public static String getRecordFieldsAsString(Set<String> recordFields) {
        String recordFieldsAsString = '';
        for (String field : recordFields) {
            if (!recordFieldsAsString.equals('')) recordFieldsAsString += ',';
            recordFieldsAsString += field;
        }
        return recordFieldsAsString;
    }
    
    public static String getFieldName(String name){
        Configuration__c opportunitySettings;
        Map<String, Configuration__c> settingsMap = Configuration__c.getAll();
        if(settingsMap.containsKey(name)){
            opportunitySettings = settingsMap.get(name);
        }else{
            opportunitySettings = new Configuration__c(Name=name, Field_Name__c = 'AccountId', Object__c = name, Use_Partner_Portal__c = true, Share_with_this_Account__c = true);
            //insert opportunitySettings;
        }
        String customField ;
        // Boolean shareWithThisAcc = false;
        if(opportunitySettings != null){
            customField = opportunitySettings.Field_Name__c;
        }
        return customField;
    }


    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //test method for the MTVUtil class
    //testmethod static void testGetFieldName(){
    //    String s = getFieldName('Opportunity');     
    //}
    
    
    //testMethod static void testGetUsers() {
    //    Set<Id> contactIds = new Set<Id>();
    //    for( User u : [Select ContactId from User where ContactId != null limit 10]) {
    //        contactIds.add(u.ContactId);
    //    }
    //    MTVUtil.getUsers(contactIDs);
    //}
    
    //testMethod static void testHasChanges() {
    //    Account oldRecord = null;
    //    //Account newRecord = new Account(Name = 'Test2', BillingCity = 'Palo Alto');
    //    Account newRecord = utilTestClass.CreateAccount('Test2');
    //    newRecord.BillingCity = 'Palo Alto';
    //    MTVUtil.hasChanges('BillingCity', oldRecord, newRecord);
    //    MTVUtil.hasChanges(new Set<String>{'BillingCity', 'Name'}, oldRecord, newRecord);
    //    //oldRecord = new Account(Name = 'Test1', BillingCity = 'SFO');
    //    oldRecord = utilTestClass.CreateAccount('Test1');
    //    oldRecord.BillingCity = 'SFO';
    //    MTVUtil.hasChanges('BillingCity', oldRecord, newRecord);
    //    MTVUtil.hasChanges(new Set<String>{'BillingCity', 'Name'}, oldRecord, newRecord);
    //}
    
    //testMethod static void testAddToMap() {
    //    Id sObjectId = UserInfo.getUserId();
    //    Object value = null;
    //    Map<Id, Set<id>> m = new Map<Id, Set<id>>();
    //    MTVUtil.addToMap(sObjectId, value, m);
    //    value = sObjectId;
    //    MTVUtil.addToMap(sObjectId, value, m);
    //}
    
    //testMethod static void testAddToMapAsString() {
    //    Id sObjectId = UserInfo.getUserId();
    //    Object value = null;
    //    Map<Id, String> m = new Map<Id, String>();
    //    MTVUtil.addToMapAsString(sObjectId, value, m);
    //    value = sObjectId;
    //    MTVUtil.addToMapAsString(sObjectId, value, m);
    //}
    
    //testMethod static void testGetRecordFieldsAsString() {
    //    Set<String> recordFields = new Set<String> {'A', 'B'};
    //    String recordFieldsAsString = MTVUtil.getRecordFieldsAsString(recordFields);
    //    System.assertEquals(recordFieldsAsString, 'A,B');
    //}
}
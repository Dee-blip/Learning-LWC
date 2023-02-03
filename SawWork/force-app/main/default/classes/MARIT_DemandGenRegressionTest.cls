@isTest(seeAllData = false)
public class MARIT_DemandGenRegressionTest {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    public static List<String> marketoC2ASyncFields = String.join(MarketingUtilClass.getMarketingSettingValuePartialMatch('marketoC2ASyncFields'),',')
        .replaceAll(' ', '')
        .split(',');
    public static List<String> personContactC2ASyncFields = String.join(MarketingUtilClass.getMarketingSettingValuePartialMatch('personContactC2ASyncFields'),',')
        .replaceAll(' ', '')
        .split(',');
    public static List<String> C2APersonLeadSyncFields = String.join(MarketingUtilClass.getMarketingSettingValuePartialMatch('C2APersonLeadSyncFields'),',')
        .replaceAll(' ', '')
        .split(',');
    
    @testSetup static void setupMethod(){
        
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        
        //create account
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        // Create contact
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'test@akamai.com.invalid';
        insert con;
        
        //Create Marketo Lead
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead l = new Lead();
        l.RecordTypeId = akamaiRecordTypeId;
        l.email = 'testml@akamai.com.invalid';
        l.Status = 'New';
        l.firstname = 'Test';
        l.lastname = 'Test2';
        l.Associated_Account__c = acc.Id;
        l.Company = 'Test Company';
        l.Product_Line__c = 'Media';
        l.Country = 'India';
        l.State = 'Karnataka';
        insert l;
    }
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    public static String fetchFirstPicklistValue(String objectType, String fieldName){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> entry = fieldMap.get(fieldName).getDescribe().getPicklistValues();
        return entry[0].getValue();
        
    }
    static testmethod void testCTACreationOnLead(){
        Lead ml = [Select Id,Lead_Qualification_Stage__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        //testing cta creation
        Test.startTest();
        ml.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update ml;
        List<Lead> al = [Select Id,Parent_Lead__c from Lead where Parent_Lead__c = :ml.Id];
        System.assert(!al.isEmpty(),'CTA was not created');
        // testing cta creation when an open cta exists as a result no new cta should be created
        ml.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
        update ml;
        List<Lead> al1 = [Select Id,Parent_Lead__c from Lead where Parent_Lead__c = :ml.Id];
        System.assert(al1.size()<2,'CTA got created although an open cta exists');  
        Test.stopTest();
    }
    
    static testmethod void testCTACreationOnContact(){
        Contact con = [Select Id,Lead_Qualification_Stage__c from Contact where email = 'test@akamai.com.invalid' limit 1];
        //testing cta creation
        Test.startTest();
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update con;
        List<Lead> al = [Select Id,Associated_Contact__c from Lead where Associated_Contact__c = :con.Id];
        System.assert(!al.isEmpty(),'CTA was not created');
        // testing cta creation when an open cta exists as a result no new cta should be created
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
        update con;
        List<Lead> al1 = [Select Id,Associated_Contact__c from Lead where Associated_Contact__c = :con.Id];
        System.assert(al1.size()<2,'CTA got created although an open cta exists');  
        Test.stopTest();
    }
    
    static testmethod void testCTAConversionSyncMode(){
        Lead ml = [Select Id,RecordTypeId,Lead_Qualification_Stage__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        Test.startTest();
        ml.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update ml;
        //converting cta
        Lead al = [Select Id,OwnerId,Status,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Associated_Contact__c,Associated_Opportunity__c from Lead where Parent_Lead__c = :ml.Id];
        try{
            al.Lead_Qualification_Status__c = 'Converted';
            update al;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('ANUM'), 'Anum Qualification was completed.');
            
        }
        al.Authority__c = 'test data for completing anum values';
        al.Need__c = 'test data for completing anum values';
        al.Urgency__c = 'test data for completing anum values';
        al.Money__c = 'test data for completing anum values';
        al.ANUM_Description__c = 'test data for completing anum values';
        al.Lead_Qualification_Status__c = 'Converted';
        update al;
        Lead convertedal = [Select Id,Status,Lead_Qualification_Stage__c,Lead_Qualification_Status__c,Associated_Contact__c,Associated_Opportunity__c from Lead where Parent_Lead__c = :ml.Id];
        System.assert(convertedal.Status == 'Converted', 'CTA did not Convert');
        System.assert(convertedal.Associated_Opportunity__c != null, 'CTA did not Convert');
        System.assert(convertedal.Associated_Contact__c != null, 'CTA did not Convert');
        try{
            al.Lead_Qualification_Status__c = 'Converted';
            update al;
        }
        catch(Exception ex){
            System.assert(ex.getMessage().contains('You cannot edit a converted lead'),'CTA was edited after conversion');
        }
        Test.stopTest();
    }
    
    static testmethod void testCTACreationWithOpenAndClosedOpportunityOnContact(){
        Lead ml = [Select Id,Convert_to_Opportunity__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        Test.startTest();
        ml.Convert_to_Opportunity__c = true;
        update ml;
        Lead ml1 = [Select Id,convertedContactID,Marketo_Convert_to_Contact__c,Associated_Opportunity__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        Contact con =[Select Id,Lead_Qualification_Stage__c,Associated_Opportunity__c,Buyer_Pain_Points__c from Contact where Id = :ml1.convertedContactID limit 1];
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        con.Buyer_Pain_Points__c = 'Growth';
        update con;
        OpportunityContactRole ocr = [Select OpportunityId from OpportunityContactRole where ContactId = :con.Id limit 1];
        Opportunity opp = [Select Id,adg_Buyer_Pain_Point__c from Opportunity where Id= : ocr.OpportunityId limit 1];
        System.assert(opp.adg_Buyer_Pain_Point__c == 'Growth', 'CTA was created despite of Open Opportunity');
        opp.StageName = 'Closed Lost';
        opp.Loss_Reason__c = 'Other';
        opp.Opportunity_Category__c = 'Other';
        opp.CloseDate = Date.today();
        opp.Validation_Override__c = true;
        update opp;
        //testing cta creation when no open opportunity exists on contact
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
        update con;
        List<Lead> al2 = [Select Id from Lead where Parent_Lead__c = :con.Id and status = 'New'];
        System.assert(al2.size()<2, 'New cta was not created'); 
        Test.stopTest();
    }
    
    static testmethod void testMarketoConvertToContactFlag(){
        Lead ml = [Select Id,Marketo_Convert_to_Contact__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        Test.startTest();
        //creation of contact with MarketoConvertToContact Flag set to True
        //Result = Contact should be created without an opportunity
        ml.Marketo_Convert_to_Contact__c = true;
        update ml;
        Lead ml1 = [Select Id,convertedContactID,Marketo_Convert_to_Contact__c,Associated_Opportunity__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        System.assert(ml1.convertedContactID != null, 'Contact was not created');
        System.assert(ml1.Associated_Opportunity__c == null, 'Opportunity is created');
        Test.stopTest();
    }
    
    static testmethod void testAutoConvertLeadFlag(){
        Lead ml = [Select Id,Convert_to_Opportunity__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        Test.startTest();
        //creation of contact with MarketoConvertToContact Flag set to True
        //Result = Contact should be created along with an opportunity
        ml.Convert_to_Opportunity__c  = true;
        update ml;
        Lead ml1 = [Select Id,convertedContactID,Convert_to_Opportunity__c,Associated_Opportunity__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        System.assert(ml1.convertedContactID != null, 'Contact was not created');
        Contact con = [Select Id, Associated_Opportunity__c from Contact where Id = :ml1.ConvertedContactID];
        Lead akamaiLead = [Select Id,Status from Lead where Associated_Contact__c = :con.Id];
        System.assert(akamaiLead.Status == 'Converted','CTA associated is not converted');
        System.assert(con.Associated_Opportunity__c != null, 'Opportunity is not created');
        Test.stopTest();
    }
    
    static testmethod void testCopyOverFieldsFromMarketoLeadToCTA(){
        Lead ml = [Select Id from Lead where email = 'testml@akamai.com.invalid' limit 1];
        List<String> stringTypeFields = new List<String>();
        Test.startTest();
        ml.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update ml;
        String objectType = 'Lead';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        for(String s:marketoC2ASyncFields){
            if(s != 'MobilePhone_Extension__c' && s != 'Phone_Extension__c' && s != 'Phone_Formatting_error__c') {
                Schema.DisplayType f = fieldMap.get(s).getDescribe().getType();
                if((f == Schema.DisplayType.String) || (f == Schema.DisplayType.TEXTAREA)){
                    stringTypeFields.add(s);
                    ml.put(s,generateRandomString(5));
                }else if(f == Schema.DisplayType.PICKLIST){
                    stringTypeFields.add(s);
                    ml.put(s,fetchFirstPicklistValue('Lead',s));
                }
            }    
        }
        update ml;
        String query = 'SELECT Id,Parent_Lead__c,' + String.join(stringTypeFields,',') + ' FROM Lead WHERE Parent_Lead__c = \'' + ml.Id + '\' limit 1';
        Lead al = Database.query(query);
        for(String t : stringTypeFields){
            System.assert(al.get(t) == ml.get(t),'copy over is failing from marketo to cta for field '+t+' cta value '+al.get(t)+' ml value '+ml.get(t));
        }
        Test.stopTest();
    }
    
    static testmethod void testCopyOverFieldsFromContactToCTA(){
        Contact con = [Select Id, Lead_Qualification_Stage__c from Contact where email = 'test@akamai.com.invalid' limit 1];
        List<String> stringTypeFields = new List<String>();
        Test.startTest();
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update con;
        String objectType = 'Contact';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        for(String s: personContactC2ASyncFields){
            if(s != 'MobilePhone_Extension__c' && s != 'Phone_Extension__c' && s != 'Phone_Formatting_error__c') {
                Schema.DisplayType f = fieldMap.get(s).getDescribe().getType();
                if((f == Schema.DisplayType.String) || (f == Schema.DisplayType.TEXTAREA)){
                    if(s.equalsIgnoreCase('Mailingcity')){
                        stringTypeFields.add('city');
                    }else if(s.equalsIgnoreCase('Mailingstate')){
                        stringTypeFields.add('state');
                    }else if(s.equalsIgnoreCase('Mailingstreet')){
                        stringTypeFields.add('street');
                    }else if(s.equalsIgnoreCase('Mailingcountry')){
                        stringTypeFields.add('country');
                    }else if(s.equalsIgnoreCase('MailingpostalCode')){
                        stringTypeFields.add('postalCode');
                    }else{
                        stringTypeFields.add(s);  
                    }
                    con.put(s,generateRandomString(5));
                }else if(f == Schema.DisplayType.PICKLIST){
                    stringTypeFields.add(s);
                    con.put(s,fetchFirstPicklistValue('Contact',s));
                }
            }    
        }
        update con;
        String query = 'SELECT Id,Associated_Contact__c,' + String.join(stringTypeFields,',') + ' FROM Lead WHERE Associated_Contact__c = \'' + con.Id + '\' limit 1';
        Lead al = Database.query(query);
        for(String t : stringTypeFields){
            if(t.equalsIgnoreCase('city')){
                System.assert(al.get(t) == con.MailingCity,'copy over is failing from contact to cta');
            } else if(t.equalsIgnoreCase('street')){
                System.assert(al.get(t) == con.MailingStreet,'copy over is failing from contact to cta');
            } else if(t.equalsIgnoreCase('state')){
                System.assert(al.get(t) == con.MailingState,'copy over is failing from contact to cta');
            } else if(t.equalsIgnoreCase('country')){
                System.assert(al.get(t) == con.MailingCountry,'copy over is failing from contact to cta');
            } else if(t.equalsIgnoreCase('postalCode')){
                System.assert(al.get(t) == con.MailingPostalCode,'copy over is failing from contact to cta');
            } else {
                System.assert(al.get(t) == con.get(t),'copy over is failing from contact to cta for field '+t+' cta value '+al.get(t)+' con value '+con.get(t));
            }
            
        }
        Test.stopTest();
    }
    
    static testmethod void testCopyOverFromCTAtoMarketoLead(){
        Lead ml = [Select Id,Lead_Qualification_Stage__c from Lead where email = 'testml@akamai.com.invalid' limit 1];
        List<String> stringTypeFields = new List<String>();
        Test.startTest();
        ml.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update ml;
        String queryForakamaiLeadForML = 'Select Id, Parent_Lead__c,'+ String.join(C2APersonLeadSyncFields,',')+ ' from Lead where Parent_Lead__c = \'' + ml.Id + '\' limit 1';
        Lead akamaiLeadForML = Database.query(queryForakamaiLeadForML);
        String objectType = 'Lead';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        for(String s:C2APersonLeadSyncFields){
            Schema.DisplayType f = fieldMap.get(s).getDescribe().getType();
            if((f == Schema.DisplayType.String) || (f == Schema.DisplayType.TEXTAREA)){
                stringTypeFields.add(s);
                akamaiLeadForML.put(s,generateRandomString(6));
            }else if(f == Schema.DisplayType.PICKLIST){
                stringTypeFields.add(s);
                akamaiLeadForML.put(s,fetchFirstPicklistValue('Lead',s));
            }
        }
        update akamaiLeadForML;
        String query = 'SELECT Id,email,' + String.join(stringTypeFields,',') + ' FROM Lead WHERE email = \'testml@akamai.com.invalid\' limit 1';
        Lead reQueryML = Database.query(query);
        for(String t: stringTypeFields){
            System.assert(reQueryML.get(t) == akamaiLeadforML.get(t),'copy over is failing from cta to marketo lead');
        }
        Test.stopTest();
    }
    
    static testmethod void testCopyOverFromCTAToContact(){
        Contact con = [Select Id, Lead_Qualification_Stage__c from Contact where email = 'test@akamai.com.invalid' limit 1];
        List<String> stringTypeFields = new List<String>();
        Test.startTest();
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
        update con;
        String queryForakamaiLeadForContact = 'Select Id, Associated_Contact__c,'+ String.join(C2APersonLeadSyncFields,',')+ ' from Lead where Associated_Contact__c = \'' + con.Id + '\' limit 1';
        Lead akamaiLeadForContact = Database.query(queryForakamaiLeadForContact);
        String objectType = 'Lead';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectType);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        for(String s:C2APersonLeadSyncFields){
            Schema.DisplayType f = fieldMap.get(s).getDescribe().getType();
            if((f == Schema.DisplayType.String) || (f == Schema.DisplayType.TEXTAREA)){
                if(s.equalsIgnoreCase('city')){
                    stringTypeFields.add('MailingCity');
                } else if(s.equalsIgnoreCase('street')){
                    stringTypeFields.add('Mailingstreet');
                } else if(s.equalsIgnoreCase('state')){
                    stringTypeFields.add('Mailingstate');
                } else if(s.equalsIgnoreCase('country')){
                    stringTypeFields.add('Mailingcountry');
                } else if(s.equalsIgnoreCase('postalCode')){
                    stringTypeFields.add('MailingpostalCode');
                } else {
                    stringTypeFields.add(s);
                }
                
                akamaiLeadForContact.put(s,generateRandomString(5));
            }else if(f == Schema.DisplayType.PICKLIST){
                stringTypeFields.add(s);
                akamaiLeadForContact.put(s,fetchFirstPicklistValue('Lead',s));
            }
        }
        update akamaiLeadForContact;
        String queryForContact = 'Select Id, '+ String.join(stringTypeFields,',') + ' from Contact where Id = \'' + con.Id +'\' limit 1';
        Contact reQueryContact = Database.query(queryForContact);
        for(String t: stringTypeFields){
            if(t.equalsIgnoreCase('Mailingcity')){
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.city,'copy over is failing from cta to contact'); 
            }else if(t.equalsIgnoreCase('Mailingstate')){
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.state,'copy over is failing from cta to contact'); 
            }else if(t.equalsIgnoreCase('Mailingstreet')){
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.street,'copy over is failing from cta to contact'); 
            }else if(t.equalsIgnoreCase('Mailingcountry')){
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.Country,'copy over is failing from cta to contact'); 
            }else if(t.equalsIgnoreCase('MailingpostalCode')){
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.PostalCode,'copy over is failing from cta to contact'); 
            }else{
                System.assert(reQueryContact.get(t) == akamaiLeadForContact.get(t),'copy over is failing from cta to contact'); 
            }               
        }
        Test.stopTest();
    }
    
}
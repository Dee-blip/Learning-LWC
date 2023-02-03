/**
    GsmUtilClass
    @version 1.0
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This class holds commonly used utility methods.

    @History
    --Developer           --Date            --Change
    Ali KM                31/10/2011        CR 1361999 Rename Opportunity.Installed Competitor and change logic
                                            -> getting rid of validation for Installed_Competitor__c as per request in CR.
    Lisha Murthy          11/06/2012        CR 1677658 E-Sign Oppty Validations should not fire for ADS Opportunities.
                                            -> Giving ADS Opportunities override to SS6 validation of "Product is Mandatory." and "Estimated Monthly Revenue Impact is required."
    Ali KM                27/07/2012        CR 1766000 BED and Contract Ext. Automation Update Request
                                            -> Giving SS6 Validations override to Contract Extension / BED Deferment Opportunities.
    Ali KM                03/08/2012        CR 1819048 E-Sign request should be valid only until OA.Valid Until Date.
                                            -> Disabling 'valid until date' check for Send for E-Signature.
    Ali KM                17/08/2012        CR 1521982 Credit check approval # deletion and fix related WF
                                            -> Commenting out all lines referring: Credit_Check_Approval__c field.
    Ali KM                24/08/2012        CR 1864342 - Exception - POA Document attachment Name too long.
                                            -> Generic method to trim string length to 80 chars
    Ali KM                17/08/2012        CR 1521982 Credit check approval # deletion and fix related WF
                                            -> Commenting out all lines referring: Credit_Check_Approval__c field.
    Ali KM                07/11/2012        CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                                            -> added few more util methods.
                                                - GetCustomSettingValue(param1: propertyName)
                                                - GetEmailTemplate(param1: pTemplateDeveloperName)
    Ali KM                05/Feb/2015       CR 2914599 - As a CREDIT & COLLECTIONS AGENT, when I open an account to update Credit Check Status field with value WAIVE, system should
                                            provide me provision to do it.
     Sonali Tandon       28th April 2014    CR 2919963 - Deal Reg -- Migrate Deal Reg data from one Opty to Another
                                            -Created button 'Migrate Deal Registration Information' that calls web service migrateDealRegData()
    Sneha                 02/06/2015        CR 3036341 Rename "WAIVE" under Credit Check Status field at Account level to "SECDEP WAIVE"
    Ruchika               31/12/2016        CR 3259981 Created 3 util methods: getAllCustomSettingResult, getAllCSFieldsAndQueryByType, validateEmailAddress
    Rahul                 15/4/2016         SFDC-922  Added the new mode in the CreditCheckButtonInvoke method
    Ruchika               18/May/2016       SFDC-948 - 3410551: added helper method getAccParentsInHierarchy which returns the parent accounts of passed account id
    Ruchika Sharma        29/08/2016        SFDC-1147 - identify if logged in user is a user present in pilot user permission set for new product Wizard
    Shubham Richhariya    25/09/2017        SFDC-1964 - Deal Registration Migration - migrated fields to MigrateDealRegData__mdt metadata
*/

global class GsmUtilClass {

    //SFDC-212 - rsharma
    //Map to store custom setting name and fields put in soql in method getAllCSFieldsByType
    public static Map<String,List<String>> objToFieldsQueriedMap = new Map<String,List<String>>();

    public static final String ACCOUNT_OBJECT_NAME ='Account';
    public static final String FUND_REQUEST = 'FR';
    public static final String FUND_CLAIM = 'FC';
    public static final String NUMBER_TYPE ='Number';
    public static final String String_TYPE ='String';
    public static final String NUMBER_STRING_TYPE ='NUMBER_STRING';
    public static Boolean disableLossReasonValidation = true; //SFDC-8121 Flag for disable Projectwin Validation
    // for A/B testing in test classes
    private static Map<String, Boolean> defaultSettings = new Map<String, Boolean>();
    
    @TestVisible private static void switchOffFeature(String featureName)
    {
        defaultSettings.put(featureName, false);
    }

    @TestVisible private static void switchOnFeature(String featureName)
    {
        defaultSettings.put(featureName, true);
    }


    /**
        - Generic function to trim Name to 80 chars.
    */
    public static String trimName(String pName)
    {
        String trimmedName = pName;
        if (pName.length() > 80)
        {
            String extPart;
            List<String> parts = pName.split('\\.');
            extPart = '.' +  parts[parts.size()-1];
            trimmedName = pName.substring(0, 80 - extPart.length()) + extPart;
            System.debug('newFileName=' + trimmedName);
            System.assertEquals(80, trimmedName.length());
        }
        return trimmedName;
    }

    public static Messaging.SingleEmailMessage createSingleEmail(Id whatId,Id TargetObjectId,string CcEmail,string CaseCreateTemplate,string OrgwideId)
    {
        // Example whatid is opportunity TargetObjectId is User/Contact
        boolean CcEmailflag=false;
        if(CcEmail!='')
        CcEmailflag=true;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] ccAddresses = CcEmail.split(',');
        mail.setWhatId(whatId);
        mail.setTargetObjectId(TargetObjectId);
        if(CcEmailflag==true)
            mail.setCcAddresses(ccAddresses);
        mail.setTemplateId(CaseCreateTemplate);
        if(Orgwideid != null)
            mail.setOrgWideEmailAddressId(OrgwideId);
        mail.setSaveAsActivity(false);
        return mail;
    }
    // Generates custom Email for Partner Portal purposes.
    public static Messaging.SingleEmailMessage createSingleEmail(String toAddress,String ccAddress, String Subject,String bodytext,String htmltext)
    {
        boolean CcEmailflag=false;
        if(ccAddress!='')
            CcEmailflag=true;
        String[] toAddresses = toAddress.split(',');
        String[] ccAddresses = ccAddress.split(',');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        if(CcEmailflag==true)
            mail.setCcAddresses(ccAddresses);
        mail.setPlainTextBody(bodytext);
        mail.setHtmlBody(htmltext);
        mail.setSubject(Subject);
        //mail.setOrgWideEmailAddressId(PRM_Settings__c.getInstance('Partner Portal Email Id').Value__c); //SFDC-2573
        mail.setOrgWideEmailAddressId(GsmUtilClass.getPRMSettingValue('Partner_Portal_Email_Id')); //SFDC-2573
        mail.setSaveAsActivity(false);
        return mail;
    }
    // Generates custom Emails
    public static Messaging.SingleEmailMessage createSingleEmailWithOrgId(String toAddress,String ccAddress, String Subject,String bodytext,String htmltext,string OrgwideId)
    {
        boolean CcEmailflag=false;
        if(ccAddress!='')
            CcEmailflag=true;
        String[] toAddresses = toAddress.split(',');
        String[] ccAddresses = ccAddress.split(',');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        if(CcEmailflag==true)
            mail.setCcAddresses(ccAddresses);
        mail.setPlainTextBody(bodytext);
        mail.setHtmlBody(htmltext);
        mail.setSubject(Subject);
        if(OrgwideId!='')
        mail.setOrgWideEmailAddressId(OrgwideId);
        mail.setSaveAsActivity(false);
        return mail;
    }

    public static list<string> SalesStageSixValidation(Id oppid)
    {
        return SalesStageSixValidation(oppid, 'poa');
    }

    public static list<string> SalesStageSixValidation(Id oppid, String pSource)
    {
        list<string> ErrorList= new list<string>();

        Opportunity opp = [select id,DD_CCG_Expiration_Date__c,Contract_Extension__c,BED_Change__c,Churn_No_Paper__c,No_Paper_Strategic_Opportunity__c,CCG__c,Opportunity_Revenue_Impact__c,Type,Product_Count__c,Installed_Competitor__c,Competitor__c,RecordTypeId, Opportunity_Type__c,recordtype.Developername  from Opportunity where id=:oppid];
        system.debug('Swati::'+opp.recordtype.Developername);
        
        // Added condition to skip this validation for BED Deferments & Contract Extensions.
        if(opp.Opportunity_Type__c != 'Contract Change' && opp.Product_Count__c==0 && !(String.valueOf(opp.RecordTypeId).contains(GSM_Custom_Settings__c.getInstance('GSMUtilClass#ADSRecordTypeId').Value__c)) && opp.recordtype.Developername != 'Administrative_Opportunity')
            ErrorList.add('Product is Mandatory.');

        // Added condition to skip this validation for BED Deferments & Contract Extensions.
        if(opp.Opportunity_Type__c != 'Contract Change' && opp.Opportunity_Revenue_Impact__c==null && !(String.valueOf(opp.RecordTypeId).contains(GSM_Custom_Settings__c.getInstance('GSMUtilClass#ADSRecordTypeId').Value__c)) && opp.recordtype.Developername != 'Administrative_Opportunity')
            ErrorList.add('Estimated Monthly Revenue Impact is required.');
        
        //Start SFDC-4178
        String CaseClosedStatus = GsmUtilClass.getGSMSettingValue('CaseStatusClosedValues');
        List<Case> cs = new List<Case>();
        if(opp!=null){
                    cs = [select id, status, Opportunity__c, Valid_Until_Date__c from Case where Opportunity__c = :opp.Id and RecordType.Name = 'Order Approval-Order Management'];
                }

        if(!Test.isRunningTest()){

            if(cs.size() == 0){
                ErrorList.add('No Order Management case is associated to this order approval. Create an Order Management Case in order to proceed.');
            }
            else{
                if(!CaseClosedStatus.contains(cs[0].status)){
                    ErrorList.add('Order Approval-Order Management case must have an Approved Status.');
                }
                if(Date.today() > cs[0].Valid_Until_Date__c){
                    ErrorList.add('Valid Until Date has expired. Please contact your SA Rep.');
                }
             }

         }
        //End SFDC-4178

        return ErrorList;
    }

    WebService static String CreditCheckButtonInvoke(string mode,Id Accountid)
    {
        if(!GSM_Custom_Settings__c.getValues('AccountTriggerClass#CheckCheckButton').Value__c.contains(Userinfo.getProfileId().substring(0,15)))
            return '0:You do not have privileges to Perform this operation.';
        Account acc=new Account(id=Accountid);
        acc.Validation_Override__c=true;
        acc.Credit_Check_Date__c=datetime.now().date();

        //SFDC-1556
        if(mode != null)
        {
            String creditCheckStatusSetting = getGSMSettingValue('CreditCheckStatus_'+mode);
            acc.Credit_Check_Status__c = creditCheckStatusSetting;
            //acc.Credit_Check_Approval__c='Credit Approved';
        }
        //End of SFDC-1556

        else
            return '0:Something went wrong!! Please raise a Helpdesk Ticket.';

         try
            {
                update acc;
            }
            catch (System.Dmlexception ex)
            {
                for (Integer i = 0; i < ex.getNumDml(); i++)
                {
                    return '0:'+ex.getDMLMessage(i);

                }
            }
        return '1:'+Accountid;
    }
    /**
        GetCustomSettingValue(String pPrefix, String pPropertyName)
        - Generic function to return Custom Setting values for the single Custom Setting Object model
        - Key Value pair kindda Custom Settings
    */
    public static String GetCustomSettingValue(String pPrefix, String pPropertyName)
    {
        System.debug('GetCustomSettingValue parm=' + pPrefix +'#'+pPropertyName);
        return GSM_Custom_Settings__c.getInstance(pPrefix +'#'+pPropertyName).Value__c;
    }

    /**
        GetCustomSettingValue(String pPropertyName)
        - Generic funtion to return custom setting value with 1 param received.
    */
    public static String GetCustomSettingValue(String pPropertyName)
    {
        System.debug('GetCustomSettingValue parm=' + pPropertyName);
        return GSM_Custom_Settings__c.getInstance(pPropertyName).Value__c;
    }

    //Anand Hegde - because getByName() API is not provided
    public static String getGSMSettingValue(String developerName)
    {   //SFDC-2686
        List<GSM_Settings__mdt> mdtRecord = [select Id, Value__c from GSM_Settings__mdt where DeveloperName = :developerName];
        if(mdtRecord.size() > 0)
            return mdtRecord[0].Value__c;
        else
            return null;
    }

    public static Boolean isFeatureToggleEnabledCustomMetadata(String developerName)
    {    
        if(Test.isRunningTest() && defaultSettings.containsKey(developerName))
        {
            return defaultSettings.get(developerName);
        }
        else 
        {
          //SFDC-2686
         List<FeatureToggle__mdt> mdtRecord = [select Id, Toggle__c from FeatureToggle__mdt where DeveloperName = :developerName];
         if(mdtRecord.size() > 0)
             return mdtRecord[0].Toggle__c;
         else
             return null;
        }
        
    }
    
    public static String featureToggleMsg(String developerName)
    {       //SFDC-2686
            List<FeatureToggle__mdt> mdtRecord = [select Id, Disabled_Alert_Message__c from FeatureToggle__mdt where DeveloperName = :developerName];
            if(mdtRecord.size() > 0)
                return mdtRecord[0].Disabled_Alert_Message__c;
            else 
                return null;
    }

    //Hitesh - SFDc -1469
    public static Deal_Reg_Rebate_Discount_Matrix__mdt getDealRegRebateMatrixSettingValue(String developerName)
    {
        Deal_Reg_Rebate_Discount_Matrix__mdt mdtRecord = [select Id, Deal_Reg_Rebate_Percentage__c ,Discount__c ,Discount_Status__c  from Deal_Reg_Rebate_Discount_Matrix__mdt where DeveloperName = :developerName];
        return mdtRecord;
    }

    public static String getAccountReassignSettingValue(String developerName)
    {
        Account_Reassignment_Config__mdt mdtRecord = [select Id, Value__c from Account_Reassignment_Config__mdt where DeveloperName = :developerName];
        return mdtRecord.Value__c;

    }

//Saket More
    public static String getPRMSettingValue(String developerName)
    {
        PRM_Setting__mdt mdtRecord = [select Id, Value__c from PRM_Setting__mdt where DeveloperName = :developerName];
        return mdtRecord.Value__c;
    }

    public static String getNAPSettingValue(String developerName)
    {
        NAP_Settings__mdt napRecord = [select Id, Value__c from NAP_Settings__mdt where DeveloperName = :developerName];
        return napRecord.Value__c;
    }

//Saket More
    public static Map<String, GSM_Settings__mdt> getGsmSettingValue()
    {
        Map<String, GSM_Settings__mdt > testcaseCustomSettings=new Map<String, GSM_Settings__mdt >();
        List<String> usedCustomSettingsValues = new List<String>{'User_Role','SystemAdminProfileId','ONA_User_Id'};
        list<GSM_Settings__mdt> mdtRecord = [select Id, Value__c,DeveloperName from GSM_Settings__mdt where DeveloperName in :usedCustomSettingsValues];
        for(GSM_Settings__mdt i: mdtRecord){
            testcaseCustomSettings.put(i.DeveloperName,i);
        }
        return testcaseCustomSettings;
    }

//SFDC-1395
    public static List<String> getGSMSettingValuePartialMatch(String developerName)
    {
        String query = 'select Id, Value__c from GSM_Settings__mdt where DeveloperName like \'%'+developerName+'%\'';
        List<GSM_Settings__mdt> mdtRecords = Database.query(query);
        List<String> mdtRecordList = new List<String>();
        for(GSM_Settings__mdt mdtRecord : mdtRecords){
            mdtRecordList.add(mdtRecord.Value__c);
        }

        return mdtRecordList;
        
    }

 //SFDC-2421
    public static Map<String,String> getGSMSettingValuePartialMatchMap(String developerName)
    {
        String query = 'select Id, Value__c,DeveloperName from GSM_Settings__mdt where DeveloperName like \'%'+developerName+'%\'';
        List<GSM_Settings__mdt> mdtRecords = Database.query(query);
        Map<String,String> mdtRecordMap = new Map<String,String>();
        for(GSM_Settings__mdt mdtRecord : mdtRecords){
            mdtRecordMap.put(mdtRecord.DeveloperName,mdtRecord.Value__c);
        }
        return mdtRecordMap;
    }
    
     //SFDC-1363
// Commenting this as this is not used - SFORCE-79
//    public static Map<String, MarketPlace_Product_Details__mdt> getMarketPlaceMetadataRecords()
//     {
//         Map<String, MarketPlace_Product_Details__mdt > marketPlaceMetadataRecords=new Map<String, MarketPlace_Product_Details__mdt >();
//         list<MarketPlace_Product_Details__mdt> mdtRecords = [select Id,productId__c,productName__c,List_Order__c, Default_Value__c,configuration_Description_1__c,Configuration_Description_2__c,Configuration_Description_3__c,Configuration_Description_4__c,DeveloperName from MarketPlace_Product_Details__mdt where productId__c !=null order by List_Order__c];
//         for(MarketPlace_Product_Details__mdt mpRecord: mdtRecords){
//             marketPlaceMetadataRecords.put(mpRecord.productId__c,mpRecord);
//         }
//         return marketPlaceMetadataRecords;
//     }

    //SFDC-1363
    public static List<SelectOption> getDynamicPicklist(String objOrMetadata,String objOrMetadataName,String pickListApiName,Map<String, sObject> metadataKeyToRecord){
        List<SelectOption> options = new List<SelectOption>();
        if(objOrMetadata.equalsIgnoreCase('object')){
            Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objOrMetadataName).getDescribe().fields.getMap();
            List<Schema.PicklistEntry> ple = fieldMap.get(pickListApiName).getDescribe().getPicklistValues();
            //List<String> picklistValue = new List<String>();

            for( Schema.PicklistEntry f : ple)
            {
                options.add(new SelectOption(f.getValue(), f.getLabel()));
                //picklistValue.add(f.getValue());

            }
        }
        if(objOrMetadata.equalsIgnoreCase('metadata')){
            system.debug('metadataKeyToRecord: '+metadataKeyToRecord);
            for(String picklistValue : metadataKeyToRecord.keySet()){
                system.debug(metadataKeyToRecord.get(picklistValue).get(pickListApiName));
                if(picklistValue==null)
                    options.add(new SelectOption('',(String)metadataKeyToRecord.get(picklistValue).get(pickListApiName)));
                else
                    options.add(new SelectOption(picklistValue,(String)metadataKeyToRecord.get(picklistValue).get(pickListApiName)));
            }
            system.debug('options: '+options);
        }
        return options;
    }

    /**
        GetEmailTemplateId(String pTemplateDeveloperName)
        - @param: receives 1 parameter - email template DeveloperName
        - returns EmailTemplate
    public static EmailTemplate GetEmailTemplate(String pTemplateDeveloperName)
    {
        return [Select e.TemplateType, e.TemplateStyle, e.Subject, e.Name, e.Markup, e.IsActive, e.Id, e.HtmlValue, e.FolderId,
            e.DeveloperName, e.Description, e.Body From EmailTemplate e where e.IsActive=true AND e.DeveloperName = : pTemplateDeveloperName][0];
    }


    Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    Usage: query lead and then clone it
    String soql = Utils.getCreatableFieldsSOQL('lead','id=\'00Q3000000aKwVN\'');
    lead l = (Lead)Database.query(soql);
    lead l2 = l.clone(false, true);
    insert l2;

    @author Vikas Rajkumar, 30th Jan 2012
    */
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){

        String selects = '';

        if (whereClause == null || whereClause == ''){ return null; }

        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();

        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }

        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}

        }

        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;

    }

    /**
    Returns all non managed custom settings
    @author Ruchika Sharma, 28th Dec 2015
    */
    //SFDC-212- rsharma:  CR 3259981
    public static List < DescribeSObjectResult > getAllCustomSettingResult() {
        List < DescribeSObjectResult  > sObjectResultList = new List < DescribeSObjectResult> ();
        //Integer count=0;
        for (Schema.SObjectType sObjType: Schema.getGlobalDescribe().values()) {

            DescribeSObjectResult sObjResult = sObjType.getDescribe();
            String sObjName = sObjResult.getName();
            // Fetch all custom setting objects when they does not belongs to managed package
            if (sObjResult.isCustomSetting() && sObjResult.isUpdateable() && (sObjName.countMatches('__')==1)) {
                //count++;
                sObjectResultList.add(sObjResult);
            }
        }
        // system.debug('count: '+count);
        return sObjectResultList;
    }

    /**
    Returns all fields of custom settings in a soql which macthes the type passed as parameter
    This method also creates map of custom setting name to fields put in query
    @author Ruchika Sharma, 28th Dec 2015
    CR 3259981: SFDC-212
    */
    public static Map<String,String> getAllCSFieldsAndQueryByType(List <DescribeSObjectResult> sObjectResultList,Set<Schema.DisplayType> Types){
        //Map to store custom setting name and soql
        Map<String,String> objToSoqlMap = new Map<String,String>();

        for(DescribeSObjectResult sObjResult: sObjectResultList){
            Map<String,Schema.SObjectField> mfields = sObjResult.fields.getMap();
            List<String> mfieldNameList = new List<String>();

            for(Schema.SObjectField mField: mfields.values()){
                Schema.DescribeFieldResult dfr = mField.getDescribe();
                if(Types.contains(dfr.getType())){
                    mfieldNameList.add(dfr.getName());

                }
            }
            String sObjectName = sObjResult.getName();
            String soql = 'select ' + String.join(mfieldNameList, ', ') + ' from '+ sObjectName;

            if(!objToSoqlMap.containsKey(sObjectName))
                objToSoqlMap.put(sObjResult.getName(),soql);
            if(!objToFieldsQueriedMap.containsKey(sObjectName))
                objToFieldsQueriedMap.put(sObjResult.getName(),mfieldNameList);
            // system.debug('objToSoqlMap: '+objToSoqlMap);


        }
        return objToSoqlMap;
    }
    /**
    This method validates email address with regex
    @author Ruchika Sharma, 28th Dec 2015
    CR 3259981: SFDC-212
    */
    public static Boolean validateEmailAddress(String emailAddress)
        {
            if(emailAddress.contains(',')){
                emailAddress = emailAddress.split('[,]{1}[\\s]?')[0];
            }

            String emailRegex = '(^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$)';
            Pattern MyPattern = Pattern.compile(emailRegex);

            // Instantiate a new Matcher object "MyMatcher"
            Matcher MyMatcher = MyPattern.matcher(emailAddress.toUpperCase());

            if (!MyMatcher.matches()) {
            return false;
            }
            else
            {
                return true;
            }
        }

    // Sonali Tandon- 28th April 2014- CR 2919963 - Deal Reg -- Migrate Deal Reg data from one Opty to Another
    // Saket More - 28th April 2017 - SFDC-1542 - DR -- Migrate DR data to existing opty button to include partner user.
    //Shubham Richhariya -  25/09/2017 - SFDC-1964 - Deal Registration Migration - migrated fields to MigrateDealRegData__mdt metadata
    WebService static String migrateDealRegData(Id Opptyid)
    {
        List<opportunityteammember> oppotm = new List<opportunityteammember>();
        List<opportunityteammember> InsertdupOppotm = new List<opportunityteammember>();
        List<MigrateDealRegData__mdt> mdr = [select Id,FieldsToCopy__c,DeveloperName from MigrateDealRegData__mdt where DeveloperName != 'CommonFieldsBewteenDupOppAndOpp'];
        List<MigrateDealRegData__mdt> commonMdr = [select Id,FieldsToCopy__c,DeveloperName from MigrateDealRegData__mdt where DeveloperName = 'CommonFieldsBewteenDupOppAndOpp'];

        //fields to query from opp and dupOpp
        Set<String> fieldSet = new Set<String>();

        //fields to copy from dupOpp to opp
        Set<String> commonFieldSet = new Set<String>();

        al.SoqlBuilder soqlB = null;
        String soql = null;

        Opportunity opp,dupOpp = null;


        for(MigrateDealRegData__mdt mdtObj : mdr)
        {
          fieldSet.addAll(mdtObj.FieldsToCopy__c.split(','));
        }

        for(MigrateDealRegData__mdt mdtObj : commonMdr)
        {
          fieldSet.addAll(mdtObj.FieldsToCopy__c.split(','));
          commonFieldSet.addAll(mdtObj.FieldsToCopy__c.split(','));
        }



        soqlB = new al.SoqlBuilder()
                    .selectx(fieldSet)
                    .fromx('Opportunity')
                    .wherex(new al.AndCondition()
                            .add(new al.FieldCondition('Id', al.Operator.EQUALS, Opptyid))
                           );
        soql = soqlB.toSoql();

        opp = Database.query(soql);

        if(opp.Registration_Status__c!='Approved')
          return 'This Deal Registration must be Approved before data can be migrated to another opportunity.';

        soqlB = new al.SoqlBuilder()
                    .selectx(fieldSet)
                    .fromx('Opportunity')
                    .wherex(new al.AndCondition()
                            .add(new al.FieldCondition('Id', al.Operator.EQUALS, opp.Duplicate_Opportunity__c))
                           );
        soql = soqlB.toSoql();

        dupOpp  = Database.query(soql);

        if(opp.Partner_Involved__c!= dupOpp.Partner_Involved__c)
            return 'The Partners on the two Opportunities are different and the data cannot be migrated. Please correct the problem and try again.';

        oppotm = [Select OpportunityId, TeamMemberRole, OpportunityAccessLevel, UserId from opportunityteammember where OpportunityId =: Opptyid and TeamMemberRole = 'Partner'];


        //null check
        if(!oppotm.isEmpty()){
            for(opportunityteammember opptyTeamMem : oppotm){
                opportunityteammember dupOppotm = new opportunityteammember();
                dupOppotm.TeamMemberRole = opptyTeamMem.TeamMemberRole;
                dupOppotm.OpportunityId = opp.Duplicate_Opportunity__c;
                dupOppotm.OpportunityAccessLevel = opptyTeamMem.OpportunityAccessLevel;
                dupOppotm.UserId = opptyTeamMem.UserId;
                InsertdupOppotm.add(dupOppotm);
            }
        }

        for(String key : commonFieldSet)
        {
          dupOpp.put(key.trim(), opp.get(key.trim()));
        }


        dupopp.Merged_Opportunity__c = opp.Id;
        dupopp.Migrated_DR_Date__c = Datetime.now();
        //dupOpp.Registration_Status__c = 'Migrated From DR'; //need to pick this up from picklist



        //SFDC-269: adding validation override
        dupopp.validation_override__c = true;

         try{
            update dupOpp;
            if(!oppotm.isEmpty()){
               delete oppotm;
               insert InsertdupOppotm;
            }
        }
        catch(Exception e)
        {
        String error = e.getMessage();
        return error;
        }

        return 'Deal Registration Information is successfully migrated.';

    }

    webservice static String cloneAndTiebackLead(ID Leadid, ID OpptyId){

    Opportunity updateObject;
    Id convertedRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Converted Lead').getRecordTypeId();
    for(Opportunity o:[Select id, Associated_Lead__c from Opportunity where id = :opptyId]){
        if(o != null) {updateObject = o;}
    }

    if(updateObject == null){
        return 'There was an error in retrieving this Opportunity, please contact eae-ops@akamai.com';
    }

    if (updateObject.Associated_Lead__c != null){
        return 'This Opportunity already has a lead associated with it. Please remove that association before proceeding';
    }

    String soql = GSMUtilClass.getCreatableFieldsSOQL('lead','id=\''+ leadid +'\'');
    lead l = (Lead)Database.query(soql);

    if(l == null){
        return 'Please enter a valid Lead Id';
    }

    lead l2 = l.clone(false, true);
    l2.Validation_Override__c = true;
    l2.status = 'NC Tie-Back';
    l2.RecordTypeId = convertedRecTypeId;
    System.debug(convertedRecTypeId);
    System.debug(l2.RecordTypeId);
    insert l2;
    System.debug(l2.RecordTypeId);
    updateObject.Associated_Lead__c = l2.id;

    update updateObject;

    return 'The Lead was cloned and associated to the Opportunity Successfully. Please refresh the Page to see the changes.';

    }

    /**
        isFeatureToggleEnabled(String pFeatureToggleName)
        - Generic function to return Features Toggle.Toggle status (Boolean).
    */
    public static Boolean isFeatureToggleEnabled(String pFeatureToggleName)
    {
        System.debug('isFeatureToggleEnabled parm=' + pFeatureToggleName);
        return Features_Toggle__c.getInstance(pFeatureToggleName).Toggle__c;
    }

    /**
        getFeatureToggleDisabledAlertMessage(String pFeatureToggleName)
        - Generic function to return Features Toggle.DisabledAlertMessage
    */
    public static String getFeatureToggleDisabledAlertMessage(String pFeatureToggleName)
    {
        System.debug('getFeatureToggleDisabledAlertMessage parm=' + pFeatureToggleName);
        return Features_Toggle__c.getInstance(pFeatureToggleName).Disabled_Alert_Message__c;
    }

    public static String getSalesApprovalStatus(Sales_Approved_Country__c sac)
    {
        if(sac.Is_Reselling_Allowed__c && sac.Is_Direct_Allowed__c)
        {
            return 'Both Direct and Reselling Allowed';
        }
        else if(sac.Is_Reselling_Allowed__c)
        {
            return 'Only Reselling Allowed';
        }
        else if(sac.Is_Direct_Allowed__c)
        {
            return 'Only Direct Allowed';
        }
        else
        {
            return 'Both Restricted';
        }
    }

    //SFDC-948
    /*getAccParentsInHierarchy(String ObjId, Integer level) -> takes accountid and level of hierarchy to be returned*/
   public static Map<Id,List<Id>> getAccParentsInHierarchy(List<String> objId, Integer level){
    Map<Id,List<Id>> parentHierarchy = new Map<Id,List<Id>>();
    String query ='select id,parentId,parent.parentId,parent.parent.parentId,parent.parent.parent.parentId,parent.parent.parent.parent.parentId from Account where id IN :objId';
    List<Account> sObjList= new List<Account>();
    sObjList = Database.query(query);
    system.debug('sObjList: '+sObjList);
    for(Account sObj : sObjList){
        List<Id> parentList= new List<Id>();

        if(level>=1 && sobj.parentId!=null)
            parentList.add(sobj.parentId);
        if(level>=2 && sobj.parent.parentId!=null)
            parentList.add(sobj.parent.parentId);
        if(level>=3 && sobj.parent.parent.parentId!=null)
            parentList.add(sobj.parent.parent.parentId);
        if(level>=4 && sobj.parent.parent.parent.parentId!=null)
            parentList.add(sobj.parent.parent.parent.parentId);
        if(level>=5 && sobj.parent.parent.parent.parent.parentId!=null)
            parentList.add(sobj.parent.parent.parent.parent.parentId);
        parentHierarchy.put(sObj.id,parentList);
      }
    return parentHierarchy;
    }

       public static void doDatabaseInsert(List<sObject> objectsToBeInserted, String className, String jobName, Boolean swallowDuplicateError)
    {
        Database.SaveResult[] saveRes = Database.Insert(objectsToBeInserted, false);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        Integer count = 0;
        for(Database.SaveResult result : saveres)
        {
            if(!result.isSuccess()){
                String errMessage = '';
                for(Database.Error err : result.getErrors())
                {
                    if(swallowDuplicateError && err.getMessage().containsIgnoreCase('DUPLICATE_VALUE'))
                    {
                        //swallow this error, haha!
                        System.Debug(LoggingLevel.Error, 'agh_ swallowed some');
                    }
                    else
                    {
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }


                }
                Map<String, Object> fieldsToValue = objectsToBeInserted[count].getPopulatedFieldsAsMap();
                System.Debug(LoggingLevel.Error, 'AGH_ fieldsToValue'+fieldsToValue);
                String objectState = JSON.serialize(fieldsToValue);

                Error_Log__c el = new Error_Log__c(Name=jobName, Class__c=className, Error_Message__c=errMessage , Object_State__c=objectState);
                System.debug(LoggingLevel.Error, 'AGH_ errored insert'+el);
                errorLogs.add(el);
            }
            count += 1;
        }
        // making this future to avoid mixed DML
        if(errorLogs.size()>0)
            Sawyer.saw(errorLogs, className, jobName);
    }


    // SFDC-6596 : Added this class to also return email with records that are not processed 
    public static String doDatabaseInsertWithErrorEmail(List<sObject> objectsToBeInserted, String className, String jobName, Boolean swallowDuplicateError, list<string> fieldsToCapture)
    {
        Database.SaveResult[] saveRes = Database.Insert(objectsToBeInserted, false);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        String htmlBody = '';            

        Integer count = 0;
        for(Database.SaveResult result : saveres)
        {
            if(!result.isSuccess()){
                String errMessage = '';
                for(Database.Error err : result.getErrors())
                {
                    if(swallowDuplicateError && err.getMessage().containsIgnoreCase('DUPLICATE_VALUE'))
                    {
                        //swallow this error, haha!
                        System.Debug(LoggingLevel.Error, 'agh_ swallowed some');
                    }
                    else
                    {
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }


                }
                Map<String, Object> fieldsToValue = objectsToBeInserted[count].getPopulatedFieldsAsMap();
                System.Debug(LoggingLevel.Error, 'AGH_ fieldsToValue'+fieldsToValue);
                String objectState = JSON.serialize(fieldsToValue);

                Error_Log__c el = new Error_Log__c(Name=jobName, Class__c=className, Error_Message__c=errMessage , Object_State__c=objectState);
                System.debug(LoggingLevel.Error, 'AGH_ errored insert'+el);
                errorLogs.add(el);
                htmlBody = htmlBody+'<tr>';

                for(string field : fieldsToCapture){
                    htmlBody += '<td>' + String.valueOf(fieldsToValue.get(field)) + '</td>';
                }
                htmlBody += '<td>' + errMessage + '</td></tr>';
            }
            count += 1;
        }
        if(errorLogs.size()>0)
            Sawyer.saw(errorLogs, className, jobName);

        return htmlBody;
    }

     public static void doDatabaseUpsert(List<sObject> objectsToBeUpserted, String className, String jobName, Boolean swallowDuplicateError){
         Database.UpsertResult[] saveRes = Database.upsert(objectsToBeUpserted, false);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        Integer count = 0;
        for(Database.UpsertResult result : saveres)
        {
            if(!result.isSuccess()){
                String errMessage = '';
                for(Database.Error err : result.getErrors())
                {
                    if(swallowDuplicateError && err.getMessage().containsIgnoreCase('DUPLICATE_VALUE'))
                    {
                        System.Debug(LoggingLevel.Error, 'swallowed some');
                    }
                    else
                    {
                        errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                    }


                }
                Map<String, Object> fieldsToValue = objectsToBeUpserted[count].getPopulatedFieldsAsMap();
                System.Debug(LoggingLevel.Error, 'fieldsToValue'+fieldsToValue);
                String objectState = JSON.serialize(fieldsToValue);

                Error_Log__c el = new Error_Log__c(Name=jobName, Class__c=className, Error_Message__c=errMessage , Object_State__c=objectState);
                System.debug(LoggingLevel.Error, 'errored upsert'+el);
                errorLogs.add(el);
            }
            count += 1;
        }
        if(errorLogs.size()>0)
            Sawyer.saw(errorLogs, className, jobName);
     }

     public static void doDatabaseDelete(List<sObject> recordsToBeDeleted, String className, String jobName){
            Database.DeleteResult[] drList = Database.delete(recordsToBeDeleted, false);
            Sawyer.saw(drList, className, jobName);
       }

    @future
    private static void insertErrorLogs(String errorLogJson)
    {
        List<Error_Log__c> erLogs = (List<Error_Log__c>)JSON.deserialize(errorLogJson, List<Error_Log__c>.class);
        insert erLogs;
    }

       public static void doDatabaseUpdate(List<sObject> recordsToBeUpdated, String className, String jobName)
       {
           Database.SaveResult[] saveRes = Database.Update(recordsToBeUpdated, false);
           Sawyer.saw(saveRes, recordsToBeUpdated, className, jobName);
       }


        webservice static String marketplaceContactRoleValidationOnOpportunity(Id opptyId)
        {
            //Removed below code as part of SFDC-1657
            /*List<OpportunityContactRole> listOfOpportunityContactRole = new List<OpportunityContactRole>();
            System.debug('i am wolverine');
            listOfOpportunityContactRole = [Select ContactId,OpportunityId,Role from OpportunityContactRole where Role = 'Marketplace Authorized' and OpportunityId =:opptyId];
            if(listOfOpportunityContactRole.size() == 0)
            {
                return Label.No_contact_role_of_type_MP_Authorised;
            }
            */


            if(OpportunityUtilClass.CheckCountryWarning(opptyId))
            {
                return GsmUtilClass.getGSMSettingValue('Opportunity_Country_Warning');
            }


            return null;
        }

        public static Boolean isPilotUser(String userIdd){
            //SFDC-1952
            //Product_Wizard_Pilot_User_Permission_Set
          String productWizardPermissionSetId = GsmUtilClass.getGSMSettingValue('Emri_2_0_Pilot_Users');
          if(!String.isBlank(userIdd))
          {
              String userId = userIdd.substring(0,15);
              List<PermissionSetAssignment> permissionSetAssignmentObjList = new List<PermissionSetAssignment>();
              
              //Modify below query to return all assignees for this permission set once metadata api and caching of record is done.
              permissionSetAssignmentObjList = [SELECT Assigneeid FROM PermissionSetAssignment WHERE Assigneeid= :userId AND PermissionSetId = :productWizardPermissionSetId];
              //System.debug('pilotUserString: '+pilotUserString);
              System.debug('permissionSetAssignmentObj: '+permissionSetAssignmentObjList);
              System.debug('userId: '+userId);
              if(permissionSetAssignmentObjList!=null && !permissionSetAssignmentObjList.isEmpty())
                return true;
            }
          return false;
        }

    public static Map<Id,Boolean> isPilotUser(List<Id> ownerIds){
        //SFDC-1952
        //Product_Wizard_Pilot_User_Permission_Set
      String productWizardPermissionSetId = GsmUtilClass.getGSMSettingValue('Emri_2_0_Pilot_Users');
      //String userId = UserInfo.getUserId().substring(0,15);
      List<PermissionSetAssignment> permissionSetAssignmentObjList = new List<PermissionSetAssignment>();
      Map<Id, Boolean> mapIdToPilotUser = new Map<Id, Boolean>();
      //Modify below query to return all assignees for this permission set once metadata api and caching of record is done.
      permissionSetAssignmentObjList = [SELECT Assigneeid FROM PermissionSetAssignment WHERE Assigneeid IN :ownerIds AND PermissionSetId = :productWizardPermissionSetId];
      set<Id> permissionSetAssigneId = new Set<Id>();
      for(PermissionSetAssignment psa : permissionSetAssignmentObjList)
        permissionSetAssigneId.add(psa.Assigneeid);
      //System.debug('pilotUserString: '+pilotUserString);
      System.debug('permissionSetAssignmentObj: '+permissionSetAssignmentObjList);
      System.debug('userId: '+ownerIds);
      if(permissionSetAssignmentObjList!=null && !permissionSetAssignmentObjList.isEmpty()){
            for(Id ownerId : ownerIds){
                mapIdToPilotUser.put(ownerId,false);
                //user has permission
                if(permissionSetAssigneId.contains(ownerId))
                    mapIdToPilotUser.put(ownerId,true);
            }   
        }        
      return mapIdToPilotUser;
    }

        public static Boolean isEMRIDeskUser(){
        //SFDC-1952
        //Product_Wizard_Pilot_User_Permission_Set
      String productWizardPermissionSetId = GsmUtilClass.getGSMSettingValue('Emri_2_0_EMRI_Desk_Users');
      String userId = UserInfo.getUserId().substring(0,15);
      List<PermissionSetAssignment> permissionSetAssignmentObjList = new List<PermissionSetAssignment>();

      //Modify below query to return all assignees for this permission set once metadata api and caching of record is done.
      permissionSetAssignmentObjList = [SELECT Assigneeid FROM PermissionSetAssignment WHERE Assigneeid= :userId AND PermissionSetId = :productWizardPermissionSetId];
      //System.debug('pilotUserString: '+pilotUserString);
      System.debug('permissionSetAssignmentObj: '+permissionSetAssignmentObjList);
      System.debug('userId: '+userId);
      if(permissionSetAssignmentObjList!=null && !permissionSetAssignmentObjList.isEmpty())
        return true;
      return false;
    }


      webservice static String isMP3enabled ()
        {
            if(Features_Toggle__c.getInstance('IsMP3Enabled').Toggle__c)
                return '1';
            else
                return '0';
        }
            public static String getErrorPageSettingValue(String developerName)
        {
             List<Error_Page_Setting__mdt> mdtRecord = [select Id, Value__c from Error_Page_Setting__mdt where DeveloperName = :developerName];
             if(mdtRecord.size() == 1)
                return mdtRecord[0].Value__c;
            else 
                return null;
        }

        public static Integer getNumberOfDaysToShift(Datetime dt)
        {
            Integer No_of_days_to_shift = Integer.valueOf(GSMSettings.getValue('LeadAutoRoute_NumberOfRegularDays'));
            if(dt.format('E') == 'Sat')
            {
                No_of_days_to_shift = No_of_days_to_shift + 1;
            }
            else if(dt.format('E') == 'Thu' || dt.format('E') == 'Fri')
            {
                No_of_days_to_shift = No_of_days_to_shift + 2;
            }
            return No_of_days_to_shift;
        }
    //Commenting as part of Agility
        //SFDC 1368 
    /*public static Map<String, ContactToLeadConversionCampaign__mdt> getContactConversionMetadataRecords()
    {
        Map<String,ContactToLeadConversionCampaign__mdt> contactConversionMetadataRecords=new Map<String, ContactToLeadConversionCampaign__mdt>();
        list<ContactToLeadConversionCampaign__mdt> mdtRecords = [select Id,CampaignId__c ,Campaign_Name__c ,Lead_Source__c ,DeveloperName from ContactToLeadConversionCampaign__mdt];
        for(ContactToLeadConversionCampaign__mdt mpRecord: mdtRecords){
            contactConversionMetadataRecords.put(mpRecord.DeveloperName,mpRecord);
        }
        return contactConversionMetadataRecords;
    }
    }*/

        //SFDC-1238
    //hierarchyDir - Down: all children, Up - all parents, Both
    public static Map<Id,Account> getAccCompleteHierarchy(List<String> objIds, String hierarchyDir){
        String dynamicQuery = 'Select #fields# From Account where id in :ObjIds #AddnCondition#';
        if(hierarchyDir.equalsIgnoreCase('Down') || hierarchyDir.equalsIgnoreCase('Both')){
            if(hierarchyDir.equalsIgnoreCase('Down'))
                dynamicQuery = dynamicQuery.replace('#fields#', 'id');

            dynamicQuery = dynamicQuery.replace('#AddnCondition#', 'or parentId IN :objIds or parent.ParentId IN:objIds or parent.parent.parentId IN :objIds or parent.parent.parent.parentId IN :objIds or parent.parent.parent.parent.parentId IN :objIds');
        }
        if(hierarchyDir.equalsIgnoreCase('up') || hierarchyDir.equalsIgnoreCase('Both')){
            dynamicQuery = dynamicQuery.replace('#fields#', 'id,parentId,parent.parentId,parent.parent.parentId,parent.parent.parent.parentId,parent.parent.parent.parent.parentId');
            if(hierarchyDir.equalsIgnoreCase('up'))
                dynamicQuery = dynamicQuery.replace('#AddnCondition#','');
        }


    Map<Id,Account> accInHierarchy = new Map<Id,Account>();
    system.debug('dynamicQuery: '+dynamicQuery);
    accInHierarchy = new Map<id,account>((List<account>)Database.query(dynamicQuery));
    return accInHierarchy;
    }
    //SFDC-1238
    public static List<Account> getAccCompleteHierarchy(String objId, String hierarchyDir){
        List<Id> objIds = new List<Id>();
        List<Account> accountList = new List<Account>();
        objIds.add(objId);
        Map<Id,Account> accInHierarchy = getAccCompleteHierarchy(objIds,hierarchyDir);
        for(Id accId: accInHierarchy.keySet()){
            accountList.add(accInHierarchy.get(accId));
        }
        return accountList;
    }

     // SFDC-1425 : this method gets the currency isocode of line items, converts all MRR values (custom meta data type) to the destinationCurrency
        public static List<OpportunityLineItem> genericConvertLineItemCurrencies(List<OpportunityLineItem> listOfLineItems, Set<String> sourceCurrency,String destinationCurrency, Datetime closeDate,Map<OpportunityLineItem,String> oLIToCurrencyMap)
        {

            Set<String> setOfOpportunityCurrencyCodes = new Set<String>();
            setOfOpportunityCurrencyCodes = sourceCurrency;


            Map<String, List<DatedConversionRate>> mapOfIsoCodeToDC = new Map<String, List<DatedConversionRate>>();
            List<String> mrrFields = new List<String>();
            // for(OpportunityLineItem oli : listOfLineItems)
            //   setOfOpportunityCurrencyCodes.add(mapOfOpptyIdToOpportunity.get(oli.OpportunityId).CurrencyIsoCode);

            setOfOpportunityCurrencyCodes.add(destinationCurrency);

            mrrFields = getGSMSettingValue('MRRsToConvert').split(',');
            mrrFields.add('Specialist_Projected_Monthly_Commit__c');
            System.debug('mrrFields' + mrrFields);


            for(DatedConversionRate dcr : [SELECT IsoCode, ConversionRate, NextStartDate, StartDate FROM DatedConversionRate WHERE IsoCode in :setOfOpportunityCurrencyCodes])
            {
                if(!mapOfIsoCodeToDC.containsKey(dcr.IsoCode))
                    mapOfIsoCodeToDC.put(dcr.IsoCode, new List<DatedConversionRate>());
                    mapOfIsoCodeToDC.get(dcr.IsoCode).add(dcr);
            }
            system.debug('HC dcr map '+mapOfIsoCodeToDC +'Source Currency '+setOfOpportunityCurrencyCodes);
            //for(String sourceCurrencyItem : sourceCurrency)
            //{
                for(OpportunityLineItem oli : listOfLineItems)
                {
                    //for(DatedConversionRate tempDCR : mapOfIsoCodeToDC.get(sourceCurrency))
                    for(DatedConversionRate tempDCR : mapOfIsoCodeToDC.get(oLIToCurrencyMap.get(oli)))
                    {
                        if(tempDCR.StartDate <= closeDate && tempDCR.NextStartDate > closeDate)
                        {
                            for(String mrrField : mrrFields)
                            {
                                if(oli.get(mrrField)!=null)
                                    oli.put(mrrField,(Decimal)oli.get(mrrField)/tempDCR.ConversionRate);
                                System.debug('oli.get(mrrField)' + oli.get(mrrField));
                            }

                            break;
                        }
                    }
                }
            //}

            for(DatedConversionRate destDCR: mapOfIsoCodeToDC.get(destinationCurrency))
            {
                for(OpportunityLineItem oli : listOfLineItems)
                {
                    if(destDCR.StartDate <= closeDate && destDCR.NextStartDate > closeDate)
                    {

                         for(String mrrField : mrrFields)
                        {
                            if(oli.get(mrrField)!=null)
                                oli.put(mrrField,(Decimal)oli.get(mrrField)*destDCR.ConversionRate);
                            System.debug('oli.get(mrrField)' + oli.get(mrrField));
                        }

                    }
                }
            }

            System.debug('listOfLineItems' + listOfLineItems);
            return listOfLineItems;
         }

        public static OpportunityLineItem genericConvertLineItemCurrencies(OpportunityLineItem oli, String sourceCurrency,String destinationCurrency, Datetime closeDate)
        {
            List<OpportunityLineItem> listOfLineItems = new List<OpportunityLineItem>();
            Map<OpportunityLineItem,String> oLIToSourceCurrencyMap = new Map<OpportunityLineItem,String>();
            oLIToSourceCurrencyMap.put(oli,sourceCurrency);
            Set<String> soucreCurrencySet = new Set<String>();
            soucreCurrencySet.add(sourceCurrency);
            listOfLineItems = genericConvertLineItemCurrencies(new List<OpportunityLineItem>{oli},soucreCurrencySet,destinationCurrency,closeDate,oLIToSourceCurrencyMap);
            //listOfLineItems = genericConvertLineItemCurrencies(new List<OpportunityLineItem>{oli},sourceCurrency,destinationCurrency,closeDate);

            return listOfLineItems[0];
        }


                public static List<String> getCurrencyIsoCodes ()
        {
            List<String> listOfIsoCodes = new List<String>();
            for(AggregateResult isoCode : [Select CurrencyIsoCode from PricebookEntry where isActive = true GROUP BY CurrencyIsoCode ORDER BY CurrencyIsoCode ASC])
                listOfIsoCodes.add((String)isoCode.get('CurrencyIsoCode'));

            return listOfIsoCodes;
        }

        //SFDC-1483
        public static List<Merge_Contract_PO__c> calculateRemaingFundOnPurchaseOrder(Map<Merge_Contract_PO__c,List<Invoice__c>> poToInvoiceListMap)
        {
            Map<Invoice__c,String> invoiceToCurrencyMap = new Map<Invoice__c,String>();
            List<Invoice__c> convertedInvoceList = new List<Invoice__c>();
            List<Merge_Contract_PO__c> mchPurOrdList = new List<Merge_Contract_PO__c>();
            List<Merge_Contract_PO__c> mchPurOrdUpdateList = new List<Merge_Contract_PO__c>();

            for(Merge_Contract_PO__c mchPO :poToInvoiceListMap.keySet())
            {
                Boolean currencyMismatch = false ;
                Decimal sumInvoiceValue = 0 ;

                for(Invoice__c invoiceRecord : poToInvoiceListMap.get(mchPO))
                {
                    if(invoiceRecord.CurrencyIsoCode == mchPO.CurrencyIsoCode)
                        sumInvoiceValue += invoiceRecord.Original_Amount__c;
                    else
                        currencyMismatch= true;
                }

                if(currencyMismatch){

                    for(Invoice__c invoiceRec : poToInvoiceListMap.get(mchPO))
                    {
                        invoiceToCurrencyMap.put(invoiceRec,invoiceRec.CurrencyIsoCode);
                    }

                }
                else
                    {
                        mchPO.Remaining_Fund__c = mchPO.PO_Fund__c - sumInvoiceValue;
                        if(mchPO.Remaining_Fund__c < 0 )
                            mchPO.Remaining_Fund__c = 0;
                            mchPurOrdUpdateList.add(mchPO);
                        List<Invoice__c> removedmchInvoiceList = poToInvoiceListMap.remove(mchPO);
                    }
            }
            system.debug('Maps for converion '+invoiceToCurrencyMap +' MCHPO '+poToInvoiceListMap);
            if(!invoiceToCurrencyMap.isEmpty()  && !poToInvoiceListMap.isEmpty())
                mchPurOrdList = GsmUtilClass.genericConvertContractInvoiceCurrencies(invoiceToCurrencyMap,poToInvoiceListMap);
            system.debug('After Conversion '+mchPurOrdList);
            for(Merge_Contract_PO__c mchPORec : mchPurOrdList)
                {mchPurOrdUpdateList.add(mchPORec);}

             return mchPurOrdUpdateList;
        }
        //SFDC-1483
        public static List<Merge_Contract_PO__c> genericConvertContractInvoiceCurrencies(Map<Invoice__c,String> invoiceToCurrencyMap,Map<Merge_Contract_PO__c,List<Invoice__c>> poToInvoiceListMap)
        {

            Set<String> setOfCurrencyCodes = new Set<String>();
            Set<String> setofDestinationCurrencyCodes = new Set<String>();

            for(Merge_Contract_PO__c mchPoCodeRec: poToInvoiceListMap.keySet())
            {
                setOfCurrencyCodes.add(mchPoCodeRec.CurrencyIsoCode);
            }
            for(String strSourceCodes :invoiceToCurrencyMap.values())
            {
                setOfCurrencyCodes.add(strSourceCodes);
            }
            List<Merge_Contract_PO__c> purchaseOrderItemList = new List<Merge_Contract_PO__c>();
            Date currentDate = Date.today();

            Map<String,CurrencyType> mapOfIsoCodeToDC = new Map<String,CurrencyType>();

            for(CurrencyType ctype : [Select ConversionRate,IsoCode From CurrencyType WHERE IsoCode in :setOfCurrencyCodes])
            {
                mapOfIsoCodeToDC.put(ctype.IsoCode,ctype);
            }
            for(Merge_Contract_PO__c mchPO :poToInvoiceListMap.keySet())
            {
               Decimal totalSumOriginalAmount = 0;
               if(poToInvoiceListMap.get(mchPO) != null)
              {
               for(Invoice__c invoiceRec : poToInvoiceListMap.get(mchPO))
                {
                    Decimal convertedUSDValue = 0;
                    Decimal convertedOriginalAmount = 0;
                    convertedUSDValue = (Decimal)invoiceRec.Original_Amount__c/mapOfIsoCodeToDC.get(invoiceToCurrencyMap.get(invoiceRec)).ConversionRate;
                    convertedOriginalAmount = convertedUSDValue*mapOfIsoCodeToDC.get(mchPO.CurrencyIsoCode).ConversionRate;
                    totalSumOriginalAmount +=  convertedOriginalAmount;
                }
                mchPO.Remaining_Fund__c = mchPO.PO_Fund__c - totalSumOriginalAmount;
                if(mchPO.Remaining_Fund__c < 0 )
                    mchPO.Remaining_Fund__c = 0;
                purchaseOrderItemList.add(mchPO);
            }
          }


            return purchaseOrderItemList;
         }

        //SFDC-1395
       //To Do: Make method more generic by casting value after identifying field type dynamically
       // Operator independent
       //add further extensions like order by
       public static List<sObject> doDatabaseSelect(List<String> listOfParameterNames,String sObjectName,String fieldName, String fieldValue,String fieldType, String className, String jobName)
       {
            List<sObject> listOfrecordsQueried = new List<sObject>();
            al.SoqlBuilder queryBuilder = new al.SoqlBuilder().selectx(listOfParameterNames).fromx(sObjectName);

            if(fieldName!=null){

                if(fieldType.equalsIgnoreCase('Boolean'))
                    queryBuilder.wherex(new al.FieldCondition(fieldName,Boolean.valueOf(fieldValue)));
                else
                    queryBuilder.wherex(new al.FieldCondition(fieldName,fieldValue));
            }
            String query = queryBuilder.toSoql();

            System.debug('query' +query);
            try
            {
                listOfrecordsQueried = Database.query(query);
                //Add governor limits
            }

            catch(Exception exc)
            {
                System.Debug(LoggingLevel.Error, 'SOQL_ERROR' + exc.getMessage());
                Error_Log__c elc = new Error_Log__c(Name=jobName, Class__c=className, Error_Message__c=exc.getMessage());
                insert elc;
            }
            return listOfrecordsQueried;
       }


    //SFDC-1395
    public static Set<String> getCurrencyIsoCodes (String className, String jobName)
        {
            Set<String> listOfIsoCodes = new Set<String>();
            List<String> listOfParameterNames = new List<String>{'Id'
                                                            ,'product2.Akam_Product_Id__c'
                                                            ,'currencyIsoCode'};
            //for(AggregateResult isoCode : [Select CurrencyIsoCode from PricebookEntry GROUP BY CurrencyIsoCode ORDER BY CurrencyIsoCode ASC])
            getPriceBookEntries(listOfParameterNames,'isActive','true','Boolean', className,  jobName);
            system.debug(LoggingLevel.ERROR,'priceBookEntryList: '+priceBookEntryList);
            for(PricebookEntry pricebookEntryRec: priceBookEntryList)
                listOfIsoCodes.add((String)pricebookEntryRec.get('CurrencyIsoCode'));

            return listOfIsoCodes;
        }
    //SFDC-1395
    public static Map<String,Id> getPriceBookForProduct(){
        Map<String,Id> productToPriceBookIdMap=new Map<String,Id>();
        for(PricebookEntry pbe : priceBookEntryList)
            {
                productToPriceBookIdMap.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
            }
        return productToPriceBookIdMap;
    }

    //SFDC-1395
    public static List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();
    private static Boolean dontRerunPriceBookQuery = false;
    public static void getPriceBookEntries (List<String> listOfParameterNames,String fieldName, String fieldValue, String fieldType, String className, String jobName){

        if(!dontRerunPriceBookQuery){

            //listOfParameterNames.addAll()
            priceBookEntryList = (List<PricebookEntry>)GsmUtilClass.doDatabaseSelect(listOfParameterNames,'PricebookEntry',fieldName,fieldValue,fieldType,className,jobName);
            system.debug(LoggingLevel.ERROR,'priceBookEntryList query run: '+priceBookEntryList);
        }
        dontRerunPriceBookQuery = true;
        //return priceBookEntryList;

    }

    //SFDC-1395
    public static List<SelectOption> getCurrencies(String className, String jobName)
        {
            List<SelectOption> options = new List<SelectOption>();

            for(String isoCode : GsmUtilClass.getCurrencyIsoCodes(className,  jobName))
                options.add(new SelectOption(isoCode,isoCode));

            return options;

        }
        //SFDC-1548
 public static String toSelectByFieldSet(List<FieldSetMember> fs) {
      List<String> fields = new List<String>();
      for(FieldSetMember fsm : fs) {
        fields.add(fsm.fieldPath);
      }
      return String.join(fields, ',');
    }

    public static Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }


    public static Boolean listContainsMatch(List<String> stringPatterns, String str)
    {
        for(String s : stringPatterns)
        {
            if(str.containsIgnoreCase(s.trim()))
                return true;
        }
        return false;
    }

    //SFDC-2135 - Moving code from Util class to GsmUtilClass
    public static Map<Id, Integer> getMaxSequenceForGivenAccounts(Set<Id> accountIdSet, String objectName) 
    {
        Map<Id, Integer> accountSeqMap = new Map<Id, Integer>();
        AggregateResult[] groupedResults = null;
        if (objectName == FUND_REQUEST) {
            groupedResults   = [SELECT Max(Sequence__c) seq  , Account__c accountID  FROM SFDC_MDF__c where Account__c IN : accountIdSet  group by Account__c ];
        } else if (objectName == FUND_CLAIM) {
            groupedResults   = [SELECT Max(Sequence__c) seq  , Account__c accountID  FROM SFDC_MDF_Claim__c where Account__c IN : accountIdSet  group by Account__c ];
        }

        Integer seq = 0;
        for (AggregateResult ar : groupedResults)  {
            seq = 0;
            if (ar.get('seq') != null) {
                seq = ((Decimal)ar.get('seq')).intValue();
            }
            accountSeqMap.put(((Id)ar.get('accountID')),seq );
        }
        
        return accountSeqMap;
    }

    public static Map<Id, List<SFDC_Budget__c>> getAvlBudgetForGivenAccounts(Set<Id> accountIdSet) 
    {
        Map<Id, List<SFDC_Budget__c>> accountIdToListOfBudgetsMap = new Map<Id, List<SFDC_Budget__c>>();
        SFDC_Budget__c[] listOfBudgetsForTheAccount = [select Account__c, Available_Budget__c, Fund_Claim_DeadLine__c from SFDC_Budget__c where  Fund_Request_Deadline__c >= : system.today() and (Account__c IN : accountIdSet OR Account__c = null)];
        System.debug('===listOfBudgetsForTheAccount' + listOfBudgetsForTheAccount);
        for (SFDC_Budget__c ithBudget : listOfBudgetsForTheAccount)  
        {
            if(!accountIdToListOfBudgetsMap.containsKey(ithBudget.Account__c))
            {
                accountIdToListOfBudgetsMap.put(ithBudget.Account__c, new List<SFDC_Budget__c>());
            }
            accountIdToListOfBudgetsMap.get(ithBudget.Account__c).add(ithBudget);
        }

        System.debug('===getAvlBudgetForGivenAccounts accountIdToListOfBudgetsMap ' + accountIdToListOfBudgetsMap); 

        return accountIdToListOfBudgetsMap; 
    }

    public static Date getEarliestFCDeadlineFromListOfBudgetsOrBudgetAllocations(SFDC_Budget__c[] listOfBudgets)
    {
        // set earliestFCDeadline to infinity first
        Date earliestFCDeadline = date.newinstance(9999, 12, 31); 
        if(listOfBudgets!=null && listOfBudgets.size()>0)
        {
            for(SFDC_Budget__c ithBudget : listOfBudgets)
            {
                if(ithBudget.Fund_Claim_DeadLine__c!=null && ithBudget.Fund_Claim_DeadLine__c < earliestFCDeadline)
                    earliestFCDeadline = ithBudget.Fund_Claim_DeadLine__c;
            }
        }
        return earliestFCDeadline;
    }

    public static Date getEarliestFCDeadlineFromListOfBudgetsOrBudgetAllocations(Budget_Allocation__c[] listOfBudgetAllocations)
    {
        // set earliestFCDeadline to infinity first
        Date earliestFCDeadline = date.newinstance(9999, 12, 31); 
        if(listOfBudgetAllocations!=null && listOfBudgetAllocations.size()>0)
        {
            for(Budget_Allocation__c ithBudgetAllocation : listOfBudgetAllocations)
            {
                if(ithBudgetAllocation.Budget__c!=null && ithBudgetAllocation.Budget__r.Fund_Claim_DeadLine__c < earliestFCDeadline)
                    earliestFCDeadline = ithBudgetAllocation.Budget__r.Fund_Claim_DeadLine__c;
            }
        }
        return earliestFCDeadline;
    }

    public static SFDC_Budget__c createFundBudgetGivenDetails(Account account, SFDC_Fund_Accural__c fundAccural, Map<string,string> prmMdfMap) {
        return createFundBudgetGivenDetails(account, fundAccural,prmMdfMap, null) ;
    }   
    
    public static SFDC_Budget__c createFundBudgetGivenDetails(Account account, SFDC_Fund_Accural__c fundAccural, Map<string,string> prmMdfMap, SFDC_Budget__c fundBudget) {
        if (fundBudget == null) {
            fundBudget = new SFDC_Budget__c();
        }
        fundBudget.Account__c = account.Id;
        fundBudget.Period_Revenue__c = fundAccural.Revenue__c;
        if (fundAccural.Budget_Name__c != null) {
            fundBudget.Budget_Name__c = fundAccural.Budget_Name__c;
        }
        
        if (prmMdfMap.get('MDF_Account_CO_OP_Field_Name') != null) {
            fundBudget.CoOp_Earned__c = (Decimal)account.get(prmMdfMap.get('MDF_Account_CO_OP_Field_Name').toLowerCase());
        } else {
            fundBudget.CoOp_Earned__c = (Decimal)account.get('Co_op_Percentage__c');
        }
        if (fundBudget.CoOp_Earned__c != null && fundBudget.Period_Revenue__c != null) {
            fundBudget.Amount__c = (fundAccural.Revenue__c * (fundBudget.CoOp_Earned__c/ 100));
        }
        Datetime todaysDate = datetime.now();
        if(fundAccural.Start_Earned_Date__c == null) {
            fundBudget.Start_Earned_Date__c = Datetime.newInstance(todaysDate.year(), todaysDate.month(), 1).date();
        } else {
            fundBudget.Start_Earned_Date__c = fundAccural.Start_Earned_Date__c;
        }
        if(fundAccural.End_Earned_Date__c == null) {
            Integer days = 31;
            if(todaysDate.month() == 2) {
                days = 28;
            } else {
                Integer remainder = math.mod(todaysDate.month(), 2);
                if (remainder != 0) {
                    days = 30;
                }
            }
            fundBudget.End_Earned_Date__c =Datetime.newInstance(todaysDate.year(), todaysDate.month(), days).date();
        } else {
            fundBudget.End_Earned_Date__c = fundAccural.End_Earned_Date__c;
        }
        if (prmMdfMap.get('MDF_Fund_Request_DeadLine')!= null && integer.valueof(prmMdfMap.get('MDF_Fund_Request_DeadLine')) > 0) {
            fundBudget.Fund_Request_Deadline__c = fundBudget.End_Earned_Date__c.addDays(integer.valueof(prmMdfMap.get('MDF_Fund_Request_DeadLine')));
        } else {
            fundBudget.Fund_Request_Deadline__c = fundBudget.End_Earned_Date__c;
        }
        
        if (prmMdfMap.get('MDF_Fund_Claim_DeadLine') != null && integer.valueof(prmMdfMap.get('MDF_Fund_Claim_DeadLine')) > 0) {
            fundBudget.Fund_Claim_Deadline__c = fundBudget.End_Earned_Date__c.addDays(integer.valueof(prmMdfMap.get('MDF_Fund_Claim_DeadLine')));
        } else {
            fundBudget.Fund_Claim_Deadline__c = fundBudget.End_Earned_Date__c;
        }        
        return fundBudget;
    }

    public static List<SObject> getAccountDetailsGivenNames(Set<String> accountNameSet, Map<string,string> prmMdfMap) {
        List<SObject> accountList = null; 
        try {
            String soql = 'Select Id,Name';
            if (prmMdfMap.get('MDF_Account_CO_OP_Field_Name') != null) {
                soql += ','+ prmMdfMap.get('MDF_Account_CO_OP_Field_Name').toLowerCase();
            } else {
                soql +=',Co_op_Percentage__c';
            }
            if (prmMdfMap.get('MDF_Account_Identity_Field_Name') != null) {
                if (prmMdfMap.get('MDF_Account_Identity_Field_Name').equalsIgnoreCase('Id')) {
                    soql +=  ' From Account where '+ prmMdfMap.get('MDF_Account_Identity_Field_Name') +' IN ';
                } else {
                    soql +=  ','+ prmMdfMap.get('MDF_Account_Identity_Field_Name') +' From Account where '+ prmMdfMap.get('MDF_Account_Identity_Field_Name') +' IN ';
                }
            } else {
                soql +=  ' From Account where Name IN ';
            }
            
            System.debug('soql----------->'+ soql);
            soql +=  buildInExpression(accountNameSet,prmMdfMap);
            accountList = Database.query(soql);
        } catch (Exception ex) {
            
        }
        return accountList;
    }

    public static Map<Id,SObject> getAccountDetailsGivenIds(Set<Id> accountIdSet, Map<string,string> prmMdfMap) {
        Map<Id,SObject> accountMap = new Map<Id,SObject>();
        String soql = 'Select Id,Name';
        if (prmMdfMap.get('MDF_Account_CO_OP_Field_Name') != null) {
            soql += ','+ prmMdfMap.get('MDF_Account_CO_OP_Field_Name').toLowerCase();
        } else {
            soql +=',Co_op_Percentage__c';
        }
        soql +=  ' From Account where Id IN ';
        soql +=  buildInExpression(accountIdSet);
        List<SObject> accountList = Database.query(soql);
        if (accountList != null && accountList.size() > 0) {
            for(SObject accObj : accountList) {
                accountMap.put((Id)accObj.get('Id'), accObj);
            }
        }
       return accountMap;
    }

    public static boolean isAccountIdentityNumber(String fieldName) {
        boolean isNumber = false;
        Map<String, Schema.SObjectField> accountMap = Schema.SObjectType.Account.fields.getMap();
        if (accountMap != null && accountMap.containsKey(fieldName)) {
             Schema.DescribeFieldResult identityField = accountMap.get(fieldName).getDescribe() ;
             if(identityField.getType() == Schema.DisplayType.Integer) { 
                isNumber = true;
             }
        }                
        return isNumber;
    }

    public static String buildInExpression(Set<String> accountNameSet, Map<string,string> prmMdfMap) {
        boolean isNumber = false;
        if (prmMdfMap.get('MDF_Account_Identity_Field_Name') != null) {
            isNumber = isAccountIdentityNumber(prmMdfMap.get('MDF_Account_Identity_Field_Name'));
        }
        String names = '(';
        for (String name : accountNameSet) {
            if (isNumber) {
                names += ( name + ',');
            } else {
                names += ('\'' + name + '\',');
            }
        }
        return names.substring(0,names.length() - 1) + ')';
    }

    public static String buildInExpression(Set<Id> accountNameSet) {
        String names = '(';
        for (Id name : accountNameSet) {
            names += ('\'' + name + '\',');
        }
        return names.substring(0,names.length() - 1) + ')';
    }

    public static Map<Id,SObject> getAccountRegions(Set<Id> accountIdSet, Map<string,string> prmMdfMap) {
        Map<Id,SObject> accountMap = new Map<Id,SObject>();
        if (accountIdSet != null && accountIdSet.size() > 0) {
            String soql = 'Select Id,Name';
            if (prmMdfMap.get('MDF_Account_Region_Field_Name') != null) {
                soql += ','+ prmMdfMap.get('MDF_Account_Region_Field_Name').toLowerCase();
            }
            soql +=  ' From Account where Id IN ';
            soql +=  buildInExpression(accountIdSet);
            List<SObject> accountList = Database.query(soql);
            if (accountList != null && accountList.size() > 0) {
                for(SObject accObj : accountList) {
                    accountMap.put((Id)accObj.get('Id'), accObj);
                }
            }
        }
        
        return accountMap;
    }

    public static boolean checkValidationFundRequired(SObject account, Map<string,string> prmMdfMap) {
        boolean validate = true;
        if(prmMdfMap.get('MDF_Regions_Without_Fund_Allocations') != null){
            String[] regionArray = prmMdfMap.get('MDF_Regions_Without_Fund_Allocations').split(',');  
            if (regionArray != null) {
                for (String regionName : regionArray) {
                    if (regionName.equalsIgnoreCase((String)account.get(prmMdfMap.get('MDF_Account_Region_Field_Name')))) {
                        return false;
                    }
                }
            } 
        }      
        return validate;
    }

    public static Decimal getClaimedAmtsForAGivenFundRequest(String fundRequestId) {
        AggregateResult[] groupedResults   = [Select sum(Approved_Amount__c) claimSum From SFDC_MDF_Claim__c  where Fund_Request__c = : fundRequestId];
        Decimal claimedAmount = 0;
        for (AggregateResult ar : groupedResults)  {
            if (ar.get('claimSum') != null) {
                claimedAmount = (Decimal)ar.get('claimSum');
            }
        }
        
        return claimedAmount;
    }

    public static Map<Id, Decimal> getClaimedAmtsForAGivenFundRequest(Set<Id> fundRequestIdSet) {
        Map<Id, Decimal> requestClaimedMap = new Map<Id, Decimal>();
        AggregateResult[] groupedResults   = [Select Fund_Request__c fundRequestId,sum(Approved_Amount__c) claimSum From SFDC_MDF_Claim__c  where Fund_Request__c IN : fundRequestIdSet and Status__c ='Approved' group by Fund_Request__c];
        Decimal claimedAmount = 0;
        for (AggregateResult ar : groupedResults)  {
            claimedAmount = 0;
            if (ar.get('claimSum') != null) {
                claimedAmount = (Decimal)ar.get('claimSum');
            } 
            requestClaimedMap.put(((Id)ar.get('fundRequestId')),claimedAmount);
        }
        
        return requestClaimedMap;
    }

    public static String getAccountIdentityFieldName(Map<string,string> prmMdfMap) {
        String fieldName='Name';
        if (prmMdfMap.get('MDF_Account_Identity_Field_Name') != null) {
            fieldName = prmMdfMap.get('MDF_Account_Identity_Field_Name');
        }
        return fieldName;
    }

    @future
    public static void updateFundAccuralWithAccountAndBudgetDetails(Map<String,String> fundAccuralAndAccountIdMap,Map<String,String> accountIdAndBudgetIdMap) {
        String accountId = null;
        String fundBudgetId = null;
        List<SFDC_Fund_Accural__c> updateList = new List<SFDC_Fund_Accural__c>();
        for(String fundAccuralId : fundAccuralAndAccountIdMap.KeySet()) {
            accountId =fundAccuralAndAccountIdMap.get(fundAccuralId);
            fundBudgetId = accountIdAndBudgetIdMap.get(accountId);
            updateList.add(new SFDC_Fund_Accural__c(Id=fundAccuralId,Account__c=accountId,Fund_Budget__c=fundBudgetId));
        }
        if(updateList.size() > 0) {
            update updateList;
        }
    }

    public static Decimal getFundRequestApprovedAmount(Id fundRequestId, Id fudReqAllocationsRecordId) {
        AggregateResult[] groupedResults   = [Select sum(Amount__c) approvedSum From Budget_Allocation__c  where Fund_Request__c = : fundRequestId AND RecordTypeId =: fudReqAllocationsRecordId];
        Decimal approvedAmount = 0;
        for (AggregateResult ar : groupedResults)  {
            if (ar.get('approvedSum') != null) {
                approvedAmount = (Decimal)ar.get('approvedSum');
            }
        }
        
        return approvedAmount;
    }

    public static String convertToCommunityURL(String rawURL)
    {
        //if(Network.getNetworkId()!=null && PRM_Settings__c.getInstance('PrefixCommunityName').Value__c=='TRUE') //SFDC-2573
        if(Network.getNetworkId()!=null && GsmUtilClass.getPRMSettingValue('PrefixCommunityName')=='TRUE') //SFDC-2573
        {
            rawURL = '/'+Label.Partner_Community_Name + rawURL;
        }
        return rawURL;
    }
    //End of SFDC-2135
    
    //Vivek Baidya //SFDC-2304
    public static Map<String,String> getGsmSettingKeyValue(string prefix)
    {
        Map<String,String> gsmSettingMap = new Map<String,String>();
        prefix = prefix + '%';
        String query = 'Select Id, Value__c, DeveloperName from GSM_Settings__mdt where DeveloperName like : prefix';
        List<GSM_Settings__mdt> mdtRecords = Database.query(query);
        for(GSM_Settings__mdt gsmSetting : mdtRecords){
            gsmSettingMap.put(gsmSetting.DeveloperName, gsmSetting.Value__c);
        }
        return gsmSettingMap;
    }
    
    //Vivek Baidya //SFDC-2304
    public static Map<String,String> getAccReassignmentKeyValue()
    {
        Map<String,String> accReMap = new Map<String,String>();
        for(Account_Reassignment_Config__mdt  accRe : [select Id, Value__c, DeveloperName from Account_Reassignment_Config__mdt ]){
            accReMap.put(accRe.DeveloperName, accRe.Value__c);
        }
        return accReMap;
    }

    //SFDC-2568
    public static Map<String,String> getPRMSettingKeyValue(string prefix)
    {
        Map<String,String> prmSettingMap = new Map<String,String>();
        prefix = prefix + '%';
        String query = 'Select Id, Value__c, DeveloperName from PRM_Setting__mdt where DeveloperName like : prefix';
        List<PRM_Setting__mdt> mdtRecords = Database.query(query);
        for(PRM_Setting__mdt prmSetting : mdtRecords){
            prmSettingMap.put(prmSetting.DeveloperName, prmSetting.Value__c);
        }
        return prmSettingMap;
    }

    //Start SFDC-5434
    public static void updateCustomNotes(Map<Id, Set<String>> IdToFieldSet, Map<Id, SObject> IdToSobject, String sObjectName){

        List<Custom_Notes__c> CustomNotesListToUpdate = new List<Custom_Notes__c>();

        Map <String, Object> objectToFieldMap = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('CustomNotesObjectFieldMapping'));
        Map <String, Object> fieldMappingForKeyValue = new Map <String, Object>();

        Object innerKeyValue = objectToFieldMap.get(sObjectName);
        fieldMappingForKeyValue = (Map <String, Object>)innerKeyValue;


        List<Custom_Notes__c> CustomNotesList = new List<Custom_Notes__c>();
        CustomNotesList = [Select Id, Parent_Id__c From Custom_Notes__c Where Parent_Id__c IN: IdToFieldSet.keyset()];


        for(Custom_Notes__c contentNote : CustomNotesList){
            Custom_Notes__c CNtoUpdate = new Custom_Notes__c(Id = contentNote.id );
            for(String field : IdToFieldSet.get(contentNote.Parent_Id__c)){
                CNtoUpdate.put(String.valueOf(fieldMappingForKeyValue.get(field)), IdToSobject.get(contentNote.Parent_Id__c).get(field));
            }
            CustomNotesListToUpdate.add(CNtoUpdate);

        }

        if(CustomNotesListToUpdate.size()>0){
            //update CustonNotesList;
            GsmUtilClass.doDatabaseUpdate(CustomNotesListToUpdate,'GsmUtilClass','updateCustomNotes');
        }


    }
    //End SFDC-5434

    /* vivek baidya - fetch key value type metadata */
    public static map<string,string> getKeyValueMetadata(string metadataObj, string valueField, string developerNames, boolean isAllRecords){
        map<String,String> keyValue = new map<String,String>();
        metadataObj = metadataObj.trim();
        valueField = valueField.trim();
        developerNames = developerNames.removeEndIgnoreCase(',');
        set<string> uniqueDevNames = new set<string>();
        for(string devName : developerNames.split(','))
            uniqueDevNames.add(devName.trim());
        string query = 'select developername,'+valueField+' from '+metadataObj;
        if(!isAllRecords)
            query+=' where developername in : uniqueDevNames';
        for(sObject mdt : database.query(query)) {
            keyValue.put((string)mdt.get('developername'),(string)mdt.get(valueField));
        }
        return keyValue;
    }
    
    /* vivek baidya - fetch Account_Reassignment_Reason_Code__mdt metadata */
    public static list<Account_Reassignment_Reason_Code__mdt> getReasonCodeSetting(){
        return [select Id,developerName, Approval_Required__c, Respect_Cut_off__c
                from Account_Reassignment_Reason_Code__mdt];
    }
    
    /* vivek baidya - capture transactional limits */
    public static void captureTransactionalLimits(string className,string methodName,integer heapSize,integer heapSizeLimit,integer cpuTime,integer cpuTimeLimit,integer dmlStatements,integer dmlStatementsLimit,integer emailInvocations,integer emailInvocationsLimit,integer queries,integer queriesLimit){
        string limitsDetails='';
        limitsDetails += 'Method: '+methodName+' ## ';
        limitsDetails += 'HeapSize: '+heapSize+' : HeapSize Limit: '+heapSizeLimit+' ## ';
        limitsDetails += 'CpuTime: '+cpuTime+' : CpuTime Limit: '+cpuTimeLimit+' ## ';
        limitsDetails += 'DMLStatements: '+dmlStatements+' : DMLStatements Limit: '+dmlStatementsLimit+' ## ';
        limitsDetails += 'EmailInvocations: '+emailInvocations+' : EmailInvocations Limit: '+emailInvocationsLimit+' ## ';
        limitsDetails += 'Queries: '+queries+' : Queries Limit: '+queriesLimit+' ## ';
        Error_Log__c el = new Error_Log__c(Name='TransactionalLimitsTracking', Class__c=className, Error_Message__c=limitsDetails);
        insert el;
    }
    
    public class FailureEmailClass{
        public string htmlBody='';
        public set<string> accountIds;
        public FailureEmailClass(){
            htmlBody='';
            accountIds=new set<string>();
        }
    }
    
    /* vivek baidya - do database update with failure email feature */
    public static FailureEmailClass doDatabaseUpdateWithErrorEmail(List<sObject> recordsToBeUpdated, String className, String methodName, string htmlBody, list<string> fieldsToCapture){
        Database.SaveResult[] saveRes = Database.update(recordsToBeUpdated, false);
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        Integer count = 0;
        set<string> failedAccountIds = new set<string>();
        for(Database.SaveResult result : saveRes){
            if(!result.isSuccess()){
                String errMessage = '';
                for(Database.Error err : result.getErrors())
                    errMessage += err.getMessage() + '\n';
                Map<String, Object> fieldsToValue = recordsToBeUpdated[count].getPopulatedFieldsAsMap();
                String objectState = JSON.serialize(fieldsToValue);
                Error_Log__c el = new Error_Log__c(Name=methodName, Class__c=className, Error_Message__c=errMessage , Object_State__c=objectState);
                errorLogs.add(el);
                htmlBody += '<tr>';
                for(string field : fieldsToCapture){
                    htmlBody += '<td>' + String.valueOf(fieldsToValue.get(field)) + '</td>';
                    if(field=='AccountId')
                        failedAccountIds.add(String.valueOf(fieldsToValue.get(field)));
                }
                htmlBody += '<td>' + errMessage + '</td></tr>';
            }
            count += 1;
        }
        if(errorLogs.size()>0)
            Sawyer.saw(errorLogs, className, methodName);

        FailureEmailClass emailObj = new FailureEmailClass();
        emailObj.htmlBody=htmlBody;
        emailObj.accountIds=failedAccountIds;
        return emailObj;
    }
}
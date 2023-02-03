@isTest(seeAllData=false)
public class MeddiccTriggerTestClass {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            //Account Creation
            Account acc = utilTestClass.CreateAccount('Test Account');
            insert acc;
            
            //Opportunity Creation
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
            
            //MEDDICC_Questionnaire__c Creation
            List<MEDDICC_Questionnaire__c> questions = new List<MEDDICC_Questionnaire__c>();
            for(integer i=0;i<21;i++){
                MEDDICC_Questionnaire__c q = new MEDDICC_Questionnaire__c();
                q.Question__c='Test Question';
                q.Question_Weightage__c=5;
                q.Section_Weightage__c=15;
                q.AKAM_MEDDICC_Questionnaire_ID__c='F-MEDQ-00000'+i;
                if(i>=0 && i<=2) q.Section__c='Metrics';
                if(i>=3 && i<=5){ 
                    q.Section__c='Economic Buyer';
                    q.Question__c='Eb identified';
                    if(i==3)
                    	q.AKAM_MEDDICC_Questionnaire_ID__c=GsmUtilClass.getGSMSettingValue('MEDDICC_EB_Identified');
                }
                if(i>=6 && i<=8) q.Section__c='Decision Criteria';
                if(i>=9 && i<=11) q.Section__c='Decision Process';
                if(i>=12 && i<=14) q.Section__c='Identify Pain';
                if(i>=15 && i<=17){
                    q.Section__c='Competition';
                    q.Question__c='Identified Competition';
                    if(i==15)
                    	q.AKAM_MEDDICC_Questionnaire_ID__c=GsmUtilClass.getGSMSettingValue('MEDDICC_Competition_Identified');
                }
                if(i>=18 && i<=20){
                    q.Section__c='Champion';
                    q.Question__c='Potential champion identified';
                    if(i==18)
                    	q.AKAM_MEDDICC_Questionnaire_ID__c=GsmUtilClass.getGSMSettingValue('MEDDICC_Champion_Identified');
                }
                questions.add(q);
            }
            insert questions;
        }
    }
    
    @isTest static void testCalculateSectionCompletion(){
        Opportunity oppty = [select Id,Competitor__c,Competitor_Secondary__c,Other_Competitor_Name__c from Opportunity where Name='__Test Opportunity' LIMIT 1][0];
        List<MEDDICC_Questionnaire__c> questions = [select Id from MEDDICC_Questionnaire__c];
        list<MEDDICC__c> meddiccListToInsert = new list<MEDDICC__c>();
        for(MEDDICC_Questionnaire__c q : questions){
            MEDDICC__c m = new MEDDICC__c();
            m.Opportunity__c=oppty.Id;
            m.MEDDICC_Questionnaire__c=q.Id;
            m.Question_Weightage__c=5;
            m.Section_Completion__c=50;
            meddiccListToInsert.add(m);
        }
        insert meddiccListToInsert;
        meddiccListToInsert[0].Response__c=true;
        update meddiccListToInsert[0];
        MeddiccTriggerClass.updateMeddicResponse(new List<Opportunity>{oppty});
    }
    
    @isTest static void testL2Q_UpdateMeddiccOnOCRChange(){
        Opportunity oppty = [select Id,AccountId from Opportunity where Name='__Test Opportunity' LIMIT 1][0];
        //Contact Creation;
        List<Contact> conList = new List<Contact>();
        Contact con1 = utilTestClass.CreateContact('__ Test Economic','__Test Buyer');
        con1.AccountId = oppty.AccountId;
        Contact con2 = utilTestClass.CreateContact('__ Test Champion','__Test Champion');
        con2.AccountId = oppty.AccountId;
        conList.add(con1);
        conList.add(con2);
        insert conList;
        
        List<MEDDICC_Questionnaire__c> questions = [select Id from MEDDICC_Questionnaire__c];
        list<MEDDICC__c> meddiccListToInsert = new list<MEDDICC__c>();
        for(MEDDICC_Questionnaire__c q : questions){
            MEDDICC__c m = new MEDDICC__c();
            m.Opportunity__c=oppty.Id;
            m.MEDDICC_Questionnaire__c=q.Id;
            m.Question_Weightage__c=5;
            m.Section_Completion__c=50;
            meddiccListToInsert.add(m);
        }
        insert meddiccListToInsert;
        
        //OpportunityContactRole Creation
        List<OpportunityContactRole> ocrList = new List<OpportunityContactRole>();
        OpportunityContactRole ocr1 = new OpportunityContactRole();
        ocr1.OpportunityId=oppty.Id;
        ocr1.ContactId=con1.Id;
        ocr1.Role='Economic Buyer';
        ocrList.add(ocr1);
        OpportunityContactRole ocr2 = new OpportunityContactRole();
        ocr2.OpportunityId=oppty.Id;
        ocr2.ContactId=con2.Id;
        ocr2.Role='Champion';
        ocrList.add(ocr2);
        insert ocrList;
        L2Q_UpdateMeddiccOnOCRChange j = new L2Q_UpdateMeddiccOnOCRChange();
        String sch = '0 0 0,4,8,12,16,20 ? * MON-FRI';
        System.schedule('L2Q_UpdateMeddiccOnOCRChangeTest', sch, j);
        delete questions;
    }
}
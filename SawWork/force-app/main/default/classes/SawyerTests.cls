@isTest(seeAllData = false)
public class SawyerTests
{

    static User dmlUser = new User(id=UserInfo.getUserId());
    public static boolean myTest=false;

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        test.startTest();

        insert new Beep_Rule__c(Is_Object_Default__c=false,
                C1_Field__c='Class__c',
                C1_Operator__c='TextEquals',
                C1_Match__c='Sawyer',
                C2_Field__c='CreatedDate',
                C2_Operator__c='DateTimeGreaterThan',
                C2_Match__c='2020-06-20T04:24:02.000Z',
                SobjectType__c='SawedLawg__c',
                Is_Active__c=true,
                Fingerprint__c='Class__c',
                Merge_Fields_in_Fingerprint__c='Class__c',
                Merge_Fields_in_Title__c='Class__c,Method__c',
                Beep_Title__c='Class__c.Method__c',
                Hash_Fingerprint__c=true, Order__c=0.0);

        insert new Beep_Rule__c(Is_Object_Default__c=false,
                C1_Field__c='Class__c',
                C1_Operator__c='TextEquals',
                C1_Match__c='TestingThings',
                SobjectType__c='SawedLawg__c',
                Is_Active__c=true,
                Fingerprint__c='Class__c',
                Merge_Fields_in_Fingerprint__c='Class__c',
                Merge_Fields_in_Title__c='Class__c,Method__c',
                Beep_Title__c='Class__c.Method__c',
                Hash_Fingerprint__c=true, Order__c=1.0);
            PageReference pageRef = Page.SawyerButtons;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('fromButton','Fingerprint');
            Sawyer sc= new Sawyer();
            sc.initButtons();
        Sawyer.saw(new List<Error_Log__c>{new Error_Log__c(Error_Message__c='Something something', Object_State__c='{}', RecordId__c='jfdajiodsa')}, 'TestingThings', 't1');
        Test.stopTest();
        /*
        Beep__c bp1 = [select id from Beep__c limit 1];
            ApexPages.currentPage().getParameters().put('fromButton','EraseFingerprintsOnSawedLawgs');
            ApexPages.currentPage().getParameters().put('recordId',bp1.Id);

            Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer scc2= new Sawyer();
            scc2.initButtons();
            */

    }

     static testmethod void testFingerprinting()
    {
        Test.startTest();
        List<SawedLawg__c> slUpdates = new List<SawedLawg__c>();
		for(SawedLawg__c sl : [select id,fingerprint__c,beep__c,beep_rule__c from sawedlawg__c limit 10])
        {
            sl.fingerprint__c='';
            sl.beep__c=null;
            sl.beep_rule__c=null;
          	slUpdates.add(sl);
        }

        if(slUpdates.size()>0)
            update slUpdates;

                    Test.setCurrentPageReference(Page.SawyerButtons);
                            ApexPages.currentPage().getParameters().put('fromButton','FingerprintNew');
                            ApexPages.currentPage().getParameters().put('sotype','SawedLawg__c');
            Sawyer scc2= new Sawyer();
            scc2.initButtons();
        Test.stopTest();
    }

     static testmethod void testReFingerprinting()
    {
        Test.startTest();

        Beep__c bp1 = [select id from Beep__c limit 1];

                    Test.setCurrentPageReference(Page.SawyerButtons);
            ApexPages.currentPage().getParameters().put('recordId',bp1.Id);
                            ApexPages.currentPage().getParameters().put('fromButton','Refingerprint');
            Sawyer scc2= new Sawyer();
            scc2.initButtons();
            ApexPages.currentPage().getParameters().put('recordId',bp1.Id);
                            ApexPages.currentPage().getParameters().put('fromButton','ClearLawgs');
            scc2.initButtons();
        Test.stopTest();
    }

    // Begin SFDC-8568 - Harsh Pandey
    static testmethod void testLogging_recId(){
        
        Test.startTest();
        Beep_Rule__c bp = new Beep_Rule__c(Is_Object_Default__c=true,
                SobjectType__c='SawedLawg__c',
                Is_Active__c=true,
                Fingerprint__c='Class__c',
                Merge_Fields_in_Fingerprint__c='Class__c',
                Merge_Fields_in_Title__c='Class__c,Method__c',
                Beep_Title__c='Class__c.Method__c',
                Hash_Fingerprint__c=true, Order__c=0.0);
        insert bp;
        String str ='Test_objState';
        
        try
        {
            insert new Lead();
            
        }
        catch(Exception ex)
        {
            Sawyer.saw(ex,bp.Id,str);
        }
        Test.stopTest();        
    }
    // End SFDC-8568 - Harsh Pandey
    
    static testmethod void testLogging()
    {

        Test.startTest();
        Beep_Rule__c bp = new Beep_Rule__c(Is_Object_Default__c=true,
                SobjectType__c='SawedLawg__c',
                Is_Active__c=true,
                Fingerprint__c='Class__c',
                Merge_Fields_in_Fingerprint__c='Class__c',
                Merge_Fields_in_Title__c='Class__c,Method__c',
                Beep_Title__c='Class__c.Method__c',
                Hash_Fingerprint__c=true, Order__c=0.0);
        insert bp;
        try
        {
            insert new Account();
        }
        catch(Exception ex)
        {
            Sawyer.saw(ex);
        }
        Test.stopTest();

        /*Beep__c bp1 = [select id from Beep__c limit 1];
            ApexPages.currentPage().getParameters().put('fromButton','EraseFingerprintsOnSawedLawgs');
            ApexPages.currentPage().getParameters().put('recordId',bp1.Id);*/

        Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer scc2= new Sawyer();
            scc2.initButtons();

            ApexPages.currentPage().getParameters().put('fromButton','ClearLawgs');
            /*ApexPages.currentPage().getParameters().put('recordId',bp1.Id);*/

        Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer scc3= new Sawyer();
            scc3.initButtons();

            ApexPages.currentPage().getParameters().put('fromButton','Fingerprint');
            Sawyer sc4= new Sawyer();
            sc4.initButtons();
    }

    static testmethod void testBeepButtons()
    {


        test.startTest();

        Test.setCurrentPageReference(Page.SawyerButtons);
            ApexPages.currentPage().getParameters().put('fromButton','Fingerprint');
            Sawyer sc= new Sawyer();
            sc.initButtons();
            Beep__c bp= new Beep__c(Fingerprint__c='34qu954u8954whjgr', Title__c='fdasjkl', Status__c='OPEN');
            insert bp;
            bp.Status__c='MUTED';
            update bp;
            bp.Status__c='RESOLVED';
            update bp;
             ApexPages.StandardSetController pd = new ApexPages.StandardSetController(new List<Beep__c>{bp});
            BeepExtensionController bcc = new BeepExtensionController(pd);
            bcc.runSummarization();
            bcc.standardController=null;
            bcc.runSummarization();
        Test.stopTest();
    }

    static testmethod void testErasing()
    {
        test.startTest();
        Beep__c bp1 = [select id from Beep__c limit 1];

        Test.setCurrentPageReference(Page.SawyerButtons);
            ApexPages.currentPage().getParameters().put('recordId',bp1.Id);
            ApexPages.currentPage().getParameters().put('fromButton','EraseFingerprints');
            Sawyer sc= new Sawyer();
            sc.initButtons();
        Test.stopTest();
    }
    static testmethod void testBatch()
    {


        test.startTest();
        List<SawedLawg__c> sls = [select id from SawedLawg__c];
        delete sls;

        SawedLawg__c ss = new SawedLawg__c(Class__c='TestingThings', Message_Text__c='Something something', Method__c='t1', User_ID_Text__c='005G0000003EOONIA4', Record_Id__c='jfdajiodsa');
        insert ss;

            /*
            Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Sawyer','Sawyer');
            insert testBatchJob;
            Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;
            */
        SawyerTests.myTest=true;

            SawyerBatchClass sbc = new SawyerBatchClass();
            Database.executebatch(sbc);
        Test.stopTest();
        try
        {
            delete sls;
        }
        catch(Exception exx)
        {
        Sawyer.saw(exx);
        }
    }
    static testmethod void testDelete()
    {


        test.startTest();
        List<SawedLawg__c> sls = [select id from SawedLawg__c];
        delete sls;

        Test.stopTest();
        try
        {
            delete sls;
        }
        catch(Exception exx)
        {
            Sawyer.saw(exx);
        }

        List<Account> accs = new List<Account>();
        accs.add(new Account());
        List<Database.SaveResult> saveResult = database.insert(accs,false);
        Sawyer.saw(saveResult, accs, 'SawyerTests', 'testDelete');

        List<Database.DeleteResult> dr = database.delete( sls,false);
        Sawyer.saw(dr, 'SawyerTests', 'testDelete');
    }
    static testmethod void testButtons()
    {


        test.startTest();

        insert new Beep_Rule__c(Is_Object_Default__c=true,
                SobjectType__c='SawedLawg__c',
                Is_Active__c=true,
                Fingerprint__c='Class__c',
                Merge_Fields_in_Fingerprint__c='Class__c',
                Merge_Fields_in_Title__c='Class__c,Method__c',
                Beep_Title__c='Class__c.Method__c',
                Hash_Fingerprint__c=true, Order__c=0.0);


        Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer sc= new Sawyer();
            sc.initButtons();
            Beep__c bp= new Beep__c(Fingerprint__c='34qu954u8954whjgr', Title__c='fdasjkl', Status__c='OPEN');
            insert bp;
            ApexPages.currentPage().getParameters().put('fromButton','SummarizeBeep');
            ApexPages.currentPage().getParameters().put('recordId',bp.Id);

        Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer scc= new Sawyer();
            scc.initButtons();
            bp.Status__c='MUTED';
            update bp;
            bp.Status__c='RESOLVED';
            update bp;
            ApexPages.currentPage().getParameters().put('fromButton','EraseFingerprints');
            ApexPages.currentPage().getParameters().put('recordId',bp.Id);

        Test.setCurrentPageReference(Page.SawyerButtons);
            Sawyer scc2= new Sawyer();
            scc2.initButtons();
        Test.stopTest();
    }

    static testmethod void gsmUtilMethods()
    {


        test.startTest();

        //Sawyer.saw('Testing this', (Id)'07M2f000001s3XF');
            List<Industry_Vertical_Sub_Vertical_Mapping__c> inds = new SobjectBuilder(Industry_Vertical_Sub_Vertical_Mapping__c.sObjectType)
                .count(3)
                .create()
                .getRecords();

            for(Industry_Vertical_Sub_Vertical_Mapping__c ind : inds)
            {
                ind.Vertical__c='Public Sector';
            }

            GsmUtilClass.doDatabaseUpdate(inds, 'AccountTriggerClass', 'someMethod');



        Test.stopTest();
    }
}
@isTest
public with sharing class PACE_Program2ControllerTestClass {
//    ID newID;

//    public static PACECustomSettings__c defPahseRecordType = PACECustomSettings__c.getValues('DefinitionPhaseRecordTypeName');
//    public static PACECustomSettings__c devPahseRecordType = PACECustomSettings__c.getValues('DevelopmentPhaseRecordTypeName');
//    public static PACECustomSettings__c launchPahseRecordType = PACECustomSettings__c.getValues('LaunchPhaseRecordTypeName');

//    private static User CreateUser(String pUsrAlias, String pProfile, String pRole) {
//        Profile pr = [select Id from Profile where Name =: pProfile][0];
//        UserRole role = [select Id, Name from UserRole where Name =: pRole][0];
//        User newUser = new User(alias = pUsrAlias, email = pUsrAlias + '@akamai.com', emailencodingkey = 'UTF-8', lastname = 'NewOwner', languagelocalekey = 'en_US', localesidkey = 'en_US', timezonesidkey = 'America/Los_Angeles', username = pUsrAlias + '@akamai.com', profileid = pr.Id, UserRoleId = null);
//        return newUser;
//    }



//    private static PACE_Program__c CreatePACEProgram(String name, User productManager1, User generalUser1) {

//        PACE_Program__c program = new PACE_Program__c();
//        program.Division__c = 'Media';
//        program.Product_Manager__c = productManager1.Id;
//        program.Program_Manager__c = productManager1.Id;
//        program.Program_Type__c = 'New Product';
//        program.Original_CC__c = Date.today();
//        program.Planned_CC__c = Date.today();

//        program.Version__c = '1.0';

//        return program;


//    }


//    testmethod static void getPhaseRecordsGeneric_PositiveTest() {




//        Id definitionId;
//        Id developmentId;
//        Id launchId;

//        User productManager = CreateUser('pm1', 'Product Operations', 'Worldwide');
//        insert productManager;

//        User generalUser = CreateUser('pm2', 'Sales Operations', 'Sales Operations');
//        insert generalUser;

//        User testUser = CreateUser('pm3', 'Sales Operations', 'Sales Operations');
//        insert testUser;
//        System.RunAs(testUser) {
//            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
//            insert plc;


//            PACE_Program__c testProgram = CreatePACEProgram('ipv81', productManager, generalUser);
//            insert testProgram;

//            PACE_Program2Controller programObjet = new PACE_Program2Controller();
//            Apexpages.StandardController stdController = new Apexpages.StandardController(testProgram);
//            PACE_Program2Controller programObject = new PACE_Program2Controller(stdController);

//            programObject.getPhaseRecordsGeneric();

//            Integer definitionStepno = 0;
//            Integer developmentStepno = 0;
//            Integer launchStepno = 0;
//            Integer conceptStepno = 0;


//            for (PACE_Phase__c phaseRecord: [Select Id, Name, RecordType.Name, Target_Phase_Commit_Date__c, SystemModstamp, RecordTypeId, Phase_Review_Approval_Status__c, Phase_Contract_Tolerance_Date__c, Phase_Commit_Date__c, PRB_Review_Date__c, PACE_Program__c, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Exception_Review_Date__c, CurrencyIsoCode, CreatedDate, CreatedById FROM PACE_Phase__c WHERE PACE_Program__c =: stdController.getId()]) {
//                if (phaseRecord.RecordType.Name == defPahseRecordType.Value__c) {
//                    definitionId = phaseRecord.Id;
//                } else if (phaseRecord.RecordType.Name == devPahseRecordType.Value__c) {
//                    developmentId = phaseRecord.Id;
//                } else if (phaseRecord.RecordType.Name == launchPahseRecordType.Value__c) {
//                    launchId = phaseRecord.Id;
//                }
//            }

//            //     programObject.init();
//            List < PACE_Step__c > stepRecordList = new List < PACE_Step__c > ();
//            stepRecordList = [Select Name, Id, Phase__r.Id, Phase__r.RecordType.Name From PACE_Step__c];
//            for (PACE_Step__c stepItem: stepRecordList) {

//                if (stepItem.Phase__r.Id == definitionId) {
//                    definitionStepno++;
//                } else if (stepItem.Phase__r.Id == developmentId) {
//                    developmentStepno++;
//                } else if (stepItem.Phase__r.Id == launchId) {
//                    launchStepno++;
//                }
//            }

//            System.assertEquals(definitionStepno, 6);
//            System.assertEquals(developmentStepno, 13);
//            System.assertEquals(launchStepno, 2);
//        }
//    }

//    testmethod static void uploadLink_PositiveTest()

//    {

//        User productManager = CreateUser('pm4', 'Product Operations', 'Worldwide');
//        insert productManager;

//        User generalUser = CreateUser('pm5', 'Sales Operations', 'Sales Operations');
//        insert generalUser;

//        User testUser = CreateUser('pm6', 'Sales Operations', 'Sales Operations');
//        insert testUser;
//        System.RunAs(testUser) {
//            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
//            insert plc;


//            PACE_Program__c testProgram = CreatePACEProgram('ipv81', productManager, generalUser);
//            insert testProgram;


//            Apexpages.StandardController stdController = new Apexpages.StandardController(testProgram);
//            PACE_Program2Controller programObject = new PACE_Program2Controller(stdController);

//            Id defID;
//            for (PACE_Phase__c phaseRecord: [Select Id, Name, RecordType.Name, Target_Phase_Commit_Date__c, SystemModstamp, RecordTypeId, Phase_Review_Approval_Status__c, Phase_Contract_Tolerance_Date__c, Phase_Commit_Date__c, PRB_Review_Date__c, PACE_Program__c, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Exception_Review_Date__c, CurrencyIsoCode, CreatedDate, CreatedById FROM PACE_Phase__c WHERE PACE_Program__c =: stdController.getId()]) {
//                if (phaseRecord.RecordType.Name == defPahseRecordType.Value__c) {
//                    defID = phaseRecord.Id;
//                }
//            }

//            String link = 'www.google.com';
//            String documentTitle = 'Test Document';
//            List < PACE_Step__c > stepItemList = [Select Name, Id, Phase__r.Id, Phase__r.RecordType.Name From PACE_Step__c where Phase__r.Id =: defID];
//            String url = '/apex/PACE_UploadDocument_Program';
//            PageReference pageRef = new PageReference(url);
//            pageRef.getParameters().put('id', stepItemList[0].Id);

//            test.setCurrentPageReference(pageref);

//            programObject.link = link;
//            programObject.documentTitle = documentTitle;
//            programObject.linkStepId = pageRef.getParameters().get('Id');

//            Test.startTest();

//            programObject.uploadLink();

//            List < PACE_Document_Link__c > documentLinkItemList = [Select Id, Name From PACE_Document_Link__c where Step__c =: programObject.linkStepId];

//            if (documentLinkItemList.size() > 0) {
//                System.assertEquals(documentLinkItemList.size(), 1);
//            }

//            Test.stopTest();
//        }
//    }

//    testmethod static void removeLinkMethod_PositiveTest() {

//        User productManager = CreateUser('pm7', 'Product Operations', 'Worldwide');
//        insert productManager;

//        User generalUser = CreateUser('pm8', 'Sales Operations', 'Sales Operations');
//        insert generalUser;

//        User testUser = CreateUser('pm9', 'Sales Operations', 'Sales Operations');
//        insert testUser;
//        System.RunAs(testUser) {
//            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
//            insert plc;


//            PACE_Program__c testProgram = CreatePACEProgram('ipv81', productManager, generalUser);
//            insert testProgram;


//            Apexpages.StandardController stdController = new Apexpages.StandardController(testProgram);
//            PACE_Program2Controller programObject = new PACE_Program2Controller(stdController);

//            Id defID;
//            for (PACE_Phase__c phaseRecord: [Select Id, Name, RecordType.Name, Target_Phase_Commit_Date__c, SystemModstamp, RecordTypeId, Phase_Review_Approval_Status__c, Phase_Contract_Tolerance_Date__c, Phase_Commit_Date__c, PRB_Review_Date__c, PACE_Program__c, LastModifiedDate, LastModifiedById, LastActivityDate, IsDeleted, Exception_Review_Date__c, CurrencyIsoCode, CreatedDate, CreatedById FROM PACE_Phase__c WHERE PACE_Program__c =: stdController.getId()]) {
//                if (phaseRecord.RecordType.Name == defPahseRecordType.Value__c) {
//                    defID = phaseRecord.Id;
//                }
//            }
//            List < PACE_Step__c > stepItemList = [Select Name, Id, Phase__r.Id, Phase__r.RecordType.Name From PACE_Step__c where Phase__r.Id =: defID];
//            PACE_Document_Link__c documentLink = new PACE_Document_Link__c(Document_URL__c = 'www.google.com', Name = 'Test Document', Step__c = stepItemList[0].Id);

//            String url1 = '/apex/PACE_ProgramWithTab';
//            PageReference pageRef1 = new PageReference(url1);
//            pageRef1.getParameters().put('id', stdController.getId());
//            pageRef1.getParameters().put('Id', testProgram.Id);

//            programObject.removedocumentLinkId = documentLink.Id;

//            programObject.removedFromTab = 'development';


//            //  PACE_Program__c lis = CreatePACEProgram('ipv81',productManager, generalUser);
//            // insert lis;
//            PACE_Program__c lis = new PACE_Program__c(Division__c = 'Media', Name = 'PgmName', Program_Type__c = 'New Product', Version__c = '1.0', Original_CC__c = Date.today(), Planned_CC__c = Date.today());
//            insert lis;
//            System.assertNotEquals(lis.id, null);
//            /*  lis.Name ='Rapid';
//        update lis;
//        System.assertNotEquals(lis.id, null);*/


//            Id newID;
//            List < PACE_Phase__c > stepRecordList1 = new List < PACE_Phase__c > ();
//            stepRecordList1 = [Select Id, Phase_Commit_Date__c From PACE_Phase__c where PACE_Program__c =: lis.Id];
//            for (PACE_Phase__c Phaseobj: stepRecordList1) {
//                newID = Phaseobj.Id;
//                Phaseobj.Phase_Commit_Date__c = Date.today();
//                System.assertEquals(Phaseobj.Phase_Commit_Date__c, Date.today());
//            }

//            // Update the database

//            update stepRecordList1;




//            Id definitionPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
//            //        PACE_Phase__c phaseObject = new PACE_Phase__c(PACE_Program__c = lis.Id,Phase_Commit_Date__c=date.parse('06/07/2012'));
//            //      insert phaseObject;
//            //  System.assertNotEquals(stepRecordList1.Id, null);


//            /*
 
//    integer count1= database.countQuery('select count() from PACE_Phase__c where PACE_Program__c =\''+lis.Id+'\'');
//            System.assertEquals(count1,1);
            
//            phaseObject.Phase_Commit_Date__c   =  Date.today(); 
//        update phaseObject;  
//            System.assertEquals(phaseObject.Phase_Commit_Date__c ,Date.today());
//        System.assertNotEquals(phaseObject.id, null);*/

//            // PACE_Phase__c customObject;
//            // 
//            // Test Classes should be allowed to create History

//            /*
//PACE_Phase__History customObjectHistory = new PACE_Phase__History(
//    ParentId = newID,
////  OldValue = date.parse('06/07/2012'),//field not writable
//    //NewValue = date.parse('06/07/2017'),
//    Field = 'Phase_Commit_Date__c'
//);
//            insert customObjectHistory;


            
//integer count= database.countQuery('select count() from PACE_Phase__History where ParentId =:newID');
//System.assertEquals(count,1);*/



//            system.Test.startTest();


//            Apexpages.StandardController stdController1 = new Apexpages.StandardController(lis);
//            PACE_Program2Controller launchitem = new PACE_Program2Controller(stdController1);
//            //         Apexpages.StandardController stdController1x = new Apexpages.StandardController(phaseObject);
//            //PACE_Program2Controller launchitemx = new  PACE_Program2Controller(stdController1x); 


//            system.Test.setCurrentPageReference(pageRef1);
//            PageReference removePR = programObject.removeLinkMethod();
//            List < PACE_Document_Link__c > documentLinkItemList1 = [Select Id, Name From PACE_Document_Link__c where Id =: programObject.removedocumentLinkId];
//            System.assertEquals(documentLinkItemList1.size(), 0);
//            PACE_Program2Controller programObj = new PACE_Program2Controller();
//            System.debug(stdController);




//            launchitem.getPhaseHistoryMethod();
//            launchitem.getProgramHistoryMethod();

//            List < PACE_Program__History > count = database.Query('select  ParentId,  OldValue, NewValue    From PACE_Program__History limit 1');

//            //launchitemx.getPhaseHistoryMethod();  
//            //         launchitemx.getProgramHistoryMethod();   

//            // Initialize list to be returned
//            //list<cHistories> list_ch = new list<cHistories>();

//            // Loop through all field history records
//            /*  for (PACE_Program__History fh: [select 
//                   ParentId, 
//                   OldValue, 
//                   NewValue, 
//                   IsDeleted, 
//                   Id, 
//                   Field, 
//                   CreatedDate, 
//                   CreatedById,
//                   CreatedBy.Name
//                   From PACE_Program__History 
//                       where ParentId ='a6rG0000000Gms9IAC' limit 1
//                    ]) 
//              { */
//            /*
//       System.assert(fh.getsObjectType() == AccountHistory.sObjectType);

//<!-- bunch of code in between to translate/transform data returned Then:-->

//        ch.FieldLabel = fieldName;
//        ch.fromValue = fromText;
//        ch.toValue = toText;
        
//        System.assertEquals(fieldName ,ch.FieldLabel);
//        System.assertEquals(fromText ,ch.fromValue);
//        System.assertEquals(toText, ch.toValue);
//        System.assertEquals(ch.theDate, String.valueOf(fh.createddate));
//       */
//            //  launchitem.getPhaseHistoryMethod();  
//            // launchitem.getProgramHistoryMethod();

//            //}
//            // list_ch.add(ch);    
//            //}    


//            system.Test.stopTest();
//        }



//    }
//    /*  static testMethod void History_TrackingTest(){
//         // ivision__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c
//          PACE_Program__c limitQuery = [SELECT Id, Name FROM PACE_Program__c where Name = 'PgmName'  LIMIT 1];

//          ApexPages.StandardController sc = new ApexPages.StandardController(limitQuery);
//          DetailPage det = new DetailPage(sc);

//          limitQuery.Name = 'Rapid';
//          update limitQuery;

//          PACE_Program__History objectHistory = new PACE_Program__History(ParentId = limitQuery.Id);
//          insert objectHistory;

//          List<Object__History> objectHistoryList = [select ParentId, OldValue, NewValue, IsDeleted, Id, Field, CreatedDate,                      CreatedById, CreatedBy.Name From object__History where ParentId =: limitQuery.id];
//          System.ASSERT(rmaHistoryList.size() > 0);
//          det.getHistories();

//      }*/

}
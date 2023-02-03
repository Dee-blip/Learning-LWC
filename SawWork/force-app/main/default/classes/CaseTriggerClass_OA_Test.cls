/*=====================================================================================================+
Class name          :   CaseTriggerClass_OA_Test
Author              :   Bhavesh
Created             :   12-Mar-20
Purpose             :   This class is a test class for CaseTriggerClass_OA

Last Modified   Developer   Purpose            
=============   =========   ============ 
28 Sep 2021     Jay         ESESP-6093
+=====================================================================================================*/
@isTest
public class CaseTriggerClass_OA_Test {
    @testSetup static void setup()
    {
        //SCUtilTestClass.createCustomSettingsForCase();
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        Account acc = utilTestClass.CreateAccount('Test Account123');   
        insert acc;
        Contact con = utilTestClass.CreateContact('first','Test'); 
        con.Akam_Contact_Id__c = 'F-CO-2435149';
        con.AccountId = acc.id;
        insert con;
    }
    static Approval_Details__c createApprovalDetail(String caseId, String oaId,String appreqValue){
        Approval_Details__c ad= new Approval_Details__c();
        ad.Related_To__c = caseId;
        ad.Order_Approval__c = oaId;
        ad.Approval_Requested_By__c = userinfo.getUserId();
        ad.Approval_Details_Description__c = 'test';
        ad.Business_Justification__c = 'test';
        Ad.Approval_Request__c = appReqValue;
        return ad;
    }
    static Case createCase(String recordTypeName, String randomStr){
        Account acc = utilTestClass.CreateAccount(''+randomStr+'Test Account');   
        insert acc;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        //oppty.OwnerId = Userinfo.getUserId();
        insert oppty;
        
        Order_Approval__c orderApproval = new Order_Approval__c();
        orderApproval.Associated_Opportunity__c = oppty.Id;
        insert orderApproval;
        
        Case thisCase = new Case();
        thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        thisCase.AccountId = acc.Id;
        thisCase.Opportunity__c = oppty.id;
        thisCase.Order_Approval__c = orderApproval.id;
        return thisCase;
    }
    static testmethod void validateOACaseTest()
    {
        test.startTest();
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        insert DDCase;
        Order_Approval__c oa = [Select id,CCG_Status__c from Order_Approval__c LIMIT 1];
        
        Opportunity oppty = [Select id from Opportunity LIMIT 1];
        
        Account acc1 = [Select id from Account where Name = '1Test Account'];
        Case EscCase = new Case();
        EscCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Escalations').getRecordTypeId();
        EscCase.AccountId = acc1.Id;
        EscCase.Opportunity__c = oppty.id;
        EscCase.Order_Approval__c = oa.id;
        EscCase.ParentId = DDCase.Id;
        insert EscCase;
        
        test.stopTest();
    }
    
    static testmethod void validateOACaseEscalationTest()
    {
        
        Id omProfile, ddProfile,legalProfile,enggProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal' or name = 'Engineering']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            else
                enggProfile = pf.id;
            
        }
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert ddusr;
        Case DDCase = new Case();
        
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        Opportunity opp = [Select id FROM Opportunity LIMIT 1];
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember();
        teamMember1.OpportunityId = opp.Id;
        teamMember1.OpportunityAccessLevel = 'Edit';
        teamMember1.TeamMemberRole = 'Opportunity Owner';
        teamMember1.UserId = DDusr.id;
    	insert teamMember1;
        Map<Id,Id> mapOppIDOTMId = new Map<Id,Id>();
        mapOppIDOTMId.put(opp.id,teamMember1.Id);
        Map<Id,OpportunityTeamMember> otmNewMap = new Map<Id,OpportunityTeamMember>();
        otmNewMap.put(teamMember1.id,teamMember1);
        
        DDCase.OwnerId = ddusr.id;
        insert DDCase;
        test.startTest();
        DDCase.OwnerId = ddusr.id;
        DDCase.Opportunity__c = opp.id;
        update DDCase;
        CaseTriggerClass_OA.oaCaseShareWithOTM(otmNewMap,mapOppIDOTMId,true);
        CaseTriggerClass_OA.oaCaseShareWithOTM(otmNewMap,mapOppIDOTMId,false); 
        Approval_Details__c ap1,ap2;
        
        System.runAs(ddusr){
            ap1 = CaseTriggerClass_OA_Test.createApprovalDetail(DDCase.id,DDCase.order_Approval__c,'Deal Desk Approval');
            ap1.Approval_Status__c = 'Pending';
            insert ap1;
            ap1 = [select id,name from approval_Details__c where id = :ap1.id];
            Case EscCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Escalations','2');
            EscCase.ParentId = DDCase.Id;
            escCase.Approval_Detail_ID__c = ap1.Name;
            insert EscCase;
            DDCase = [Select id,order_Approval__c from Case where id =: ddcase.id LIMIT 1];
            EscCase = [Select id,order_Approval__c from Case where id =: EscCase.id LIMIT 1];
            
            
            ap2 = CaseTriggerClass_OA_Test.createApprovalDetail(DDCase.id,EscCase.order_Approval__c,'BED Deferral');
            ap2.Approval_Status__c = 'Pending';
            insert new List<Approval_Details__c>{ap2};
        }
        
        test.stopTest();
    }
    
    static testmethod void testCustomerSegmentFldNull()
    {
        test.startTest();
        String omQueueId = [select Id,Name from Group where Name = 'OA_OM_Queue' and Type = 'Queue'].Id;
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Order Management','1');
        Account acc = [Select id from Account where name like '%Test Account' LIMIT 1];
        acc.BillingCountry = 'India';
        acc.Commercial_Segmentation__c = 'Standardized';
        update acc;
        Opportunity opp = [Select id from Opportunity LIMIT 1];
        opp.Deal_Type__c = 'Direct';
        update opp;
        try{
            insert DDCase;
        }
        Catch(Exception e){}
        System.assertEquals(0, [select id from Case LIMIT 10].size());
        acc.GST__c ='test';
        update acc;
        try{
            DDCase.OwnerId = omQueueId;
            insert DDCase;
        }
        Catch(Exception e){}
        System.assertEquals(1, [select id from Case LIMIT 10].size());
        DDCase.Status = 'Closed-Approved';
        try{
            update DDCase;
        }
        Catch(Exception e){}
        System.assertNotEquals('Closed-Approved', [select id,Status from Case LIMIT 1].Status);
        
        test.stopTest();
    }
    
    static testmethod void testCloseCaseAD()
    {
        List<SC_Order_Approval__mdt> lErrorMessages = [SELECT Value__c,MasterLabel,DeveloperName,Active__c
                                                FROM SC_Order_Approval__mdt 
                                                WHERE Active__c = TRUE
                                               ];    
        
        Map<String,String> mErrorMssgRec = new Map<String,String>();
        //Get the Map of Case RecordTypes
        map<Id, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosById();
        map<Id, string> mRecordType = new map<Id,string>();
        
        for(string varCaseRecordTypeId :mCaseRecordType.keySet()){
            mRecordType.put(varCaseRecordTypeId, mCaseRecordType.get(varCaseRecordTypeId).getName());
        }
        for(SC_Order_Approval__mdt eachMDTRec : lErrorMessages)
        {
            mErrorMssgRec.put(eachMDTRec.MasterLabel,eachMDTRec.Value__c);
        }
        Id omProfile, ddProfile,legalProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            
        }
        
     	User omusr = new User(LastName = 'LIVESTON',
                           FirstName='JASON',
                           Alias = 'jliv',
                           Email = 'jason.liveston@akamai.com',
                           Username = 'jason.liveston@akamai.com',
                           ProfileId = omProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User legalusr = new User(LastName = 'LIVESTON2',
                           FirstName='JASON1',
                           Alias = 'jliv21',
                           Email = 'jason2.liveston@akamai.com',
                           Username = 'jaso21.liveston@akamai.com',
                           ProfileId = legalProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert new List<user>{omusr,ddusr,legalusr};
        
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        DDCase.OwnerId = ddusr.id;
        
        Order_Approval__c oa = [Select id,CCG_Status__c from Order_Approval__c LIMIT 1];
        oa.CCG_Status__c = 'In Progress';
        update oa;
        Opportunity oppty = [Select id from Opportunity LIMIT 1];
        
        Account acc1 = [Select id from Account where Name = '1Test Account'];
        Case omCase = new Case();
        omCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        omCase.AccountId = acc1.Id;
        omCase.Opportunity__c = oppty.id;
        omCase.Order_Approval__c = oa.id;
        omCase.OwnerId = omusr.id;
        test.startTest();
        insert OMcase;
        System.debug('99999999999'); 
        //insert new List<Case>{DDCase,omCase,legalCase};
        omCase.ownerId = omusr.Id;
        omCase.AutoClose__c = false;
        update omcase;
        System.debug('0000000000000000');
        oppty.StageName = 'Closed Won';
        oppty.Owner__c = userinfo.getuserid();
        oppty.No_of_Contracts__c = 'test';
        oppty.Competitor__c = 'test';
        update oppty;
        System.debug('11111121321111212');
        System.runAs(omusr){
            Approval_Details__c ap1,ap2;
        	ap1 = CaseTriggerClass_OA_Test.createApprovalDetail(omcase.id,oa.id,'OM Order Approval');
            ap1.Approval_Status__c = 'Pending';
            ap2 = CaseTriggerClass_OA_Test.createApprovalDetail(omcase.id,oa.id,'OM Order Approval');
            ap2.Approval_Status__c = 'Pending';
            insert new List<Approval_Details__c>{ap1,ap2};
            ap1.Approval_Status__c = 'Approved by OM';
            ap1.Approver_Notes__c = 'tes';
            update ap1;
            System.debug('222222222222');
            omCase.Status = 'Closed-Approved';
            omCase.Validation_Override__c = true;
            omCase.AutoClose__c = true; 
            update omCase;
        }
        omcase.AutoClose__c = false;
        omCase.Validation_Override__c = false;
        CaseTriggerClass_OA.validateCloseCase(new List<ID>{omCase.id},mErrorMssgRec,new Map<ID,Case>{omCase.id=>omCase},new LIst<id>{oppty.id},mRecordType,false);
		
        test.stopTest();
        
        
    }
    
    static testmethod void testApproverChange()
    {
        Id omProfile, ddProfile,legalProfile,enggProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal' or name = 'Engineering']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            else
                enggProfile = pf.id;
            
        }
        
     	User omusr = new User(LastName = 'LIVESTON',
                           FirstName='JASON',
                           Alias = 'jliv',
                           Email = 'jason.liveston@akamai.com',
                           Username = 'jason.liveston@akamai.com',
                           ProfileId = omProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User legalusr = new User(LastName = 'LIVESTON2',
                           FirstName='JASON1',
                           Alias = 'jliv21',
                           Email = 'jason2.liveston@akamai.com',
                           Username = 'jaso21.liveston@akamai.com',
                           ProfileId = legalProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User enguser = new User(LastName = 'LIVESTasON2',
                           FirstName='JASsON1',
                           Alias = 'jlisv21',
                           Email = 'jasosn2.liveston@akamai.com',
                           Username = 'jasso21.liveston@akamai.com',
                           ProfileId = enggProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert new List<user>{omusr,ddusr,legalusr,enguser};
        test.startTest();
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        DDCase.OwnerId = ddusr.id;
        
        Order_Approval__c oa = [Select id from Order_Approval__c LIMIT 1];
        oa.ccg_Status__c = 'In Progress';
        update oa;
        Opportunity oppty = [Select id from Opportunity LIMIT 1];
        Account acc1 = [Select id from Account where Name = '1Test Account'];
        Case omCase = new Case();
        omCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        omCase.AccountId = acc1.Id;
        omCase.Opportunity__c = oppty.id;
        omCase.Order_Approval__c = oa.id;
        omCase.OwnerId = omusr.id;
        Case legalCase = new Case();
        legalCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Legal').getRecordTypeId();
        legalCase.AccountId = acc1.Id;
        legalCase.Opportunity__c = oppty.id;
        legalCase.Order_Approval__c = oa.id;
        legalCase.OwnerId = legalusr.id;
        insert new List<Case>{DDCase,omCase,legalCase};
        DDCase.OwnerId = ddusr.id;
        omCase.ownerId = omusr.Id;
        legalCase.ownerId = legalusr.id;
        update new List<Case>{DDCase,omCase,legalCase};
        
        try{
           omcase.ownerId = userinfo.getuserid();
           ddcase.ownerId = userinfo.getuserid();
           legalcase.ownerId = userinfo.getuserid();
            System.runAs(enguser){
                update new list<Case>{omcase,ddcase,legalcase};
            }
           
        } Catch(exception e ){
            
        }
        omcase.ownerId = userinfo.getuserid();
        ddcase.ownerId = userinfo.getuserid();
        legalcase.ownerId = userinfo.getuserid();
        try{
            System.runAs(omusr){
                update omCase;
            }
        } Catch(exception e ){}
        try{
            System.runAs(ddusr){
                update ddCase;
            }
        } Catch(exception e ){}
        try{
            System.runAs(legalusr){
                update legalCase;
            }
        } Catch(exception e ){}
        
		
        test.stopTest();
        
        
    }
    
    static testmethod void testReopenCase()
    {
        Id omProfile, ddProfile,legalProfile,enggProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal' or name = 'Engineering']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            else
                enggProfile = pf.id;
            
        }
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert ddusr;
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        ddCase.OwnerId = ddusr.id;
        insert DDCase;
        ddCase.OwnerId = ddusr.id;
        update DDCase;
        test.startTest();
        
        Order_Approval__c oa = [Select id from Order_Approval__c LIMIT 1];
        oa.CCG_Status__c = 'Close';
        update oa;
        /*CaseShare ddShare = new CaseShare();
        ddshare.CaseId = DDCase.Id;
        ddshare.RowCause = 'Manual';
        ddshare.UserOrGroupId = ddusr.id;
        ddshare.CaseAccessLevel = 'Edit';
        insert ddshare;*/
        System.runas(ddusr){
            
            DDCase.Status = 'Closed-Auto Approved';
            update DDCase;
        }
        Opportunity oppty = [Select id from Opportunity LIMIT 1];
        oppty.StageName = 'Closed Won';
        oppty.Owner__c = userinfo.getuserid();
        oppty.No_of_Contracts__c = 'test';
        oppty.Competitor__c = 'test';
        update oppty;
        
        DDCase.status = 'Reopened';
        DDCase.Re_open_Reason_Code__c  = 'New Request';
        update DDCase;
        test.stopTest();
        
        
    }
    
    static testmethod void testRecordTypeChange()
    {
        Id omProfile, ddProfile,legalProfile,enggProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal' or name = 'Engineering']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            else
                enggProfile = pf.id;
            
        }
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert ddusr;
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Others','1');
        ddCase.Approver__c = ddusr.id;
        ddCase.Sub_Type__c = 'Edgesuite Transition Approval';
        insert DDCase;
        test.startTest();
        try{
            String newRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            ddCase.RecordTypeId = newRT;
            ddCase.Sub_Type__c = 'Edgesuite Transition Approval';
            update DDCase;
            newRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Legal').getRecordTypeId();
            ddCase.RecordTypeId = newRT;
            ddCase.Sub_Type__c = 'Revenue Alignment';
            update DDCase;
        } Catch(Exception e){}
        
        test.stopTest();
        
        
    }
    static testmethod void testCloseCaseSendEmail()
    {
        Id omProfile, ddProfile,legalProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            
        }
        
     	User omusr = new User(LastName = 'LIVESTON',
                           FirstName='JASON',
                           Alias = 'jliv',
                           Email = 'jason.liveston@akamai.com',
                           Username = 'jason.liveston@akamai.com',
                           ProfileId = omProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User ddusr = new User(LastName = 'LIVESTON1',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.liveston@akamai.com',
                           Username = 'jason1.liveston@akamai.com',
                           ProfileId = ddProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User legalusr = new User(LastName = 'LIVESTON2',
                           FirstName='JASON1',
                           Alias = 'jliv21',
                           Email = 'jason2.liveston@akamai.com',
                           Username = 'jaso21.liveston@akamai.com',
                           ProfileId = legalProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert new List<user>{omusr,ddusr,legalusr};
        
        Case DDCase = new Case();
        DDCase = CaseTriggerClass_OA_Test.createCase('Order Approval-Deal Desk','1');
        DDCase.OwnerId = ddusr.id;
        Order_Approval__c oa = [Select id from Order_Approval__c LIMIT 1];
        oa.ccg_Status__c = 'In Progress';
        update oa;
        Opportunity oppty = [Select id from Opportunity LIMIT 1];
        Account acc1 = [Select id from Account where Name = '1Test Account'];
        Case omCase = new Case();
        omCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        omCase.AccountId = acc1.Id;
        omCase.Opportunity__c = oppty.id;
        omCase.Order_Approval__c = oa.id;
        omCase.OwnerId = omusr.id;
        insert new List<Case>{DDCase,omCase};
            test.startTest();
        omCase.ownerId = omusr.id;
        ddCase.ownerId = ddusr.id;
        update new List<Case>{DDCase,omCase};
        System.runas(ddusr){
            CaseTriggerClass_OA.checkSenderApprovingGroup(DDCase);
            DDCase.Status = 'Closed-Approved';
            DDCase.Validation_Override__c = true;
            update DDCase;
        }
        /*DDCase.OwnerId = ddusr.id;
        omCase.ownerId = omusr.Id;
        update new List<Case>{DDCase,omCase};*/
        
		
        test.stopTest();
        
        
    }

    /*
    @isTest
    public static void testClosureNotificationLogic(){
        Id omProfile, ddProfile,legalProfile,salesProfile;
        
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'SA - Manager' OR Name = 'Deal Desk' OR Name = 'Legal' OR Name ='Sales - Inside Sales']){
            if( pf.Name == 'SA - Manager')
                omProfile = pf.id;
            else if(pf.Name == 'Deal Desk')
                ddProfile = pf.Id;
            else if(pf.Name == 'Legal')
                legalProfile = pf.Id;
            else if(pf.Name == 'Sales - Inside Sales')
                salesProfile = pf.id;
        }
        
     	User omusr = new User(LastName = 'LIVESTON',
                           FirstName='JASON',
                           Alias = 'jliv',
                           Email = 'jason.liveston@akamai.com',
                           Username = 'jason.liveston@akamai.com',
                           ProfileId = omProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User salesUser = new User(LastName = 'LIVESTON1a',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.livestona@akamai.com',
                           Username = 'jason1.livestona@akamai.com',
                           ProfileId = salesProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User legalusr = new User(LastName = 'LIVESTON2',
                           FirstName='JASON1',
                           Alias = 'jliv21',
                           Email = 'jason2.liveston@akamai.com',
                           Username = 'jaso21.liveston@akamai.com',
                           ProfileId = legalProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        User salesUser2 = new User(LastName = 'LIVESTON1aa',
                           FirstName='JASON1',
                           Alias = 'jliv1',
                           Email = 'jason1.livestonaa@akamai.com',
                           Username = 'jason1.livestonaa@akamai.com',
                           ProfileId = salesProfile,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                           LocaleSidKey = 'en_US'
                           );
        insert new List<user>{omusr,salesUser,legalusr,salesUser2};
        Case legal = new Case();
        
        legal = CaseTriggerClass_OA_Test.createCase('Order Approval-Legal','1');
        Order_Approval__c oa = [Select id from Order_Approval__c LIMIT 1];
        Opportunity opp = [Select id FROM Opportunity LIMIT 1];
        Account acc1 = [Select id from Account where Name = '1Test Account'];
        Case omCase = new Case();
        omCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        omCase.AccountId = acc1.Id;
        omCase.Opportunity__c = opp.id;
        omCase.Order_Approval__c = oa.id;
        legal.Order_Approval__c = oa.id;
        test.startTest();
        opp.ownerId = salesUser.id;
        update opp;
        OpportunityTeamMember teamMember1 = new OpportunityTeamMember();
        teamMember1.OpportunityId = opp.Id;
        teamMember1.OpportunityAccessLevel = 'Edit';
        teamMember1.TeamMemberRole = 'Sales - Secondary';
        teamMember1.UserId = salesUser2.id;
    	insert teamMember1;
        System.runAs(salesUser2){
            insert new LIst<Case>{legal,omCase};
        }
        
        
       
        
        legal.OwnerId = legalusr.id;
        omCase.ownerId = omUsr.id;
        update new LIst<Case>{legal,omCase};
        CaseTriggerClass_OA.oaRecursiveCheckSendEmail = false;
        System.runAs(legalusr){
            CaseTriggerClass_OA.checkSenderApprovingGroup(legal);
            legal.Status = 'Closed-Approved';
        	update legal;
        }
        test.stopTest();
    }
     */
}
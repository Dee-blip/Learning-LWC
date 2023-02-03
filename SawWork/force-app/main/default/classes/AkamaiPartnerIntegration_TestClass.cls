/*=====================================================================================================+
    Class name          :   AkamaiPartnerIntegration_TestClass 
    Authors             :   Aditya,Akhila,Kunal & Jay
    Created             :   27-Jan-16
    Purpose             :   Initially created this test class for the purpose of covering all Microsoft Azure code.
-------------------------------------------------------------------------------------------------------
	Vamsee S 	ESESP-4019	04/02/2021	Seealldata = False
+=====================================================================================================*/

@isTest(seeAllData = False)
public class AkamaiPartnerIntegration_TestClass {
 
    static Id TechnicalRtId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
    static Id SerActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
    static Id MSActRecType = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security Activity').getRecordTypeId();    
    //static Account MSAct = [Select Id from Account where Name='Microsoft Azure' limit 1];
    
    static void createAccountAndContact()
    {
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        Account a = UtilTestClass.CreateAccount('Test Account asdf');
        insert a;
        
        Contact c = UtilTestClass.CreateContact('Test Contact','last name');
        c.email = 'asdf@asdfkkk.com';
        c.AccountId = a.Id;
        insert c;                  
        
        EB_AccountProductMap__c caseProd = new EB_AccountProductMap__c();
        caseProd.EB_Account__c = a.Id;
        caseProd.Name='akamCaseProd1';
        caseProd.EB_Product__c='akamCaseProd1';
        insert caseProd;                
    }
    
    static void createInboundProduct()
    {
        Case_Exchange_Inbound_Partner_Product__c cip = new Case_Exchange_Inbound_Partner_Product__c();
        cip.Akamai_Case_Product__c='akamCaseProd1';
        cip.Partner_Product_Id__c ='1';
        cip.RecordTypeId = Schema.SObjectType.Case_Exchange_Inbound_Partner_Product__c.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        cip.Name='name123';
        cip.Akamai_Problem__c='akamaiProblem123';
        cip.Akamai_Case_Record_Type_Name__c='Technical';
        cip.Partner_Product_Name__c='partnerProdName';
        insert cip;    
    }
    
    static void createOutboundProduct()
    {    
        Case_Exchange_Outbound_Partner_Product__c cop = new Case_Exchange_Outbound_Partner_Product__c();
        cop.Name='akamCaseOutboundProd1';
        cop.Partner_Problem_Product__c='problem_product_outbound';
        cop.Partner_Product_Id__c='1234';
        cop.Support_Topic_Id__c='5678';
        cop.Support_Topic_L1__c='supportTopicL1';   
        insert cop;
    }
    
    static String fetchInboundPayload(String type)
    {
        String payload;
        
        if(type == 'NamedInboundCaseCreation')
        {    
            //named,isautoescalation=false,with preferred details,multiple contacts
            payload = '{"Ticket":{"RequestDateTime":"2016-01-18T07:56:23.7192681Z","SystemTransactionId":"1f542ff5-11e4-4f60-b553-zzzzzzzzzzzz","Sender":{"TicketReference":"116011810077777","Id":18,"Name":"AKASolve","ConversationRoleId":11},';
            payload = payload + '"Receiver":{"TicketReference":"","Id":17,"Name":"Akamai","ConversationRoleId":12},"TrackingReference":"a705de9e-125a-4364-b028-zzzzzzzzzzzz","TicketDetails":[{"Context":"","Name":"Status","Value":"Open"},{"Context":"","Name":"Severity","Value":"1"},';
            payload = payload + '{"Context":"","Name":"Title","Value":"Test SR Service Request From Test Class"},{"Context":"","Name":"Problem Product","Value":"13491"},{"Context":"","Name":"Suporttopic","Value":"1"},{"Context":"","Name":"Problem Description","Value":"Customer LAN connection problems"},';
            payload = payload + '{"Context":"","Name":"Eligibility Key Value","Value":"3997c739-ff0c-4afc-96fa-6a04a1zzzzzz"},{"Context":"","Name":"IsAutoEscalation","Value":"False"}],"Contacts":[{"Type":"Authorized","Email":"asdf@asdfkkk.com","PreferredEmail":"pref@asdf.com","FirstName":"Tom","LastName":"Hank",';
            payload = payload + '"PhoneNumber":"1111111","PreferredPhoneNumber":"1111119","IsPrimary":true,"IsEmailEnabled":false,"LiveID":"v-niredd@microsoft.com","PUID":"","Details":[]},{"Type":"Authorized","Email":"sshan@asdf.com","PreferredEmail":"","FirstName":"Jose Luis ","LastName":"Barrera","PhoneNumber":"+-57-300-246-1419",';
            payload = payload + '"PreferredPhoneNumber":"","IsPrimary":false,"IsEmailEnabled":false,"LiveID":"jbarrera_l2cqa2_l2cqa_qa_a_abcffs@byb-television.com","PUID":"","Details":[]}],"Notes":[],"CCNotes":[{"Content":"solve-partner","Id":"5633d2b0-ed7f-45cc-a0e3-c9a041zzzzzz","PartnerCookie":"",';
            payload = payload + '"SharingLevel":2,"Type":1,"OriginatingSystemDateTime":"2016-01-18T07:56:23.2312859Z","NoteFrom":"Nithin Reddypotlapati"}],"Attachments":[],"MessageType":2},"MessageId":916}';
            return payload;
        }
        else if(type == 'InboundActivityCreation')
        {
            payload = '{   "Ticket":{   "RequestDateTime":"2015-11-17T11:08:35.4190509Z",   "SystemTransactionId":"6d6fa5b7-6b30-test-9519-zzzzzzzzzzzz",   "Sender":{   "TicketReference":"115111710091194",   "Id":18,   "Name":"SOLVE",   "ConversationRoleId":11   },   "Receiver":{   "TicketReference":"TicketReferencePlaceHolder",';
            payload = payload + '"Id":17,  "Name":"Partner", "ConversationRoleId":12   },   "TrackingReference":"ef510f9a-65b4-test-91d7-zzzzzzzzzzzz",   "CCNotes":[   {   "Content":"Case Update From MS. Started working on this Case.",   "Id":"a058c2f3-13e9-test-9875-zzzzzzzzzzzz",';
            payload = payload + '"PartnerCookie":"",   "SharingLevel":2,   "Type":2, "OriginatingSystemDateTime":"2015-11-17T11:08:32.2147886Z",   "NoteFrom":"Neha Jha"   }   ],   "MessageType":3   },   "MessageId":473   }';
            return payload;
        }    
        else if(type == 'AggregateInboundCaseCreation')   
        {
            payload = '{"Ticket":{"RequestDateTime":"2016-01-18T07:56:23.7192681Z","SystemTransactionId":"1f542ff5-11e4-4f60-b553-zzzzzzzzzzzz","Sender":{"TicketReference":"116011810077777","Id":18,"Name":"AKASolve","ConversationRoleId":11},';
            payload = payload + '"Receiver":{"TicketReference":"","Id":17,"Name":"Akamai","ConversationRoleId":12},"TrackingReference":"a705de9e-125a-4364-b028-zzzzzzzzzzzz","TicketDetails":[{"Context":"","Name":"Status","Value":"Open"},{"Context":"","Name":"Severity","Value":"1"},';
            payload = payload + '{"Context":"","Name":"Title","Value":"Test SR Service Request From Test Class"},{"Context":"","Name":"Problem Product","Value":"13491"},{"Context":"","Name":"Suporttopic","Value":"1"},{"Context":"","Name":"Problem Description","Value":"Customer LAN connection problems"},';
            payload = payload + '{"Context":"","Name":"Eligibility Key Value","Value":"3997c739-ff0c-4afc-96fa-6a04a1zzzzzz"},{"Context":"","Name":"IsAutoEscalation","Value":"True"}],"Contacts":[{"Type":"Authorized","Email":"prefkkkk@asdfggg.com","PreferredEmail":"","FirstName":"Tom","LastName":"Hank",';
            payload = payload + '"PhoneNumber":"1111111","PreferredPhoneNumber":"","IsPrimary":true,"IsEmailEnabled":false,"LiveID":"v-niredd@microsoft.com","PUID":"","Details":[]}],"Notes":[],"CCNotes":[{"Content":"solve-partner","Id":"5633d2b0-ed7f-45cc-a0e3-c9a041zzzzzz","PartnerCookie":"",';
            payload = payload + '"SharingLevel":2,"Type":1,"OriginatingSystemDateTime":"2016-01-18T07:56:23.2312859Z","NoteFrom":"Nithin Reddypotlapati"}],"Attachments":[],"MessageType":2},"MessageId":283}';
            return payload;
        }  
        return '';
     
    }    
    
    @isTest
    //Case Creation
    static void namedScenario_Test_1()
    {
        createAccountAndContact();
        test.startTest();
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('NamedInboundCaseCreation'),Partner_Request_Id__c='916',Originating_Partner_Account__c='MSAzure');
        insert inRec;
        inRec.Receipt_Status__c ='Success Receipt Sent';
        test.stopTest();
    }
    
    @isTest
    //System Updates
    static Void namedScenario_Test_2()
    {
        createAccountAndContact();
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('NamedInboundCaseCreation'),Partner_Request_Id__c='916',Originating_Partner_Account__c='MSAzure',Response_Data__c = '{"TicketReference":"F-CS-1901454", "MessageId":"14916720", "ProcessingStatus":"Success"}');
        insert inRec;
        test.startTest();
        List<Inbound_Request_Queue__c> lInboundRec = [Select Response_Data__c from Inbound_Request_Queue__c where Id=:inRec.Id limit 1];
        if(!lInboundRec.isEmpty())
        {          
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(lInboundRec[0].Response_Data__c);
            String caseId = (String) m.get('TicketReference');
            String payload = fetchInboundPayload('InboundActivityCreation').replace('TicketReferencePlaceHolder', caseId);
            Inbound_Request_Queue__c inRec2 = new Inbound_Request_Queue__c(Request_Data__c=payload,Partner_Request_Id__c='473',Originating_Partner_Account__c='MSAzure');
            insert inRec2;
            inRec2.Receipt_Status__c ='Success Receipt Sent';
            update inRec2;
            system.debug(inRec2);
        }
        test.stopTest();
    }
    
    @isTest
    //Case Creation
    static void aggregateScenario_Test_1()
    {
        createAccountAndContact();
        createInboundProduct();
        test.startTest();
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('AggregateInboundCaseCreation'),Partner_Request_Id__c='283',Originating_Partner_Account__c='MSAzure',Response_Data__c = '{"TicketReference":"F-CS-1901454", "MessageId":"14916720", "ProcessingStatus":"Success"}');
        insert inRec;
        test.stopTest();
    }
    
    //ER creation for outbound escalation, changing severity & Status on case
    @isTest
    static void outboundScenario_Test_1()
    {
        createAccountAndContact();
        createOutboundProduct();
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('NamedInboundCaseCreation'),Partner_Request_Id__c='916',Originating_Partner_Account__c='MSAzure');
        insert inRec;
        List<Inbound_Request_Queue__c> lInboundRec = [Select Request_Data__c,Response_Data__c,Partner_Request_Id__c from Inbound_Request_Queue__c where Id=:inRec.Id limit 1];
        system.debug('#####'+lInboundRec);
        if(!lInboundRec.isEmpty() && lInboundRec[0].Response_Data__c != null)
        {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(lInboundRec[0].Response_Data__c);
            String caseId = (String) m.get('TicketReference');
            List<Engagement_Request__c> lErInbound = [Select Id,Case__c from Engagement_Request__c where Case__r.Akam_Case_Id__c =:caseId limit 1];
            system.debug('$$$$$'+lErInbound);
            if(!lErInbound.isEmpty())
            {
                lErInbound[0].Request_Status__c='Closed';
                update lErInbound[0];
                Id ERtype = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation to Microsoft Azure').getRecordTypeId();            
                test.startTest();
                //create an ER to create outbound record
                    Engagement_Request__c er = new Engagement_Request__c();
                    er.RecordTypeId=ERtype;
                    er.Case__c=lErInbound[0].Case__c;
                    er.Partner_Problem_Product__c='problem_product_outbound';
                    er.Support_Topic_L1__c='supportTopicL1';
                    er.Subject__c='test ER';
                    er.Description__c='Desc';
                    er.Additional_CC_List__c='a@a.com';
                    insert er;
                    Outbound_Request_Queue__c orb = [Select Request_Data__c from Outbound_Request_Queue__c where Event_Object_Id__c=:er.Id];
                    system.debug('####'+orb);
                    //Changing the severity and status
                    Case c = new Case(Id=lErInbound[0].Case__c);
                    c.Severity__c='2';
                    c.Status='Work in Progress';
                    update c;
                //update outbound record to process the receipt
                test.stopTest();
            }     
        }
    }
    
    //Closed Colab
    @isTest
    static void outboundScenario_Test_2()
    {
        createAccountAndContact();
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('NamedInboundCaseCreation'),Partner_Request_Id__c='916',Originating_Partner_Account__c='MSAzure');
        insert inRec;
        List<Inbound_Request_Queue__c> lInboundRec = [Select Response_Data__c from Inbound_Request_Queue__c where Id=:inRec.Id limit 1];
        system.debug('%%%%%'+lInboundRec);
        if(!lInboundRec.isEmpty() && lInboundRec[0].Response_Data__c != null)
        {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(lInboundRec[0].Response_Data__c);
            String caseId = (String) m.get('TicketReference');
            system.debug('%%%%%'+caseId+'oo'+m);
            List<Case> lC = [Select Id from Case where Akam_Case_Id__c =:caseId limit 1];
            if(!lC.isEmpty())
            {
                test.startTest();
                    //Changing the status
                    lC[0].Status='Closed';
                    lC[0].Validation_Override__c =true;
                    update lC[0];
                //update outbound record to process the receipt
                test.stopTest();
            }
        }
    }
    
    @isTest    
    static void testIsPartnerActivity(){
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
        /*System.RunAs(usr)
         {
             Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
             environmentSetup.Active_Org__c = true;
             update environmentSetup;
         } */ 
        
        //new Case 
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('AggregateInboundCaseCreation'),Partner_Request_Id__c='283',Originating_Partner_Account__c='MSAzure',Response_Data__c = '{"TicketReference":"F-CS-1901454", "MessageId":"14916720", "ProcessingStatus":"Success"}');
        insert inRec;
       
        List<String> lAkamCaseIds = new List<String>();
        list<Id> caseTestId = new list<Id>();
        List<case> caseUpdate = new List<Case>();
        Map<String, Object> responseDataPayload;
        string caseId = '';  
        List<Inbound_Request_Queue__c> irqList = [select Id,response_data__c from Inbound_Request_Queue__c where Partner_Request_Id__c ='283'];
       
        for(Inbound_Request_Queue__c forEachInbound : irqList){
            //desearializing the json data coming from Response Data from Inbound Queue
                responseDataPayload = (Map<String, Object>) JSON.deserializeUntyped(forEachInbound.Response_Data__c );
                caseID = (String)responseDataPayload.get('TicketReference'); 
                lAkamCaseIds.add(caseID);
         }
        
        list<Case> lCasesToSendEmail = [SELECT Subject,AKAM_Case_ID__c,Description,Id,NextStepsExternal__c,
                                        AuthorizedContacts__c,Contact.Email,Contact.Name,ContactId,Partner_Joint_Troubleshooting_Status__c
                                        FROM Case WHERE AKAM_Case_ID__c IN :lAkamCaseIds];
        
        for(case cId :lCasesToSendEmail){
            caseTestId.add(cId.Id);
            cId.Partner_Joint_Troubleshooting_Status__c = 'open';
            cId.Validation_Override__c=true;
            caseUpdate.add(cId);
        }
        update caseUpdate;
        
        Map<Id,Case> caseMap = new Map<Id,Case>();
        list<Id> lparentid = new list<Id>();
        for(case c : lCasesToSendEmail){
        caseMap.put(c.id,c);
        lparentid.add(c.id);   
        }
        system.debug('^^^^^^6'+lparentid);
        if(!lparentid.isEmpty())
        {
            Id rtype = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            Task tsk = new Task();
            tsk.Subject = 'Test-Task1234';
            tsk.Visibility__c = 'Customer';
            tsk.Type = 'Call';
            tsk.RecordTypeId = rtype;
            tsk.WhatId = lparentid[0];
            tsk.Partner_Activity_Id__c = '7a17c4a6-08aa-41a8-a738-3e0c31989797';
            tsk.Partner_Receipt_Status__c = 'Success Receipt Received';
            
            insert tsk;
            
            List<Task> taskNewId = new List<Task>([select id from task where subject = 'Test-Task1234' and type ='Call' limit 1]);
            
            
            Id ERtype = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation to Microsoft Azure').getRecordTypeId();
            Id ERMtype = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Escalation From Microsoft Azure').getRecordTypeId();
            Engagement_Request__c  newER = new Engagement_Request__c();
                newER.RecordtypeId =ERType;
                newER.Subject__c  = 'Test ER';
                newER.description__c = 'Test Description';
                newER.Case__c = lparentid[0];
                newER.Partner_Problem_Product__c = 'Test 1';
                newER.Support_Topic_L1__c = 'Test1';
                newER.Support_Topic_L2__c = 'Test1';
                newER.Support_Topic_L3__c = 'Test1';
                newER.Request_Status__c = 'Open';
                newER.Partner_Ticket__c = '116021610096035';
            //insert newEr;
            
            test.startTest();
            
            String TextBody = 'Your request for assistance from Akamai Support has been received and is being reviewed. An Akamai representative will contact you shortly if more information is needed Type: RESNOT';     
                
            EmailMessage lmsg = new EmailMessage();
                lmsg.TextBody = TextBody;
                lmsg.FromAddress = 'test@akamai.com';
                lmsg.ToAddress = 'test@microsoft.com';
                lmsg.parentid = lparentid[0];
                lmsg.ccAddress = 'test1@akamai.com';
                lmsg.Incoming = False;
                lmsg.Status = '0';
                lmsg.ActivityId = taskNewId[0].Id;
             
            insert lmsg; 
                   
            test.stopTest();
        }
    }  
    
    @isTest
    static void answerCustomerController_Test(){
        Inbound_Request_Queue__c inRec = new Inbound_Request_Queue__c(Request_Data__c=fetchInboundPayload('NamedInboundCaseCreation'),Partner_Request_Id__c='916',Originating_Partner_Account__c='MSAzure', Response_Data__c = '{"TicketReference":"F-CS-1901454", "MessageId":"14916720", "ProcessingStatus":"Success"}');
        insert inRec;
        List<Inbound_Request_Queue__c> lInboundRec = [Select Request_Data__c,Response_Data__c,Partner_Request_Id__c from Inbound_Request_Queue__c where Id=:inRec.Id limit 1];
        system.debug('#####'+lInboundRec);
        if(!lInboundRec.isEmpty())
        {
            Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(lInboundRec[0].Response_Data__c);
            String caseId = (String) m.get('TicketReference');
            system.debug('####'+m);
            List<Case> lc = [Select Id from Case where Akam_Case_Id__c=:caseId];
            if(!lc.isEmpty())
            {    
                test.startTest();
                    ApexPages.StandardController sc = new ApexPages.standardController(lc[0]);
                    ApexPages.currentPage().getParameters().put('id',lc[0].id);                
                    AnswerCustomerController ac = new AnswerCustomerController(sc);
                test.stopTest();
            }    
        }    
    }

    /*@isTest
    static void outboundScenarioSeverityChange(){
		Case varCase = new Case();
        //Case objCase = utilTestClass.createCase(acc.Id); 
        varCase.AccountId = MSAct.Id;
        varCase.Partner_Account__c = MSAct.Id;
        varCase.Subject = 'Test Class Case';
        varCase.Description = 'Test Class Case Description';
        varCase.Eligible_for_Partner_Case_Exchange__c = true;
        varCase.Partner_Joint_Troubleshooting_Status__c = 'Open';
        varCase.Severity__c = '1';
		varCase.Validation_Override__c = true;
        Insert varCase;
        
		varCase.Validation_Override__c = true;
        varCase.Severity__c = '2';
        update varCase;
   }  */  
    
   /* @isTest
    static void testActivityHistoryCreation(){
     
     testIsPartnerActivity();   
     List<Task> tskListforUpdate = [select id,Visibility__c from task where Visibility__c = 'Customer'];
     Id rtype = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
     List<Case> caseId = [select id from case limit 1];
     test.startTest();   
     List<Task> tskUpdate = new List<Task>();
     for(task forTsk : tskListforUpdate){
          forTsk.Visibility__c = 'Internal Only';
          forTsk.RecordTypeId = rtype;
          forTsk.WhatId = caseId[0].id;
          tskUpdate.add(forTsk);
        }
     update tskUpdate;
     test.stopTest();
    }*/
   
}
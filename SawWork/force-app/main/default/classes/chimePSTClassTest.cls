/***************************************************************************************************
* @author       Ashin Louis
* @date         23/MAR/2022
* @Class name   chimePSTClassTest
* @description  This class is used as test class for 'chimePSTClass' Apex class
* @team         GSS
* Ver     Date           Author      Modification
* 1.0   09-20-2021     Ashin Louis   Created new test class for 'chimePSTClass' Apex class
*****************************************************************************************************/

@isTest(seeAllData=false)
public class chimePSTClassTest 
{
/***************************************************************************************************
* @author       Ashin Louis
* @date         7/FEB/2022
* @methodname   getChimeDetailsTest
* @description  This methods is used to test the chimePSTClass.getChimeDetails method
* @return       void
*****************************************************************************************************/
    @testSetup static void setupgetChimeDetailsTest()
    {
        utilTestClass.createCustomSettings();
        CHIME_GSS_Settings__c sett = new CHIME_GSS_Settings__c ();
        sett.Name = 'TestSetting';
        sett.Question_Admin_Email__c = 'abc@test.com';
        insert sett;
        
        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestChimeAccount4';
        acc.BillingCountry = 'India4';
        acc.BillingState = 'DELHI4';
        acc.website = 'www.testchimeaccount4.com';
        insert acc;

        Contact con = new Contact();
        con.FirstName = 'Test1';
        con.LastName ='Contact1';
        con.Email ='testcon@akam1.com';
        con.Phone ='+12345678781';
        con.AccountId = acc.Id;
        insert con;

        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Edge Redirector Cloudlet';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        insert pacProduct;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__ChimeTest Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        
         Id chimeToDsrRecordTypeId = Schema.SObjectType.DSR_Chime_Product_Map__c.getRecordTypeInfosByName().get('Chime to DSR Product Map').getRecordTypeId();
        Id DsrToPSTRecordTypeId = Schema.SObjectType.DSR_Chime_Product_Map__c.getRecordTypeInfosByName().get('DSR to Case Product Map').getRecordTypeId();
        
        DSR_Chime_Product_Map__c chimeTodsr = new DSR_Chime_Product_Map__c();
        chimeTodsr.Name='demo';
        chimeTodsr.Chime_Product__c='edge redirector cloudlet';
        chimeTodsr.DSR_Product__c='cloudlets';
        chimeTodsr.Active__c=true;
        chimeTodsr.RecordTypeId=chimeToDsrRecordTypeId;
        insert chimeTodsr;
        
        DSR_Chime_Product_Map__c dsrTopst = new DSR_Chime_Product_Map__c();
        dsrTopst.Name='demo1';
        dsrTopst.DSR_Product__c='cloudlets';
        dsrTopst.PST_Case_Product__c='cloudlets';
        dsrTopst.Active__c=true;
        dsrTopst.RecordTypeId=DsrToPSTRecordTypeId;
        insert dsrTopst;
        
        
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acc.id;
        chimeRecord.Opportunity__c = oppty.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        chimeRecord.POC_Type__c='Standard-POC';
        insert chimeRecord;
        
        CHIME__c chimeRecord2 = new CHIME__c();
        chimeRecord2.Account__c = chimeRecord.Account__c;
        chimeRecord2.Opportunity__c = chimeRecord.Opportunity__c;
        chimeRecord2.CHIME_Name__c = 'Chime Test Record2';
        chimeRecord2.Implementation_Type__c = chimeRecord.Implementation_Type__c;
        chimeRecord2.POC_Type__c='Custom-POC';
        chimeRecord2.Stage__c ='Gating';
        chimeRecord2.Is_Emergency__c = false;
        chimeRecord2.Is_Work_At_Risk_Investment_Work__c = false;
        chimeRecord2.Business_Goals__c= 'Improve Uptime & Availability';
        chimeRecord2.CHIME__c = chimeRecord.Id;
        chimeRecord2.LOE_Review_Status__c = 'Review required';
        insert chimeRecord2;
	       
        
        Deal_Support_Request__c newDsr = new Deal_Support_Request__c();
        newDsr.Request_Type__c='POC';
        newDsr.Account__c=acc.id;
        newDsr.Opportunity__c = oppty.id;
        newDsr.CHIME__c=chimeRecord.Id;
        newDsr.POC_Status__c='Planned';
        newDsr.SE__c=UserInfo.getUserId();
        newDsr.RVP__c=UserInfo.getUserId();
        newDsr.Start_Date__c = system.today();
        newDsr.Product__c='Cloudlets';
        newDsr.Success_Criteria__c='demo';
        newDsr.Approval_Status__c='Approved';
        insert newDsr;
        
        //Template
        Chime_Product_Template__c template = new Chime_Product_Template__c();
        template.Product__c= pacProduct.Id;
        template.Is_Latest__c= true;
        insert template;
        
         PAC_Product_Features__c feature     = new PAC_Product_Features__c(

            Feature_Name__c                 = 'Auto-Convert Image Format',
            Parent_Product_Marketing_Id__c  = 'M-LC-165919',
            Product__c                      = pacProduct.id,
            Active__c                       = true,
            Description__c                  = 'Tets',
            Unique_Id__c                    = 'M-LC-165919'+'-'+'1',
            Feature_Id__c                   = '1',

            //Addtional columns
            First_Unit_LOE_In_Hours__c      = 20,
            Additional_Unit_LoE_In_Hours__c = 5,
            Unit_Type__c                    = 'Configuration',
            Default_Feature__c              = true,
            Review_Required__c              = true,
            Scope_of_Work__c                = 'Tets' );
            insert feature;
        
        //CPA
        list<Chime_Product_Association__c> cprassList = new List<Chime_Product_Association__c>();
        Chime_Product_Association__c newCPA1 = new Chime_Product_Association__c(CHIME_Product__c=pacProduct.Id,CHIME__c=chimeRecord.Id, Chime_Product_Template__c=template.id);
        cprassList.add(newCPA1);
        Chime_Product_Association__c newCPA2 = new Chime_Product_Association__c(CHIME_Product__c=pacProduct.Id,CHIME__c=chimeRecord2.Id, Chime_Product_Template__c=template.id);
        cprassList.add(newCPA2);
        insert cprassList;
        Chime_Product_Association__c retList = [Select id from Chime_Product_Association__c LIMIT 1 ];
        Chime_Features_LoE__c cfeature = new Chime_Features_LoE__c();
        cfeature.CHIME_Product__c=retList.id;
        cfeature.LoE__c=10;
        insert cfeature;
        
        List<CHIME_Product_Question__c> qList = new List<CHIME_Product_Question__c>();
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c ();
        q1.CHIME_Product__c =pacProduct.Id;
        q1.Chime_Product_Template__c =template.Id;
        q1.template__c=template.Id;
        q1.Required__c =true;
        q1.Question_Text__c='q1';
        q1.Possible_Response__c='Yes';
        q1.Form_Stage__c ='Gating';
        qList.add(q1);
        
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c ();
        q2.CHIME_Product__c =pacProduct.Id;
        q2.Chime_Product_Template__c =template.Id;
        q2.template__c=template.Id;
        q2.Required__c =true;
        q2.Question_Text__c='q2';
        q2.Possible_Response__c='Yes';
        q2.Form_Stage__c ='Scoping';
        qList.add(q2);
        insert qList;

        CHIME_Product_Question__c q3 = new CHIME_Product_Question__c ();
        q3.CHIME_Product__c =pacProduct.Id;
        q3.Chime_Product_Template__c =template.Id;
        q3.template__c=template.Id;
        q3.Question_Text__c='q3';
        q3.Required__c =true;
        q3.Possible_Response__c='Yes';
        q3.Form_Stage__c ='Scoping';
        q3.parent_question__c = q2.id;
        q3.Expected_Response__c = 'Yes';
         insert q3;

         CHIME_Product_Question__c q4 = new CHIME_Product_Question__c ();
        q4.CHIME_Product__c =pacProduct.Id;
        q4.Chime_Product_Template__c =template.Id;
        q4.template__c=template.Id;
        q4.Required__c =false;
        q4.Question_Text__c='q4';
        q4.Possible_Response__c='Yes';
        q4.Form_Stage__c ='Gating';
        q4.parent_question__c = q1.id;
        q4.Expected_Response__c = 'Yes';
         insert q4;
        
        Id pstRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('PST').getRecordTypeId();
        Id dsrRecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByName().get('Pre-Sales Activity').getRecordTypeId();
      
        
        case newCase = new case();
        newCase.AccountId = acc.id;
        newCase.Description = 'demo description';
        newCase.Subject ='demo subject' ;
        newCase.Opportunity__c = oppty.id;
        newCase.Severity__c = '3';
        newCase.PST_Case_Product__c = 'Cloudlets';
        newCase.RecordTypeId = pstRecordTypeId;
        newCase.Service__c = 'Trial / PoC';
        newCase.Deal_Support_Request__c = newDsr.id;
        newCase.Request_Type__c = 'PoC(PST)';
        newCase.Chime_Form__c = chimeRecord.Id;
        newCase.Origin = 'Autogen';
        newCase.Chime_Case_Type__c = 'Chime PST Case';
        insert newCase;
        
    }
         @isTest static void getChimeDetailsTest()
    {
        test.startTest();
        chime__c chimeRecord = [select id from chime__c where CHIME_Name__c = 'Chime Test Record' LIMIT 1];
         chime__c chimeRecord2 = [select id from chime__c where CHIME_Name__c = 'Chime Test Record2' LIMIT 1];
        CHIME__c rchime = chimePSTClass.getChimeDetails(chimeRecord.Id);
        system.assertEquals(chimeRecord.Id,rchime.id);
        String stringchimeproducts = chimePSTClass.getChimeProdDetails(chimeRecord.Id);
        system.debug('aaaa'+ stringchimeproducts);
        system.assertNotEquals('', stringchimeproducts);
        
        List<String> justficationlist = new List<String>();
        justficationlist.add('demo justification');
        string notes = 'sample notes';
        List<String> chimeprodnames = new List<String>();
        chimeprodnames.add('edge redirector cloudlet');
       
        
        string[] splitted = stringchimeproducts.split('\\,"justification"');  
        system.debug('splitted string' +splitted);
        String[] splitted1 = splitted[0].split('\\"productList":');
        string finalPrdList = splitted1[1];
        
        
        //string finalPrdList = '['+stringchimeproducts+']';
        String casesInserted = chimePSTClass.createChimeCase(justficationlist,finalPrdList,notes,chimeprodnames);
        system.assertEquals('true', casesInserted);
        
        chimePSTClass.loeClone(chimeRecord2.id,chimeRecord.id);
        test.stopTest();
        
         
    }
    
    

}
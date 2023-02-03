/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 04-01-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-20-2021   apyati   SFDC-8655 Added validateAddRemoveContacts
**/
@isTest(seeAllData=false)
public class ChimeTriggerClassTest {
    
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() {
        
       utilTestClass.createCustomSettings();
        CHIME_GSS_Settings__c sett = new CHIME_GSS_Settings__c ();
        sett.Name = 'TestSetting';
        sett.Question_Admin_Email__c = 'abc@test.com';
        insert sett;
        
       	List<Account> accList = new List<Account>();
        
        Account partneracc = new Account();
        partneracc.Name = 'TestPartnerAccount';
        partneracc.BillingCountry = 'India';
        partneracc.BillingState = 'DELHI';
        partneracc.website = 'www.testchimeaccount.com';
        accList.add(partneracc);
      
        Account partneracc2 = new Account();
        partneracc2.Name = 'TestPartnerAccount';
        partneracc2.BillingCountry = 'India';
        partneracc2.BillingState = 'DELHI';
        partneracc2.website = 'www.testchimeaccount.com';
        partneracc2.ParentId = partneracc.id;
       accList.add(partneracc2);

        Account partneracc3 = new Account();
        partneracc3.Name = 'TestPartnerAccount';
        partneracc3.BillingCountry = 'India';
        partneracc3.BillingState = 'DELHI';
        partneracc3.website = 'www.testchimeaccount.com';
        partneracc3.ParentId = partneracc2.id;
       accList.add(partneracc3);


        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestChimeAccount';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.testchimeaccount.com';
       accList.add(acc);
        
	    insert accList;
      

        List<Contact> conList = new List<Contact>();
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName ='Contact';
        con.Email ='testcon@akam.com';
        con.Phone ='+1234567878';
        con.AccountId = acc.Id;
         conList.add(con);


        Contact partnercon = new Contact();
        partnercon.FirstName = 'Test';
        partnercon.LastName ='Contact';
        partnercon.Email ='testpartnercon@akam.com';
        partnercon.Phone ='+1234567878';
        partnercon.AccountId = partneracc3.Id;
        conList.add(partnercon);
		
  		insert conList;
        
        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Test Product';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        insert pacProduct;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__ChimeTest Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acc.id;
        chimeRecord.Opportunity__c = oppty.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        chimeRecord.Reopen_Reason__c ='Missing Data';
        chimeRecord.Partner_Involved__c= partneracc3.Id;
        insert chimeRecord;
        
        
        //Template
        Chime_Product_Template__c template = new Chime_Product_Template__c();
        template.Product__c= pacProduct.Id;
        template.Is_Latest__c= true;
        insert template;
        
        //CPA
        Chime_Product_Association__c newCPA = new Chime_Product_Association__c(CHIME_Product__c=pacProduct.Id,CHIME__c=chimeRecord.Id, Chime_Product_Template__c=template.id);
        insert newCPA;
        
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
        qList.add(q3);

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
         qList.add(q4);
        
        insert qList;
        
        Case c = new Case();
        c.AccountId = acc.Id;
        c.Chime_Form__c = chimeRecord.Id;
        c.Chime_Case_Type__c = 'Integration Case';
        insert c;
    }
    
    @isTest static void getAllProductsTest(){
        Test.startTest();
        list<PAC_Product_Catalog__c> pacProducts = ChimeTriggerClass.getAllProducts(false);
        
        list<PAC_Product_Catalog__c> pacProducts2 = ChimeTriggerClass.getAllProducts(true);
        Test.stopTest();
        system.assertEquals(1, pacProducts.size());
    }
    
    @isTest static void getAssignedChimeFormTest(){
        Test.startTest();
        Map<String,String> chimeIdToProducts = ChimeTriggerClass.getAssignedChimeForm();
        ChimeTriggerClass.getInvalidTextResponses();
        ChimeTriggerClass.getSuccCri();
        Test.stopTest();
        system.assertEquals(0, chimeIdToProducts.size());
    }
    
    @isTest static void getSelectedProductsTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        
        list<Chime_Product_Association__c> selectedProducts = ChimeTriggerClass.getSelectedProducts(chime.id);
        Test.stopTest();
        system.assertEquals(1, selectedProducts.size());
    }
        
    @isTest static void getAllSuccessCriteriaTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        
        ChimeTriggerClass.getAllSuccessCriteria(chime.id);
        Test.stopTest();
    }
    
    @isTest static void getSelectedProductsForChimeTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        
        list<Chime_Product_Association__c> selectedProducts = ChimeTriggerClass.getSelectedProductsForChime(chime.id);
        Test.stopTest();
        system.assertEquals(1, selectedProducts.size());
    }
    
    @isTest static void createChimeProductAssociationTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        PAC_Product_Catalog__c prod = [select id from PAC_Product_Catalog__c where Product_Name__c = 'Test Product' limit 1];
        
        Chime_Product_Association__c cpa = ChimeTriggerClass.createChimeProductAssociation(chime.id, prod.id);
        Test.stopTest();
    }
        
    @isTest static void deleteChimeProductAssociationTest(){
        Test.startTest();
        Chime__c chime = [Select id,Opportunity__c,Account__c from Chime__c limit 1];
        Chime_Product_Association__c chimeAssociation = [select Id from Chime_Product_Association__c where chime__c =: chime.id];
        
        ChimeTriggerClass.deleteChimeProductAssociation(chimeAssociation.Id);
        ChimeTriggerClass.getChimeDetails(chime.id);
        ChimeTriggerClass.getOpportunityDetails(chime.Opportunity__c);
        ChimeTriggerClass.getObjectDetails(chime.Account__c);
        ChimeTriggerClass.getObjectDetails(chime.Opportunity__c);
        //ChimeTriggerClass.getObjectDetails('');
        Test.stopTest();
    }
    
    @isTest static void validateChimeAccessTest(){
        Test.startTest();
        Chime__c chime = [Select id,Opportunity__c,Account__c from Chime__c limit 1];
        
        ChimeTriggerClass.validateChimeAccess(chime.id);
        list<PAC_Product_Catalog__c> selectedProdIds = new list<PAC_Product_Catalog__c>();
        PAC_Product_Catalog__c prod = [select id from PAC_Product_Catalog__c where Product_Name__c = 'Test Product' limit 1];
        selectedProdIds.add(prod);
        //public static string createChime(String chimeId, String opportunityId,String partneraccountId,String accountId, String impType, boolean isEmer, String chimeName, list<PAC_Product_Catalog__c> selectedProdIds, Boolean isPOC){

        ChimeTriggerClass.createChime('', chime.Opportunity__c,chime.Account__c, chime.Account__c, 'Standard', True, 'Test New Chime1', selectedProdIds,false,'Standard-POC',False);
        ChimeTriggerClass.createChime(chime.Id, chime.Opportunity__c,chime.Account__c, chime.Account__c, 'Standard', True, 'Test New Chime2', selectedProdIds,false,'Custom-POC',False);
        Test.stopTest();
    }
    
    @isTest
    static void checkPermissionToAcceptChimeTest(){
		Test.startTest();     
        ChimeTriggerClass.checkPermissionToAcceptChime('Accept');
        ChimeTriggerClass.checkPermissionToAcceptChime('Reopen');
        Test.stopTest();
    }
     @isTest
    static void clearFlag2Test(){
		Test.startTest();     
        List<Chime_Product_Association__c> cpa = [Select id from Chime_Product_Association__c];
        //ChimeTriggerClass.clearFlag(JSON.serialize(cpa));
        Chime__c chime = [Select id from Chime__c limit 1];
        PAC_Product_Catalog__c pacProduct = [Select id from PAC_Product_Catalog__c limit 1];
        String cId = (String)Chime.Id;
        String pId =(string)pacProduct.Id;
        ChimeTriggerClass.clearFlag2(cId,pId);
        Test.stopTest();
    }  
    
    @isTest
    static void StageTransitionCheckTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q1list){
                if(q.Question_Text__c=='q1'){
                    q1=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q2List =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q2list){
                if(q.Question_Text__c=='q2'){
                    q2=q;
                    break;
                }
            }
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);
        Insert rList;
        
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Gating',JSON.serialize(new List<Id>{q1.Id}));
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q1.Id,q2.Id}));
        
        ChimeTriggerClass.CaseCreationFlagCheck((String)chime.Id , 'Scoping',true);	
        ChimeTriggerClass.CaseCreationFlagCheck((String)chime.Id , 'Scoping',false);
        Test.stopTest();
    }
    @isTest
    static void StageTransitionCheckTest1(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q1list){
                if(q.Question_Text__c=='q1'){
                    q1=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q2list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q2list){
                if(q.Question_Text__c=='q2'){
                    q2=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q3list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q3 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q3list){
                if(q.Question_Text__c=='q3'){
                    q3=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q4list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
		CHIME_Product_Question__c q4 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q4list){
                if(q.Question_Text__c=='q4'){
                    q4=q;
                    break;
                }
            }        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);

        CHIME_Response__c r3 = new CHIME_Response__c ();
        r3.CHIME__c =chime.Id;
        r3.CHIME_Product_Question__c =q3.Id;
        r3.Response__c ='Yes';
        rList.add(r3);
        Insert rList;
        
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Gating',JSON.serialize(new List<Id>{q1.Id,q4.Id}));
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q1.Id,q2.Id,q3.Id,q4.Id}));
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Gating');
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Scoping');
        Test.stopTest();
    }
    @isTest
    static void StageTransitionCheckTest3(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q1list){
                if(q.Question_Text__c=='q1'){
                    q1=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q2list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q2list){
                if(q.Question_Text__c=='q2'){
                    q2=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q3list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q3 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q3list){
                if(q.Question_Text__c=='q3'){
                    q3=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q4list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
		CHIME_Product_Question__c q4 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q4list){
                if(q.Question_Text__c=='q4'){
                    q4=q;
                    break;
                }
            }
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);

        CHIME_Response__c r3 = new CHIME_Response__c ();
        r3.CHIME__c =chime.Id;
        r3.CHIME_Product_Question__c =q3.Id;
        r3.Response__c ='Yes';
        rList.add(r3);

        CHIME_Response__c r4 = new CHIME_Response__c ();
        r4.CHIME__c =chime.Id;
        r4.CHIME_Product_Question__c =q4.Id;
        r4.Response__c ='Yes';
        rList.add(r4);
        Insert rList;
        
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Gating');
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Scoping');
        
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Gating',JSON.serialize(new List<Id>{q1.Id,q4.Id}));
        //ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q1.Id,q2.Id,q3.Id,q4.Id}));
        Test.stopTest();
    }
    @isTest
    static void StageTransitionCheckTest2(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q1list){
                if(q.Question_Text__c=='q1'){
                    q1=q;
                    break;
                }
            }
        List<CHIME_Product_Question__c> q2list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q2list){
                if(q.Question_Text__c=='q2'){
                    q2=q;
                    break;
                }
            }
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        /*CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);*/
        Insert rList;
        
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Gating');
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Scoping');
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Gating',JSON.serialize(new List<Id>{q1.Id}));
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q1.Id,q2.Id}));
        //ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q4.Id}));
        ChimeTriggerClass.checkForReadOnly();
        Test.stopTest();
    }
    
    @isTest
    static void StageTransitionCheckTest4(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c();
            for(CHIME_Product_Question__c q: q1list){
                if(q.Question_Text__c=='q4'){
                    q1=q;
                    break;
                }
            }
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        /*CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);*/
        Insert rList;
        
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Gating');
        ChimeTriggerClass.StageTransitionCheck((String)chime.Id , 'Scoping');
        //ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Gating',JSON.serialize(new List<Id>{q1.Id}));
        ChimeTriggerClass.StageTransitionChecknew((String)chime.Id , 'Scoping',JSON.serialize(new List<Id>{q1.Id}));
        ChimeTriggerClass.checkForReadOnly();
        Test.stopTest();
    }
    @isTest
    static void notifyOppTeamTest(){
		Test.startTest();     
        Chime__c chime = [Select id from Chime__c limit 1];
        String casestring = L2Q_LOE_Utility.create_updateCase(chime.Id, 'Tets', 'Integration_Case', '3', false);
        ChimeTriggerClass.notifyOppTeam((String)chime.Id , 'Reopened');
        ChimeTriggerClass.notifyOppTeam((String)chime.Id , 'Accepted');
        chime.Stage__c='Integration';
        chime.Status__c  = 'Reopened';
        chime.Reopen_Reason__c='Properties Addition';
        update chime;
        Test.stopTest();
    }
    @isTest
    static void validateAddRemoveContacts(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        Account  acc  = [Select id from Account limit 1];

        List<Contact>  lstContacts = ChimeTriggerClass.getContacts(acc.Id, chime.Id);
        System.assert(lstContacts.size()>0, ' contacts dont exist');

        try{
            String message = ChimeTriggerClass.addChimeContacts(lstContacts, chime.Id);
            System.assert(!String.isBlank(message), 'Chime contacts didnt get added');
        }catch(Exception e){
            system.debug( 'Exception occured');
        }
        
        List<Contact> selectedContacts = new List<Contact>();
        for(Contact con :lstContacts ){
            con.Has_Chime_Access__c =true;
            selectedContacts.add(con);
        }

        String message = ChimeTriggerClass.addChimeContacts(selectedContacts, chime.Id);
        System.assert(!String.isBlank(message), 'Chime contacts didnt get added');

        List<CHIME_Contact__c> chimecontacts = ChimeTriggerClass.getChimeContacts(chime.Id);
        System.assert(chimecontacts.size()>0, ' chime contacts dont exist');

        chimecontacts[0].Chime_access__c =true;
        message = ChimeTriggerClass.updateChimeContacts(chimecontacts);
        System.assert(!String.isBlank(message), 'Chime contacts didnt get updated');

        message = ChimeTriggerClass.removeChimeContacts(chimeContacts);
        System.assert(!String.isBlank(message), 'Chime contacts didnt get removed');

    }
    @isTest
    static void checkPreSalesUserTest(){
        Test.startTest();
        ChimeTriggerClass.checkPreSalesUser();
        Test.stopTest();
    }
    @isTest
    static void setEnterpriseProductFlagOnChimeTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        
        ChimeTriggerClass.setEnterpriseProductFlagOnChime(chime.Id);
        Test.stopTest();
    }
    @isTest
    static void getProductIdByNameTest(){
        Test.startTest();
        ChimeTriggerClass.getProductIdByName('Test Product');
        Test.stopTest();
    }

    @isTest
    static void testDeprovisioningChimeContact(){
        Test.startTest();

        Chime__c chime = [Select id from Chime__c limit 1];
        Account  acc  = [Select id from Account limit 1];
        Opportunity oppty = [Select id, stageName from Opportunity limit 1];
        List<Contact>  lstContacts = ChimeTriggerClass.getContacts(acc.Id, chime.Id);

        List<Contact> selectedContacts = new List<Contact>();
        
        for(Contact con :lstContacts ){
            con.Has_Chime_Access__c =true;
            con.Remove_Chime_Access_TimeStamp__c = datetime.now();
            selectedContacts.add(con);
        }

        ChimeTriggerClass.addChimeContacts(selectedContacts, chime.Id);
        
        List<CHIME_Contact__c> chimecontacts = ChimeTriggerClass.getChimeContacts(chime.Id);
        
        oppty.stageName = 'Closed Lost';
        oppty.Opportunity_Category__c = 'Account Health';
        oppty.Loss_Reason__c = 'Customer Unresponsive';
        oppty.Validation_Override__c = true;
        update oppty;

        update selectedContacts;

        GSM_DisabledChimeAccessBatchClass disable = new GSM_DisabledChimeAccessBatchClass();
        disable.validateAndDisableChimeContactAccess();

        Test.stopTest();
    }
    
     @isTest
    static void TestMethodForHideButton(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        ChimeTriggerClass.hideChimeForm(chime.Id,true);
        ChimeTriggerClass.hideChimeForm(chime.Id,false);
        ChimeTriggerClass.checkCaseAssociateWithChime(chime.Id);
        ChimeTriggerClass.getAllProlexicProductsForChime(chime.Id);
        ChimeTriggerClass.getProlexicProductsForChime(chime.Id);
        ChimeTriggerClass.getChimeDSRs(chime.Id);
        ChimeTriggerClass.getEnterpriseProductsOnChime(chime.Id,false);
        Test.stopTest();
    }
    
}
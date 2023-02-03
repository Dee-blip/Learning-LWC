/*
    L2Q_LOE_Chime_Test
    @author         : Sujay
    @Description    : This Class contains methods to cover test cases for chime forms and further process
*/

@isTest
public without sharing class L2Q_LOE_Chime_Test 
{

    public static Account                       acct;
    public static Opportunity                   opp;
    public static PSA_TestUtility               testUtil;  
    public static Contact                       resource;
    public static User                          usr; 
    public static PAC_Product_Catalog__c        product;
    public static PAC_Product_Catalog__c        product2;
    public static PAC_Product_Features__c       feature;
    public static CHIME_GSS_Settings__c         chimeSetting;
    public static CHIME__c                      chimeForm;
    public static CHIME__c                      chimeForm1;
    public static CHIME__c                      chimeForm2;
    public static Chime_Product_Association__c  chimeProdAssn;
    public static Chime_Product_Association__c  chimeProdAssn2;
    public static Chime_Product_Association__c  chimeProdAssn3;
    public static Id                            chimeRecordTypeId;
    public static Inv_WorkBox_Region_Mapping__c gssUserRegion;
    public static pse__Region__c                geo;
    public static pse__Region__c                reg;
    public static pse__Region__c                area;
    public static list<Chime_Product_Association__c> cprList;
    
 
    public L2Q_LOE_Chime_Test() 
    {

    }

    static
    {

        testUtil            = new PSA_TestUtility();
        chimeRecordTypeId   = Schema.SObjectType.Inv_WorkBox_Region_Mapping__c.getRecordTypeInfosByName().get('Chime').getRecordTypeId();
        

        
        if(CHIME_GSS_Settings__c.getInstance('CHIME GSS') == null)
        {
            chimeSetting                            = new CHIME_GSS_Settings__c();
            chimeSetting.Name                       = 'CHIME GSS';
            chimeSetting.P1_Escalation_Hours__c     = 1;
            chimeSetting.P2_Escalation_Hours__c     = 2;
            chimeSetting.P3_Escalation_Hours__c     = 3;
            chimeSetting.From_Email_Add_OrgId__c    = '0D2G00000004DzO';
            chimeSetting.Default_ContactId__c       = '003L000001KnButIAF';
            chimeSetting.Question_Admin_Email__c    = 'hkar@akamai.com';
            chimeSetting.Business_Hour_ID__c        = '01mG0000000GptZIAS';
            chimeSetting.Last_Success_Run__c        =  null;

            insert chimeSetting;
        }
        

        usr                 = testUtil.newUserSysAdmin(false);
        usr.UserName        =  '456' + usr.UserName;
        usr.Title           = 'Manager..Service Line';
        usr.Cost_Center__c  = 10138;
        //usr.managerId       = usr2.id;

        insert usr;
        

        acct                 = testUtil.newAccount(false);
        acct.Name            = 'Living Church Of God';
        acct.TERR_HIER_1__c  = 'Media Americas';
        acct.TERR_HIER_2__c  = 'Media Americas';
        acct.TERR_HIER_3__c  = 'Broadcasting';
        acct.TERR_HIER_4__c  = 'Media East';
        acct.TERR_HIER_5__c  = 'Media East';

        insert acct;


        resource                    =   testUtil.newResource(false, acct .Id, usr.Id);
        resource.email              =   'chimecontact@akamai.com';
        
        insert resource;
        

        opp                         =   testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
        opp.StageName               =   '1. Identify Need';
        opp.Validation_Override__c  =   TRUE;

        insert opp;


        geo                         =   testUtil.newRegionMaster(false);
        geo.Name                    =   'Media Americas (Geography)';
        geo.psa_Old__c              =   false;

        insert geo;
        
        
        reg                         =   testUtil.newRegionMaster(false);
        reg.Name                    =   'Media Americas (Region)';
        reg.psa_Old__c              =   false;
        reg.pse__Parent_Region__c   =   geo.Id;

        insert reg;
        
        
        area                        =   testUtil.newRegionMaster(false);
        area.Name                   =   'Broadcasting (Area)';
        area.psa_Old__c             =   false;
        area.pse__Parent_Region__c  =   reg.Id;

        insert area;


        product                     =   newPACProduct(true, 'Image and Video Manager - Image Optimization', 'M-LC-165917', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
        // product2                     =   newPACProduct(false, 'Image and Video Manager - Image Optimization', 'M-LC-1659137', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
		//product2.Marketing_Category__c='Enterprise Security';
        //insert product2;
        
        feature                     =   newPACProductFeature(true,'Auto-Convert Image Format','1',product.Marketing_Product_Id__c, product.Id, true);

        chimeForm                   =   newChimeForm(true, acct.Id, opp.Id, 'Standard','Scoping','Not Accepted');
        chimeForm1                   =  newChimeForm(true, acct.Id, opp.Id, 'Standard','Scoping','Not Accepted');
        //chimeForm2                   =  newChimeForm(false, acct.Id, opp.Id, 'Standard','Scoping','Not Accepted');
        //chimeForm2.POC_Type__c ='Custom-POC';
        //chimeForm2.Implementation_Type__c = 'Standard & Managed';
        //chimeForm2.Review_Case_Id__c='1234';
        //chimeForm2.LOE_Review_Status__c='Review not required';
        //insert chimeForm2;

        chimeProdAssn               =   newChimeProductAssociation(true, chimeForm.id, product.id, 96, 'Standard' );
        //chimeProdAssn2               =   newChimeProductAssociation(false, chimeForm2.id, product2.id, 96, 'Standard' );
        //chimeProdAssn3               =   newChimeProductAssociation(false, chimeForm2.id, product2.id, 96, 'Standard' );
        //list<Chime_Product_Association__c>cprList1= new list<Chime_Product_Association__c>();
        // cprList1.add(chimeProdAssn2);
        //cprList1.add(chimeProdAssn3);
        //insert cprList1;

        gssUserRegion               =   testUtil.newGSSUserRegion(true, usr.Id, geo.Id, reg.Id, area.Id, NULL, NULL, chimeRecordTypeId);

        
        //Adding dependet Custom setting from bellow classes for case creation 
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();

    }



    //L2Q_ChimeSubmitForReviewController
    @isTest
    static void TestChimeSubmitForReviewControllerMethod()
    {
        test.startTest(); 

            String ImpMode  = L2Q_ChimeFormLOETabController.getProductImplementationType(chimeProdAssn.Id);

            L2Q_ChimeFormLOETabController.updateTotalLOEOnProd(chimeProdAssn.Id);

        test.stopTest();
    }


    //L2Q_LOE_Utility
    @isTest
    static void TestL2Q_LOE_UtilityMethod()
    {
                CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acct.Id;
        chimeRecord.Opportunity__c = opp.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        chimeRecord.POC_Type__c='Standard-POC';
        insert chimeRecord;
        
        CHIME__c chimeRecord2 = new CHIME__c();
        chimeRecord2.Account__c = acct.Id;
        chimeRecord2.Opportunity__c = opp.id;
        chimeRecord2.CHIME_Name__c = 'Chime Test Record2';
        chimeRecord2.Implementation_Type__c = 'Standard';
        chimeRecord2.POC_Type__c='Custom-POC';
        chimeRecord2.Stage__c ='Gating';
        chimeRecord2.Is_Emergency__c = false;
        chimeRecord2.Business_Goals__c= 'Improve Uptime & Availability';
        chimeRecord2.CHIME__c = chimeRecord.Id;
        chimeRecord2.LOE_Review_Status__c = 'Review required';
        insert chimeRecord2;
        
        
        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Edge Redirector Cloudlet';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        pacProduct.Marketing_Category__c='Enterprise Security';
        pacProduct.Review_Required__c=true;
        insert pacProduct;
        
        PAC_Product_Catalog__c pacProduct2 = new PAC_Product_Catalog__c();
        pacProduct2.Product_Name__c = 'Edge Redirector Cloudlet';
        pacProduct2.Is_Available_For_Chime__c = true;
        pacProduct2.Phase__c = 'Beta';
        pacProduct2.Marketing_Category__c='Enterprise Security';
        pacProduct2.Review_Required__c=false;
        insert pacProduct2;
       
        
        test.startTest();

            String caseupdate       =   L2Q_LOE_Utility.create_updateCase(chimeForm.Id, 'Tets', 'Review_Case', '3', false);

            Case caseRec            =   [select Id, L2Q_Chime_LOE_Send_Escalation_Email__c, OwnerId, Chime_Form__c, Chime_Form__r.LOE_Review_Status__c , L2Q_Chime_LOE_Next_Escalation_Time__c, Chime_Case_Type__c, Status, ACCOUNT_TERR_HIER_1__c, ACCOUNT_TERR_HIER_2__c, ACCOUNT_TERR_HIER_3__c from Case Limit 1];
            System.debug('caseRec testclass :: ' + caseRec);
            System.debug('chimeForm testclass :: ' + chimeForm);

            caseRec.L2Q_Chime_LOE_Send_Escalation_Email__c = true;
            update caseRec;
        
            L2Q_LOE_Utility.setEscalationOrNotifyReviewers(new List<Case>{caseRec});

            String caseupdateInt    =   L2Q_LOE_Utility.createUpdate_Review_IntegrationCase(chimeForm.Id, 'Tets', 'Review_Case', '3', false, new List<String>{chimeProdAssn.Id});

            Id reviewId             =   L2Q_LOE_Utility.getReviewerId(chimeForm.Id);
            L2Q_LOE_Utility.markChimeReviewComplete(chimeForm.Id);

            L2Q_LOE_Utility.sendReviewCompletionEmail(chimeForm.Id);
            


            Case caseNumber       =   L2Q_LOE_Utility.getCaseNumber(caseRec.Id);

            List<Id> admins = L2Q_LOE_Utility.getAdminsId();

            String caseupdate2      =   L2Q_LOE_Utility.create_updateCase(chimeForm.Id, 'Tets', 'Integration_Case', '3', false);
       
        //Below added by Ashin
        

        newChimeProductAssociation(true, chimeRecord2.id, pacProduct.id, 96, 'Standard');
         
        chime__c retChime = [SELECT id from chime__c where id=:chimeRecord.id];
        retChime.POC_Type__c = 'Custom-POC';
		update retChime;        
        newChimeProductAssociation(true, chimeRecord2.id, pacProduct2.id, 96, 'Standard');
        

        //Above added by Ashin        
        test.stopTest();
        
            boolean caseButton      =   L2Q_LOE_Utility.isCaseButtonEnable(chimeForm.Id);
    }


    //L2Q_PAC_Prod_FeatureTriggerController
    @isTest
    static void TestL2Q_PAC_Prod_FeatureTriggerControllerMethod()
    {
        test.startTest();
            PAC_Product_Features__c updateFeature            =  new PAC_Product_Features__c(
                    Id                              = feature.Id,
                    Review_Required__c              = false

            );

            update updateFeature;

            updateFeature.Review_Required__c = true;

            update updateFeature;

            L2Q_PAC_Prod_FeatureTriggerController.sendEmailtoLOEAdmin_Prod(new Set<Id>{product.Id});

            L2Q_PAC_Prod_FeatureTriggerController.sendEmailtoLOEAdmin(new Set<Id>{product.Id});

            chimeForm.status__c = 'Accepted';

            update chimeForm;

            L2Q_ChimeProductsLinksController.getProductLOEDetailsForLink();

        test.stopTest();
    }
    
    //L2Q_ChimeSubmitForReviewController
    @isTest
    static void TestL2Q_ChimeSubmitForReviewController()
    {
        
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        CHIME__c chimeRec1 = new CHIME__c();
        chimeRec1.Account__c = acct.Id;
        chimeRec1.Opportunity__c = opp.id;
        chimeRec1.CHIME_Name__c = 'Chime Test Record';
        chimeRec1.Implementation_Type__c = 'Standard';
        chimeRec1.POC_Type__c='Standard-POC';
        chimeRec1.Review_Case_Id__c='1234';
        insert chimeRec1;
        
        case c = new case();
        c.AccountId = acct.id;
        c.Description = 'demo description';
        c.Subject ='demo subject' ;
        c.Opportunity__c = opp.id;
        c.Severity__c = '3';
        c.RecordTypeId = caseRecordTypeId;
        c.Service__c = 'Trial / PoC';
        c.Request_Type__c = 'PoC';
        c.Chime_Form__c = chimeRec1.Id;
        c.Origin = 'Autogen';
        c.Chime_Case_Type__c = 'Review Case';
        insert c;
        test.startTest();
            L2Q_ChimeSubmitForReviewController.sendSubsequentReviewEmail(chimeForm.Id,'test@example.com','TestName');
            L2Q_ChimeSubmitForReviewController.getProductData(chimeForm.Id);
        
        
        chime__c ch = [Select id,Review_Case_Id__c from chime__c where id=:chimeRec1.id];
        ch.Review_Case_Id__c=c.id;
        update ch;
        L2Q_ChimeSubmitForReviewController.getProductData(chimeRec1.Id);
        //Above added by Ashin
            L2Q_ChimeSubmitForReviewController.submitProcess(new List<Id>{chimeProdAssn.Id},'P3','reason',chimeForm.Id);

        test.stopTest();
    }
    
    //Below added by Ashin to test l2q_loe_utility.create_updateCase and l2q_loe_utility.chimeFormType
    @isTest
    static void testL2q_loe_utility()
    {
        //Below added by Ashin
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        CHIME__c chimeRec1 = new CHIME__c();
        chimeRec1.Account__c = acct.Id;
        chimeRec1.Opportunity__c = opp.id;
        chimeRec1.CHIME_Name__c = 'Chime Test Record';
        chimeRec1.Implementation_Type__c = 'Standard';
        chimeRec1.POC_Type__c='Custom-POC';
        chimeRec1.Review_Case_Id__c='1234';
        insert chimeRec1;
        
        case c = new case();
        c.AccountId = acct.id;
        c.Description = 'demo description';
        c.Subject ='demo subject' ;
        c.Opportunity__c = opp.id;
        c.Severity__c = '3';
        c.RecordTypeId = caseRecordTypeId;
        c.Service__c = 'Trial / PoC';
        c.Request_Type__c = 'PoC';
        c.Chime_Form__c = chimeRec1.Id;
        c.Origin = 'Autogen';
        c.Chime_Case_Type__c = 'Review Case';
        insert c;
        
        test.startTest();
            
        
        chime__c ch = [Select id,Review_Case_Id__c from chime__c where id=:chimeRec1.id];
        ch.Review_Case_Id__c=c.id;
        update ch;
        
        L2Q_LOE_Utility.create_updateCase(ch.id,c.Description,c.Chime_Case_Type__c,'Medium',false);
        L2Q_LOE_Utility.chimeFormType(ch.id);
       
        //Above added by Ashin
            

        test.stopTest();
    }
    //Below added by Ashin on apr 7
    @isTest
    static void testL2q_chimeproductAssociationController()
    {
        //Below added by Ashin
        /*
        CHIME__c chimeRec1 = new CHIME__c();
        chimeRec1.Account__c = acct.Id;
        chimeRec1.Opportunity__c = opp.id;
        chimeRec1.CHIME_Name__c = 'Chime Test Record';
        chimeRec1.Implementation_Type__c = '';
        chimeRec1.POC_Type__c='Custom-POC';
        chimeRec1.Review_Case_Id__c='1234';
        chimeRec1.LOE_Review_Status__c='Review not required';
        insert chimeRec1;
        
        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Edge Redirector Cloudlet';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        pacProduct.Marketing_Category__c='Enterprise Security';
        pacProduct.Review_Required__c=true;
        pacProduct.Tech_Overhead_Exempt__c=false;
        pacProduct.Business_Unit__c='Web Performance';
        insert pacProduct;
        
         Chime_Product_Association__c cpa        = new Chime_Product_Association__c();
                cpa.CHIME__c                        = chimeForm.id;
                cpa.CHIME_Product__c                = product.id;
                cpa.Total_LoE__c                    = 96;
                cpa.Product_Implementation_Mode__c  = 'Standard';
                cpa.Publisher_notes__c ='demo';
        cpa.Review_Required__c=true;
        insert cpa;
        
        Chime_Product_Association__c cpa1        = new Chime_Product_Association__c();
                cpa1.CHIME__c                        = chimeForm.id;
                cpa1.CHIME_Product__c                = product.id;
                cpa1.Total_LoE__c                    = 96;
                cpa1.Product_Implementation_Mode__c  = 'Standard';
                cpa1.Publisher_notes__c ='demo';
        cpa1.Review_Required__c=true;
        insert cpa1;*/
        //chime__c chimeForm1                   =  newChimeForm(true, acct.Id, opp.Id, 'Standard','Scoping','Not Accepted');
        chime__c chimeForm2                   =  newChimeForm(false, acct.Id, opp.Id, 'Standard','Scoping','Not Accepted');
        chimeForm2.POC_Type__c ='Custom-POC';
        chimeForm2.Implementation_Type__c = 'Standard & Managed';
        chimeForm2.Review_Case_Id__c='1234';
        chimeForm2.LOE_Review_Status__c='Review not required';
        insert chimeForm2;
        
        PAC_Product_Catalog__c product2  =   newPACProduct(false, 'Image and Video Manager - Image Optimization', 'M-LC-1659137', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
		product2.Marketing_Category__c='Enterprise Security';
        insert product2;
        
         Chime_Product_Association__c chimeProdAssn2 =   newChimeProductAssociation(false, chimeForm2.id, product2.id, 96, 'Standard' );
       Chime_Product_Association__c  chimeProdAssn3  =   newChimeProductAssociation(false, chimeForm2.id, product2.id, 96, 'Standard' );
        list<Chime_Product_Association__c>cprList1= new list<Chime_Product_Association__c>();
         cprList1.add(chimeProdAssn2);
        cprList1.add(chimeProdAssn3);
        insert cprList1;
        
        test.startTest();
                List<Chime_Product_Association__c> allChimeProductAssociation = new List<Chime_Product_Association__c>();
                    allChimeProductAssociation = [select id,Product_Implementation_Mode__c , Review_Required__c, Features_LoE_Sum__c,CHIME__r.Implementation_Type__c ,CHIME_Product__c, CHIME_Product__r.Review_Required__c , CHIME_Product__r.TPM_for_calculation__c , CHIME_Product__r.Technical_Overhead__c , CHIME_Product__r.Tech_Overhead_Exempt__c, CHIME_Product__r.Product_Name__c , CHIME_Product__r.Marketing_Category__c from Chime_Product_Association__c where CHIME__c =:chimeForm2.id and CHIME__r.POC_Type__c = 'Custom-POC' ];
				system.debug('checking list' +allChimeProductAssociation);

        Chime_Product_Association__c chpr = [select id , Total_LoE__c from Chime_Product_Association__c where id=:chimeProdAssn3.id];
        chpr.Total_LoE__c=23;
        chpr.Product_Implementation_Mode__c='Managed';
        update chpr;
   
        
        
        
        
       
        //Above added by Ashin on apr 7
            

        test.stopTest();
    }
    
    //L2Q_ChimeFormLOETabController
    @isTest
    static void TestL2Q_ChimeFormLOETabController()
    {   List<L2Q_ChimeFormLOETabController.loeWrapperClass> loeWrapperClassInstanceList = new List<L2Q_ChimeFormLOETabController.loeWrapperClass>();
        L2Q_ChimeFormLOETabController.loeWrapperClass loeWrapperClassInstance = new L2Q_ChimeFormLOETabController.loeWrapperClass();
        Chime_Product_Association__c sampleCPA = newChimeProductAssociation(true, chimeForm.id, product.id, 96, 'Standard');
        List<Chime_Features_LoE__c> featuresList = [Select Id,Is_Selected__c,Feature__r.Review_Required__c,Chime_Product__c,Feature__r.Feature_Name__c,Units__c from Chime_Features_LoE__c where Chime_Product__c=:sampleCPA.Id];
        loeWrapperClassInstance.feature = featuresList[0];
        loeWrapperClassInstance.productLoEVal = Double.valueOf(20);
        loeWrapperClassInstanceList.add(loeWrapperClassInstance);
        test.startTest();
            L2Q_ChimeFormLOETabController.updateChimeFeatureLOEs(chimeProdAssn.Id);
            L2Q_ChimeFormLOETabController.updateTotalLOEOnProd(chimeProdAssn.Id);
            L2Q_ChimeFormLOETabController.getFeatureLOEData(chimeProdAssn.Id);
            L2Q_ChimeFormLOETabController.getReviewChecks(chimeProdAssn.Id);
            L2Q_ChimeFormLOETabController.getChimeStatus(chimeProdAssn.Id);
        L2Q_ChimeFormLOETabController.updateManualLoE(chimeProdAssn.Id,Double.valueOf(20));
       // L2Q_ChimeFormLOETabController.updateManualLoE(chimeProdAssn.Id,Double.valueOf(20));
        L2Q_ChimeFormLOETabController.updateProductImplementationType(chimeProdAssn.Id,'Standard');
        L2Q_ChimeFormLOETabController.updateImplementationModeOnChimeRec(chimeForm.Id);
        L2Q_ChimeFormLOETabController.getProductImplementationType(chimeProdAssn.Id);
		L2Q_ChimeFormLOETabController.updateChimeFeatureLOEs(chimeProdAssn.Id);
		L2Q_ChimeFormLOETabController.updateTotalLOEOnProd(chimeProdAssn.Id);
     	L2Q_ChimeFormLOETabController.updateFeatureLOEData(JSON.serialize(loeWrapperClassInstanceList),'Custom',Double.valueOf(20));
         
     	Chime_Product_Association__c sampleCPAChimeForm1 = newChimeProductAssociation(true, chimeForm1.id, product.id, 96, 'Standard');
     	sampleCPAChimeForm1.Product_Implementation_Mode__c = 'Managed';
     	update sampleCPAChimeForm1;
     	Chime_Product_Association__c sampleCPAChimeForm2 = newChimeProductAssociation(true, chimeForm1.id, product.id, 96, 'Standard');
     	delete sampleCPAChimeForm1;
     	PAC_Product_Catalog__c  testProd1  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization RealProduct', 'M-LC-165918', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
        testProd1.Base_Product__c = true;
        testProd1.PAC_Show_On_UI__c = true;
        testProd1.PAC_Is_Stand_Alone_Prod__c = true;
     	
     
		insert testProd1;
     	testProd1.Phase__c = 'EOS';
     update testProd1;
     	
     	PAC_Product_Catalog__c  testProd2  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization RealProduct1', 'M-LC-165922', 'GA','Web Performance','Image Manager (Images & Videos)1',true,false);
        testProd2.Base_Product__c = true;
        testProd2.PAC_Show_On_UI__c = true;
        testProd2.PAC_Is_Stand_Alone_Prod__c = true;
		insert testProd2;
     testProd2.Phase__c = 'EOL';
     update testProd2;
     
     PAC_Product_Catalog__c  testProd3  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization RealProduct2', 'M-LC-165923', 'GA','Web Performance','Image Manager (Images & Videos)2',true,false);
        testProd3.Base_Product__c = true;
        testProd3.PAC_Show_On_UI__c = true;
        testProd3.PAC_Is_Stand_Alone_Prod__c = true;
     	testProd3.Base_Product__c = true;
     
		insert testProd3;
     	testProd3.Phase__c = 'EOS';
     update testProd3;
     
     PAC_Product_Catalog__c  testProd4  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization RealProduct3', 'M-LC-165924', 'GA','Web Performance','Image Manager (Images & Videos)3',true,false);
        testProd4.Base_Product__c = true;
        testProd4.PAC_Show_On_UI__c = true;
        testProd4.PAC_Is_Stand_Alone_Prod__c = true;
     	testProd4.Base_Product__c = true;
     
		insert testProd4;
     	testProd4.Phase__c = 'EOS';
     update testProd4;

        test.stopTest();
    }
    
    
    
    //method for chime Addons and juntion object through mule integration user
    @isTest
    static void pacAddonAndJunctionObjectRecords()
    {
        PAC_Product_Catalog__c  realProduct  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization RealProduct', 'M-LC-165918', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
        realProduct.Base_Product__c = true;
        realProduct.PAC_Show_On_UI__c = true;
        realProduct.PAC_Is_Stand_Alone_Prod__c = true;
		insert realProduct;
        
        PAC_Product_Catalog__c  addOnProduct  	=   newPACProduct(false, 'Image and Video Manager - Image Optimization Addon', 'M-LC-165919', 'GA','Web Performance','Image Manager (Images & Videos)',true,false);
        addOnProduct.Add_On__c = true;
        addOnProduct.Original_Marketing_Product_Id__c = realProduct.Marketing_Product_Id__c;
        insert addOnProduct;
        
        realProduct.PAC_Show_On_UI__c = false;
        realProduct.Product_Add_on_Mapping__c = 'M-LC-165919';
        update realProduct;
        
        
    }
    




    /************************************** util methods for chime data setup ************************************* */


    //method for PAC product creation
    public static PAC_Product_Catalog__c newPACProduct(

        Boolean isInsert,
        String  prodName,
        String  marketingProdId,
        String  phase,
        String  businessUnit,
        String  category,
        boolean showOnUI,
        boolean isStandAlone
        )
    {

        PAC_Product_Catalog__c pacProd      = new PAC_Product_Catalog__c(

            Product_Name__c                 = prodName,
            Marketing_Product_Id__c         = marketingProdId,
            Version__c                      = 'v15',
            Short_Description__c            = 'Description',
            Phase__c                        = phase,
            Business_Unit__c                = businessUnit,
            Marketing_Category__c           = category,
            PAC_Show_On_UI__c               = true,
            PAC_Is_Stand_Alone_Prod__c      = false,

            Minimum_TPM__c                  = 2,
            Percentage_TPM_hours_in__c      = 7,
            Review_Required__c              = true,
            Tech_Overhead_Exempt__c         = false,
            Scope_of_work_Standard__c       = 'Tets',
            Scope_of_work_Managed__c        = 'tets'

        );

        if(isInsert)
        {
            insert pacProd;
        }
        return pacProd;
    }



    //method for PAC Product Feature creation
    public static PAC_Product_Features__c newPACProductFeature(

        boolean isInsert, 
        String  featueName,
        String  featureId,
        String  marketingProdId,
        String  productId,
        boolean active

        )
    {

        PAC_Product_Features__c feature     = new PAC_Product_Features__c(

            Feature_Name__c                 = featueName,
            Parent_Product_Marketing_Id__c  = marketingProdId,
            Product__c                      = productId,
            Active__c                       = active,
            Description__c                  = 'Tets',
            Unique_Id__c                    = marketingProdId+'-'+featureId,
            Feature_Id__c                   = featureId,

            //Addtional columns
            First_Unit_LOE_In_Hours__c      = 20,
            Additional_Unit_LoE_In_Hours__c = 5,
            Unit_Type__c                    = 'Configuration',
            Default_Feature__c              = true,
            Review_Required__c              = true,
            Scope_of_Work__c                = 'Tets' 

        );

        if(isInsert)
        {
            insert feature;
        }
        return feature;
    }


    //method for Chimeform Creation
    public static CHIME__c newChimeForm(

        Boolean isInsert,
        String  accountId,
        String  opportunityId,
        String  impType,
        String  stage,
        String  status

    )
    {
        CHIME__c chimeForm      = new CHIME__c(

            Account__c              = accountId,
            Opportunity__c          = opportunityId,
            Implementation_Type__c  = impType,
            Stage__c                = stage,
            Status__c               = status, 
            Notes__c                = 'Tets',
            LOE_Review_Status__c    = 'Awaiting Assignment' 

        );

        if(isInsert)
        {
            insert chimeForm;
        }
        return chimeForm;
    }


    //method for chime product association
    public static Chime_Product_Association__c newChimeProductAssociation(

        boolean isInsert,
        String  chimeFormId,
        String  productId,
        Decimal totalLoe,
        String  prodImpType
        
    )
    {
        Chime_Product_Association__c cpa        = new Chime_Product_Association__c(
                CHIME__c                        = chimeFormId,
                CHIME_Product__c                = productId,
                Total_LoE__c                    = totalLoe,
                Product_Implementation_Mode__c  = 'Standard'
        );

        if(isInsert)
        {
            insert cpa;
        }
        return cpa;
       
    }


}
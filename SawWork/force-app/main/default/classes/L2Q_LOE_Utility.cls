/*
Author          : Himanshu, Vishnu
Description     : Helper Class for LOE in Chime Form
Called From		: 
Test Class		: L2Q_LOE_Utility_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
12 Jun 2020       	Himanshu               ESESP-5155            Initial Version
------------------------------------------------------------------------------------------------------------------

*/

public class L2Q_LOE_Utility{


	// Wrapper Class to store Product Details
	public class productWrapper{
	
		Map<string,Decimal> allProducts_MandatoryReview; // Mandatory Review Product Name + LOE
		Map<string,Decimal> allProducts_HumanReview;	// Optional HUman Review Product Name + LOE
		Map<string,Decimal> allProducts;				// All Product Name + LOE
		string CaseProduct_forRouting; 				// to store Case Product Name for Routing with Higheast LOE
		string Business_Unit; 							// BU for Routing for Review Case
        string prodwithhigestloe;            // stores prodcuct with highest loe
		
		// Constructor for initializing vairables
		productWrapper(){
		
			allProducts_MandatoryReview = new Map<string,Decimal>();
			allProducts_HumanReview = new Map<string,Decimal>();
			allProducts = new Map<string,Decimal>();
			CaseProduct_forRouting = null;
			Business_Unit = '';
            prodwithhigestloe = '';
		}
	}
	
    // Method - 1 : Creating / Updating Case. Called from "Create Case" button on Chime Form
    // Case_Type = Review_Case or Integration_Case
    @AuraEnabled
    public static string create_updateCase(Id chimeFormID, string caseDescription, string Case_Type, string priority,
    										boolean isAutoUpdate ){ 
             
        // Variable to stamp the Case Id
        ID getCaseId;
        
        // Initializing Wrapper
        productWrapper prdWrp = new productWrapper();
        
        // Step - 1 : Query on Chime to get the Details
        CHIME__c chimeDetails = [select ID, Account__c,Total_LoE__c, Opportunity__c, Integration_Case_ID__c, Implementation_Type__c ,
        						 Review_Case_Id__c, Is_Emergency__c,Is_Work_At_Risk_Investment_Work__c,CHIME_Name__c,LOE_Review_Status__c  , All_Enterprise_Products__c , POC_Type__c  
                                 from CHIME__c 
                                 where ID = :chimeFormID limit 1 ];
                                 
        // Step - 2 : Stamp the Case ID
        getCaseId = (Case_Type == 'Review_Case') ? chimeDetails.Review_Case_Id__c : chimeDetails.Integration_Case_ID__c;
            
        // Step - 3 : Get List of Associated Product and set the Wrapper      
        getProducts(chimeFormID, prdWrp, chimeDetails.Is_Emergency__c, chimeDetails.Is_Work_At_Risk_Investment_Work__c, chimeDetails);           
              
        // Step - 4 : Create Case        
        return ( upsertCase(getCaseId,chimeDetails, prdWrp, caseDescription, Case_Type, priority,isAutoUpdate) );    
    }
    
    // Method - 2 : 
    public static void getProducts(Id chimeFormID, productWrapper prdWrp, boolean isEmergency, Boolean isWorkAtRisk, CHIME__c chimeRec){
        
        string CaseProduct_forRouting = null;
        string getMarketingID;
        List<Chime_Product_Association__c> chimeProductList = new List<Chime_Product_Association__c>();


        if (chimeRec.POC_Type__c == 'Custom-POC' && chimeRec.Implementation_Type__c == 'Standard' && chimeRec.All_Enterprise_Products__c == 'Mix' ) {
            chimeProductList = [select Total_LoE__c, CHIME_Product__r.Product_Name__c,
                                        CHIME_Product__r.Marketing_Product_Id__c, Review_Required__c,Human_Review__c,
                                        CHIME_Product__r.Business_Unit__c
                                        from Chime_Product_Association__c 
                                        where CHIME__c = :chimeFormID 
                                        AND CHIME_Product__r.Marketing_Category__c != 'Enterprise Security'
                                        order by Total_LoE__c ASC, CHIME_Product__r.Product_Name__c ASC];
        } else {
            chimeProductList = [select Total_LoE__c, CHIME_Product__r.Product_Name__c,
                                        CHIME_Product__r.Marketing_Product_Id__c, Review_Required__c,Human_Review__c,
                                        CHIME_Product__r.Business_Unit__c
                                        from Chime_Product_Association__c 
                                        where CHIME__c = :chimeFormID 
                                        order by Total_LoE__c ASC, CHIME_Product__r.Product_Name__c ASC];
        }

        decimal highloeValue = 0;
        integer highloeindex = 0;
        //ESESP-7101 - Changes by Kushal
        if (chimeProductList.size () > 0 && !chimeProductList.isEmpty()){
            highloeindex = chimeProductList.size()-1;
            highloeValue = chimeProductList[highloeindex].Total_LoE__c;
        }

        
        // Query on all Associate Chime Products
        for(Chime_Product_Association__c eachProd : chimeProductList )
        {
            //ESESP-7101 - Changes by Kushal
            if(eachProd.Total_LoE__c == highloeValue && eachProd.CHIME_Product__r.Product_Name__c.toLowerCase().contains('prolexic')){ 
                prdWrp.prodwithhigestloe = chimeProductList[highloeindex].CHIME_Product__r.Product_Name__c;
            }

            // Last product of the Loop will be deciding factor(Highest LOE)
            getMarketingID = eachProd.CHIME_Product__r.Marketing_Product_Id__c ; 
            prdWrp.Business_Unit = eachProd.CHIME_Product__r.Business_Unit__c;
            
            // Adding All the Products to List
            prdWrp.allProducts.put(eachProd.CHIME_Product__r.Product_Name__c , 
            						(eachProd.Total_LoE__c == null) ? 0 : eachProd.Total_LoE__c);
            
            // If Chime Form has isEmergency=true, then all Products are mandatory review, else calculate
            if(isEmergency || isWorkAtRisk)
            	prdWrp.allProducts_MandatoryReview.put(eachProd.CHIME_Product__r.Product_Name__c , 
            											(eachProd.Total_LoE__c == null) ? 0 : eachProd.Total_LoE__c);
            else
            {
				// Adding All product Names to both the List
				if(eachProd.Review_Required__c)
					prdWrp.allProducts_MandatoryReview.put(eachProd.CHIME_Product__r.Product_Name__c , 
															(eachProd.Total_LoE__c == null) ? 0 : eachProd.Total_LoE__c);
				else if(!eachProd.Review_Required__c && eachProd.Human_Review__c)
					prdWrp.allProducts_HumanReview.put(eachProd.CHIME_Product__r.Product_Name__c , 
														(eachProd.Total_LoE__c == null) ? 0 : eachProd.Total_LoE__c);
            }
        }
      
        
        // Query on ... Object to get Marketing Prod-Case Prod Mapping
        List<Siebel_Marketing_Prod_Case_Prod_Map__c> marketingCaseProdMap = new List<Siebel_Marketing_Prod_Case_Prod_Map__c>();
        List<String> caseProductNames = new List<String>();
        List<EB_AccountProductMap__c> caseProductList = new List<EB_AccountProductMap__c>();
        Map<String,EB_AccountProductMap__c> nameVsCaseProductRecMap = new Map<String,EB_AccountProductMap__c>();
        marketingCaseProdMap = [select Case_Product_Name__c from Siebel_Marketing_Prod_Case_Prod_Map__c 
                                where Marketing_Product_ID__c = :getMarketingID];

        for(Siebel_Marketing_Prod_Case_Prod_Map__c iteratedMarketingCaseProdMap : marketingCaseProdMap){
            caseProductNames.add(iteratedMarketingCaseProdMap.Case_Product_Name__c);
        }
       
        if(caseProductNames.size() > 0){
            //Fetching EB Case Product records.
            caseProductList = [Select Id,Name,EB_Account__c from EB_AccountProductMap__c where Name IN: caseProductNames AND EB_MarkedForDeletion__c = false AND EB_Account__c =: chimeRec.Account__c];
            //creating map data for Case Product name vs Case Product record.
            if(caseProductList.size() > 0){
                for(EB_AccountProductMap__c iteratedCaseProduct : caseProductList){
                    nameVsCaseProductRecMap.put(iteratedCaseProduct.Name,iteratedCaseProduct);
                }
            }
            for(String iteratedcaseProductName : caseProductNames){
                if(nameVsCaseProductRecMap.containsKey(iteratedcaseProductName)){
                 
                        prdWrp.CaseProduct_forRouting = nameVsCaseProductRecMap.get(iteratedcaseProductName).Id;
                        break;
               
                }
            }

        }

        
        
        // If Multiple Case Products exist, take any one for routing
       // if(marketingCaseProdMap.size() > 0)
       //     prdWrp.PlatformProduct_forRouting = marketingCaseProdMap[0].Case_Product_Name__c;
        
    }

   
    
    // Method - 3 : For Case Creation/Updatation
    public static string upsertCase(ID ChimeCaseId, CHIME__c chimeDetails, productWrapper prdWrp, 
    								string caseDescription, string Case_Type, string priority, boolean isAutoUpdate){
    	
      	// Fetching Assignment Rule & Setting DML Options
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = [Select id from AssignmentRule where SobjectType ='Case' and Active=True limit 1].Id;
        dmo.EmailHeader.TriggerUserEmail = true;
      
        // Instantiation of Case Record
        Case caseRec = new Case(ID = ChimeCaseId);
        caseRec.RecordtypeID = '012G0000000z10uIAA';
        caseRec.Validation_Override__c = true;
        caseRec.AccountID = chimeDetails.Account__c;
        caseRec.Opportunity__c = chimeDetails.Opportunity__c;
        caseRec.Chime_Form__c = chimeDetails.ID;
        caseRec.origin = 'Autogen';
        caseRec.DO_NOT_SHOW_IN_PORTAL__C = true;
        caseRec.Chime_Form_Name__c= chimeDetails.CHIME_Name__c;
        if(Case_Type == 'Review_Case'){
            caseRec.Chime_Case_Type__c = 'Review Case'; 
        }else{
            caseRec.Chime_Case_Type__c = 'Integration Case'; 
        }
        //Setting to queue for create Case only and not update
        if(String.isBlank(ChimeCaseId)){
        caseRec.setOptions(dmo);
        }
        
        // Dont update Severity for AutoUpdate Case
        if(!isAutoUpdate){
        	caseRec.Severity__c = setSeverity(priority);
        }
        caseRec.LOE_Hours__c = chimeDetails.Total_LoE__c;
        //caseRec.PS_Product__c = 'AnswerX Cloud';

        //caseRec.PS_Product__c = prdWrp.CaseProduct_forRouting;
       
        
        caseRec.Case_Product__c = prdWrp.CaseProduct_forRouting;
        
        
        // Calling Method to stamp Service & Request Type
        setServiceReqType(Case_Type, chimeDetails, caseRec,prdWrp);
        
        // Calling Method to Set Subject
        setSubject(Case_Type, chimeDetails, caseRec);
        
        // Calling Method to Set Description
        setDescription(Case_Type, chimeDetails, caseRec, prdWrp, ChimeCaseId, caseDescription);


        
        // Calling SetEscalationDate only for Integration Case
        if(Case_Type == 'Review_Case'){
        
        	SetEscalationDate(caseRec);
        
        }
        System.debug('poc type in : ' +  chimeDetails.POC_Type__c );
        if (chimeDetails.POC_Type__c == 'Custom-POC') {

            System.debug('case typee : ' + Case_Type );
            caseRec.Service__c = 'Trial / PoC';
            caseRec.Request_Type__c = 'PoC';
            caseRec.Service_Category__c = null;
            caseRec.BusinessHoursId = null;
            if (Case_Type == 'Review_Case' ) {
                caseRec.Subject = caseRec.Subject.replace('LOE', ' Trial / PoC LOE');
                caseRec.Description = caseRec.Description.replace('This is a LOE review request', 'This is a Custom PoC LOE Review request ');
                caseRec.Description = caseRec.Description.replace('to a pilot representative.', 'to a representative.');
            } else {
                caseRec.Subject = caseRec.Subject.replace('Standard Integration', ' Custom Trial / PoC ');
                caseRec.Subject = caseRec.Subject.replace('Managed Integration', ' Custom Trial / PoC ');
                caseRec.Description = 'This is a Custom POC Request \n' + caseRec.Description;
                System.debug('case sub update ? ' + caseRec.Subject );
            }

            //ESESP-7101 - Changes by Kushal
            if(prdWrp.prodwithhigestloe.contains('Prolexic')){
                caseRec.Service__c  = 'Prolexic';
                caseRec.Request_Type__c = 'Integration';
            }
        }
        
        // Upserting Case
        try{
        Upsert caseRec; 
        }catch(Exception e){
        
        	return 'Error in Case Creation/Update : '+ e.getMessage();
        }
        
        // Calling Update Chime Method
        updateChime (caseRec.ID, chimeDetails, Case_Type);
        
        // Get the Case Number & Return
        Case casedetails = [select Id,CaseNumber,Owner.Name from Case where Id = :caseRec.Id];
        String returnString = 'Case Number : ' + casedetails.CaseNumber;
        System.debug('****Owner****'+casedetails.Owner.Name);
        if(casedetails.Owner.Name != null && casedetails.Owner.Name.contains('Orphan Queue')){
            returnString = returnString + ' (assigned to Orphan Queue)';  
        }

        return returnString;
        
    }
    
    // Method 4 : For Setting Service & Request Type
    public static void setServiceReqType(string Case_Type, CHIME__c chimeDetails, Case caseRec, productWrapper prdWrp){
    
        //ESESP-7101 - Changes by Kushal
        if(prdWrp.prodwithhigestloe.contains('Prolexic')){
            caseRec.Service__c  = 'Prolexic';
            caseRec.Request_Type__c = 'Integration';
            return;
        }

    	// Logic for Integration Case
    	if(Case_Type == 'Integration_Case'){
			
			if(chimeDetails.Is_Emergency__c || chimeDetails.Is_Work_At_Risk_Investment_Work__c){
		
				caseRec.Service__c  = 'Emergency Integration';
				caseRec.Request_Type__c = 'N/A';
			}
			else if(chimeDetails.Implementation_Type__c.contains('Managed')){
		
				caseRec.Service__c  = 'Managed Integration';
                //caseRec.Request_Type__c = 'Default Project Management';
                caseRec.Request_Type__c = 'Default - Project Management';
			}
			else{
			
				caseRec.Service__c  = 'Standard Integration';
				caseRec.Request_Type__c = 'N/A';
			}
        }
        // Logic for Review Case
        else{
        
        	caseRec.Service__c  = (prdWrp.Business_Unit != null && prdWrp.Business_Unit.containsIgnoreCase('Security')) ?
        							'Other (Security)' : 'Other (Non-Security)';
        	caseRec.Request_Type__c = 'PreSales LOE/SOW';
        }
    }
    
    // Method 5 : For Setting Case Subject
    public static void setSubject(string Case_Type, CHIME__c chimeDetails, Case caseRec){
        caseRec.Subject = (chimeDetails.Is_Emergency__c)? 'Emergency - ' : '';
        caseRec.Subject = (chimeDetails.Is_Work_At_Risk_Investment_Work__c)? 'Work At Risk (Investment Work)' : '';
    	caseRec.Subject = (Case_Type == 'Review_Case') ? caseRec.Subject+'Chime LOE Review Request - ' + chimeDetails.CHIME_Name__c : 
        caseRec.Subject+'Chime ' + caseRec.Service__c + ' Request - ' + chimeDetails.CHIME_Name__c;
    }
    
    // Method 6 : For Setting Case Description
    public static void setDescription(string Case_Type, CHIME__c chimeDetails, Case caseRec, productWrapper prdWrp, 
    									ID ChimeCaseId, string caseDescription){
    
        Integer counter = 1;
        String chimeURL = System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Chime__c/' + chimeDetails.Id + '/view';
    	string calculateDesc = 'Date : ' +system.now().format() + '\n';
    	  	
    	// Design for Review Case
    	if(Case_Type == 'Review_Case'){
    	
    		calculateDesc += 'Comments : '+caseDescription+'\n This is a LOE review request to understand how many hours are needed to be used to support the integration.\n\n'
    							+ 'All the Mandatory Review Products are : \n';
    							
    		
    		// Designing Table for Mandatory Products with LOE
    		for(string eachProd : prdWrp.allProducts_MandatoryReview.keyset()){
    			calculateDesc += counter + '. ' + eachProd + ' - ' + prdWrp.allProducts_MandatoryReview.get(eachProd) + '\n';
    			counter++;
    		}
    		
    		// Render Human Review Products if Exist
    		if(prdWrp.allProducts_HumanReview.size() > 0){
				
				counter = 1;
				calculateDesc += '\n All the Human Review Products are : \n';
		
				// Designing Table for Human Review Products with LOE
				for(string eachProd : prdWrp.allProducts_HumanReview.keyset()){
				
					calculateDesc += counter + '. ' + eachProd + ' - ' + prdWrp.allProducts_HumanReview.get(eachProd) + '\n';
				
					counter++;
				}
    		}
    		
    	}
    	// Design for Integration Case
    	else{
    		
    		calculateDesc += caseDescription+'\n\n All the associated Products are : \n';
    		
    		// Designing Table for All Products with LOE
    		for(string eachProd : prdWrp.allProducts.keyset()){
    			calculateDesc += counter + '. ' + eachProd + ' - ' + prdWrp.allProducts.get(eachProd) + '\n';
    			counter++;
    		}
    							
    	}
    	
    	calculateDesc += '\n For more information please refer back to CHIME form : ' + '\n' +chimeURL;
    	
    	// Getting Existing Case Details
    	List<Case> getCase = new List<Case>();
    	if(ChimeCaseId == null){
    		caseRec.Description = calculateDesc;
    	}
    	else{
    		getCase = [select Description from Case where ID = :ChimeCaseId limit 1];
    		caseRec.Description = calculateDesc + '\n' + (getCase[0].Description == null ? '' : getCase[0].Description) ;
    	}
    }
    
    // Method 7 : For Setting Case Severity
    public static string setSeverity(string priority){
    
    	Map<string, string> priority_SevMap = new Map<string, string>{'P1' => '1', 'P2' => '2', 'P3' => '3'};
    	return (priority_SevMap.get(priority) == null) ? '3' : priority_SevMap.get(priority);
    	
    }
    
    // Method 8 : For Setting Next Escalation Time
    public static void SetEscalationDate(Case caseRec){ 
    
    	// Getting Costome setting Details
    	CHIME_GSS_Settings__c csRec = CHIME_GSS_Settings__c.getall().values();
    	
    	Map<string, Integer> severity_noOfEscHoursMap = new Map<string, Integer>();
    	severity_noOfEscHoursMap.put('1' , Integer.valueOf(csRec.P1_Escalation_Hours__c));
    	severity_noOfEscHoursMap.put('2' , Integer.valueOf(csRec.P2_Escalation_Hours__c));
    	severity_noOfEscHoursMap.put('3' , Integer.valueOf(csRec.P3_Escalation_Hours__c));
    	
    	// Fetching Business Hour
      	Id businessHourID = csRec.Business_Hour_ID__c;
      	
      	// 1 Hour Milli sec Value - For Business Hour Calculation
        Long milliSecValuefor1Hour = 3600000;
        
        // Calculating Business Hour        
        caseRec.L2Q_Chime_LOE_Next_Escalation_Time__c  = BusinessHours.add(businessHourID, system.now(), 
        												milliSecValuefor1Hour * severity_noOfEscHoursMap.get(caseRec.Severity__c));

        caseRec.L2Q_Chime_LOE_Next_Escalation_Level__c = 'SLM'; 
	
    }
    
    // Method 9 : For Updating Chime Object
    public static void updateChime(ID ChimeCaseId, CHIME__c chimeDetails,string Case_Type){
    
            // Update the Chime Record to Disable the Case button
            CHIME__c updateChimeRec = new CHIME__c(Id = chimeDetails.ID);
            
            if(Case_Type == 'Integration_Case'){
            
            	updateChimeRec.Integration_Case_ID__c = ChimeCaseId;
            	updateChimeRec.Is_Case_Button_Enabled__c = false;
            }
            else{
            
            	
            	
                // Update LOE status once Case Got Created
              //  System.debug('current review Case**'+updateChimeRec.Review_Case_Id__c);
            	if(chimeDetails.Review_Case_Id__c == null){
                    updateChimeRec.LOE_Review_Status__c = 'Awaiting Assignment';
                    updateChimeRec.Review_Case_Id__c = ChimeCaseId;
                }  
                // Removing below code because of JIRA ESESP-6951  
                // if (chimeDetails.POC_Type__c == 'Custom-POC' && chimeDetails.All_Enterprise_Products__c == 'All') {
                //     updateChimeRec.stage__c = 'Integration';
                // }
                // Removing above code because of JIRA ESESP-6951  
            }
            
            Update updateChimeRec;
        
        
    }

    // Method 10 : Logic for Showing Create Case Button on Chime Form
    @auraEnabled
    public static boolean isCaseButtonEnable(Id chimeFormID){ 
        
        boolean returnString = false;
        
        // Step - 1 : Query on Chime to get the Details
        CHIME__c chimeDetails = [select ID , POC_Type__c , Stage__c, Opportunity__c, Implementation_Type__c ,Is_Emergency__c,
                                 Is_All_Qun_Ans_Complete__c, Is_All_LOE_Review_Complete__c, Opportunity__r.StageName,
                                 Is_Case_Button_Enabled__c,No_of_review_required_products__c,Review_Case_Id__c, Is_Work_At_Risk_Investment_Work__c
                                 from CHIME__c 
                                 where ID = :chimeFormID limit 1 ];
        
        
        //Step to Re-Calculate Is_All_Qun_Ans_Complete__c on ChimeForm - Manish Mahajan
        ChimeTriggerClass.CaseCreationFlagCheck(chimeFormID,chimeDetails.Stage__c,false);
        
        // Outer IF for basic Check - Dummy
        if(chimeDetails.Stage__c == 'Scoping' && chimeDetails.Is_All_Qun_Ans_Complete__c && 
            chimeDetails.Opportunity__c != null && ((chimeDetails.Is_All_LOE_Review_Complete__c  && chimeDetails.Is_Case_Button_Enabled__c) || (chimeDetails.No_of_review_required_products__c == 0 && chimeDetails.Review_Case_Id__c == null)) ){
        
            // Additional Check
            if( (chimeDetails.Is_Work_At_Risk_Investment_Work__c) || (chimeDetails.Is_Emergency__c ) || (chimeDetails.POC_Type__c == 'Custom-POC') || 
            ((!chimeDetails.Is_Emergency__c || !chimeDetails.Is_Work_At_Risk_Investment_Work__c ) &&  chimeDetails.Opportunity__r.StageName == 'Closed Won') 
            ){
                returnString = true;
            }
        }
        
        return returnString;
    }

    @AuraEnabled
    public static string chimeFormType(Id chimeFormID){

        String chimeformType = '';

        CHIME__c chimeDetails = [select ID , POC_Type__c , Stage__c, Opportunity__c, Implementation_Type__c ,Is_Emergency__c,
                                 Is_All_Qun_Ans_Complete__c, Is_All_LOE_Review_Complete__c, Opportunity__r.StageName,
                                 Is_Case_Button_Enabled__c,No_of_review_required_products__c,Review_Case_Id__c,Is_Work_At_Risk_Investment_Work__c
                                 from CHIME__c 
                                 where ID = :chimeFormID limit 1 ];

        if( chimeDetails.POC_Type__c == 'Custom-POC' )
        {
            chimeformType = 'custompoc';
        } else {
            chimeformType = 'fullint';
        }

        return chimeformType;
        
    }
    
    // Method 11 : Main method to be called from Chime Form for Review Case / Integration Case
    @auraEnabled
    public static string createUpdate_Review_IntegrationCase(Id chimeFormID, string caseDescription, 
    															string Case_Type, string priority, boolean isAutoUpdate,List<String> selectedProducts){ 
    
    	
    	if(Case_Type == 'Review_Case'){
            List<Chime_Product_Association__c> chimeProdList = new List<Chime_Product_Association__c>();
            for(String iteratedchimeProd : selectedProducts){
                Chime_Product_Association__c sampleChimeProd = new  Chime_Product_Association__c(Id=iteratedchimeProd,Human_Review__c=true);
                chimeProdList.add(sampleChimeProd);
            }
    		
            // perform DML on Product
            /*List<Chime_Product_Association__c> chimeProd = [Select Id, Human_Review__c from Chime_Product_Association__c where CHIME__c =: chimeFormID];
            for(Chime_Product_Association__c itrProd : chimeProd){
                itrProd.Human_Review__c = true;
            }*/
			update chimeProdList;
    	}
    	
    	return ( create_updateCase(chimeFormID,caseDescription,Case_Type, priority,isAutoUpdate) );
    	
    }
	
	// Method 12 : Method to be Invoked from Process Builder - 
    @InvocableMethod(label='Set Escalation Or Notify Reviewers' description='Find relavant users from GSS User Region and notify them on Chime form linked to Case')
    public static void setEscalationOrNotifyReviewers(case[] caseRecord) 
    {
    	set<ID> caseIDs = new set<ID>();
    	for(case eachRec : caseRecord){
    		caseIDs.add(eachRec.Id);
    	}
    	processEscalation(caseIDs);
    }
	// Method 12 : Method to be Invoked from Process Builder - 
    @future
    public static void processEscalation(set<ID> caseIDs) 
    {
    	// Getting Case Record.
        List<Case> allCaseUpdate = new List<Case>();
        allCaseUpdate = [select Id,ACCOUNT_TERR_HIER_1__c,ACCOUNT_TERR_HIER_3__c,L2Q_Chime_LOE_Next_Escalation_Level__c 
        				from Case 
        				where ID IN :caseIDs];
        
        
        // Calling Method to get the List of To Add
        List<String> toAddresses    = new List<String>();
        List<String> lstReviewers   = new List<String>();
        
        Map<String, List<String>> emailORNames = new Map<String,List<String>>();
        String geo ;
        String area;
        
        
        for(Case eachchimeCase : allCaseUpdate){
        	
        	geo 	= eachchimeCase.ACCOUNT_TERR_HIER_1__c;
        	area 	= eachchimeCase.ACCOUNT_TERR_HIER_3__c;
        	toAddresses    = new List<String>();
        	lstReviewers   = new List<String>();
        	
        	emailORNames                = getDynamicQuery(eachchimeCase.L2Q_Chime_LOE_Next_Escalation_Level__c, geo, area);
        	toAddresses                 = emailORNames.get('email');
        	lstReviewers                = emailORNames.get('name');

        
			// Get List of Admin People if To Add is empty
			if(toAddresses.isEmpty())
			{
				emailORNames                = getDynamicQuery('Admin', null, null);
				toAddresses                 = emailORNames.get('email');
				lstReviewers                = emailORNames.get('name');
			}

            Set<String> myset = new Set<String>();
            myset.addAll(lstReviewers);
            lstReviewers.clear();
            lstReviewers.addAll(myset);

          	//creating new Instance as same case is in Read Only mode and can not be updated in invokable method.
            eachchimeCase.L2Q_Chime_LOE_Send_Escalation_Email__c  = false;
            eachchimeCase.L2Q_Chime_LOE_Next_Escalation_Time__c   = null;
            eachchimeCase.L2Q_Chime_LOE_Escalation_History__c     = System.now().format() + '\n Escalated to ' + eachchimeCase.L2Q_Chime_LOE_Next_Escalation_Level__c;
            eachchimeCase.L2Q_Chime_LOE_Reviewers__c              = (String.join( lstReviewers, ', ' ).length()) > 255 ? ((String.join( lstReviewers, ', ' )).SubString(0,255)) :  (String.join( lstReviewers, ', ' ));
            

			try
			{
				//Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 
				sendEmail_allUseCases(eachchimeCase.Id, 'CHIME LOE Review Escalation Notification', toAddresses,null,null) ;

			}
			catch(Exception e)
			{
				System.debug('Exception occured  :: ' + e.getMessage());
				string setEmailSub          = 'Exception: In sending mails for the CHIME LOE Review Notification or Case update.';
				string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
											  'Class Name = L2Q_LOE_Utility\n' +
											  'Method Name = setEscalationOrNotifyReviewers\n';
				errorMessage                += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
				SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
				sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
			}
        
        }
        
        try{
        
        	if(allCaseUpdate.size() > 0)
        	 Update allCaseUpdate;
        }
        catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: Exception Case Update. ';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                                          'Class Name = L2Q_LOE_Utility\n' +
                                          'Method Name = setEscalationOrNotifyReviewers\n';
            errorMessage                += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        } 

    }

    
    // Method 13 : to fetch the Reviewrs from GSS User Region based on Account Geo and Area
    public static Map<String, List<String>> getDynamicQuery(string EscType, String geo, String area)
    {
        List<Inv_WorkBox_Region_Mapping__c> reviewersFromGSSUserRegion = new List<Inv_WorkBox_Region_Mapping__c>();
        String Query            = '';
        List<String> toAddress  = new List<String>();
        Map<String, List<String>>   emailAndNameMap = new Map<String, List<String>>();
        emailAndNameMap.put('email', new List<String>());
        emailAndNameMap.put('name', new List<String>());

        if(EscType == 'SLM')
        {
            Query = 'SELECT Id, User__c,User__r.name, User__r.Email FROM Inv_WorkBox_Region_Mapping__c WHERE User__r.isActive = TRUE AND RecordType.Name = \'Chime\' AND TERR_HIER_3_F__c  =: area AND TERR_HIER_1_F__c  =: geo AND TERR_HIER_1__r.psa_Old__c = false ';
            reviewersFromGSSUserRegion = Database.query(Query);
    
            if(reviewersFromGSSUserRegion.isEmpty())
            {
                Query = 'SELECT Id, User__c, User__r.name, User__r.Email FROM Inv_WorkBox_Region_Mapping__c WHERE User__r.isActive = TRUE AND RecordType.Name = \'Chime\' AND TERR_HIER_1_F__c  =: geo  AND TERR_HIER_1__r.psa_Old__c = false ';
                reviewersFromGSSUserRegion = Database.query(Query);

            }
            for(Inv_WorkBox_Region_Mapping__c eReviewer : reviewersFromGSSUserRegion)
            {
                emailAndNameMap.get('email').add(eReviewer.User__r.Email);
                emailAndNameMap.get('name').add(eReviewer.User__r.Name);
                //toAddress.add(eReviewer.User__r.Email);
            }
        }
        else if(EscType == 'SLD1')
        {
            //future usage
        }
        else if(EscType == 'SLD2')
        {
            //future usage
        }
        else if(EscType == 'Admin')
        {
            for(PermissionSetAssignment ePSA : [SELECT Assignee.Email, Assignee.Name, Id FROM  PermissionSetAssignment WHERE PermissionSet.Name = 'Chime_Admin_Permission_Set'])
            {
                emailAndNameMap.get('email').add(ePSA.Assignee.Email);
                emailAndNameMap.get('name').add(ePSA.Assignee.Name);
                //toAddress.add(ePSA.Assignee.Email);
            }
        }
        return emailAndNameMap; 
    }
    
    // Method 14 : Send Email Method for all LOE use Cases
    public static void sendEmail_allUseCases(ID setWhatId, string templateName, List<String> toAddresses, string subject, string body) {
        System.debug('subject**'+subject);
        System.debug('body**'+body);
        System.debug('toAddresses**'+toAddresses);
		
	
		// Instantiating SingleEmailMessage
		List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
	
		// Setting all the Static Parameters
		email.setOrgWideEmailAddressId(CHIME_GSS_Settings__c.getall().values().From_Email_Add_OrgId__c); 	
		email.setUseSignature(false); 
		email.setSaveAsActivity(false);
		email.setToAddresses(toAddresses); 
		
		
		
		// If Template is selected then populate Template Attributes, else set Subject & body
		if(templateName != null){
		
			// Get the Template ID
			Id templateId = [select Id from EmailTemplate where Name = :templateName limit 1].Id;
            List<contact> contactRec = new List<contact>();
            contactRec = [select Id from contact where email IN :toAddresses];
            if (contactRec.size() == 0)
            {
                email.setTargetObjectId(CHIME_GSS_Settings__c.getall().values().Default_ContactId__c); 
            }else
            {
                email.setTargetObjectId(contactRec[0].Id); 
            }
			email.setWhatId(setWhatId);  
			email.setTemplateId(templateId); 
		}
		else{
		
			email.subject = subject;
            email.HtmlBody = body;
		}
	
		// Sending Email
		Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email}); 

	}


    // Method 14 : Review Complete
    @AuraEnabled
    public static void markChimeReviewComplete(Id chimeId){
        CHIME__c chimeRec = [Select Id,LOE_Review_Status__c,Is_All_LOE_Review_Complete__c,Is_Case_Button_Enabled__c,Review_Case_Id__c from CHIME__c where Id=:chimeId];
        //CHIME__c chimeRec = new CHIME__c(Id=chimeId);
        Case c = [Select Id,LOE_Review_Completed__c from Case where Id=:chimeRec.Review_Case_Id__c];
        chimeRec.LOE_Review_Status__c = 'Review Completed';
        chimeRec.Is_All_LOE_Review_Complete__c = true;
        chimeRec.Is_Case_Button_Enabled__c = true;


        update chimeRec;
        c.LOE_Review_Completed__c = System.today();
        update c;
    }

    // Method 15 : Get Reviewer Id
    @AuraEnabled
    public static Id getReviewerId(Id chimeId){
        Id reviewerId;
        CHIME__c chimeRec = [Select Id,	Review_Case_Id__c from CHIME__c where Id=:chimeId];
        if(chimeRec.Review_Case_Id__c != '' && chimeRec.Review_Case_Id__c != null){
            reviewerId = [Select Id,ownerId from Case where Id=:chimeRec.Review_Case_Id__c].ownerId;
        }
        return reviewerId;
    }

    // Method 16 : Get Admin Users Is
    @AuraEnabled
    public static List<Id> getAdminsId(){
        List<Id> adminsId = new List<Id>();
        for(PermissionSetAssignment iteratedPS : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Chime_Admin_Permission_Set']){
            adminsId.add(iteratedPS.AssigneeId);
        }
        return adminsId;
    }

    @AuraEnabled
    public static void sendReviewCompletionEmail(Id chimeId){
        List<String> emailAddresses = new List<String>();
        CHIME__c chimeRec = [Select Id,Name,createdBy.email,createdBy.Name from CHIME__c where id=: chimeId]; 
        emailAddresses.add(chimeRec.createdBy.email);
        String body = 'Hi '+chimeRec.createdBy.Name+',<br/>';
        body += 'Chime form '+chimeRec.Name+' is review completed :'+URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/CHIME__c/'+chimeId+'/view'+'<br/>';
        body += 'Thanks,'+'<br/>';
        body += 'LOE Team';
      //  String body = 'Hi '+ caseOwnerName+','+'\n Review Case case has been updated :'+URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/case/'+reviewCase+'/view';
        L2Q_LOE_Utility.sendEmail_allUseCases(null,null,emailAddresses,'Review completed for chime form',body);
        
    }

    // Method 18 : Method to get case number from id
    @auraEnabled
    public static Case getCaseNumber(Id caseId){
        return [Select Id,CaseNumber,Owner.Name from case where Id=:caseId];
    }

    @AuraEnabled(cacheable=true)
    public static CHIME__c getClosedChimeForm(String oppId) 
    {
        return [SELECT Id, Name from CHIME__c Where Opportunity__c =: oppId and Stage__c = 'Closed' order by LastModifiedDate desc limit 1 ]; 
    }

}
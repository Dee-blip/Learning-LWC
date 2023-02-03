public with sharing class chimePSTClass {
    public chimePSTClass() {

    }

    @AuraEnabled
    public static CHIME__C getChimeDetails(string chimeId){        

        // List<DSR_Chime_Product_Map__c> dsrchimeProdMap = new List<DSR_Chime_Product_Map__c>();
        // Map<String, String> prodMap = new Map<String, String>();
        // Boolean dsrMissing = false;

        // for (DSR_Chime_Product_Map__c dsrchimeMap : [select id , Chime_Product__c , DSR_Product__c from DSR_Chime_Product_Map__c WHERE RecordType.Name IN ('Chime to DSR Product Map') AND Active__c = true limit 40000] ) {
        //     prodMap.put(dsrchimeMap.Chime_Product__c.toLowercase(), dsrchimeMap.DSR_Product__c.toLowercase());
        // }
        // System.debug(' prds maps : ' + prodMap );

        // List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();
        // List<String> dsrApprovalMap = new List<String>();

        // dsrList = [select id , Approval_Status__c , CHIME__c , Product__c from Deal_Support_Request__c where CHIME__c = :chimeId ];

        // for (Deal_Support_Request__c eacDsr : dsrList) {
        //     dsrApprovalMap.add(eacDsr.Product__c.toLowercase());
        // }
        
        // System.debug(' dsr app map : ' + dsrApprovalMap );

        // List<Chime_Product_Association__c> chimeProductList = [Select Id,Name,CHIME__r.Is_Emergency__c,CHIME__r.Is_Work_At_Risk_Investment_Work__c,CHIME_Product__c,CHIME_Product__r.Product_Name__c,Review_Required__c,	Review_Reason__c,Review_Priority__c,Human_Review__c from Chime_Product_Association__c where CHIME__c =:chimeId];

        // for (Chime_Product_Association__c cpAssociation : chimeProductList) {
        //     System.debug(' unsd each : ' +  cpAssociation.CHIME_Product__r.Product_Name__c.toLowercase());

        //     System.debug(' unsd each :1 ' +  prodMap.get(cpAssociation.CHIME_Product__r.Product_Name__c.toLowercase()) + ' and :: ' + dsrApprovalMap.contains(prodMap.get(cpAssociation.CHIME_Product__r.Product_Name__c.toLowercase()) ));

        //     if ( !dsrApprovalMap.isEmpty() && !dsrApprovalMap.contains(prodMap.get(cpAssociation.CHIME_Product__r.Product_Name__c.toLowercase()).toLowercase() )  ) {
        //         dsrMissing = true;
        //     } else if (dsrApprovalMap.isEmpty()) {
        //         dsrMissing = true;
        //     }
        // }

        CHIME__c retchime = new CHIME__c();

        retchime = [select Id, Stage__c, CHIME_Name__c, Reopen_Reason__c,Notes__c, CreatedById, CreatedBy.Name, Account__c, Account__r.Name, Account__r.Type, Account__r.Owner.Name, Opportunity__c, Opportunity__r.Name, 
        Partner_Involved__c, Partner_Involved__r.Name,Implementation_Type__c, Is_Emergency__c,Is_Work_At_Risk_Investment_Work__c, Is_All_Qun_Ans_Complete__c,Status__c,LOE_Id__c,Total_LoE__c,Is_Case_Button_Enabled__c,Case_ID__c,Case_Description_UI__c,Integration_Case_ID__c,
        LOE_Review_Status__c,	Review_Case_Id__c, Sign_Off__c,Is_POC_Demo__c,Product_Approval_Status__c,Prolexic_Products__c,POC_Type__c from CHIME__c where Id =: chimeId];

        // if (dsrMissing == true) {
        //     retchime.Notes__c = 'dsrMissing';
        // }

        return retchime;
    }

    @AuraEnabled
    public static String getChimeProdDetails(Id chimeRecordId)
    {
        chimeWrapClass sampleWrapper = new chimeWrapClass();
        List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();
        List<DSR_Chime_Product_Map__c> dsrchimeProdMap = new List<DSR_Chime_Product_Map__c>();
        
        //sampleWrapper.severity = '';
        //sampleWrapper.reveiwCaseId = '';
        Map<String, String> prodMap = new Map<String, String>();
        for (DSR_Chime_Product_Map__c dsrchimeMap : [select id , Chime_Product__c , DSR_Product__c from DSR_Chime_Product_Map__c where RecordType.Name IN ('Chime to DSR Product Map') AND Active__c = true limit 40000] ) {

            //prodMap.put(dsrchimeMap.Chime_Product__c, dsrchimeMap.DSR_Product__c);
            if ( prodMap.containsKey(dsrchimeMap.DSR_Product__c.toLowercase()) ) {
                String tempSt = prodMap.get(dsrchimeMap.DSR_Product__c.toLowercase()) + ';' + dsrchimeMap.Chime_Product__c.toLowercase();
                prodMap.put(dsrchimeMap.DSR_Product__c.toLowercase(), tempSt);
            } else {
                prodMap.put(dsrchimeMap.DSR_Product__c.toLowercase(),dsrchimeMap.Chime_Product__c.toLowercase() );
            }
            
        }
        System.debug(' prod masp : ' + prodMap);
        CHIME__c chimeRec = [Select Id,Review_Case_Id__c,Status__c,Stage__c,LOE_Review_Status__c from CHIME__c where Id=: chimeRecordId];
        sampleWrapper.chimeRec = chimeRec;

        //Added by Ashin
        Map<String, String> dsrProdToApprovalMap = new Map<String, String>();
        Map<string,Deal_Support_Request__c > dsrProdToDSRMap = new Map<string,Deal_Support_Request__c>();
        dsrList = [select id , Approval_Status__c, Account__c , Opportunity__c , CHIME__c , CHIME__r.name , CHIME__r.CHIME_Name__c , Product__c from Deal_Support_Request__c where CHIME__c = :chimeRecordId ];
        List<productWrapperClass> productWrapList1 = new List<productWrapperClass>();
         
        //++++++++++++Below Added by Ashin+++++++++++++++++++++++
        for (Deal_Support_Request__c dsr : dsrList) {
			
            dsrProdToApprovalMap.put(dsr.Product__c.toLowercase(), dsr.Approval_Status__c );
            dsrProdToDSRMap.put(dsr.Product__c.toLowercase(),dsr);
         }
   
        List<String> chimeProductNames = new List<String>();
        List<String> finalDSRList = New List<String>();
        Map<String, string> finalDSRListToDisplay = New Map<String,string>();// Added by Ashin regrading UI formatting
        List<Chime_Product_Association__c> chimeProductAssociation = [Select Id,Name,CHIME__r.Is_Emergency__c,CHIME__r.Is_Work_At_Risk_Investment_Work__c,CHIME_Product__c,CHIME_Product__r.Product_Name__c,Review_Required__c, CHIME_Product__r.Business_Unit__c,Review_Reason__c,Review_Priority__c,Human_Review__c from Chime_Product_Association__c where CHIME__c =:chimeRecordId];
        for( Chime_Product_Association__c cpa: chimeProductAssociation){
            chimeProductNames.add(cpa.CHIME_Product__r.Product_Name__c.toLowercase());
        }        
        Map<String,string>DSRmapping= new Map<String,string>();
        Map<String,string>DSRmappingToDisplay= new Map<String,string>(); // Added by Ashin regrading UI formatting
        List<DSR_Chime_Product_Map__c> dsrMapList = [select id , Chime_Product__c , DSR_Product__c from DSR_Chime_Product_Map__c where RecordType.Name IN ('Chime to DSR Product Map') AND Active__c = true limit 40000];
        for(DSR_Chime_Product_Map__c dsr:dsrMapList)
        {
            DSRmapping.put(dsr.Chime_Product__c.toLowercase(),dsr.DSR_Product__c.toLowercase());
            DSRmappingToDisplay.put(dsr.Chime_Product__c.toLowercase(),dsr.DSR_Product__c);// Added by Ashin regrading UI formatting
        }
        for(string c:chimeProductNames)
        {
            if(DSRmapping.containsKey(c))
            {
                if(!finalDSRList.contains(DSRmapping.get(c)))
                {
				 finalDSRList.add(DSRmapping.get(c));  
                 finalDSRListToDisplay.put(DSRmapping.get(c),DSRmappingToDisplay.get(c)); // Added by Ashin regrading UI formatting
                }
            }
        }
	 	Map<String,string>DSRmapping1= new Map<String,string>();
        Map<String,String> productBUMap1 = new Map<String, String>();
        //Map<String,String> productApprovalMap = new Map<String, String>();
        for(DSR_Chime_Product_Map__c dsr1:dsrMapList)
        {
            DSRmapping1.put(dsr1.Chime_Product__c.toLowercase(),dsr1.DSR_Product__c.toLowercase());
        }
        for(Chime_Product_Association__c chpass:chimeProductAssociation)
        {
            if(chpass.CHIME_Product__r.Business_Unit__c=='Media')
            {
                productBUMap1.put(DSRmapping1.get(chpass.CHIME_Product__r.Product_Name__c.toLowercase()),'Media');
            }
            
        }
        list<DSR_Chime_Product_Map__c> dsrChimeProductList = [Select id, DSR_Product__c,PST_Case_Product__c from DSR_Chime_Product_Map__c WHERE RecordType.Name IN ('DSR to Case Product Map') And Active__c=true  ];
        Map<String,String> dsrChimeProductMap = new map<string,string>();
        for (DSR_Chime_Product_Map__c dcp : dsrChimeProductList)
        {
            dsrChimeProductMap.put(dcp.DSR_Product__c.toLowercase(),dcp.PST_Case_Product__c.toLowercase());
        }
        
        for(String s:finalDSRList)
        { 
            system.debug('+-+-+-'+finalDSRListToDisplay.get(s)); // Added by Ashin regrading UI formatting
            productWrapperClass prodWrapObj = new productWrapperClass();
            //prodWrapObj.prodName = s; //Commented by Ashin regrading UI formatting
            prodWrapObj.prodName = finalDSRListToDisplay.get(s); // Added by Ashin regrading UI formatting
            prodWrapObj.pstProdName=dsrChimeProductMap.get(s);
            
			prodWrapObj.dealsupport= dsrProdToDSRMap.get(s);
			if(productBUMap1.get(s)=='Media')
            {
                if(!dsrProdToApprovalMap.containsKey(s))
                {
                    prodWrapObj.justificationNeeded = false;
                    prodWrapObj.justificationStr = 'DSR is not yet associated with this product';
                }
                else
                {
                prodWrapObj.justificationNeeded = true;
                prodWrapObj.justificationStr = 'Media Product - DSR Approval not required';
                } 
            }
            else if(dsrProdToApprovalMap.containsKey(s) && dsrProdToApprovalMap.get(s)=='Approved')
            {
                prodWrapObj.justificationNeeded = true;
                prodWrapObj.justificationStr = 'Justification not required - DSR approved';
            }
            else if(dsrProdToApprovalMap.containsKey(s) && dsrProdToApprovalMap.get(s)!='Approved')
            {
                prodWrapObj.justificationNeeded = false;
                prodWrapObj.justificationStr = 'Please Enter Justification since DSR is not approved';
            }
            else if(!dsrProdToApprovalMap.containsKey(s))
            {
                prodWrapObj.justificationNeeded = false;
                prodWrapObj.justificationStr = 'DSR is not yet associated with this product';
            }
            productWrapList1.add(prodWrapObj);
        }
       
        //++++++++++++++++Above Added by Ashin+++++++++++++++++++++++++
        
        List<String> chimeProdNames = new List<String>();
        Map<String,String> productBUMap = new Map<String, String>();
        List<Chime_Product_Association__c> chimeProductList = [Select Id,Name,CHIME__r.Is_Emergency__c,CHIME__r.Is_Work_At_Risk_Investment_Work__c,CHIME_Product__c,CHIME_Product__r.Product_Name__c,Review_Required__c, CHIME_Product__r.Business_Unit__c,	Review_Reason__c,Review_Priority__c,Human_Review__c from Chime_Product_Association__c where CHIME__c =:chimeRecordId];
        for( Chime_Product_Association__c eachAssoc: chimeProductList){
            chimeProdNames.add(eachAssoc.CHIME_Product__r.Product_Name__c.toLowercase());
            productBUMap.put(eachAssoc.CHIME_Product__r.Product_Name__c.toLowercase(), eachAssoc.CHIME_Product__r.Business_Unit__c);
        }

        System.debug(' chime prod names :  ' + chimeProdNames );

        List<productWrapperClass> productWrapList = new List<productWrapperClass>();

        for (Deal_Support_Request__c eachdsr : dsrList) {
            
            //System.debug(' und each : ' + eachdsr.Product__c + ' prod ma :  ' + prodMap.get(eachdsr.Product__c.toLowercase()).split(';') + ' :prod ? : ' +  prodMap.get(eachdsr.Product__c.toLowercase()) );
            Boolean multipleCProd = false ;
            if ( prodMap.get(eachdsr.Product__c.toLowercase()) != null && prodMap.get(eachdsr.Product__c.toLowercase()).contains(';') ) {
                List<String> products = new List<String>();
                products.addAll( prodMap.get(eachdsr.Product__c.toLowercase()).split(';') );
                for (String eachStr : products) {
                    if (chimeProdNames.contains(eachStr.toLowercase())) {
                        multipleCProd = true;
                    }
                }
            }

            System.debug(' eachhc : ' + prodMap.get(eachdsr.Product__c.toLowercase())  );

            /*if ( chimeProdNames.contains( prodMap.get(eachdsr.Product__c.toLowercase()).toLowercase() ) || (multipleCProd) ) {

                productWrapperClass prodWrapObj = new productWrapperClass();
                prodWrapObj.dealsupport = eachdsr;

                if ( productBUMap.get( prodMap.get(eachdsr.Product__c.toLowercase()).toLowercase() ) == 'Media' ) {
                    prodWrapObj.justificationNeeded = true;
                    prodWrapObj.justificationStr = 'Media Product - DSR Approval not required';
                    System.debug('loggss s ');
                } else if(eachdsr.Approval_Status__c == 'Approved'){
                    prodWrapObj.justificationNeeded = true;
                    prodWrapObj.justificationStr = 'Justification not required - DSR approved';
                }
                 else {
                    prodWrapObj.justificationNeeded = false;
                    prodWrapObj.justificationStr = 'Please Enter Justification since DSR is not approved';
                }
                productWrapList.add(prodWrapObj);   
            }*/
        }

        if (productWrapList1 != null && !productWrapList1.isEmpty() ) {
            sampleWrapper.productList = productWrapList1;
            sampleWrapper.chimeProducts = chimeProdNames ;
            

            System.debug('samp wr ' + sampleWrapper.productList );
            
            return JSON.serialize(sampleWrapper);
        } else {
            return 'error';
        }

    }

    @AuraEnabled
    public static string createChimeCase(List<String> dsrJustificationList, String productListStr, String chimeNotes, List<String> chimeProdNames ){
        System.debug(' drs just l ' + dsrJustificationList );
        system.debug('>>>chomeProdNames are '+chimeProdNames);
        List<productWrapperClass> productList = new List<productWrapperClass>();
        System.debug(' drs just lstr  ' + productListStr );
        productList = ((List<productWrapperClass>)system.JSON.deserialize(productListStr, List<productWrapperClass>.class));
        System.debug(' plist : '  + productList.size()  );
        String accountId = productList[0].dealsupport.Account__c;
        String oppId = productList[0].dealsupport.Opportunity__c;
        List<Case> casestoInsert = new List<Case>();
        Map<String, String> dsrchimeProdMap = new Map<String, String>();
        
        Map<String, String> prodMap = new Map<String, String>();
        for (DSR_Chime_Product_Map__c dsrchimeMap : [select id , Chime_Product__c , DSR_Product__c from DSR_Chime_Product_Map__c where RecordType.Name IN ('Chime to DSR Product Map') AND Active__c = true limit 40000] ) {

            //prodMap.put(dsrchimeMap.Chime_Product__c, dsrchimeMap.DSR_Product__c);
            prodMap.put(dsrchimeMap.DSR_Product__c.toLowercase(),dsrchimeMap.Chime_Product__c.toLowercase() );
            if (chimeProdNames.contains(dsrchimeMap.Chime_Product__c.toLowercase())) {
                if(dsrchimeProdMap.containsKey(dsrchimeMap.DSR_Product__c.toLowercase()))
                {
                    // below line modified by Ashin regrading UI formatting - removed .toLowercase() from map values
                    String tempStr = '-'+ dsrchimeProdMap.get(dsrchimeMap.DSR_Product__c.toLowercase()) + '\n ' +'-'+ dsrchimeMap.Chime_Product__c;
                    dsrchimeProdMap.put(dsrchimeMap.DSR_Product__c.toLowercase(), tempStr);
                } else {
                    dsrchimeProdMap.put(dsrchimeMap.DSR_Product__c.toLowercase(), dsrchimeMap.Chime_Product__c);
                }
            }
        }
		
        list<DSR_Chime_Product_Map__c> dsrChimeProductList = [Select id, DSR_Product__c,PST_Case_Product__c from DSR_Chime_Product_Map__c WHERE RecordType.Name IN ('DSR to Case Product Map') And Active__c=true  ];
        Map<String,String> dsrChimeProductMap = new map<string,string>();
        Map<String,String> dsrChimeProductMapToDisplay = new map<string,string>(); //Added by Ashin regatding UI formatting
        for (DSR_Chime_Product_Map__c dcp : dsrChimeProductList)
        {
            dsrChimeProductMap.put(dcp.DSR_Product__c.toLowercase(),dcp.PST_Case_Product__c.toLowercase());
            dsrChimeProductMapToDisplay.put(dcp.DSR_Product__c.toLowercase(),dcp.DSR_Product__c); //Added by Ashin regatding UI formatting
        }
        
        string recTypeId  = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' and DeveloperName = 'PST_Case' limit 1].Id; 
        Integer count  = 0 ;
        
        System.debug(' acc from DSR : ' + accountId );
        //Only this if condition statement is added by Ashin on Feb 10 - 2022
        if(dsrJustificationList.size()>0)
        {
        for (String drsProd : dsrJustificationList) {
            System.debug('logs ' + dsrchimeProdMap.get(productList[count].dealsupport.Product__c.toLowercase() ) );
            system.debug('++++++ '+productList[count].dealsupport.Product__c.toLowercase());
            system.debug('=== '+drsProd); // Added by Ashin regrading UI formatting
            // below if else statement Added by Ashin regrading UI formatting
            if(drsProd!= '')
            {
            String pasnotes = chimeNotes == null? '' : ' \nNotes : ' + chimeNotes ;
            casestoInsert.add(createCase(accountId,oppId,recTypeId,'3','Chime Standard Trial / PoC Request - ' + productList[count].dealsupport.CHIME__r.CHIME_Name__c , 'Chime:' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + productList[count].dealsupport.CHIME__c + ' \n\n This is a Standard PoC request. \n\nJustification : ' + drsProd + '\n'+pasnotes + '\n\nChime Products are:- '+'\n'+ dsrchimeProdMap.get(productList[count].dealsupport.Product__c.toLowercase() ) +'\n\nDSR Product is:- ' +dsrChimeProductMapToDisplay.get(productList[count].dealsupport.Product__c.toLowercase()) , 'Trial / PoC' , 'PoC(PST)', '' , 'Autogen' , productList[count].dealsupport.CHIME__c , productList[count].dealsupport.Id  ,dsrChimeProductMap.get(productList[count].dealsupport.Product__c.toLowercase()) ));
            count ++;
            }
            else if(drsProd== '')
            {
                String pasnotes = chimeNotes == null? '' : ' \nNotes : ' + chimeNotes ;
            casestoInsert.add(createCase(accountId,oppId,recTypeId,'3','Chime Standard Trial / PoC Request - ' + productList[count].dealsupport.CHIME__r.CHIME_Name__c , 'Chime:' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + productList[count].dealsupport.CHIME__c + ' \n\n This is a Standard PoC request. \n\nJustification : ' + 'N/A' + pasnotes + '\n\nChime Products are:- '+'\n'+ dsrchimeProdMap.get(productList[count].dealsupport.Product__c.toLowercase() ) +'\n\nDSR Product is:- ' +dsrChimeProductMapToDisplay.get(productList[count].dealsupport.Product__c.toLowercase()), 'Trial / PoC' , 'PoC(PST)', '' , 'Autogen' , productList[count].dealsupport.CHIME__c , productList[count].dealsupport.Id  ,dsrChimeProductMap.get(productList[count].dealsupport.Product__c.toLowercase()) ));
            count ++;
            }
        }
        }
        //Only this above if condition statement is added by Ashin on Feb 10 - 2022
        System.debug('case to in ' + casestoInsert);
        insert casestoInsert;
        return 'true';
        
    }
    
    public static case createCase(
        String accName,
        String opp,
        String caseRecType,
        String severity,
        String subject, 
        String descp,
        String service,
        String reqType,
        String caseOwener,
        String erssform,
        String chimeform,
        String dsr,
        String pstcaseProduct
    )
    {
        //List<Case> caseListtoInsert = new List<Case>();
        case newCase = new case();
        System.debug('acc t : ' + descp);
        newCase.AccountId = accName;
        newCase.Description = descp;
        newCase.Subject = subject;
        newCase.Opportunity__c = opp;
        newCase.Severity__c = severity;
        System.debug('pst prd ' + pstcaseProduct);
        //newCase.PST_Case_Product__c = 'Media Services Live 4; mPulse; Page Integrity Manager';
        newCase.PST_Case_Product__c = pstcaseProduct;
        newCase.RecordTypeId = caseRecType;
        newCase.Service__c = service;
        newCase.Request_Type__c = reqType;
        newCase.Chime_Form__c = chimeform;
        newCase.Deal_Support_Request__c = dsr;
        newCase.Origin = 'Autogen';
        newCase.Chime_Case_Type__c = 'Chime PST Case';
        return newCase;
    }


    public static void loeClone(Id newChimeId, Id oldChimeId)
    {
        List<Chime_Features_LoE__c> testLi = new List<Chime_Features_LoE__c>();
        Map<Id, Decimal> featuretoUnitMap = new Map<Id, Decimal>();
        Map<Id, Decimal> featuretoLoeMap = new Map<Id, Decimal>();
        Map<Id, Boolean> featuretoSelectedMap = new Map<Id, Boolean>();
        //List<Chime_Features_LoE__c> AllchimeFeatures = new List<Chime_Features_LoE__c>();
        List<Chime_Features_LoE__c> NewchimeFeatures = new List<Chime_Features_LoE__c>();
        List<Chime_Product_Association__c> chimeProdAssoctoUpdate = new List<Chime_Product_Association__c>();
        
        List<Id> chimeIds = new List<Id>();
        Map<Id , Decimal> pacProdtoLoe = new Map<Id, Decimal>();
        Map<Id, String> pacProducttoImp = new Map<Id, String>();
        // testLi = [select id , Chime_Product__r.chime__c , Chime_Product__r.CHIME_Product__r.Name from Chime_Features_LoE__c where  Chime_Product__r.chime__c =:newChimeId limit 40000];
        
        // System.debug('checking issu ' + testLi.size() );
        chimeIds.add(newChimeId);
        chimeIds.add(oldChimeId);

        List<Chime_Product_Association__c> chimeProdAssList = new List<Chime_Product_Association__c>();
        //AllchimeFeatures = [select id , LoE__c , Chime_Product__r.chime__c ,Feature__c,Units__c, Chime_Product__r.CHIME_Product__r.Name from Chime_Features_LoE__c where  Chime_Product__r.chime__c IN :chimeIds limit 40000];  

        List<Chime_Product_Association__c> chimeProdandFeaturesL = new List<Chime_Product_Association__c>( [select id,CHIME__c, CHIME__r.POC_Type__c , CHIME__r.Is_POC_Demo__c , CHIME__r.Implementation_Type__c ,CHIME_Product__c, CHIME_Product__r.TPM_for_calculation__c , CHIME_Product__r.Percentage_TPM_hours_in__c , CHIME_Product__r.Minimum_TPM__c ,Total_LoE__c,Product_Implementation_Mode__c, (select id, LoE__c, Units__c, Is_Selected__c , Feature__c from Chime_Features_LoEs__r ) from Chime_Product_Association__c where CHIME__c IN: chimeIds ] );

        for(Chime_Product_Association__c prodAssoc: chimeProdandFeaturesL)
        {
            if(prodAssoc.CHIME__c == oldChimeId )
            {
                pacProdtoLoe.put(prodAssoc.CHIME_Product__c, prodAssoc.Total_LoE__c);
                pacProducttoImp.put(prodAssoc.CHIME_Product__c,prodAssoc.Product_Implementation_Mode__c );

                for(Chime_Features_LoE__c eachFeature : prodAssoc.Chime_Features_LoEs__r)
                {
                    featuretoUnitMap.put(eachFeature.Feature__c, eachFeature.Units__c );
                    featuretoLoeMap.put(eachFeature.Feature__c, eachFeature.LoE__c ); 
                    featuretoSelectedMap.put(eachFeature.Feature__c, eachFeature.Is_Selected__c);
                }
            }
        }

        for(Chime_Product_Association__c prodAssoc: chimeProdandFeaturesL)
        {
            if(prodAssoc.CHIME__c == newChimeId )
            {   
                System.debug('new chime while clne');
                prodAssoc.Total_LoE__c = pacProdtoLoe.get(prodAssoc.CHIME_Product__c);
                System.debug('newss vall : 3 ::' + prodAssoc.Total_LoE__c );
                Decimal totLoe = 0.0;
                

                for(Chime_Features_LoE__c eachFeature : prodAssoc.Chime_Features_LoEs__r)
                {
                    eachFeature.Units__c = featuretoUnitMap.get( eachFeature.Feature__c );
                    eachFeature.LoE__c = featuretoLoeMap.get( eachFeature.Feature__c);
                    eachFeature.Is_Selected__c =  featuretoSelectedMap.get(eachFeature.Feature__c);
                    newChimeFeatures.add(eachFeature);
                    if (eachFeature.Is_Selected__c) {
                        totLoe = totLoe + eachFeature.LoE__c;
                    }
                    
                }

                System.debug(' totl wrong > : ' + totLoe);

                Decimal calculatedTPM = ( ( (totLoe) * (prodAssoc.CHIME_Product__r.Percentage_TPM_hours_in__c)) / 100);
                Decimal actTpm = calculatedTPM > prodAssoc.CHIME_Product__r.Minimum_TPM__c ? calculatedTPM : prodAssoc.CHIME_Product__r.Minimum_TPM__c ;

                if ( prodAssoc.CHIME__r.POC_Type__c == 'Custom-POC' ) {
                    prodAssoc.Product_Implementation_Mode__c = pacProducttoImp.get(prodAssoc.CHIME_Product__c);
                    if( prodAssoc.CHIME__r.Implementation_Type__c == 'Standard & Managed' && (prodAssoc.Product_Implementation_Mode__c == pacProducttoImp.get(prodAssoc.CHIME_Product__c) ) && prodAssoc.Product_Implementation_Mode__c == 'Managed' )
                    {
                        prodAssoc.Total_LoE__c = prodAssoc.Total_LoE__c - actTpm ;
                    }

                    System.debug('newws all : ' +  prodAssoc.Total_LoE__c);
                }
                
                if ( prodAssoc.CHIME__r.Is_POC_Demo__c == false && (prodAssoc.Product_Implementation_Mode__c != pacProducttoImp.get(prodAssoc.CHIME_Product__c) )  ) 
                {
                    System.debug('dis etner :: ' +  actTpm  + '  cal tpm : ' + calculatedTPM + ' prodAssoc.Total_LoE__c : '  + prodAssoc.Total_LoE__c);
                    if (prodAssoc.Product_Implementation_Mode__c == 'Managed')
                    {
                        prodAssoc.Total_LoE__c = prodAssoc.Total_LoE__c + actTpm ;
                    } else if (prodAssoc.Product_Implementation_Mode__c == 'Standard') {

                        prodAssoc.Total_LoE__c = prodAssoc.Total_LoE__c - actTpm ;
                    } 
                }

                chimeProdAssoctoUpdate.add(prodAssoc);


                System.debug('newss vall : 4 : ' + prodAssoc.Total_LoE__c );
            }
        }
        

        if( !newChimeFeatures.isEmpty() && newChimeFeatures != null && newChimeFeatures.size() > 0 )
        {
            update newChimeFeatures;
            update chimeProdAssoctoUpdate;
        }

    }



    public class chimeWrapClass{
       
        @AuraEnabled
        public List<productWrapperClass> productList;
       
        @AuraEnabled
        public CHIME__c chimeRec;

        @AuraEnabled
        public string justification;

        @AuraEnabled
        public List<String> chimeProducts;

    }

    public class productWrapperClass{
        @AuraEnabled
        public Deal_Support_Request__c dealsupport;
        
        @AuraEnabled
        public string prodName;
        
        @AuraEnabled
        public string pstProdName;

        @AuraEnabled
        public Boolean justificationNeeded;

        @AuraEnabled
        public string justificationStr;
        
    }
}
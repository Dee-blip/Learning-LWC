/**
**/
public class L2Q_ChimeProductAssociationController {
    // Update review required field on Chime Product Association
    public static void updateReviewRequiredField(List<Chime_Product_Association__c> newList){
        List<Id> parentChimeFormIds = new List<Id>();
        List<Id> productIds = new List<Id>();
        Map<Id,CHIME__c> chimeRecsMap = new Map<Id,CHIME__c>();
        Map<Id,PAC_Product_Catalog__c> productMap = new Map<Id,PAC_Product_Catalog__c>();
        //ESESP-5314 update
        List<CHIME__c> chimeRecsToMarkReviewRequired = new List<CHIME__c>();
        List<CHIME__c> chimeRecsToMarkReviewRequiredFinal = new List<CHIME__c>();
        Set<CHIME__c> chimeRecsSetToMarkReviewRequired = new Set<CHIME__c>();
        
        CHIME__c tempChimeRec = new CHIME__c();
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            parentChimeFormIds.add(iteratedChimeProduct.CHIME__c);
            productIds.add(iteratedChimeProduct.CHIME_Product__c);
        }
        chimeRecsMap= new Map<Id,CHIME__c>([Select Id,Is_Emergency__c ,Is_Work_At_Risk_Investment_Work__c,Implementation_Type__c ,POC_Type__c,LOE_Review_Status__c from CHIME__c where Id IN: parentChimeFormIds]);
        productMap = new Map<Id,PAC_Product_Catalog__c>([Select Id,Review_Required__c,Marketing_Category__c, Product_Name__c from PAC_Product_Catalog__c where Id IN:productIds]);
        for(Chime_Product_Association__c iteratedChimeProduct : newList){

            System.debug('befor eifii :');
        
            if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Is_Work_At_Risk_Investment_Work__c || chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Is_Emergency__c  || productMap.get(iteratedChimeProduct.CHIME_Product__c).Review_Required__c){
                System.debug(' which cntd : for prodt : ' + productMap.get(iteratedChimeProduct.CHIME_Product__c).Product_Name__c );
                Boolean contn1 = chimeRecsMap.get(iteratedChimeProduct.CHIME__c).POC_Type__c != 'Custom-POC' ;
                Boolean contn2 = chimeRecsMap.get(iteratedChimeProduct.CHIME__c).POC_Type__c == 'Custom-POC' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c == 'Standard' && productMap.get(iteratedChimeProduct.CHIME_Product__c).Marketing_Category__c != 'Enterprise Security' && productMap.get(iteratedChimeProduct.CHIME_Product__c).Review_Required__c ;
                Boolean contn3 = chimeRecsMap.get(iteratedChimeProduct.CHIME__c).POC_Type__c == 'Custom-POC' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c != 'Standard' && productMap.get(iteratedChimeProduct.CHIME_Product__c).Review_Required__c ;
                Boolean contn4 = chimeRecsMap.get(iteratedChimeProduct.CHIME__c).POC_Type__c == 'Custom-POC' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c == 'Standard' && productMap.get(iteratedChimeProduct.CHIME_Product__c).Marketing_Category__c == 'Enterprise Security' ;
                System.debug(' which cntd :1 ' +  contn1 );
                System.debug(' which cntd :2 ' + contn2 );
                System.debug(' which cntd :3 ' + contn3 );
                System.debug(' which cntd :4 ' + contn4 );
                
                if( contn1 )
                {
                    iteratedChimeProduct.Review_Required__c = true;
                    if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Awaiting Assignment' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Being Reviewed' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Review Completed'){
                        tempChimeRec = chimeRecsMap.get(iteratedChimeProduct.CHIME__c);
                        tempChimeRec.LOE_Review_Status__c = 'Review required';
                        chimeRecsToMarkReviewRequired.add(tempChimeRec);
                    }
                } else if( contn2  )
                {
                    iteratedChimeProduct.Review_Required__c = true;
                    if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Awaiting Assignment' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Being Reviewed' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Review Completed'){
                        tempChimeRec = chimeRecsMap.get(iteratedChimeProduct.CHIME__c);
                        tempChimeRec.LOE_Review_Status__c = 'Review required';
                        chimeRecsToMarkReviewRequired.add(tempChimeRec);
                    }
                } else if( contn3 )
                {
                    iteratedChimeProduct.Review_Required__c = true;
                    if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Awaiting Assignment' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Being Reviewed' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Review Completed'){
                        tempChimeRec = chimeRecsMap.get(iteratedChimeProduct.CHIME__c);
                        tempChimeRec.LOE_Review_Status__c = 'Review required';
                        chimeRecsToMarkReviewRequired.add(tempChimeRec);
                    }
                } else if ( contn4)
                {
                    iteratedChimeProduct.Review_Required__c = false;
                    iteratedChimeProduct.Total_LoE__c = 0;
                    if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Awaiting Assignment' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Being Reviewed' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Review Completed'){
                        //tempChimeRec = chimeRecsMap.get(iteratedChimeProduct.CHIME__c);
                        //tempChimeRec.LOE_Review_Status__c = 'Review not required';
                        //chimeRecsToMarkReviewRequired.add(tempChimeRec);
                    }

                }
                
            }
            if( !productMap.get(iteratedChimeProduct.CHIME_Product__c).Review_Required__c && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).POC_Type__c == 'Custom-POC' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c == 'Standard' && productMap.get(iteratedChimeProduct.CHIME_Product__c).Marketing_Category__c == 'Enterprise Security' )
            {
                System.debug('this is changing ');
                iteratedChimeProduct.Review_Required__c = false;
                iteratedChimeProduct.Total_LoE__c = 0;
                if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Awaiting Assignment' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Being Reviewed' && chimeRecsMap.get(iteratedChimeProduct.CHIME__c).LOE_Review_Status__c != 'Review Completed'){
                    //tempChimeRec = chimeRecsMap.get(iteratedChimeProduct.CHIME__c);
                    //tempChimeRec.LOE_Review_Status__c = 'Review not required';
                    //chimeRecsToMarkReviewRequired.add(tempChimeRec);
                }
            }
        } 

        if(chimeRecsToMarkReviewRequired.size() > 0){
            System.debug(' ins this ? ');
            chimeRecsSetToMarkReviewRequired.addAll(chimeRecsToMarkReviewRequired);
            chimeRecsToMarkReviewRequiredFinal.addAll(chimeRecsSetToMarkReviewRequired);
            update chimeRecsToMarkReviewRequiredFinal;
           
        }  


         

    }

    // Set default implementation mode field on Chime Product Association
    public static void updateImplementationMode (List<Chime_Product_Association__c> newList){
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            iteratedChimeProduct.LOE_Implementation_Mode__c = 'Baseline';
        }    
    }

    // Set default product implementation mode field on Chime Product Association
    public static void updateProductImplementationMode (List<Chime_Product_Association__c> newList){
        List<Id> parentChimeId= new List<Id>();
        List<Id> chimeProductIds = new List<Id>();
        Map<Id,CHIME__c> chimeRecsMap = new Map<Id,CHIME__c>();
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            parentChimeId.add(iteratedChimeProduct.CHIME__c);
            chimeProductIds.add(iteratedChimeProduct.CHIME_Product__c);
            
        } 
        chimeRecsMap= new Map<Id,CHIME__c>([Select Id,Implementation_Type__c from CHIME__c where Id IN: parentChimeId]);
        Map<Id, PAC_Product_Catalog__c> pacProductMap = new Map<Id, PAC_Product_Catalog__c>([Select Id,LoE_hours_sum_from_features__c,Default_LOE_Standard__c,	Default_LOE_Managed__c From PAC_Product_Catalog__c]);
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c != 'Standard & Managed'){
            iteratedChimeProduct.Product_Implementation_Mode__c = chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c;
            }

          //  if(pacProductMap.get(iteratedChimeProduct.CHIME_Product__c).LoE_hours_sum_from_features__c != 0){
                if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c == 'Standard'){
                    iteratedChimeProduct.Total_LoE__c = pacProductMap.get(iteratedChimeProduct.CHIME_Product__c).Default_LOE_Standard__c;
                }else if(chimeRecsMap.get(iteratedChimeProduct.CHIME__c).Implementation_Type__c == 'Managed'){
                    iteratedChimeProduct.Total_LoE__c = pacProductMap.get(iteratedChimeProduct.CHIME_Product__c).Default_LOE_Managed__c;
                }else{
                    iteratedChimeProduct.Total_LoE__c = pacProductMap.get(iteratedChimeProduct.CHIME_Product__c).Default_LOE_Standard__c;
                }
          /*  }else{
                iteratedChimeProduct.Total_LoE__c = 0;
            }*/
        }    
    }

   

    //Create Chime Feature LOE recs 
    public static void createChimeFeatureLOERecords(List<Chime_Product_Association__c> newList){
        List<Id> chimeProductIds = new List<Id>();
        List<PAC_Product_Features__c> featuresList = new List<PAC_Product_Features__c>();
        Map<Id,List<PAC_Product_Features__c>> productVsFeaturesList = new Map<Id,List<PAC_Product_Features__c>>();
        List<Chime_Features_LoE__c> chimeFeaturesList = new List<Chime_Features_LoE__c>();
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            chimeProductIds.add(iteratedChimeProduct.CHIME_Product__c);
        }
        featuresList = [Select Id,Active__c,Default_Feature__c,Feature_Name__c,Description__c,Name,Review_Required__c,Scope_of_Work__c,Unit_Type__c,First_Unit_LOE_In_Hours__c,Product__c,  Additional_Unit_LoE_In_Hours__c from PAC_Product_Features__c where Active__c = true AND Product__c IN: chimeProductIds];
        if(featuresList.size() > 0){
            for(PAC_Product_Features__c iteratedFeature : featuresList){
                if(productVsFeaturesList.get(iteratedFeature.Product__c) != null){
                    productVsFeaturesList.get(iteratedFeature.Product__c).add(iteratedFeature);
                }else{
                    List<PAC_Product_Features__c> tempFeatureList = new List<PAC_Product_Features__c>();
                    tempFeatureList.add(iteratedFeature);
                    productVsFeaturesList.put(iteratedFeature.Product__c,tempFeatureList);
                }
            }
        }
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
           // iteratedChimeProduct.LOE_Implementation_Mode__c = 'Baseline';
           if(productVsFeaturesList.get(iteratedChimeProduct.CHIME_Product__c) != null && productVsFeaturesList.get(iteratedChimeProduct.CHIME_Product__c).size() > 0){
                for(PAC_Product_Features__c iteratedFeature : productVsFeaturesList.get(iteratedChimeProduct.CHIME_Product__c)){
                    System.debug('Iterated feature:***'+iteratedFeature.Id);
                    Chime_Features_LoE__c chimeFeature = new Chime_Features_LoE__c();
                    chimeFeature.Chime_Product__c = iteratedChimeProduct.Id;
                    chimeFeature.Feature__c = iteratedFeature.Id;
                    chimeFeature.Is_Selected__c = iteratedFeature.Default_Feature__c;
                    chimeFeature.LoE__c = iteratedFeature.First_Unit_LOE_In_Hours__c;
                    chimeFeature.Units__c = 1;
                    chimeFeature.Unit_Type__c = iteratedFeature.Unit_Type__c;
                    chimeFeature.Feature_Active_at_creation__c = iteratedFeature.Active__c;
                    chimeFeaturesList.add(chimeFeature);
                }
            } 
        } 
        if(chimeFeaturesList.size() > 0){
            Insert chimeFeaturesList;
        }   

    }



    public static void updateChimeProductReviewRequired(List<Chime_Product_Association__c> newList){
     

        List<Id> chimeProductIds = new List<Id>();
        List<PAC_Product_Features__c> featuresList = new List<PAC_Product_Features__c>();
        Map<Id,List<PAC_Product_Features__c>> productVsFeaturesList = new Map<Id,List<PAC_Product_Features__c>>();
        List<Chime_Features_LoE__c> chimeFeaturesList = new List<Chime_Features_LoE__c>();
        //ESESP-5314 updates 
        Set<Id> chimeIdsToMarkReview = new Set<Id>();
        List<CHIME__c> chimeRecsToMarkReview = new List<CHIME__c>();
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            chimeProductIds.add(iteratedChimeProduct.CHIME_Product__c);
        }
        featuresList = [Select Id,Active__c,Default_Feature__c,Feature_Name__c,Description__c,Name,Review_Required__c,Scope_of_Work__c,Unit_Type__c,First_Unit_LOE_In_Hours__c,Product__c,  Additional_Unit_LoE_In_Hours__c from PAC_Product_Features__c where Active__c = true AND Product__c IN: chimeProductIds];
        if(featuresList.size() > 0){
            for(PAC_Product_Features__c iteratedFeature : featuresList){
                if(productVsFeaturesList.get(iteratedFeature.Product__c) != null){
                    productVsFeaturesList.get(iteratedFeature.Product__c).add(iteratedFeature);
                }else{
                    List<PAC_Product_Features__c> tempFeatureList = new List<PAC_Product_Features__c>();
                    tempFeatureList.add(iteratedFeature);
                    productVsFeaturesList.put(iteratedFeature.Product__c,tempFeatureList);
                }
            }
        }
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            if(productVsFeaturesList.get(iteratedChimeProduct.CHIME_Product__c) == null || productVsFeaturesList.get(iteratedChimeProduct.CHIME_Product__c).size() == 0){
            
                iteratedChimeProduct.Review_Required__c = true;
                chimeIdsToMarkReview.add(iteratedChimeProduct.CHIME__c);
            }
        } 
        if(chimeIdsToMarkReview.size() > 0){
            chimeRecsToMarkReview = [Select Id,LOE_Review_Status__c from CHIME__c where Id IN: chimeIdsToMarkReview AND LOE_Review_Status__c != 'Awaiting Assignment' AND LOE_Review_Status__c != 'Review Completed' AND LOE_Review_Status__c != 'Being Reviewed'];
            for(CHIME__c iteratedChimeRec : chimeRecsToMarkReview){
                iteratedChimeRec.LOE_Review_Status__c = 'Review required';
            }
            update chimeRecsToMarkReview;
        } 
    } 

     // Update LoE hours on Chime Product on Implementation Mode change
     public static void updateTotalLoEOnModeChange (List<Chime_Product_Association__c> newList,Map<Id,Chime_Product_Association__c> oldMap){
         System.debug('hereee');
        List<Id> pacProductId = new List<Id>();
        Map<Id,PAC_Product_Catalog__c> pacProdMap = new Map<Id,PAC_Product_Catalog__c>();
        List<Chime_Product_Association__c> targetChimeProducts = new List<Chime_Product_Association__c>();
        Double offSetValue = 0;
        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            if(iteratedChimeProduct.Product_Implementation_Mode__c != oldMap.get(iteratedChimeProduct.Id).Product_Implementation_Mode__c){
                targetChimeProducts.add(iteratedChimeProduct);
                pacProductId.add(iteratedChimeProduct.CHIME_Product__c);
            }
        }
        pacProdMap = new Map<Id,PAC_Product_Catalog__c>([Select Id,	Minimum_TPM__c,Percentage_TPM_hours_in__c,Tech_Overhead_Exempt__c,Technical_Overhead__c from PAC_Product_Catalog__c where Id IN: pacProductId]);
        for(Chime_Product_Association__c iteratedChimeProduct : targetChimeProducts){
            offSetValue = 0;
            
           /* System.debug('1**'+iteratedChimeProduct.Features_LoE_Sum__c);
            System.debug('2**'+pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Percentage_TPM_hours_in__c);
            System.debug('3**'+pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Minimum_TPM__c);*/
            if( ((iteratedChimeProduct.Features_LoE_Sum__c * pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Percentage_TPM_hours_in__c) / 100 ) < pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Minimum_TPM__c){
                offSetValue = pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Minimum_TPM__c; 
            }else{
                offSetValue = (iteratedChimeProduct.Features_LoE_Sum__c * pacProdMap.get(iteratedChimeProduct.CHIME_Product__c).Percentage_TPM_hours_in__c) / 100 ;
            }

            
            if(iteratedChimeProduct.Product_Implementation_Mode__c == 'Standard'){
                iteratedChimeProduct.Total_LoE__c = iteratedChimeProduct.Total_LoE__c  - offSetValue;
            }else if(iteratedChimeProduct.Product_Implementation_Mode__c == 'Managed'){
                System.debug('changed here :: ' + iteratedChimeProduct.Total_LoE__c );
                iteratedChimeProduct.Total_LoE__c = iteratedChimeProduct.Total_LoE__c + offSetValue;
                System.debug('changed here ::1 ' + iteratedChimeProduct.Total_LoE__c );
            }
        }

        
     }  

     public static void updateTotalLoEforCustomPOC(List<Chime_Product_Association__c> newList,Map<Id,Chime_Product_Association__c> oldMap){

        System.debug('check ain try ');

        Map<Id,PAC_Product_Catalog__c> pacProdMap = new Map<Id,PAC_Product_Catalog__c>();
        List<Chime_Product_Association__c> allChimeProductAssociation = new List<Chime_Product_Association__c>();
        List<Chime_Product_Association__c> chimeProductstoUpdate = new List<Chime_Product_Association__c>();
        Map<Id, Decimal> chimeProductIdtoLoeMap = new Map<Id, Decimal>();
        Map<Id, Boolean> chimeProductIdtoReviewMap = new Map<Id, Boolean>();
        List<Id> productAssociaionValueChanges = new List<Id>();
        List<Id> pacProductId = new List<Id>();
        List<CHIME__c> chimeforms = new List<CHIME__c>();
        Id chimeId = newList[0].CHIME__c ;
        String chimeImplementationType = '';
        Boolean StdImplementation = false;
        Boolean ManagedImplementation = false;

        

        for(Chime_Product_Association__c iteratedChimeProduct : newList){
            if(iteratedChimeProduct.Product_Implementation_Mode__c != oldMap.get(iteratedChimeProduct.Id).Product_Implementation_Mode__c){
                //targetChimeProducts.add(iteratedChimeProduct);
                pacProductId.add(iteratedChimeProduct.CHIME_Product__c);
                productAssociaionValueChanges.add(iteratedChimeProduct.Id);
            }
            System.debug(' it chime prod : '+  iteratedChimeProduct.Id + ' impl : ' + iteratedChimeProduct.Product_Implementation_Mode__c );
        }

        System.debug('impl typess : ' + StdImplementation + ' nxt mgd: ' + ManagedImplementation);
        System.debug(' check ain try out after if :');

        if ( !pacProductId.isEmpty() && pacProductId != null && pacProductId.size() > 0 ) {

            System.debug(' check ain try wher id ');
            allChimeProductAssociation = [select id,Product_Implementation_Mode__c , Review_Required__c, Features_LoE_Sum__c,CHIME__r.Implementation_Type__c ,CHIME_Product__c, CHIME_Product__r.Review_Required__c , CHIME_Product__r.TPM_for_calculation__c , CHIME_Product__r.Technical_Overhead__c , CHIME_Product__r.Tech_Overhead_Exempt__c, CHIME_Product__r.Product_Name__c , CHIME_Product__r.Marketing_Category__c from Chime_Product_Association__c where CHIME__c =:chimeId and CHIME__r.POC_Type__c = 'Custom-POC' ];

            for (Chime_Product_Association__c eachChimeProduct : allChimeProductAssociation) {
                System.debug(' ins for main : ' +  eachChimeProduct.CHIME_Product__r.Product_Name__c );
                System.debug(' all :: ' + productAssociaionValueChanges );

                System.debug(' name :123: ' + eachChimeProduct.CHIME_Product__r.Product_Name__c + ' id:: ' + eachChimeProduct.Id + ' contains :: ' + productAssociaionValueChanges.contains(eachChimeProduct.Id) );

                System.debug(' conttns s : ' +  ( !productAssociaionValueChanges.contains(eachChimeProduct.Id) ) );


                if( !productAssociaionValueChanges.contains(eachChimeProduct.Id) )
                {
                    //System.debug(' 1after if : ' + (eachChimeProduct.CHIME__r.Implementation_Type__c == 'Standard' && chimeImplementationType == '' ) + ' nextt : ' + chimeImplementationType == ''  );
                    System.debug('helloosons' + eachChimeProduct.Product_Implementation_Mode__c );
                    if (eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && chimeImplementationType == '' ) {
                        System.debug(' for prod : 1 :' + eachChimeProduct.Product_Implementation_Mode__c );
                        chimeImplementationType = 'Standard';
                    } else if( eachChimeProduct.Product_Implementation_Mode__c == 'Managed' && chimeImplementationType == '') {
                        System.debug(' for prod : 2 :' + eachChimeProduct.Product_Implementation_Mode__c );
                        chimeImplementationType = 'Managed';
                    } else if( eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && chimeImplementationType == 'Managed' )
                    {
                        System.debug(' for prod : 3 :' + eachChimeProduct.Product_Implementation_Mode__c );
                        chimeImplementationType = 'Standard & Managed';
                    } else if( eachChimeProduct.Product_Implementation_Mode__c == 'Managed' && chimeImplementationType == 'Standard' )
                    {
                        System.debug(' for prod : 4 :' + eachChimeProduct.Product_Implementation_Mode__c );
                        chimeImplementationType = 'Standard & Managed';
                    }
                }
            }

            if (chimeImplementationType != 'Standard & Managed') {
                for(Chime_Product_Association__c eachProdAssociation : newList)
                {
                    if(eachProdAssociation.Product_Implementation_Mode__c != chimeImplementationType )
                    {
                        chimeImplementationType = 'Standard & Managed';
                    }   
                }
            }



            System.debug(' check ain try wher id222 ');

            for (Chime_Product_Association__c eachChimeProduct : allChimeProductAssociation) {
                System.debug(' check ain try wher id222 in for ' + ' name:: ' + eachChimeProduct.CHIME_Product__r.Product_Name__c + ' valss : '  + eachChimeProduct.Product_Implementation_Mode__c + ' Marketing_Category__c : ' + eachChimeProduct.CHIME_Product__r.Marketing_Category__c + ' lementationType '  + chimeImplementationType );
                System.debug(' check ain try wher id222 in for last cont : ' + (eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && eachChimeProduct.CHIME_Product__r.Marketing_Category__c == 'Enterprise Security' && chimeImplementationType == 'Standard' && !productAssociaionValueChanges.contains(eachChimeProduct.Id) )   );
                if (eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && eachChimeProduct.CHIME_Product__r.Marketing_Category__c == 'Enterprise Security' && chimeImplementationType == 'Standard & Managed' && !productAssociaionValueChanges.contains(eachChimeProduct.Id) ) {
                    eachChimeProduct.Total_LoE__c = eachChimeProduct.Features_LoE_Sum__c ;
                    if( !eachChimeProduct.CHIME_Product__r.Tech_Overhead_Exempt__c)
                    {
                        eachChimeProduct.Total_LoE__c = eachChimeProduct.Total_LoE__c + eachChimeProduct.CHIME_Product__r.Technical_Overhead__c;
                    }
                    if(eachChimeProduct.CHIME_Product__r.Review_Required__c) {
                        eachChimeProduct.Review_Required__c = true;
                    }
                    chimeProductstoUpdate.add(eachChimeProduct);
                    System.debug(' prodt updating LOE : ' + eachChimeProduct.CHIME_Product__r.Product_Name__c + ' val :' + eachChimeProduct.Total_LoE__c );
                } 
                else if( productAssociaionValueChanges.contains(eachChimeProduct.Id) && eachChimeProduct.Product_Implementation_Mode__c == 'Managed' && eachChimeProduct.CHIME_Product__r.Marketing_Category__c == 'Enterprise Security' && chimeImplementationType == 'Standard' )
                {
                    eachChimeProduct.Total_LoE__c = 0;
                    eachChimeProduct.Review_Required__c = false;
                    chimeProductIdtoLoeMap.put(eachChimeProduct.Id, eachChimeProduct.Total_LoE__c);
                    chimeProductIdtoReviewMap.put(eachChimeProduct.Id, eachChimeProduct.Review_Required__c);

                    //chimeProductstoUpdate.add(eachChimeProduct);

                } else if (eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && eachChimeProduct.CHIME_Product__r.Marketing_Category__c == 'Enterprise Security' && chimeImplementationType == 'Standard' && !productAssociaionValueChanges.contains(eachChimeProduct.Id) ) 
                {
                    eachChimeProduct.Total_LoE__c = 0;
                    eachChimeProduct.Review_Required__c = false;
                    chimeProductstoUpdate.add(eachChimeProduct);
                } else if(eachChimeProduct.Product_Implementation_Mode__c == 'Standard' && eachChimeProduct.CHIME_Product__r.Marketing_Category__c == 'Enterprise Security' && chimeImplementationType == 'Standard & Managed' && productAssociaionValueChanges.contains(eachChimeProduct.Id) )
                {

                    System.debug('in lastst : '  + eachChimeProduct.CHIME_Product__r.TPM_for_calculation__c );
                    eachChimeProduct.Total_LoE__c = eachChimeProduct.Features_LoE_Sum__c + eachChimeProduct.CHIME_Product__r.TPM_for_calculation__c  ;
                    System.debug(' in lastst :1 ' +eachChimeProduct.Total_LoE__c );
                    if( !eachChimeProduct.CHIME_Product__r.Tech_Overhead_Exempt__c)
                    {
                        eachChimeProduct.Total_LoE__c = eachChimeProduct.Total_LoE__c + eachChimeProduct.CHIME_Product__r.Technical_Overhead__c;
                    }
                    if(eachChimeProduct.CHIME_Product__r.Review_Required__c) {
                        //eachChimeProduct.Review_Required__c = true;
                        chimeProductIdtoReviewMap.put(eachChimeProduct.Id, true);
                    } else {
                        chimeProductIdtoReviewMap.put(eachChimeProduct.Id, false);
                    }
                    chimeProductIdtoLoeMap.put(eachChimeProduct.Id, eachChimeProduct.Total_LoE__c);
                    System.debug(' in lastst :2 ' +eachChimeProduct.Total_LoE__c );

                }
            }

            if ( !chimeProductIdtoLoeMap.isEmpty() && chimeProductIdtoLoeMap != null && chimeProductIdtoLoeMap.size() > 0 ) {
                for(Chime_Product_Association__c cpa : newList )
                {
                    if( chimeProductIdtoLoeMap.keySet().contains(cpa.Id) )
                    {
                        cpa.Total_LoE__c = chimeProductIdtoLoeMap.get(cpa.Id);
                        cpa.Review_Required__c = chimeProductIdtoReviewMap.get(cpa.Id);
                    }
                }
                
            }

            if(chimeProductstoUpdate != null && !chimeProductstoUpdate.isEmpty() && chimeProductstoUpdate.size() > 0 )
            {
                update chimeProductstoUpdate;
            }
        }


     }
     
     // Update LoE review status on Chime Product Deletion
     public static void updateChimeLOEReviewStatus(List<Chime_Product_Association__c> oldList){
        List<Id> parentChimeIdList = new List<Id>();
        List<CHIME__c> chimeRecsList = new List<CHIME__c>();
        for(Chime_Product_Association__c iteratedCPA : oldList){
            parentChimeIdList.add(iteratedCPA.CHIME__c);
        }
        chimeRecsList = [Select Id,(Select Id,Review_Required__c from Chime_Product_Associations__r) from CHIME__c where Id IN: parentChimeIdList AND LOE_Review_Status__c != 'Awaiting Assignment' AND LOE_Review_Status__c != 'Review Completed' AND LOE_Review_Status__c != 'Being Reviewed'];
        for(CHIME__c iteratedChimeRec : chimeRecsList){
            for(Chime_Product_Association__c iteratedCPARec : iteratedChimeRec.Chime_Product_Associations__r){
                if(iteratedCPARec.Review_Required__c){
                    iteratedChimeRec.LOE_Review_Status__c = 'Review required';
                    break;
                }
                iteratedChimeRec.LOE_Review_Status__c = 'Review not required';
            }
        }

        update chimeRecsList;


    }
   
    // Update LoE review status on Chime Form's Emergency status change
    public static void updateChimeLOEReviewStatusOnEmergency(List<CHIME__c> newList,Map<Id,CHIME__c> oldMap){
        List<Id> parentChimeIdList = new List<Id>();
        List<CHIME__c> chimeRecsList = new List<CHIME__c>();
        for(CHIME__c iteratedChimeRec : newList){
            if((iteratedChimeRec.Is_Work_At_Risk_Investment_Work__c || iteratedChimeRec.Is_Emergency__c) && (oldMap.get(iteratedChimeRec.Id).Is_Emergency__c == false || oldMap.get(iteratedChimeRec.Id).Is_Work_At_Risk_Investment_Work__c == false) && iteratedChimeRec.LOE_Review_Status__c != 'Awaiting Assignment' && iteratedChimeRec.LOE_Review_Status__c != 'Review Completed' && iteratedChimeRec.LOE_Review_Status__c != 'Being Reviewed'){
                iteratedChimeRec.LOE_Review_Status__c = 'Review required';
            }
            else if((iteratedChimeRec.Is_Work_At_Risk_Investment_Work__c == false || iteratedChimeRec.Is_Emergency__c == false) && (oldMap.get(iteratedChimeRec.Id).Is_Work_At_Risk_Investment_Work__c || oldMap.get(iteratedChimeRec.Id).Is_Emergency__c) && iteratedChimeRec.LOE_Review_Status__c != 'Awaiting Assignment' && iteratedChimeRec.LOE_Review_Status__c != 'Review Completed' && iteratedChimeRec.LOE_Review_Status__c != 'Being Reviewed'){
               // parentChimeIdList.add(iteratedChimeRec.Id); 
               if(iteratedChimeRec.No_of_review_required_products__c == 0)
               iteratedChimeRec.LOE_Review_Status__c = 'Review not required';
            }
        }
       
    }

    public static void checkForEnterpriseSecurityProduct(List<Chime_Product_Association__c> newList){
        List<Id> listProductIds = new List<Id>();
        for(Chime_Product_Association__c cpa : newList){
            listProductIds.add(cpa.CHIME_Product__c);
        }
        
        List<PAC_Product_Catalog__c > listProducts = [Select id,Marketing_Category__c from PAC_Product_Catalog__c  where id in:listProductIds ];
        Map<Id,String> mapProductMarketingCategory = new Map<Id,String>();
        for(PAC_Product_Catalog__c item: listProducts){
            mapProductMarketingCategory.put(item.Id,item.Marketing_Category__c);
        }
        
        for(Chime_Product_Association__c cpa : newList){
            System.debug('Marketing_Category__c: '+mapProductMarketingCategory.get(cpa.CHIME_Product__c));
            if(mapProductMarketingCategory.get(cpa.CHIME_Product__c) == 'Enterprise Security'){
                cpa.Enterprise_Security_Product__c =true;
            }
        }
    }
    
    private static Map<String,String> getFieldsForAudit (){
        Map<String,String> pickListValuesList= new Map<String,String>();
		Schema.DescribeFieldResult fieldResult = CHIME_Audit_Trail__c.Field__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.put( pickListVal.getValue(),pickListVal.getLabel());
		}     
		return pickListValuesList;

    }
    

    public static void processAuditTrails(List<Chime_Product_Association__c> newChimeProducts , Map<Id,Chime_Product_Association__c> oldChimeProducts){
    
        List<CHIME_Audit_Trail__c> allTrails = new List<CHIME_Audit_Trail__c>();
        Map<String,String> mapAuditFields= getFieldsForAudit();
        Set<String> objectFields = Schema.SObjectType.Chime_Product_Association__c.fields.getMap().keySet();
        
        for(Chime_Product_Association__c chimeProduct : newChimeProducts) {
            for(String field : mapAuditFields.keySet()){
                if( objectFields.contains(field.toLowerCase())&& chimeProduct?.get(field)!=oldChimeProducts?.get(chimeProduct.Id)?.get(field)){
                    CHIME_Audit_Trail__c eachTrail = new CHIME_Audit_Trail__c();
                    eachTrail.PreviousValue__c = (oldChimeProducts?.get(chimeProduct.Id)?.get(field) == null)? '': oldChimeProducts?.get(chimeProduct.Id)?.get(field) +'';
                    eachTrail.CurrentValue__c = (chimeProduct.get(field)==null)? '': chimeProduct.get(field)+'';
                    eachTrail.Source__c ='CHIME Product';
                    eachTrail.CHIME__c = chimeProduct.CHIME__c;
                    eachTrail.CHIME_Product__c = chimeProduct.Id;
                    eachTrail.Field__c =mapAuditFields.get(field);
                    allTrails.add(eachTrail);
                }
            }
        }

        if(allTrails.size() > 0) {
            try {
                insert allTrails;
            }
            catch(Exception e) {
                Sawyer.saw(e);
            }
        }

    }
}
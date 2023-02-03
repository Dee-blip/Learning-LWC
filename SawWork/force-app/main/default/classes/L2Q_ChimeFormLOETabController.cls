public class L2Q_ChimeFormLOETabController {
    @AuraEnabled
    public static string getFeatureLOEData(Id productId){
       List<loeWrapperClass> loeWrapperList = new  List<loeWrapperClass> ();
      // loeWrapperClass loeWrapperInstance = new loeWrapperClass();
       
       

       //List<PAC_Product_Features__c> featuresList = [Select Id,Default_Feature__c,Feature_Name__c,Description__c,Name,Review_Required__c,Scope_of_Work__c,Unit_Type__c,First_Unit_LOE_In_Hours__c,	Additional_Unit_LoE_In_Hours__c from PAC_Product_Features__c where Active__c = true AND Product__c =: productId];
       List<Chime_Features_LoE__c> featuresList = [Select Id,	Feature__c,Feature__r.Product__r.Tech_Overhead_Exempt__c,Feature__r.Product__r.Technical_Overhead__c,Feature__r.Product__r.Percentage_TPM_hours_in__c,	Feature__r.Product__r.Minimum_TPM__c,	Feature__r.Feature_Name__c,Feature__r.Description__c,Feature__r.Review_Required__c,Feature__r.Scope_of_Work__c,Unit_Type__c,Parent_Feature_First_Unit_LoE__c,Parent_Feature_Additional_Unit_LoE__c,Units__c,LoE__c,Is_Selected__c,Chime_Product__r.LOE_Implementation_Mode__c,Chime_Product__c,Chime_Product__r.Review_Required__c,	Chime_Product__r.Total_LoE__c from Chime_Features_LoE__c where Feature_Active_at_creation__c = true and 	Chime_Product__c =:productId];
       if(featuresList.size() > 0){
           for(Chime_Features_LoE__c iteratedFeature : featuresList){
            loeWrapperClass loeWrapperInstance = new loeWrapperClass();
            loeWrapperInstance.feature = iteratedFeature;
            loeWrapperInstance.productLoEVal = 0;
            //loeWrapperInstance.isDefaultfeature = iteratedFeature.Default_Feature__c;
            //loeWrapperInstance.noOfUnits = 1;
            loeWrapperList.add(loeWrapperInstance); 
           }
       }else{
        loeWrapperClass loeWrapperInstance = new loeWrapperClass();
        loeWrapperInstance.productLoEVal = [Select Id,Total_LoE__c from Chime_Product_Association__c where Id=:productId].Total_LoE__c;
        loeWrapperList.add(loeWrapperInstance); 
       }
       return JSON.serialize(loeWrapperList);
    }

    @AuraEnabled(cacheable = true)
    public static string getReviewChecks(Id productId){
        reviewChecksWrapper reviewCheckInstance = new reviewChecksWrapper();
        Case c;
        Chime_Product_Association__c currentChimeProdAssociation = [Select Id,CHIME__r.LOE_Review_Status__c,	CHIME__r.Review_Case_Id__c,Human_Review__c from Chime_Product_Association__c where Id=: productId];
        reviewCheckInstance.chimeReviewStatus = currentChimeProdAssociation.CHIME__r.LOE_Review_Status__c;
        reviewCheckInstance.productHumanReview = currentChimeProdAssociation.Human_Review__c;
       // System.debug('Case**'+currentChimeProdAssociation.CHIME__r.Review_Case_Id__c);
       if(currentChimeProdAssociation.CHIME__r.Review_Case_Id__c != null && currentChimeProdAssociation.CHIME__r.Review_Case_Id__c != ''){
         c= [Select Id,OwnerId,Owner.Name from Case where Id=:currentChimeProdAssociation.CHIME__r.Review_Case_Id__c];
         if(c != null){
            reviewCheckInstance.reviewer = c.OwnerId;
            reviewCheckInstance.reviewerName = c.Owner.Name;
         }
       }else{
        reviewCheckInstance.reviewer = ''; 
       }
       return JSON.serialize(reviewCheckInstance);
    }    

    @AuraEnabled
    public static Chime_Product_Association__c getChimeStatus(Id productId){
        return [Select Id,CHIME__r.Status__c,CHIME__r.Stage__c from Chime_Product_Association__c where Id=:productId];
    }

    

    public class loeWrapperClass{
        @AuraEnabled
        public Chime_Features_LoE__c feature;
        @AuraEnabled
        public Double productLoEVal;
        
        
        
    }

    public class reviewChecksWrapper{
        @AuraEnabled
        public String chimeReviewStatus;
        @AuraEnabled
        public String reviewer;
        @AuraEnabled
        public String reviewerName;
        @AuraEnabled
        public Boolean productHumanReview;
    }

  

    @AuraEnabled
    public static void updateManualLoE(Id chimeProdAssociation,Double LoEVal){
        Chime_Product_Association__c chimeProd = new Chime_Product_Association__c(Id=chimeProdAssociation);
        chimeProd.Total_LoE__c = LoEVal;
        update chimeProd;
    }
    @auraEnabled
    public static void updateFeatureLOEData(String featureLOEData,String loeImplementationMode,Double totalLoE){
        List<L2Q_ChimeFormLOETabController.loeWrapperClass> updatedFeaturesWraperList = (List<L2Q_ChimeFormLOETabController.loeWrapperClass>)JSOn.deserialize(featureLOEData,L2Q_ChimeFormLOETabController.loeWrapperClass[].class);
        List<Chime_Features_LoE__c> chimeFeaturesLOEToUpdate = new List<Chime_Features_LoE__c> ();
        for(L2Q_ChimeFormLOETabController.loeWrapperClass loeWrapper : updatedFeaturesWraperList){
            if(loeWrapper.feature.Is_Selected__c && loeWrapper.feature.Feature__r.Review_Required__c){
                Chime_Product_Association__c chimeProduct = new Chime_Product_Association__c(Id=loeWrapper.feature.Chime_Product__c); 
                chimeProduct.Review_Required__c = true;
                update chimeProduct;
            }
            
           
        }
        for(L2Q_ChimeFormLOETabController.loeWrapperClass loeWrapper : updatedFeaturesWraperList){
            chimeFeaturesLOEToUpdate.add(loeWrapper.feature);
            System.debug('***'+loeWrapper.feature.Feature__r.Feature_Name__c+'---'+loeWrapper.feature.Units__c);
        }
        if(chimeFeaturesLOEToUpdate.size() > 0){
            update  chimeFeaturesLOEToUpdate;
            Chime_Product_Association__c chimeProduct = new Chime_Product_Association__c(Id=chimeFeaturesLOEToUpdate[0].Chime_Product__c);
            chimeProduct.LOE_Implementation_Mode__c = loeImplementationMode;
            chimeProduct.Total_LoE__c = totalLoE;
            update chimeProduct;
        }
    }

    //method to update implementation mode on Chime Product Association
    @AuraEnabled
  public static void updateProductImplementationType(Id prodId,String mode){
      List<Chime_Product_Association__c> chimeProductAssociationList= new List<Chime_Product_Association__c> ();
      chimeProductAssociationList = [Select Id,	CHIME__c,Product_Implementation_Mode__c from Chime_Product_Association__c where Id=: prodId];
      if(chimeProductAssociationList.size() > 0){
        chimeProductAssociationList[0].Product_Implementation_Mode__c = mode;
        update chimeProductAssociationList;
        updateImplementationModeOnChimeRec(chimeProductAssociationList[0].CHIME__c);
      }


  }

  @AuraEnabled
  public static void updateImplementationModeOnChimeRec(Id chimeRecId){
    CHIME__c chimeRec = [Select Id,Implementation_Type__c,Standard_Implemented_Product_Count__c,Managed_Implemented_Product_Count__c from CHIME__c where Id=:chimeRecId];
    if(chimeRec.Standard_Implemented_Product_Count__c > 0 && chimeRec.Managed_Implemented_Product_Count__c > 0){
        chimeRec.Implementation_Type__c = 'Standard & Managed';
    }else if(chimeRec.Standard_Implemented_Product_Count__c > 0 && chimeRec.Managed_Implemented_Product_Count__c == 0){
        chimeRec.Implementation_Type__c = 'Standard';
    }else if(chimeRec.Standard_Implemented_Product_Count__c == 0 && chimeRec.Managed_Implemented_Product_Count__c > 0){
        chimeRec.Implementation_Type__c = 'Managed';
    }
    update chimeRec;
  }

  @AuraEnabled
  public static String getProductImplementationType(Id prodId){
      return [Select Id,Product_Implementation_Mode__c from Chime_Product_Association__c where Id =: prodId].Product_Implementation_Mode__c;
  }

  @AuraEnabled
  public static void updateChimeFeatureLOEs(Id prodId){
    List<PAC_Product_Features__c> featuresList = new List<PAC_Product_Features__c>();
    List<Chime_Features_LoE__c> chimeFeaturesList = new List<Chime_Features_LoE__c>();
    Chime_Product_Association__c chimeProd = [Select Id,CHIME_Product__c from Chime_Product_Association__c where Id=: prodId];
    delete [Select Id from Chime_Features_LoE__c where Chime_Product__c =: prodId];
    featuresList = [Select Id,Active__c,Default_Feature__c,Feature_Name__c,Description__c,Name,Review_Required__c,Scope_of_Work__c,Unit_Type__c,First_Unit_LOE_In_Hours__c,Product__c,  Additional_Unit_LoE_In_Hours__c from PAC_Product_Features__c where Active__c = true AND Product__c =:chimeProd.CHIME_Product__c];
    for(PAC_Product_Features__c iteratedFeature : featuresList){
      
        Chime_Features_LoE__c chimeFeature = new Chime_Features_LoE__c();
        chimeFeature.Chime_Product__c = prodId;
        chimeFeature.Feature__c = iteratedFeature.Id;
        chimeFeature.Is_Selected__c = iteratedFeature.Default_Feature__c;
        chimeFeature.LoE__c = iteratedFeature.First_Unit_LOE_In_Hours__c;
        chimeFeature.Units__c = 1;
        chimeFeature.Unit_Type__c = iteratedFeature.Unit_Type__c;
        chimeFeature.Feature_Active_at_creation__c = iteratedFeature.Active__c;
        chimeFeaturesList.add(chimeFeature);
    }
    if(chimeFeaturesList.size() > 0){
        Insert chimeFeaturesList;
    } 
  } 

  @AuraEnabled
  public static void updateTotalLOEOnProd(Id prodId){
 
    Chime_Product_Association__c chimeProd = [Select Id,Product_Implementation_Mode__c,CHIME_Product__r.Default_LOE_Managed__c,CHIME_Product__r.Default_LOE_Standard__c from Chime_Product_Association__c where Id=:prodId];
    if(chimeProd.Product_Implementation_Mode__c == 'Standard'){
        chimeProd.Total_LoE__c = chimeProd.CHIME_Product__r.Default_LOE_Standard__c;
    }else if(chimeProd.Product_Implementation_Mode__c == 'Managed'){
        chimeProd.Total_LoE__c = chimeProd.CHIME_Product__r.Default_LOE_Managed__c;
    }  
    chimeProd.LOE_Implementation_Mode__c = 'Baseline';
    update chimeProd;
  } 
}
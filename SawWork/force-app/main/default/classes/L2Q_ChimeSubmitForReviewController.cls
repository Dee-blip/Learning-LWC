public with sharing class L2Q_ChimeSubmitForReviewController {
    @AuraEnabled
    public static String getProductData(Id chimeRecordId){
        submitWrapperClass sampleWrapper = new submitWrapperClass();
        sampleWrapper.severity = '';
        sampleWrapper.reveiwCaseId = '';
        CHIME__c chimeRec = [Select Id,Review_Case_Id__c,Status__c,Stage__c,LOE_Review_Status__c , All_Enterprise_Products__c , POC_Type__c	, Implementation_Type__c from CHIME__c where Id=: chimeRecordId];
        sampleWrapper.chimeRec = chimeRec;
        if(chimeRec.Review_Case_Id__c != null && chimeRec.Review_Case_Id__c !=''){
            sampleWrapper.reveiwCaseId = chimeRec.Review_Case_Id__c;
            Case c = [Select Id,Severity__c,ownerId,owner.Name,owner.Email from Case where Id=:  chimeRec.Review_Case_Id__c];
            sampleWrapper.severity = c.Severity__c;
            sampleWrapper.reviewerEmail = '';
            sampleWrapper.reviewerName = '';
            if(String.valueOf(c.ownerId).contains('005')){
                sampleWrapper.reviewerEmail = c.owner.Email;
                sampleWrapper.reviewerName = c.owner.Name;
            }
        }
        List<Chime_Product_Association__c> chimeProductList = new List<Chime_Product_Association__c>();

        if (chimeRec.POC_Type__c == 'Custom-POC' && chimeRec.Implementation_Type__c == 'Standard' && chimeRec.All_Enterprise_Products__c == 'Mix' ) {
            chimeProductList = [Select Id,Name,CHIME__r.Is_Emergency__c,CHIME__r.Is_Work_At_Risk_Investment_Work__c,CHIME_Product__c,CHIME_Product__r.Product_Name__c,Review_Required__c,	Review_Reason__c,Review_Priority__c,Human_Review__c from Chime_Product_Association__c where	CHIME__c =:chimeRecordId and CHIME_Product__r.Marketing_Category__c != 'Enterprise Security' ];
        } else {
            chimeProductList = [Select Id,Name,CHIME__r.Is_Emergency__c,CHIME__r.Is_Work_At_Risk_Investment_Work__c,CHIME_Product__c,CHIME_Product__r.Product_Name__c,Review_Required__c,	Review_Reason__c,Review_Priority__c,Human_Review__c from Chime_Product_Association__c where CHIME__c =:chimeRecordId];
        }
        
        if(chimeProductList != null && chimeProductList.size() > 0){
            sampleWrapper.isEmergency = chimeProductList[0].CHIME__r.Is_Emergency__c;
            sampleWrapper.isWorkAtRisk = chimeProductList[0].CHIME__r.Is_Work_At_Risk_Investment_Work__c;
        }
        sampleWrapper.productList = chimeProductList;
        return JSON.serialize(sampleWrapper);
        

    }

    @AuraEnabled
    public static void submitProcess(List<Id> productIds,String priority,String reason,Id chimeId){
        Chime_Product_Association__c chimeProdToUpdate = new Chime_Product_Association__c();
        List<Chime_Product_Association__c> chimeProdToUpdateList = new List<Chime_Product_Association__c>();
        for(Id iteratedProductId : productIds){
            chimeProdToUpdate = new Chime_Product_Association__c(Id=iteratedProductId);
            chimeProdToUpdate.Review_Priority__c = priority;
            chimeProdToUpdate.Review_Reason__c = reason;
            chimeProdToUpdateList.add(chimeProdToUpdate);
        }
        if(chimeProdToUpdateList.size() > 0){
            update chimeProdToUpdateList;
          //  sendReviewEmail(productIds,chimeId);
            
        }
    
    }

    /*public static void sendReviewEmail(List<Id> productIds,Id chimeId){
        Map<Id,List<User>> productIdVsReviewers = new Map<Id,List<User>>();
        Chime__c chimeRecDetails = [Select Id,Account__r.TERR_HIER_1__c,Account__r.TERR_HIER_3__c from Chime__c where Id=:chimeId];
        List<PermissionSetAssignment>  adminUsersPermissionSet= new List<PermissionSetAssignment>();
        List<Inv_WorkBox_Region_Mapping__c> GSSUserRegionList = new List<Inv_WorkBox_Region_Mapping__c>();
        List<Id> userIds = new List<Id>();
        GSSUserRegionList = [Select Id,User__c,User1__c from Inv_WorkBox_Region_Mapping__c where 	User__c != '' AND Geography1__c =: chimeRecDetails.Account__r.TERR_HIER_1__c AND 	Area1__c=:chimeRecDetails.Account__r.TERR_HIER_3__c AND 	Product__c =: productIds[0]];
        if(GSSUserRegionList.size() == 0){
            GSSUserRegionList = [Select Id,User__c,User1__c from Inv_WorkBox_Region_Mapping__c where 	User__c != '' AND Geography1__c =: chimeRecDetails.Account__r.TERR_HIER_1__c AND Product__c =: productIds[0]];
        }
        if(GSSUserRegionList.size() == 0){
            GSSUserRegionList = [Select Id,User__c,User1__c from Inv_WorkBox_Region_Mapping__c where 	User__c != '' AND Product__c =: productIds[0]];
        }
        if(GSSUserRegionList.size() == 0){
            GSSUserRegionList = [Select Id,User__c,User1__c from Inv_WorkBox_Region_Mapping__c where 	User__c != '' AND Geography1__c =: chimeRecDetails.Account__r.TERR_HIER_1__c AND 	Area1__c=:chimeRecDetails.Account__r.TERR_HIER_3__c];
        }
        if(GSSUserRegionList.size() == 0){
           // GSSUserRegionList = [Select Id,User,User.Name from Inv_WorkBox_Region_Mapping__c where 	User__c != '' AND Geography1__c =: chimeRecDetails.Account__r.TERR_HIER_1__c AND 	Area1__c=:chimeRecDetails.Account__r.TERR_HIER_3__c];
           adminUsersPermissionSet =[SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Chime_Admin_Permission_Set'];
        }


        if(adminUsersPermissionSet.size() > 0){
            for(PermissionSetAssignment iteratedPSA : adminUsersPermissionSet){
                userIds.add(iteratedPSA.AssigneeId); 
            }
        }else if(GSSUserRegionList.size() > 0){
            for(Inv_WorkBox_Region_Mapping__c iteratedGSSUser : GSSUserRegionList){
                userIds.add(iteratedGSSUser.User__c);
            }
        }

        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Id iteratedUserId : userIds){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      //  mail.setTargetObjectAsRecipient(true);
        mail.setTargetObjectId(iteratedUserId);
        mail.setPlainTextBody('Tested');
        mails.add(mail);

        }
         Messaging.sendEmail(mails);



    }*/
    
    public class submitWrapperClass{
        @AuraEnabled
        public Boolean isEmergency;
        @AuraEnabled
        public Boolean isWorkAtRisk;
        @AuraEnabled
        public List<Chime_Product_Association__c> productList;
        @AuraEnabled
        public String reveiwCaseId;
        @AuraEnabled
        public String severity;
        @AuraEnabled
        public String reviewerName;
        @AuraEnabled
        public String reviewerEmail;
        @AuraEnabled
        public CHIME__c chimeRec;

    }

    @AuraEnabled
    public static void sendSubsequentReviewEmail(Id reviewCase , String caseOwnerEmail , String caseOwnerName){
        List<String> emailAddresses = new List<String>();
        emailAddresses.add(caseOwnerEmail);
        String body = 'Hi '+caseOwnerName+',<br/>';
        body += 'Review Case has been updated :'+URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/case/'+reviewCase+'/view';
      //  String body = 'Hi '+ caseOwnerName+','+'\n Review Case case has been updated :'+URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/case/'+reviewCase+'/view';
        L2Q_LOE_Utility.sendEmail_allUseCases(null,null,emailAddresses,'Review Case has been updated',body);
        
    }
}
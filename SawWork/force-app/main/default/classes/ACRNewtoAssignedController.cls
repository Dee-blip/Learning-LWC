Public class ACRNewtoAssignedController{

Public Boolean ErrorFlag{get;set;}
Public string ErrorMessage{get;set;}

Public Account_Creation_Request__c AccReqRec;


   
    Public pagereference AssignedTo()
    {
        String ProfileIds = GsmUtilClass.getGSMSettingValue('ACRProfileId'); 
         Id ACRId = ApexPages.currentPage().getParameters().get('id');
       
       AccReqRec=[select id,Name,Website__c,City__c,Zip_Postal_Code__c,Street__c,State__c,Country__c,status__c,account__c,CreatedbyId,ownerid from Account_Creation_Request__c where id=:ACRId];
       
        if(!ProfileIds.contains(UserInfo.getprofileid())){
       
           ErrorFlag =true;
           ErrorMessage =GsmUtilClass.getGSMSettingValue('ACRAssignedError');
           system.debug('ErrorMessage:::'+ErrorMessage);
           return null;
       }else if(AccReqRec.status__c =='Closed - Complete' || AccReqRec.status__c =='Closed - Denied'){
           ErrorFlag =true;
           ErrorMessage =GsmUtilClass.getGSMSettingValue('ACRStatusMoved');
           system.debug('ErrorMessage:::'+ErrorMessage);
           return null;
       }
       
       
       ErrorFlag=false;
       AccReqRec.status__c ='Assigned';
       AccReqRec.Ownerid=userinfo.getuserid();
       try{
       update AccReqRec;
       }catch(DMLException dl){

        ErrorFlag =true; ErrorMessage = dl.getmessage(); return null;
           //system.debug('ErrorMessage:::'+ErrorMessage);
           

       }
       PageReference returnURL = new Pagereference ('/'+ ACRId);
     
       return returnURL;
        
    }
    public PageReference Cancel(){
      Id recordId = ApexPages.currentPage().getParameters().get('Id');
        return new PageReference('/'+(Id)recordId);
    }


}
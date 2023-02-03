public class PostRefreshActivityConroller {

    public String suffix{get; set;}
    public Integer batchSize{get; set;}
    public String maskingParam{get; set;}
    
    public void executeBatch(){
    
        if(batchSize != null && batchSize != 0){
            if(suffix != null && suffix != '' && suffix.startsWith('_')){
                BATCH_MaskContactAndLead batch = new BATCH_MaskContactAndLead(suffix);
                Database.executeBatch(batch,batchSize);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.confirm,'Batch submitted Successfully'));  
               }
              else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Suffix cannot be Empty and should start with _'));  
               } 
        }else {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Batch Size cant be Empty'));
        }
    }
    
    /*  
        Action method to fetch all custom settings, to get their soqls and fields and to chunkify those records in batches
        All these chunks are passed to an async job to do masking of emails, if present in fields
        CR 3259981 : rsharma
    */
    public void maskCSAction(){
        Set<Schema.DisplayType> types = new Set<Schema.DisplayType>{Schema.DisplayType.Email, Schema.DisplayType.anytype, Schema.DisplayType.TextArea,Schema.DisplayType.String};
        Map<String,String> objToSoqlMap = GsmUtilClass.getAllCSFieldsAndQueryByType(GsmUtilClass.getAllCustomSettingResult(),types);
         Map<String,List<String>> objToFieldsQueriedMap = GsmUtilClass.objToFieldsQueriedMap;
        Integer collectionSize = objToSoqlMap.keySet().size();
        Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('MaskCSEmails','BatchSize'));//50;
        Integer maskingParamMaxLength = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('PostRefresh#MaskCSEmail','maskParamSize'));
        Integer count = 1;
        Map<String,String> objToSoqlMapChunked = new Map<String,String>();
        Map<String,List<String>> objToFieldsQueriedMapChunked = new Map<String,List<String>>();
        List<Id> jobIds = new List<Id>();
        if(String.isBlank(maskingParam)){

            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Masking Suffix cannot be Empty.'));  
        }
        else if(maskingParam.length()>maskingParamMaxLength){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error,'Masking Suffix should be less than or equal to '+maskingParamMaxLength+' characters.'));  
        }
        else{
            Integer nextInc = Math.min(collectionSize-count,batchSize);
              
                for(String sObjName:objToSoqlMap.keySet()){
              
                    if(count<nextInc){  
                        objToSoqlMapChunked.put(sObjName,objToSoqlMap.get(sObjName));
                        objToFieldsQueriedMapChunked.put(sObjName,objToFieldsQueriedMap.get(sObjName));
                        }
                    else{
                        objToSoqlMapChunked.put(sObjName,objToSoqlMap.get(sObjName));
                        objToFieldsQueriedMapChunked.put(sObjName,objToFieldsQueriedMap.get(sObjName));

                        ID jobID = System.enqueueJob(new AsyncMaskCustomSettingeMail(objToSoqlMapChunked,objToFieldsQueriedMapChunked,maskingParam));
                        jobIds.add(jobID);
                        //keeping debug statements to debug in production, if anything goes wrong
                        system.debug('in else with size: '+objToSoqlMapChunked.size()+' collectionSize: '+collectionSize+' nextInc: '+nextInc+' count: '+count);
                        objToSoqlMapChunked = new Map<String,String>();
                        objToFieldsQueriedMapChunked = new Map<String,List<String>>();
                        collectionSize = collectionSize-count+1;
                        nextInc = Math.min(collectionSize,batchSize);
                        count=0;
                    }

                    count++;
                }
                
            //enque the last chunk formed above
            ID jobID = System.enqueueJob(new AsyncMaskCustomSettingeMail(objToSoqlMapChunked,objToFieldsQueriedMapChunked,maskingParam));
            jobIds.add(jobID);
            system.debug('in else with size: '+objToSoqlMapChunked.size()+' collectionSize: '+collectionSize+' nextInc: '+nextInc+' count: '+count);
        }
        
    }
    
    public void maskEmail() {
    // login();
    }
    
    
}
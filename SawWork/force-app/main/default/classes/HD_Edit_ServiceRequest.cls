global class HD_Edit_ServiceRequest {

   global class SR_Details{
    @AuraEnabled    
    public BMCServiceDesk__SRM_RequestDetail__c request_detail = new BMCServiceDesk__SRM_RequestDetail__c ();
    @AuraEnabled    
    public List<BMCServiceDesk__SRM_FulfillmentInputs__c>  FF_Inputs = new List<BMCServiceDesk__SRM_FulfillmentInputs__c> ();
    @AuraEnabled    
    public List<BMCServiceDesk__SRM_RequestDetailInputs__c> RD_Inputs = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
    @AuraEnabled    
    public MAP<Id,String>FFIValue  = new MAP<Id,String>() ;
       
    @AuraEnabled    
    public MAP<String,MAP<Id,String>> LookupValues  = new MAP<String,MAP<Id,String>>();
       
   
    
    }
  
    
    @AuraEnabled
    public static  SR_Details getSRDetails(String Id){
        
        SR_Details srdetails =  new SR_Details();
        BMCServiceDesk__Incident__c sr = [ Select Id,Name,BMCServiceDesk__FKRequestDefinition__c 
                                          from BMCServiceDesk__Incident__c where id = :Id];
       
        srdetails.RD_Inputs = [Select Id, BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Condition__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Conditional__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ConditionsPostfix__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ControlProcess__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayinFullSpan__c, BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__From_import__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Hidden__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Prompt__c,BMCServiceDesk__FKFulfillmentInputs__r.Input_Conditional_Holder__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__InputValues__c,BMCServiceDesk__FKFulfillmentInputs__r.Input_Values_holder__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__FKLookupFilter__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Order__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Record_ID__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__FKRequestDefinition__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Required__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ResponseType__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.Run_workflow__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Scrollable__c,BMCServiceDesk__FKFulfillmentInputs__r.HD_Secure_Field__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__URLInfo__c,BMCServiceDesk__FKFulfillmentInputs__r.Used_for_validation__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Validate__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ValidationRule__c,
                                BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__VisibleLines__c,BMCServiceDesk__FKFulfillmentInputs__c,HD_Ffi_Response_Type__c,HD_Ffi_Secure_Flag__c,BMCServiceDesk__History__c,
                                HD_Incident_id__c,BMCServiceDesk__Input__c,BMCServiceDesk__NewResponse__c,BMCServiceDesk__FKRequestDetail__c,BMCServiceDesk__Response__c,BMCServiceDesk__Richtext_Response__c,HD_Secure_Response__c,
                                BMCServiceDesk__StoredValue__c from BMCServiceDesk__SRM_RequestDetailInputs__c 
                                WHERE BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__c  = :Id AND BMCServiceDesk__History__c != true];
        
        System.debug('AAAA 111 '+sr.Id);
        srdetails.FF_Inputs = [SELECT Id, BMCServiceDesk__AdditionalInfo__c,BMCServiceDesk__Condition__c,
                               BMCServiceDesk__Conditional__c,BMCServiceDesk__ConditionsPostfix__c,BMCServiceDesk__ControlProcess__c,
                               BMCServiceDesk__DisplayinFullSpan__c,BMCServiceDesk__DisplayInSecondColumn__c,BMCServiceDesk__From_import__c,
                               BMCServiceDesk__Hidden__c,BMCServiceDesk__Prompt__c,Input_Conditional_Holder__c,BMCServiceDesk__InputValues__c,
                               Input_Values_holder__c,BMCServiceDesk__FKLookupFilter__c,BMCServiceDesk__Order__c,BMCServiceDesk__Record_ID__c,
                               BMCServiceDesk__FKRequestDefinition__c,BMCServiceDesk__Required__c,BMCServiceDesk__ResponseType__c,
                               Run_workflow__c,BMCServiceDesk__Scrollable__c,HD_Secure_Field__c,BMCServiceDesk__Tooltip__c,
                               BMCServiceDesk__URLInfo__c,Used_for_validation__c,BMCServiceDesk__Validate__c,BMCServiceDesk__ValidationRule__c,
                               BMCServiceDesk__VisibleLines__c FROM BMCServiceDesk__SRM_FulfillmentInputs__c
                               where BMCServiceDesk__FKRequestDefinition__c = :sr.BMCServiceDesk__FKRequestDefinition__c  
                               ORDER BY  BMCServiceDesk__Order__c ];
        
        for(BMCServiceDesk__SRM_RequestDetailInputs__c rdi : srdetails.RD_Inputs){
            srdetails.FFIValue.put(rdi.BMCServiceDesk__FKFulfillmentInputs__c,rdi.BMCServiceDesk__Response__c);
        }
        
        
        System.debug('AAAA '+srdetails);
        return srdetails;
    }
    
    
    
    @AuraEnabled
    public static void SaveSRDetails(String incident_id, MAP<String,String> values){
        SR_Details srdetails =  new SR_Details();
        Id inci_id = incident_id;
        
        BMCServiceDesk__Incident__c sr = [ Select Id,Name,BMCServiceDesk__FKRequestDefinition__c from BMCServiceDesk__Incident__c where id = :inci_id];
        
        MAP<ID,BMCServiceDesk__SRM_RequestDetailInputs__c> RD_Inputs = new MAP<ID,BMCServiceDesk__SRM_RequestDetailInputs__c>([Select Id, BMCServiceDesk__FKFulfillmentInputs__r.id, BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Condition__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Conditional__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ConditionsPostfix__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ControlProcess__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayinFullSpan__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Hidden__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Prompt__c,BMCServiceDesk__FKFulfillmentInputs__r.Input_Conditional_Holder__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__InputValues__c, BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__From_import__c, BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.Input_Values_holder__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__FKLookupFilter__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ValidationRule__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Order__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Record_ID__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__FKRequestDefinition__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Required__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__ResponseType__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.Run_workflow__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Scrollable__c,BMCServiceDesk__FKFulfillmentInputs__r.HD_Secure_Field__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__URLInfo__c,BMCServiceDesk__FKFulfillmentInputs__r.Used_for_validation__c,BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Validate__c,
                               BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__VisibleLines__c,BMCServiceDesk__FKFulfillmentInputs__c,HD_Ffi_Response_Type__c,HD_Ffi_Secure_Flag__c,BMCServiceDesk__History__c,HD_Incident_id__c,
                               BMCServiceDesk__Input__c,BMCServiceDesk__NewResponse__c,BMCServiceDesk__FKRequestDetail__c,BMCServiceDesk__Response__c,BMCServiceDesk__Richtext_Response__c,HD_Secure_Response__c,BMCServiceDesk__StoredValue__c 
                               from BMCServiceDesk__SRM_RequestDetailInputs__c 
                               WHERE BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__c = :sr.Id] );
        
      MAP<Id,BMCServiceDesk__SRM_FulfillmentInputs__c>  FF_Inputs = new MAP<Id,BMCServiceDesk__SRM_FulfillmentInputs__c>([SELECT Id, BMCServiceDesk__AdditionalInfo__c,BMCServiceDesk__Condition__c,BMCServiceDesk__Conditional__c,BMCServiceDesk__ConditionsPostfix__c,BMCServiceDesk__ControlProcess__c,BMCServiceDesk__DisplayinFullSpan__c,BMCServiceDesk__DisplayInSecondColumn__c,
                     BMCServiceDesk__From_import__c,BMCServiceDesk__Hidden__c,BMCServiceDesk__Prompt__c,Input_Conditional_Holder__c,
                     BMCServiceDesk__InputValues__c,Input_Values_holder__c,BMCServiceDesk__FKLookupFilter__c,BMCServiceDesk__Order__c,
                     BMCServiceDesk__Record_ID__c,BMCServiceDesk__FKRequestDefinition__c,BMCServiceDesk__Required__c,BMCServiceDesk__ResponseType__c,
                     Run_workflow__c,BMCServiceDesk__Scrollable__c,HD_Secure_Field__c,BMCServiceDesk__Tooltip__c,BMCServiceDesk__URLInfo__c,
                     Used_for_validation__c,BMCServiceDesk__Validate__c,BMCServiceDesk__ValidationRule__c,BMCServiceDesk__VisibleLines__c
                     FROM BMCServiceDesk__SRM_FulfillmentInputs__c
 where BMCServiceDesk__FKRequestDefinition__c = :sr.BMCServiceDesk__FKRequestDefinition__c  ORDER BY  BMCServiceDesk__Order__c ]);
        
        
        List<BMCServiceDesk__SRM_FulfillmentMappings__c> ffi_mapings = [SELECT Id,Name,BMCServiceDesk__FKFulfillmentInputs__c,BMCServiceDesk__ProcessVariable__c FROM BMCServiceDesk__SRM_FulfillmentMappings__c where BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__FKRequestDefinition__c = :sr.BMCServiceDesk__FKRequestDefinition__c ];
        MAP<ID,String> ffid_ffimap = new  MAP<ID,String>();
        for(BMCServiceDesk__SRM_FulfillmentMappings__c ffi_map :ffi_mapings ){
            ffid_ffimap.put(ffi_map.BMCServiceDesk__FKFulfillmentInputs__c,ffi_map.BMCServiceDesk__ProcessVariable__c);
        }
        //String[] keyval = values.split(',');
        System.debug(' IN VALS '+values);
        System.debug(' INCID VALS --- '+inci_id);
        System.debug(' RD IN '+RD_Inputs);
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> delete_rdi = new  List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        MAP<String,String> in_val = new  MAP<String,String>();
        MAP<String,BMCServiceDesk__SRM_RequestDetailInputs__c> ffi_rdi = new  MAP<String,BMCServiceDesk__SRM_RequestDetailInputs__c>();
        String[] kval;
        Boolean tobedeleted = false;
        MAP<String,String> mapping_fields = new MAP<String,String>() ;
        
        for(BMCServiceDesk__SRM_RequestDetailInputs__c rdi :  RD_Inputs.values() ){
            ffi_rdi.put(rdi.BMCServiceDesk__FKFulfillmentInputs__r.id,rdi);
            
            tobedeleted = true;
            for(String fid : values.keySet()){
                if(rdi.BMCServiceDesk__FKFulfillmentInputs__r.id == fid){
                    tobedeleted = false;
                    break;
                }
                
            }
            if(tobedeleted == true){
                delete_rdi.add(rdi);
            }
            
            
        }
        
        BMCServiceDesk__SRM_RequestDetailInputs__c in_rd ;//= new BMCServiceDesk__SRM_RequestDetailInputs__c();
        BMCServiceDesk__SRM_RequestDetailInputs__c new_rd ; //= new BMCServiceDesk__SRM_RequestDetailInputs__c();
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> upsert_rds = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        boolean create_new_record ;
        for(String fid : values.keySet()){
            System.debug(' IN KEYVAL '+fid+'  Values '+values.get(fid));
            in_rd = new BMCServiceDesk__SRM_RequestDetailInputs__c();
            new_rd = new BMCServiceDesk__SRM_RequestDetailInputs__c();
            create_new_record = false;
            if(ffi_rdi.containsKey(fid)){
                in_rd = ffi_rdi.get(fid);
                if(in_rd.BMCServiceDesk__Response__c != values.get(fid)){
                     in_rd.BMCServiceDesk__History__c = true;
                     in_rd.BMCServiceDesk__NewResponse__c = values.get(fid);
                     upsert_rds.add(in_rd);
                     create_new_record = true;
                }
            }else{
                create_new_record = true;
             }
            
           if(create_new_record){
                new_rd.BMCServiceDesk__FKFulfillmentInputs__c = fid;
                new_rd.BMCServiceDesk__FKRequestDetail__c = RD_Inputs.values()[0].BMCServiceDesk__FKRequestDetail__c;
                new_rd.BMCServiceDesk__Response__c = values.get(fid) ;
                new_rd.BMCServiceDesk__Input__c = FF_Inputs.get(fid).BMCServiceDesk__Prompt__c;
               System.debug(' FFIIII '+FF_Inputs.get(fid));
                String stval = getStoredvalue(FF_Inputs.get(fid),values.get(fid));
                new_rd.BMCServiceDesk__StoredValue__c = stval;
                upsert_rds.add(new_rd);
               if(ffid_ffimap.containsKey(fid)){
                   String[] str = ffid_ffimap.get(fid).split(':');
                   if( str[1] == 'incidentDescription__c' || str[1] == 'shortDescription__c'){
                       str[1] = 'BMCServiceDesk__'+str[1];
                   }
                   mapping_fields.put(String.escapeSingleQuotes(str[1]),stval);  //cs -fix PRTORES-1581 shegade
               } 
               
               
            }          
        }
        
        
        
        
        for ( BMCServiceDesk__SRM_RequestDetailInputs__c rdi : upsert_rds){
            System.debug(' RDI  -- '+rdi.BMCServiceDesk__FKFulfillmentInputs__c+' '+rdi.BMCServiceDesk__Input__c+' '+rdi.BMCServiceDesk__Response__c+' '+rdi.BMCServiceDesk__StoredValue__c+' '+rdi.Id);
        }
      
        try{
            upsert upsert_rds;
            delete delete_rdi;
            
            if(mapping_fields.keySet().size() > 0)
            {
                List<String> fields = new List<String>();
                fields.addall(mapping_fields.keyset());
                String querystr = 'SELECT ID, '+String.join(fields,',')+' FROM BMCServiceDesk__Incident__c WHERE ID = :inci_id';
                sObject sobj = Database.query(querystr);
                for( String ky : mapping_fields.keySet() ){
                    sobj.put(ky,mapping_fields.get(ky));
                }
                
                update sobj;
                
            }
            }catch (Exception e) { 
            
               throw new AuraHandledException(e.getMessage());
            }
    
        
        
    }
    
    public static string getStoredvalue(BMCServiceDesk__SRM_FulfillmentInputs__c ffi , String val){
        String stored_val = val;
        Integer ct = 0;
       
        if (ffi.BMCServiceDesk__ResponseType__c == 'Picklist' || ffi.BMCServiceDesk__ResponseType__c =='Radio Button'){
            
            String[] options = ffi.BMCServiceDesk__InputValues__c.split('П');
            String[] opt_var ;
            stored_val = '';
            MAP<String,String> opt_val = new MAP<String,String>();
            
                for(String optval : options){
                   opt_var = optval.split('ф');
                   opt_val.put(opt_var[0],opt_var[1]);  
               }
            
            string[] in_vals = val.split(';');
            for(String inp : in_vals){
                if(ct  > 0){
                            stored_val += ';';
                        }
                stored_val += opt_val.get(inp);
                 ct += 1;
            }
              
        }
        
        if (ffi.BMCServiceDesk__ResponseType__c == 'Date/Time'){
             String[] val1  = val.split('T');
             String datestr = val1[0]+ ' '+val1[1].remove('Z');
            
            DateTime dt1 =  Datetime.ValueOf(datestr);
           stored_val = dt1.format('MM/dd/yyyy hh:mm a');
        
        }
        
        if (ffi.BMCServiceDesk__ResponseType__c == 'Date'){
           Date dt =  Date.ValueOf(val);
           stored_val =  dt.format();
            
        }
        
        system.debug(' IN Options '+val+' -- '+ffi.id+' -- '+ffi.BMCServiceDesk__ResponseType__c+' stored val '+stored_val);
        return stored_val;
    }//getStoredValue
}
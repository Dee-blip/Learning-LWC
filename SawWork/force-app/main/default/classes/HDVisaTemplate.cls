/*
* File Name: HDVisaTemplate
* Description : 
* @author : 
* Modification Log ===============================================================
* Date              Author              Modification
* 5 Aug 2020        Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1811 - Code Scanner part 5 fixes
*/
public class HDVisaTemplate {

    public String controllerValue {get;set;}
    public String test {get;set;}
    public Id incid {get;set;}
    public Boolean testClassRun {get;set;}
    public String employeeOrganization {get;set;}
   

    public Map<String, String> templateDetails{
        get{
            return getEamilFields(this.incid);
        }
        set;
    }
    
    public Boolean validTemplate{
        get{
            try{
                
                BMCServiceDesk__SRM_RequestDetail__c reqDetail = new  BMCServiceDesk__SRM_RequestDetail__c();
                reqDetail = getRequestDetail(this.incId);
                if(reqDetail != null && reqDetail.BMCServiceDesk__FKRequestDefinition__r.name == 'Travel Visa'){
                    System.debug('test');
                    return true;
                }
                return false;
                //return true;
                
            }catch(Exception e){
                return false;
            }
            
                
        }
        set;
    }
    
    
    
    
    public HDVisaTemplate(){
        templateDetails = new Map<String,String>();
        validTemplate = false;
        testClassRun = false;
        
    }
    
    private BMCServiceDesk__SRM_RequestDetail__c getRequestDetail(Id incID){
        return [select id, BMCServiceDesk__FKRequestDefinition__r.name from BMCServiceDesk__SRM_RequestDetail__c 
                where id in (select BMCServiceDesk__FKRequestDetail__c  from 
                             BMCServiceDesk__Incident__c where id =:incID)  limit 1];
    }  
    
    private BMCServiceDesk__Incident__c getClientDetails(Id incId){
        return [select id, BMCServiceDesk__FKClient__r.name, BMCServiceDesk__FKClient__r.EmployeeNumber, BMCServiceDesk__FKClient__r.title  from BmcserviceDesk__incident__C where id = :incId ];    
    }
    
    private String formatDate(Date d) {
        return d.day() + '-' + d.month() + '-' + d.year();
    }
    
    private String formatDateYYYYMMDD(String indate){
        
        //checks for the format 23/32/1232 
        Pattern MyPattern = Pattern.compile('[0-9][0-9]/[0-9][0-9]/[0-9][0-9][0-9][0-9]');
        Matcher MyMatcher = MyPattern.matcher(indate);
        Boolean acceptedFormat = MyMatcher.matches(); 
        
        if(acceptedFormat==true){
            return indate;
        }

        //else the fromat will be in yyyy-mm-dd
        String[] tokens = indate.split('-');
        return tokens[1] + '/' +tokens[2] + '/' + tokens[0];
        
    }
    
        
    
    private List<BMCServiceDesk__SRM_RequestDetailInputs__c>  getRequestInputs(Id reqId){
       
        return [select Id,Name,BMCServiceDesk__Input__c,BMCServiceDesk__Response__c, HD_Ffi_Response_Type__c  from 
                BMCServiceDesk__SRM_RequestDetailInputs__c where 
                BMCServiceDesk__FKRequestDetail__c =:reqId and 
                BMCServiceDesk__FKFulfillmentInputs__c !=null 
                order by BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Order__c asc  limit 100 ];
    }
    
    public Map<String,String> getEamilFields(Id incId){
        Set<String> templateFieldLists = new Set<String>();
        
        //thes are the list of variables we are interested in showing information on the visualforce page
        
        templateFieldLists.add('test');
        templateFieldLists.add('Akamai Logo');
        templateFieldLists.add('Akamai Footer');
        templateFieldLists.add('Akamai Signature');
        templateFieldLists.add('Start Date');
        templateFieldLists.add('End Date');   
        templateFieldLists.add('Region');
        templateFieldLists.add('Date of Hire');
        templateFieldLists.add('Travel Type');
        templateFieldLists.add('Countries');
        templateFieldLists.add('Country Travelling To');
        templateFieldLists.add('Client Name');
        templateFieldLists.add('Employee Date of Hire (MM-DD-YYYY)');
        templateFieldLists.add('Employee Date of Hire (MM/DD/YYYY)');
        templateFieldLists.add('Country List');
        templateFieldLists.add('Client Title');
        templateFieldLists.add('organization');
        Map<String,String> templateDetails = new Map<String,String>();
        
        //initializing all values to null to avoid null pointer exception on VF page
        
        for(String init : templateFieldLists){
            templateDetails.put(init,'');  
        }
        
        //check for valid service request
        BMCServiceDesk__SRM_RequestDetail__c reqDetail = new BMCServiceDesk__SRM_RequestDetail__c();
        // request detail can be null as well
        try{
            reqDetail = getRequestDetail(incId);
        }catch(Exception e){
            System.debug(e);
        }

        

        if(validTemplate || testClassRun){
            List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqInputs = getRequestInputs(reqDetail.Id);
            
            for(BMCServiceDesk__SRM_RequestDetailInputs__c reqInput : reqInputs){
                if(templateFieldLists.contains(reqInput.BMCServiceDesk__Input__c)){
                    if(reqInput.HD_Ffi_Response_Type__c == 'Date' ){
                        templateDetails.put(reqInput.BMCServiceDesk__Input__c, formatDateYYYYMMDD(reqInput.BMCServiceDesk__Response__c));                        
                    }else if( reqInput.BMCServiceDesk__Input__c.contains('Date of Hire') && reqInput.BMCServiceDesk__Response__c!= NULL){
                        templateDetails.put('Date of Hire', reqInput.BMCServiceDesk__Response__c.replace('-','/')); 
                    }else {
                        templateDetails.put(reqInput.BMCServiceDesk__Input__c, reqInput.BMCServiceDesk__Response__c);   
                    }
                    
                }
            }
            
            //if countries(conditional input -- use 'coutries' over 'Country travelling to' ) is populated
            if(tempLateDetails.get('Countries')!= ''){
                templateDetails.put('Country List', tempLateDetails.get('Countries'));
            }else{
                templateDetails.put('Country List', tempLateDetails.get('Country Travelling To'));
            }
           
            
            //get custom setting values for image url 
            if(HD_Image_Url__c.getValues('Akamai Logo')!=null)
            templateDetails.put('Akamai Logo', HD_Image_Url__c.getValues('Akamai Logo').Image_Url__c );
            if(HD_Image_Url__c.getValues('Akamai Footer')!=null)
            templateDetails.put('Akamai Footer', HD_Image_Url__c.getValues('Akamai Footer').Image_Url__c );
            if(HD_Image_Url__c.getValues('Akamai Signature')!=null)
            templateDetails.put('Akamai Signature', HD_Image_Url__c.getValues('Akamai Signature').Image_Url__c );
            

            //getting client name and employee id
            BMCServiceDesk__Incident__c currentIncident = getClientDetails(incId);
            templateDetails.put('Client Title',currentIncident.BMCServiceDesk__FKClient__r.title);
            templateDetails.put('Client Name',currentIncident.BMCServiceDesk__FKClient__r.name);
            templateDetails.put('Client Employee Number',currentIncident.BMCServiceDesk__FKClient__r.EmployeeNumber);
            
            //update the organization
            templateDetails.put('organization',employeeOrganization);
            
            return templateDetails;            
            
        }else {
            return new Map<String,String>();
        }
    } 
}
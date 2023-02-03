/***
    TrialsRequestFormCtrl
    @version     :1.0
    @author      :Kunal Sharma
    @Description :This Controller is implemented for making web service calls to EDNS, Site Analyser and Net Storage.                           
    
*/    
public class TrialsRequestFormCtrl {
    
    public Attachment attachmentAkamai {get { if(attachmentAkamai==null){ attachmentAkamai = new Attachment();}return attachmentAkamai;}set;}
    public Attachment attachmentOrigin {get { if(attachmentOrigin==null){ attachmentOrigin = new Attachment();}return attachmentOrigin;}set;}
    public List<Attachment> lAttachment = new List<Attachment>();
    public list<ResposeWrapper> lResponseWrapper{get{if(lResponseWrapper == null){lResponseWrapper = new list<ResposeWrapper>();}return lResponseWrapper;} set;}
    public static list<string> lURLs;
    public static list<string> lProcessEmbededURLs;
    
    public Trials_Request_Form__c trialsReqForm{get{if(trialsReqForm == null)trialsReqForm = new Trials_Request_Form__c(); return trialsReqForm;}set;}
    public integer picklistSelectedValue{set;get;}
    public string var1{get; set;}
    public string var2{get; set;}
    public string paramPassed;
    public Trials_Request_Form__c trialsReqFormAfterInsert;
    
    public Trials_Request_Form__c trialsReqFormAfterEdns;
    
    public boolean akamaiResponseReceived{get;set;}
    public boolean originResponseReceived{get;set;}
    public boolean readOnly{get;set;}
    public boolean updateChildRecs;
    public boolean createdTRF{get;set;}
    public integer timeLeft{get{if(timeLeft == null)timeLeft = 0; return timeLeft;}set;}
    public boolean instantCheckReqSent{get;set;}
    public boolean provisionTestReqSent{get;set;}
    public boolean rendercacheableURL{get;set;}
    
    /*Start of Jaya's code*/
    String cnameTarget = '';
    String cnameNameHttpField = '';
    String cnameNameHttpsField = '';
    String targetHttpDSAWAAValue = '';
    String targetHttpsDSAWAAValue = '';
    String targetHttpDSDValue = '';
    String targetHttpsDSDValue = '';
    String targetHttpIonValue = '';
    String targetHttpsIonValue = '';
    String akamaiEDNS = '';
    String originEDNS = '';
    String originEDNSTrimmed = '';
    String fileNameFromForm = '';
    String ednsDomainName = '';
        
    /*End of Jaya's code*/
    
    //Default constructor for toggling the value of createdTRF variable.   
    public TrialsRequestFormCtrl(){
        paramPassed = Apexpages.currentPage().getParameters().get('id');
        createdTRF = false;
        if(paramPassed != null){
            createdTRF = true;
        }
        
        /*Start of Jaya's code*/
        Trials__c cnameHttp = Trials__c.getValues('cnameNameHttpField');
        cnameNameHttpField = cnameHttp.Value__c;
        
        Trials__c cnameHttps = Trials__c.getValues('cnameNameHttpsField');
        cnameNameHttpsField = cnameHttps.Value__c;
        
        Trials__c targetHttpDSAWAA = Trials__c.getValues('TargetHttpDSAWAA');
        targetHttpDSAWAAValue = targetHttpDSAWAA.Value__c;
        
        Trials__c targetHttpsDSAWAA = Trials__c.getValues('TargetHttpsDSAWAA');
        targetHttpsDSAWAAValue = targetHttpsDSAWAA.Value__c;
        
        Trials__c targetHttpDSD = Trials__c.getValues('TargetHttpDSD');
        targetHttpDSDValue = targetHttpDSD.Value__c;
        
        Trials__c targetHttpsDSD = Trials__c.getValues('TargetHttpsDSD');
        targetHttpsDSDValue = targetHttpsDSD.Value__c;
        
        Trials__c targetHttpIon = Trials__c.getValues('TargetHttpIon');
        targetHttpIonValue = targetHttpIon.Value__c;
                       
        Trials__c targetHttpsIon = Trials__c.getValues('TargetHttpsIon');
        targetHttpsIonValue = targetHttpsIon.Value__c;
        
        Trials__c ednsDomain = Trials__c.getValues('EDNSDomain');
        ednsDomainName = ednsDomain.Value__c;
        /*End of Jaya's code*/
    }
    
    // constructor to fetch the values from the page and display the instant check result on the page.
    public TrialsRequestFormCtrl(ApexPages.StandardController controller){
        this();
        instantCheckReqSent = false;
        provisionTestReqSent = false;
        trialsReqForm = (Trials_Request_Form__c) controller.getRecord();
        DateTime expDate = DateTime.Now();
        //trialsReqForm.Trials_Instant_Check_Back_Date__c = DateTime.now().addMinutes(-timeOutValue);
        if(trialsReqForm.Trials_Test_Duration_In_Days__c != null)
        trialsReqForm.TrialsEndDate__c = expDate.addDays(Integer.valueOf(trialsReqForm.Trials_Test_Duration_In_Days__c) + 1);
        
        if(trialsReqForm.Id != null){
            createdTRF = true;
           
            if(! trialsReqForm.Trials_DNS_Created__c)
           timeLeft = 30;
        }    
        
        if(! String.isBlank(trialsReqForm.Trials_URLs__c)){
            lURLs = trialsReqForm.Trials_URLs__c.split('\n');
        }
        
        
        if(trialsReqForm.Id != null && trialsReqForm.Trials_JSON_Received_For_Akamai_XML__c && trialsReqForm.Trials_JSON_Received_For_Origin_XML__c){
            
            List<Trials_Request_Form__c> lTRF = [SELECT Id,Trials_Objects_Akamai__c, Trails_Objects_Origin__c,Trials_Instant_Check_Back_Date__c,
                                             Trials_Response_Codes_Akamai__c, Trails_Response_Codes_Origin__c, Trials_Response_Time_Akamai__c,
                                             Trials_Response_Time_Origin__c FROM Trials_Request_Form__c WHERE Id = :trialsReqForm.Id];
        
            for(Trials_Request_Form__c objTRF :lTRF){
                integer i=0;
                lResponseWrapper.add(new ResposeWrapper('# Objects', objTRF.Trials_Objects_Akamai__c, objTRF.Trails_Objects_Origin__c));
                lResponseWrapper.add(new ResposeWrapper('Response Time', objTRF.Trials_Response_Time_Akamai__c, objTRF.Trials_Response_Time_Origin__c));
                i++;
            }  
            
            Map<string,string> mResponseCodeOrigin = new Map<string, string>();
            Map<string,string> mResponseCodeAkamai = new Map<string, string>();
            
            if(lTRF[0].Trails_Response_Codes_Origin__c != null){
                integer i = 0;
                string tempKey;
                for(string varString: lTRF[0].Trails_Response_Codes_Origin__c.split(':')){
               
                    if(Math.Mod(i,2) == 0){
                        mResponseCodeOrigin.put(varString, '0');
                        tempKey = varString;
                    }
                    else{
                        string temp = mResponseCodeOrigin.get(tempKey);
                        temp = varString;
                        mResponseCodeOrigin.put(tempKey,temp);
                    }
                    
                    i++;
                }
            }
            
            if(lTRF[0].Trials_Response_Codes_Akamai__c != null){
                integer i = 1;
                string tempKey;
            
                for(string varString: lTRF[0].Trials_Response_Codes_Akamai__c.split(':')){
                    if(Math.Mod(i,2) == 1){
                        mResponseCodeAkamai.put(varString, '0');
                        tempKey = varString;
                    }
                    else
                        mResponseCodeAkamai.put(tempKey, varString);
                    ++i;
                }
            }
            
            for (string varString: mResponseCodeOrigin.keySet()){
                
                lResponseWrapper.add(new ResposeWrapper('Response Code '+ varString, mResponseCodeAkamai.containsKey(varString)?mResponseCodeAkamai.get(varString):'0',
                                     mResponseCodeOrigin.get(varString)));
                mResponseCodeAkamai.remove(varString);                     
            }
            
            if(mResponseCodeAkamai != null){
                for(string varString: mResponseCodeAkamai.keySet()){
                    lResponseWrapper.add(new ResposeWrapper('Response Code '+ varString, mResponseCodeAkamai.containsKey(varString)?mResponseCodeAkamai.get(varString):'0',
                                     mResponseCodeOrigin.containsKey(varString)?mResponseCodeOrigin.get(varString):'0'));
                }
            } 
        }    
    }
    
    
    /*
        Method for creating XML's and calling the web services.
    */
    public PageReference mainMethod(){
        List<String> urlList = new List<String>();
        List<String> cacheableUrlList = new List<String>();
        Boolean insertForm = false;
        DateTime expDate = DateTime.Now();
        //trialsReqForm.Trials_Instant_Check_Back_Date__c = DateTime.now().addMinutes(-timeOutValue);
        if(trialsReqForm.Trials_Test_Duration_In_Days__c != null)
        trialsReqForm.TrialsEndDate__c = expDate.addDays(Integer.valueOf(trialsReqForm.Trials_Test_Duration_In_Days__c) + 1);
        
        if(!TrialsUtilClass.allTrialsValidation(trialsReqForm)){
            return null;
        }
        //String idnew=trialsReqForm.Id;
        if(trialsReqForm.Id == NULL){
            //trialsReqForm.Trials_Instant_Check_Back_Date__c = DateTime.now().addMinutes(-58);
            if(trialsReqForm.Trials_Cacheable_URLs__c == null || trialsReqForm.Trials_Cacheable_URLs__c == '')
            {
                updateChildRecs = false;               
                insert trialsReqForm; 
                trialsReqFormAfterInsert = [SELECT Name,Trials_Protocol__c,Trials_Origin_EDNS__c,Trials_Akamai_EDNS__c, Trials_Product__c , Id FROM Trials_Request_Form__c WHERE id = :trialsReqForm.Id];
                    
                    if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && (trialsReqFormAfterInsert.Trials_Product__c == 'DSA' || trialsReqFormAfterInsert.Trials_Product__c == 'WAA'))
                    {     
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;      
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && trialsReqFormAfterInsert.Trials_Product__c == 'DSD') 
                    {                                                                             
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;                                
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && (trialsReqFormAfterInsert.Trials_Product__c == 'DSA' || trialsReqFormAfterInsert.Trials_Product__c == 'WAA'))
                    {        
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                                                 
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && trialsReqFormAfterInsert.Trials_Product__c == 'DSD') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                    
                    }
                    /*Below 2 conditions will change according to reqs for Ion*/
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && trialsReqFormAfterInsert.Trials_Product__c == 'ION') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                    
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && trialsReqFormAfterInsert.Trials_Product__c == 'ION') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;                    
                    }
                    update trialsReqFormAfterInsert;               
            }
            else if(trialsReqForm.Trials_Cacheable_URLs__c != '' && trialsReqForm.Trials_Cacheable_URLs__c != null)
            {
                urlList = trialsReqForm.Trials_URLs__c.split('\n');
                cacheableUrlList = trialsReqForm.Trials_Cacheable_URLs__c.split('\n');
                for(String url:urlList)
                {
                    for(String cacheableUrl:cacheableUrlList)
                    {
                        if(url.contains(cacheableUrl))
                        {
                            insertForm = true;
                        }
                    }
                }
                if(insertForm == true)
                {
                    insert trialsReqForm;
                    updateChildRecs = false;
                    trialsReqFormAfterInsert = [SELECT Name,Trials_Protocol__c,Trials_Origin_EDNS__c,Trials_Akamai_EDNS__c, Trials_Product__c , Id FROM Trials_Request_Form__c WHERE id = :trialsReqForm.Id];
                    
                    if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && (trialsReqFormAfterInsert.Trials_Product__c == 'DSA' || trialsReqFormAfterInsert.Trials_Product__c == 'WAA'))
                    {     
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;      
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && trialsReqFormAfterInsert.Trials_Product__c == 'DSD') 
                    {                                                                             
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;                                
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && (trialsReqFormAfterInsert.Trials_Product__c == 'DSA' || trialsReqFormAfterInsert.Trials_Product__c == 'WAA'))
                    {        
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                                                 
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && trialsReqFormAfterInsert.Trials_Product__c == 'DSD') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                    
                    }
                    /*Below 2 conditions will change according to reqs for Ion*/
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'ESSL' && trialsReqFormAfterInsert.Trials_Product__c == 'ION') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField+'.'+ednsDomainName;                    
                    }
                    else if(trialsReqFormAfterInsert.Trials_Protocol__c == 'Freeflow' && trialsReqFormAfterInsert.Trials_Product__c == 'ION') 
                    {                                                                              
                        trialsReqFormAfterInsert.Trials_Origin_EDNS__c = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpsField;                                                                     
                        trialsReqFormAfterInsert.Trials_Akamai_EDNS__c = 'test'+trialsReqFormAfterInsert.Name.substring(6)+'.'+cnameNameHttpField+'.'+ednsDomainName;                    
                    }
                    
                    update trialsReqFormAfterInsert;
                }
                else
                {
                    updateChildRecs = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cacheable Url\'s must be present in URL\'s'));
                    return null;
                }
            }
            
        }
        
        else{
            if(trialsReqForm.Trials_Cacheable_URLs__c == null || trialsReqForm.Trials_Cacheable_URLs__c == '')
            {
                update trialsReqForm;
                updateChildRecs = true;
            }
            else if(trialsReqForm.Trials_Cacheable_URLs__c != '' && trialsReqForm.Trials_Cacheable_URLs__c != null)
            {
                urlList = trialsReqForm.Trials_URLs__c.split('\n');
                cacheableUrlList = trialsReqForm.Trials_Cacheable_URLs__c.split('\n');
                for(String url:urlList)
                {
                    for(String cacheableUrl:cacheableUrlList)
                    {
                        if(url.contains(cacheableUrl))
                        {
                            insertForm = true;
                        }
                    }
                }
                
                if(insertForm == true)
                {
                    update trialsReqForm;
                    updateChildRecs = true;
                }
                else
                {
                    updateChildRecs = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cacheable Url\'s must be present in URL\'s'));
                    return null;
                }
            }
        }
        createChildRecords(updateChildRecs);
        createdTRF = true;
        PageReference pg = new PageReference('/apex/TrialsRequestForm?id='+trialsReqForm.Id);
        pg.setRedirect(true);
        return pg;
        
    }
    
    public void dummyFunction(){
         createdTRF = false;
    }
    
    public void cancels(){
        createdTRF = true;
        
    }
    
    /*
    Deletes the provisioned Trials request from SA.
    */
    public void deleteTestFromSA(){
        HttpResponse deleteTestResponse = new HttpResponse();
        trialsReqForm.Trials_Test_Deleted__c = true;
        ResponseForAddingTest responseDeletion;
        
        if(trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c != NULL){
        
            deleteTestResponse=TrialsUtilClass.deleteTestFromSA(trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c);
            JSONParser parser = JSON.createParser(deleteTestResponse.getBody());
            responseDeletion = (ResponseForAddingTest)parser.readValueAs(ResponseForAddingTest.class);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Akamai Test: ' + responseDeletion.Message));
        }
        if(trialsReqForm.Trials_Origin_Provisioned_Test_Id__c != NULL){
            deleteTestResponse=TrialsUtilClass.deleteTestFromSA(trialsReqForm.Trials_Origin_Provisioned_Test_Id__c);
            JSONParser parser = JSON.createParser(deleteTestResponse.getBody());
            responseDeletion = (ResponseForAddingTest)parser.readValueAs(ResponseForAddingTest.class);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Origin Test: ' + responseDeletion.Message));
        }
        
        update trialsReqForm;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Origin report: ' + deleteTestResponse.getBody() + ' ' + deleteTestResponse));
    }
    
    /*
    Method for creating child records from Trials Request Form.
    */
    public void createChildRecords(boolean updateChildRecs){
        List<Trials_XML__c> lChildRecs= new List<Trials_XML__c>();
        
        if(! String.isBlank(trialsReqForm.Trials_URLs__c)){
            lURLs = trialsReqForm.Trials_URLs__c.split('\n');
        }
        /*
        if(! String.isBlank(trialsReqForm.Trials_Third_Party_Exclusions__c)){
            lProcessEmbededURLs = trialsReqForm.Trials_Third_Party_Exclusions__c.split('\n');
        }*/
        
        if(!updateChildRecs){
            for(integer i=0; i<2; i++){
                Trials_XML__c objTriXML = new Trials_XML__c();
                objTriXML.Trials_URLs__c = trialsReqForm.Trials_URLs__c;
                objTriXML.Trials_Frequency_for_Running_Test__c = trialsReqForm.Trials_Frequency_for_Running_Test__c;
                objTriXML.Trials_Hostnames_Digital_Properties__c = trialsReqForm.Trials_Hostnames_Digital_Properties__c;
                objTriXML.Trials_Location_of_Test_Agents__c = trialsReqForm.Trials_Location_of_Test_Agents__c;
                objTriXML.Trials_Test_Duration_In_Days__c = trialsReqForm.Trials_Test_Duration_In_Days__c;
                objTriXML.Trials_Third_Party_Exclusions__c = trialsReqForm.Trials_Third_Party_Exclusions__c;
                objTriXML.Trials_Generated_XML__c = TrialsUtilClass.createXMLFile(lURLs, trialsReqForm.Trials_Third_Party_Exclusions__c,
                                                                                  trialsReqForm.Trials_Frequency_for_Running_Test__c,i==1?true:false,
                                                                                  trialsReqForm.Trials_Hostnames_Digital_Properties__c, trialsReqFormAfterInsert.Trials_Akamai_EDNS__c);
                objTriXML.Trials_Akamai_XML__c = i==1?true:false;
                objTriXML.Trials_Request_Form__c = trialsReqForm.Id;
                lChildRecs.add(objTriXML);                                                                
            }
            insert lChildRecs;
        }
        
        else{
            List<Trials_XML__c> lTriXML = [SELECT Id,Trials_URLs__c,Trials_Frequency_for_Running_Test__c,Trials_Hostnames_Digital_Properties__c, Trials_Request_Form__r.Trials_Akamai_EDNS__c,
                                             Trials_Location_of_Test_Agents__c,Trials_Test_Duration_In_Days__c,Trials_Third_Party_Exclusions__c,
                                             Trials_Generated_XML__c,Trials_Akamai_XML__c FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqForm.Id];
            
            for(Trials_XML__c objTriXML :lTriXML){
                objTriXML.Trials_URLs__c = trialsReqForm.Trials_URLs__c;
                objTriXML.Trials_Frequency_for_Running_Test__c = trialsReqForm.Trials_Frequency_for_Running_Test__c;
                objTriXML.Trials_Hostnames_Digital_Properties__c = trialsReqForm.Trials_Hostnames_Digital_Properties__c;
                objTriXML.Trials_Location_of_Test_Agents__c = trialsReqForm.Trials_Location_of_Test_Agents__c;
                objTriXML.Trials_Test_Duration_In_Days__c = trialsReqForm.Trials_Test_Duration_In_Days__c;
                objTriXML.Trials_Third_Party_Exclusions__c = trialsReqForm.Trials_Third_Party_Exclusions__c;
                objTriXML.Trials_Generated_XML__c = TrialsUtilClass.createXMLFile(lURLs, trialsReqForm.Trials_Third_Party_Exclusions__c,
                                                                                  trialsReqForm.Trials_Frequency_for_Running_Test__c,objTriXML.Trials_Akamai_XML__c,
                                                                                  trialsReqForm.Trials_Hostnames_Digital_Properties__c, objTriXML.Trials_Request_Form__r.Trials_Akamai_EDNS__c);
                //objTriXML.Trials_Akamai_XML__c = i==1?true:false;
                //objTriXML.Trials_Request_Form__c = trialsReqForm.Id;
                lChildRecs.add(objTriXML);
            } 
            update lChildRecs;                             
        }
    }
    /*
    public void doInstantCheck(){
        HttpResponse responseReceived = new HttpResponse();
        instantCheckReqSent = true;
        provisionTestReqSent = false;
        for(Trials_XML__c objTriXML: [SELECT Id,Trials_Generated_XML__c,Trials_Akamai_XML__c,Trials_Request_Form__r.TrialsTestNamePrefix__c,
                                      Trials_Frequency_for_Running_Test__c,Trials_Location_of_Test_Agents__c,
                                      Trials_Request_Form__r.Name FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqForm.Id]){
                                          
           responseReceived=TrialsUtilClass.sendRequestToSA(objTriXML.Id,objTriXML.Trials_Generated_XML__c,objTriXML.Trials_Request_Form__r.Name,
                                                            provisionTestReqSent,instantCheckReqSent,objTriXML.Trials_Akamai_XML__c,
                                                            objTriXML.Trials_Frequency_for_Running_Test__c, objTriXML.Trials_Location_of_Test_Agents__c,
                                                            objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c);
           if(objTriXML.Trials_Akamai_XML__c){
               trialsReqForm.Trails_Akamai_Instant_Check_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
               trialsReqForm.Trials_Akamai_Instant_Check_Status_Messa__c = String.valueOf(responseReceived.getStatus());
           } 
           else{
               trialsReqForm.Trials_Origin_Instant_Check_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
               trialsReqForm.Trials_Origin_Instant_Check_Status_Messa__c = String.valueOf(responseReceived.getStatus());
           }
        }
        update trialsReqForm;
    }*/
    /*
    public void provisionTest(){
        HttpResponse responseReceived = new HttpResponse();
        HttpResponse emailConfigureResponse = new HttpResponse();
        instantCheckReqSent = false;
        provisionTestReqSent = true;
        ResponseForAddingTest responseProvisioning;
        list<Trials_Request_Form__c> lTRFToUpdate = new list<Trials_Request_Form__c>();
        
        for(Trials_XML__c objTriXML: [SELECT Id,Trials_Generated_XML__c,Trials_Akamai_XML__c,
                                      Trials_Request_Form__r.Name,Trials_Frequency_for_Running_Test__c,Trials_Location_of_Test_Agents__c
                                      FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqForm.Id]){
           responseReceived=TrialsUtilClass.sendRequestToSA(objTriXML.Id,objTriXML.Trials_Generated_XML__c,
                                                            objTriXML.Trials_Request_Form__r.Name,provisionTestReqSent,
                                                            instantCheckReqSent,objTriXML.Trials_Akamai_XML__c,
                                                            objTriXML.Trials_Frequency_for_Running_Test__c,objTriXML.Trials_Location_of_Test_Agents__c);
           JSONParser parser = JSON.createParser(responseReceived.getBody());
            //if (parser.getCurrentToken()== JSONToken.START_OBJECT)
           responseProvisioning = (ResponseForAddingTest)parser.readValueAs(ResponseForAddingTest.class);
           system.debug('$$$$$' + responseProvisioning);
           system.debug('!!!!' + parser);
           
            if(objTriXML.Trials_Akamai_XML__c){
               trialsReqForm.Akamai_Provisioning_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
               trialsReqForm.Akamai_Provisioning_Status_Message__c = String.valueOf(responseReceived.getStatus());
               trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c = responseProvisioning.data;
               
               if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                   if(responseProvisioning.success!= NULL && responseProvisioning.success){
                       //HttpResponse emailConfigureResponse = new HttpResponse();
                       trialsReqForm.Trials_Provisioned_Trails__c = true;
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Akamai test is Provisioned Successfully and Test Id is ' + responseProvisioning.data));
                       system.debug('## Id ' + trialsReqForm.Id);
                       emailConfigureResponse = TrialsUtilClass.sendEmailRequestSA(trialsReqForm.Id,responseProvisioning.data,true,trialsReqForm.Trials_Additional_Email_Addresses__c);
                       JSONParser parserEmail = JSON.createParser(emailConfigureResponse.getBody());
                       ResponseForAddingTest emailResponse = (ResponseForAddingTest)parserEmail.readValueAs(ResponseForAddingTest.class);
                       if(emailConfigureResponse.getStatusCode()==200 && emailConfigureResponse.getStatus()=='OK'){
                           if(emailResponse.success != NULL && emailResponse.success){
                               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Akamai report: ' + emailResponse.message));
                           }
                           else{
                               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Akamai Email: ' + responseProvisioning.message));
                           }
                       }
                       else{
                           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Akamai Email: ' + emailConfigureResponse.getStatus() +' ' +emailResponse.error));
                       }
                   }
                   
                   else{
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Akamai Test: ' + responseProvisioning.message));
                   }
                   
               }
                
                else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Akamai Test: ' + 'Error in Web Service Call'));
                }
                lTRFToUpdate.add(trialsReqForm);
               } 
               else{
                   
                   trialsReqForm.Origin_Provisioning_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
                   trialsReqForm.Origin_Provisioning_Status_Message__c = String.valueOf(responseReceived.getStatus());
                   trialsReqForm.Trials_Origin_Provisioned_Test_Id__c = responseProvisioning.data;
                   if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                       if(responseProvisioning!= null && responseProvisioning.success != null && responseProvisioning.success){
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Origin test is Provisioned Successfully and Test Id is ' + responseProvisioning.data));
                       trialsReqForm.Trials_Provisioned_Trails__c = true;
                       emailConfigureResponse = TrialsUtilClass.sendEmailRequestSA(trialsReqForm.Id,responseProvisioning.data,false,trialsReqForm.Trials_Additional_Email_Addresses__c);
                       JSONParser parserEmail = JSON.createParser(emailConfigureResponse.getBody());
                       ResponseForAddingTest emailResponse = (ResponseForAddingTest)parserEmail.readValueAs(ResponseForAddingTest.class);
                       if(emailConfigureResponse.getStatusCode()==200 && emailConfigureResponse.getStatus()=='OK'){
                           if(emailResponse.success!=NULL && emailResponse.success){
                               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Origin report: ' + emailResponse.message));
                           }
                           else{
                               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Origin Email: ' + emailResponse.message));
                           }
                       }
                       
                       else{
                           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Origin Test: # ' + emailResponse.message));
                       }
                   }
                   
                   else{
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Origin Test: $ ' + responseProvisioning.message));
                   }
                      
               }
               else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Origin Test: % ' + responseReceived.getStatus()));
                }    
               lTRFToUpdate.add(trialsReqForm);
            }
        }
       
        update trialsReqForm;
    }
    */
    public class ResponseForAddingTest{
        public string message{get;set;}
        public boolean success{get;set;}
        public string data{get;set;}
        public string error{get;set;}
    }
    
    public class ResposeWrapper{
        public string rowName{get;set;}
        public string akamaiValue{get;set;}
        public string originValue{get;set;}
        
        public ResposeWrapper(){
        }
        
        public ResposeWrapper(string rowName, string akamaiValue, string originValue){
            this.rowName = rowName;
            if(rowName == 'Response Time'){
                this.akamaiValue = akamaiValue + ' sec';
                this.originValue = originValue + ' sec';
            }      
            else{
                this.akamaiValue = akamaiValue;
                this.originValue = originValue;
            }         
        }
    }
    
    public void createOriginXMLForSA(Set<String> sURLs){
     
    }
    
    
    /*Jaya's code for Netstorage*/
    
    /*Below are the variables that need to be set from the page. trialsReqForm*/

    /* The below two functions are used for generating the HMACSHA256 signature. 
    The first function forms the sign string and passes that data to the next function to generate HMACSHA256 signature.*/

    public String generateSignature(String XAAuthData, String action) 
    {
        Trials__c trialsSecretKey = Trials__c.getValues('SecretKey');
        String secretKey = trialsSecretKey.Value__c;
        
        Trials__c trialsFileUploadPath = Trials__c.getValues('FileUploadPath');
        String fileUploadUrl = trialsFileUploadPath.Value__c;
        
        /*Trials__c trialsFileName = Trials__c.getValues('FileName');
        String fileName = trialsFileName.Value__c;*/
        
        String signString = fileUploadUrl+fileNameFromForm+'.bin'+'\nx-akamai-acs-action:'+action+'\n';
        //System.assertEquals(fileNameFromForm,'filename');
        String data = XAAuthData+signString;
        String signature = generateHmacSHA256Signature(secretKey,data);
        return signature;
    }

/*This function returns the HMACSHA256 code in the base 64 encoded format*/
    private static String generateHmacSHA256Signature(String keyValue, String dataValue) 
    {
        String algorithmName = 'HmacSHA256';
        Blob hmacData = Crypto.generateMac(algorithmName, Blob.valueOf(dataValue), Blob.valueOf(keyValue));
        return EncodingUtil.base64Encode(hmacData);
    }
    
    public void instantCheck(){
        instantCheckReqSent = true;
    }

    public void sendNotification() 
    {   
        trialsReqFormAfterInsert = [SELECT Name,Trials_Cacheable_URLs__c,Trials_Protocol__c,Trials_Akamai_EDNS__c,Trials_Origin_EDNS__c, Trials_Product__c , Id FROM Trials_Request_Form__c WHERE id = :trialsReqForm.Id];
                        
        akamaiEDNS = trialsReqFormAfterInsert.Trials_Akamai_EDNS__c;
        originEDNS = trialsReqFormAfterInsert.Trials_Origin_EDNS__c;
        originEDNSTrimmed = 'origin-test'+trialsReqFormAfterInsert.Name.substring(6);
        fileNameFromForm = 'test'+trialsReqFormAfterInsert.Name.substring(6);
                               
        /*End of paste*/
         //=  trialsReqForm.Trials_Hostnames_Digital_Properties__c;// We have to generate. Trials_Hostnames_Digital_Properties__c
        Boolean pconnVarValue =  trialsReqForm.Trials_PCONN__c;// Trials_PCONN__c
        String pconnVarValueString = '';
        /*on off instead of true false*/
        if(pconnVarValue == true)
            pconnVarValueString = 'on';
        else if(pconnVarValue == false)
            pconnVarValueString = 'off';
        String ttlFileExtn =  trialsReqForm.Trails_File_Extension__c.replace(';',' ');// Trails_File_Extension__c
        String ttl =  trialsReqForm.Trials_TTL__c;// Trials_TTL__c
        
        /* Setting the ttl value according to what is required in the netstorage file format. */
        if(ttl == '7 Days')
            ttl = '7d';
        else if(ttl == '0 Sec')
            ttl = '0s';
        else if(ttl == '6 Hours')
            ttl = '6h';
        else if(ttl == '5 Mins')
            ttl = '5m';
        else if(ttl == '1 Day')
            ttl = '1d';
            
         //= trialsReqForm.Trials_Hostnames_Digital_Properties__c; // We have to generate. Trials_Hostnames_Digital_Properties__c
        String hostName = trialsReqForm.Trials_Hostnames_Digital_Properties__c; //Trials_Hostnames_Digital_Properties__c
        Boolean tdValue = trialsReqForm.Trials_TD__c; // Trials_TD__c
        String tdValueString = '';
        if(tdValue == true)
            tdValueString = 'on';
        else
            tdValueString = 'off';
        
        Boolean srValue;
        String srValueString = '';
        if(trialsReqForm.Trials_SRTO__c != null && trialsReqForm.Trials_SRTO__c != '')
        {
            srValue = true; // if Trials_SRTO__c is null then this is off
            srValueString = 'on';
        }
        else
        {
            srValue = false;
            srValueString = 'off';
        }
        
        String srObjectValue = trialsReqForm.Trials_SRTO__c == null ? '' : trialsReqForm.Trials_SRTO__c; // Trials_SRTO__c
 
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        /* Unique id here is the GUID that we use for XAkamaiAuthData header.*/
        String uniqueId = GuidUtil.NewGuid();
        String body = '';
        String cacheUrlList = '';
        /*Start of code for generating the file body*/
       // String boundary = '__boundary__xxx';
       // String header = '--'+boundary+'\n';
       //System.assertEquals(akamaiEDNS,'abc');
        if(trialsReqForm.Trials_Product__c == 'ION')  
        { 
            if(trialsReqFormAfterInsert.Trials_Cacheable_URLs__c != null && trialsReqFormAfterInsert.Trials_Cacheable_URLs__c != '')
            {
                string varString;
                                for(string varCachURLs :trialsReqFormAfterInsert.Trials_Cacheable_URLs__c.split('\n')){
                                        if(varString=='' || varString==null){
                                        varString = varCachURLs.trim();
                                    }
    
                                else{
                                        varString = varString.trim() + ' ' + varCachURLs.trim();
                                }
                                }   

                cacheUrlList = varString;
                //cacheUrlList = cacheUrlList.replaceAll(',',' ');
            }
            
            else{
                cacheUrlList = '""';
            }
                body = 'content_policy {\n\ttaxonomy {\n\tname: "default"\n\ncategory {\n\tname: "query"\ncondition {\n\ttype: REQUEST_HOST\nparam {\tvalue: "'
                            + akamaiEDNS + '"}\n}\n}\n\ncategory {\n\tname: "query1"\ncondition {\n\ttype: REQUEST_HOST\nparam {\n\tvalue: "'
                            + akamaiEDNS +'"\n}\n}\n}\n}\n\npolicy {'
                            + '\n\tname: "PCONN-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "PCONN_VAR"\nvalue: "'
                            + pconnVarValueString + '"}\n\n}\n}\n\npolicy {\n\tname: "TTL-RULE"'
                            + '\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "EXTN_LIST"\nvalue: "'
                            + ttlFileExtn + '"\n}\n\nresult {\n\tname: "TTL_EXTN"\nvalue: "'
                            + ttl + '"\n}\n}\n}\n\npolicy {\n\tname: "TORIGIN"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "ORIGIN_VAR"'
                            + '\nvalue: "'+ originEDNSTrimmed + '"\n}result {\n\tname: "HOST_VAR"\nvalue: "'
                            + hostName + '"\n}\n}\n}\n\npolicy {\n\tname: "TD-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "TD_VAR"\nvalue: "'
                            + tdValueString +'"\n}\n}\n}\n\npolicy {\n\tname: "SR-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "SR_VAR"\nvalue: "'
                            + srValueString +'"\n}\n\nresult {\n\tname: "SRTO_VAR"\nvalue: "'
                            + srObjectValue +'"\n}\n}\n}'
                            + 'policy {\n\t'
                            + 'name: "PRODUCT-NAME"\n'
                            + 'rule {\n\t'
                            + 'selector: "//default/query1"\n'
                            + 'result {\n\t'
                            + 'name: "PRODUCT_NAME"\n'
                            + 'value: '+'"'+trialsReqFormAfterInsert.Trials_Product__c+'"'+'\n'
                            + '}\n}\n}\n\n\n'
                            + 'policy {\n\t'
                            + 'name: "DPC-PAGES"\n'
                            + 'rule {\n\t'
                            + 'selector: "//default/query1"\n'
                            + 'result {\n\t'
                            + 'name: "CACHE_PAGES"\n'
                            + 'value: '+ '"'+cacheUrlList+'"'
                            + ' '
                            +'}\n}\n}\n}\n';
            
        }                                                                      
        else
        {
            body = 'content_policy {\n\ttaxonomy {\n\tname: "default"\n\ncategory {\n\tname: "query"\ncondition {\n\ttype: REQUEST_HOST\nparam {\tvalue: "'
                        + akamaiEDNS + '"}\n}\n}\n\ncategory {\n\tname: "query1"\ncondition {\n\ttype: REQUEST_HOST\nparam {\n\tvalue: "'
                        + akamaiEDNS +'"\n}\n}\n}\n}\n\npolicy {'
                        + '\n\tname: "PCONN-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "PCONN_VAR"\nvalue: "'
                        + pconnVarValueString + '"}\n\n}\n}\n\npolicy {\n\tname: "TTL-RULE"'
                        + '\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "EXTN_LIST"\nvalue: "'
                        + ttlFileExtn + '"\n}\n\nresult {\n\tname: "TTL_EXTN"\nvalue: "'
                        + ttl + '"\n}\n}\n}\n\npolicy {\n\tname: "TORIGIN"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "ORIGIN_VAR"'
                        + '\nvalue: "'+ originEDNSTrimmed + '"\n}result {\n\tname: "HOST_VAR"\nvalue: "'
                        + hostName + '"\n}\n}\n}\n\npolicy {\n\tname: "TD-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "TD_VAR"\nvalue: "'
                        + tdValueString +'"\n}\n}\n}\n\npolicy {\n\tname: "SR-RULE"\n\nrule {\n\tselector: "//default/query1"\nresult {\n\tname: "SR_VAR"\nvalue: "'
                        + srValueString +'"\n}\n\nresult {\n\tname: "SRTO_VAR"\nvalue: "'
                        + srObjectValue +'"\n}\n}\n}\n\n\n}'; 
        }                 
        //'Content-Disposition: form-data; name="data"; filename="'+'foo.txt'+'"\nContent-Type: multipart/form-data';
       // String footer = '\n--'+boundary+'--';
        
        
       // String bodyEncoded = EncodingUtil.urlEncode(body, 'UTF-8');
        //body = EncodingUtil.urlEncode(header, 'UTF-8')+bodyEncoded+EncodingUtil.urlEncode(footer, 'UTF-8');
        /*End of code for generating the file body*/

        req.setEndpoint('http://techsales1-nsu.akamaihd.net/113275/trialsautomation/policies/'+fileNameFromForm+'.bin');
        
        //req.setHeader('Host','techsales1-nsu.akamaihd.net');
       
        req.setMethod('POST');
        req.setBody(body);
        String md5Code = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(body)));
        
        /*Get the epoch time in seconds hence dividing by 1000*/
        datetime dt = datetime.now();
        Long epochTime = dt.getTime()/1000;
        
        //ignoring the optional parameters in the action header – md5 and mtime.
        String actionHeader = 'version=1&action=upload';//&md5='+md5Code+'&mtime='+epochTime;

        /*Setting the action header*/
        req.setHeader('X-Akamai-ACS-Action', actionHeader);
        /*Setting the content type to indicate that we are uploading a file*/
                
        /*
          Auth data should be in the below format:
          AUTH_DATA="5, 0.0.0.0, 0.0.0.0, $CURRENT_DATE, $CURRENT_UNIQ, $AK_USERNAME"
          */
        String XAkamaiACSAuthData = '5, 0.0.0.0, 0.0.0.0, '+epochTime+', '+uniqueId+', trauto';
                
        String HMAC256Code = generateSignature(XAkamaiACSAuthData,actionHeader);
        
        /*Set the Auth data and auth sign headers*/
        req.setHeader('X-Akamai-ACS-Auth-Data', XAkamaiACSAuthData);       
        req.setHeader('X-Akamai-ACS-Auth-Sign', HMAC256Code);
        req.setHeader('Content-Type','multipart/form-data');
        req.setHeader('Content-Length', String.valueOf(body.length()));
        
        //Send the http request. This is the point where the error comes.
        res = http.send(req);
        
        if(res.getStatusCode() != 200)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Netstorage request failed. '+res.getBody()));
            //return null;
        }
         
        //System.assertEquals(res.getStatusCode(),null);
            
    } 
    
    /*End of changes for Jaya's code*/
    
    /*Start of changes for Jaya's code - EDNS*/
    
        /**
     * The signing algorithm for the EdgeGrid version 1 protocol.
     */
    private static final String ALGORHTM = 'EG1-HMAC-SHA256';

    /**
     * The HMAC algorithm used.
     */
    private static final String HMAC_ALG = 'HmacSHA256';

    /**
     * The message digest algorithm used.
     */
   // private static final String MD_ALG = 'SHA-256';

    /**
     * The charset used for String to bytes conversions.
     */
    private static final String CHARSET = 'UTF-8';

    /**
     * The field name for the client token in the authorization header.
     */
    private static final String AUTH_CLIENT_TOKEN_NAME = 'client_token';

    /**
     * The field name for the access token in the authorization header.
     */
    private static final String AUTH_ACCESS_TOKEN_NAME = 'access_token';

    /**
     * The field name for the time stamp in the authorization header.
     */
    private static final String AUTH_TIMESTAMP_NAME = 'timestamp';

    /**
     * The field name for the nonce in the authorization header.
     */
    private static final String AUTH_NONCE_NAME = 'nonce';

    /**
     * The field name for the signature in the authorization header.
     */
    private static final String AUTH_SIGNATURE_NAME = 'signature';
    
    /** This function generates the body to be posted to the server.
    * Parses through the response of the get request and forms the post body.
    * The attributes or type of records that we are considering are: zone,soa,ns,a,cname.
    * We would need to modify this code in case any additional type of records are to be considered.
    * https://developer.akamai.com/api/luna/config-dns/overview.html contains explanations of all types of records. 
    
    Author: Jaya
    */
    public static Boolean tokenFoundFlag = false;
    public String generatePostBody(EdnsResponse body)
    {
        //System.assertEquals(body,null);
        JSONGenerator gen = JSON.createGenerator(true);
               
        String protocol =  trialsReqForm.Trials_Protocol__c;
        String product = trialsReqForm.Trials_Product__c;
        
        String idField = trialsReqForm.Name !=NULL ? trialsReqForm.Name.substring(6):'';
       
        String hostNameEdns = trialsReqForm.Trials_Origin__c +'.';
        
        gen.writeStartObject();
            if(body.token != null && body.token != '') 
                gen.writeStringField('token',body.token);
            else
                gen.writeNullField('token');
            gen.writeFieldName('zone');
                gen.writeStartObject();
            if(body.Zone.name != null && body.Zone.name != '') 
                gen.writeStringField('name',body.Zone.name);
            else
                gen.writeNullField('name');
                
                /*Start of block for generating soa */
                gen.writeFieldName('soa');
                    gen.writeStartObject();
                    gen.writeNumberField('serial',body.Zone.soa.serial + 1);
                    gen.writeNumberField('expire',body.Zone.soa.expire);
                    gen.writeNumberField('refresh',body.Zone.soa.refresh);
                    gen.writeNumberField('retry',body.Zone.soa.retry);
                    gen.writeNumberField('ttl',body.Zone.soa.ttl);
                    gen.writeNumberField('minimum',body.Zone.soa.minimum);
                    if(body.Zone.soa.contact !=null && body.Zone.soa.contact != '')
                        gen.writeStringField('contact',body.Zone.soa.contact);
                    else
                        gen.writeNullField('contact');
                    if(body.Zone.soa.originserver != null && body.Zone.soa.originserver != '')
                        gen.writeStringField('originserver',body.Zone.soa.originserver);
                    else
                        gen.writeNullField('originserver');
                    gen.writeEndObject();
                    /*End of block for generating soa */
                    
              /*Start of block for generating ns */
              gen.writeFieldName('ns');                  
                  gen.writeStartArray();
                  for(EdnsResponse.Ns nsRecs:body.Zone.ns)
                  {
                      gen.writeStartObject();
                      if(nsRecs.name != null && nsRecs.name != '')
                          gen.writeStringField('name',nsRecs.name);
                      else 
                          gen.writeNullField('name');
                      gen.writeBooleanField('active',nsRecs.active);
                      if(nsRecs.target != null && nsRecs.target != '')
                          gen.writeStringField('target',nsRecs.target);
                      else 
                          gen.writeNullField('target');
                      gen.writeNumberField('ttl',nsRecs.ttl);
                      gen.writeEndObject();                    
                  }
                  gen.writeEndArray();
              /*End of block for generating ns */   
              
              /*Start of block for generating a */ 
              gen.writeFieldName('a');                  
                  gen.writeStartArray();
                  for(EdnsResponse.A aRecs:body.Zone.a)
                  {
                      gen.writeStartObject();
                      if(aRecs.name != null && aRecs.name != '')
                          gen.writeStringField('name',aRecs.name);
                      else 
                          gen.writeNullField('name');
                      gen.writeBooleanField('active',aRecs.active);
                      if(aRecs.target != null && aRecs.target != '')
                          gen.writeStringField('target',aRecs.target);
                      else 
                          gen.writeNullField('target');
                      gen.writeNumberField('ttl',aRecs.ttl);
                      gen.writeEndObject();                    
                  }
                  gen.writeEndArray();
              /*End of block for generating a */
              
              /*Start of block for generating cname */ 
              gen.writeFieldName('cname');                  
                  gen.writeStartArray();
                  for(EdnsResponse.Cname cnameRecs:body.Zone.cname)
                  {
                      gen.writeStartObject();
                      if(cnameRecs.name != null && cnameRecs.name != '')
                          gen.writeStringField('name',cnameRecs.name);
                      else 
                          gen.writeNullField('name');
                      gen.writeBooleanField('active',cnameRecs.active);
                      if(cnameRecs.target != null && cnameRecs.target != '')
                          gen.writeStringField('target',cnameRecs.target);
                      else 
                          gen.writeNullField('target');
                      gen.writeNumberField('ttl',cnameRecs.ttl);
                      gen.writeEndObject();                    
                  }
                  /* Create a new cname record */
                if(protocol == 'Freeflow' && (product == 'DSA' || product == 'WAA'))
                {
                    /*cname for akamai edns*/
                    gen.writeStartObject();
                    if(targetHttpDSAWAAValue != null && targetHttpDSAWAAValue != '')
                        gen.writeStringField('target', targetHttpDSAWAAValue);  
                    else 
                        gen.writeNullField('target'); 
                    if(cnameNameHttpField != null && cnameNameHttpField != '')                                                               
                        gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpField);
                    else 
                        gen.writeNullField('name');    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                   // gen.writeEndArray();
                    
                    /*cname for origin edns*/
                    gen.writeStartObject();
                    if(hostNameEdns != null && hostNameEdns != '')
                        gen.writeStringField('target', hostNameEdns);
                    else 
                        gen.writeNullField('target'); 
                    if(cnameNameHttpField != null && cnameNameHttpField != '')                                                             
                        gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpField); 
                    else 
                        gen.writeNullField('name');    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                }
                else if(protocol == 'Freeflow' && product == 'DSD') 
                {
                    /*cname for akamai edns*/
                    gen.writeStartObject();
                    if(targetHttpDSDValue != null && targetHttpDSDValue != '')  
                        gen.writeStringField('target', targetHttpDSDValue);
                    else 
                        gen.writeNullField('target'); 
                    if(cnameNameHttpField != null && cnameNameHttpField != '')                                                                
                        gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpField); 
                    else 
                        gen.writeNullField('name');    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                    /*cname for origin edns*/
                    gen.writeStartObject();
                    if(hostNameEdns != null && hostNameEdns != '')  
                        gen.writeStringField('target', hostNameEdns);
                    else
                        gen.writeNullField('target');  
                    if(cnameNameHttpField != null && cnameNameHttpField != '')                                                              
                        gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpField);
                    else
                        gen.writeNullField('name');     
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                }
                else if(protocol == 'ESSL' && (product == 'DSA' || product == 'WAA'))
                {
                    /*cname for akamai edns */
                    gen.writeStartObject();
                    if(targetHttpsDSAWAAValue != null && targetHttpsDSAWAAValue != '') 
                        gen.writeStringField('target', targetHttpsDSAWAAValue);   
                    else
                        gen.writeNullField('target');  
                    if(cnameNameHttpsField != null && cnameNameHttpsField != '')                                                               
                        gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpsField);   
                    else
                        gen.writeNullField('name'); 
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                    /*cname for origin edns */
                    gen.writeStartObject();
                    if(hostNameEdns != null && hostNameEdns != '')  
                        gen.writeStringField('target', hostNameEdns);
                    else
                        gen.writeNullField('target');  
                    if(cnameNameHttpsField != null && cnameNameHttpsField != '')                                                              
                        gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpsField);   
                    else
                        gen.writeNullField('name'); 
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                }
                else if(protocol == 'ESSL' && product == 'DSD') 
                {
                    /*cname for akamai edns */
                    gen.writeStartObject();
                    if(targetHttpsDSDValue != null && targetHttpsDSDValue != '')
                        gen.writeStringField('target', targetHttpsDSDValue);
                    else
                        gen.writeNullField('target'); 
                    if(cnameNameHttpsField != null && cnameNameHttpsField != '')                                                              
                        gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpsField);
                    else
                        gen.writeNullField('name');    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                    /*cname for origin edns */
                    gen.writeStartObject();
                    if(hostNameEdns != null && hostNameEdns != '') 
                        gen.writeStringField('target', hostNameEdns);
                    else
                        gen.writeNullField('target');    
                    if(cnameNameHttpsField != null && cnameNameHttpsField != '')                                                            
                        gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpsField); 
                    else
                        gen.writeNullField('name');   
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                }
                /*Added for ion will undergo a change*/
                else if(protocol == 'Freeflow' && product == 'ION') 
                {
                    
                    gen.writeStartObject();
                    if(targetHttpIonValue != null && targetHttpIonValue != '')
                        gen.writeStringField('target', targetHttpIonValue);  
                    else
                        gen.writeNullField('target');                                                            
                    gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpField);    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                    
                    gen.writeStartObject();
                    gen.writeStringField('target', hostNameEdns);                                                              
                    gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpField);    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                }
                
                else if(protocol == 'ESSL' && product == 'ION') 
                {
                    
                    gen.writeStartObject();
                    if(targetHttpsIonValue != null && targetHttpsIonValue != '')
                        gen.writeStringField('target', targetHttpsIonValue);  
                    else
                        gen.writeNullField('target');                                                              
                    gen.writeStringField('name', 'test'+idField+'.'+cnameNameHttpsField);    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                    
                    gen.writeStartObject();
                    gen.writeStringField('target', hostNameEdns);                                                              
                    gen.writeStringField('name', 'origin-test'+idField+'.'+cnameNameHttpsField);    
                    gen.writeBooleanField('active', true);
                    gen.writeNumberField('ttl', 7200);                                                                                            
                    gen.writeEndObject();
                    //gen.writeEndArray();
                    
                }
                  gen.writeEndArray();
              /*End of block for generating cname */
                    
        gen.writeEndObject();
        //System.assertEquals(gen.getAsString(),null);
        return gen.getAsString();
    }
    
    /* Sends the get and post request to the server */    
    public void postRequest()
    {
        String trimmedSignature = '';
        trialsReqFormAfterEdns = [SELECT Id, Trials_EdnsDone__c FROM Trials_Request_Form__c WHERE id = :trialsReqForm.Id];
        
        /* Only if Edns post is not yet done, execute the below code. This condition is for handling updates. Edns should not perform updates. */
        if(trialsReqFormAfterEdns.Trials_EdnsDone__c == false)
        {
            /*Added by Jaya to check if the trials request form */                
            /*Unique id to be used as nonce*/       
            String guid = GuidUtil.NewGuid();
            
            Trials__c trialsClientSecret = Trials__c.getValues('EdnsClientSecret');
            String clientSecret = trialsClientSecret.Value__c;
            
            Trials__c trialsClientToken = Trials__c.getValues('EdnsClientToken');
            String clientToken = trialsClientToken.Value__c;
            
            Trials__c trialsAccessToken = Trials__c.getValues('EdnsAccessToken');
            String accessToken = trialsAccessToken.Value__c;
            
            Trials__c trialsEdnsHostName = Trials__c.getValues('Edns_HostName');
            String ednsHostName = trialsEdnsHostName.Value__c;        
            
            Trials__c trialsEdnsRelativePath = Trials__c.getValues('EdnsRelativePath');
            String ednsRelativePath = trialsEdnsRelativePath.Value__c;
                    
            /*Returns the time in GMT format. The upper case HH for hours is for getting the output in 24 hour format.*/
            //String gmtDateTime2 = Datetime.now().format('yyyyMMdd\'T\'HH:mm:ss\'+0000\'');
            
            
            
            DateTime gmtDateTime1 = Datetime.now();//.format('yyyyMMdd\'T\'HH:mm:ss\'+0000\'');
            
            DateTime gmtDateTimeUnformatted = DateTime.valueOf(String.valueOfGmt(gmtDateTime1));//.format('yyyyMMdd\'T\'HH:mm:ss\'+0000\'');
            
            String gmtDateTime = gmtDateTimeUnformatted.format('yyyyMMdd\'T\'HH:mm:ss\'+0000\'');
            
            //System.assertEquals(gmtDateTime,null);
            
            String endPoint = 'https://'+ednsHostName+ednsRelativePath;
          
            String signingKey = generateHmacSHA256Signature(clientSecret,gmtDateTime);
            //Blob signingKey = Crypto.generateMac('HmacSHA256', Blob.valueOf(clientSecret), Blob.valueOf(gmtDateTime));
            String authData = ALGORHTM + ' ' + AUTH_CLIENT_TOKEN_NAME + '=' + clientToken + ';' + AUTH_ACCESS_TOKEN_NAME + '='
                              + accessToken + ';' + AUTH_TIMESTAMP_NAME + '=' +  gmtDateTime + ';' + AUTH_NONCE_NAME + '=' + guid
                              + ';';
                              
            //String requestData = 'GET\thttps\takaa-55a32tmjhzg6ivpo-jabj44znoccmammr.luna.akamaiapis.net\t/config-dns/v1/zones/ajayapra.org\t\t\tEG1-HMAC-SHA256 client_token='+clientToken+';access_token='+accessToken+';timestamp='+gmtDateTime+';nonce='+guid+';';
            String requestData = 'GET\thttps\t'+ednsHostName+'\t'+ednsRelativePath+'\t\t\tEG1-HMAC-SHA256 client_token='+clientToken+';access_token='+accessToken+';timestamp='+gmtDateTime+';nonce='+guid+';';
            
            String signature = generateHmacSHA256Signature(signingKey,requestData);
          
            /*Append the signature to the auth data*/
            authData = authData+'signature='+signature;
            
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();
                
            req.setMethod('GET');
            req.setHeader('Authorization', authData);       
            req.setEndpoint(endPoint);
            res = http.send(req); 
            if(res.getStatusCode() != 200)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'EDNS GET request failed. '+res.getBody()));
            }
            else
            {
                EdnsResponse ednsRes = (EdnsResponse)JSON.deserialize(res.getBody(), EdnsResponse.class);                  
                String tokenFromGetRequest = '';
                
                String postBody = generatePostBody(ednsRes);
         
                String body = postBody;
                
                HttpRequest req1 = new HttpRequest();
                req1.setBody(body);
                //System.assertEquals(body,null);
                req1.setHeader('Content-Type','application/json');
                
                req1.setHeader('Content-Length', String.valueOf(body.length()));
                req1.setMethod('POST');
                req1.setEndpoint(endPoint);
                /*Start of change by janantha for reducing the signature size 262144 characters*/
                String hexValueOfBody = EncodingUtil.convertToHex(req1.getBodyAsBlob()); 
                if(hexValueOfBody.length()>262144) 
                    trimmedSignature = hexValueOfBody.substring(0,262144); 
                else
                    trimmedSignature = hexValueOfBody;
                    
                String bodyHash = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', EncodingUtil.convertFromHex(trimmedSignature)));    
                    
                //String bodyHash = EncodingUtil.base64Encode(Crypto.generateDigest('SHA-256', req1.getBodyAsBlob()));
                String requestData1 = 'POST\thttps\t'+ednsHostName+'\t'+ednsRelativePath+'\t\t'+bodyHash+'\tEG1-HMAC-SHA256 client_token='+clientToken+';access_token='+accessToken+';timestamp='+gmtDateTime+';nonce='+guid+';';
                
                String signature1 = generateHmacSHA256Signature(signingKey,requestData1);
                
                String authData1 = ALGORHTM + ' ' + AUTH_CLIENT_TOKEN_NAME + '=' + clientToken + ';' + AUTH_ACCESS_TOKEN_NAME + '='
                                  + accessToken + ';' + AUTH_TIMESTAMP_NAME + '=' +  gmtDateTime + ';' + AUTH_NONCE_NAME + '=' + guid
                                  + ';';
               
                authData1 = authData1+'signature='+signature1;
                              
                HttpResponse res1 = new HttpResponse();
                Http http1 = new Http();
                            
                req1.setHeader('Authorization', authData1);         
                req1.setTimeout(60000);
                res1 = http1.send(req1);
                if(res1.getStatusCode() != 204)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'EDNS POST request failed. '+res1.getBody()));
                }
                
                /*Edns returns a null string on successful post. Hence update the flag to true*/
                if(res1.getBody() == '')
                {                
                    trialsReqFormAfterEdns.Trials_EdnsDone__c = true;
                    update trialsReqFormAfterEdns;
                } 
            }               
       }    
    }
    
    public void submit(){
        integer  timeOutValue = Integer.valueOf(Trials_Automation_Site_Analyser_Details__c.getValues('SABackDateTime').Value__c);
        DateTime expDate = DateTime.Now();
        try{
            sendNotification();
        
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Netstorage POST request failed.'));
        }
        
        try{
            postRequest();
        }
        catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'EDNS POST request failed.'));
        }
        
        list<Trials_XML__c> lXMLToUpdate = [SELECT Id,Trials_Generated_XML__c,Trials_Akamai_XML__c,Trials_Request_Form__r.Name,
                                            Trials_Frequency_for_Running_Test__c FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqForm.Id];
        trialsReqForm.Trials_Akamai_Binary_Response__c = null;
        trialsReqForm.Origin_Binary_Response__c = null;
        trialsReqForm.Trials_Instant_Check_Back_Date__c = DateTime.now().addMinutes(-timeOutValue);
        trialsReqForm.TrialsEndDate__c = expDate.addDays(Integer.valueOf(trialsReqForm.Trials_Test_Duration_In_Days__c) + 1);
        update trialsReqForm;
        
        if(trialsReqForm.Trials_DNS_Created__c){
            
            TrialsUtilClass.doInstantCheck(trialsReqForm.Id);
        }   
    }
}
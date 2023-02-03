@RestResource(urlMapping='/SAResponseToSF/*')
global class TrialsResponseFromSA{
    @HttpPost
        global static void attachResponseToChildObject(String recordId, List<JSONFromSA> receivedJSON){
           string binaryResponse;
           Map<string,integer> mCodeCounts = new Map<string, integer>();
           System.debug('recordId: '+ recordId);
           System.debug('receivedJSON: '+ receivedJSON);
           List<Trials_XML__c> lTrailsXML = [SELECT Id, Trials_JSON_Received__c, Trials_Akamai_XML__c, Trials_Request_Form__r.Trials_JSON_Received_For_Origin_XML__c,
                                             Trials_Request_Form__c,Trials_Request_Form__r.Trials_JSON_Received_For_Akamai_XML__c FROM Trials_XML__c WHERE Id=: recordId];
            if(lTrailsXML.size()>0){
            for(JSONFromSA objJSONFromSA: receivedJSON){
               integer successCodeCount = 0;
               integer failureCodeCount = 0;
               if(objJSONFromSA.TranSummary != NULL && objJSONFromSA.TranSummary.hasErrors != NULL){
                   binaryResponse = TrialsUtilClass.convertIntToBinary(objJSONFromSA.TranSummary.hasErrors);
               }
               if(objJSONFromSA.tranSummary != NULL && objJSONFromSA.tranSummary.transactionTime !=NULL){
                   lTrailsXML[0].Trials_Response_time__c = (Decimal.valueOf(objJSONFromSA.tranSummary.transactionTime))/1000;
               }
               if(objJSONFromSA.tranSummary != NULL){
                   lTrailsXML[0].Trials_Objects__c = objJSONFromSA.tranSummary.numUrls;
               }
               if(objJSONFromSA.Pages !=null){ 
                   for(Pages objPages :objJSONFromSA.Pages){
                       
                       for(PageObjects objPageObjects :objPages.pageObjects){
                           if(mCodeCounts.containsKey(objPageObjects.responseCode)){
                              integer i = mCodeCounts.get(objPageObjects.responseCode) + 1;
                              mCodeCounts.put(objPageObjects.responseCode,i); 
                           }
                           
                           else{
                               mCodeCounts.put(objPageObjects.responseCode, 1);
                           }
                       }
                   }
               }    
               for(string varString :mCodeCounts.keySet()){
                   if(lTrailsXML[0].Trails_All_Code_Counts__c == '' || lTrailsXML[0].Trails_All_Code_Counts__c==null){
                       lTrailsXML[0].Trails_All_Code_Counts__c =  varString + ':'+ mCodeCounts.get(varString);
                   }
                   
                   else{
                       lTrailsXML[0].Trails_All_Code_Counts__c = lTrailsXML[0].Trails_All_Code_Counts__c + ':' + varString + ':' 
                                                             + mCodeCounts.get(varString);
                   }
               }
               lTrailsXML[0].Trials_Response_Codes__c = successCodeCount;
           }
                                          
           if(lTrailsXML.size()>0){
               string varJSON = String.valueOf(receivedJSON);
               if(varJSON.length() > 30001){
                   varJSON = varJSON.subString(0,30000);
                   
               }
               lTrailsXML[0].Trials_JSON_Received__c = varJSON;
                   
               /*if(lTrailsXML[0].Trials_Akamai_XML__c){
                   lTrailsXML[0].Trials_Request_Form__r.Trials_JSON_Received_For_Akamai_XML__c = true;
               }
               
               else{
                   lTrailsXML[0].Trials_Request_Form__r.Trials_JSON_Received_For_Origin_XML__c = true;
               }*/
               update lTrailsXML;
           } 
            
           List<Trials_Request_Form__c> lTrialsRequestForm = [SELECT Id,Trials_Objects_Akamai__c, Trails_Objects_Origin__c,Trials_JSON_Received_For_Akamai_XML__c,Trials_Akamai_Binary_Response__c,
                                                             Trials_Response_Codes_Akamai__c, Trails_Response_Codes_Origin__c, Trials_Response_Time_Akamai__c,Trials_JSON_Received_For_Origin_XML__c,
                                                             Trials_Akamai_Provisioned_Test_Id__c, Trials_Origin_Provisioned_Test_Id__c,
                                                             Origin_Binary_Response__c, Trials_Response_Time_Origin__c FROM Trials_Request_Form__c WHERE Id =:lTrailsXML[0].Trials_Request_Form__c];
            
            if(lTrailsXML != NULL && lTrailsXML[0].Trials_Akamai_XML__c && lTrialsRequestForm != NULL){
                lTrialsRequestForm[0].Trials_Objects_Akamai__c = lTrailsXML[0].Trials_Objects__c;
                lTrialsRequestForm[0].Trials_Response_Codes_Akamai__c = lTrailsXML[0].Trails_All_Code_Counts__c;
                lTrialsRequestForm[0].Trials_Response_Time_Akamai__c = String.valueOf(lTrailsXML[0].Trials_Response_time__c);
                lTrialsRequestForm[0].Trials_JSON_Received_For_Akamai_XML__c = true;
                lTrialsRequestForm[0].Trials_Akamai_Binary_Response__c = binaryResponse;
                
            }
            
            else if(lTrailsXML != NULL && lTrialsRequestForm != NULL && !lTrailsXML[0].Trials_Akamai_XML__c){
                for(integer i=0;i<20000;i++){
                }
                lTrialsRequestForm[0].Trails_Objects_Origin__c = lTrailsXML[0].Trials_Objects__c;
                lTrialsRequestForm[0].Trails_Response_Codes_Origin__c = lTrailsXML[0].Trails_All_Code_Counts__c;
                lTrialsRequestForm[0].Trials_Response_Time_Origin__c = String.valueOf(lTrailsXML[0].Trials_Response_time__c);
                lTrialsRequestForm[0].Trials_JSON_Received_For_Origin_XML__c = true;
                lTrialsRequestForm[0].Origin_Binary_Response__c = binaryResponse;
                /*
                if(lTrialsRequestForm[0].Trials_JSON_Received_For_Akamai_XML__c && 
                   lTrialsRequestForm[0].Trials_JSON_Received_For_Origin_XML__c){
                    lTrialsRequestForm[0].Trials_Provisioned_Trails_Back_Date__c = DateTime.now().addMinutes(-45);       
                }
                */
            }
            try{
                update lTrialsRequestForm;
            }
            catch(Exception e){
                //try{
                    for(integer i=0;i<20000;i++){
                    }
                    system.debug('#### In Exception' + lTrialsRequestForm);
                    update lTrialsRequestForm;
               // }
                
            }
                
                if((lTrialsRequestForm[0].Trials_Akamai_Provisioned_Test_Id__c!=NULL && lTrailsXML[0].Trials_Akamai_XML__c) ||
                   (lTrialsRequestForm[0].Trials_Origin_Provisioned_Test_Id__c!=NULL && !lTrailsXML[0].Trials_Akamai_XML__c)){
                    system.debug('In Update Method' + lTrialsRequestForm[0].Trials_Akamai_Provisioned_Test_Id__c + ' ' + lTrialsRequestForm[0].Trials_Origin_Provisioned_Test_Id__c);
                    TrialsUtilClass.provisionTest(lTrailsXML[0].Trials_Request_Form__c);
                    
                }
                
                else{
                    TrialsUtilClass.provisionTest(lTrailsXML[0].Trials_Request_Form__c);
                }
            }
            
            
            //return 'Hello Outside World ' + recordId + ' '+ receivedJSON;
        }
    
    
    global class JSONFromSA{
        string testType;
        string regionId;
        string regionName;
        TranSummary tranSummary;
        List<Pages> pages;
    }
    
    public class TranSummary{
        string regionId;
        string numPages;
        string numUrls;
        string transactionTime;
        string hasErrors;
        string totalBytes;
    }
    
    public class Pages{
        string header;
        List<PageObjects> pageObjects;
        PageSummary pageSummary;
    }
    
    public class PageObjects{
        string path;
        string protocol;
        string port;
        string domain;
        string startTime;
        string errorCode;
        string connectTime;
        string objectType;
        string serverIp;
        string isConnectionAlive;
        string contentLen;
        string checkSum;
        string dnsTime;
        string handshakeTime;
        string dataStartTime;
        string dataDownloadTime;
        string totalTime;
        string isReconnect;
        string responseCode;
    }
    
    public class PageSummary{
        string regionId;
        string totalDownloadTime;
        string baseDownloadTime;
        string hasErrors;
        string totalUrls;
        string totalBaseUrls;
        string totalBytes;
        string domLoading;
        string domComplete;
        string loadEventStartTime;
        string loadEventEndTime;
        string stepNum;
        
    }

}
/***
    TrialsUtilClass:
    
    @History
    --Developer           --Date            --Change
    Sharath Prasanna      26/11/2014      Modified the class for CRs 2744679,2722890 and 2870661.    
*/

public with sharing class TrialsUtilClass {
    
    static List<string> lURLLocals = new list<string>();
    static Map<string, Trials_Automation_Site_Analyser_Details__c> mTrialsSACustomSetting = new Map<string, Trials_Automation_Site_Analyser_Details__c>();
    
    static {
       mTrialsSACustomSetting = Trials_Automation_Site_Analyser_Details__c.getAll();
    }
    public static string createXMLFile(List<string> lURLs, boolean thirdParty, string frequency , boolean akamaiXML,
                                      string hostName, string akamaiEDNS){
        string acgId;
        string recorderVersion; 
        //lURLLocals = lURLs;
                                          
        if(akamaiXML){
            //this.lURLs = lURLs;
            for(string varString: lURLs){
                system.debug('<<<<' + varString.replaceFirst(hostName, akamaiEDNS));
                varString = varString.replaceFirst(hostName, akamaiEDNS);
                lURLLocals.add(varString);
                system.debug('<<<<' + varString.replaceFirst(hostName, akamaiEDNS));
                system.debug('!!!!!' + varString);
            }
        }
                                                  
        XmlStreamWriter originXML = new XmlStreamWriter();
        originXML.writeStartDocument('UTF-8', '1.0');
        originXML.writeCharacters('\n');                     
          originXML.writeStartElement(null, 'test', null);
                originXML.writeAttribute(null, null, 'testId', '1');
                originXML.writeAttribute(null, null, 'testName', 'Tst');
                originXML.writeAttribute(null, null, 'acgId', 'TestId');
                originXML.writeAttribute(null, null, 'appType', 'satest');
                originXML.writeAttribute(null, null, 'queryLogOption', '3');
                originXML.writeAttribute(null, null, 'frequency', frequency);
                originXML.writeAttribute(null, null, 'testType', 't');
                originXML.writeCharacters('\r\n');                          
            
        originXML.writeStartElement(null, 'sessionInfo', null);
            originXML.writeAttribute(null, null, 'id', '1');
            originXML.writeAttribute(null, null, 'recorderVersion', '1.39.9');
            originXML.writeCharacters('\r\n');                                          
        integer i = 1;
        
        if((akamaiXML && lURLLocals != null) || (!akamaiXML && lURLs != null)){
            for(string objUrl: akamaiXML? lURLLocals:lURLs){
                originXML.writeStartElement(null, 'step', null); //This will come under a for loop for multiple URLs 
                    originXML.writeAttribute(null, null, 'id', string.valueof(i)); // Will be one variable for this
                    originXML.writeAttribute(null, null, 'name', 'step' + i); // Will come from form
                    originXML.writeAttribute(null, null, 'breakOnError', 'false');
                    originXML.writeCharacters('\r\n');                     
                
                originXML.writeStartElement(null, 'fullPage', null);
                    originXML.writeAttribute(null, null, 'processEmbeddedUrl', 'true');
                    originXML.writeAttribute(null, null, 'breakOnError', 'false');
                    originXML.writeCharacters('\r\n');                     
                
                originXML.writeStartElement(null, 'basePage', null);
                  originXML.writeAttribute(null, null, 'id', '1'); //This should be variable
                  originXML.writeCharacters('\r\n');                     
                
                originXML.writeStartElement(null, 'url', null);
                    originXML.writeAttribute(null, null, 'isHex', 'false');
                    originXML.writeAttribute(null, null, 'hasVariable', 'false');
                    originXML.writeCharacters(objUrl.trim());
                
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
                
                originXML.writeStartElement(null, 'request', null);
                  originXML.writeAttribute(null, null, 'version', '');
                  originXML.writeCharacters('\r\n');                     
                
                originXML.writeStartElement(null, 'method', null);
                   originXML.writeCharacters('GET');                     
                  
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
              
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
                
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
 
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
                
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
                ++i;
            }
        }
        originXML.writeStartElement(null, 'limits', null);
                originXML.writeAttribute(null, null, 'numConnections', '4');
                originXML.writeAttribute(null, null, 'maxRequests', '2');
                originXML.writeAttribute(null, null, 'maxBitRate', '0');
                originXML.writeAttribute(null, null, 'maxPlaytime', '0');
                originXML.writeAttribute(null, null, 'maxStreamTime', '0');
              //Start of changes made by sharath for CR - 2744679
              //  originXML.writeAttribute(null, null, 'maxTimeout', '65535');
              
                originXML.writeAttribute(null, null, 'maxTimeout', mTrialsSACustomSetting.get('SATimeout').value__c);
              //End of changes made for CR - 2744679  
                originXML.writeCharacters('\r\n');                     
       
        originXML.writeStartElement(null, 'maxContentLen', null);
        
        //Start of changes made for CR - 2744679
       // originXML.writeCharacters('0');                    
  
          originXML.writeCharacters(mTrialsSACustomSetting.get('SADownloadLimit').value__c);                    
        //End of changes for CR - 2744769
        originXML.writeEndElement();
        originXML.writeCharacters('\r\n');                                     
        
        originXML.writeEndElement();
        originXML.writeCharacters('\r\n');   
                                          
        originXML.writeStartElement(null, 'filterOptions', null);
        originXML.writeAttribute(null, null, 'isHex', 'false');
        originXML.writeCharacters('\r\n');                     
        
        
                if(thirdParty){
                originXML.writeStartElement(null, 'includeUrl', null);
                    if(akamaiXML){
                        originXML.writeCharacters('.*' + akamaiEDNS + '.*');
                    }
                    else if( !akamaiXML){
                        originXML.writeCharacters('.*' + hostName + '.*');
                    }
                originXML.writeEndElement();
                originXML.writeCharacters('\r\n');   
                }
        
        originXML.writeEndElement();
        originXML.writeCharacters('\r\n');                                     
        
        originXML.writeEndElement();
        originXML.writeCharacters('\r\n');   
                                          
        originXML.writeEndElement();
        String xmlOutput = originXML.getXmlString();
        return xmlOutput;
    }
    
    public static boolean urlRegexChek(List<string> lURLCheck){
        //Start of changes for CR - 2722890    
         //string validURLRegex = '^(https?\\:\\/\\/)(([a-zA-Z0-9\\.a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]+[a-zA-Z0-9])\\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])(.[\\S]*)?$';
      
        string validURLRegex = '^https?\\:\\/\\/[a-zA-Z0-9\\-\\.]+\\.[a-zA-Z]{1,3}(\\/\\S*)?$';
        //End of changes for CR - 2722890
        Pattern domainNamePattern = Pattern.compile(validURLRegex);
        integer i = 1;
        
        for(string varString: lURLCheck){
            Matcher domainNameMatcher = domainNamePattern.matcher(varString.trim());
            if(!domainNameMatcher.matches()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The URL entered at position ' + i + ' is incorrect.'));
                return domainNameMatcher.matches();
            }
            i++;
        }
        
        return true;  
    }
    
    public static boolean domainNameRegexChek(string hostName){
        string validHostnameRegex = '^(([a-zA-Z0-9\\.a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)+([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$';
        Pattern domainNamePattern = Pattern.compile(validHostnameRegex);
        Matcher domainNameMatcher = domainNamePattern.matcher(hostName.trim());
        if(!domainNameMatcher.matches()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter valid Hostname.'));
            return false;
        }
        return true;
    }
    
    public static boolean testNamePrefixRegexCheck(string testNamePrefix){
        string validTestNamePrefix = '[0-9A-Za-z\\.,_\\-:]+';
        Pattern testNamePrefixPattern = Pattern.compile(validTestNamePrefix);
        Matcher testNamePrefixMatcher = testNamePrefixPattern.matcher(testNamePrefix.trim());
        if(!testNamePrefixMatcher.matches()){
             // change made by shprasan for CR-2870661. Modified the error message, added in Test name prefix
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Special Character are not allowed in Test Name Prefix'));
            return false;
        }
        return true;
    }
    
    public static boolean hostnameURLMatcher(string hostname, list<string> lURLToMatchHostname){
        integer i =1;
        for(string varString: lURLToMatchHostname){
            if(varString.startsWithIgnoreCase('http://') && !varString.substringAfter('http://').startsWithIgnoreCase(hostname.trim())){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Host name and URL does not match. ' + i));
                return false;
            }
            
            else if(varString.startsWithIgnoreCase('https://') && !varString.substringAfter('https://').startsWithIgnoreCase(hostname.trim())){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Host name and URL does not match. ' + i));
                return false;
            }
            
            i++;
        }
        return true;
    }
    
    public static boolean allTrialsValidation(Trials_Request_Form__c trialsReqForm){
        List<string> lURLs = new List<string>();
        List<string> lCacheableURLs = new List<string>();
        
        if(! String.isBlank(trialsReqForm.Trials_URLs__c)){
            lURLs = trialsReqForm.Trials_URLs__c.split('\n');
        }
        
        if(! String.isBlank(trialsReqForm.Trials_Cacheable_URLs__c)){
            lCacheableURLs = trialsReqForm.Trials_Cacheable_URLs__c.split('\n');
        }
        
        //for(string varURL: lURLs){
            for(string varCacheableURL: lCacheableURLs){
                system.debug('######!@!@!' + varCacheableURL);
                system.debug('####' + varCacheableURL.trim().equals('/'));
                 system.debug('######!@!@!' + trialsReqForm.Trials_URLs__c);
                if(!varCacheableURL.startsWithIgnoreCase('/') ||
                   varCacheableURL.startsWithIgnoreCase('http://')  ||
                   varCacheableURL.startsWithIgnoreCase('https://') || 
                   varCacheableURL.trim().contains(trialsReqForm.Trials_Hostnames_Digital_Properties__c.trim())){
                   
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The cacheable path should start with "/" and should be a part of  test URLs'));
                       return false;
                }
                
                else if(!trialsReqForm.Trials_URLs__c.containsIgnoreCase(varCacheableURL.trim()) && !varCacheableURL.trim().equals('/')){
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The cacheable path should start with "/" and should be a part of  test URLs'));
                     return false;
                }
               
            }
        //}
        
        if(! testNamePrefixRegexCheck(trialsReqForm.TrialsTestNamePrefix__c)){
            return false;
        }
        
        if(! String.isBlank(trialsReqForm.Trials_Hostnames_Digital_Properties__c) && 
           trialsReqForm.Trials_Hostnames_Digital_Properties__c.contains('\n')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please remove Newline/Enter character from Hostname.'));
            return false;
        }
        
        if(! domainNameRegexChek(trialsReqForm.Trials_Hostnames_Digital_Properties__c)){
            return false;
        }
                
        if(! String.isBlank(trialsReqForm.Trials_URLs__c) && trialsReqForm.Trials_URLs__c.contains('\n' + '\n')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please remove multiple Newline/Enter character from two consecutive URLs.'));
            return false;
        }
        
        if(!urlRegexChek(lURLs)){
            return false;
        }
        
        if(!hostnameURLMatcher(trialsReqForm.Trials_Hostnames_Digital_Properties__c,lURLs)){
            return false;
        }
        
        if(trialsReqForm.Trials_Product__c =='DSD' &&  trialsReqForm.Trials_TD__c){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please turn Off TD for DSD'));
                return false;
        }
        
        if(trialsReqForm.Trials_Product__c !='ION' && 
          (trialsReqForm.Trials_Cacheable_URLs__c != Null)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cacheable URLs are only allowed for ION'));
                return false;
        }
        
        if(trialsReqForm.Trials_Product__c =='DSD' && 
           (trialsReqForm.Trials_SRTO__c  != Null)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'SRTO should be blank for DSD'));
                return false;
        }
        
        if(trialsReqForm.Trials_Product__c !='DSD' && 
           (trialsReqForm.Trials_SRTO__c  == Null)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'SRTO is mandatory for products other than DSD'));
                return false;
        }

        return true;
    }
    
    public static HttpRequest setHeader(HttpRequest saRequest,boolean provisionTestReqSent, 
                                        boolean instantCheckReqSent){
    
        saRequest.setHeader('Content-Type','multipart/form-data; boundary=----WebKitFormBoundarySm7nboJHI4QcZjiA');
        saRequest.setHeader('X-ECWS-ManagedCustomer', mTrialsSACustomSetting.get('SAManagedCustomer').value__c);
        //System.debug(saRequest.getHeader('Content-Type'));
        //System.debug(saRequest.getHeader('X-ECWS-ManagedCustomer'));

        String saAuthHeader_raw;
        if(provisionTestReqSent){
            saAuthHeader_raw = mTrialsSACustomSetting.get('Base64TokenForSAProd').value__c;
            saRequest.setEndpoint(mTrialsSACustomSetting.get('SAStagingEndPoint').value__c + 'provision/addtest');
        }
        else if(instantCheckReqSent){  
            saAuthHeader_raw = mTrialsSACustomSetting.get('Base64TokenForSAProd').value__c;
            saRequest.setEndpoint(mTrialsSACustomSetting.get('SAStagingEndPoint').value__c + 'instantcheck/tran');
        }
        String saAuthHeaderFull = 'BASIC ' + saAuthHeader_raw; 
        saRequest.setHeader('Authorization', saAuthHeaderFull);
        //System.debug(saRequest.getHeader('Authorization'));
        //System.debug('The Header is: ' + saRequest);
        saRequest.setMethod('POST');
        saRequest.setTimeout(120000);
        return saRequest;
    } 
    
    public static string createBodyForInstantCheck(string requestXML, string boundryValue, string regionsId, string recIds){
        string constantText = 'Content-Disposition: form-data; name=';
        return boundryValue 
                    + '\n' + constantText + '"regions"' + '\n\n' + mTrialsSACustomSetting.get('SARegionId').value__c +'\n' + boundryValue
                    + '\n' + constantText + '"testXml"' + '\n\n' + requestXML                                        +'\n' + boundryValue 
                    + '\n' + constantText + '"async"'   + '\n\n' + 'true'                                            +'\n' + boundryValue 
                    + '\n' + constantText + '"recordId"'+ '\n\n' + recIds                                            +'\n' + boundryValue
                    + '\n' + constantText + '"dataFromOneRegion"'   + '\n\n' + 'true'                                            +'\n' + boundryValue 
                    + '--';
        
    }
    
    
    
    public static string createBodyForProvisioning(string requestXML, string boundryValue,
                                                   string nameOfTrials,string expireAfterDays,
                                                   string groupName, string testNamePrefix){
        string constantText = 'Content-Disposition: form-data; name=';
        DateTime expDate = DateTime.Now(); 
        string expiryDate = expDate.addDays(Integer.valueOf(expireAfterDays) + 1).formatGMT('MM/dd/yyyy');
        string testNameForSA = nameOfTrials + '-' + testNamePrefix; 
        //Changes for CR-2744679: added maxObjSize                                              
        return boundryValue 
                     + '\n' + constantText +'"appType"'     + '\n\n' + mTrialsSACustomSetting.get('SAAppType').value__c                 + '\n' + boundryValue 
                     + '\n' + constantText +'"xmlFile"'     + '\n\n' + requestXML                                                       + '\n' + boundryValue
                     + '\n' + constantText +'"testName"'    + '\n\n' + testNameForSA                                                    + '\n' + boundryValue
                     + '\n' + constantText +'"testType"'    + '\n\n' + mTrialsSACustomSetting.get('SATestType').value__c                + '\n' + boundryValue
                     + '\n' + constantText +'"masterAcgId"' + '\n\n' + mTrialsSACustomSetting.get('SAMasterAcgId').value__c             + '\n' + boundryValue 
                     + '\n' + constantText +'"active"'      + '\n\n' + '1'                                                              + '\n' + boundryValue 
                     + '\n' + constantText +'"group"'       + '\n\n' + mTrialsSACustomSetting.get('SA'+ groupName +'GroupId').value__c  + '\n' + boundryValue 
                     + '\n' + constantText +'"maxObjSize"'  + '\n\n' + mTrialsSACustomSetting.get('SAmaxObjSize').value__c              + '\n' + boundryValue 
                     + '\n' + constantText +'"frequency"'   + '\n\n' + mTrialsSACustomSetting.get('SAFrequency').value__c               + '\n' + boundryValue 
                     + '\n' + constantText +'"pagecheck"'   + '\n\n' + '0'                                                              + '\n' + boundryValue
                     + '\n' + constantText +'"expireDate"'  + '\n\n' + expiryDate                                                       + '\n' + boundryValue
                     +'--';
    }
    
    public static string createURLForReport(boolean isAkamaiXML, string testId, string recId, string additionalEmailAddress, string formName){
        string queryString;
        string recordId = recId;
        string salesforceEmailAddress = additionalEmailAddress + mTrialsSACustomSetting.get('SASalesforceEmailAddress').value__c;
        if(formName.length()>85){
            formName.substring(84);
        }
        queryString = '?emailReportName='   + recordId +':'+ formName + '&emailRcpt='      + salesforceEmailAddress 
                     +'&emailReportFormat=' + 'pdf'  + '&emailFrequency=' + 'D' 
                     +'&testIds='           + testId + '&appType='        +  mTrialsSACustomSetting.get('SAAppType').value__c
                     +'&useStartAsCreationDate=true';
        return queryString;
    }
        
    public static HttpResponse sendRequestToSA(string trialsReqFormId, string xmlToSend, string trialsReqFormName,
                                               boolean provisionTestReqSent, boolean instantCheckReqSent, boolean isAkamaiXML,
                                               string expireAfterDays, string groupName, string testNamePrefix){
       HttpRequest saRequest;
       string requestBody;
       Http http = new Http();
       saRequest = new HttpRequest();
       HttpResponse saResponse = new HttpResponse();
       string boundryValue = '------WebKitFormBoundarySm7nboJHI4QcZjiA';
       saRequest = setHeader(saRequest,provisionTestReqSent,instantCheckReqSent);
       if(instantCheckReqSent){
          // System.debug('Ready to call the createBodyForInstantCheck');       
           requestBody = createBodyForInstantCheck(xmlToSend,boundryValue,'13275',trialsReqFormId);
          //System.debug('createBodyForInstantCheck function returned');           
       }
       else if(provisionTestReqSent){
           requestBody = createBodyForProvisioning(xmlToSend,boundryValue,isAkamaiXML?'Akamai-'+ trialsReqFormName.substring(6) : 'Origin-'+ trialsReqFormName.substring(6),
                                                   expireAfterDays, groupName, testNamePrefix);
       }                                       
       saRequest.setBody(requestBody);
       //System.debug('Test Form: The whole body: '+ saRequest.getBody());
       //System.debug('Before sending the http request');
       saResponse = http.send(saRequest);
       //System.debug('Response received' + saResponse);
       return saResponse;
    }
    
    public static HttpResponse sendEmailRequestSA(string recId, string testId, boolean isAkamaiXML, 
                                                  string additionalEmails, string ownerEmailAddress,
                                                  string formName){
        string additionalEmailAddress = '';
        list<string> lAdditionalEmailAddress = new list<string>();
        
        if(additionalEmails != '' && additionalEmails != null){
            lAdditionalEmailAddress = additionalEmails.split('\n');
            for(integer i=0; i<lAdditionalEmailAddress.size(); i++){
                additionalEmailAddress = i==0? (lAdditionalEmailAddress[i]).trim() + ',' :  (additionalEmailAddress + lAdditionalEmailAddress[i]).trim() + ',';
            }
        }
        
        additionalEmailAddress = additionalEmailAddress + ownerEmailAddress + ',';
        HttpRequest saRequest;
        Http http = new Http();
        saRequest = new HttpRequest();
        string URL = mTrialsSACustomSetting.get('SAStagingEndPoint').value__c + 'email/dashboard/schedule' + createURLForReport(isAkamaiXML,testId,recId,additionalEmailAddress,formName);
        saRequest.setEndpoint(URL);
        String saAuthHeader_raw = mTrialsSACustomSetting.get('Base64TokenForSAProd').value__c;
        String saAuthHeaderFull = 'BASIC ' + saAuthHeader_raw;
        saRequest.setHeader('Authorization', saAuthHeaderFull);
        saRequest.setMethod('GET');
        saRequest.setTimeout(120000);
        saRequest.setHeader('X-ECWS-ManagedCustomer', mTrialsSACustomSetting.get('SAManagedCustomer').value__c);
        HttpResponse saResponse = new HttpResponse();
        saResponse = http.send(saRequest);
        return saResponse;
    }
    
    public static HttpResponse sendEditTestRequest(string trialsReqFormId, string xmlToSend, 
                                                   boolean isAkamaiXML, string trialsReqFormName,
                                                   string testIdForSA, string expireAfterDays, string groupName,
                                                   string testNamePrefix){
        HttpRequest saRequest;
        string requestBody;
        Http http = new Http();
        saRequest = new HttpRequest();
        HttpResponse saResponse = new HttpResponse();
        string boundryValue = '------WebKitFormBoundarySm7nboJHI4QcZjiA';
        saRequest = setHeader(saRequest,true,false);
        saRequest.setEndpoint(mTrialsSACustomSetting.get('SAStagingEndPoint').value__c + 'provision/edittest');
        requestBody = createBodyForProvisioning(xmlToSend,boundryValue,isAkamaiXML?'Akamai-'+ trialsReqFormName.substring(6) : 'Origin-'+ trialsReqFormName.substring(6),
                                                expireAfterDays,groupName,testNamePrefix);  
        requestBody = requestBody.substring(0, requestBody.length()-2)
                      + '\n' + 'Content-Disposition: form-data; name=' +'"testId"'   + '\n\n' + testIdForSA +'\n' + boundryValue
                      + '--';                                            
        saRequest.setBody(requestBody);
        saResponse = http.send(saRequest);                                       
        return saResponse;                                               
    }
    
    public static HttpResponse deleteTestFromSA(string testId){
        HttpRequest saRequest;
        Http http = new Http();
        saRequest = new HttpRequest();
        string URL = mTrialsSACustomSetting.get('SAStagingEndPoint').value__c + 'provision/deletetest?appType=' 
                   + mTrialsSACustomSetting.get('SAAppType').value__c         + '&testId=' + testId;
        saRequest.setEndpoint(URL);
        String saAuthHeader_raw = mTrialsSACustomSetting.get('Base64TokenForSAProd').value__c;
        String saAuthHeaderFull = 'BASIC ' + saAuthHeader_raw;
        saRequest.setHeader('Authorization', saAuthHeaderFull);
        saRequest.setMethod('GET');
        saRequest.setHeader('X-ECWS-ManagedCustomer', mTrialsSACustomSetting.get('SAManagedCustomer').value__c);
        saRequest.setTimeout(120000);
        HttpResponse saResponse = new HttpResponse();
        saResponse = http.send(saRequest);
        return saResponse;
    }
    
    public static string convertIntToBinary(string intToConvert){
        integer numberAfterMod = integer.valueOf(intToConvert);
        string binaryString = '';
        string eightBitBinaryValue;
        
        while(numberAfterMod > 1){
            binaryString =  string.valueOf(Math.mod(numberAfterMod, 2)) + binaryString;
            numberAfterMod = (Integer)Math.floor((Double)numberAfterMod/2);
        }
        
        if(numberAfterMod == 1){
            binaryString = '1' + binaryString;
        }
        
        eightBitBinaryValue = binaryString;
        
        for(integer i = binaryString.length(); i<16; i++){
            eightBitBinaryValue = '0' + eightBitBinaryValue;
        }
        return eightBitBinaryValue;
    }
    
    @future(callout=true)
    public static void doInstantCheck(string trialsReqFormId){
        
        Trials_Request_Form__c trialsReqForm = [SELECT Id,Trails_Akamai_Instant_Check_Status_Code__c,Trials_Akamai_Instant_Check_Status_Messa__c, Owner.Email,
                                                Trials_Origin_Instant_Check_Status_Code__c,Trials_Origin_Instant_Check_Status_Messa__c, Trials_JSON_Received_For_Akamai_XML__c,
                                                Trials_Provisioned_Trails_Back_Date__c, Trials_JSON_Received_For_Origin_XML__c,Name,TrialsTestNamePrefix__c 
                                                FROM Trials_Request_Form__c WHERE Id = :trialsReqFormId][0];
            
        HttpResponse responseReceived = new HttpResponse();
        for(Trials_XML__c objTriXML: [SELECT Id,Trials_Generated_XML__c,Trials_Akamai_XML__c,Trials_Location_of_Test_Agents__c,
                                      Trials_Frequency_for_Running_Test__c,Trials_Request_Form__r.Name, Trials_Request_Form__r.TrialsTestNamePrefix__c 
                                      FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqFormId]){
           
         //  System.debug('Ready to call the sendRequestToSA');
           responseReceived = TrialsUtilClass.sendRequestToSA(objTriXML.Id,objTriXML.Trials_Generated_XML__c,
                                                              objTriXML.Trials_Request_Form__r.Name,false,true,
                                                              objTriXML.Trials_Akamai_XML__c,objTriXML.Trials_Frequency_for_Running_Test__c,
                                                              objTriXML.Trials_Location_of_Test_Agents__c,objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c  );
         //  System.debug('sendRequestToSA function successfully called');                                                              
           if(objTriXML.Trials_Akamai_XML__c){
               trialsReqForm.Trails_Akamai_Instant_Check_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
               trialsReqForm.Trials_Akamai_Instant_Check_Status_Messa__c = String.valueOf(responseReceived.getStatus());
           } 
                                          
           else{
               trialsReqForm.Trials_Origin_Instant_Check_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
               trialsReqForm.Trials_Origin_Instant_Check_Status_Messa__c = String.valueOf(responseReceived.getStatus());
           }
        }
        if(!(responseReceived.getStatusCode() == 200)){
            System.debug('####' + responseReceived.getStatusCode());
            Messaging.SingleEmailMessage messageForTrials = new Messaging.SingleEmailMessage();
            messageForTrials.setSaveAsActivity(false);
            messageForTrials.setSubject(trialsReqForm.Name + ': Instant Check Service Down'); 
            messageForTrials.setPlainTextBody('Hi, /n Instant check service is temporarily down.' +
                                               'Please reach out to perf-eval-help@akamai.com. \n\n Regards, \n Trials Team');
            messageForTrials.setToAddresses(new List<String>{trialsReqForm.Owner.Email});
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { messageForTrials });
        }
        update trialsReqForm;
    }
   
    @future(callout=true)
    public static void provisionTest(string trialsReqFormId){
        for(integer i=0; i<30000; i++){
        }
        
        Trials_Request_Form__c trialsReqForm = [SELECT Id,Akamai_Provisioning_Status_Code__c,Akamai_Provisioning_Status_Message__c,Trials_Akamai_Provisioned_Test_Id__c,OwnerId,
                                                Trials_Akamai_Test_Name__c,Origin_Provisioning_Status_Code__c,Origin_Provisioning_Status_Message__c, Trials_Test_Duration_In_Days__c,
                                                Trials_JSON_Received_For_Akamai_XML__c , Trials_Origin_Test_Name__c, Trials_Provisioned_Trails__c,Trials_Akamai_Provisioning_Error_Message__c,
                                                Origin_Binary_Response__c,Trials_Akamai_Binary_Response__c,Trials_Additional_Email_Addresses__c,Trials_Email_Provisioned__c, Name,
                                                Trials_Origin_Provisioned_Test_Id__c,Trials_JSON_Received_For_Origin_XML__c,Trials_Akamai_Email_Error_Message__c,TrialsTestNamePrefix__c, 
                                                Owner.Email,Trials_Trials_Request_Name__c FROM Trials_Request_Form__c WHERE Id = :trialsReqFormId][0];
        if(trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c == null)
        trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c = '';     
        
        if(trialsReqForm.Trials_JSON_Received_For_Origin_XML__c && trialsReqForm.Trials_Akamai_Binary_Response__c != null &&
           trialsReqForm.Trials_JSON_Received_For_Akamai_XML__c && trialsReqForm.Origin_Binary_Response__c != null &&
           trialsReqForm.Trials_Akamai_Binary_Response__c.substring(15) != '1' && trialsReqForm.Origin_Binary_Response__c.substring(15) != '1'){
            HttpResponse responseReceived = new HttpResponse();
            HttpResponse emailConfigureResponse = new HttpResponse();
            ResponseForAddingTest responseProvisioning;
            JSONParser parser;
            list<Trials_Request_Form__c> lTRFToUpdate = new list<Trials_Request_Form__c>();
            
            for(Trials_XML__c objTriXML: [SELECT Id,Trials_Generated_XML__c,Trials_Akamai_XML__c,Trials_Request_Form__r.Name, Trials_Test_Duration_In_Days__c,
                                          Trials_Location_of_Test_Agents__c,Trials_Frequency_for_Running_Test__c,Trials_Request_Form__r.TrialsTestNamePrefix__c
                                          FROM Trials_XML__c WHERE Trials_Request_Form__c = :trialsReqFormId]){
               
               if((trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c==NULL && objTriXML.Trials_Akamai_XML__c) ||
                  (trialsReqForm.Trials_Origin_Provisioned_Test_Id__c==NULL && !objTriXML.Trials_Akamai_XML__c)){                          
                       responseReceived=TrialsUtilClass.sendRequestToSA(objTriXML.Id,objTriXML.Trials_Generated_XML__c,
                                                                        objTriXML.Trials_Request_Form__r.Name,true,false,objTriXML.Trials_Akamai_XML__c,
                                                                        objTriXML.Trials_Test_Duration_In_Days__c,objTriXML.Trials_Location_of_Test_Agents__c,
                                                                        objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c);
                       parser = JSON.createParser(responseReceived.getBody());
                       responseProvisioning = (ResponseForAddingTest)parser.readValueAs(ResponseForAddingTest.class);
                   
               }
               
               else{
                   responseReceived=TrialsUtilClass.sendEditTestRequest(objTriXML.Id, objTriXML.Trials_Generated_XML__c, 
                                                   objTriXML.Trials_Akamai_XML__c, objTriXML.Trials_Request_Form__r.Name,
                                                   objTriXML.Trials_Akamai_XML__c ? trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c:trialsReqForm.Trials_Origin_Provisioned_Test_Id__c,
                                                   objTriXML.Trials_Test_Duration_In_Days__c,objTriXML.Trials_Location_of_Test_Agents__c,objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c);
                   parser = JSON.createParser(responseReceived.getBody());
                   responseProvisioning = (ResponseForAddingTest)parser.readValueAs(ResponseForAddingTest.class);
                   if(objTriXML.Trials_Akamai_XML__c){
                       if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                           if(responseProvisioning.success!= NULL && responseProvisioning.success){
                               trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Success:: '+
                                                                                       'Akamai test is Edited Successfully and Test Id is '  + responseProvisioning.data + '\n';
                           }
                           
                           else if(responseProvisioning.success!= NULL){
                               trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Success:: '+
                                                                                       'Akamai test edit: '  + responseProvisioning.message + '\n';
                           }
                       }
                       
                       else{
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Error::' + 'Akamai Test Edit: '  +'Error in Web Service Call.'+ '\n';
                       }
                   }
                   
                   else if(!objTriXML.Trials_Akamai_XML__c){
                       if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                           if(responseProvisioning.success!= NULL && responseProvisioning.success){
                               trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Success:: '+
                                                                                       'Origin test is Edited Successfully and Test Id is '  + responseProvisioning.data + '\n';
                           }
                           
                           else if(responseProvisioning.success!= NULL){
                               trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Error:: '+
                                                                                       'Origin test edit: '  + responseProvisioning.message + '\n';
                           }
                       }
                       
                       else{
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Error::' + 'Origin Test Edit: '  +'Error in Web Service Call.'+ '\n';
                       }
                   }
               }
               
                                              
               if(objTriXML.Trials_Akamai_XML__c && trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c==NULL){
                   trialsReqForm.Akamai_Provisioning_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
                   trialsReqForm.Akamai_Provisioning_Status_Message__c = String.valueOf(responseReceived.getStatus());
                   
                   if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                       if(responseProvisioning.success!= NULL && responseProvisioning.success){
                           trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c = responseProvisioning.data;
                           trialsReqForm.Trials_Akamai_Test_Name__c = 'Akamai-' + objTriXML.Trials_Request_Form__r.Name.substring(6) + '-' + objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c;
                           trialsReqForm.Trials_Provisioned_Trails__c = true;
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Success:: '+
                                                                                       'Akamai test is Provisioned Successfully and Test Id is '  + responseProvisioning.data + '\n';
                           
                       }
                       
                       else if(responseProvisioning != null){
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + 
                                                                                       '::Error::' + 'Akamai Test: '  + responseProvisioning.message + '\n';
                       }
                       
                   }
                    
                    else{
                         trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Error::' + 'Akamai Test: '  +'Error in Web Service Call.'+ '\n';
                    }
                    lTRFToUpdate.add(trialsReqForm);
                   } 
                   else if(!objTriXML.Trials_Akamai_XML__c && trialsReqForm.Trials_Origin_Provisioned_Test_Id__c==NULL){
                       
                       trialsReqForm.Origin_Provisioning_Status_Code__c = String.valueOf(responseReceived.getStatusCode());
                       trialsReqForm.Origin_Provisioning_Status_Message__c = String.valueOf(responseReceived.getStatus());
                       if(responseReceived.getStatusCode() == 200 && responseReceived.getStatus()== 'OK'){
                           if(responseProvisioning!= null && responseProvisioning.success != null && responseProvisioning.success){
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + '::Success:: '+
                                                                                       'Origin test is Provisioned Successfully and Test Id is '  + responseProvisioning.data + '\n';
                           trialsReqForm.Trials_Origin_Provisioned_Test_Id__c = responseProvisioning.data;
                           trialsReqForm.Trials_Origin_Test_Name__c = 'Origin-' + objTriXML.Trials_Request_Form__r.Name.substring(6) + '-' + objTriXML.Trials_Request_Form__r.TrialsTestNamePrefix__c;
                           trialsReqForm.Trials_Provisioned_Trails__c = true;
                           
                       }
                       
                       else{
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c + 
                                                                                       '::Error::' + 'Origin Test: '  + responseProvisioning.message + '\n';
                       }
                          
                   }
                   else{
                       trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Error::' + 'Origin Test: '  +'Error in Web Service Call.'+ '\n';
                    }    
                   lTRFToUpdate.add(trialsReqForm);
                }
            }
            
            if(trialsReqForm.Trials_Origin_Provisioned_Test_Id__c != null && 
               trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c != null && 
               !trialsReqForm.Trials_Email_Provisioned__c){
                   emailConfigureResponse = TrialsUtilClass.sendEmailRequestSA(trialsReqForm.Name,trialsReqForm.Trials_Origin_Provisioned_Test_Id__c+','+
                                                                               trialsReqForm.Trials_Akamai_Provisioned_Test_Id__c,false,
                                                                               trialsReqForm.Trials_Additional_Email_Addresses__c, trialsReqForm.Owner.Email,
                                                                               trialsReqForm.TrialsTestNamePrefix__c);
                   JSONParser parserEmail = JSON.createParser(emailConfigureResponse.getBody());
                   ResponseForAddingTest emailResponse = (ResponseForAddingTest)parserEmail.readValueAs(ResponseForAddingTest.class);
                   if(emailConfigureResponse.getStatusCode()==200 && emailConfigureResponse.getStatus()=='OK'){
                       trialsReqForm.Trials_Email_Provisioned__c = true;
                       if(emailResponse.success!=NULL && emailResponse.success){
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Success::' + 'Email: '  + emailResponse.message + '\n';
                                   //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Origin report: ' + emailResponse.message));
                       }
                       else{
                           trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::Error::' + 'Email: '  + emailResponse.message + '\n';
                                   //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Origin Email: ' + emailResponse.message));
                       }
                   }
                           
                   else{
                       trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c =  trialsReqForm.Trials_Akamai_Provisioning_Error_Message__c +
                                                                                       '::ERROR::' + 'Email: '  + 'Error in Provision Email Service' + '\n';
                   }
            }
            
            update trialsReqForm;
    
        }
        map<string,string> mEmailTemplateNameId = new map<string,string>();
        for(EmailTemplate varEmailTemp :[SELECT ID,Name FROM EmailTemplate WHERE Name = 'Trials Email Template Failure' OR Name = 'Trials Email Template Success']){
            mEmailTemplateNameId.put(varEmailTemp.Name,varEmailTemp.Id);
        }
        if((trialsReqForm.Trials_Akamai_Binary_Response__c != null && trialsReqForm.Trials_Akamai_Binary_Response__c.substring(15) == '1') ||
                 trialsReqForm.Origin_Binary_Response__c != null && trialsReqForm.Origin_Binary_Response__c.substring(15) == '1'){
                Messaging.Singleemailmessage email = new Messaging.SingleEmailMessage();
                email.setWhatId(trialsReqForm.Id);
                email.setTargetObjectId(trialsReqForm.OwnerId);
                email.setTemplateId(mEmailTemplateNameId.get('Trials Email Template Failure'));
                email.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    
        }
        
        if((trialsReqForm.Trials_Akamai_Binary_Response__c != null && trialsReqForm.Trials_Akamai_Binary_Response__c.substring(15) == '0') &&
                 trialsReqForm.Origin_Binary_Response__c != null && trialsReqForm.Origin_Binary_Response__c.substring(15) == '0'){
                Messaging.Singleemailmessage email = new Messaging.SingleEmailMessage();
                email.setWhatId(trialsReqForm.Id);
                email.setTargetObjectId(trialsReqForm.OwnerId);
                email.setTemplateId(mEmailTemplateNameId.get('Trials Email Template Success'));
                email.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    
        }
    }
    
        public class ResponseForAddingTest{
        public string message{get;set;}
        public boolean success{get;set;}
        public string data{get;set;}
        public string error{get;set;}
    }
}
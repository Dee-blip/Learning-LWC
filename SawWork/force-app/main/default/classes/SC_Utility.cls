/*=====================================================================================================+
    Class name                :   SC_Utility 
    Purpose                   :   Reusable methods should go in this class
    Test class 				  :   SC_Case_Trgr_EmlServc_Class_TC
    
   Last Modified  Developer     Purpose            
   =============  =========     ======= 
   24-Aug-2015      Jay         CR:3127251 : Bug fixes for date issue. added GMT fix
   12-Nov-15        Himanshu    CR:3151921 : Added Method "ImageConverter" for Image Synching to Jive
   12-Nov-15        Jay         CR:3212571 : Day light savings issue
   27-Apr-15        Vamsee      CR:3172971 : Modified getShiftDateTime function to skip saturday and sunday
                                             for non weekend shifts.
   27-Apr-17        Pinkesh     ESESP-542  : Added case transition feature for BOCC
   30-Jan-18        Vamsee      ESESP-571  : Added DST Check for EMEA
   05-Jun-18        Vamsee      ESESP-1101 : Added ProcessSaveResult method
   20-Jun-19        Vamsee      ESESP-2306 : Added sendExceptionEmail method
   01-Jul-19      	Vishnu      ESESP-758: Convenience methods for AMG SLA improvements
                                    - filterSObjList - applies filters to list of sobjet and returns filtered list
                                    - isSobjAMatch - checks if a sobject matches filter conditions or not
   24-May-20	 	Vamsee		ESESP-3567	 	Removed case transition feature for BOCC (BOCC is Migrating to Technical)
   31-May-22		Saiyam		ESESP-5957 : Added Case transition feature for BOCC
+=====================================================================================================*/  
    
public class SC_Utility {
    
    /* current time is taken and shift applicabe is returned.
     * Possible Values
     *  1.APAC
     *  2.EMEA
     *  3.US EAST
     *  4.US WEST
     //changes by Saiyam for ESESP-5957 - BOCC case transition.
     *  5.Americas - 1
     *  6.Americas - 2
     *  7.APJ
     */
     
    
    // Method - 1 
    //changes by Saiyam for ESESP-5957 - BOCC case transition.
    public static String getCurrentShiftDetails(String recordTypeName){
        Map<string,decimal> hourShiftMap = getRegularShiftTimes(recordTypeName);
        DateTime currentDateTime = (DateTime) datetime.now();
        decimal currentHour = currentDateTime.hourGmt();
        currentHour = currentHour + currentDateTime.minuteGmt()/60.0;
        decimal differenceInHours = 10000000;
        String currentShift = null;
        if(recordTypeName == 'Akatec' && (currentDateTime.format('EEEE') == 'Saturday' || currentDateTime.format('EEEE') == 'Sunday'))
            currentShift = 'Weekend';
        else if(recordTypeName == 'BOCC' && currentHour>=0.5 && currentHour<12.5 && (currentDateTime.format('EEEE') == 'Saturday' || currentDateTime.format('EEEE') == 'Sunday'))
            currentShift = 'Weekend APAC/EMEA';
        else if(recordTypeName == 'BOCC' && ((currentHour>=12.5 && (currentDateTime.format('EEEE') == 'Saturday' || currentDateTime.format('EEEE') == 'Sunday')) || (currentHour<0.5 && (currentDateTime.format('EEEE') == 'Sunday' || currentDateTime.format('EEEE') == 'Monday')) ))
            currentShift = 'Weekend America'; 
        else
            {//loop through and tell me which shift I am in now
                for(String g:hourShiftMap.keyset()){
                    decimal hh = hourShiftMap.get(g);
                    if(currentHour - hh  < differenceInHours && currentHour >= hh ){
                        differenceInHours = currentHour - hh;
                        currentShift = g;
                    }
                }
            }
        if (currentShift == null){
            //this might happen when zero hours
            if(recordTypeName == 'Akatec')
                currentShift = 'US West';
            else if(recordTypeName == 'BOCC')
                currentShift = 'Americas - 2';
        }
        return currentShift;
    }
    
    // Method - 2
    //changes by Saiyam for ESESP-5957 - BOCC case transition.
    public static map<String,decimal> getRegularShiftTimes(String recordTypeName){
        Map<string,decimal> hourShiftMap = new Map<string,decimal>();
        boolean isUSA_DST_On = isUSADayLightSavingsOn();
        boolean isEMEA_DST_On = isEMEADayLightSavingsOn();
        Decimal result;
        
        if(recordTypeName == 'Akatec'){
            hourShiftMap.put('APAC',0.5);
            //USA DST Check
            result = isUSA_DST_On ? hourShiftMap.put('US East',13) : hourShiftMap.put('US East',14);
            result = isUSA_DST_On ? hourShiftMap.put('US West',17) : hourShiftMap.put('US West',18);
            
            //EMEA DST Check
            result = isEMEA_DST_On ? hourShiftMap.put('EMEA',7) : hourShiftMap.put('EMEA',8);
        }
        else if(recordTypeName == 'BOCC'){
            hourShiftMap.put('APJ',0.5);
            //USA DST Check
            result = isUSA_DST_On ? hourShiftMap.put('Americas - 1',12.5) : hourShiftMap.put('Americas - 1',13.5);
            result = isUSA_DST_On ? hourShiftMap.put('Americas - 2',18.5) : hourShiftMap.put('Americas - 2',19.5);  
            
            //EMEA DST Check
            result = isEMEA_DST_On ? hourShiftMap.put('EMEA',6.5) : hourShiftMap.put('EMEA',7.5);
            
        }
        return hourShiftMap;
    }
    
   /* public static String getNextShift(string currentShift){
        if (currentShift != null){
            Map<string,string> hourShiftMap = new Map<string,string>();
            hourShiftMap.put('APAC','EMEA');
            hourShiftMap.put('EMEA','US East');
            hourShiftMap.put('US East','US West');
            hourShiftMap.put('US West','APAC');
            return hourShiftMap.get(currentShift);
        }    
        return null;
    }
    */
    
    // Method - 3
    //changes by Saiyam for ESESP-5957 - BOCC case transition.
    public static DateTime getShiftDateTime(String shiftName, String recordTypeName){
        boolean isUSA_DST_On = isUSADayLightSavingsOn();
        boolean isEMEA_DST_On = isEMEADayLightSavingsOn();
        Decimal result;
        
        Map<string,decimal> hourShiftMap = new Map<string,decimal>();
        hourShiftMap = getRegularShiftTimes(recordTypeName);
        
        //DST Check
        result = isEMEA_DST_On ? hourShiftMap.put('Weekend APAC/EMEA',0.5) : hourShiftMap.put('Weekend APAC/EMEA',1.5);
        result = isUSA_DST_On ? hourShiftMap.put('Weekend America',12.5) : hourShiftMap.put('Weekend America',13.5);
        
        hourShiftMap.put('Weekend',13);
        DateTime currentDateTime = (DateTime) datetime.now();
        decimal currentHour = currentDateTime.hourGmt();
        currentHour = currentHour + currentDateTime.minuteGmt()/60.0;
        String dayOfWeek = currentDateTime.formatGmt('EEEE');
        decimal shiftTime = hourShiftMap.get(shiftName);
        Integer minutes = 0;
        String stringReprentationOfDecimal= String.valueOf(shiftTime);
        if(stringReprentationOfDecimal.indexOf('.') > -1){
            String decimalValueAfterDot = stringReprentationOfDecimal.substring(stringReprentationOfDecimal.indexOf('.'),stringReprentationOfDecimal.length());
            decimal minutsDecimal = decimal.valueof(decimalValueAfterDot)*60;
            minutes = minutsDecimal.intValue();
        }
        if(shiftname != 'Weekend' && shiftname != 'Weekend APAC/EMEA' && shiftname != 'Weekend America'){
            Datetime myDate;
            if (shiftTime > currentHour){
                //target date is greater than current date. return todays date only
                Datetime d =  datetime.now();
                //shift time might have minutes. so set minutes also
                myDate = Datetime.newInstanceGMT(d.yearGMT(), d.monthGMT(), d.dayGMT(), shiftTime.intValue(), minutes, 0);
                //return myDate;
                
            }
            else {
                //looks like shift was over. tomo shift details
                 Datetime d =  datetime.now();
                 d = d.addDays(1);
                 myDate = Datetime.newInstanceGMT(d.yearGMT(), d.monthGMT(), d.dayGMT(), shiftTime.intValue(), minutes, 0);
                 //return myDate;
            }
            //Changes done by Vamsee - This is to skip the week ends
            String targetDay = myDate.formatGmt('EEEE');
            if(targetDay == 'Saturday'){
                myDate = myDate.addDays(2);
            }
            else if(targetDay == 'Sunday'){
                myDate = myDate.addDays(1);
            }
            return myDate;
            //Changes Ends here
        }
        else {
            //saturday always 0 GMT
            if(currentDateTime.format('EEEE') == 'Saturday' || currentDateTime.format('EEEE') == 'Sunday'){
                Datetime myDate = Datetime.newInstanceGMT(currentDateTime.yearGMT(), currentDateTime.monthGMT(), currentDateTime.dayGMT(), 0, 0, 0);
                Integer noOfDays;
                if(currentDateTime.format('EEEE') == 'Saturday')
                    noOfDays = 1;
                else
                    noOfDays = 6;
                if(recordTypeName == 'Akatec'){
                    myDate = myDate.addDays(noOfDays);
                    myDate = myDate.addHours((Integer)hourShiftMap.get(shiftname));
                }
                else if(recordTypeName == 'BOCC'){
                    myDate = myDate.addHours((Integer)hourShiftMap.get(shiftname));
                    myDate = myDate.addMinutes(minutes); //changes by Saiyam for ESESP-5957 - BOCC case transition - to add minutes to the wakeup time.
                    if((currentHour >= 1.5 && shiftname == 'Weekend APAC/EMEA') || (currentHour >= 13.5 && shiftname == 'Weekend America')) {
                        myDate = myDate.addDays(noOfDays);
                    }
                }
                //myDate = myDate.addHours((Integer)hourShiftMap.get(shiftname));
                return myDate;
            }
            else{
                Datetime d = getNextSaturday();
                Datetime myDate = Datetime.newInstanceGMT(d.yearGMT(), d.monthGMT(), d.dayGMT(), 0, 0, 0);
                myDate = myDate.addHours((Integer)hourShiftMap.get(shiftname));
                myDate = myDate.addMinutes(minutes); //changes by Saiyam for ESESP-5957 - BOCC case transition - to add minutes to the wakeup time.
                return myDate;
            }
        }
        //return null;
    }
    
    // Method - 4
    /* gives saturday date when executed. considers current time.
     * if currrent day is monday , then date returned will be 5 days later */
    public static DateTime getNextSaturday(){
        map<String,integer> differenceToSaturday = new Map<String,integer>();
        differenceToSaturday.put('Friday',1);
        differenceToSaturday.put('Thursday',2);
        differenceToSaturday.put('Wednesday',3);
        differenceToSaturday.put('Tuesday',4);
        differenceToSaturday.put('Monday',5);
        differenceToSaturday.put('Saturday',7);
        differenceToSaturday.put('Sunday',6);
        DateTime currentDateTime = (DateTime) datetime.now();
        String dayOfWeek = currentDateTime.formatGmt('EEEE');
        Integer addDaysToSaturday = differenceToSaturday.get(dayOfWeek);
        DateTime newDateReturn = currentDateTime.addDays(addDaysToSaturday);
        return newDateReturn;
    }
    
    // Method - 5 : This method check whether USA DST is on
    public static boolean isUSADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('America/New_York');
        DateTime d = datetime.now();
        return tz.getOffset(d) != -18000000; //GMT -5 Hours
    } 
    
    // Method - 6 : This method check whether EMEA DST is on
    public static boolean isEMEADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('Europe/Amsterdam');
        DateTime d = datetime.now();
        return tz.getOffset(d) != 3600000; // GMT +1 Hour
    } 
    
    // Method - 7 - For Converting Image URL to Actual Image Data
    public static string ImageConverter(string result){
        
        // Pattern and Matcher 
        Pattern myPattern = Pattern.compile('<\\s*img\\s+([^>]*)src\\s*=\\s*\"([^\"]+)\"');
        Matcher myMatcher = myPattern.matcher(result);
        
        Try{
        	// Loop for each Image URL
            While(myMatcher.find()){ 
                String imageStr = myMatcher.group();
                integer srcIndex = imageStr.indexOf('src') + 3;
                string imageURL = imageStr.substring(srcIndex);
                imageURL = imageURL.replaceFirst('=', '').replace('\"', '').trim();
                string sfImageURL = imageURL.replace('&amp;', '&');
                
                // For getting the Content of the Image URL
                PageReference ref = new PageReference(sfImageURL);
                if(!Test.isRunningTest()){
                    string imageContent = 'data:image/png;base64,' + EncodingUtil.base64Encode(ref.getContent());
                    result = result.replace(imageURL,imageContent);
                }
            }
        
    	}
        Catch(Exception e){
           result = e.getMessage();
            system.debug('--result--'+result);
            
        }
        return result; 
    }
    
    //This method will process the Saveresult and send out email to sc-dev
    public static void processSaveResult(List<Database.SaveResult> saveResultList, List<Id> idList){
        string Result = '';
        for(Integer i =0; i<idList.size(); i++){
            if(!saveResultList[i].isSuccess()){
                Result = Result + 'Record URL: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + idList[i] +'\n';
                Result = Result + 'Error: ' + saveResultList[i].getErrors() + '\n\n';
            }
        }
        if(String.isNotBlank(Result)){
            String toAddresses = [SELECT Value__c FROM SC_Utility__mdt WHERE DeveloperName = 'Case_Transition_Exception_Emails' LIMIT 1].Value__c;
            String[] toAdd = toAddresses.split(',');
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAdd);
            mail.subject = 'Exception: In Case Transition Future Method';
            mail.plainTextBody = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                            'Class Name = SC_CaseTransitionControllerV2\n' + 
                            'Method Name = updateCaseAsync\n\n' + Result; 
            
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }

    
    //Method Used to send Exception Emails to sc-dev@akamai.com
    Public Static void sendExceptionEmail(String subject, String Body){
        //Get the two address
        sc_utility__mdt utilitySettings = [Select Value__c from sc_utility__mdt where DeveloperName = 'General_Exception_Email'];
        String[] toAdd = new String[] {};
        toAdd.add(utilitySettings.Value__c);
            
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = subject;
        mail.plainTextBody = Body;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }
    
    
    // Convenience method created for ESESP-758, to Filter SObject List
    public static List<SObject> filterSObjList(List<SObject> lSobj, Map<String, Object> filters) {
        List<SObject> filteredList = new List<SObject>();
        // validate each element in list against filter conditions
        for(SObject so: lSobj) {
            if(isSobjAMatch(so, filters)) {
                filteredList.add(so);
            }
        }
        return filteredList;
    }
    
    // validate - if sobj satisfies filter conditions
    public static boolean isSobjAMatch(SObject sobj, Map<String, Object> filters) {
        Boolean isMatch = true;
        for(String fld: filters.keySet()) {
            if(sobj.get(fld) != filters.get(fld)) {
                isMatch = false;
                break;
            }
        }
        return isMatch;
    }
    
    // FFPSA-1633: Bhavesh: Creating offboarding case
    public static Case createOffboardingCase(String type, pse__Proj__c proj, Id contractId, Boolean insertCase) {
        String errMsg = '';
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Case cs = new Case();
        cs.pse_Project__c = proj.Id;
        cs.RecordTypeId = recordTypeId;
        cs.AccountId = proj.pse__Account__c;//Project Contract Line Item.OriginalContractID.Account
        cs.OwnerId = proj.pse__Project_Manager__r.pse__Salesforce_User__c;//Project.Project Manager
        cs.Contract__c = contractId;
        cs.Origin = 'Autogen';
        cs.Request_Type__c = 'Customer offboarding';
        cs.Severity__c = '3';
        cs.Status = 'Assigned';
        cs.Do_Not_Show_In_Portal__c = True;
        
        if( type.toUpperCase() == 'SOA') {
            cs.Subject = proj.pse__Account__r.Name+'- SOA - Contract about to expire';
            cs.Service__c = 'Security Optimization Assistance';
            cs.Description = 'Customer’s Security Optimization Assistance entitlement has either ended or will be ending soon, no renewal can be found on the contract. Please review customer\'s contract and either initiate renewal process or customer offboarding.';
        } else if( type.toUpperCase() == 'PLUS'){
            cs.Subject = proj.pse__Account__r.Name+'- PLUS - Contract about to expire';
            cs.Service__c = 'Plus Service and Support';
            cs.Description = 'Customer’s Plus Service and Support entitlement has either ended or will be ending soon, no renewal can be found on the contract. Please review customer\'s contract and either initiate renewal process or customer offboarding.';
        }
        cs.Autogen_UseCase__c = type;
        if(insertCase){
            try{
                insert cs;
            } Catch(Exception e){
                errMsg = e.getMessage();
            }
        }
        
        //return errMsg == ''?''+cs.Id:errMsg;
        return cs;
    }
}
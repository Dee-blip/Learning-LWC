/**
|  HISTORY  |   

|  BASE CLASS: GSS_Autogen_Class

|  TEST CLASS: GSS_Autogen_Test

|  DATE             DEVELOPER       JIRA            DESCRIPTION                               

|  ===========      =========       =======         =========== 

|  08-Feb-2021      Sandeep        FFPSA-1769     Util Class for GSS_Autogen_Class

**/
public class GSS_Autogen_Util {    
        
    /*Update the existing case based on Billing duration match*/
    public static Set<Case> updateCaseDescription(Map<Case,String> caseMatchMap){

        Map<String,Case> mapOfDuplicateCaseParamToUniqueCase = new Map<String,Case>();//Added this map to store multiple descriptions if there are duplicate values in caseMatchMap
        
        Set<Case> updatedCaseSet = new Set<Case>();
        for(Case eachCase : caseMatchMap.keySet()){

            String keyVal = eachCase.AccountId+'~'+eachCase.Contract__c+'~'+eachCase.Service__c+'~'+eachCase.Request_Type__c+'~'+eachCase.Severity__c+'~'+eachCase.RecordTypeId+'~'+eachCase.Subject+'~'+eachCase.Sub_Type__c;
            String caseDescription = '';
            if(mapOfDuplicateCaseParamToUniqueCase.containsKey(keyVal)){
                //eachCase.Description = mapOfDuplicateCaseParamToUniqueCase.get(keyVal).Description+' '+caseMatchMap.get(eachCase);
                caseDescription = mapOfDuplicateCaseParamToUniqueCase.get(keyVal).Description+' '+caseMatchMap.get(eachCase);
            }
            else{
                //eachCase.Description = eachCase.Description+' '+caseMatchMap.get(eachCase);
                caseDescription = eachCase.Description+' '+caseMatchMap.get(eachCase);
            }
            if(caseDescription.length() > 30000){
                if(!caseDescription.contains('CHARACTER LIMIT REACHED'))
                    eachCase.Description = caseDescription+'CHARACTER LIMIT REACHED';                                
            }
            else{
                eachCase.Description = caseDescription;
            }
            mapOfDuplicateCaseParamToUniqueCase.put(keyVal,eachCase);//this will always have the most updated case for each unique key pair

            //updatedCaseSet.add(eachCase);
        }
        updatedCaseSet.addAll(mapOfDuplicateCaseParamToUniqueCase.values());
        return updatedCaseSet;
    }
    
    public static Map<String,Id> getRegionNameToIdMap(List<Autogen_Contract_Header_Detail__c> achdsForProjectsList)
    {
        Set<String> regionNamesSet = new Set<String>();        
        
        for(Autogen_Contract_Header_Detail__c eachACHD : achdsForProjectsList){
            // regionNamesSet.add(eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.Area__c + ' (Territory)');      
            regionNamesSet.add(eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)');      
        }
        
        Map<String,Id> regionNameToIdMap = new Map<String,Id>();
        if(regionNamesSet.size() > 0){
            for(pse__Region__c region : [
                SELECT id, Name
                FROM pse__Region__c
                WHERE Name in :regionNamesSet
            ]){
                regionNameToIdMap.put(region.Name,region.Id);
            }
        }        
        return regionNameToIdMap;        
    }        
  
    public static Double calculatePlannedHours(GSS_Autogen__c eachAutogen,Autogen_Contract_Header_Detail__c achd)
    {
                                        
        Double plannedHours = 0;
        Integer isNormalQuarterlyHoursProject;
        if(eachAutogen.IS_Normal_Quarterly_Hours_Project__c != NULL && eachAutogen.IS_Normal_Quarterly_Hours_Project__c){
            isNormalQuarterlyHoursProject = 1;
        }
        else{
            isNormalQuarterlyHoursProject = 0;
        }        
        
        Decimal fixedHoursPerMonth = eachAutogen.Fixed_Hours_Per_Month__c != NULL ? eachAutogen.Fixed_Hours_Per_Month__c : 0;
        Decimal fixedHoursPerQuarter = eachAutogen.Fixed_Hours_Per_Quarter__c != NULL ? eachAutogen.Fixed_Hours_Per_Quarter__c : 0;
        Decimal unitsLow = achd.Parent_Contract_Detail__r.Units_Low__c != NULL  ? achd.Parent_Contract_Detail__r.Units_Low__c : 0;
        Decimal loePerUnitLow = eachAutogen.LOE_Per_Unit_Low__c != NULL  ? eachAutogen.LOE_Per_Unit_Low__c : 0;

        Integer isBucketProject;
        if(eachAutogen.IS_Bucket_Project__c != NULL && eachAutogen.IS_Bucket_Project__c){
            isBucketProject = 1;
        }
        else{
            isBucketProject = 0;
        }      
        Integer noOfActiveMonths = numberOfActiveMonths(achd.Parent_Contract_Detail__r.Effective_Start_Date__c,achd.Parent_Contract_Detail__r.Effective_End_Date__c);        
        
        plannedHours += Math.Round((unitsLow/3.0) * noOfActiveMonths * isNormalQuarterlyHoursProject);
        plannedHours += Math.Round(noOfActiveMonths * fixedHoursPerMonth);
        plannedHours += Math.Round(noOfActiveMonths/3.0) * fixedHoursPerQuarter;
        //plannedHours += (unitsLow * noOfActiveMonths / 12 ).round(roundingMode.DOWN) * loePerUnitLow;
        plannedHours += Math.Round(unitsLow * noOfActiveMonths / 12 ) * loePerUnitLow;
        plannedHours += Math.Round(unitsLow * isBucketProject);

        return plannedHours;        
    }
    
    public static pse__Proj__c getProjectTemplate(GSS_Autogen__c eachAutogen)
    {        
        pse__Proj__c proj = new pse__Proj__c();
        proj.Id = eachAutogen.Project_Template__c;
        proj.Name = eachAutogen.Project_Template__r.Name;
        proj.pse__Account__c = eachAutogen.Project_Template__r.pse__Account__c;
        proj.RecordTypeId = eachAutogen.Project_Template__r.RecordTypeId;
        proj.pse__Is_Billable__c = eachAutogen.Project_Template__r.pse__Is_Billable__c;
        proj.pse__Project_Type__c = eachAutogen.Project_Template__r.pse__Project_Type__c;
        proj.Project_Sub_Type__c = eachAutogen.Project_Template__r.Project_Sub_Type__c;
        proj.pse__Start_Date__c = eachAutogen.Project_Template__r.pse__Start_Date__c;
        proj.pse__End_Date__c = eachAutogen.Project_Template__r.pse__End_Date__c;
        proj.CURRENCYISOCODE = 'USD';
        proj.pse__Practice__c = eachAutogen.Project_Template__r.pse__Practice__c;
        proj.pse__Is_Active__c = eachAutogen.Project_Template__r.pse__Is_Active__c;
        proj.pse__Region__c = eachAutogen.Project_Template__r.pse__Region__c;
        proj.pse__is_template__c = true;
        proj.pse__Allow_Timecards_Without_Assignment__c = false;
        proj.pse__Allow_Self_Staffing__c = eachAutogen.Project_Template__r.pse__Allow_Self_Staffing__c;
        proj.pse__Project_manager__c = eachAutogen.Project_Template__r.pse__Project_manager__c;
        proj.pse__Billing_Type__c = eachAutogen.Project_Template__r.pse__Billing_Type__c;

        return proj;        
    }  
    
    public static pse__Proj__c createProject(GSS_Autogen__c eachAutogen, Id regionID, Autogen_Contract_Header_Detail__c eachACHD)
    {
        System.debug('Creating Autogen project in util class**');
        PSA_Settings__c psaSettings = PSA_Settings__c.getInstance('Project Manager');

        String projectName = eachAutogen.Project_Name__c;

        pse__Proj__c projectTemplate = getProjectTemplate(eachAutogen);
        Double plannedHours = calculatePlannedHours(eachAutogen,eachACHD);
        
        pse__proj__c project = new pse__proj__c();
        project = projectTemplate.clone(false,true,false,false);        
        project.Name = projectName;
        project.Project_Template__c = projectTemplate.id;
        project.CurrencyIsoCode = eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Currency__c;
        project.pse__Account__c = eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__c;    
        project.Contract_Closed__c = 'No';   
        project.pse__Billing_Type__c = projectTemplate.pse__Billing_Type__c;    
        project.pse__Project_Manager__c = psaSettings.Value__c;    
        project.pse__End_Date__c = eachACHD.Parent_Contract_Detail__r.Effective_End_Date__c;
        project.pse__Start_Date__c = eachACHD.Parent_Contract_Detail__r.Effective_Start_Date__c;            
        project.pse__Region__c = regionID; 
        project.pse__Planned_Hours__c = plannedHours;
        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        project.SMP_Contract__c = eachACHD.Parent_Contract_Header__c;
        project.SMP_Contract_Line_Item__c = eachACHD.Parent_Contract_Detail__r.Id;  
        project.PCLI_MRR1__c = eachACHD.Parent_Contract_Detail__r.Id; 
        project.PCLI_Overage1__c = eachACHD.Parent_Contract_Detail__r.Id; 
        project.PCLI_PerMonth1__c = eachACHD.Parent_Contract_Detail__r.Id;    
        project.Unit_Price__c = eachACHD.Parent_Contract_Detail__r.Unit_Price__c;
        project.Units_Low__c = eachACHD.Parent_Contract_Detail__r.Units_Low__c;
        project.Ongoing_Project_Recurring_Budget_Amt__c = 0;            
        project.Autogen_Product__c = projectName;
        project.ACHD__C = eachACHD.Id;        
        project.GSS_Autogen__c = eachAutogen.Id;
        project.pse__is_template__c = false;  
        project.External_Id__c = String.valueOf(eachACHD.Id);      
        
        try{
            Integer noOfActiveMonths = numberOfActiveMonths(eachACHD.Parent_Contract_Detail__r.Effective_Start_Date__c,eachACHD.Parent_Contract_Detail__r.Effective_End_Date__c);
            project.Ongoing_Project_Recurring_Planned_Hour__c = plannedHours/noOfActiveMonths;
        }
        catch(Exception e){
            project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        }                                
        return project;
    }

    //computes the number of Active months -> if the params are null, return 0
    public static Integer numberOfActiveMonths(Date startDate, Date endDate)
    {
        if(startDate == null || endDate == null){
            return 0;
        }
        Date firstDate;
        Date secondDate;
        Integer noOfMonths;
        Integer diffDays;

        //Get the lower date and store it in firstDate. The greater date is stored in secondDate
        if(startDate <= endDate){
            firstDate = startDate;
            secondDate = endDate;
        }
        else{
            secondDate = startDate;
            firstDate = endDate;
        }
        //get the number of months between the 2 dates. It will ignore the day difference. 
        //noOfMonths = firstDate.MonthsBetween(secondDate);
        noOfMonths  = ((secondDate.year() - firstDate.year()) * 12 )+ secondDate.month() - firstDate.month();
        //System.assertEquals(noOfMonths,0);
        //If the day of the second date is greater than or equal to the day of the first date, add 1 to the months. If the day of the first date is greater, then find the difference in days between the 2; if the difference is less than 15, then subtract 1 from the total months.
        if(secondDate.day() >= firstDate.day()){
            diffDays =  secondDate.day() - firstDate.day();
            if(Math.abs(diffDays) >= 15){
                noOfMonths++;
            }
        }
        else{
            Integer daysInMonth = 0;
            if(firstDate.month() == 1 || firstDate.month() == 3  || firstDate.month() == 5  || firstDate.month() == 7 || firstDate.month() == 8  || firstDate.month() == 10 || firstDate.month() == 12  ){
                daysInMonth = 31;
            }
            else if(firstDate.month() == 2){
                daysInMonth = 28;
            }
            else{
                daysInMonth = 30;
            }
            diffDays = daysInMonth - firstDate.day() + secondDate.day(); 
            if(Math.abs(diffDays) < 15){
                noOfMonths--;
            }
        }
        return Math.abs(noOfMonths);
    }
    
    public static List<pse__Milestone__c> createMilestonesUsingExternalIdAndProjectTemplate(pse__Proj__c project, List<pse__Milestone__c> templateMilestones)
    {
        pse__Proj__c projectLookUp = new pse__Proj__c();
        projectLookUp.External_Id__c = project.External_Id__c;   
        
        List<pse__Milestone__c> milestonesList = new List<pse__Milestone__c>();
        pse__Milestone__c milestone;
        
        for(pse__Milestone__c m : templateMilestones)
        {            
            milestone = new pse__Milestone__c();
            milestone.RecordtypeID  = m.RecordtypeID;
            milestone.pse__Status__c  = m.pse__Status__c;
            milestone.Milestone_Type_List__c  = m.Milestone_Type_List__c;
            milestone.Milestone_Type_Value__c  = m.Milestone_Type_Value__c;
            milestone.Task_Milestone_Name__c = m.Task_Milestone_Name__c;
            milestone.Name = m.Name;
            milestone.Billable__c = m.Billable__c;                        
            milestone.Start_Date__c = project.pse__Start_Date__c;
            milestone.pse__Target_Date__c = project.pse__End_Date__c;
            milestone.External_Id__c = project.External_Id__c + m.Name;                                                        
            milestone.pse__Project__r = projectLookUp;                
            milestone.pse__Milestone_Amount__c = 0;
            milestone.pse__Planned_Hours__c = 0; 
            
            milestonesList.add(milestone);
        }            
        return milestonesList;
    }
    
    
    public static pse__Budget__c createBudgetsUsingExternalId(pse__Proj__c project)
    { 
        pse__Proj__c projectLookUp = new pse__Proj__c();
        projectLookUp.External_Id__c = project.External_Id__c;            
        
        pse__Budget__c budget= new pse__Budget__c();      
        budget.Name = project.name;
        budget.pse__Billable__c = project.pse__Is_Billable__c;                        
        budget.External_Id__c = project.External_Id__c;
        budget.pse__Project__r = projectLookUp;
        budget.pse__Account__c = project.pse__Account__c;
        budget.pse__Status__c = 'Approved';            
        budget.pse__Type__c = 'Customer Purchase Order';
        budget.pse__Approved__c = TRUE;
        budget.Autogen_Budget__c = true;
        budget.pse__Effective_Date__c = project.pse__Start_Date__c;
        budget.pse__Amount__c = 0;
        
        return budget;
    }
    
    
    //Creates the Project_Contract__c record
    public static Project_Contract__c createProjectContractUsingExternalId(pse__Proj__c project)
    {
        pse__Proj__c projectLookUp = new pse__Proj__c();
        projectLookUp.External_Id__c = project.External_Id__c;
        
        Project_Contract__c pc = new Project_Contract__c();
        pc.Project__r = projectLookUp;
        pc.Original_Contract_Id__c = project.SMP_Contract__c;
        pc.Account__c = project.pse__Account__c;
        pc.External_Id__c = project.External_Id__c + System.now();
        return pc;
    }
    
    public static Project_Contract_Line_Item__c createProjectContractLineItemsUsingExternalId(pse__Proj__c project, Project_Contract__c pc)
    {
        pse__Proj__c projectLookUp = new pse__Proj__c();
        projectLookUp.External_Id__c = project.External_Id__c;
        
        Project_Contract__c pcLookUp = new Project_Contract__c();
        pcLookUp.External_Id__c = pc.External_Id__c;
        
        Project_Contract_Line_Item__c pcli = new Project_Contract_Line_Item__c();
        pcli.Contract_Detail__c = project.SMP_Contract_Line_Item__c;
        pcli.Original_Contract_Id__c = project.SMP_Contract__c;
        pcli.Project__r = projectLookUp;
        pcli.Project_Contract__r = pcLookUp;
        pcli.Valid_Create__c = TRUE;
            
        return pcli;
    }                 
    
    //This takes in the subject and the error message String: sends a mail to the engg team
    public static void sendErrorMails(String subject, String error)
    {
        if(error == '')
        {
          return;
        }
        // 20.4.2 Adding Host name on the email that we send
        String hostName = URL.getSalesforceBaseUrl().getHost(); 
        PSA_Settings__c enggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
        List<String> emailAddresses = enggEmail != null ?enggEmail.Value__c.split(',') : new list<String>{'services-engg@akamai.com'};
        String body = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() +', <br/> Instance : '+  hostName + '<br/><br/>';  
        Body += error;
        Body += '</body></html>';
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(emailAddresses);            
        objEmail.setSubject(subject + hostName);
        objEmail.setHTMLBody( body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);

    }
}
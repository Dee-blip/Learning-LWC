/**
|  HISTORY  |   

|  UTIL CLASS: GSS_Autogen_Util

|  TEST CLASS: GSS_Autogen_Test

|  DATE             DEVELOPER       JIRA            DESCRIPTION                               

|  ===========      =========       =======         =========== 

|  08-Feb-2021      Sandeep        FFPSA-1769     Class for GSS_Autogen_Batch

**/
public class GSS_Autogen_Class 
{

    Set<Autogen_Contract_Header_Detail__c> unitOfMeasureFailedACHDSet = new Set<Autogen_Contract_Header_Detail__c>();
    
    Map<Id,GSS_Autogen__c> achdIdToGSSAutogenForProjectsMap = new Map<Id,GSS_Autogen__c>();//prepared map for ACHD to GSS Autogen records for project creation purpose(only 1 per ACHD)
    
    Map<Id,Case> achdIdToCaseForProjectMap = new Map<Id,Case>();    //map of ACHD Id to existing case 

    Map<Id,String> cliDescriptionMap = new Map<Id,String>();//has ACHDs which have wrong Billing Duration and their related error that needs to be attached on case description
    Map<Case,String> caseMatchMap = new Map<Case,String>();  //Has existing case to the description that needs to go there on the case  
    List<String> accountIdGSSAutogenKeyForExisitingCasesList = new List<String>();


    Set<Case> casesForUpsertSet = new Set<Case>();
    List<pse__Proj__c> projectsForInsertList = new List<pse__Proj__c>();
    List<pse__Milestone__c> milsetonesForInsertList = new List<pse__Milestone__c>();
    List<pse__Budget__c> budgetForInsertList = new List<pse__Budget__c>();
    List<Project_Contract__c> pcsForInsertList = new List<Project_Contract__c>();
    List<Project_Contract_Line_Item__c> pclisForInsertList = new List<Project_Contract_Line_Item__c>();

    /**Constructor**/
    Map<String, Set<GSS_Autogen__c>> productIdToGSSAutogenMap = new Map<String, Set<GSS_Autogen__c>>();
    public GSS_Autogen_Class(Map<String, Set<GSS_Autogen__c>> productIdToGSSAutogen)
    { 
        productIdToGSSAutogenMap = productIdToGSSAutogen;
    }

    /*MAIN METHOD CALLED FROM BATCH CLASS*/
    public void mainAutogenMethod(List<Autogen_Contract_Header_Detail__c> allReturnACHD){
       
        //For the List of ACHDS, filter based on Unit of Measure, and Remove Duplicate ACHDs
        List<Autogen_Contract_Header_Detail__c> filteredACHDList = filterACHDForWrongUnitOfMeasure(allReturnACHD); // received filtered ACHDs so no ACHD with wrong UOM is here

        Map<Id,List<GSS_Autogen__c>> accountIdToGSSAutogenListMap = createGSSAutogenMaps(filteredACHDList); //gives account ->all GSS Autogen needs to be processed for all filtered ACHDs

        Map<Id,List<Case>> accountToExistingCaseListMap = checkIfCaseExist(filteredACHDList,accountIdToGSSAutogenListMap); //returns a map of Account and all related existing cases        
        
        Map<String,List<Autogen_Contract_Header_Detail__c>> filteredACHDMap = filterACHDsForWrongBillingDuration(filteredACHDList,accountToExistingCaseListMap); //returns a map for all ACHDs for which new case need to be created, projects are unfiltered
        

        if(filteredACHDMap.containsKey('Projects')){
            filteredACHDMap = filterForDuplicateProjectACHDs(filteredACHDMap); //New cases, new projects and duplicate projects
        }
        
        //Create Autogen Case ad Project Records, update flag on ACHD Records
        createAutogens(filteredACHDMap);
        
        //Perform DMLs on Projects (and its children), Cases, ACHDs and Project Case Associations
        performDMLs(filteredACHDMap);        
    }    
    
    /*
        Owner: Both
        Input: achdList: List of ACHDs coming from the batch class
        Output: filteredACHDMap: Map of filtered ACHDs 
        Function: Filter out ACHDs based on UoM and remove duplicates
        Steps: Take in the list of ACHDs, for each achd,
            1. Fetch the product Id and fetch the associated GSS Autogen records for the profuct Id 
            2. Iterate through the set of GSS Autogen records and ensure atleast one record has the Unit of Measure fields matching and add them to filteredACHDSet
            (If UoM doesn't match, add record to unitOfMeasureFailedACHDSet, these records will be marked cli onbaorded, but will have no case/projects associated)
            3. Run through the filteredACHDSet and add achds into filteredACHDMap by considering the unque key of Account + Product Id + UoM + Billing Duration
            (We want to ensure we have only one record with the above key in transaction, if duplicates are present, they will be processed in further transactions, so we remove them here)
    */
    
    public List<Autogen_Contract_Header_Detail__c> filterACHDForWrongUnitOfMeasure(List<Autogen_Contract_Header_Detail__c> achdList)
    {
 
        Set<Autogen_Contract_Header_Detail__c> filteredACHDSet = new Set<Autogen_Contract_Header_Detail__c>();
        //Run through each ACHD
        for(Autogen_Contract_Header_Detail__c eachACHD : achdList){           
            for(GSS_Autogen__c eachAutogen : productIdToGSSAutogenMap.get(eachACHD.Product__c)){
                if(eachAutogen.Triggering_Unit_of_Measure__c == eachACHD.Parent_Contract_Detail__r.Unit_of_Measure__c){
                    filteredACHDSet.add(eachACHD);     //filtered ACHDs (filtered using Unit of measure right now)
                    break;               
                }
            }
            if(!filteredACHDSet.contains(eachACHD)){
                eachACHD.IS_CLI_Onboarded__c = true; //If the unit of measure is wrong then we just onboard the CLI and no project and cases are created
                unitOfMeasureFailedACHDSet.add(eachACHD);
            }
        }

        Map<String,Autogen_Contract_Header_Detail__c> filteredACHDMap = new Map<String,Autogen_Contract_Header_Detail__c>();
        for(Autogen_Contract_Header_Detail__c eachACHD : filteredACHDSet){
            String uniqueKey = eachACHD.Parent_Contract_Header__r.Account_Name__c+eachACHD.Autogen_Triggering_Key__c;   
            if(!filteredACHDMap.containsKey(uniqueKey)){
                filteredACHDMap.put(uniqueKey,eachACHD); //Used in createAutogens() and performDML() method - Need an example for it??
            }
        }
        
        return filteredACHDMap.values();
    }

    /*
        Owner: Both
        Input: uniqueKeyToACHDMap: Map of filtered and unique ACHDs 
        Output: void
        Function: For the given ACHDs create achdIdToGSSAutogenForProjectsMap
        Steps:
            Take in the list of ACHDs, for each achd,
            1. Fetch all GSS Autogen records for each achd using the achd.ProductId on productIdToGSSAutogenMap          
            2. For each GSS Autogen, check if it is not Case Only and check if the triggering key matches, then add it with the achd record to achdIdToGSSAutogenForProjectsMap
            3. Map all the achd.accounts and their List of GSS Autogen records into accountIdToGSSAutogenListMap using the achd.ProductId on productIdToGSSAutogenMap 
    */
    
    public Map<Id,List<GSS_Autogen__c>> createGSSAutogenMaps(List<Autogen_Contract_Header_Detail__c> filteredACHDList)
    {
        Map<Id,List<GSS_Autogen__c>> accountIdToGSSAutogenListMap = new Map<Id,List<GSS_Autogen__c>>();

        for(Autogen_Contract_Header_Detail__c eachACHD : filteredACHDList){
            for(GSS_Autogen__c gssAutogen : productIdToGSSAutogenMap.get(eachACHD.Product__c)){
                if((gssAutogen.Triggering_Key__c).equals(eachACHD.Autogen_Triggering_Key__c) && !gssAutogen.Case_Only__c){
                    achdIdToGSSAutogenForProjectsMap.put(eachACHD.Id,gssAutogen); //prepared map for ACHD to GSS Autogen records for project creation purpose(only 1 per ACHD as there is only one case only ???)
                }
            }

            if(accountIdToGSSAutogenListMap.containsKey(eachACHD.Parent_Contract_Header__r.Account_Name__c)) {
                List<GSS_Autogen__c> tempLst = new List<GSS_Autogen__c>();
                tempLst.addAll(productIdToGSSAutogenMap.get(eachACHD.Product__c));
                accountIdToGSSAutogenListMap.get(eachACHD.Parent_Contract_Header__r.Account_Name__c).addAll(tempLst);
            } 
            else {
                List<GSS_Autogen__c> tempLst = new List<GSS_Autogen__c>();
                tempLst.addAll(productIdToGSSAutogenMap.get(eachACHD.Product__c));
                accountIdToGSSAutogenListMap.put(eachACHD.Parent_Contract_Header__r.Account_Name__c,  tempLst); //prepared map of Account to all needed GSS Autogen records for case creation
            }        
        }
        return accountIdToGSSAutogenListMap;
        
    }
    
    /*
        Owner: Support Team , (achdIdToCaseForProjectMap : Service Team)
        Input: uniqueKeyToACHDMap: Map of filtered and unique ACHDs 
        Output: accountToExistingCaseListMap: Map of account to List of Existing cases on the account
        Function: For the given ACHDs (Account) fetch all the cases created
        Steps:
            PART A: For each queried open case which is created in last 30 days, origin = autogen, and account in accountIdToGSSAutogenListMap
            1. Use case.account on accountIdToGSSAutogenListMap to iterate through GSS Autogen records
            2. Check if the case is relevant by matching the case paramenters on the GSS Autogen records and pick only the ones that match.
            3. For the matched cases, Create a record in accountToExistingCaseListMap 
            4. Additionally, if the GSS Autogen record has Case_Only__c = false, then create a record in accountIdGSSAutogenKeyToCaseForProjectMap with key as Account + GSS Autogen
            (This helps us to identify a case uniquely based on account and gss autogen record)

            PART B: For each ACHD,
            1. Fetch the GSS Autogen using the achdIdToGSSAutogenForProjectsMap
            2. Use this GSS Autogen in the accountIdGSSAutogenKeyToCaseForProjectMap to fetch the Case relevant to the ACHD
            3. Add the Case as a lookup to the ACHD record (Add the case and ACHD in the achdIdToCaseForProjectMap)
    */
    
    public Map<Id,List<Case>> checkIfCaseExist(List<Autogen_Contract_Header_Detail__c> achdList,Map<Id,List<GSS_Autogen__c>> accountIdToGSSAutogenListMap)
    {
        Map<Id,List<Case>> accountToExistingCaseListMap = new Map<Id,List<Case>>();
        Map<String,Case> accountIdGSSAutogenKeyToCaseForProjectMap = new Map<String,Case>();
        
        Date minus30Days = date.today().adddays(-30);

        for(Case eachCase : [
            SELECT id,AccountId,Account.Name,Contract__c,Description, Contract_Detail__c,Subject,Service__c,RecordTypeId,RecordType.Name,Sub_Type__c,Do_Not_Show_In_Portal_Picklist__c,RecordType_Name__c,Severity__c,Request_Type__c
            FROM case 
            WHERE 
                isClosed = false AND 
                Origin = 'Autogen' AND 
                createddate >=: minus30Days AND 
                AccountId in: accountIdToGSSAutogenListMap.keySet()
        ]){
            for(GSS_Autogen__c eachAutogen : accountIdToGSSAutogenListMap.get(eachCase.AccountId)){
                if(eachCase.Subject.contains(eachAutogen.Case_Subject__c) && eachAutogen.Case_Service__c == eachCase.Service__c
                && eachAutogen.Case_Record_Type__c == eachCase.RecordType.Name && eachAutogen.Case_Sub_Type__c == eachCase.Sub_Type__c
                && eachAutogen.Case_Severity__c == eachCase.Severity__c && eachAutogen.Case_Request_Type__c == eachCase.Request_Type__c)
                {                        
                    if(!eachAutogen.Case_Only__c){
                        accountIdGSSAutogenKeyToCaseForProjectMap.put(eachCase.AccountId + '' + eachAutogen, eachCase); //map of Account+Autogen to Case
                    }
                    if(accountToExistingCaseListMap.containsKey(eachCase.AccountId)) {
                        accountToExistingCaseListMap.get(eachCase.AccountId).add(eachCase); //prepared a map for account in filteredACHDs to existing cases of similar GSS Autogens
                    } 
                    else {
                        accountToExistingCaseListMap.put(eachCase.AccountId , new List<Case> { eachCase });
                    }
                }
            }
            
        }

        
        GSS_Autogen__c autogenForACHD;
        Case caseForACHD;
        for(Autogen_Contract_Header_Detail__c eachACHD : achdList){
            if(achdIdToGSSAutogenForProjectsMap.containsKey(eachACHD.Id)){
                autogenForACHD = achdIdToGSSAutogenForProjectsMap.get(eachACHD.Id);    //Only 1 value per ACHD
                if(accountIdGSSAutogenKeyToCaseForProjectMap.containsKey(eachACHD.Parent_Contract_Header__r.Account_Name__c + '' + autogenForACHD)){
                    caseForACHD = accountIdGSSAutogenKeyToCaseForProjectMap.get(eachACHD.Parent_Contract_Header__r.Account_Name__c + '' + autogenForACHD);            
                    achdIdToCaseForProjectMap.put(eachACHD.Id,caseForACHD); //map of ACHD Id to existing case 
                    eachACHD.Case_For_Project__c = caseForACHD.Id;//we also stamp the case Id to the ACHD record
                }                        
            }            
        }
        return accountToExistingCaseListMap;
    }

    
    /*
        Owner: achdsForProjectsList : Service Team, achdsForNewCasesList : Support Team
        Input: achdList : List of ACHDs that need to be filtered for incorrect billing durations
        Output: achdMap : Map of <'Projects' : List of ACHDs for project creation>, <'Cases' : List of ACHDs for new cases to be created>
        Function: Filter the given list of ACHDs which have incorrect billing duration
        Steps: 
            Part A: For each ACHD,
            1. Fetch all the GSS autogens for the achd.productId using productIdToGSSAutogenMap
            2. Check if the ACHD and GSS Autogen billing duration are matching.
            3. Create respective case descriptions in the fields matchedDesc and unmatchedDesc and add them to cliDescriptionMap 
            4. If a case already exists, if the description is a part of matchedIdSet (It means Billing duration is correct) then add to achdsForProjectsList fro project creation
            5. If mismatched, it will be in cliDescriptionMap which will be used to update case desriptions later.
            
            Part B: For each ACHD
            1. Check if the case associated to the gss autogen (account product id -> gss autogen list + case parameters) exists
            2. If yes, it means we have to update the case, get the case description from cliDescriptionMap and put it on caseMatchMap
            3. Also add gss autogen record to accountIdGSSAutogenKeyForExisitingCasesList ???
            4. If no, it means we have to create new cases for the achd, so add achds to achdsForNewCasesList
    */    
    Set<Id> matchedACHDIdSet = new Set<Id>(); // holds all the ACHDs that match UOM and Billing duration
    public Map<String,List<Autogen_Contract_Header_Detail__c>> filterACHDsForWrongBillingDuration(List<Autogen_Contract_Header_Detail__c> achdList, Map<Id,List<Case>> accountToExistingCaseListMap)
    {
        String unmatchedDesc;
        List<Autogen_Contract_Header_Detail__c> achdsForProjectsList = new List<Autogen_Contract_Header_Detail__c>(); // holds filterd ACHDs that are correct and !case_only
        List<Autogen_Contract_Header_Detail__c> achdsForNewCasesList = new List<Autogen_Contract_Header_Detail__c>();
        for(Autogen_Contract_Header_Detail__c eachACHD : achdList){

            for(GSS_Autogen__c eachAutogen : productIdToGSSAutogenMap.get(eachACHD.Product__c)){

                if(eachAutogen.Triggering_Unit_Of_Measure__c == eachACHD.Parent_Contract_Detail__r.Unit_of_Measure__c){
                    if(eachAutogen.Triggering_Billing_Duration__c == eachACHD.Parent_Contract_Detail__r.Billing_Duration__c)
                    {                    
                        matchedACHDIdSet.add(eachACHD.Id);
                    
                        if(!eachAutogen.Case_Only__c)
                        {
                            achdsForProjectsList.add(eachACHD);
                        }
                        break;
                    }
                    //If billing duration is not supported, then create only case and append error in description
                    else{//the below should work for more than 1 project failures
                        if(cliDescriptionMap.containsKey(eachACHD.id))
                        {
                            unmatchedDesc = cliDescriptionMap.get(eachACHD.id);
                        }
                        else{
                            unmatchedDesc = '';
                        }
                        unmatchedDesc += '\n\n '+System.now()+': Project {0} could not be created due to non-standard Billing Duration for the UoM:{1} (Product supports only {2}) - please correct the contract and proceed with manual project set-up. If this is corrected within the next 72 hours project will be automatically generated.';
                        if(eachAutogen.Project_Name__c == null || eachAutogen.Case_Only__c){
                            unmatchedDesc = unmatchedDesc.replace('{0}', '');
                        } 
                        else {
                            unmatchedDesc = unmatchedDesc.replace('{0}', eachAutogen.Project_Name__c);
                        }
                        unmatchedDesc = unmatchedDesc.replace('{1}', eachACHD.Parent_Contract_Detail__r.Unit_of_Measure__c);
                        unmatchedDesc = unmatchedDesc.replace('{2}', eachAutogen.Triggering_Billing_Duration__c);
                        cliDescriptionMap.put(eachACHD.id,unmatchedDesc); //has ACHDs which have wrong Billing Duration and their related error that needs to be attached on case description
                    }
                }
                
            }
            
            /*If Case exists and Billing Duration Doesn't match update the case else create a new case*/
            if(accountToExistingCaseListMap.containsKey(eachACHD.Parent_Contract_Header__r.Account_Name__c)){
                for(GSS_Autogen__c eachAutogen : productIdToGSSAutogenMap.get(eachACHD.Product__c)){
                    for(Case existingCase : accountToExistingCaseListMap.get(eachACHD.Parent_Contract_Header__r.Account_Name__c)){
                        if(existingCase.Subject.contains(eachAutogen.Case_Subject__c) && eachAutogen.Case_Service__c == existingCase.Service__c
                           && eachAutogen.Case_Record_Type__c == existingCase.RecordType.Name && eachAutogen.Case_Sub_Type__c == existingCase.Sub_Type__c)
                        {
                            accountIdGSSAutogenKeyForExisitingCasesList.add('' + existingCase.AccountId + eachAutogen.id); //used in method createAutogenCase() to check if case already does not exist before creating a new case
                            if(cliDescriptionMap.containsKey(eachACHD.id)){
                                caseMatchMap.put(existingCase,cliDescriptionMap.get(eachACHD.id));//Has existing case to the description that needs to go there on the case
                            }
                            else{
                                caseMatchMap.put(existingCase,'');
                            }
                        }
                        else{
                            achdsForNewCasesList.add(eachACHD);//If Biling duration is wrong and there is no existing case then add the ACHD to create a new case
                        }
                    }
                }
            }
            else{
                achdsForNewCasesList.add(eachACHD);
            }
        }  
        Map<String,List<Autogen_Contract_Header_Detail__c>> achdMap = new Map<String,List<Autogen_Contract_Header_Detail__c>>();
        achdMap.put('Projects',achdsForProjectsList);//this has ACHDs for which a project might exist and also for which new project needs to be created
        achdMap.put('Cases',achdsForNewCasesList);
        return achdMap; //right now this map has only ACHDs for which new cases need to be created, projects are unfiltered
    }

     /*
        Owner: Service Team
        Input: unfilteredACHDsForProjectList: List of achd records for which Duplicate projects associated records should be filtered
        Output: achdMap : Map of achdsForProjectsList(List of final list of ACHDs for which projects have to be created and, duplicateACHDsList List of achds with cases descrioption showing error
        Function: Method to find if projects are already associated to the ACHD and filter them for further transactions.
        Steps: Take in the list of ACHDs, for each achd,
           1. Check If the ACHD corresponds to an existing case using the eachACHD.Case_For_Project__c lookup and check if there is an GSS Autogen record in the achdIdToGSSAutogenForProjectsMap
           2. If yes, Add GSS autogen records and the case Ids associated to the ACHDs into gssAutogenIdsForExistingProjectsList, caseIdsForExistingProjectsList
           3. Fetch all Project case association with the above in filters and add the existing valid cases with the GSS Autogen in to the caseIdsAndGSSAutogenOfExisitingProjectsSet
           4. For each ACHD, if eachACHD.Case_For_Project__c + '' + achdIdToGSSAutogenForProjectsMap.get(achd.Id).Id is in caseIdsAndGSSAutogenOfExisitingProjectsSet, add to duplicateACHDsList, otherwise add to achdsForProjectsList
    */
    public Map<String,List<Autogen_Contract_Header_Detail__c>> filterForDuplicateProjectACHDs(Map<String,List<Autogen_Contract_Header_Detail__c>> achdMap)
    {

        List<Autogen_Contract_Header_Detail__c> unfilteredACHDsForProjectList = achdMap.get('Projects'); 
        List<Id> caseIdsForExistingProjectsList = new List<Id>();
        List<Id> gssAutogenIdsForExistingProjectsList = new List<Id>();
        
        for(Autogen_Contract_Header_Detail__c eachACHD : unfilteredACHDsForProjectList){
            if(eachACHD.Case_For_Project__c!=null && achdIdToGSSAutogenForProjectsMap.containsKey(eachACHD.Id))
            {
                caseIdsForExistingProjectsList.add(eachACHD.Case_For_Project__c);//gives case on an ACHD(as if case exits we can say project exists)
                gssAutogenIdsForExistingProjectsList.add(achdIdToGSSAutogenForProjectsMap.get(eachACHD.Id).Id);//here we are getting the autogen id for which project needs to be created
            }
        }

        Set<String> caseIdsAndGSSAutogenOfExisitingProjectsSet = new Set<String>();
        for(pse__Proj__c proj : [
            SELECT id,Case__c,GSS_Autogen__c
            FROM pse__Proj__c
            WHERE 
                Autogen_Product__c != null AND 
                GSS_Autogen__c = :gssAutogenIdsForExistingProjectsList AND 
                Case__c = :caseIdsForExistingProjectsList AND
                Case__r.isClosed = False AND
                Case__r.Origin = 'Autogen'
        ]){
            caseIdsAndGSSAutogenOfExisitingProjectsSet.add(proj.Case__c + '' + proj.GSS_Autogen__c);
        }        

        List<Autogen_Contract_Header_Detail__c> achdsForProjectsList = new List<Autogen_Contract_Header_Detail__c>();
        List<Autogen_Contract_Header_Detail__c> duplicateACHDsList = new List<Autogen_Contract_Header_Detail__c>();
        for(Autogen_Contract_Header_Detail__c eachACHD : unfilteredACHDsForProjectList){
            if(eachACHD.Case_For_Project__c!=null && achdIdToGSSAutogenForProjectsMap.containsKey(eachACHD.Id)){
                String key = eachACHD.Case_For_Project__c + '' + achdIdToGSSAutogenForProjectsMap.get(eachACHD.Id).Id;
                if(!caseIdsAndGSSAutogenOfExisitingProjectsSet.contains(key)){
                    achdsForProjectsList.add(eachACHD);//Here we have filtered ACHDs for which we need to create new projects
                }
                else{
                    duplicateACHDsList.add(eachACHD);//projects already exist
                }
            }
            else{
                achdsForProjectsList.add(eachACHD);//new projects
            }            
        }
        achdMap.put('Projects',achdsForProjectsList);
        achdMap.put('Duplicate Projects',duplicateACHDsList);
        return achdMap;//now here the map has cases new to be created(it was already), we have filtred projects to be created and we also have duplicate projects.
    }

    /*
        Owner: Both
        Input: accountToExistingCaseListMap: Map of account to List of created Cases
        Output: None
        Function: Create Autogen Case, Project (and its children) records
        Steps: Take in the filteredACHDMap
            1. If Map contains 'Cases' key and corresponding list has values, send them for new case creation
            2. If Map contains 'Projects'' key and corresponding list has values, send them for new Project creation
            3. Call update case description on caseMatchMap (caseMatchMap values will be populated in step 2 as per project creation)
            New cases, projects etc. will be added into casesForUpsertSet, projectsForUpsertList, etc.
    */    
    public void createAutogens(Map<String,List<Autogen_Contract_Header_Detail__c>> filteredACHDMap)
    {        
        if(filteredACHDMap!=null && filteredACHDMap.containsKey('Cases')){
            List<Autogen_Contract_Header_Detail__c> achdsForCasesList = filteredACHDMap.get('Cases');
            if(achdsForCasesList!=null && achdsForCasesList.size() > 0){
                List<Case> newCaseList = createAutogenCase(filteredACHDMap.get('Cases'));
                casesForUpsertSet.addAll(newCaseList);   //all new cases to be inserted

            }              
        }
        
        if(filteredACHDMap!=null && filteredACHDMap.containsKey('Projects')){
            List<Autogen_Contract_Header_Detail__c> achdsForProjectsList = filteredACHDMap.get('Projects');
            if(achdsForProjectsList!=null && achdsForProjectsList.size() > 0){
                createAutogenProject(achdsForProjectsList);     //all new projects that need to be created   
            }            
        }
        if(caseMatchMap!=null && caseMatchMap.size() > 0){
            //What to do with filteredACHDMap.get('Duplicate Projects')
            for(Autogen_Contract_Header_Detail__c eachACHD : filteredACHDMap.get('Duplicate Projects')){
                Case cs = achdIdToCaseForProjectMap.get(eachACHD.Id); //Got the case for the duplicate project on which we need to stamp message
                String description ='';
                if(caseMatchMap.containsKey(cs)){
                    description += caseMatchMap.get(cs);
                }
                String stg = '\n\n '+System.now()+': CLI {0} with Unit of Measure : {1} was added to {2} but the project was not generated. Please close this case if you want new projects to be created for this product.';
                stg = stg.replace('{0}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+eachACHD.Id);
                stg = stg.replace('{1}', eachACHD.Parent_Contract_Detail__r.Unit_of_Measure__c);
                stg = stg.replace('{2}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Id);
                description += stg;
                caseMatchMap.put(cs,description);
            }
            
        }        
    }


    /*
        Owner: Support Team
        Input: achdsForNewCasesList: List of achd records for which Cases have to be created
        Output: newCaseList : List of new case records which have to be inserted
        Function: Method to create Autogen Case and ensure there are no duplicates within an account
        Steps: Take in the list of ACHDs, for each achd,
           ???
    */
    public List<Case> createAutogenCase(List<Autogen_Contract_Header_Detail__c> achdsForNewCasesList)
    {        
        Case newCase;
        List<Case> newCaseList = new List<Case>();
        Map<Id,List<Case>> accountCaseListMap = new Map<Id,List<Case>>();
        Map<String,Case> newCaseMap = new Map<String,Case>(); 
        for(Autogen_Contract_Header_Detail__c eachACHD : achdsForNewCasesList){

            for(GSS_Autogen__c eachAutogen : productIdToGSSAutogenMap.get(eachACHD.Product__c)){
                //If the logic goes inside the below if means for a  given Autogen there is no existing  case
                if(!accountIdGSSAutogenKeyForExisitingCasesList.contains(''+ eachACHD.Parent_Contract_Header__r.Account_Name__c + eachAutogen.id)){

                    if(eachACHD.Parent_Contract_Detail__r.Unit_of_Measure__c == eachAutogen.Triggering_Unit_of_Measure__c){
                        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(eachAutogen.Case_Record_Type__c).getRecordTypeId();
                        String caseDescription = '';
                        newCase = new Case();
                        newCase.RecordTypeId = caseRecordTypeId;
                        newCase.Subject = eachAutogen.Case_Subject__c+eachACHD.Parent_Contract_Header__r.Account_Name__r.name;
                        if(cliDescriptionMap.get(eachACHD.Id) != null){
                            //newCase.Description = eachAutogen.Case_Description__c+cliDescriptionMap.get(eachACHD.Id);
                            caseDescription = eachAutogen.Case_Description__c+cliDescriptionMap.get(eachACHD.Id);
                        } else{
                            //newCase.Description = eachAutogen.Case_Description__c;
                            caseDescription = eachAutogen.Case_Description__c;
                        } 
                        if(caseDescription.length() > 30000){
                            if(!caseDescription.contains('CHARACTER LIMIT REACHED'))
                            	newCase.Description = caseDescription+'CHARACTER LIMIT REACHED';                                
                        }
                        else{
                            newCase.Description = caseDescription;
                        }
                        newCase.Service__c = eachAutogen.Case_Service__c;
                        newCase.Sub_Type__c  = eachAutogen.Case_Sub_Type__c;
                        newCase.Origin = 'Autogen';
                        newCase.Request_Type__c = eachAutogen.Case_Request_Type__c;
                        newCase.Severity__c = eachAutogen.Case_Severity__c;
                        newCase.Case_Assignment_Using_Active_Rules__c = true;
                        newCase.Status = 'Unassigned';
                        newCase.Do_Not_Show_in_Portal__c = true;
                        newCase.AccountId = eachACHD.Parent_Contract_Header__r.Account_Name__c;
                        newCase.Contract__c = eachACHD.Parent_Contract_Header__c;
                        newCase.Contract_Detail__c = eachACHD.Parent_Contract_Detail__r.Original_Detail_Id__c;
                        
                        newCaseList.add(newCase); 

                        //below checking whether we already have this ACHD for project creation or not
                        if(!eachAutogen.Case_Only__c && achdIdToGSSAutogenForProjectsMap.containsKey(eachACHD.Id)){                            
                            achdIdToCaseForProjectMap.put(eachACHD.Id,newCase);//this is done so that later the case Id can be stamped on the ACHD record                                                                                                      
                        }
                    }
                }
                
            }
        }
        for(Case newCaseCreated : newCaseList){
            if(accountCaseListMap.containsKey(newCaseCreated.AccountId)) {                
                accountCaseListMap.get(newCaseCreated.AccountId).add(newCaseCreated);
            } 
            else {
                accountCaseListMap.put(newCaseCreated.AccountId, new List<Case> { newCaseCreated });//map of account and all related new cases to be inserted
            }
        }
        
        for(Id accountId : accountCaseListMap.keySet()){
            for(Case eachCase : accountCaseListMap.get(accountId)){
                String caseParameter = eachCase.AccountId+ eachCase.Service__c+ eachCase.Request_Type__c+ eachCase.Severity__c+ eachCase.Sub_Type__c+ eachCase.Do_Not_Show_In_Portal_Picklist__c + eachCase.Subject;
                newCaseMap.put(caseParameter,eachCase); //This case map maps each new case to be created uniquely(case unique key ->case)
            }
        }
        return newCaseMap.values();
    }


    /*
        Owner: Service Team
        Input: achdsForProjectsList: List of achd records for which Projects have to be created
        Output: void, the results are put in the global variables
        Function: Method to create Autogen Project
        Steps: 
           1. Method call: GSS_Autogen_Util.getRegionNameToIdMap() Find the region linked to the account of the ACHD, fetch its Id and put in the regionNameToIdMap
           For each ACHD
           2. Fetch it's relevant GSS Autogen record from achdIdToGSSAutogenForProjectsMap and ensure a region Id is present for the territory on the account linked
           3. Use the GSS Autogen values to create projects in GSS_Autogen_Util.createProject()
           4. Additionally add the project template Ids into projectTemplateIdsSet which will be used later for milestone and other project dependencies creation.
    */
    public void createAutogenProject(List<Autogen_Contract_Header_Detail__c> achdsForProjectsList)
    {        
        Map<String,Id> regionNameToIdMap = GSS_Autogen_Util.getRegionNameToIdMap(achdsForProjectsList);
        if(regionNameToIdMap!=null)
        {            
            Set<Id> projectTemplateIdsSet = new Set<Id>();
            for(Autogen_Contract_Header_Detail__c eachACHD : achdsForProjectsList){

                if(achdIdToGSSAutogenForProjectsMap.containsKey(eachACHD.Id) && regionNameToIdMap.containsKey(eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)'))
                {
                    //Fetch the GSS Autogen Record                    
                    GSS_Autogen__c eachAutogen = achdIdToGSSAutogenForProjectsMap.get(eachACHD.Id);

                    Id regionID = regionNameToIdMap.get(eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)');

                    pse__proj__c project = GSS_Autogen_Util.createProject(eachAutogen,regionID,eachACHD);  
                    projectTemplateIdsSet.add(project.Project_Template__c);                      
                    projectsForInsertList.add(project);  
                }			
                else if(!regionNameToIdMap.containsKey(eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)')){
                    string setEmailSub = 'Region Not found in autogen';
                    string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '</br>' +
                                            'Class Name = GSS_Autogen_Class</br>' + 
                                            'Util Class Name = GSS_Autogen_Util</br>' +
                                            'Method Name = createAutogenProject</br>'+
                                            'Account Id = '+eachACHD.Parent_Contract_Detail__r.Original_Contract_Id__r.Account_Name__c;

                    GSS_Autogen_Util.sendErrorMails(setEmailSub, errorMessage);
                }		                    
            }
            createProjectDependencies(projectTemplateIdsSet);
        }
               
    }

    /*
        Owner: Service Team
        Input: projectTemplateIdsSet: Set of project templates used for creating projects
        Output: void, the results are put in the global variables
        Function: Method to create Autogen Project dependencies like assignments, budgets, milestones, project contracts, project contract line items and project case association.
        Steps: 
           1. Fetch all the milestones which are linked to projectTemplateIdsSet and put them in a map projectTemplateIdToMilestonesListMap
           2. For each of the projects created in projectsForInsertList, create milestones, budgets, pcas, pcs and pclis
    */
    public void createProjectDependencies(Set<Id> projectTemplateIdsSet)
    {
        Map<Id,List<pse__Milestone__c>> projectTemplateIdToMilestonesListMap = new Map<Id,List<pse__Milestone__c>>();        
        for(pse__Milestone__c templateMilestone : [
            SELECT Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c,pse__Project__c 
            FROM pse__Milestone__c 
            WHERE pse__Project__c in :projectTemplateIdsSet
        ]){
            List<pse__Milestone__c> tempMilestoneList = new List<pse__Milestone__c>();
            if(!projectTemplateIdToMilestonesListMap.isEmpty() && projectTemplateIdToMilestonesListMap.containsKey(templateMilestone.pse__Project__c))
            {
                tempMilestoneList = projectTemplateIdToMilestonesListMap.get(templateMilestone.pse__Project__c);
            }
            tempMilestoneList.add(templateMilestone);
            projectTemplateIdToMilestonesListMap.put(templateMilestone.pse__Project__c,tempMilestoneList);
        }        
                
        for(pse__Proj__c project : projectsForInsertList)
        {                                 
            milsetonesForInsertList.addAll(GSS_Autogen_Util.createMilestonesUsingExternalIdAndProjectTemplate(project,projectTemplateIdToMilestonesListMap.get(project.Project_Template__c)));
            budgetForInsertList.add(GSS_Autogen_Util.createBudgetsUsingExternalId(project));
            Project_Contract__c pc = GSS_Autogen_Util.createProjectContractUsingExternalId(project);
            pcsForInsertList.add(pc);
            pclisForInsertList.add(GSS_Autogen_Util.createProjectContractLineItemsUsingExternalId(project,pc));

        }
    }


    /*
        Owner: Both
        Input: allReturnACHD: List of the ACHDs
        Output: void
        Function: Perform DMLs on various objects and fetch to update values accordingly.
        Steps: 
           1. Perform Upsert on projectsForInsertList, for each succesful record, create a clone record of the project (mark SMP_Automated_Project__c and Contract_Closed__c to Ture and Yes) and add to projectsForUpdateList
           2. Perform Insert on milsetonesForInsertList, budgetForInsertList, pcsForInsertList, pclisForInsertList and update on projectsForUpdateList
           3. Call updateCaseDescriptionsWithProjects which will update the cases with respective description and also update 
    */        
    public void performDMLs(Map<String,List<Autogen_Contract_Header_Detail__c>> filteredACHDMap)
    {

        //Insert Autogen Project

        Savepoint sp = Database.setSavepoint(); // Savepoint to return here when there is a exception
        
        try{

            List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
            List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
            Map<Id,Id> achdIdToProjectIdMap = new Map<Id,Id>();
            List<pse__Proj__c> projectsForUpdateList = new List<pse__Proj__c>();         


            //Insert Autogen Project Contract Line Items
            if(projectsForInsertList != null && !projectsForInsertList.isEmpty()){
                
                pse__Proj__c indexedProject;
                pse__Proj__c projectToUpdate;

                upsertResultRecords = Database.Upsert(projectsForInsertList,true);//Firstly we insert the new projects(if here any exception occurs then further more nothing gets created)
                for(Database.UpsertResult insertedProject: upsertResultRecords)
                {
                    if (insertedProject.isSuccess()) 
                    {                                            
                        indexedProject = projectsForInsertList.get(upsertResultRecords.indexOf(insertedProject));
                        achdIdToProjectIdMap.put(indexedProject.ACHD__C,insertedProject.getId());


                        projectToUpdate = new pse__Proj__c();
                        // projectToUpdate = indexedProject.clone(false,true,false,false);
                        projectToUpdate.Id = insertedProject.getId();
                        projectToUpdate.SMP_Automated_Project__c = TRUE;
                        projectToUpdate.Contract_Closed__c = 'Yes';
                        projectToUpdate.External_Id__c = indexedProject.External_Id__c;
                        projectToUpdate.SMP_Contract_Line_Item__c = indexedProject.SMP_Contract_Line_Item__c;
                        projectToUpdate.SMP_Contract__c = indexedProject.SMP_Contract__c;
                        projectToUpdate.ACHD__c = indexedProject.ACHD__c;
                        projectToUpdate.pse__Account__c = indexedProject.pse__Account__c;
                        projectToUpdate.GSS_Autogen__c = indexedProject.GSS_Autogen__c;
                        projectsForUpdateList.add(projectToUpdate);//After the projects are inserted successfully we update some other data and prepare project update list

                    }
                }
    

                //Insert Autogen Project Milestones
                if(milsetonesForInsertList != null && !milsetonesForInsertList.isEmpty()){
                    insert milsetonesForInsertList;
                }
                

                //Insert Autogen Project Budget
                if(budgetForInsertList != null && !budgetForInsertList.isEmpty()){
                    insert budgetForInsertList;
                }   
                
                //Insert Autogen Project Contract Line Items
                if(pcsForInsertList != null && !pcsForInsertList.isEmpty()){
                    insert pcsForInsertList;
                }       
                
                //Insert Autogen Project Contract Line Items
                if(pclisForInsertList != null && !pclisForInsertList.isEmpty()){
                    insert pclisForInsertList;
                }                                                                 
                
                
            }
            updateCaseDescriptionsWithProjectDetails(projectsForUpdateList); //Whenever project is inserted we need to update message on the case so we call this method
            
            //Upsert Autogen Cases                   
            List<Case> casesForUpsertList = new List<Case>();
            Map<String,Case> unique = new Map<String,Case>();
  
            for(Case eachCase : casesForUpsertSet){
                String caseParameter = '' + eachCase.AccountId + eachCase.Service__c + eachCase.Request_Type__c + eachCase.Severity__c + eachCase.Subject + eachCase.Sub_Type__c + eachCase.Do_Not_Show_In_Portal_Picklist__c;
                unique.put(caseParameter,eachCase);
            }
            casesForUpsertList = unique.values();

            Map<String,Id> caseParametersToCaseIdMap = new Map<String,Id>();
            Case eachCase;
            String caseParameter;

            if(casesForUpsertList != null && !casesForUpsertList.isEmpty()){
                upsertResultRecords = Database.Upsert(casesForUpsertList,true);
                for(Database.UpsertResult upsertedCase: upsertResultRecords){
                    if (upsertedCase.isSuccess()) {     
                        eachCase = casesForUpsertList.get(upsertResultRecords.indexOf(upsertedCase));
                        caseParameter = '' + eachCase.AccountId + eachCase.Service__c + eachCase.Request_Type__c + eachCase.Severity__c + eachCase.Subject + eachCase.Sub_Type__c + eachCase.Do_Not_Show_In_Portal_Picklist__c;
                        caseParametersToCaseIdMap.put(caseParameter,upsertedCase.getId());                                
                    }
                }                
            }
            
            for(pse__Proj__c proj : projectsForUpdateList){
                eachCase = achdIdToCaseForProjectMap.get(proj.ACHD__c);
                caseParameter = '' + eachCase.AccountId + eachCase.Service__c + eachCase.Request_Type__c + eachCase.Severity__c + eachCase.Subject + eachCase.Sub_Type__c + eachCase.Do_Not_Show_In_Portal_Picklist__c;
                proj.Case__c = caseParametersToCaseIdMap.get(caseParameter);
            }

            if(projectsForUpdateList!=null && projectsForUpdateList.size()>0){
                update projectsForUpdateList;
            }
            

            List<Autogen_Contract_Header_Detail__c> allACHDList = new List<Autogen_Contract_Header_Detail__c>();
            Set<Autogen_Contract_Header_Detail__c> allACHDSet = new Set<Autogen_Contract_Header_Detail__c>();
            allACHDSet.addAll(filteredACHDMap.get('Cases'));
            allACHDSet.addAll(filteredACHDMap.get('Projects'));
            allACHDSet.addAll(filteredACHDMap.get('Duplicate Projects'));
            allACHDList.addAll(allACHDSet);
            
            //Update ACHD Records, Mark Onboarded flag
            for(Autogen_Contract_Header_Detail__c eachACHD : allACHDList){
                if(matchedACHDIdSet.contains(eachACHD.Id)){
                    eachACHD.IS_CLI_Onboarded__c = true;
                    if(achdIdToProjectIdMap.containsKey(eachACHD.Id)){
                        eachACHD.Project__c = achdIdToProjectIdMap.get(eachACHD.Id);     
                    }
                }                    
            }
            if(!unitOfMeasureFailedACHDSet.isEmpty()){
                List<Autogen_Contract_Header_Detail__c> unitOfMeasureFailedACHDList = new List<Autogen_Contract_Header_Detail__c>();
                unitOfMeasureFailedACHDList.addAll(unitOfMeasureFailedACHDSet);
                allACHDList.addAll(unitOfMeasureFailedACHDList);
            }
            
            if(allACHDList != null && !allACHDList.isEmpty()){
                update allACHDList;
            }
        }
        catch(Exception e){
            Database.rollback(sp);//rolling bcak to a state where nothing was created

            System.debug('!!!DML ERROR CATCH BLOCK!!!');

            string setEmailSub = 'Exception: An exception occurred while creating autogen case/project.';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '</br>' +
                      				'Class Name = GSS_Autogen_Class</br>' + 
                                	'Util Class Name = GSS_Autogen_Util</br>' +
                                	'Method Name = performDMLs</br>';


            errorMessage = errorMessage + '</br>Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
            System.debug('!!!Exception type caught: ' + e.getTypeName());
            System.debug('!!!Message: ' + e.getMessage());
            System.debug('!!!Cause: ' + e.getCause());
            System.debug('!!!Line number: ' + e.getLineNumber());
            System.debug('!!!Stack trace: ' + e.getStackTraceString());

            GSS_Autogen_Util.sendErrorMails(setEmailSub, errorMessage);
        }
    }


     /*
        Owner: Service Team
        Input: projectsForUpdateList: List of the projects for which case descriptions will updated
        Output: void
        Function: For the list of projects, create the case description message
        Steps: 
           1. For each project in projectsForUpdateList, create the case description message in matchedDesc
           2. Fetch the respective case for the project and put key = case, value = matchedDesc in caseMatchMap
    */       
    public void updateCaseDescriptionsWithProjectDetails(List<pse__Proj__c> projectsForUpdateList)
    {

        for(pse__Proj__c project : projectsForUpdateList){
            GSS_Autogen__c eachAutogen = achdIdToGSSAutogenForProjectsMap.get(project.ACHD__c);//got the autogen from the project's ACHD

            String matchedDesc = '\n\n'+'Project {0} for Unit of measure {1} was created successfully and linked to the CLI Detail Id: {2} that is part of the Original contract Id: {3}, Link to the project: {4}';
            matchedDesc = matchedDesc.replace('{0}', eachAutogen.Project_Name__c);
            matchedDesc = matchedDesc.replace('{1}', eachAutogen.Triggering_Unit_of_Measure__c);
            matchedDesc = matchedDesc.replace('{2}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+project.SMP_Contract_Line_Item__c);
            matchedDesc = matchedDesc.replace('{3}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+project.SMP_Contract__c);
            matchedDesc = matchedDesc.replace('{4}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+project.Id);

            if(cliDescriptionMap.containsKey(project.ACHD__c)){//If there are no wrong Biling Duration it won't go inside
                matchedDesc = cliDescriptionMap.get(project.ACHD__c) + matchedDesc;
            }
            cliDescriptionMap.put(project.ACHD__c,matchedDesc);  // <CLI1,SCA><CLI2,TRA><CLI3,SSP>

            if(caseMatchMap.containsKey(achdIdToCaseForProjectMap.get(project.ACHD__c))){
                String tempStr = caseMatchMap.get(achdIdToCaseForProjectMap.get(project.ACHD__c));
                caseMatchMap.put(achdIdToCaseForProjectMap.get(project.ACHD__c),tempStr+matchedDesc);
            }
            else{
                caseMatchMap.put(achdIdToCaseForProjectMap.get(project.ACHD__c),matchedDesc);//<case,SCA desc><case,TSR desc><case, SSP>
            }
        }

        Set<Case> casesForProjectUpdateVals = GSS_Autogen_Util.updateCaseDescription(caseMatchMap);
        casesForUpsertSet.addAll(casesForProjectUpdateVals);
    }
  
}
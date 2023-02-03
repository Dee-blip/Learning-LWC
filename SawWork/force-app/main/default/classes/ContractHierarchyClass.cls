/**
* This class is a custom controller to build hierarchy for the 
* Contracts. There are 3 different level NAP Master, Reseller 
* and Indirect Contracts
* History: 
* =========================
* Developer        Date        Description
* --------------------------------------------------------------------------------------------------
* Hitesh Chawda    02/2015     Created Class CR 2906850
* Nagaraj Desai    04/12/2019  Modified class to support lightning calls as part of SFDC-5963
* **/

public with sharing class ContractHierarchyClass{
    
    public static List<hierarchyItem> hierarchyItemList {get;set;}
    public static Id ContractIdd {get;set;}
    public static List<Merge_Contract_Header__c> resellerContractwithNAP = new List<Merge_Contract_Header__c>();
    private static Map<Id,Map<Integer,Merge_Contract_Header__c>> parentToIndexToContractRecordMap = new Map<Id,Map<Integer,Merge_Contract_Header__c>>();
    private static List<Merge_Contract_Header__c> indirectRecordsList = new List<Merge_Contract_Header__c>();
    private static Integer hierarchyIndex = 0;
    private static Integer numDays = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Contract_HierarchyEndDateDays'));
    private static Date dt = Date.today().addDays(-Integer.valueOf(numDays));
    public ContractHierarchyClass() {}
    // public ContractHierarchyClass(ApexPages.StandardController std)
    // {   
    //     Id ContractID = std.getId();
    //     ContractIdd = ContractID;
    //     hierarchyItemList = new List<hierarchyItem>();
    //     //Get current Contract Details        
    // }
    @AuraEnabled
    public static String setRequiredData(String ContractIdd) {
        hierarchyItemList = new List<hierarchyItem>();
        Merge_Contract_Header__c currentContract = [ SELECT  Account_Name__r.Id,
                                                    Account_Name__r.Name,
                                                    NAP_Master_Contract__c, Parent_Contract__c, Name,  
                                                    NAP_Master_Contract__r.Name,Active__c,
                                                    Effective_Start_Date__c , Effective_End_Date__c ,Contract_Type__c , Contract_Id__c,Id,
                                                    Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,
                                                    Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,
                                                    Partner_Type__c ,Paper_Type__c,Paper_Version__c,Paper_Version_no__c,
                                                    Parent_Contract__r.NAP_Master_Contract__c,Parent_Contract__r.NAP_Master_Contract__r.Name,
                                                    Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c,Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__r.Name,
                                                    Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__r.Name
                                                    FROM Merge_Contract_Header__c 
                                                    Where ID = :ContractIdd];
        
        if(currentContract.Active__c == true && currentContract.Effective_End_Date__c >= dt) {
            if(currentContract.NAP_Master_Contract__c == null) {
                if(currentContract.Parent_Contract__c == null) {
                    buildRootMethod(currentContract.Id,currentContract.Name); //Single Indirect or NAP
                }
                else {
                    findMasterOfHierarchy(currentContract);//Indirect/Reseller not immediate child of NAP
                }
            }
            else {
                buildRootMethod(currentContract.NAP_Master_Contract__c,currentContract.NAP_Master_Contract__r.Name);   // All Reseller records
            }
        }
        return JSON.serialize(hierarchyItemList);
    }
    /* Find out the Resellers under the NAP and Call Reller Root Method to build the Hierarch*/
    
    
    private static void findMasterOfHierarchy(Merge_Contract_Header__c contractRecord)
    {
        List<Merge_Contract_Header__c> resellerList = new List<Merge_Contract_Header__c>();
        if(contractRecord.Parent_Contract__r.NAP_Master_Contract__c != null)
            buildRootMethod(contractRecord.Parent_Contract__r.NAP_Master_Contract__c,contractRecord.Parent_Contract__r.NAP_Master_Contract__r.Name);
        else if(contractRecord.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c != null)
            buildRootMethod(contractRecord.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c,contractRecord.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__r.Name);
        else if(contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c != null)
            buildRootMethod(contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__c,contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.NAP_Master_Contract__r.Name);
        else{
            if(contractRecord.Parent_Contract__r.Parent_Contract__c == null)
            {
                Merge_Contract_Header__c masterReseller1 = getContractRecord(contractRecord.Parent_Contract__c);
                resellerList.add(masterReseller1);
                buildResellerRootMethod(resellerList);
            }
            else if(contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c == null)
            {
                Merge_Contract_Header__c masterReseller2 = getContractRecord(contractRecord.Parent_Contract__r.Parent_Contract__c);
                resellerList.add(masterReseller2);
                buildResellerRootMethod(resellerList);
            }
            else if(contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c == null)
            {
                Merge_Contract_Header__c masterReseller3 = getContractRecord(contractRecord.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c);
                resellerList.add(masterReseller3);
                buildResellerRootMethod(resellerList);
            }
            
            
            
        }
        
    }
    
    /*Generic Method to Query the record*/
    private static Merge_Contract_Header__c getContractRecord(Id contractRecord )
    {
        Merge_Contract_Header__c mch = new Merge_Contract_Header__c();
        mch =[ SELECT Id,Account_Name__r.Name,Account_Name__r.id,NAP_Master_Contract__c, Parent_Contract__c, Name,Contract_Type__c , Contract_Id__c,   
              Effective_Start_Date__c , Effective_End_Date__c  ,Active__c,
              Partner_Type__c ,Paper_Type__c,Paper_Version__c,Paper_Version_no__c      
              FROM Merge_Contract_Header__c 
              Where Id = :contractRecord];
        return mch;
        
    }
    
    /*Build Hierarchy for NAP or Single Indirect*/
    private static void buildRootMethod(Id contractRecord , String contractRecordName )
    {
        List<Merge_Contract_Header__c> con = new List<Merge_Contract_Header__c>();
        List<Merge_Contract_Header__c> resellerList = new List<Merge_Contract_Header__c>();
        List<Merge_Contract_Header__c> conSelected = new List<Merge_Contract_Header__c>();
        
        Merge_Contract_Header__c NAPRecord = getContractRecord(contractRecord);
        
        con = [ SELECT Id,Account_Name__r.Name,Account_Name__r.id,NAP_Master_Contract__c, Parent_Contract__c, Name,Contract_Type__c , Contract_Id__c,   
               Effective_Start_Date__c , Effective_End_Date__c  ,Active__c,
               Partner_Type__c ,Paper_Type__c,Paper_Version__c,Paper_Version_no__c      
               FROM Merge_Contract_Header__c 
               Where NAP_Master_Contract__c = :contractRecord];
        if(con.size()>0)
        {
            if(NAPRecord.Active__c == true && NAPRecord.Effective_End_Date__c >= dt)
            {
                hierarchyItemList.add(new hierarchyItem( contractRecordName , hierarchyIndex, NAPRecord.Account_Name__r.Name,NAPRecord.Account_Name__r.id,NAPRecord.Effective_Start_Date__c , NAPRecord.Effective_End_Date__c ,NAPRecord.Contract_Type__c , NAPRecord.Contract_Id__c,NAPRecord.Id
                                                        ,NAPRecord.Partner_Type__c ,NAPRecord.Paper_Type__c,NAPRecord.Paper_Version__c,NAPRecord.Paper_Version_no__c));
                hierarchyIndex = hierarchyIndex+1;
                for(Merge_Contract_Header__c conSel : con)
                {
                    if(conSel.Active__c == true && conSel.Effective_End_Date__c >= dt)//Date.today()-90)
                    {
                        conSelected.add(conSel);
                    }
                }
                System.Debug('NAP master is created '+contractRecordName +'child Records '+con);
                buildResellerRootMethod(conSelected);
            }
        }
        else 
        {
            if(NAPRecord.Active__c == true && NAPRecord.Effective_End_Date__c >= dt)
            {
                resellerList.add(NAPRecord);
                buildResellerRootMethod(resellerList);
            }
        } 
        /*hierarchyItemList.add(new hierarchyItem( contractRecordName , hierarchyIndex ,NAPRecord.Account_Name__r.Name,NAPRecord.Account_Name__r.id,NAPRecord.Effective_Start_Date__c , NAPRecord.Effective_End_Date__c ,NAPRecord.Contract_Type__c , NAPRecord.Contract_Id__c,NAPRecord.Id
,NAPRecord.Partner_Type__c ,NAPRecord.Paper_Type__c,NAPRecord.Paper_Version__c,NAPRecord.Paper_Version_no__c));*/
        
    }
    
    /* Build Hierarchy under Resller as Reseller to Child to Grand Child to Grand Grand Child and it's Hierarchy using Wrapper class method*/
    
    private static void buildResellerRootMethod(List<Merge_Contract_Header__c> resellerRecord)
    {
        List<Merge_Contract_Header__c> parentHierachyList = new List<Merge_Contract_Header__c>();
        List<Merge_Contract_Header__c> mchListCount1 = new List<Merge_Contract_Header__c>();
        List<Merge_Contract_Header__c> mchListCount2 = new List<Merge_Contract_Header__c>();
        List<Merge_Contract_Header__c> mchListCount3 = new List<Merge_Contract_Header__c>();
        
        
        parentHierachyList =[Select Name, Account_Name__r.Name,Account_Name__r.id,NAP_Master_Contract__c, 
                             Parent_Contract__c,Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__c ,
                             Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,Active__c
                             ,Effective_Start_Date__c , Effective_End_Date__c ,Contract_Type__c , Contract_Id__c,Id,
                             Partner_Type__c ,Paper_Type__c,Paper_Version__c,Paper_Version_no__c
                             From Merge_Contract_Header__c 
                             Where (Parent_Contract__c IN :resellerRecord OR 
                                    Parent_Contract__r.Parent_Contract__c IN :resellerRecord OR 
                                    Parent_Contract__r.Parent_Contract__r.Parent_Contract__c IN :resellerRecord )AND 
                             Active__c = True AND
                             Effective_End_Date__c >=:dt ORDER BY Effective_Start_Date__c DESC]; // ordering by Effective_Start_Date__c which will be built Effective_Start_Date__c ASC later SFDC-5963
        
        
        //throw new CustomException('Child list '+parentHierachyList);
        if(parentHierachyList.size() > 0)
        {
            for(Merge_Contract_Header__c mch : parentHierachyList)
            {
                if(mch.Parent_Contract__r.Parent_Contract__c == null )
                {
                    mchListCount1.add(mch);
                }
                else if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c == null)
                {
                    mchListCount2.add(mch);
                }
                else if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c == null)
                {
                    mchListCount3.add(mch);
                    
                }
                
                
            }
            System.Debug('List 1 '+mchListCount1 + ' List2 '+mchListCount2 +' List 3 '+mchListCount3 );        
            
        }
        for(Merge_Contract_Header__c mch: resellerRecord)
        {   
            hierarchyIndex = 1;
            System.Debug('Map values '+parentToIndexToContractRecordMap);
            System.Debug('Reseller NAme  '+mch.Name);
            hierarchyItemList.add(new hierarchyItem( mch.Name , hierarchyIndex,mch.Account_Name__r.Name,mch.Account_Name__r.id,mch.Effective_Start_Date__c , mch.Effective_End_Date__c ,mch.Contract_Type__c , mch.Contract_Id__c,mch.Id,
                                                    mch.Partner_Type__c ,mch.Paper_Type__c,mch.Paper_Version__c,mch.Paper_Version_no__c));
            //hierarchyIndex = hierarchyIndex+1;
            // building the next three for loops reverse so that we can remove list-items once consumed, thus increasing effeciency and reducing heap size SFDC-5963 : Nagaraj Desai
            for(Integer secondLevelIndex = mchListCount1.size()-1; secondLevelIndex > -1 ; secondLevelIndex-- ) {
                Merge_Contract_Header__c rch = mchListCount1.get(secondLevelIndex);
                if(rch.Parent_Contract__c == mch.Id)
                {
                    hierarchyIndex = 2;
                    hierarchyItemList.add(new hierarchyItem( rch.Name , hierarchyIndex,rch.Account_Name__r.Name,rch.Account_Name__r.id,rch.Effective_Start_Date__c , rch.Effective_End_Date__c ,rch.Contract_Type__c , rch.Contract_Id__c,rch.Id,
                                                            rch.Partner_Type__c ,rch.Paper_Type__c,rch.Paper_Version__c,rch.Paper_Version_no__c));
                    
                    for(Integer thirdLevelIndex = mchListCount2.size()-1; thirdLevelIndex > -1 ; thirdLevelIndex-- ) {
                        Merge_Contract_Header__c ich1 = mchListCount2.get(thirdLevelIndex);
                        if(ich1.Parent_Contract__c == rch.Id)
                        {
                            hierarchyIndex = 3;
                            hierarchyItemList.add(new hierarchyItem( ich1.Name , hierarchyIndex,ich1.Account_Name__r.Name,ich1.Account_Name__r.id,ich1.Effective_Start_Date__c , ich1.Effective_End_Date__c ,ich1.Contract_Type__c , ich1.Contract_Id__c,ich1.Id,
                                                                    ich1.Partner_Type__c ,ich1.Paper_Type__c,ich1.Paper_Version__c,ich1.Paper_Version_no__c));
                            
                            for(Integer fourthLevelIndex = mchListCount3.size()-1; fourthLevelIndex > -1 ; fourthLevelIndex-- ) {
                                Merge_Contract_Header__c ich2 = mchListCount3.get(fourthLevelIndex);
                                // mapping to nearest parent to solve SFDC-5963 : Nagaraj Desai
                                if(ich2.Parent_Contract__c == ich1.Id)
                                {
                                    hierarchyIndex = 4;    
                                    hierarchyItemList.add(new hierarchyItem( ich2.Name , hierarchyIndex,ich2.Account_Name__r.Name,ich2.Account_Name__r.id,ich2.Effective_Start_Date__c , ich2.Effective_End_Date__c ,ich2.Contract_Type__c , ich2.Contract_Id__c,ich2.Id,
                                                                            ich2.Partner_Type__c ,ich2.Paper_Type__c,ich2.Paper_Version__c,ich2.Paper_Version_no__c));
                                    mchListCount3.remove(fourthLevelIndex);
                                }
                            }
                            mchListCount2.remove(thirdLevelIndex);
                        }
                    }
                    mchListCount1.remove(secondLevelIndex);
                }
            }
        }
        System.Debug('Heap size '+Limits.getHeapSize() +'Heap limit '+Limits.getLimitHeapSize());
    }
    
    
    //Inner wrapper class for maintaning hierarchy items
    public class hierarchyItem{
        
        public String itemValue{get; private set;} 
        public String hierarchyIndexNo{get;private set;}
        public String accountName{get; set;}
        public Id accountId{get; set;}
        
        public Date startDate{get; set;}
        public Date endDate{get; set;}
        public String contractType{get; set;}
        public String contractID{get; set;}
        public Id sfID{get; set;}
        public String NameID{get; set;}
        public String partnerType {get; set;}
        public String paperType {get; set;}
        public String paperVersion {get; set;}
        public Date paperVersionNo {get; set;}
        
        
        public hierarchyItem(String itemValue , Integer hierarchyIndexNo, String AName ,Id accntID,Date sDate , Date eDate, String contractType,String contractID ,Id sfID ,String partnerType,String paperType,String paperVersion,Date paperVersionNo)  
        {
            String spaceCount = '';
            for(integer i = 0 ; i < hierarchyIndexNo ; i++)
                spaceCount = spaceCount  + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
            this.itemValue = spaceCount + itemValue;
            this.accountName = Aname;
            this.accountId = accntID;
            this.startDate = sDate;
            this.endDate = eDate;
            this.contractType = contractType ;
            this.contractID = contractID;
            this.sfID = sfID;
            this.NameID = itemValue;
            this.paperType = paperType;
            this.partnerType = partnerType;
            this.paperVersion = paperVersion;
            this.paperVersionNo = paperVersionNo;
        }
        
        
    }
    
}
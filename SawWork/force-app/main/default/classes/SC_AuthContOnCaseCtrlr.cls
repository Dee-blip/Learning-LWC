/*---------------------------------------------------------------------------------
     * Page Name            : SC_AuthContOnCase
     * Controller           : SC_AuthContOnCaseCtrlr
     * Developer Name       : Vandhana Krishnamurthy
     * Date                 : 20th November,2017
     * JIRA                 : ESESP-820 (SOCC)
     * Test Class           : SC_PolicyDomain_Test
---------------------------------------------------------------------------------*/ 

public class SC_AuthContOnCaseCtrlr 
{
    private Integer listSize = 5;
    
    // Case record
    public Case caseRec;
    public Integer noOfRecords{get;set;}
    
    //List of Contacts
    private List<Authorized_Contact__c> authorizedContactList;
    
    //Constructor
    public SC_AuthContOnCaseCtrlr(ApexPages.StandardController stdController)
    {
        caseRec = (Case) stdController.getRecord();
        if(caseRec.Id != NULL)
            caseRec = [Select Policy_Domain__c,Case_Prod_Name__c from Case where Id = :caseRec.Id limit 1];
        
        authorizedContactList = new List<Authorized_Contact__c>();
        Map<Id,List<Authorized_Contact__c>> caseAuthConMailIdMap = new Map<Id,List<Authorized_Contact__c>>();
            
        if(String.isNotBlank(this.caseRec.Policy_Domain__c))
        {
            //authorizedContactList = findValidAuthConFunOld(caseRec.Policy_Domain__c,caseRec.Case_Prod_Name__c);
            caseAuthConMailIdMap = findValidAuthConFun(new Map<Id,Id>{caseRec.Id => caseRec.Policy_Domain__c}, new Map<Id,String>{caseRec.Id => caseRec.Case_Prod_Name__c});
            if(caseAuthConMailIdMap != NULL && !caseAuthConMailIdMap.isEmpty() && caseAuthConMailIdMap.get(caseRec.Id) != NULL)
                authorizedContactList = caseAuthConMailIdMap.get(caseRec.Id);
        }
        
        noOfRecords = authorizedContactList.size();
    }
    
    // common function which returns Map<Case Id,List<Authorized Contacts>>
    public static Map<Id,List<Authorized_Contact__c>> findValidAuthConFun(Map<Id,Id> casePolDomIdMap, Map<Id,String> caseCaseProdMap)
    {
        Map<Id,List<Authorized_Contact__c>> caseAuthConMap = new Map<Id,List<Authorized_Contact__c>>();
        
        List<Authorized_Contact__c> allAuthCont = [SELECT Contact_Name__r.Name,Contact_Name__r.Email,Policy_Domain__c,
                                                   PD_Lead__c, Instruct__c, Maintenance_Email__c, Emergency_Email__c, 
                                                   Emergency_Voice__c, Emergency_Text__c, Product_Interests__c, Service__c  
                                                   FROM Authorized_Contact__c 
                                                   WHERE Policy_Domain__c IN :casePolDomIdMap.values()
                                                   ORDER BY PD_Lead__c desc,Contact_Name__r.Name     
                                                  ];
        
        for(Authorized_Contact__c eachAuthCon : allAuthCont)
        {
            for(Id eachCaseId : casePolDomIdMap.keySet())
            {
                if(casePolDomIdMap.get(eachCaseId) == eachAuthCon.Policy_Domain__c)   
                {
                    Set<String> prodInterest = new Set<String>(eachAuthCon.Product_Interests__c.split('; '));
                    
                    if(prodInterest.contains('All') || prodInterest.contains(caseCaseProdMap.get(eachCaseId)))
                    {
                        if(caseAuthConMap.containsKey(eachCaseId))
                        {
                            //List<String> authConEmailList = new List<String>();
                            //authConEmailList.addAll(caseAuthConMailIdMap.get(eachCaseId));
                            //authConEmailList.add(eachAuthCon.Contact_Name__r.Email);
                            caseAuthConMap.get(eachCaseId).add(eachAuthCon);
                        }
                        else
                        {
                            caseAuthConMap.put(eachCaseId,new List<Authorized_Contact__c>{eachAuthCon});
                        }
                    }
                }
            }
        }
        return caseAuthConMap;
    }
      
    public List<Authorized_Contact__c> getallAuthCont()
    {
        List<Authorized_Contact__c> lstAuthCon = new List<Authorized_Contact__c>();
        for(Authorized_Contact__c eachCon : (List<Authorized_Contact__c>)con.getRecords())
            lstAuthCon.add(eachCon);
        return lstAuthCon;
    }

    
    // Set Controller functions
    public ApexPages.standardSetController con
    {
        get
        {
            if(con == null)
            {
                con = new ApexPages.StandardSetController(authorizedContactList);
                con.setPageSize(listSize);
                noOfRecords = con.getResultSize();
            }
            return con;
        }
        set;
    }
    
    public Boolean hasNext
    {
        get{
            return con.getHasNext();
        }
        set;
    }
    
    public Boolean hasPrev
    {
        get{
            return con.gethasPrevious();
        }
        set;
    }
    
    public Integer pageNumber
    {
        get{
            if(con.getResultSize()==0)
                return 0;
            else
                return con.getPageNumber();
        }
        set;
    }
    
    public Integer totalPageNumber{
        get{
            Integer totalPages = (Math.mod(con.getResultSize(),5) == 0) ? con.getResultSize()/5 :
                        con.getResultSize()/5 + 1;
            return totalPages;
        }
        set;
    }
    
    public void first(){
        con.first();
    }
    public void last(){
        con.last();
    }
    public void next(){
        con.next();
    }
    public void previous(){
        con.previous();
    }
    
}
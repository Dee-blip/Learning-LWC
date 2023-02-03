/*---------------------------------------------------------------------------------
* Class                : SC_Special_Instructions
* Developer Name       : Supreeth 
* Date                 : 2 Apr 2019
* JIRA                 : ESESP-2086
* --------------------------------------------------------------------------------*/
public class SC_Special_Instructions {
   
     
    @AuraEnabled
    public static  List<Special_Instruction_Template__c> get_Special_Instruction_Template_List(){
        return [SELECT Name,Id from Special_Instruction_Template__c];
    }
    
    
    @AuraEnabled
    public static string Insert_Special_Instruction_With_Template(Date StartDate,Date ExpirationDate,Id SIT_Id,Id Account_Id){
        
        Special_Instructions__c SI = new Special_Instructions__c(Start_Date__c=StartDate,Expiration_Date__c=ExpirationDate,Special_Instruction_Template__c=SIT_Id,Account__c=Account_Id);
        
        try{
        insert SI;
            return 'Success';
        }catch(exception e){
           return e.getMessage(); 
        }
    }
    
    
    @AuraEnabled
    public static string Insert_Special_Instruction_WithOut_Template(Id AccountId,Date StartDate,Date ExpirationDate ,String Title,String Instructions,String SRT)
    {
        Special_Instructions__c SI = new Special_Instructions__c(Account__c=AccountId, Expiration_Date__c=ExpirationDate,Start_Date__c=StartDate,Title__c=Title,Instructions__c=Instructions,Show_for_Record_Types__c=SRT);
        
 try{
        insert SI;
            return 'Success';
        }catch(exception e){
           return  e.getMessage(); 
        }    }
    
    
        @AuraEnabled
    public static string Update_Special_Instruction_With_Template(Date StartDate,Date ExpirationDate,Id SIT_Id,Id Account_Id, Id SI_Id){
        
        Special_Instructions__c SI = new Special_Instructions__c(Start_Date__c=StartDate,Expiration_Date__c=ExpirationDate,Special_Instruction_Template__c=SIT_Id,Account__c=Account_Id,Id=SI_Id);
        
 try{
        update SI;
            return 'Success';
        }catch(exception e){
           return e.getMessage(); 
        }    }
    
    
    @AuraEnabled
    public static string Update_Special_Instruction_WithOut_Template(Id AccountId,Date StartDate,Date ExpirationDate ,String Title,String Instructions,String SRT,Id SI_Id)
    {
        Special_Instructions__c SI = new Special_Instructions__c(Account__c=AccountId, Expiration_Date__c=ExpirationDate,Start_Date__c=StartDate,Title__c=Title,Instructions__c=Instructions,Show_for_Record_Types__c=SRT,Id=SI_Id);
         try{
        update SI;
            return 'Success';
        }catch(exception e){
           return  e.getMessage(); 
        } 
    } 
    
        @AuraEnabled
    public static Boolean Is_SI_With_Template(Id SI_Id)
    {
          List<Special_Instructions__c> Special_Instruction_List=[SELECT Id,Special_Instruction_Template__c from Special_Instructions__c Where Id=:SI_Id LIMIT 1];
        if(Special_Instruction_List[0].Special_Instruction_Template__c == null)
        {
            return false;
        }
        
        return true;
       
    }
    
        @AuraEnabled
    public static List<Special_Instruction_Template__c>  get_SI_Template_details(Id SI_Id)
    {
          List<Special_Instructions__c> Special_Instruction=[SELECT Id,Special_Instruction_Template__c from Special_Instructions__c Where Id=:SI_Id LIMIT 1];
        if(Special_Instruction[0].Special_Instruction_Template__c != null){
            
        Id SIT_Id=Special_Instruction[0].Special_Instruction_Template__c;
        List<Special_Instruction_Template__c> Special_Instruction_Template_List=[SELECT Id,Name from Special_Instruction_Template__c WHERE Id=:SIT_Id LIMIT 1];
        return Special_Instruction_Template_List;
        }
        
         else
         {
             List<Special_Instruction_Template__c> Special_Instruction_Template_List_Temp = new List<Special_Instruction_Template__c>();
             Special_Instruction_Template__c sit= new Special_Instruction_Template__c();
             sit.Name='NA';
             Special_Instruction_Template_List_Temp.add(sit);
             return Special_Instruction_Template_List_Temp; 

             
         }
    }
         @AuraEnabled
    public static String getLogoUrl(String SIT_Template)
          {
              
   List<Special_Instruction_Template__c> sit_list=[SELECT Id,Name,Flag_Icon__c from Special_Instruction_Template__c Where Name=:SIT_Template LIMIT 1];
   String FlagName=sit_list[0].Flag_Icon__c;         
              String logoUrl =  URL.getSalesforceBaseUrl().getHost()+'/servlet/servlet.FileDownload?file=';
List<Document> doc_list=[select id,Name,DeveloperName from document where Name=:FlagName LIMIT 1];
              logoUrl=logoUrl+doc_list[0].id;
             logoUrl='https://'+logoUrl;
        return logoUrl;
        
         
    }
    
    
    
}
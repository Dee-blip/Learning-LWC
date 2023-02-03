public class P2RETL_GenerateOracleTableScript_Cls {
  
 public Attachment AttachmentResult{get;set;}
 public string getObjAPIName {get;set;}
 public boolean flag{get;set;}
 public String EmailIdEntered{get;set;}

    public PageReference mainMethod(){
    
        getTableScriptfromSFDCObj(getObjAPIName);
        flag = false;
        return null;
        
    } 
    
    
    public static Boolean validateEmail(String email) {
	Boolean res = true;
		
	
	String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: <a href="http://www.regular-expressions.info/email.html" target="_blank" rel="nofollow">http://www.regular-expressions.info/email.html</a>
	Pattern MyPattern = Pattern.compile(emailRegex);
	Matcher MyMatcher = MyPattern.matcher(email);

	if (!MyMatcher.matches()) 
	    res = false;
	return res;	
	}
    
    public void getTableScriptfromSFDCObj (string objName){
    
      try{
      
          // Getting SObject Type Dynamically from Parameter
          Schema.SObjectType SObjType = Schema.getGlobalDescribe().get(objName);
  
          // Describe the SObject
          Schema.DescribeSObjectResult SObjTypeDescribe = SObjType.getDescribe();
  
          // Map to store Field API Name - Field Type
          Map<String, Schema.SObjectField> fieldAPI_fieldTypeMap = SObjTypeDescribe.fields.getMap();
  
          // Variable to store each Field Description
          Schema.DescribeFieldResult FieldDesc;
   
          // string for Tab space
          string tabSpace= '\t\t\t\t\t'; 
   String tableScript ='\n--Note1 : All identifiers more than 30 char long would be commented. \n--Note2 : Last Two fields - DM_INSERT_DATE and DM_UPDATE_DATE are additions . Please remove them if not needed';
         
          // string For Table Script
           tableScript += '\n\ncreate Table ' + objName.replace('__c','').toUpperCase() + ' ( \n\n\t' + 'Id' + tabSpace + 'VARCHAR2(20) Primary Key';
  
          // Variable to store the Field Type
          string getFieldType;
          
          // Variable to store the Derived Column Name
          string columnName;
  
          // Loop for each Field
          for(string eachField : fieldAPI_fieldTypeMap.keyset()){

            // Each Field Description
            FieldDesc = fieldAPI_fieldTypeMap.get(eachField).getDescribe();
            getFieldType = string.valueOf(FieldDesc.getType());
            
            // Derivation for Column Name
            columnName = eachField.replaceAll('__c','').toUpperCase();
    
            // 1. For Text Area
            if(getFieldType.equalsIgnoreCase('TEXTAREA')){
                
                // For - Rich Text Area
                if(FieldDesc.isHtmlFormatted()){
                    if(columnName.length()<=30)
                    tableScript += ',\n\t' + columnName + tabSpace + 'BFILE';
                else
                     tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'BFILE';
                }
                // For - Long Text Area having >= 4000 Char
                else if(FieldDesc.getLength() > 4000){
                    
                	if(columnName.length()<=30)
                    tableScript += ',\n\t' + columnName + tabSpace + 'NCLOB';
                    else
                    tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'NCLOB';
                }
                // For - Long Text Area having < 4000 Char + Text Area  
                else
                {	
                    if(columnName.length()<=30)
                    tableScript += ',\n\t' + columnName + tabSpace + 'VARCHAR2(' + FieldDesc.getLength() + ' CHAR)';
                 	else
                    tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'VARCHAR2(' + FieldDesc.getLength() + ' CHAR)';
                 	 
                }
            }
    
            // 2. For Text + Email + PICKLIST + REFERENCE + PHONE + URL
            else if(getFieldType.equalsIgnoreCase('STRING') || getFieldType.equalsIgnoreCase('EMAIL') || getFieldType.equalsIgnoreCase('PICKLIST') || getFieldType.equalsIgnoreCase('REFERENCE') || getFieldType.equalsIgnoreCase('PHONE') || getFieldType.equalsIgnoreCase('URL')){
                if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'VARCHAR2(' + FieldDesc.getLength() + ' CHAR)';
                else
                tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'VARCHAR2(' + FieldDesc.getLength() + ' CHAR)';
            }
    
            // 3. For DATE + DATETIME
            else if(getFieldType.equalsIgnoreCase('DATE') || getFieldType.equalsIgnoreCase('DATETIME')){
                if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'DATE';
                else
                tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'DATE';
            }
    
            // 4. For CURRENCY + DOUBLE
            else if(getFieldType.equalsIgnoreCase('CURRENCY') || getFieldType.equalsIgnoreCase('DOUBLE') || getFieldType.equalsIgnoreCase('PERCENT')){
                
                
                if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'NUMBER(' + FieldDesc.getPrecision() + ',' + FieldDesc.getScale() +
                        ')';
                
                else
                    tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'NUMBER(' + FieldDesc.getPrecision() + ',' + FieldDesc.getScale() +
                        ')';
            
            }
    
            // 5. For BOOLEAN
            else if(getFieldType.equalsIgnoreCase('BOOLEAN') ){
                if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'CHAR(10 CHAR)';
                else
                tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'CHAR(10 CHAR)';
            }
              
              // 6. For MULTIPICKLIST
            else if(getFieldType.equalsIgnoreCase('MULTIPICKLIST')){
  				if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'VARCHAR2(4000 CHAR)';
                else
                tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'VARCHAR2(4000 CHAR)';
            }
    
       // 7. For ANYTYPE
            else if(getFieldType.equalsIgnoreCase('ANYTYPE')){
  				if(columnName.length()<=30)
                tableScript += ',\n\t' + columnName + tabSpace + 'VARCHAR2(4000 CHAR)';
                else
                 tableScript += ',\n--Identifier Too long\t' + columnName + tabSpace + 'VARCHAR2(4000 CHAR)';
            }
    
          }
          //Adding DM_INSERT_DATE and DM_UPDATE_DATE
          tableScript=tableScript+',\n\tDM_INSERT_DT'+ tabSpace+ 'DATE DEFAULT SYSDATE NOT NULL' ;
          tableScript=tableScript+',\n\tDM_UPDATE_DT'+ tabSpace+ 'DATE DEFAULT SYSDATE NOT NULL' ;
          tableScript += '\n );';
          
          
          flag = true;
          
          // Getting Current User Email
          
          string getCurrEmail;
          
          if(String.isEmpty(EmailIdEntered))
          {
          getCurrEmail= [select Email from User where Id = :userInfo.getUserId() limit 1][0].Email;
              System.debug(getCurrEmail);
          }
          else 
          {
              if(validateEmail(EmailIdEntered)){
                  getCurrEmail=EmailIdEntered;
              }
          }
System.debug('Sending email');
          // Sending Email 
          Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
          String[] toAddresses = new list<string> {getCurrEmail};
          String subject ='SFDC DataType';
          
          email.setSubject(subject);
          email.setToAddresses( toAddresses );
          email.setPlainTextBody(tableScript);
          
          Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});

          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Details has been sent to your Email'));
          
       }
        catch(EmailException e1){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter Valid Email-Id'));
       }
        
        
       catch(NullPointerException e2){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Enter Valid Object API Name'));
       }
        
       
  
    }
  
  }
/*****************************************************************************
 * Name             : EmailToCaseUtility
 * Created By       : Pitamber Sharma
 * Created Date     : 22-May-2013
 * Purpose          : Class containing some utility methods for email services.
 Last Modified BY       Last Modified Date  Purpose
 ----------------       ------------------  ---------
 Himanshu               27-March-14         Truncate the Subject to 255 Char for Task(Release - 3.40) 
 Vijetha Vijayendran    23-Apr-14			Fix added to return correct key in findString function(Release - 3.41)
 Akhila					20-Mar-15			CR 2907264 - By passing Case's RecentUPdate flag update for emails with fromaddr=Case.OwnerEmail
 Aditya				 	17-Feb-16			CR 3307861 Added MS Azure Visibility Changes
 Vandhana               30-Sept-19          New function for AMG Account ID   
*****************************************************************************/

public with sharing class EmailToCaseUtility {
    
    public static String getCaseNumber(string subjecttext,String delimiter,String endDelimiter) {
    String caseNumber;
    integer index = subjecttext.lastIndexOfIgnoreCase(delimiter);
    index += delimiter.length();
    String subjectTrimmed = subjecttext.subString(index);
    Integer endDelimiterIndex = subjectTrimmed.indexOfIgnoreCase(endDelimiter);
    caseNumber = subjecttext.substring(index,index+endDelimiterIndex);
    caseNumber = caseNumber.trim();
    return caseNumber;
  }
    
    public static String convertHtmlBodyToText(String htmlBody) {
    String HTML_TAG_PATTERN = '<style.*?>.*?</style>'; //regular expression to match all HTML/XML tags
        String result = htmlBody.replaceAll('<br/>', '\n');
        result = result.replaceAll('\n', '');
        result = result.replaceAll('<br />', '\n');
        result = result.replaceAll('</p>', '\n');
       
        pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
        matcher myMatcher = myPattern.matcher(result);          // get your matcher instance
        result = myMatcher.replaceAll('');          //remove the tags     
        myPattern = pattern.compile('<.*?>');
        myMatcher = myPattern.matcher(result);          // get your matcher instance
      result = myMatcher.replaceAll('');
      return result;
  }
  
  public static List<String> convertLowerCase(String[] incomingArr) {
    List<String> returnList = new List<String>();
    if(incomingArr != null && incomingArr.size() >= 0) {
        for(String s : incomingArr) {
            returnList.add(s.toLowerCase());
        }
    }
    return returnList;
  }
  
  public static String listToString(String[] incomingArr) {
    String returnStr = '';
    if(incomingArr != null && incomingArr.size() >= 0) {
        for(String s : incomingArr) {
            returnStr += s.toLowerCase() + ';';
        }
    }
    if(returnStr.contains(';') ) {
        returnStr = returnStr.substring(0, returnStr.lastIndexOf(';'));
    }
    return returnStr;
  }
  
  public static String findString(String parentStr, String searchKey) {
    String res;
    for(String s : parentStr.split('\\n')) {
        if(s.containsIgnoreCase(searchKey)) {
            Integer keyIndex = s.indexOf(searchKey) + (searchKey.length() - 1);
            Integer firstSpace = s.indexOf(' ', keyIndex);
        
            if(firstSpace != -1 || (firstSpace - keyIndex) == 1) {
                keyIndex += 2;
            firstSpace = s.indexOf(' ', keyIndex);
            }
        
            if(firstSpace == -1) {
            res = s.substring(keyIndex);
            } else {
                res = s.substring(keyIndex, firstSpace);
            }
        
            res = res.trim();
            break;
            }
    }
    return res;
  }
  
  public static String findStringAMG(String parentStr, String searchKey) 
    {
        String res;
        for(String s : parentStr.split('\\n')) 
        {
            if(s.containsIgnoreCase(searchKey)) 
            {
                Integer keyIndex = s.toLowerCase().indexOf(searchKey.toLowerCase()) + (searchKey.length() - 1);
                Integer firstSpace = s.indexOf(' ', keyIndex);
                System.debug('keyIndex : ' + keyIndex);
                System.debug('firstSpace : ' + firstSpace);
                if(firstSpace != -1 || (firstSpace - keyIndex) == 1) 
                {
                    keyIndex += 2;
                    firstSpace = s.indexOf(' ', keyIndex);
                }
                
                if(firstSpace == -1) 
                {
                    res = s.substring(keyIndex);
                    System.debug('res -1 : ' + res);
                } 
                else 
                {
                    res = s.substring(keyIndex, firstSpace);
                    System.debug('res normal : ' + res);
                }
                if(res.contains(':'))
                    res = res.replace(':','');
                res = res.trim();
                System.debug('res final : ' + res);
                break;
            }
        }
        return res;
    }
  
    // Called from EmailToCaseHandler Class
    // Visibility check is added as part of MS Azure changes
    public static Task createTask(String taskWhatId, String subjectText, String bodyText, Boolean isInternal,Boolean isCreatedByUser, String setVisibility) {
    
        // variable for setting subject (Truncating the Subject to 255 Char)
        string setSubject = 'Email: ' + subjectText;
        
        //kusharma: Added a check for calculating length of subject before truncating it.
        if(setSubject.length()>254){
            setSubject = setSubject.substring(0,254);
        }
      
        Task ta = new Task();
        //ta.OwnerId=usr.id;
        ta.WhatId = taskWhatId;
        ta.Subject = setSubject;
        ta.Type__c = 'Email';
        ta.Description = bodyText;
        ta.Status = 'Completed';
		ta.isCreatedByUser__c = isCreatedByUser;
        ta.Internal_Only__c = ((setVisibility != 'Customer')?true:false);// Added as part of MS Azure Visibility Changes
        ta.Visibility__c = setVisibility; // Added as part of MS Azure Visibility Changes
        insert ta;
        return ta;
    }
    
	/*public static Task createTaskWithVisibility(String taskWhatId, String subjectText, String bodyText,Boolean isCreatedByUser,String Visibility) {
    
        // variable for setting subject (Truncating the Subject to 255 Char)
        string setSubject = 'Email: ' + subjectText;
        //kusharma: Added a check for calculating length of subject before truncating it.
        if(setSubject.length()>254){
            setSubject = setSubject.substring(0,254);
        }
        
        Task ta = new Task();
        //ta.OwnerId=usr.id;
        ta.WhatId = taskWhatId;
        ta.Subject = setSubject;
        ta.Type__c = 'Email';
        ta.Description = bodyText;
        ta.Status = 'Completed';
        ta.Internal_Only__c = ((Visibility != 'Customer')?true:false); // Added as part of MS Azure Visibility Changes
		ta.isCreatedByUser__c = isCreatedByUser;    
        ta.Visibility__c = Visibility;// Added as part of MS Azure Visibility Changes
        insert ta;
        return ta;
    }    */
    
    public static Boolean isInternalActivity(String fromAddress, String toAddresses, String ccAddresses) {
        
        if(toAddresses.containsIgnoreCase('nocc@akamai.com') || toAddresses.containsIgnoreCase('nocc-tix@akamai.com') || toAddresses.containsIgnoreCase('nocc-shift@akamai.com')
          || ccAddresses.containsIgnoreCase('nocc@akamai.com') || ccAddresses.containsIgnoreCase('nocc-tix@akamai.com') || ccAddresses.containsIgnoreCase('nocc-shift@akamai.com')){
               return true;
           }
        
        if(!fromAddress.containsIgnoreCase('@akamai.com') && toAddresses.contains('@akamai.com') 
            && !toAddresses.contains('nocc@akamai.com') && !toAddresses.contains('nocc-tix@akamai.com') && !toAddresses.contains('nocc-shift@akamai.com')
            && !ccAddresses.contains('nocc@akamai.com') && !ccAddresses.contains('nocc-tix@akamai.com') && !ccAddresses.contains('nocc-shift@akamai.com') ) {
        return false;
    } 
    if(fromAddress.containsIgnoreCase('@akamai.com') && !toAddresses.contains('@akamai.com') && !ccAddresses.contains('@akamai.com')
                        && !fromAddress.containsIgnoreCase('nocc@akamai.com') && !fromAddress.containsIgnoreCase('nocc-tix@akamai.com') 
                        && !fromAddress.containsIgnoreCase('nocc-shift@akamai.com') ) {
        return false;
    }
    for(String toAdd : toAddresses.split(';')) {
        if(!toAdd.equals('') && !toAdd.containsIgnoreCase('@akamai.com')) {
            return false;
        }
    }
    for(String ccAdd : ccAddresses.split(';')) {
        if(!ccAdd.equals('') && !ccAdd.containsIgnoreCase('@akamai.com')) {
            return false;
        }
    }
    return true;
    }
    
    public static Boolean isPartnerActivity(String fromAddress, String toAddresses, String ccAddresses) {
        
        if(!fromAddress.containsIgnoreCase('@akamai.com') && !fromAddress.containsIgnoreCase('@microsoft.com'))
            return false;
        
        if(toAddresses!=null && toAddresses!='')
        {
            for(String toAdd : toAddresses.split(';')) {
                if(toAdd!=null && !toAdd.equals('') && !toAdd.containsIgnoreCase('@akamai.com') && !toAdd.containsIgnoreCase('@microsoft.com')) {
                    system.debug('lllll'+toAdd);
                    return false;
                }
            }
        }
        if(ccAddresses!=null && ccAddresses!='')
        {
            for(String ccAdd : ccAddresses.split(';')) {
                if(ccAdd!=null && !ccAdd.equals('') && !ccAdd.containsIgnoreCase('@akamai.com') && !ccAdd.containsIgnoreCase('@microsoft.com')) {
                    system.debug('lllll'+ccAdd);
                    return false;
                }
            }
        }
        return true;
    }
}
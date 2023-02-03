/*
 * CR: 3147531
 * Release: 16.5
 * Developer: Sharath Prasanna
 * Summary: Acceptance Form for ERSS forms
 */
public class RSS_Acceptance_Form_Controller {
	
    //The acceptance form variable
    public ERSS_Acceptance_Form__c AcceptanceForm 
    {
        get
        {
            if(AcceptanceForm==null)
            {
                AcceptanceForm = new ERSS_Acceptance_Form__c();
            } 
            return AcceptanceForm;
        }
        set;
    }  
    //Stores the choices of the first question
  	Public List<SelectOption> Choices1 
  	{
  		  get
  		  {			
  			   if(Choices1==null) 
  			   { 
  				    Choices1 = stringToSelectOptionsList(AcceptanceForm.Choices1__c);
  			   }
  			   return Choices1;
  		  }
  		  set;
  	}
    //Stores the choices of the second question
  	Public List<SelectOption> Choices2 
  	{
  		get
  		{			
  			 if(Choices2==null) 
  			 { 
  			   	Choices2 = stringToSelectOptionsList(AcceptanceForm.Choices2__c);
  			 }
  			 return Choices2;
  		  }
  		  set;
  	}
    //Stores the choices of the third question
  	Public List<SelectOption> Choices3 
  	{
    		get
    		{			
    			if(Choices3==null) 
    			{ 
    				Choices3 = stringToSelectOptionsList(AcceptanceForm.Choices3__c);
    			}
    			return Choices3;
    		}
    		set;
  	}
    //This has the values entered for the second question
  	public List<String> CheckBoxValues2
  	{

    		get
    		{ 
    			CheckBoxValues2 = stringToListOFString(AcceptanceForm.Response2__c);
    			return CheckBoxValues2;
    		}
    		set
    		{ 
    			CheckBoxValues2 = value; 
    			AcceptanceForm.Response2__c = String.join(CheckBoxValues2,',');
    		}
  	}

    //This has the values entered for the third question
  	public List<String> CheckBoxValues3
  	{

    		get
    		{ 
    			CheckBoxValues3 = stringToListOFString(AcceptanceForm.Response3__c);
    			return CheckBoxValues3;
    		}
    		set
    		{ 
    			CheckBoxValues3 = value; 
    			AcceptanceForm.Response3__c = String.join(CheckBoxValues3,',');
    		}
  	}
    //This has the values entered for the first question
     Public String answer
     { 
     		get 
     		{ 
     			if(AcceptanceForm==null) 
     			{ 
     				return '';
     			} 
     			return AcceptanceForm.Response1__c;
     		} 
     		set 
     		{ 
     			AcceptanceForm.Response1__c = value; 
     		} 
     }  	
     //This variable determines if the ERSS form was satisfactorily filled by the Pre-Sales
      public Boolean Satisfactory {get;set;}

     //Default constructor 
  	public RSS_Acceptance_Form_Controller() 
  	{
  	}
    //Standard controller
    public RSS_Acceptance_Form_Controller(ApexPages.StandardController controller)
    {
        CustomConstructor();
    }


	  public void CustomConstructor()
    {
		    String ParameterPassed;
		    Satisfactory = true;
        if(Apexpages.currentPage()!= NULL)
        { 
            ParameterPassed = Apexpages.currentPage().getParameters().get('id');
            
            if(ParameterPassed!= NULL)
            {
                if(ParameterPassed.length() >= 15 )
                {
                	AcceptanceForm = [select id,Submitted__c,Choices1__c,Choices2__c,Choices3__c,Comments__c,Question1__c,Question2__c,Question3__c,Response1__c,Response2__c,Response3__c,Quality__c,Total__c,Completeness__c,Acceptance_Date__c,RSS_Form__c,RSS_Form_UniqueName__c from ERSS_Acceptance_Form__c where id = :ParameterPassed limit 1]; 
                	if (AcceptanceForm.Response1__c == 'NO')
                	{
                		Satisfactory = false;
                	}  
                    //System.assertEquals(AcceptanceForm.Question1__c,null);
                }
                else
                {

                }
            }
        }        	
    }    

    //Converts a string of options to a list of select options
  	public List<SelectOption> stringToSelectOptionsList(String choiceString)
  	{
  		List<String> stringList = new List<String>();
        	List<SelectOption> optionsList = new List<SelectOption>();
        	if(!String.isBlank(choiceString))
        	{
        		stringList = choiceString.split(',');
        		for(String s: stringList)
        		{
          		if (s != '') 
          		{
            			optionsList.add(new SelectOption(s.trim(),s.trim()));          
          		}
        		}      
        	}
  	    return optionsList;
    }
    //Converts a string of options to a list of strings
    public List<String> stringToListOFString(String str)
    {
    
        List<String> strList = new List<String>();
        if(!String.isBlank(str))
        {
        		strList = str.split(',');
        		for(String s:strList)
        		{
        			s=s.trim();
        		}
        } 
        return strList;
    }

    //checks if the first response is yes or no
    public void CheckForNo()
    {

      	if (AcceptanceForm.Response1__c == 'NO')
      	{
      		Satisfactory = false;
      	} 
      	else
      	{
      		Satisfactory = true;
      		AcceptanceForm.Response2__c = '';
      		AcceptanceForm.Response3__c = '';
      	} 

    }

    //function called from the save button
    Public PageReference UpdateForm()
    {
      	try
      	{
      		update AcceptanceForm;
      	}
      	Catch(Exception e)
      	{

      	}    	
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, ' Saved '));     	
      	return null;
    }


    //function called from the submit button
    Public PageReference SubmitForm()
    {
        //if the first response is blank, show the error message
        if(AcceptanceForm.Response1__c == '' || AcceptanceForm.Response1__c == null)
        {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'The Basic Integration Achieved question needs to be answered'));       
              return null;            
        }
        //if the ERSS Form is not satisfacory, check if either of 2 or 3 question is answered. Then set the Completeness and Quality
    		if(!Satisfactory )		
    		{
    			if(AcceptanceForm.Response3__c == '' && AcceptanceForm.Response2__c == '')
    			{
    					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' The Completeness or Quality section needs to be answered'));     	
    					return null;
    			}
    			AcceptanceForm.Completeness__c = 5 - CheckBoxValues2.size();
    			AcceptanceForm.Quality__c  = 5 - CheckBoxValues3.size();

    		}
    		else
    		{
      			AcceptanceForm.Quality__c = 5;
      			AcceptanceForm.Completeness__c  = 5;				
    		}
        //compute the total and set the Acceptance date, case date
    		AcceptanceForm.Total__c = AcceptanceForm.Quality__c + AcceptanceForm.Completeness__c;
    		AcceptanceForm.Submitted__c = true;
    		AcceptanceForm.Acceptance_Date__c = System.today();
        
        //query for the case linked to the RSS form and get its created date
        List<Case> linkedCases = new List<Case>();
        String formUniqueName = AcceptanceForm.RSS_Form_UniqueName__c;
        linkedCases = [select createddate from Case where eRSS_Form__r.UniqueName__c = :formUniqueName];
        if(linkedCases != null && linkedCases.size() == 1)
        {
             AcceptanceForm.Case_Date__c = linkedCases.get(0).createddate.date();
        }
      	
        try
      	{
      		update AcceptanceForm;
      	}
      	Catch(Exception e)
      	{

      	}    	
         PageReference pg = new PageReference('/apex/RSS_Acceptance_Form?id='+AcceptanceForm.id);
         pg.setRedirect(true);
         return pg;

    }
    //function called from the return to form link
    Public PageReference ReturnToForm()
    {
    	    PageReference pg = new PageReference('/apex/RSSForm?id='+AcceptanceForm.RSS_Form__c);
          pg.setRedirect(true);
          return pg;

    }

}